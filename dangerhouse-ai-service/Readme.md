<div align="center">

# 🏠 危房智能检测系统

**Dangerous House Intelligent Detection System — AI 检测服务**

[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=flat-square&logo=python&logoColor=white)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688?style=flat-square&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![PyTorch](https://img.shields.io/badge/PyTorch-2.x-EE4C2C?style=flat-square&logo=pytorch&logoColor=white)](https://pytorch.org/)
[![OpenCV](https://img.shields.io/badge/OpenCV-4.8+-5C3EE8?style=flat-square&logo=opencv&logoColor=white)](https://opencv.org/)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](../dangerhouse-admin-web/LICENSE)
[![Version](https://img.shields.io/badge/Version-v2.1.0-orange?style=flat-square)](#-版本历史)

**基于 Faster R-CNN 的建筑裂缝检测与多图风险评级推理服务**

[项目简介](#-项目简介) • [核心能力](#-核心能力) • [技术架构](#-技术架构) • [快速开始](#-快速开始) • [接口说明](#-接口说明) • [版本历史](#-版本历史)

</div>

---

> **当前版本**：v2.1.0（API）  
> **文档更新**：2026-06-04

## 📋 目录

- [项目简介](#-项目简介)
- [核心能力](#-核心能力)
- [技术架构](#-技术架构)
- [技术栈](#-技术栈)
- [快速开始](#-快速开始)
- [项目结构](#-项目结构)
- [核心设计](#-核心设计)
- [接口说明](#-接口说明)
- [配置说明](#-配置说明)
- [训练与本地调试](#-训练与本地调试)
- [部署说明](#-部署说明)
- [常见问题](#-常见问题)
- [贡献指南](#-贡献指南)
- [版本历史](#-版本历史)
- [许可证](#-许可证)

---

## 📖 项目简介

`dangerhouse-ai-service` 是危房智能检测系统的 **AI 推理子服务**，基于 **FastAPI** 与 **PyTorch** 提供 HTTP 接口。后端 Java 服务通过 Multipart 上传图片调用本服务，获取裂缝检测框、标注结果图（Base64）以及 A/B/C/D 风险等级评估。

### 系统定位

```
管理端 / 移动端
       │
       │ REST + JWT
       ▼
Spring Boot 后端 ──Multipart HTTP──► FastAPI AI 服务 (本项目)
       │                                    │
       │                                    ├── Faster R-CNN 推理
       │                                    ├── DBSCAN 多图去重
       │                                    └── 风险等级评估
       ▼
MySQL / Redis / 文件存储
```

### 核心价值

| 维度 | 说明 |
| :--- | :--- |
| **标准对接** | 响应结构与 Java `AiDetectionResponse` DTO 对齐，便于后端直接反序列化 |
| **多图联合** | 单请求支持多张图片，汇总检测并做建筑级整体评估 |
| **空间去重** | 多图场景使用 DBSCAN 对检测中心聚类，降低重复计数 |
| **可本地调试** | 提供 PyQt6 桌面工具与训练脚本，支持离线验证与模型迭代 |

---

## ✨ 核心能力

| 模块 | 能力 |
| :--- | :--- |
| **裂缝检测** | Faster R-CNN ResNet50 FPN v2，输出 bbox、置信度与标注图 |
| **单图分析** | 裂缝数量、损伤面积占比、平均置信度、A/B/C/D 等级与处置建议 |
| **多图评估** | 跨图 DBSCAN 去重 + 最大损伤占比，生成建筑整体风险结论 |
| **结果可视化** | 检测框绘制后编码为 JPEG Base64 返回 |
| **桌面调试** | `damage_detector_qt.py` 支持本地选图、调阈值、查看结果 |
| **模型训练** | `run_dectect.py` 支持 HRCDS 数据集训练并导出 `best.pt` |

---

## 🏗️ 技术架构

### 推理流程

```
上传图片列表 (multipart)
  → OpenCV 解码
  → Faster R-CNN 前向推理 (score_thr 过滤)
  → 单图：裂缝统计 + 损伤占比 + 等级判定
  → 多图：DBSCAN 中心聚类去重
  → 建筑级 Analysis 汇总
  → 绘制标注框 → Base64
  → APIResponse { code, message, data }
```

### 风险等级规则

单图与建筑整体均按 **裂缝数量** 与 **损伤面积占比（%）** 取较高风险维度判定：

| 等级 | 裂缝数条件 | 损伤占比条件 |
| :--- | :--- | :--- |
| **A** | 低于 B 级阈值 | 低于 B 级阈值 |
| **B** | ≥ 3 | ≥ 5% |
| **C** | ≥ 6 | ≥ 15% |
| **D** | > 10 | > 30% |

处置建议示例：A 无需处理；B 定期观察；C 建议修缮加固；D 建议立即停用并由专业机构鉴定。

---

## 🛠️ 技术栈

| 分类 | 技术 | 说明 |
| :--- | :--- | :--- |
| **Web 框架** | FastAPI + Uvicorn | HTTP 服务与异步生命周期 |
| **深度学习** | PyTorch + Torchvision | Faster R-CNN 推理 |
| **图像处理** | OpenCV | 编解码、绘制检测框 |
| **聚类** | scikit-learn DBSCAN | 多图检测中心去重 |
| **桌面工具** | PyQt6 | 本地可视化调试 |
| **数据校验** | Pydantic v2 | 响应模型与 Java DTO 对齐 |

---

## 🚀 快速开始

### 环境要求

| 依赖 | 版本要求 | 说明 |
| :--- | :--- | :--- |
| **Python** | 3.10+ | 推荐 3.10 或 3.11 |
| **CUDA** | 可选 | 有 NVIDIA GPU 时自动使用 `cuda` |
| **模型权重** | `runs_detect/best.pt` | 需自行训练或放置权重文件 |

### 安装步骤

```bash
# 1. 克隆项目
git clone https://github.com/DzDenzel/dangerHouseSystem.git

# 2. 进入 AI 服务目录
cd dangerHouseSystem/dangerhouse-ai-service

# 3. 创建虚拟环境并安装依赖
python -m venv .venv

# Windows
.\.venv\Scripts\pip install -r requirements.txt

# Linux / macOS
source .venv/bin/activate
pip install -r requirements.txt

# 4. 准备模型权重（必须）
# 将训练好的 best.pt 放到 runs_detect/best.pt

# 5. 启动 API 服务
# Windows
.\.venv\Scripts\python -m uvicorn api_server:app --host 0.0.0.0 --port 8000

# Linux / macOS
python -m uvicorn api_server:app --host 0.0.0.0 --port 8000
```

启动成功后：

| 地址 | 用途 |
| :--- | :--- |
| `http://localhost:8000/docs` | Swagger UI |
| `http://localhost:8000/api/v1/detect_damage` | 损伤检测接口 |

后端需在 `application.yml` 中配置：

```yaml
ai:
  detection:
    url: http://127.0.0.1:8000/api/v1/detect_damage
```

---

## 📁 项目结构

```
dangerhouse-ai-service/
├── api_server.py           # FastAPI 推理服务（生产入口）
├── run_dectect.py          # 模型训练脚本（HRCDS 数据集）
├── damage_detector_qt.py   # PyQt6 本地调试工具
├── requirements.txt        # Python 依赖
├── runs_detect/            # 训练输出目录（需 best.pt）
│   └── best.pt             # 模型权重（需自行准备）
└── .gitignore
```

> `runs_detect/best.pt` 与数据集目录体积较大，默认不纳入 Git 版本管理。

---

## 📐 核心设计

### 模型加载

- 应用启动时通过 FastAPI `lifespan` 加载模型单例到 `ModelContainer`。
- 默认权重路径：`./runs_detect/best.pt`；文件不存在时使用预训练骨架并记录警告。
- 设备自动选择：`cuda` 可用时用 GPU，否则 `cpu`。

### 与后端对接

- Java `AiDetectionClient` 以 Multipart 形式上传，字段名为 **`images`**（可多文件）。
- 响应顶层为 `{ code, message, data }`，`data` 内含 `analysis`、`detections`、`imageResults`、`resultImage`。
- 后端 `DetectionAiClientService` 负责校验响应、持久化结果并保存结果图。

### 训练脚本说明

`run_dectect.py` 面向 HRCDS 裂缝数据集：

- 默认数据根目录：`./HRCDS`
- 训练输出：`./runs_detect/best.pt`
- 可配置 epoch、batch size、学习率等（见脚本顶部常量）

---

## 📡 接口说明

### 损伤检测

| 项目 | 说明 |
| :--- | :--- |
| **路径** | `POST /api/v1/detect_damage` |
| **Content-Type** | `multipart/form-data` |
| **字段** | `images`：图片文件列表（必填） |
| **查询参数** | `score_thr`：置信度阈值，默认 `0.3`，范围 `0.0 ~ 1.0` |

### 响应示例（结构）

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "analysis": {
      "severityLevel": "B",
      "damageRatio": 8.5,
      "crackCount": 4,
      "confidenceScore": 87.2,
      "recommendation": "存在轻微损伤，建议定期观察"
    },
    "detections": [],
    "imageResults": [],
    "resultImage": "<base64>"
  }
}
```

### 错误码

| HTTP 状态 | 场景 |
| :--- | :--- |
| `503` | 模型尚未加载完成 |
| `422` | 请求参数校验失败 |

---

## ⚙️ 配置说明

主要常量定义在 `api_server.py` 顶部，可按环境调整：

| 常量 | 默认值 | 说明 |
| :--- | :--- | :--- |
| `WEIGHT_PATH` | `./runs_detect/best.pt` | 模型权重路径 |
| `DEVICE` | 自动 | `cuda` / `cpu` |
| `BUILDING_B_LEVEL_CRACK_THRESHOLD` | 3 | B 级裂缝阈值 |
| `BUILDING_C_LEVEL_CRACK_THRESHOLD` | 6 | C 级裂缝阈值 |
| `BUILDING_D_LEVEL_CRACK_THRESHOLD` | 10 | D 级裂缝阈值 |
| `BUILDING_B_LEVEL_RATIO_THRESHOLD` | 5.0 | B 级损伤占比（%） |
| `BUILDING_C_LEVEL_RATIO_THRESHOLD` | 15.0 | C 级损伤占比（%） |
| `BUILDING_D_LEVEL_RATIO_THRESHOLD` | 30.0 | D 级损伤占比（%） |

DBSCAN 聚类参数：`eps=50`，`min_samples=1`（多图建筑级评估）。

---

## 🧪 训练与本地调试

### 训练模型

```bash
# 将 HRCDS 数据集放到 ./HRCDS 后执行
python run_dectect.py
```

训练完成后权重输出至 `runs_detect/best.pt`。

### PyQt 桌面调试

```bash
python damage_detector_qt.py
```

支持本地选图、调整置信度阈值、查看检测框与评分，适合算法验证，不经过 HTTP。

---

## 🚢 部署说明

1. 在 GPU 服务器安装 CUDA 对应版本的 PyTorch（如需 GPU 推理）。
2. 将 `best.pt` 部署到 `runs_detect/` 目录。
3. 使用 Uvicorn 或 Gunicorn + Uvicorn Worker 启动，建议置于内网，仅允许后端访问。
4. 配置进程守护（systemd / Docker）与健康检查。
5. 后端 `ai.detection.url` 指向实际服务地址；生产环境使用 HTTPS 或专线。

**Docker 思路（示例）：**

```dockerfile
# 需自行编写 Dockerfile：基于 python:3.10，COPY 权重与代码，EXPOSE 8000
CMD ["uvicorn", "api_server:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## ❓ 常见问题

### Q: 启动后提示 Model not loaded？

**A:** 检查 `runs_detect/best.pt` 是否存在；查看启动日志中模型加载是否报错。

### Q: 使用 CPU 推理很慢？

**A:** 安装 CUDA 版 PyTorch 并在有 GPU 的机器上部署；或降低图片分辨率与批量大小。

### Q: 后端调用 AI 失败？

**A:** 确认 AI 服务已监听 `8000` 端口，后端 `ai.detection.url` 与网络可达；多张图片字段名必须为 `images`。

### Q: 权重文件不存在时仍能启动？

**A:** 会使用未加载自定义权重的初始模型，检测效果不可靠，生产环境必须提供 `best.pt`。

### Q: 如何调整检测灵敏度？

**A:** 请求时传入 `score_thr` 查询参数，或在 `damage_detector_qt.py` 中交互调整。

---

## 🤝 贡献指南

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/ai-improvement`)
3. 提交更改并附测试说明
4. 提交 Pull Request

算法改动请同步更新本文档中的阈值说明与版本历史。

---

## 📅 版本历史

### v2.1.0

**本次技术增量更新：**

- ✅ 基于 Faster R-CNN ResNet50 FPN v2 的目标检测推理服务
- ✅ 多图上传与 `imageResults` 单图明细返回
- ✅ DBSCAN 多图空间聚类去重，建筑级整体风险评估
- ✅ 响应模型与 Java `AiDetectionResponse` 字段对齐
- ✅ 启动生命周期加载模型单例，支持 CUDA 自动切换
- ✅ 提供 PyQt6 本地调试工具与 HRCDS 训练脚本

### v2.0.x 及更早

- 单图裂缝检测与损伤占比评估
- 风险等级 A/B/C/D 规则引擎
- Base64 标注图返回

---

## 📄 许可证

本项目基于 [MIT License](../dangerhouse-admin-web/LICENSE) 开源协议发布（与 monorepo 其他子项目保持一致）。

---

## 📞 联系方式

- 🐛 Issue：[GitHub Issues](https://github.com/DzDenzel/dangerHouseSystem/issues)
- 📖 关联文档：[后端 README](../dangerhouse-backend/Readme.md) · [管理端 README](../dangerhouse-admin-web/README.md) · [移动端 README](../dangerhouse-mobile-app/Readme.md)

---

<div align="center">

**⭐ 如果这个项目对你有帮助，请给一个 Star 支持一下！⭐**

Made with ❤️ by Danger House Team

**让危房检测更智能、更高效**

</div>
