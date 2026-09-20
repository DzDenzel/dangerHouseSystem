# dangerhouse-backend

危房智能检测系统的后端服务，为管理端 Web、移动端 App 与 AI 检测服务提供统一的 REST 接口。

Spring Boot 3.2 · Java 17 · MyBatis-Plus 3.5.3.1 · MySQL 8 · Redis 6

## 功能范围

- **认证**：JWT 登录/注册/登出，密码 BCrypt 存储，登出通过 Redis 黑名单让 Token 立即失效
- **建筑档案**：增删改查、按业主或地址检索、图片上传
- **检测任务**：建单 → 上传图片 → 调用 AI 服务 → 结果落库，六个状态流转
- **报告**：生成 PDF、查询详情、下载文件
- **系统管理**：用户管理、检测员授权、操作日志、看板统计
- **缓存**：Redis 热点缓存，带空值缓存与互斥锁，防穿透和击穿
- **文件**：本地磁盘与阿里云 OSS 两套实现，配置切换

## 技术栈

| 依赖 | 版本 |
| :--- | :--- |
| Java | 17 |
| Spring Boot | 3.2.0 |
| Spring Security | 随 parent |
| MyBatis-Plus | 3.5.3.1 |
| mybatis-spring | 3.0.3 |
| MySQL Connector/J | 随 parent |
| JJWT | 0.11.5 |
| Hutool | 5.8.22 |
| springdoc-openapi | 2.2.0 |
| OpenPDF | 1.3.30 |
| aliyun-sdk-oss | 3.17.2 |
| spring-boot-starter-data-redis | 3.2.0 |

## 环境要求

- JDK 17
- MySQL 8.0+
- Redis 6.0+
- AI 检测服务（可选；未启动时检测任务会直接置为 `FAILED`）

## 快速开始

初始化数据库：

```bash
# 仅建表 + 基础角色数据
mysql -u root -p < sql/dangerhouse_v3.0.sql

# 建表 + 业务示例数据
mysql -u root -p < sql/dangerhouse_v3.0_with_data.sql
```

按需修改 `src/main/resources/application.yml` 里的数据库、Redis 和 AI 服务地址，然后启动：

```bash
# Windows
mvnw.cmd spring-boot:run

# Linux / macOS
./mvnw spring-boot:run
```

服务监听 `8080`，Swagger UI 在 `http://localhost:8080/swagger-ui.html`。

`/api/health` 接口存在，但不在 SecurityConfig 的放行列表里，不带 Token 访问会返回 401，不能当作免鉴权的存活探针使用。

## 项目结构

```
src/main/java/com/dz/dangerhouse/
├── annotation/   自定义注解
├── aspect/       切面（操作日志记录）
├── cache/        Redis 缓存封装与缓存键定义
├── client/       AI 检测服务客户端
├── common/       Result 统一响应、RiskLevel 风险等级枚举
├── config/       Security、异步线程池、Redis、MyBatis-Plus 等配置
├── controller/   REST 接口层
├── dto/          请求对象与响应对象
├── entity/       8 个实体：User、Role、UserRole、Building、Detection、Image、Report、OperationLog
├── exception/    业务异常与全局异常处理
├── filter/       JWT 认证过滤器
├── mapper/       MyBatis-Plus Mapper
├── service/      业务逻辑
└── util/         JWT、PDF 生成、报告编号、文件上传等工具
```

`src/main/resources/` 下只有一份 `application.yml`，未按 profile 拆分；`mapper/` 下有三个 XML：`DetectionMapper.xml`、`OperationLogMapper.xml`、`UserRoleMapper.xml`。

数据库共 8 张表：`user`、`role`、`user_role`、`building`、`detection`、`image`、`report`、`operation_log`。

## 接口概览

所有接口以 `/api` 为前缀，统一返回 `Result<T>`：

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {},
  "timestamp": 1710000000,
  "requestId": "..."
}
```

分页接口的 `data` 为 `PageResponse`：`records`、`total`、`current`、`size`、`pages`。

| 模块 | 路径前缀 | 主要接口 |
| :--- | :--- | :--- |
| 健康检查 | `/api` | `GET /health` |
| 认证 | `/api/auth` | `POST /login`、`POST /register`、`POST /logout`、`GET /check-username/{username}`、`GET /check-phone/{phone}` |
| 用户 | `/api` | `GET/PUT /user/profile`、`PUT /user/password`、`POST /user/avatar`、`GET /users`、`GET /users/{id}`、`PUT /users/{userId}/inspector`、`PUT /users/{userId}/status` |
| 建筑 | `/api/buildings` | `GET`、`POST`、`GET/PUT/DELETE /{id}`、`GET /by-owner`、`GET /by-address`、`POST /{id}/image` |
| 检测 | `/api/detections` | `POST`、`POST /{id}/images`、`POST /{id}/start`、`GET`、`GET /{id}`、`GET /{id}/images`、`PUT /{id}/cancel`、`DELETE /{id}` |
| AI | `/api/ai` | `POST /detect` |
| 报告 | `/api/reports` | `POST /generate`、`GET /{id}`、`GET /{id}/download` |
| 管理 | `/api/admin` | `GET /dashboard`、`GET /operation-logs`、`GET /models` |
| 文件 | `/api/files` | `GET /view` |

## 核心设计

### 认证与权限

`SecurityConfig` 放行 `/api-docs/**`、`/swagger-ui*`、`/uploads/**`、`/api/files/**`、`/api/auth/**`，其余请求一律要求认证。`JwtAuthenticationFilter` 从 `Authorization: Bearer <token>` 中解析身份。

登出时把当前 Token 的哈希写入 Redis 黑名单（键前缀 `auth:token:blacklist:`），TTL 设为该 Token 的剩余有效期。

接口权限用方法级 `@PreAuthorize` 控制，共约 30 处；`AdminController` 在类级别声明 `hasRole('ADMIN')`。系统有三个角色：`ADMIN`、`INSPECTOR`、`USER`。

### 检测任务状态

状态定义在 `DetectionServiceImpl` 中，为字符串字面量，没有对应的枚举类：

| 状态 | 进入时机 |
| :--- | :--- |
| `CREATED` | 创建任务 |
| `READY` | 图片上传完成 |
| `PROCESSING` | 开始调用 AI 服务 |
| `COMPLETED` | AI 返回结果并落库 |
| `FAILED` | 调用异常，或无图片、文件缺失 |
| `CANCELLED` | 取消任务，仅 `CREATED` / `READY` 可取消 |

### Redis 缓存

缓存 TTL 与键前缀在 `application.yml` 的 `app.cache.*` 下配置：

| 配置 | 值 |
| :--- | :--- |
| `default-ttl-minutes` | 10 |
| `dashboard-ttl-minutes` | 5 |
| `auth-user-ttl-minutes` | 60 |
| `null-value-ttl-seconds` | 120 |
| `mutex-lock-ttl-seconds` | 10 |
| `mutex-retry-delay-millis` | 50 |
| `mutex-max-retries` | 20 |
| `ttl-jitter-seconds` | 300 |

键前缀：`dashboard:data`、`user:detail:`、`user:list:`、`auth:user:`、`auth:token:blacklist:`、`building:detail:`、`building:list:`、`detection:detail:`、`detection:list:`、`report:detail:`、`lock:cache:`。

缓存穿透用空值缓存兜底（TTL 120 秒），缓存击穿用 `lock:cache:` 互斥锁兜底（锁 10 秒，失败后每 50ms 重试一次、最多 20 次）。TTL 会加上最多 300 秒的随机抖动，避免同一批键同时过期。

### 异步与外部调用

操作日志写库走 `operationLogExecutor` 线程池：核心 2、最大 8、队列 500、线程名前缀 `operation-log-`、关闭前等待 10 秒。

调用 AI 服务用 `RestTemplate`，连接超时 5 秒、读超时 30 秒，请求地址由 `ai.detection.url` 指定，默认 `http://127.0.0.1:8000/api/v1/detect_damage`。

### 文件存储

`LocalFileStorageServiceImpl` 与 `OssFileStorageServiceImpl` 两套实现，按 `aliyun.oss.enabled` 切换，默认关闭走本地磁盘。本地上传目录为 `uploads/`，访问前缀 `/uploads`，单文件上限 10MB、单请求上限 50MB。

## 配置说明

| 配置项 | 默认值 | 说明 |
| :--- | :--- | :--- |
| `server.port` | `8080` | 服务端口 |
| `spring.datasource.url` | `jdbc:mysql://localhost:3306/dangerhouse?...` | 数据库连接 |
| `spring.data.redis.*` | `127.0.0.1:6379`，database 5 | Redis 连接 |
| `jwt.expiration` | `3600` | Token 有效期（秒） |
| `jwt.remember-expiration` | `259200` | 勾选"记住我"后的有效期（秒） |
| `ai.detection.url` | `http://127.0.0.1:8000/api/v1/detect_damage` | AI 服务地址 |
| `file.upload.base-dir` | `uploads` | 本地上传目录 |
| `file.upload.url-prefix` | `/uploads` | 文件访问前缀 |
| `aliyun.oss.enabled` | `false` | 是否启用 OSS，可用环境变量 `ALIYUN_OSS_ENABLED` 覆盖 |
| `springdoc.swagger-ui.path` | `/swagger-ui.html` | Swagger UI 路径 |

阿里云 OSS 启用时还需提供 `aliyun.oss.access-key-id`、`access-key-secret`、`bucket-name`、`base-url`。

## 构建与测试

```bash
# 打包
./mvnw clean package

# 运行测试
./mvnw test
```

测试类共 3 个：

- `DangerhouseApplicationTests` — Spring 上下文加载
- `LogicalDeleteRemovalTest` — 纯 JUnit，校验逻辑删除相关的残留配置已被移除
- `RedisTest` — Redis 读写，需要本地有可用的 Redis 实例

## 常见问题

**Swagger 打不开** — 确认 `springdoc.api-docs.path` 与 `springdoc.swagger-ui.path` 未被改动，且 `packages-to-scan` 指向 `com.dz.dangerhouse.controller`。

**Redis 连不上** — 默认连 `127.0.0.1:6379` 的 5 号库，密码 `root`。改配置后需要重启。

**AI 检测总是失败** — 检查 AI 服务是否已在 `8000` 端口启动，以及 `ai.detection.url` 是否指向正确地址。任务失败时状态会停在 `FAILED`，可以直接重新触发。

**上传的文件访问不到** — 确认 `file.upload.base-dir` 目录存在且有写权限，`url-prefix` 与静态资源映射一致。

**控制台 SQL 日志太多** — `mybatis-plus.configuration.log-impl` 设为 `StdOutImpl`，生产环境可改为 `NoLoggingImpl`。
