import os, json, random
from pathlib import Path
import numpy as np
import cv2
from tqdm import tqdm

import torch
from torch.utils.data import Dataset, DataLoader
from torchvision.models.detection import (
    fasterrcnn_resnet50_fpn_v2,
    FasterRCNN_ResNet50_FPN_V2_Weights
)
from torchvision.models.detection.faster_rcnn import FastRCNNPredictor

# ----------------------------
# 你需要改的配置
# ----------------------------
DATA_ROOT = Path(r"./HRCDS")  # 数据集根目录

# 过滤太小的碎框（裂缝容易碎）
MIN_AREA_PX =120

# 训练参数
EPOCHS = 20                       #训练轮数
BATCH_SIZE = 8                    #每批图片
LR = 2e-5                         #学习率
NUM_WORKERS = 4  # 若仍报错，先改 0 便于调试             #数据加载线程
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

# Faster R-CNN：num_classes=2 表示 1个前景类(damage/crack)+背景
NUM_CLASSES = 2

OUT_DIR = Path("./runs_detect")
OUT_DIR.mkdir(parents=True, exist_ok=True)

# 验证/可视化阈值（前期建议低一点，否则可能全被过滤）
EVAL_SCORE_THR = 0.05
IOU_THR = 0.5

# 是否做形态学平滑（建议 True）
USE_MORPH = True


# ----------------------------
# 工具：读取原始mask -> 自动前景二值
# ----------------------------
def mask_to_binary_auto(mask_path: Path) -> np.ndarray:
    """
    自动提取前景（damage）：
    - 灰度mask：像素最多的灰度值当背景，其余为前景
    - 彩色mask：像素最多的颜色当背景，其余为前景
    返回 uint8 二值图(0/1)
    """
    m = cv2.imread(str(mask_path), cv2.IMREAD_UNCHANGED)
    if m is None:
        raise FileNotFoundError(mask_path)

    # 灰度
    if m.ndim == 2:
        vals, cnts = np.unique(m, return_counts=True)
        bg_val = vals[np.argmax(cnts)]
        binary = (m != bg_val).astype(np.uint8)
        return binary

    # 彩色
    rgb = cv2.cvtColor(m, cv2.COLOR_BGR2RGB)
    pixels = rgb.reshape(-1, 3)
    colors, cnts = np.unique(pixels, axis=0, return_counts=True)
    bg_color = colors[np.argmax(cnts)]
    binary = np.any(rgb != bg_color, axis=-1).astype(np.uint8)
    return binary


def smooth_binary(binary: np.ndarray) -> np.ndarray:
    binary = (binary > 0).astype(np.uint8)
    k = cv2.getStructuringElement(cv2.MORPH_RECT, (9, 9))
    binary = cv2.morphologyEx(binary, cv2.MORPH_CLOSE, k, iterations=2)
    return binary

def binary_to_boxes(binary_mask: np.ndarray, min_area: int = 20):
    # 连通域 -> 外接矩形
    num_labels, labels, stats, _ = cv2.connectedComponentsWithStats(binary_mask, connectivity=8)
    boxes = []
    for i in range(1, num_labels):
        x, y, w, h, area = stats[i]
        if area < min_area:
            continue
        boxes.append([x, y, x + w, y + h])
    return boxes


# ----------------------------
# 工具：读取 COCO json bbox（可选）
# ----------------------------
def load_boxes_from_annotations(ann_path: Path):
    """
    仅演示 COCO json 的 bbox 读取。
    返回 ("coco", file2boxes) 或 (None, None)
    file2boxes: {file_name(or basename): [[x1,y1,x2,y2], ...], ...}
    """
    if not ann_path.exists() or ann_path.suffix.lower() != ".json":
        return None, None

    data = json.loads(ann_path.read_text(encoding="utf-8"))
    if "images" not in data or "annotations" not in data:
        return None, None

    id2file = {img["id"]: img["file_name"] for img in data["images"]
               if "id" in img and "file_name" in img}
    file2boxes = {}

    for a in data["annotations"]:
        if "bbox" not in a or "image_id" not in a:
            continue
        fn = id2file.get(a["image_id"])
        if fn is None:
            continue
        x, y, w, h = a["bbox"]
        box = [x, y, x + w, y + h]

        file2boxes.setdefault(fn, []).append(box)
        file2boxes.setdefault(Path(fn).name, []).append(box)

    return "coco", file2boxes


# ----------------------------
# Dataset（mask用stem映射匹配）
# ----------------------------
class CrackDetDataset(Dataset):
    """
    适配目录结构：
      {split}_image / {split}_mask / {split}_annotations

    优先从 COCO annotations 读 bbox；
    若读不到 bbox，则直接读取原始 mask 自动得到前景 -> bbox（不依赖固定颜色）。
    """
    def __init__(self, data_root, split="train", min_area=20, use_morph=True):
        self.data_root = Path(data_root)
        self.split = split
        self.min_area = min_area
        self.use_morph = use_morph

        self.img_dir = self.data_root / f"{split}_image"
        self.mask_dir = self.data_root / f"{split}_mask"
        self.ann_dir = self.data_root / f"{split}_annotations"

        if not self.img_dir.exists():
            raise FileNotFoundError(f"Image dir not found: {self.img_dir}")

        # 1) 收集图片文件
        exts_img = {".jpg", ".jpeg", ".png", ".bmp"}
        self.img_files = sorted([p.name for p in self.img_dir.iterdir()
                                 if p.is_file() and p.suffix.lower() in exts_img])
        if len(self.img_files) == 0:
            raise RuntimeError(f"No images found in: {self.img_dir}")

        # 2) 建立 mask 索引：stem -> mask_path（兼容各种后缀 & *_mask 命名）
        self.mask_map = {}
        if self.mask_dir.exists():
            exts_mask = {".png", ".jpg", ".jpeg", ".bmp", ".tif", ".tiff"}
            for p in self.mask_dir.iterdir():
                if not (p.is_file() and p.suffix.lower() in exts_mask):
                    continue
                stem = p.stem
                self.mask_map[stem] = p
                if stem.endswith("_mask"):
                    self.mask_map[stem[:-5]] = p  # 去掉 _mask

        # 3) 尝试读取 COCO annotations（如果annotations目录里有json）
        self.coco_map = None
        if self.ann_dir.exists():
            coco_jsons = sorted(self.ann_dir.glob("*.json"))
            if len(coco_jsons) > 0:
                fmt, file2boxes = load_boxes_from_annotations(coco_jsons[0])
                if fmt == "coco" and file2boxes:
                    self.coco_map = file2boxes

    def __len__(self):
        return len(self.img_files)

    def __getitem__(self, idx):
        fn = self.img_files[idx]
        img_path = self.img_dir / fn

        img_bgr = cv2.imread(str(img_path))
        if img_bgr is None:
            raise FileNotFoundError(f"Failed to read image: {img_path}")
        img = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)

        # -------- 1) 优先-------------------------------------=.12333223./2321232232./
        # 
        # 
        # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
        # \从 COCO annotation 获取 bbox --------
        boxes = None
        if self.coco_map is not None:
            boxes = self.coco_map.get(fn, None)
            if boxes is None:
                boxes = self.coco_map.get(Path(fn).name, None)

        # -------- 2) 若没有 bbox，则从原始 mask 自动得到前景 -> bbox --------
        if boxes is None:
            stem = Path(fn).stem
            mask_path = self.mask_map.get(stem, None)
            if mask_path is None:
                raise FileNotFoundError(
                    f"找不到对应mask：image={fn}\n"
                    f"已在 {self.mask_dir} 建索引，未匹配到 stem='{stem}'.\n"
                    f"请检查mask是否为 {stem}.png / {stem}_mask.png 等。"
                )

            binary = mask_to_binary_auto(mask_path)
            if self.use_morph:
                binary = smooth_binary(binary)

            boxes = binary_to_boxes(binary, min_area=self.min_area)

        # boxes -> tensor
        if boxes is None or len(boxes) == 0:
            boxes_t = torch.zeros((0, 4), dtype=torch.float32)
            labels_t = torch.zeros((0,), dtype=torch.int64)
        else:
            boxes_t = torch.tensor(boxes, dtype=torch.float32)
            labels_t = torch.ones((boxes_t.shape[0],), dtype=torch.int64)  # 前景=1

        target = {
            "boxes": boxes_t,
            "labels": labels_t,
            "image_id": torch.tensor([idx], dtype=torch.int64),
        }

        img_t = torch.from_numpy(img).permute(2, 0, 1).float() / 255.0
        return img_t, target


def collate_fn(batch):
    return tuple(zip(*batch))


# ----------------------------
# 模型
# ----------------------------
def build_model(num_classes=2):
    weights = FasterRCNN_ResNet50_FPN_V2_Weights.DEFAULT
    model = fasterrcnn_resnet50_fpn_v2(weights=weights)
    in_features = model.roi_heads.box_predictor.cls_score.in_features
    model.roi_heads.box_predictor = FastRCNNPredictor(in_features, num_classes)
    return model


# ----------------------------
# 评估：简化版 IoU@0.5 的 P/R/F1
# ----------------------------
def compute_iou(boxA, boxB):
    xA = max(boxA[0], boxB[0])
    yA = max(boxA[1], boxB[1])
    xB = min(boxA[2], boxB[2])
    yB = min(boxA[3], boxB[3])
    inter = max(0, xB - xA) * max(0, yB - yA)
    areaA = max(0, boxA[2] - boxA[0]) * max(0, boxA[3] - boxA[1])
    areaB = max(0, boxB[2] - boxB[0]) * max(0, boxB[3] - boxB[1])
    union = areaA + areaB - inter + 1e-6
    return inter / union


@torch.no_grad()
def evaluate_map50(model, loader, score_thr=0.05, iou_thr=0.5):
    model.eval()
    tp = fp = fn = 0
    for images, targets in tqdm(loader, desc="Eval", leave=False):
        images = [img.to(DEVICE) for img in images]
        outputs = model(images)

        for out, tgt in zip(outputs, targets):
            gt_boxes = tgt["boxes"].cpu().numpy().tolist()
            pr_boxes = out["boxes"].cpu().numpy().tolist()
            pr_scores = out["scores"].cpu().numpy().tolist()
            pr = [b for b, s in zip(pr_boxes, pr_scores) if s >= score_thr]

            matched = [False] * len(gt_boxes)
            for pb in pr:
                best_iou, best_j = 0, -1
                for j, gb in enumerate(gt_boxes):
                    if matched[j]:
                        continue
                    iou = compute_iou(pb, gb)
                    if iou > best_iou:
                        best_iou, best_j = iou, j

                if best_iou >= iou_thr and best_j >= 0:
                    tp += 1
                    matched[best_j] = True
                else:
                    fp += 1

            fn += matched.count(False)

    precision = tp / (tp + fp + 1e-6)
    recall = tp / (tp + fn + 1e-6)
    f1 = 2 * precision * recall / (precision + recall + 1e-6)
    return {"P": precision, "R": recall, "F1": f1, "tp": tp, "fp": fp, "fn": fn}



@torch.no_grad()
def evaluate_best_f1(model, loader, iou_thr=0.5, thrs=None):
    if thrs is None:
        thrs = [0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.4, 0.5, 0.6]
    best = {"F1": -1.0, "thr": None, "P": 0.0, "R": 0.0}
    for thr in thrs:
        m = evaluate_map50(model, loader, score_thr=float(thr), iou_thr=iou_thr)
        if m["F1"] > best["F1"]:
            best = {"F1": m["F1"], "thr": float(thr), "P": m["P"], "R": m["R"]}
    return best

@torch.no_grad()
def test_and_save_vis(model, dataset, save_dir: Path, score_thr=0.05, max_images=50):
    save_dir.mkdir(parents=True, exist_ok=True)
    model.eval()

    for i in range(min(len(dataset), max_images)):
        img_t, _ = dataset[i]
        img = (img_t.permute(1, 2, 0).numpy() * 255).astype(np.uint8)

        out = model([img_t.to(DEVICE)])[0]
        boxes = out["boxes"].cpu().numpy().astype(int)
        scores = out["scores"].cpu().numpy()

        vis = img.copy()
        for b, s in zip(boxes, scores):
            if s < score_thr:
                continue
            x1, y1, x2, y2 = b.tolist()
            cv2.rectangle(vis, (x1, y1), (x2, y2), (0, 255, 0), 2)
            cv2.putText(vis, f"damage {s:.2f}", (x1, max(0, y1 - 6)),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)

        cv2.imwrite(str(save_dir / f"pred_{i:04d}.jpg"), cv2.cvtColor(vis, cv2.COLOR_RGB2BGR))


# ----------------------------
# 主流程：train/val/test + 断点续训
# ----------------------------
def main():
    torch.manual_seed(0)
    random.seed(0)
    np.random.seed(0)

    train_ds = CrackDetDataset(DATA_ROOT, split="train", min_area=MIN_AREA_PX, use_morph=USE_MORPH)
    val_ds   = CrackDetDataset(DATA_ROOT, split="val",   min_area=MIN_AREA_PX, use_morph=USE_MORPH)
    test_ds  = CrackDetDataset(DATA_ROOT, split="test",  min_area=MIN_AREA_PX, use_morph=USE_MORPH)

    train_loader = DataLoader(
        train_ds, batch_size=BATCH_SIZE, shuffle=True,
        num_workers=NUM_WORKERS, collate_fn=collate_fn,
        pin_memory=True, persistent_workers=(NUM_WORKERS > 0)
    )
    val_loader = DataLoader(
        val_ds, batch_size=8, shuffle=False,
        num_workers=NUM_WORKERS, collate_fn=collate_fn,
        pin_memory=True, persistent_workers=(NUM_WORKERS > 0)
    )
    test_loader = DataLoader(
        test_ds, batch_size=8, shuffle=False,
        num_workers=NUM_WORKERS, collate_fn=collate_fn,
        pin_memory=True, persistent_workers=(NUM_WORKERS > 0)
    )

    model = build_model(NUM_CLASSES).to(DEVICE)

    # ✅ 建议：减少每张图输出框数量，降低 FP（提升 P/F1）
    try:
        model.roi_heads.detections_per_img = 30
    except Exception:
        pass

    params = [p for p in model.parameters() if p.requires_grad]
    optim = torch.optim.AdamW(params, lr=LR, weight_decay=1e-4)

    # ✅ AMP 混合精度（cuda 才启用）
    use_amp = (DEVICE.startswith("cuda"))
    scaler = torch.cuda.amp.GradScaler(enabled=use_amp)

    # ---- 断点续训 ----
    ckpt_path = OUT_DIR / "checkpoint.pt"
    start_epoch = 1
    best_f1 = -1.0
    best_thr = EVAL_SCORE_THR

    if ckpt_path.exists():
        state = torch.load(ckpt_path, map_location=DEVICE)
        model.load_state_dict(state["model"])
        optim.load_state_dict(state["optim"])
        best_f1 = float(state.get("best_f1", -1.0))
        best_thr = float(state.get("best_thr", best_thr))
        start_epoch = int(state.get("epoch", 0)) + 1
        print(f"Resume from {ckpt_path}, start_epoch={start_epoch}, best_f1={best_f1:.3f}, best_thr={best_thr:.2f}")

    # for epoch in range(start_epoch, EPOCHS + 1):
    #     model.train()
    #     pbar = tqdm(train_loader, desc=f"Epoch {epoch}/{EPOCHS}", leave=False)
    #     loss_sum = 0.0

    #     for images, targets in pbar:
    #         images = [img.to(DEVICE) for img in images]
    #         targets = [{k: v.to(DEVICE) for k, v in t.items()} for t in targets]

    #         optim.zero_grad(set_to_none=True)

    #         if use_amp:
    #             with torch.cuda.amp.autocast():
    #                 loss_dict = model(images, targets)
    #                 loss = sum(loss_dict.values())
    #             scaler.scale(loss).backward()
    #             # ✅ 梯度裁剪（先 unscale）
    #             scaler.unscale_(optim)
    #             torch.nn.utils.clip_grad_norm_(model.parameters(), 5.0)
    #             scaler.step(optim)
    #             scaler.update()
    #         else:
    #             loss_dict = model(images, targets)
    #             loss = sum(loss_dict.values())
    #             loss.backward()
    #             torch.nn.utils.clip_grad_norm_(model.parameters(), 5.0)
    #             optim.step()

    #         loss_sum += float(loss.item())
    #         pbar.set_postfix(loss=float(loss.item()))

    #     # ✅ 每轮验证：自动找最佳阈值下的 F1
    #     bestm = evaluate_best_f1(model, val_loader, iou_thr=IOU_THR)
    #     print(f"[Epoch {epoch}] train_loss={loss_sum/len(train_loader):.6f}  "
    #           f"Val bestF1={bestm['F1']:.3f} @thr={bestm['thr']:.2f}  "
    #           f"P={bestm['P']:.3f} R={bestm['R']:.3f}")

    #     # 保存 checkpoint（每轮都保存，防止中断）
    #     torch.save({
    #         "epoch": epoch,
    #         "model": model.state_dict(),
    #         "optim": optim.state_dict(),
    #         "best_f1": best_f1,
    #         "best_thr": best_thr
    #     }, ckpt_path)

    #     # 保存 best
    #     if bestm["F1"] > best_f1:
    #         best_f1 = float(bestm["F1"])
    #         best_thr = float(bestm["thr"])
    #         torch.save(model.state_dict(), OUT_DIR / "best.pt")
    #         (OUT_DIR / "best_threshold.txt").write_text(f"{best_thr}\n", encoding="utf-8")
            # print(f"  -> saved best.pt (F1={best_f1:.3f}, thr={best_thr:.2f})")

    # ----------------------------
    # 测试：用 best.pt + best_thr
    # ----------------------------
    best_pt = OUT_DIR / "best.pt"
    if best_pt.exists():
        model.load_state_dict(torch.load(best_pt, map_location=DEVICE))

    thr_path = OUT_DIR / "best_threshold.txt"
    if thr_path.exists():
        best_thr = float(thr_path.read_text(encoding="utf-8").strip())

    test_metrics = evaluate_map50(model, test_loader, score_thr=best_thr, iou_thr=IOU_THR)
    print(f"[TEST] thr={best_thr:.2f}  P={test_metrics['P']:.3f} R={test_metrics['R']:.3f} F1={test_metrics['F1']:.3f}")

    test_and_save_vis(model, test_ds, OUT_DIR / "test_vis", score_thr=best_thr, max_images=50)
    print(f"Saved visualization to: {OUT_DIR/'test_vis'}")



if __name__ == "__main__":
    main()
