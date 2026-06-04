<div align="center">

# 🏠 危房智能检测系统

**Dangerous House Intelligent Detection System — 后端服务**

[![Java](https://img.shields.io/badge/Java-17-ED8B00?style=flat-square&logo=openjdk&logoColor=white)](https://openjdk.org/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.2.0-6DB33F?style=flat-square&logo=springboot&logoColor=white)](https://spring.io/projects/spring-boot)
[![MyBatis-Plus](https://img.shields.io/badge/MyBatis--Plus-3.5.3.1-red?style=flat-square)](https://baomidou.com/)
[![MySQL](https://img.shields.io/badge/MySQL-8.0+-4479A1?style=flat-square&logo=mysql&logoColor=white)](https://www.mysql.com/)
[![Redis](https://img.shields.io/badge/Redis-6.0+-DC382D?style=flat-square&logo=redis&logoColor=white)](https://redis.io/)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Version](https://img.shields.io/badge/Version-v3.3-orange?style=flat-square)](#-版本历史)

**为管理端、移动端与 AI 检测服务提供统一的 REST API 与业务编排能力**

[项目简介](#-项目简介) • [核心能力](#-核心能力) • [技术架构](#-技术架构) • [快速开始](#-快速开始) • [接口概览](#-接口概览) • [版本历史](#-版本历史)

</div>

---

> **当前版本**：v3.3  
> **文档更新**：2026-06-04

## 📋 目录

- [项目简介](#-项目简介)
- [核心能力](#-核心能力)
- [技术架构](#-技术架构)
- [技术栈](#-技术栈)
- [快速开始](#-快速开始)
- [项目结构](#-项目结构)
- [核心设计](#-核心设计)
- [接口概览](#-接口概览)
- [配置说明](#-配置说明)
- [构建与测试](#-构建与测试)
- [部署说明](#-部署说明)
- [开发指南](#-开发指南)
- [常见问题](#-常见问题)
- [贡献指南](#-贡献指南)
- [版本历史](#-版本历史)
- [许可证](#-许可证)

---

## 📖 项目简介

危房智能检测系统后端服务（`dangerhouse-backend`）基于 **Spring Boot 3** 构建，负责用户认证、建筑档案、检测任务、AI 检测调度、报告生成、文件存储、Redis 缓存治理与后台管理。它为 **管理端 Web**、**移动端 App** 以及 **Python FastAPI AI 服务** 提供统一的业务接口与数据持久化能力。

### 系统定位

```
┌─────────────────────────────────────────────────────────────────┐
│                    危房智能检测系统整体架构                        │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────────┐    ┌─────────────────┐  │
│  │ 管理端 Web  │    │  后端服务       │    │  AI 检测服务    │  │
│  │ (Vue 3)     │ ←→ │  (本项目)       │ ←→ │  (FastAPI)      │  │
│  └─────────────┘    │  Spring Boot    │    └─────────────────┘  │
│  ┌─────────────┐    │                 │                          │
│  │ 移动端 App  │ ←→ │  JWT / RBAC     │                          │
│  │ (Flutter)   │    │  业务编排       │                          │
│  └─────────────┘    └────────┬────────┘                          │
│                              ↓                                  │
│         ┌────────────────────┼────────────────────┐             │
│         │ MySQL │ Redis │ 本地/OSS │ 操作日志     │             │
│         └─────────────────────────────────────────┘             │
└─────────────────────────────────────────────────────────────────┘
```

### 核心价值

| 维度 | 说明 |
| :--- | :--- |
| **统一接口** | 管理端与移动端共用 `/api` 前缀，响应结构、分页与权限模型一致 |
| **安全可控** | JWT 无状态认证、Token 黑名单、BCrypt 密码、`ADMIN` / `INSPECTOR` / `USER` 角色隔离 |
| **检测闭环** | 任务状态机、多图上传、同步 AI 推理、结果持久化、报告生成与 PDF 下载 |
| **性能治理** | Redis 热点缓存、穿透/击穿/雪崩防护、写后失效与异步操作日志 |
| **存储灵活** | `FileStorageService` 抽象，本地文件系统与阿里云 OSS 可配置切换 |

---

## ✨ 核心能力

| 模块 | 能力 |
| :--- | :--- |
| **认证与权限** | JWT 无状态认证、Token 主动失效、BCrypt 密码加密、客户端类型校验、方法级 `@PreAuthorize` |
| **建筑档案** | 建筑创建、查询、更新、删除、图片上传、归属与访问权限校验 |
| **检测任务** | 任务创建、多图上传、AI 分析、状态流转、失败重试、取消和删除 |
| **AI 集成** | 通过 HTTP Multipart 调用 Python FastAPI，解析检测结果并持久化 |
| **报告管理** | 检测报告生成、详情查询和 PDF 下载 |
| **缓存治理** | Redis 热点缓存、空值缓存、缓存重建互斥锁、TTL 随机抖动和缓存失效 |
| **文件存储** | 基于统一接口切换本地文件系统与阿里云 OSS |
| **后台管理** | 仪表盘统计、用户管理、检测员身份管理、操作日志和模型信息 |
| **接口文档** | SpringDoc OpenAPI 与 Swagger UI |

---

## 🏗️ 技术架构

### 系统边界

```
移动端 / 管理端
       │
       │ REST API + JWT
       ▼
Spring Boot 后端服务
       │
       ├── MySQL：业务数据持久化
       ├── Redis：缓存、Token 黑名单、缓存重建互斥锁
       ├── 本地存储 / OSS：原图、结果图、PDF 报告
       └── FastAPI AI 服务：建筑损伤识别与风险分析
```

当前后端采用**单体分层架构**，不依赖 Spring Cloud。与 AI 服务之间使用 `RestTemplate` 发起同步 HTTP 请求（连接超时 5 秒，读取超时 30 秒）。操作日志通过独立线程池异步写入；检测任务本身在请求线程中执行。

### 请求处理链路

```
HTTP 请求
  → Spring Security / JwtAuthenticationFilter
  → Controller 参数接收与权限注解校验
  → Service 业务编排与事务
  → CacheService / Mapper / 外部服务客户端
  → Result<T> 统一响应
```

### 分层职责

| 层级 | 职责 |
| :--- | :--- |
| `controller` | 定义 REST 接口、接收参数、执行方法级权限校验 |
| `service` / `service.impl` | 业务规则、事务、数据归属校验、跨模块编排 |
| `mapper` | MyBatis-Plus 数据访问和自定义 SQL |
| `dto.request` / `dto.response` | 隔离接口模型与数据库实体 |
| `client` | 封装外部 AI 服务调用 |
| `cache` | Redis 缓存读写、穿透防护和缓存重建互斥锁 |
| `config` | Security、Redis、异步线程池、HTTP 客户端和属性配置 |
| `exception` | 业务异常和全局异常响应 |
| `util` | JWT、文件上传、PDF 报告和通用工具 |

---

## 🛠️ 技术栈

| 分类 | 技术 | 版本 |
| :--- | :--- | :--- |
| **运行环境** | Java | 17 |
| **核心框架** | Spring Boot | 3.2.0 |
| **安全框架** | Spring Security | 6.x |
| **数据访问** | MyBatis-Plus | 3.5.3.1 |
| **数据库** | MySQL | 8.0+ |
| **缓存** | Spring Data Redis / Lettuce | Spring Boot 3.2.0 |
| **身份认证** | JJWT | 0.11.5 |
| **API 文档** | SpringDoc OpenAPI | 2.2.0 |
| **PDF 生成** | OpenPDF | 1.3.30 |
| **对象存储** | Aliyun OSS SDK | 3.17.2 |
| **工具库** | Hutool | 5.8.22 |
| **构建工具** | Maven Wrapper | 项目内置 |

---

## 🚀 快速开始

### 环境要求

| 依赖 | 版本要求 | 说明 |
| :--- | :--- | :--- |
| **JDK** | 17 | 运行与编译 |
| **MySQL** | 8.0+ | 业务数据 |
| **Redis** | 6.0+ | 缓存与 Token 黑名单 |
| **Python AI 服务** | - | 仅执行 AI 检测时需要 |

### 安装步骤

```bash
# 1. 克隆项目
git clone https://github.com/DzDenzel/dangerHouseSystem.git

# 2. 进入后端目录
cd dangerHouseSystem/dangerhouse-backend

# 3. 初始化数据库（带示例数据）
mysql -u root -p < sql/dangerhouse_v3.0_with_data.sql

# 仅初始化结构（无示例数据）
# mysql -u root -p < sql/dangerhouse_v3.0.sql

# 4. 修改 src/main/resources/application.yml 中的数据库、Redis、AI 地址

# 5. 启动服务
# Windows
.\mvnw.cmd spring-boot:run

# Linux / macOS
./mvnw spring-boot:run
```

数据库结构和字段说明见 [sql/数据库说明文档.md](./sql/数据库说明文档.md)。

### 本地配置示例

默认配置位于 `src/main/resources/application.yml`。启动前至少确认以下项：

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/dangerhouse
    username: root
    password: root
  data:
    redis:
      host: 127.0.0.1
      port: 6379
      password: root
      database: 5

ai:
  detection:
    url: http://127.0.0.1:8000/api/v1/detect_damage
```

> ⚠️ 生产环境不得继续使用仓库中的默认数据库密码、Redis 密码和 JWT 密钥。

### 启动后访问

| 地址 | 用途 |
| :--- | :--- |
| `http://localhost:8080/api/health` | 健康检查 |
| `http://localhost:8080/swagger-ui.html` | Swagger UI |
| `http://localhost:8080/api-docs` | OpenAPI JSON |

---

## 📁 项目结构

```
dangerhouse-backend/
├── pom.xml
├── mvnw
├── mvnw.cmd
├── sql/
│   ├── dangerhouse_v3.0.sql
│   ├── dangerhouse_v3.0_with_data.sql
│   └── 数据库说明文档.md
└── src/
    ├── main/
    │   ├── java/com/dz/dangerhouse/
    │   │   ├── annotation/       # 操作日志注解
    │   │   ├── aspect/           # 操作日志切面
    │   │   ├── cache/            # Redis 缓存治理
    │   │   ├── client/           # AI 服务 HTTP 客户端
    │   │   ├── common/           # 通用响应与枚举
    │   │   ├── config/           # 框架与业务配置
    │   │   ├── controller/       # REST Controller
    │   │   ├── dto/              # 请求与响应 DTO
    │   │   ├── entity/           # 数据库实体
    │   │   ├── exception/        # 异常处理
    │   │   ├── filter/           # JWT 认证过滤器
    │   │   ├── mapper/           # MyBatis-Plus Mapper
    │   │   ├── service/          # 业务服务
    │   │   └── util/             # 文件、JWT、PDF 工具
    │   └── resources/
    │       ├── application.yml
    │       └── mapper/
    └── test/
        └── java/com/dz/dangerhouse/
```

---

## 📐 核心设计

### 认证与权限

- Spring Security 使用无状态会话，业务接口通过 JWT 认证。
- 登录支持用户名、手机号或邮箱。
- `ADMIN` 仅允许登录管理端，普通用户和检测员仅允许登录移动端。
- `@PreAuthorize` 负责方法级角色控制。
- 用户主动退出后，当前 Token 写入 Redis 黑名单并立即失效。
- 普通登录 Token 默认有效期为 **1 小时**，记住我登录默认有效期为 **3 天**。

### 检测任务状态

```
CREATED --上传图片--> READY --开始检测--> PROCESSING --成功--> COMPLETED
                                      \--失败--> FAILED --重试--> PROCESSING

CREATED / READY --取消--> CANCELLED
```

主要处理流程：

1. 创建检测任务并绑定建筑与发起人。
2. 上传一张或多张原始图片，任务进入 `READY`。
3. 启动检测后，任务进入 `PROCESSING`。
4. 后端读取图片文件并同步调用 FastAPI AI 服务。
5. 持久化裂缝数量、损伤比例、风险等级、置信度和结果图片。
6. 成功时进入 `COMPLETED`，异常时记录错误信息并进入 `FAILED`。

> 缓存互斥锁仅用于防止热点缓存同时回源，不负责检测任务或建筑写操作的业务并发控制。同一检测任务不应被并发启动；需要水平扩展或严格防重时，应在业务写入层增加条件更新、幂等键或数据库版本控制。

### Redis 缓存

`CacheService` 是统一缓存入口，覆盖用户、认证信息、建筑、检测、报告和仪表盘等热点读路径。

| 策略 | 实现 |
| :--- | :--- |
| 缓存穿透 | 数据不存在时写入短 TTL 空值标记 |
| 缓存击穿 | 详情热点通过 `SET NX` 互斥锁限制同时回源 |
| 缓存雪崩 | 正常 TTL 增加随机抖动 |
| 缓存更新 | 写操作完成后删除详情、列表和统计缓存 |
| 批量失效 | 使用 Redis `SCAN` 按前缀查找并删除 |
| 故障降级 | 常规缓存读写异常时记录日志并回源数据库 |
| 安全解锁 | Lua 脚本校验锁值后删除锁 |

默认缓存参数：

| 配置 | 默认值 |
| :--- | :--- |
| 普通缓存 TTL | 10 分钟 |
| 仪表盘 TTL | 5 分钟 |
| 认证用户 TTL | 60 分钟 |
| 空值 TTL | 120 秒 |
| 缓存互斥锁 TTL | 10 秒 |
| 锁重试间隔 | 50 毫秒 |
| 最大重试次数 | 20 |
| TTL 抖动 | 0 至 300 秒 |

### 分页响应

数据库分页由 MyBatis-Plus `Page<T>` 执行，Controller 通过 `PageResponse<T>` 对外返回统一结构：

```json
{
  "records": [],
  "total": 0,
  "page": 1,
  "size": 10,
  "pages": 0
}
```

`Page<T>` 属于持久层分页载体，`PageResponse<T>` 属于接口响应模型，两者职责不同。

### AI 服务集成

- `AiDetectionClient` 使用 `RestTemplate` 发送 Multipart 请求。
- 多张图片使用同名 `images` 字段上传。
- AI 地址由 `ai.detection.url` 配置。
- `DetectionAiClientService` 校验 AI 响应、解析结果并保存结果图。
- 当前调用为同步模式，HTTP 请求线程会等待 AI 推理完成。
- AI 服务不可用或响应异常时，任务状态更新为 `FAILED`，错误信息写入检测记录。

### 异步任务

当前异步能力用于操作日志写入：

| 配置 | 值 |
| :--- | :--- |
| Bean 名称 | `operationLogExecutor` |
| 核心线程数 | 2 |
| 最大线程数 | 8 |
| 队列容量 | 500 |
| 关闭等待时间 | 10 秒 |

AI 检测、报告生成和业务写操作当前不通过消息队列或异步任务执行。

### 文件存储

业务层通过 `FileStorageService` 和 `FileUploadUtil` 使用统一文件能力：

| 模式 | 启用条件 | 说明 |
| :--- | :--- | :--- |
| 本地存储 | `aliyun.oss.enabled=false` | 文件写入 `uploads/`，通过 `/uploads` 或文件接口访问 |
| 阿里云 OSS | `aliyun.oss.enabled=true` | 文件写入 OSS，支持公开 URL 和临时签名 URL |

存储内容包括建筑图片、检测原图、AI 结果图、临时文件和 PDF 报告。默认单文件上限为 **10 MB**，单次请求上限为 **50 MB**。

---

## 📡 接口概览

### 基础信息

| 项目 | 说明 |
| :--- | :--- |
| 基础路径 | `http://localhost:8080/api` |
| 认证方式 | Bearer Token (JWT) |
| 数据格式 | JSON |
| 在线文档 | Swagger UI：`/swagger-ui.html` |

接口统一使用 `/api` 前缀。完整参数、响应模型和在线调试以 **Swagger UI** 为准。

| 模块 | 路径 | 说明 |
| :--- | :--- | :--- |
| 健康检查 | `GET /api/health` | 服务状态 |
| 认证 | `/api/auth/**` | 登录、注册、退出、账号检查 |
| 当前用户 | `/api/user/**` | 资料、密码和头像 |
| 用户管理 | `/api/users/**` | 管理员用户查询、状态和检测员身份管理 |
| 建筑档案 | `/api/buildings/**` | 建筑增删改查和图片上传 |
| 检测任务 | `/api/detections/**` | 任务、图片、启动、查询、取消和删除 |
| AI 兼容接口 | `POST /api/ai/detect` | 上传图片并执行检测 |
| 报告 | `/api/reports/**` | 报告生成、详情和下载 |
| 管理后台 | `/api/admin/**` | 仪表盘、操作日志和模型信息 |
| 文件访问 | `/api/files/**` | 文件读取 |

### 通用响应结构

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {},
  "requestId": "..."
}
```

除认证、Swagger 和公开文件路径外，请求需携带：

```http
Authorization: Bearer <token>
```

---

## ⚙️ 配置说明

### 主要配置项

| 前缀 | 说明 |
| :--- | :--- |
| `server` | 服务端口 |
| `spring.datasource` | MySQL 连接 |
| `spring.data.redis` | Redis 连接池和数据库 |
| `jwt` | Token 密钥、有效期和请求头 |
| `app.cache` | 缓存 TTL、锁和键名前缀 |
| `ai.detection` | AI 检测服务地址 |
| `file.upload` | 本地文件目录和访问前缀 |
| `aliyun.oss` | OSS 开关、凭据、Bucket 和签名配置 |
| `springdoc` | OpenAPI 与 Swagger UI |

### OSS 环境变量

```text
ALIYUN_OSS_ENABLED
ALIYUN_OSS_ENDPOINT
ALIYUN_OSS_ACCESS_KEY_ID
ALIYUN_OSS_ACCESS_KEY_SECRET
ALIYUN_OSS_BUCKET_NAME
ALIYUN_OSS_BASE_URL
ALIYUN_OSS_SIGNATURE_EXPIRE_SECONDS
ALIYUN_OSS_MAX_FILE_SIZE
```

---

## 🧪 构建与测试

### 运行测试

```bash
# Windows
.\mvnw.cmd test

# Linux / macOS
./mvnw test
```

测试目录包含：

| 测试类 | 说明 |
| :--- | :--- |
| `DangerhouseApplicationTests` | 应用上下文测试 |
| `LogicalDeleteRemovalTest` | 逻辑删除字段移除校验 |
| `RedisTest` | Redis 连接与读写测试 |

运行完整测试前需要启动 MySQL 和 Redis，并保证 `application.yml` 中的连接信息正确。

### 构建产物

```bash
# Windows
.\mvnw.cmd clean package

# Linux / macOS
./mvnw clean package
```

构建产物位于 `target/`。

---

## 🚢 部署说明

1. 准备 JDK 17、MySQL、Redis，并初始化数据库。
2. 通过安全配置源提供数据库、Redis、JWT 和 OSS 凭据。
3. 如需 AI 检测，先部署 FastAPI AI 服务并配置 `ai.detection.url`。
4. 执行 Maven 构建并运行 JAR：

```bash
java -jar target/dangerhouse-backend-0.0.1-SNAPSHOT.jar
```

5. 在反向代理或网关层配置 HTTPS、请求体大小、跨域来源和访问日志。
6. 对 MySQL、Redis、文件存储和 AI 服务建立独立备份与监控。

---

## 📝 开发指南

### 分支管理

| 分支 | 说明 |
| :--- | :--- |
| `master` | 生产环境分支，只接受合并请求 |
| `develop` | 开发环境分支，日常开发在此进行 |
| `feature/*` | 功能开发分支 |
| `hotfix/*` | 紧急修复分支 |

### 提交规范

采用 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

```
<type>(<scope>): <subject>

<body>

<footer>
```

| 类型 | 说明 |
| :--- | :--- |
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 文档更新 |
| `style` | 代码格式调整 |
| `refactor` | 代码重构 |
| `perf` | 性能优化 |
| `test` | 测试相关 |
| `chore` | 构建/工具变动 |

**示例：**

```bash
feat(detection): 新增检测任务取消接口

- 支持 CREATED / READY 状态取消
- 取消后清理关联缓存

Closes #123
```

### 代码规范

- Controller 只做参数接收与权限声明，业务逻辑放在 Service 层。
- 请求/响应使用 `dto` 包，避免直接暴露 `entity`。
- 写操作完成后通过 `CacheService` 失效相关缓存键。
- 敏感配置使用环境变量或外部配置中心，不提交到仓库。

---

## ❓ 常见问题

### Q: Swagger 无法访问？

**A:** 确认后端已启动，并访问 `http://localhost:8080/swagger-ui.html`。OpenAPI JSON 路径为 `/api-docs`。

### Q: Redis 连接失败？

**A:** 确认 Redis 已启动，密码、端口和数据库索引与 `spring.data.redis` 一致。常规查询缓存异常会尝试回源数据库，但 Token 黑名单和认证缓存依赖 Redis，部署环境应保证 Redis 可用。

### Q: AI 检测失败？

**A:** 确认 Python AI 服务已启动，并检查 `ai.detection.url`、模型文件和后端日志。检测失败后任务会进入 `FAILED`，可在 AI 服务恢复后重试。

### Q: 文件无法访问？

**A:** 本地存储模式下检查 `uploads/` 目录权限和 `file.upload.url-prefix`；OSS 模式下检查 Bucket、访问域名、凭据和对象权限。

### Q: 数据库 SQL 日志过多？

**A:** 当前 `application.yml` 使用 `StdOutImpl` 输出 SQL。生产环境应调整 MyBatis 日志配置和应用日志级别。

---

## 🤝 贡献指南

我们欢迎所有形式的贡献，包括但不限于：

1. 📝 提交 Issue 报告 Bug 或提出新功能建议
2. 🔧 提交 Pull Request 修复 Bug 或实现新功能
3. 📚 完善文档或翻译
4. 💬 参与讨论，帮助其他用户解决问题

### 贡献流程

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'feat: add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 提交 Pull Request

---

## 📅 版本历史

### v3.3 (2026-04-15)

**本次 3.3 技术增量更新：**

- ✅ 统一 Web 端账户菜单和管理员修改密码入口
- ✅ 完善密码校验、退出登录交互和品牌资源
- ✅ 持续对齐账户安全相关文档与实现

### v3.2.1 (2026-04-14)

**本次 3.2.1 技术增量更新：**

- ✅ 新增统一修改密码接口 `PUT /api/user/password`
- ✅ 新增管理员设置检测员接口 `PUT /api/users/{userId}/inspector`
- ✅ 实现 `USER` 与 `INSPECTOR` 单一业务身份切换，`ADMIN` 保持独立

### v3.2 (2026-04-13)

**本次 3.2 技术增量更新：**

- ✅ 登录请求新增 `clientType`，后端校验账号可登录的客户端类型
- ✅ JWT 有效期支持普通登录 1 小时和记住我登录 3 天
- ✅ 新增退出登录 Token 黑名单，完善角色接口权限
- ✅ 扩展建筑归属、创建人和检测员字段，收口普通用户数据访问范围
- ✅ 优化登录错误提示、用户统计和筛选查询

### v3.1 (2026-03-23)

**本次 3.1 技术增量更新：**

- ✅ 接入 Redis，覆盖仪表盘、认证、用户、建筑、检测和报告热点查询
- ✅ 增加空值缓存、缓存重建互斥锁、TTL 抖动和 `SCAN` 前缀失效
- ✅ 增加缓存异常回源、鉴权缓存续期和异步操作日志
- ✅ 完善检测失败重试、状态展示、业务提示和检测备注

### v3.0 (2026-03-19)

**本次 3.0 技术增量更新：**

- ✅ 检测链路升级为 `CREATED / READY / PROCESSING / COMPLETED / FAILED / CANCELLED` 状态流
- ✅ 支持多图上传、检测结果回显和多图报告
- ✅ 持久化检测失败原因，报告生成与检测完成解耦
- ✅ 优化 PDF 下载、通知聚合和离线草稿恢复

### v2.4 (2026-03-19)

- 新增 `FileStorageService` 文件存储抽象
- 增加本地存储和阿里云 OSS 双实现
- PDF 报告和文件下载统一通过存储服务处理

### v2.3 (2026-03-17)

- 建筑图片上传接口合并至 `BuildingController`
- 删除重复报告导出接口，统一报告下载入口
- 规范建筑结构类型代码并同步数据库说明

### v2.2 (2026-03-14)

- DTO 拆分为请求与响应模型，统一 `PageResponse` 和查询请求
- 拆分当前用户、AI 调用、检测查询、报告和结果组装等服务职责
- 文件处理和异常处理统一收口

### v2.1 (2026-03-12)

- AI 模型迁移至 Faster R-CNN ResNet50 v2
- 支持多图联合检测和 DBSCAN 空间聚类去重
- 新增健康检查、报告、管理后台、操作日志和风险等级模块
- 完善检测状态、风险等级、统一响应和多账号登录

### v1.4 (2026-03-10)

- 重构数据库结构、索引、约束和初始化数据
- 引入 RBAC 权限模型和操作日志
- 完善建筑档案、检测结果 JSON 和实体映射

### v1.2

- 新增用户资料更新、AI 检测、检测详情和建筑检测记录查询
- 新增 HTTP 客户端、文件上传、业务异常、检测和报告模块
- 完善用户、检测和报告相关数据库字段

### v1.1 (2026-03-01)

- 实现用户注册与登录
- 引入 JWT Token 认证
- 实现建筑档案基础接口和数据库结构

---

## 📄 许可证

本项目基于 [MIT License](../dangerhouse-admin-web/LICENSE) 开源协议发布（与 monorepo 其他子项目保持一致）。

---

## 📞 联系方式

如有问题或建议，欢迎通过以下方式联系我们：

- 🐛 Issue：[GitHub Issues](https://github.com/DzDenzel/dangerHouseSystem/issues)
- 📖 关联文档：[管理端 README](../dangerhouse-admin-web/README.md) · [移动端 README](../dangerhouse-mobile-app/Readme.md) · [AI 服务 README](../dangerhouse-ai-service/Readme.md)

---

<div align="center">

**⭐ 如果这个项目对你有帮助，请给一个 Star 支持一下！⭐**

Made with ❤️ by Danger House Team

**让危房检测更智能、更高效**

</div>
