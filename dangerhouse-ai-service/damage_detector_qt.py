import sys
import json
from pathlib import Path

import numpy as np
import cv2
import torch

from PyQt6.QtCore import Qt
from PyQt6.QtGui import QPixmap, QImage, QAction
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QLabel, QPushButton, QFileDialog,
    QVBoxLayout, QHBoxLayout, QSlider, QSpinBox, QDoubleSpinBox, QMessageBox,
    QSplitter, QGroupBox, QFormLayout, QLineEdit
)

from torchvision.models.detection import (
    fasterrcnn_resnet50_fpn_v2,
    FasterRCNN_ResNet50_FPN_V2_Weights
)
from torchvision.models.detection.faster_rcnn import FastRCNNPredictor


# -------------------------
# 1) 模型构建 / 推理
# -------------------------
def build_model(num_classes=2, detections_per_img=30, nms_thresh=0.3):
    weights = FasterRCNN_ResNet50_FPN_V2_Weights.DEFAULT
    model = fasterrcnn_resnet50_fpn_v2(weights=weights)
    in_features = model.roi_heads.box_predictor.cls_score.in_features
    model.roi_heads.box_predictor = FastRCNNPredictor(in_features, num_classes)

    # 推理控制：减少每图输出框、抑制重叠框
    try:
        model.roi_heads.detections_per_img = int(detections_per_img)
        model.roi_heads.nms_thresh = float(nms_thresh)
    except Exception:
        pass

    return model


def load_model(weight_path: str, device: str, detections_per_img=30, nms_thresh=0.3):
    wp = Path(weight_path)
    if not wp.exists():
        raise FileNotFoundError(f"找不到权重文件：{wp}")

    model = build_model(num_classes=2, detections_per_img=detections_per_img, nms_thresh=nms_thresh)
    state = torch.load(str(wp), map_location=device)
    model.load_state_dict(state)
    model.to(device).eval()
    return model


@torch.no_grad()
def predict_image(model, img_bgr: np.ndarray, device: str, score_thr: float):
    img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
    img_t = torch.from_numpy(img_rgb).permute(2, 0, 1).float() / 255.0
    out = model([img_t.to(device)])[0]

    boxes = out["boxes"].detach().cpu().numpy()
    scores = out["scores"].detach().cpu().numpy()

    keep = scores >= float(score_thr)
    boxes = boxes[keep].astype(int)
    scores = scores[keep].astype(float)
    return boxes, scores


def draw_boxes(img_bgr: np.ndarray, boxes: np.ndarray, scores: np.ndarray, label="damage"):
    vis = img_bgr.copy()
    for (x1, y1, x2, y2), s in zip(boxes, scores):
        cv2.rectangle(vis, (int(x1), int(y1)), (int(x2), int(y2)), (0, 255, 0), 2)
        cv2.putText(
            vis, f"{label} {s:.2f}",
            (int(x1), max(0, int(y1) - 6)),
            cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2
        )
    return vis


def result_json(filename: str, boxes: np.ndarray, scores: np.ndarray):
    return {
        "file": filename,
        "detections": [
            {"box": [int(x1), int(y1), int(x2), int(y2)], "score": float(s)}
            for (x1, y1, x2, y2), s in zip(boxes, scores)
        ]
    }


def cv_to_qpixmap(img_bgr: np.ndarray, max_w=900, max_h=700) -> QPixmap:
    """OpenCV BGR -> QPixmap (自动等比缩放)"""
    rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
    h, w, ch = rgb.shape
    bytes_per_line = ch * w
    qimg = QImage(rgb.data, w, h, bytes_per_line, QImage.Format.Format_RGB888)
    pix = QPixmap.fromImage(qimg)

    # 等比缩放
    if pix.width() > max_w or pix.height() > max_h:
        pix = pix.scaled(max_w, max_h, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation)
    return pix


def list_images_in_folder(folder: Path):
    exts = {".jpg", ".jpeg", ".png", ".bmp"}
    return sorted([p for p in folder.iterdir() if p.is_file() and p.suffix.lower() in exts])


# -------------------------
# 2) PyQt6 主界面
# -------------------------
class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("建筑损伤 / 裂缝检测软件（PyQt）")
        self.resize(1300, 800)

        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.model = None
        self.weight_path = ""
        self.current_image_path = None
        self.current_img_bgr = None
        self.current_vis_bgr = None
        self.current_result = None

        self._build_ui()
        self._build_menu()

    def _build_menu(self):
        menu = self.menuBar()
        file_menu = menu.addMenu("文件")

        act_load = QAction("加载模型(best.pt)", self)
        act_load.triggered.connect(self.on_load_model)
        file_menu.addAction(act_load)

        act_open = QAction("打开图片", self)
        act_open.triggered.connect(self.on_open_image)
        file_menu.addAction(act_open)

        act_folder = QAction("批量处理文件夹", self)
        act_folder.triggered.connect(self.on_batch_folder)
        file_menu.addAction(act_folder)

        file_menu.addSeparator()

        act_save_img = QAction("保存当前标注图", self)
        act_save_img.triggered.connect(self.on_save_vis)
        file_menu.addAction(act_save_img)

        act_save_json = QAction("导出当前JSON", self)
        act_save_json.triggered.connect(self.on_save_json)
        file_menu.addAction(act_save_json)

        file_menu.addSeparator()

        act_exit = QAction("退出", self)
        act_exit.triggered.connect(self.close)
        file_menu.addAction(act_exit)

    def _build_ui(self):
        root = QWidget()
        self.setCentralWidget(root)

        # 左侧控制面板
        left = QWidget()
        left_layout = QVBoxLayout(left)

        gb = QGroupBox("设置")
        form = QFormLayout(gb)

        self.lbl_device = QLabel(f"{self.device}")
        form.addRow("设备", self.lbl_device)

        self.ed_weight = QLineEdit()
        self.ed_weight.setPlaceholderText("选择 best.pt 路径…")
        form.addRow("权重路径", self.ed_weight)

        self.btn_load = QPushButton("加载模型")
        self.btn_load.clicked.connect(self.on_load_model)
        form.addRow(self.btn_load)

        self.ed_label = QLineEdit("damage")
        form.addRow("标签显示", self.ed_label)

        self.slider_thr = QSlider(Qt.Orientation.Horizontal)
        self.slider_thr.setMinimum(0)
        self.slider_thr.setMaximum(100)
        self.slider_thr.setValue(50)
        self.slider_thr.valueChanged.connect(self.on_thr_changed)
        self.lbl_thr = QLabel("0.50")
        thr_row = QHBoxLayout()
        thr_row.addWidget(self.slider_thr, 1)
        thr_row.addWidget(self.lbl_thr)
        form.addRow("阈值", thr_row)

        self.spin_det = QSpinBox()
        self.spin_det.setRange(1, 200)
        self.spin_det.setValue(30)
        form.addRow("每图最多框", self.spin_det)

        self.spin_nms = QDoubleSpinBox()
        self.spin_nms.setRange(0.10, 0.90)
        self.spin_nms.setSingleStep(0.05)
        self.spin_nms.setValue(0.30)
        form.addRow("NMS阈值", self.spin_nms)

        self.btn_open = QPushButton("打开图片")
        self.btn_open.clicked.connect(self.on_open_image)
        form.addRow(self.btn_open)

        self.btn_batch = QPushButton("批量处理文件夹")
        self.btn_batch.clicked.connect(self.on_batch_folder)
        form.addRow(self.btn_batch)

        self.btn_save_vis = QPushButton("保存当前标注图")
        self.btn_save_vis.clicked.connect(self.on_save_vis)
        form.addRow(self.btn_save_vis)

        self.btn_save_json = QPushButton("导出当前JSON")
        self.btn_save_json.clicked.connect(self.on_save_json)
        form.addRow(self.btn_save_json)

        left_layout.addWidget(gb)

        self.lbl_status = QLabel("未加载模型。")
        self.lbl_status.setWordWrap(True)
        left_layout.addWidget(self.lbl_status)
        left_layout.addStretch(1)

        # 右侧图像显示区
        right = QWidget()
        right_layout = QHBoxLayout(right)

        self.lbl_img = QLabel("原图")
        self.lbl_img.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.lbl_img.setStyleSheet("background:#111; color:#ddd;")
        self.lbl_img.setMinimumWidth(500)

        self.lbl_vis = QLabel("检测结果")
        self.lbl_vis.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.lbl_vis.setStyleSheet("background:#111; color:#ddd;")
        self.lbl_vis.setMinimumWidth(500)

        right_layout.addWidget(self.lbl_img, 1)
        right_layout.addWidget(self.lbl_vis, 1)

        splitter = QSplitter(Qt.Orientation.Horizontal)
        splitter.addWidget(left)
        splitter.addWidget(right)
        splitter.setStretchFactor(0, 0)
        splitter.setStretchFactor(1, 1)

        layout = QVBoxLayout(root)
        layout.addWidget(splitter)

        # 初始状态
        self.btn_open.setEnabled(False)
        self.btn_batch.setEnabled(False)
        self.btn_save_vis.setEnabled(False)
        self.btn_save_json.setEnabled(False)

    def score_thr(self) -> float:
        return self.slider_thr.value() / 100.0

    def on_thr_changed(self):
        self.lbl_thr.setText(f"{self.score_thr():.2f}")
        # 如果已有图，阈值变化后直接重跑显示
        if self.model is not None and self.current_img_bgr is not None:
            self.run_infer_and_show()

    def on_load_model(self):
        # 若输入框为空，则弹窗选择
        path = self.ed_weight.text().strip()
        if not path:
            p, _ = QFileDialog.getOpenFileName(self, "选择 best.pt", "", "PyTorch Weights (*.pt *.pth);;All Files (*)")
            if not p:
                return
            path = p
            self.ed_weight.setText(path)

        try:
            self.set_status("正在加载模型…")
            self.model = load_model(
                path, device=self.device,
                detections_per_img=self.spin_det.value(),
                nms_thresh=self.spin_nms.value()
            )
            self.weight_path = path
            self.set_status(f"模型加载成功 ✅\n权重：{path}\n设备：{self.device}")
            self.btn_open.setEnabled(True)
            self.btn_batch.setEnabled(True)
        except Exception as e:
            self.model = None
            self.set_status(f"模型加载失败 ❌\n{e}")
            QMessageBox.critical(self, "加载失败", str(e))

    def on_open_image(self):
        if self.model is None:
            QMessageBox.warning(self, "提示", "请先加载模型。")
            return
        p, _ = QFileDialog.getOpenFileName(self, "选择图片", "", "Images (*.jpg *.jpeg *.png *.bmp)")
        if not p:
            return
        self.current_image_path = p
        img = cv2.imread(p)
        if img is None:
            QMessageBox.critical(self, "错误", f"读取失败：{p}")
            return
        self.current_img_bgr = img
        self.show_images(img, None)
        self.run_infer_and_show()

    def run_infer_and_show(self):
        if self.model is None or self.current_img_bgr is None:
            return
        label = self.ed_label.text().strip() or "damage"

        try:
            boxes, scores = predict_image(self.model, self.current_img_bgr, self.device, self.score_thr())
            vis = draw_boxes(self.current_img_bgr, boxes, scores, label=label)
            self.current_vis_bgr = vis
            fname = Path(self.current_image_path).name if self.current_image_path else "image"
            self.current_result = result_json(fname, boxes, scores)

            self.show_images(self.current_img_bgr, vis)
            self.btn_save_vis.setEnabled(True)
            self.btn_save_json.setEnabled(True)

            self.set_status(
                f"检测完成 ✅\n"
                f"图片：{fname}\n"
                f"阈值：{self.score_thr():.2f}\n"
                f"框数量：{len(scores)}"
            )
        except Exception as e:
            self.set_status(f"推理失败 ❌\n{e}")
            QMessageBox.critical(self, "推理失败", str(e))

    def on_save_vis(self):
        if self.current_vis_bgr is None:
            QMessageBox.information(self, "提示", "没有可保存的标注图。")
            return
        p, _ = QFileDialog.getSaveFileName(self, "保存标注图", "vis.jpg", "JPEG (*.jpg);;PNG (*.png)")
        if not p:
            return
        ok = cv2.imwrite(p, self.current_vis_bgr)
        if ok:
            QMessageBox.information(self, "成功", f"已保存：{p}")
        else:
            QMessageBox.critical(self, "失败", "保存失败。")

    def on_save_json(self):
        if self.current_result is None:
            QMessageBox.information(self, "提示", "没有可导出的JSON。")
            return
        p, _ = QFileDialog.getSaveFileName(self, "导出JSON", "result.json", "JSON (*.json)")
        if not p:
            return
        Path(p).write_text(json.dumps(self.current_result, ensure_ascii=False, indent=2), encoding="utf-8")
        QMessageBox.information(self, "成功", f"已导出：{p}")

    def on_batch_folder(self):
        if self.model is None:
            QMessageBox.warning(self, "提示", "请先加载模型。")
            return

        folder = QFileDialog.getExistingDirectory(self, "选择包含图片的文件夹")
        if not folder:
            return
        folder = Path(folder)
        imgs = list_images_in_folder(folder)
        if not imgs:
            QMessageBox.information(self, "提示", "该文件夹内没有图片(jpg/png/bmp)。")
            return

        out_dir = folder / "detect_out"
        out_dir.mkdir(parents=True, exist_ok=True)
        vis_dir = out_dir / "vis"
        json_dir = out_dir / "json"
        vis_dir.mkdir(exist_ok=True)
        json_dir.mkdir(exist_ok=True)

        label = self.ed_label.text().strip() or "damage"
        thr = self.score_thr()

        self.set_status(f"批量处理中…\n输入：{folder}\n输出：{out_dir}\n阈值：{thr:.2f}")
        QApplication.processEvents()

        summary = []
        for p in imgs:
            img = cv2.imread(str(p))
            if img is None:
                continue
            boxes, scores = predict_image(self.model, img, self.device, thr)
            vis = draw_boxes(img, boxes, scores, label=label)

            rj = result_json(p.name, boxes, scores)
            (json_dir / f"{p.stem}.json").write_text(json.dumps(rj, ensure_ascii=False, indent=2), encoding="utf-8")
            cv2.imwrite(str(vis_dir / f"{p.stem}_vis.jpg"), vis)

            summary.append({"file": p.name, "num_boxes": int(len(scores))})

        (out_dir / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
        self.set_status(f"批量完成 ✅\n共处理：{len(summary)} 张\n输出目录：{out_dir}")
        QMessageBox.information(self, "完成", f"批量处理完成！\n输出目录：{out_dir}")

    def show_images(self, img_bgr, vis_bgr):
        self.lbl_img.setPixmap(cv_to_qpixmap(img_bgr))
        if vis_bgr is None:
            self.lbl_vis.setText("检测结果")
            self.lbl_vis.setPixmap(QPixmap())
        else:
            self.lbl_vis.setPixmap(cv_to_qpixmap(vis_bgr))

    def set_status(self, s: str):
        self.lbl_status.setText(s)


def main():
    app = QApplication(sys.argv)
    w = MainWindow()
    w.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
