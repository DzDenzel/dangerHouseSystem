import os
import io
import cv2
import torch
import numpy as np
import uvicorn
import logging
import base64
from typing import List, Optional, Any, Annotated
from fastapi import FastAPI, File, UploadFile, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from contextlib import asynccontextmanager
from pathlib import Path
from sklearn.cluster import DBSCAN

from torchvision.models.detection import (
    fasterrcnn_resnet50_fpn_v2,
    FasterRCNN_ResNet50_FPN_V2_Weights
)
from torchvision.models.detection.faster_rcnn import FastRCNNPredictor

# ----------------------------
# 1) 配置常量与日志
# ----------------------------
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("DamageAPI")

WEIGHT_PATH = "./runs_detect/best.pt"
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

# 整体评估阈值 (与之前 api_server.py 逻辑保持一致)
BUILDING_B_LEVEL_CRACK_THRESHOLD = 3
BUILDING_C_LEVEL_CRACK_THRESHOLD = 6
BUILDING_D_LEVEL_CRACK_THRESHOLD = 10
BUILDING_B_LEVEL_RATIO_THRESHOLD = 5.0
BUILDING_C_LEVEL_RATIO_THRESHOLD = 15.0
BUILDING_D_LEVEL_RATIO_THRESHOLD = 30.0

# 模型单例容器
class ModelContainer:
    def __init__(self):
        self.model = None

container = ModelContainer()

# ----------------------------
# 2) Pydantic 数据模型 (适配 Java DTO)
# ----------------------------

class DetectionItem(BaseModel):
    id: int = Field(..., description="损伤ID")
    type: str = Field(..., description="损伤类型")
    typeName: str = Field(..., description="损伤类型中文描述")
    confidence: float = Field(..., description="置信度")
    bbox: List[int] = Field(..., description="[x1, y1, x2, y2]")
    center: List[int] = Field(..., description="[cx, cy]")
    width: int = Field(..., description="宽度")
    height: int = Field(..., description="高度")
    area: int = Field(..., description="面积")

class Analysis(BaseModel):
    severityLevel: str = Field(..., description="损伤等级 (A/B/C/D)")
    damageRatio: float = Field(..., description="损伤面积占比 (0-100)")
    crackCount: int = Field(..., description="裂缝数量")
    confidenceScore: float = Field(..., description="检测置信度")
    recommendation: str = Field(..., description="建议措施")

class ImageResult(BaseModel):
    filename: str = Field(..., description="文件名")
    detections: List[DetectionItem] = Field(..., description="该图检测到的损伤列表")
    resultImage: str = Field(..., description="该图的结果图 (Base64)")
    analysis: Analysis = Field(..., description="该图的分析结果")

class DataInfo(BaseModel):
    analysis: Analysis = Field(..., description="整体分析结果 (针对建筑整体)")
    detections: List[DetectionItem] = Field(..., description="所有图片检测到的损伤列表 (汇总)")
    imageResults: List[ImageResult] = Field(..., description="单图检测详情列表")
    resultImage: Optional[str] = Field(None, description="汇总结果图片 (Base64, 通常为第一张)")

class APIResponse(BaseModel):
    code: int
    message: str
    data: Optional[DataInfo] = None

# ----------------------------
# 3) 核心算法逻辑
# ----------------------------
def build_model(num_classes=2, detections_per_img=30, nms_thresh=0.3):
    weights = FasterRCNN_ResNet50_FPN_V2_Weights.DEFAULT
    model = fasterrcnn_resnet50_fpn_v2(weights=weights) #(weights=None，weights_backbone=None)不会走网络下载fastrrcnn
    in_features = model.roi_heads.box_predictor.cls_score.in_features
    model.roi_heads.box_predictor = FastRCNNPredictor(in_features, num_classes)
    model.roi_heads.detections_per_img = int(detections_per_img)
    model.roi_heads.nms_thresh = float(nms_thresh)
    return model

def load_model_instance(weight_path: str, device: str):
    wp = Path(weight_path)
    model = build_model(num_classes=2)
    if wp.exists():
        state = torch.load(str(wp), map_location=device)
        model.load_state_dict(state)
        logger.info(f"Loaded weights from {weight_path}")
    else:
        logger.warning(f"Weights not found at {weight_path}, using initial model.")
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

def get_recommendation(level: str) -> str:
    if level == "A": return "结构安全，无需处理"
    if level == "B": return "存在轻微损伤，建议定期观察"
    if level == "C": return "局部危房，建议修缮加固"
    if level == "D": return "整幢危房，建议立即停止使用并由专业机构鉴定"
    return "建议进一步检测"

def classify_risk_level(crack_count: int, damage_ratio: float) -> str:
    # Follow the documented thresholds and use the higher-risk dimension.
    if crack_count > BUILDING_D_LEVEL_CRACK_THRESHOLD or damage_ratio > BUILDING_D_LEVEL_RATIO_THRESHOLD:
        return "D"
    if crack_count >= BUILDING_C_LEVEL_CRACK_THRESHOLD or damage_ratio >= BUILDING_C_LEVEL_RATIO_THRESHOLD:
        return "C"
    if crack_count >= BUILDING_B_LEVEL_CRACK_THRESHOLD or damage_ratio >= BUILDING_B_LEVEL_RATIO_THRESHOLD:
        return "B"
    return "A"

def analyze_severity_v2(boxes: np.ndarray, scores: np.ndarray, img_width: int, img_height: int):
    crack_count = len(boxes)
    total_area = sum((x2 - x1) * (y2 - y1) for (x1, y1, x2, y2) in boxes)
    img_area = img_width * img_height
    damage_ratio = (total_area / img_area) * 100 if img_area > 0 else 0.0
    confidence_score = float(np.mean(scores) * 100) if len(scores) > 0 else 0.0
    level = classify_risk_level(crack_count, damage_ratio)

    return Analysis(
        severityLevel=level,
        damageRatio=float(round(damage_ratio, 2)),
        crackCount=int(crack_count),
        confidenceScore=float(round(confidence_score, 2)),
        recommendation=get_recommendation(level)
    )

def evaluate_building_risk(image_results: List[ImageResult], all_boxes: List[np.ndarray]):
    """整体风险评估算法 (DBSCAN 聚类)"""
    total_imgs = len(image_results)
    if total_imgs == 0:
        return Analysis(severityLevel="A", damageRatio=0.0, crackCount=0, confidenceScore=0.0, recommendation="无有效图片")

    # DBSCAN 空间去重
    centers = []
    for boxes in all_boxes:
        for (x1, y1, x2, y2) in boxes:
            centers.append([(x1 + x2) / 2, (y1 + y2) / 2])
    
    unique_clusters = 0
    if centers:
        clustering = DBSCAN(eps=50, min_samples=1).fit(centers)
        unique_clusters = len(set(clustering.labels_))
    
    max_ratio = max([r.analysis.damageRatio for r in image_results], default=0)
    avg_confidence = np.mean([r.analysis.confidenceScore for r in image_results])

    level = classify_risk_level(unique_clusters, max_ratio)

    return Analysis(
        severityLevel=level,
        damageRatio=float(round(max_ratio, 2)),
        crackCount=int(unique_clusters),
        confidenceScore=float(round(avg_confidence, 2)),
        recommendation=get_recommendation(level)
    )

def draw_boxes(img_bgr, boxes, scores):
    vis = img_bgr.copy()
    for box, score in zip(boxes, scores):
        x1, y1, x2, y2 = box
        cv2.rectangle(vis, (x1, y1), (x2, y2), (0, 0, 255), 2)
        cv2.putText(vis, f"{score:.2f}", (x1, max(0, y1 - 10)), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 2)
    return vis

def encode_image_to_base64(img_bgr):
    _, buffer = cv2.imencode('.jpg', img_bgr)
    return base64.b64encode(buffer).decode('utf-8')

# ----------------------------
# 4) FastAPI 生命周期管理
# ----------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info(f"正在加载模型，设备: {DEVICE}...")
    container.model = load_model_instance(WEIGHT_PATH, DEVICE)
    logger.info("模型加载完成 ✅")
    yield
    if container.model:
        del container.model
        torch.cuda.empty_cache()

app = FastAPI(title="Building Damage Detection API", version="2.1.0", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

# ----------------------------
# 5) API 接口实现
# ----------------------------
@app.post("/api/v1/detect_damage", response_model=APIResponse)
async def detect_damage(
    images: Annotated[List[UploadFile], File(description="上传的图片文件列表")],
    score_thr: Annotated[float, Query(ge=0.0, le=1.0)] = 0.3
):
    if container.model is None: raise HTTPException(status_code=503, detail="Model not loaded.")
    
    logger.info(f"Batch request with {len(images)} files. score_thr={score_thr}")
    
    all_image_results = []
    all_boxes_list = []
    all_detections_summary = []
    
    for img_file in images:
        try:
            contents = await img_file.read()
            nparr = np.frombuffer(contents, np.uint8)
            img_bgr = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            if img_bgr is None: continue

            h, w = img_bgr.shape[:2]
            boxes, scores = predict_image(container.model, img_bgr, DEVICE, score_thr)
            analysis = analyze_severity_v2(boxes, scores, w, h)
            
            image_detections = []
            for i, (box, score) in enumerate(zip(boxes, scores)):
                x1, y1, x2, y2 = map(int, box)
                det_item = DetectionItem(
                    id=len(all_detections_summary) + 1, type="crack", typeName="裂缝", confidence=float(score),
                    bbox=[x1, y1, x2, y2], center=[(x1 + x2) // 2, (y1 + y2) // 2],
                    width=x2 - x1, height=y2 - y1, area=(x2 - x1) * (y2 - y1)
                )
                image_detections.append(det_item)
                all_detections_summary.append(det_item)

            result_img_base64 = encode_image_to_base64(draw_boxes(img_bgr, boxes, scores))
            
            img_res = ImageResult(
                filename=img_file.filename, detections=image_detections,
                resultImage=result_img_base64, analysis=analysis
            )
            all_image_results.append(img_res)
            all_boxes_list.append(boxes)

        except Exception as e:
            logger.error(f"Error processing {img_file.filename}: {e}")

    # 整体评估
    building_analysis = evaluate_building_risk(all_image_results, all_boxes_list)
    
    data_info = DataInfo(
        analysis=building_analysis,
        detections=all_detections_summary,
        imageResults=all_image_results,
        resultImage=all_image_results[0].resultImage if all_image_results else None
    )

    return APIResponse(code=200, message="操作成功", data=data_info)

if __name__ == "__main__":
    uvicorn.run("api_server:app", host="0.0.0.0", port=8000, reload=True)
