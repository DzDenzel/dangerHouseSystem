<div align="center">

# 🏠 危房智能检测系统

**Dangerous House Intelligent Detection System — 移动端 App**

[![Flutter](https://img.shields.io/badge/Flutter-3.2+-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.2+-0175C2?style=flat-square&logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web%20%7C%20Windows-blue?style=flat-square)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](../dangerhouse-admin-web/LICENSE)
[![Version](https://img.shields.io/badge/Version-v3.3-orange?style=flat-square)](#-版本历史)

**现场采集、多图检测、结果查看与报告管理的跨平台移动应用**

[项目简介](#-项目简介) • [核心功能](#-核心功能) • [技术架构](#-技术架构) • [快速开始](#-快速开始) • [版本历史](#-版本历史)

</div>

---

> **当前版本**：v3.3  
> **文档更新**：2026-06-04

## 📋 目录

- [项目简介](#-项目简介)
- [核心功能](#-核心功能)
- [技术架构](#-技术架构)
- [技术栈](#-技术栈)
- [快速开始](#-快速开始)
- [项目结构](#-项目结构)
- [配置说明](#-配置说明)
- [构建发布](#-构建发布)
- [测试体系](#-测试体系)
- [开发指南](#-开发指南)
- [常见问题](#-常见问题)
- [贡献指南](#-贡献指南)
- [版本历史](#-版本历史)
- [许可证](#-许可证)

---

## 📖 项目简介

`dangerhouse-mobile-app`（DangerHouse App）是危房智能检测系统的 **移动端应用**，基于 **Flutter** 开发，一套代码支持 **Android / Web / Windows**。面向普通用户与检测员，承担现场拍照、多图上传、AI 检测结果查看、建筑档案与检测报告管理等能力。

### 系统定位

```
┌─────────────────────────────────────────────────────────────────┐
│                    危房智能检测系统整体架构                        │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────────┐    ┌─────────────────┐  │
│  │ 移动端 APP  │    │  后端服务       │    │  AI 检测服务    │  │
│  │ (本项目)    │ ←→ │  Spring Boot    │ ←→ │  FastAPI        │  │
│  └─────────────┘    └─────────────────┘    └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### 核心价值

| 维度 | 传统方式 | 本应用 |
| :--- | :--- | :--- |
| **检测效率** | 人工现场勘查数小时 | 拍照上传，分钟级获取 AI 结果 |
| **结果客观性** | 依赖人员经验 | 算法量化评估，标准统一 |
| **数据管理** | 纸质记录难追溯 | 数字化存储，历史可查 |
| **角色体验** | 单一界面 | 普通用户简化首页，检测员完整业务首页 |

---

## ✨ 核心功能

### 业务流程

```
用户登录 → 创建/选择建筑 → 拍摄或选图 → 上传检测 → 查看结果 → 生成报告
```

### 功能模块

| 模块 | 主要能力 |
| :--- | :--- |
| **用户认证** | 用户名/手机/邮箱登录、注册、JWT、`clientType=APP`、记住我、修改密码 |
| **首页仪表盘** | 统计指标、风险分布、快捷入口、通知角标（检测员） |
| **建筑档案** | 列表、搜索、筛选、CRUD、图片、归档与监测 |
| **拍摄检测** | 自定义相机、相册多图、关联建筑、检测备注（必填） |
| **结果展示** | 裂缝标注、A/B/C/D 评级、多图对比、手动刷新状态 |
| **检测报告** | 列表、详情、生成、已有报告直接查看/下载 |
| **个人中心** | 资料编辑、账户与安全、检测档案、帮助与通知 |
| **历史归档** | 检测历史、状态/风险筛选、危险建筑清单 |

---

## 🏗️ 技术架构

项目采用 **Clean Architecture** + **MVVM**，结合 **Riverpod** 状态管理：

```
Presentation (UI / Pages)
        ↓
Domain (Entities / UseCases / Services)
        ↓
Data (Repositories / Remote DataSources / DTOs)
        ↓
Core (Network / Auth / Router / Theme / Utils)
```

---

## 🛠️ 技术栈

| 类别 | 技术 | 版本 | 说明 |
| :--- | :--- | :--- | :--- |
| **框架** | Flutter | 3.2+ | 跨平台 UI |
| **语言** | Dart | 3.2+ | 空安全 |
| **状态管理** | Riverpod | 2.4+ | 响应式状态 |
| **路由** | go_router | 14+ | 声明式路由与守卫 |
| **网络** | Dio | 5.4+ | 拦截器、Multipart |
| **本地存储** | SharedPreferences | 2.2+ | Token 与配置 |
| **序列化** | json_serializable | 6.7+ | 代码生成 |
| **相机/相册** | camera / image_picker | - | 拍摄与选图 |
| **UI** | Material 3 | - | 设计规范 |

---

## 🚀 快速开始

### 环境要求

| 依赖 | 版本要求 |
| :--- | :--- |
| **Flutter SDK** | >= 3.2.0 |
| **Dart SDK** | >= 3.2.0 |
| **后端服务** | `http://localhost:8080`（或局域网 IP） |
| **AI 服务** | 执行检测时需要 `http://localhost:8000` |

```bash
flutter doctor -v
```

### 安装步骤

```bash
# 1. 克隆项目
git clone https://github.com/DzDenzel/dangerHouseSystem.git
cd dangerHouseSystem/dangerhouse-mobile-app

# 2. 安装依赖
flutter pub get

# 3. 生成 JSON 代码（模型变更后执行）
dart run build_runner build --delete-conflicting-outputs

# 4. 运行
flutter run -d chrome      # Web
flutter run -d windows     # Windows
flutter run -d <device_id> # Android
```

**Android 模拟器访问本机后端：**

```bash
adb reverse tcp:8080 tcp:8080
```

---

## 📁 项目结构

```
dangerhouse-mobile-app/
├── lib/
│   ├── core/           # 网络、认证、路由、主题、工具、公共组件
│   ├── data/           # DTO、Repository、Remote DataSource
│   ├── domain/         # Entity、UseCase、Service
│   ├── presentation/   # 页面（home、capture、login、profile、result、task）
│   ├── providers/      # 全局 Riverpod Provider
│   ├── app.dart
│   └── main.dart
├── assets/images/      # Logo、背景等资源
├── test/               # 单元测试与 Widget 测试
├── integration_test/   # 集成测试
├── android/            # Android 工程配置
└── pubspec.yaml
```

---

## ⚙️ 配置说明

API 地址位于 `lib/core/constants/api_constants.dart`：

```dart
class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';  // 模拟器
    }
    return 'http://localhost:8080';
  }
}
```

真机调试请改为局域网 IP，例如 `http://192.168.1.100:8080`。

| 配置项 | 默认值 | 说明 |
| :--- | :--- | :--- |
| `connectTimeout` | 15000 ms | 连接超时 |
| `receiveTimeout` | 15000 ms | 接收超时 |

登录需携带 `clientType: "APP"`；会话时长与后端一致（普通 1 小时，记住我 3 天）。

---

## 📦 构建发布

```bash
flutter build apk --release
flutter build apk --split-per-abi --release
flutter build web --release
flutter build windows --release
```

产物路径：`build/app/outputs/flutter-apk/`、`build/web/`、`build/windows/runner/Release/`。

---

## 🧪 测试体系

```bash
flutter test
flutter test test/unit/repositories/auth_repository_test.dart
flutter test --coverage
flutter test integration_test/app_test.dart
```

| 模块 | 类型 | 覆盖内容 |
| :--- | :--- | :--- |
| AuthRepository | 单元测试 | 登录、注册、Token |
| BuildingRepository | 单元测试 | 建筑 CRUD |
| AuthProvider | 单元测试 | 认证状态 |
| LoginActivity | Widget 测试 | 登录交互 |
| App Flow | 集成测试 | 主流程 |

---

## 📝 开发指南

### 提交规范

```bash
feat(detection): 检测备注改为必填
fix(auth): 修复主动退出后误报过期
```

### 代码规范

- 遵循 [Effective Dart](https://dart.dev/guides/language/effective-dart)
- 公共 API 添加文档注释；优先使用 `const` 构造函数
- 路由统一通过 `AppRouter`，避免硬编码路径

---

## ❓ 常见问题

### Q: 登录后 Token 丢失？

**A:** 检查 `TokenManager` 与 `SharedPreferences` 初始化是否正常。

### Q: 网络请求超时？

**A:** 确认后端已启动；Android 模拟器用 `10.0.2.2`；真机用局域网 IP。

### Q: 图片上传失败？

**A:** 检查文件大小与 `multipart/form-data`；后端单文件默认上限 10 MB。

### Q: 检测结果解析错误？

**A:** `detectResult` 可能为 JSON 对象或字符串，代码已做兼容处理。

### Q: AI 检测一直失败？

**A:** 确认 AI 服务与后端 `ai.detection.url` 配置正确；任务状态为 `FAILED` 时可重试。

---

## 🤝 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改并发起 Pull Request

---

## 📅 版本历史

### v3.3 (2026-04-15)

**本次 3.3 技术增量更新：**

- ✅ 统一移动端登录页品牌 Logo，与 Web 视觉识别一致
- ✅ 账户安全能力与后端 `PUT /api/user/password` 保持一致

### v3.2.1 (2026-04-14)

**本次 3.2.1 技术增量更新：**

- ✅ 检测员与普通用户分别提供「账户与安全」入口
- ✅ 统一账户安全页与修改密码表单校验
- ✅ 接入 `PUT /api/user/password`

### v3.2 (2026-04-13)

**本次 3.2 技术增量更新：**

- ✅ 登录请求新增 `clientType = APP`
- ✅ 记住我、会话时长（1h / 3d）、退出拉黑 Token
- ✅ 管理员不能凭本地缓存进入 App
- ✅ 注册页二次密码与查重校验
- ✅ 双首页：普通用户简化首页 / 检测员完整首页
- ✅ 建筑与报告页补齐归属字段展示

### v3.1 (2026-03-23)

**本次 3.1 技术增量更新：**

- ✅ 检测详情与报告页补齐 `READY / FAILED / CREATED` 主操作
- ✅ 开始检测防重复点击；结果页改手动刷新
- ✅ 检测备注业务必填；列表显示「建筑名 + 备注」
- ✅ AI 不可用业务化提示；关键动作后刷新事件广播

### v3.0 (2026-03)

**本次 3.0 技术增量更新：**

- ✅ 检测任务状态流与多图上传、多图结果展示
- ✅ 报告多图回显与生成闭环；通知基于真实数据聚合
- ✅ 离线检测草稿缓存与手动同步

### v2.5 (2025-03)

- ✅ 建筑图片上传与列表/详情展示
- ✅ 检测详情「去检测」与图片路径工具类
- ✅ Logo、报告详情与检测历史展示优化

### v2.4 (2025-03)

- ✅ 无结果页与上传-检测-刷新流程
- ✅ 月度统计前端计算；已归档建筑风险筛选修正

### v2.3 (2025-03)

- ✅ 综合风险等级算法与权限工具类
- ✅ 快速检测与检测备注

### v2.2 (2025-03)

- ✅ Clean Architecture 重构、go_router、Riverpod 状态基类
- ✅ 统一错误处理与测试体系建立

### v1.0 (2025-01)

- 用户认证、首页、建筑、拍摄检测、结果、报告、个人中心初版

### 规划中

- [ ] 离线缓存（sqflite）
- [ ] 推送通知（FCM 等）
- [ ] 多语言（i18n）
- [ ] 图片 CDN 与统一缓存分层

---

## 📄 许可证

本项目基于 [MIT License](../dangerhouse-admin-web/LICENSE) 开源协议发布。

---

## 📞 联系方式

- 🐛 Issue：[GitHub Issues](https://github.com/DzDenzel/dangerHouseSystem/issues)
- 📖 关联文档：[后端 README](../dangerhouse-backend/Readme.md) · [管理端 README](../dangerhouse-admin-web/README.md) · [AI 服务 README](../dangerhouse-ai-service/Readme.md)

---

<div align="center">

**⭐ 如果这个项目对你有帮助，请给一个 Star 支持一下！⭐**

Made with ❤️ by Danger House Team

**让危房检测更智能、更高效**

</div>
