# 危房智能检测系统

危房智能检测系统包含移动端、管理后台、Java 后端和 AI 检测服务。系统支持建筑档案管理、现场检测、AI 裂缝识别、风险评级、检测报告和后台管理。

## 服务目录

| 目录 | 技术栈 | 默认端口 | 说明 |
| --- | --- | --- | --- |
| `dangerhouse-backend` | Spring Boot 3.2、Java 17、MyBatis-Plus、Redis | `8080` | 主业务接口、鉴权、缓存、数据持久化和 AI 服务调用 |
| `dangerhouse-admin-web` | Vue 3、TypeScript、Element Plus、Vite | `3000` | 管理员 Web 后台 |
| `dangerhouse-mobile-app` | Flutter、Dart、Riverpod、Dio | 由运行平台决定 | 用户和检测员移动端 |
| `dangerhouse-ai-service` | FastAPI、PyTorch、Faster R-CNN | `8000` | 建筑损伤图像检测与风险分析 |

## 运行依赖

- JDK 17
- MySQL 8.0+
- Redis
- Node.js 18+ 与 pnpm
- Flutter SDK 3.2+
- Python 3.10+

## 本地启动

1. 初始化数据库：

   ```powershell
   mysql -u root -p < dangerhouse-backend/sql/dangerhouse_v3.0_with_data.sql
   ```

2. 启动 AI 服务。模型文件需要保存在本地 `dangerhouse-ai-service/runs_detect/best.pt`：

   ```powershell
   cd dangerhouse-ai-service
   python -m venv .venv
   .\.venv\Scripts\pip install -r requirements.txt
   .\.venv\Scripts\python -m uvicorn api_server:app --host 0.0.0.0 --port 8000
   ```

3. 启动 Java 后端：

   ```powershell
   cd dangerhouse-backend
   .\mvnw.cmd spring-boot:run
   ```

4. 启动管理后台：

   ```powershell
   cd dangerhouse-admin-web
   pnpm install
   pnpm dev
   ```

5. 启动移动端：

   ```powershell
   cd dangerhouse-mobile-app
   flutter pub get
   flutter run
   ```

后端 Swagger 页面：`http://localhost:8080/swagger-ui.html`

详细架构请查看 [危房智诊系统架构图.md](./危房智诊系统架构图.md)。
