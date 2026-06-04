# 危房智能检测系统

危房智能检测系统是一套面向建筑安全监管的全链路解决方案，包含 **管理端 Web**、**移动端 App**、**Java 后端** 与 **Python AI 检测服务**。系统支持建筑档案管理、现场多图检测、AI 裂缝识别、A/B/C/D 风险评级、检测报告与后台运维管理。

## 服务目录

| 目录 | 技术栈 | 默认端口 | 说明 | 文档 |
| :--- | :--- | :--- | :--- | :--- |
| `dangerhouse-backend` | Spring Boot 3.2、Java 17、MyBatis-Plus、Redis | `8080` | 主业务 API、鉴权、缓存、持久化 | [Readme](./dangerhouse-backend/Readme.md) |
| `dangerhouse-admin-web` | Vue 3、TypeScript、Element Plus、Vite | `3000` | 管理员 Web 后台 | [README](./dangerhouse-admin-web/README.md) |
| `dangerhouse-mobile-app` | Flutter、Dart、Riverpod、Dio | 平台相关 | 用户与检测员移动端 | [Readme](./dangerhouse-mobile-app/Readme.md) |
| `dangerhouse-ai-service` | FastAPI、PyTorch、Faster R-CNN | `8000` | 建筑损伤图像检测与风险分析 | [Readme](./dangerhouse-ai-service/Readme.md) |

## 运行依赖

- JDK 17
- MySQL 8.0+
- Redis 6.0+
- Node.js 18+ 与 pnpm（管理端）
- Flutter SDK 3.2+（移动端）
- Python 3.10+（AI 服务，可选 GPU）

## 本地启动

按以下顺序启动各服务：

### 1. 初始化数据库

```powershell
mysql -u root -p < dangerhouse-backend/sql/dangerhouse_v3.0_with_data.sql
```

### 2. 启动 AI 服务

模型权重需放在 `dangerhouse-ai-service/runs_detect/best.pt`：

```powershell
cd dangerhouse-ai-service
python -m venv .venv
.\.venv\Scripts\pip install -r requirements.txt
.\.venv\Scripts\python -m uvicorn api_server:app --host 0.0.0.0 --port 8000
```

### 3. 启动 Java 后端

```powershell
cd dangerhouse-backend
.\mvnw.cmd spring-boot:run
```

Swagger：`http://localhost:8080/swagger-ui.html`

### 4. 启动管理后台

```powershell
cd dangerhouse-admin-web
pnpm install
pnpm run dev
```

访问：`http://localhost:3000`

### 5. 启动移动端

```powershell
cd dangerhouse-mobile-app
flutter pub get
flutter run
```

## 架构说明

详细架构请查看 [危房智诊系统架构图.md](./危房智诊系统架构图.md)。

各子项目 README 包含完整的功能说明、配置项、部署方式与版本历史。
