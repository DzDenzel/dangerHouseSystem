# DangerHouse App

<div align="center">

**危房智能检测系统 - 移动端应用**

[![Flutter](https://img.shields.io/badge/Flutter-3.2+-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.2+-0175C2?style=flat-square&logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web%20%7C%20Windows-blue?style=flat-square)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Version](https://img.shields.io/badge/Version-v3.3-orange?style=flat-square)](CHANGELOG.md)

[项目概述](#-项目概述) · [核心功能](#-核心功能) · [技术架构](#-技术架构) · [快速开始](#-快速开始) · [API文档](#-api接口文档)

</div>

---

## 📋 目录

- [项目概述](#-项目概述)
- [核心功能](#-核心功能)
- [技术架构](#-技术架构)
- [环境配置](#-环境配置)
- [安装部署](#-安装部署)
- [项目结构](#-项目结构)
- [API接口文档](#-api接口文档)
- [开发规范](#-开发规范)
- [测试体系](#-测试体系)
- [常见问题](#-常见问题)
- [贡献指南](#-贡献指南)
- [版本历史](#-版本历史)
- [许可证](#-许可证)

---

## 📖 项目概述

### 项目简介

DangerHouse App 是**危房智能检测系统**的移动端应用，基于 **Flutter** 跨平台技术框架开发。该应用作为危房检测业务的前端载体，承担着现场建筑数据采集、图片拍摄上传、AI 智能检测结果实时查看及历史检测报告管理等核心业务功能。

### 业务背景

在城市更新与老旧小区改造过程中，危房鉴定是一项关键且繁琐的工作。传统人工检测方式存在效率低、主观性强、记录不规范等问题。本系统通过移动端应用与后端 AI 服务的协同，实现了危房检测的数字化、智能化和标准化。

### 系统定位

```
┌─────────────────────────────────────────────────────────────────┐
│                    危房智能检测系统整体架构                        │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐  │
│  │ 移动端 APP  │ ←→ │  后端服务   │ ←→ │   AI 检测服务       │  │
│  │ (本项目)    │    │  (Spring)   │    │   (Python/PyTorch)  │  │
│  └─────────────┘    └─────────────┘    └─────────────────────┘  │
│         ↓                  ↓                     ↓              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐  │
│  │ 数据采集    │    │ 业务逻辑    │    │ 裂缝识别/风险评级   │  │
│  │ 图片拍摄    │    │ 数据存储    │    │ 损伤比例计算        │  │
│  │ 报告查看    │    │ 权限管理    │    │ 报告生成            │  │
│  └─────────────┘    └─────────────┘    └─────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### 核心价值

| 维度           | 传统方式                   | 本系统                              |
| :------------- | :------------------------- | :---------------------------------- |
| **检测效率**   | 人工现场勘查，耗时数小时   | 拍照上传，AI 实时分析，分钟级出结果 |
| **结果客观性** | 依赖检测人员经验，主观性强 | AI 算法量化评估，标准统一           |
| **数据管理**   | 纸质记录，易丢失难追溯     | 数字化存储，支持历史查询与统计      |
| **报告生成**   | 手工编写，格式不一         | 自动生成标准化报告，支持 PDF 导出   |

---

## ✨ 核心功能

### 业务流程

```
用户登录 → 创建建筑档案 → 拍摄/选择图片 → 上传检测 → AI分析 → 查看结果 → 生成报告
```

### 功能模块详解

#### 1. 用户认证模块

| 功能       | 描述                                                |
| :--------- | :-------------------------------------------------- |
| 账号登录   | 支持用户名、手机号、邮箱三种方式登录                |
| JWT 认证   | 基于 Token 的无状态认证机制，支持自动续期和刷新令牌 |
| 用户注册   | 新用户注册流程，包含用户名可用性校验                |
| 密码管理   | 支持密码修改、密码显隐切换                          |
| 账户安全   | 支持在个人中心进入账户与安全页面，完成账户密码更新   |
| 用户协议   | 注册时需同意用户服务协议                            |

#### 2. 首页仪表盘

| 功能       | 描述                                         |
| :--------- | :------------------------------------------- |
| 数据统计   | 展示建筑总数、检测总数、高风险数量等核心指标 |
| 风险分布   | 可视化展示 A/B/C/D 各等级建筑分布情况        |
| AI检测简报 | 今日 AI 检测数据概览，包含进度展示           |
| 快捷入口   | 提供建筑管理、检测任务、报告查看等快捷导航   |
| 消息通知   | 系统公告、检测完成通知等消息提醒             |

#### 3. 建筑档案管理

| 功能     | 描述                                               |
| :------- | :------------------------------------------------- |
| 建筑列表 | 分页展示所有建筑档案，支持下拉刷新与上拉加载       |
| 模糊搜索 | 按名称、地址进行模糊查询                           |
| 风险筛选 | 按风险等级（A/B/C/D）筛选建筑                      |
| 建筑创建 | 录入建筑名称、地址、结构类型、建造年份、面积等信息 |
| 建筑详情 | 查看建筑完整信息及关联的检测历史                   |
| 建筑编辑 | 修改建筑基本信息                                   |
| 建筑删除 | 删除不再需要的建筑档案                             |
| 归档管理 | 高风险建筑归档与定期监测跟踪                       |

#### 4. 拍摄检测模块

| 功能        | 描述                                     |
| :---------- | :--------------------------------------- |
| 自定义相机  | 内置相机界面，支持网格辅助线、闪光灯控制 |
| 图片选择    | 支持从相册选择已有图片进行检测           |
| 多图上传    | 单次支持上传多张图片进行联合分析         |
| 建筑关联    | 检测前需选择或创建关联的建筑档案         |
| 实时反馈    | 上传进度显示，检测状态实时更新           |
| AI 模型部署 | YOLOv8 模型实时部署状态提示              |

#### 5. 结果展示模块

| 功能     | 描述                                       |
| :------- | :----------------------------------------- |
| 裂缝标注 | 使用 Canvas 在原图上绘制 AI 识别的裂缝位置 |
| 风险评级 | 自动评定 A/B/C/D 四级风险等级              |
| 损伤分析 | 展示裂缝数量、损伤比例、置信度等详细数据   |
| 图片对比 | 原图与标注图片对比展示                     |
| 结果分享 | 支持分享检测结果图片                       |

#### 6. 检测报告模块

| 功能     | 描述                                               |
| :------- | :------------------------------------------------- |
| 报告列表 | 查看所有已生成的检测报告                           |
| 报告详情 | 查看报告完整内容，包含检测数据、风险建议、法规依据 |
| 报告生成 | 基于检测结果自动生成标准化评估报告                 |
| 整改建议 | 根据风险等级提供针对性整改建议                     |
| PDF 导出 | 支持将报告导出为 PDF 文件（规划中）                |

#### 7. 个人中心模块

| 功能     | 描述                                     |
| :------- | :--------------------------------------- |
| 用户信息 | 展示当前登录用户的头像、昵称、账号等信息 |
| 信息编辑 | 修改昵称、手机号、邮箱等个人信息         |
| 账户与安全 | 统一进入账户安全页，支持修改登录密码     |
| 头像上传 | 支持拍照或从相册选择头像                 |
| 检测档案 | 查看个人的所有检测历史记录               |
| 分析设置 | 调整 AI 分析模型的参数配置               |
| 帮助中心 | 使用指南、常见问题、联系客服             |
| 消息通知 | 系统通知与消息管理                       |

#### 8. 历史归档模块

| 功能     | 描述                                           |
| :------- | :--------------------------------------------- |
| 检测历史 | 按时间线展示所有检测记录                       |
| 状态筛选 | 按检测状态（待复核、分析中、已完成、失败）筛选 |
| 风险筛选 | 按风险等级（A/B/C/D）筛选                      |
| 危险建筑 | 专门展示已归档的高风险建筑清单                 |
| 定期监测 | 归档建筑的定期监测状态跟踪                     |

---

## 🏗️ 技术架构

### 技术栈选型

| 类别            | 技术                | 版本  | 选型理由                                         |
| :-------------- | :------------------ | :---: | :----------------------------------------------- |
| **开发框架**    | Flutter             | 3.2+  | 跨平台一致性高，一套代码支持 Android/Web/Windows |
| **编程语言**    | Dart                | 3.2+  | 强类型语言，支持空安全，语法现代                 |
| **状态管理**    | Riverpod            | 2.4+  | 响应式状态管理，编译时安全，易于测试             |
| **路由管理**    | go_router           | 14.0+ | 声明式路由，支持深链接和路由守卫                 |
| **网络请求**    | Dio                 | 5.4+  | 功能强大，支持拦截器、FormData、取消请求         |
| **本地存储**    | SharedPreferences   | 2.2+  | 轻量级 KV 存储，用于 Token 和用户配置持久化      |
| **JSON 序列化** | json_serializable   | 6.7+  | 代码生成方式，类型安全，减少手写模板代码         |
| **日期处理**    | intl                | 0.19+ | 国际化日期格式处理                               |
| **图片选择**    | image_picker        | 1.2+  | 统一的图片选择接口                               |
| **相机功能**    | camera              | 0.12+ | 自定义相机界面实现                               |
| **权限管理**    | permission_handler  | 12.0+ | 统一的权限请求接口                               |
| **加载提示**    | flutter_easyloading | 3.0+  | 全局加载与提示组件                               |
| **测试框架**    | mocktail            | 1.0+  | Mock 测试框架，用于单元测试和 Widget 测试        |
| **UI 设计**     | Material 3          |   -   | Google 最新设计规范，视觉现代统一                |

### 架构设计

项目采用 **Clean Architecture** 架构模式，结合 **MVVM** 设计思想，实现关注点分离：

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Presentation Layer                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────┐  │
│  │    Activities   │  │     Pages       │  │      Widgets        │  │
│  │   (UI Screens)  │  │  (Sub Pages)    │  │   (UI Components)   │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    Providers (State Management)              │    │
│  │   AuthProvider | DetectionProvider | SettingsProvider | ...  │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          Domain Layer                                │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────┐  │
│  │     Entities    │  │    Use Cases    │  │     Services        │  │
│  │  Task | Report  │  │  Auth | Detect  │  │  Auth | Detection   │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                           Data Layer                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────┐  │
│  │     Models      │  │  Repositories   │  │    Data Sources     │  │
│  │     (DTOs)      │  │  (Implement)    │  │   (Remote API)      │  │
│  │ Building | DTOs │  │ Auth | Building │  │   DioClient         │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          Core Layer                                  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────┐  │
│  │   Constants     │  │    Network      │  │       Utils         │  │
│  │ ApiConstants    │  │  DioClient      │  │  DateUtils          │  │
│  │ AppColors       │  │  AuthInterceptor│  │  RiskLevelUtil      │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────┘  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────┐  │
│  │      Auth       │  │     Router      │  │      Theme          │  │
│  │  TokenManager   │  │   go_router     │  │   AppTheme          │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────┘  │
│  ┌─────────────────┐  ┌─────────────────┐                          │
│  │     Errors      │  │     State       │                          │
│  │  ErrorHandler   │  │  BaseState      │                          │
│  └─────────────────┘  └─────────────────┘                          │
└─────────────────────────────────────────────────────────────────────┘
```

### 核心模块设计

#### 错误处理体系

```
AppException (抽象基类)
├── ValidationException    # 参数验证错误
├── UnauthorizedException  # 未授权错误 (401)
├── ForbiddenException     # 禁止访问错误 (403)
├── NotFoundException      # 资源不存在错误 (404)
├── ServerException       # 服务器错误 (500)
├── NetworkException      # 网络连接错误
├── TimeoutException      # 请求超时错误
├── CancelException       # 请求取消错误
└── UnknownException      # 未知错误
```

#### 状态管理模式

```
BaseState<T> (抽象基类)
├── SimpleState<T>        # 简单状态（加载、成功、失败）
│   ├── initial          # 初始状态
│   ├── loading          # 加载中
│   ├── success          # 成功（含数据）
│   └── failure          # 失败（含错误）
└── PaginatedState<T>     # 分页状态
    ├── initial          # 初始状态
    ├── loading          # 首次加载
    ├── loadingMore      # 加载更多
    ├── success          # 成功（含列表数据）
    ├── failure          # 失败
    └── empty            # 空数据
```

#### 路由管理

```dart
// 路由守卫示例
GoRouter(
  routes: [...],
  redirect: (context, state) {
    final isLoggedIn = TokenManager.instance.isLoggedIn;
    final isAuthRoute = state.matchedLocation.startsWith('/login');

    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }
    return null;
  },
);
```

### 数据流向

```
用户操作 → Widget → Provider → UseCase → Repository → DataSource → API
                ↓
            UI 更新 ← Provider 状态更新 ← Repository 返回数据
```

---

## 🔧 环境配置

### 开发环境要求

| 工具           | 最低版本 | 推荐版本 | 说明                  |
| :------------- | :------: | :------: | :-------------------- |
| Flutter SDK    |  3.2.0   |  3.16+   | 跨平台开发框架        |
| Dart SDK       |  3.2.0   |   3.2+   | 随 Flutter SDK 安装   |
| Android Studio |  2022.1  | 2023.1+  | Android 开发 IDE      |
| VS Code        |   1.70   |  最新版  | 推荐 Flutter 开发 IDE |
| Git            |   2.30   |  最新版  | 版本控制工具          |

### 平台特定要求

#### Android 开发

- Android SDK 21+ (Android 5.0)
- Java JDK 17+
- Android 模拟器或真机设备

#### Web 开发

- Chrome 浏览器（推荐用于调试）
- 支持 WebGL 的现代浏览器

#### Windows 开发

- Windows 10/11
- Visual Studio 2022（包含 C++ 桌面开发组件）

### 环境检查

```bash
# 检查 Flutter 环境
flutter doctor -v

# 预期输出应包含：
# [✓] Flutter (Channel stable, 3.x.x)
# [✓] Android toolchain
# [✓] Chrome - develop for the web
# [✓] Android Studio
# [✓] VS Code
```

---

## 🚀 安装部署

### 快速开始

#### 1. 克隆项目

```bash
git clone https://github.com/DzDenzel/dangerHouseSystem.git
cd dangerHouseSystem/dangerhouse-mobile-app
```

#### 2. 安装依赖

```bash
flutter pub get
```

#### 3. 生成代码

```bash
# 生成 JSON 序列化代码
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 4. 运行项目

```bash
# Web 端运行
flutter run -d chrome

# Windows 端运行
flutter run -d windows

# Android 模拟器运行
# 先ADB 端口转发，将模拟器的 8080 端口映射到主机的 8080 端口
[你的Android SDK 安装目录]\platform-tools\adb.exe reverse tcp:8080 tcp:8080
# 运行项目
flutter run -d <device_id>

# 查看可用设备
flutter devices
```

### 配置说明

#### API 地址配置

后端 API 地址配置位于 `lib/core/constants/api_constants.dart`：

```dart
class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';        // Web 端
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';         // Android 模拟器
    }
    return 'http://localhost:8080';          // Windows/其他
  }
}
```

**真机调试配置：**

如需真机调试，请将 `baseUrl` 修改为局域网 IP：

```dart
return 'http://192.168.1.100:8080';  // 替换为实际服务器 IP
```

#### 超时配置

```dart
static const int connectTimeout = 15000;  // 连接超时 15 秒
static const int receiveTimeout = 15000;  // 接收超时 15 秒
```

### 构建发布

#### Android APK 构建

```bash
# 构建 Release APK
flutter build apk --release

# 构建分架构 APK（体积更小）
flutter build apk --split-per-abi --release

# 输出位置：build/app/outputs/flutter-apk/
```

#### Web 构建

```bash
# 构建 Web 生产版本
flutter build web --release

# 输出位置：build/web/
```

#### Windows 构建

```bash
# 构建 Windows 应用
flutter build windows --release

# 输出位置：build/windows/runner/Release/
```

---

## 📂 项目结构

```
dangerhouse-mobile-app/
├── android/                          # Android 平台配置
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── kotlin/              # Android 原生代码
│   │   │   └── res/                 # Android 资源文件
│   │   └── build.gradle.kts         # 应用级构建配置
│   └── build.gradle.kts             # 项目级构建配置
│
├── assets/                           # 静态资源
│   └── images/                       # 图片资源
│       ├── app_logo.png
│       ├── app_logo_circular.png
│       └── old_building_background.jpg
│
├── integration_test/                 # 集成测试
│   └── app_test.dart
│
├── lib/                              # 主要源代码
│   ├── core/                         # 核心基础设施
│   │   ├── auth/                     # 认证模块
│   │   │   └── token_manager.dart    # Token 存储管理（支持刷新令牌）
│   │   ├── constants/                # 常量定义
│   │   │   ├── api_constants.dart    # API 路径常量
│   │   │   └── app_colors.dart       # 应用颜色常量
│   │   ├── errors/                   # 错误处理
│   │   │   ├── error_handler.dart    # 统一错误处理器
│   │   │   ├── errors.dart           # Result 类型定义
│   │   │   └── exceptions.dart       # 自定义异常类
│   │   ├── models/                   # 基础模型
│   │   │   └── base_model.dart       # Model 基类
│   │   ├── network/                  # 网络层
│   │   │   ├── api_response.dart     # API 响应封装
│   │   │   ├── dio_client.dart       # Dio 客户端封装
│   │   │   └── auth_interceptor.dart # 认证拦截器
│   │   ├── providers/                # 全局 Providers
│   │   │   └── network_providers.dart
│   │   ├── router/                   # 路由管理
│   │   │   ├── app_router.dart       # 路由配置
│   │   │   ├── app_routes.dart       # 路由常量
│   │   │   └── router.dart           # 导出文件
│   │   ├── state/                    # 状态管理基类
│   │   │   ├── base_state.dart       # 状态基类
│   │   │   ├── base_notifier.dart    # Notifier 基类
│   │   │   └── state.dart            # 导出文件
│   │   ├── theme/                    # 主题配置
│   │   │   ├── app_theme.dart        # 明暗主题
│   │   │   └── theme.dart            # 导出文件
│   │   ├── utils/                    # 工具类
│   │   │   ├── app_logger.dart       # 日志工具
│   │   │   ├── common_utils.dart     # 通用工具
│   │   │   ├── detection_status_util.dart
│   │   │   ├── refresh_utils.dart    # 刷新工具
│   │   │   ├── responsive_utils.dart # 响应式布局
│   │   │   ├── risk_level_util.dart  # 风险等级工具
│   │   │   └── utils.dart            # 导出文件
│   │   └── widgets/                  # 公共组件
│   │       ├── common_widgets.dart   # 通用组件
│   │       └── widgets.dart          # 导出文件
│   │
│   ├── data/                         # 数据层
│   │   ├── models/                   # 数据传输对象 (DTOs)
│   │   │   ├── auth_models.dart      # 认证相关模型
│   │   │   ├── auth_models.g.dart
│   │   │   ├── building_models.dart  # 建筑相关模型
│   │   │   ├── building_models.g.dart
│   │   │   ├── dashboard_models.dart # 仪表盘数据
│   │   │   ├── detection_models.dart # 检测结果模型
│   │   │   ├── detection_models.g.dart
│   │   │   ├── report_models.dart    # 报告模型
│   │   │   ├── report_models.g.dart
│   │   │   └── models.dart           # 导出文件
│   │   ├── repositories/             # 数据仓库实现
│   │   │   ├── auth_repository.dart
│   │   │   ├── base_repository.dart  # Repository 基类
│   │   │   ├── building_repository.dart
│   │   │   ├── detection_repository.dart
│   │   │   ├── report_repository.dart
│   │   │   ├── settings_repository.dart
│   │   │   ├── system_repository.dart
│   │   │   └── task_repository.dart
│   │   └── sources/                  # 数据源
│   │       ├── auth_remote_data_source.dart
│   │       ├── base_data_source.dart # DataSource 基类
│   │       ├── building_remote_data_source.dart
│   │       ├── detection_remote_data_source.dart
│   │       └── sources.dart          # 导出文件
│   │
│   ├── domain/                       # 领域层
│   │   ├── entities/                 # 业务实体
│   │   │   ├── detection_report.dart
│   │   │   ├── detection_report.g.dart
│   │   │   ├── task.dart
│   │   │   └── task.g.dart
│   │   ├── providers/                # 领域 Providers
│   │   │   ├── domain_providers.dart
│   │   │   └── providers.dart
│   │   ├── services/                 # 业务服务
│   │   │   ├── auth_service.dart
│   │   │   ├── building_service.dart
│   │   │   ├── detection_service.dart
│   │   │   └── services.dart
│   │   └── usecases/                 # 用例
│   │       ├── auth_usecases.dart
│   │       ├── base_usecase.dart     # UseCase 基类
│   │       ├── building_usecases.dart
│   │       ├── detection_usecases.dart
│   │       └── usecases.dart
│   │
│   ├── presentation/                 # 展示层
│   │   ├── capture/                  # 拍摄检测
│   │   │   ├── ai_detection_page.dart
│   │   │   ├── building_create_page.dart
│   │   │   ├── building_edit_page.dart
│   │   │   ├── building_selection_page.dart
│   │   │   ├── camera_grid_painter.dart
│   │   │   └── capture_activity.dart
│   │   ├── home/                     # 首页
│   │   │   ├── archived_dangerous_buildings_page.dart
│   │   │   ├── building_details_page.dart
│   │   │   ├── building_list_page.dart
│   │   │   ├── home_activity.dart
│   │   │   ├── home_content.dart
│   │   │   └── home_providers.dart
│   │   ├── login/                    # 登录注册
│   │   │   ├── login_activity.dart
│   │   │   └── register_activity.dart
│   │   ├── profile/                  # 个人中心
│   │   │   ├── analysis_settings_page.dart
│   │   │   ├── help_page.dart
│   │   │   ├── my_detection_archives_page.dart
│   │   │   ├── notifications_page.dart
│   │   │   ├── profile_activity.dart
│   │   │   └── user_info_edit_page.dart
│   │   ├── result/                   # 检测结果
│   │   │   ├── detection_painter.dart
│   │   │   └── result_activity.dart
│   │   └── task/                     # 检测任务
│   │       ├── report_detail_page.dart
│   │       └── report_page.dart
│   │
│   ├── providers/                    # 全局状态管理
│   │   ├── auth_provider.dart
│   │   ├── dashboard_provider.dart
│   │   ├── detection_provider.dart
│   │   ├── home_stats_provider.dart
│   │   ├── providers.dart            # 导出文件
│   │   ├── refresh_notifier.dart
│   │   ├── settings_provider.dart
│   │   └── task_provider.dart
│   │
│   ├── app.dart                      # 应用入口配置
│   └── main.dart                     # 主入口
│
├── test/                             # 测试代码
│   ├── helpers/                      # 测试辅助
│   │   ├── test_helpers.dart
│   │   └── widget_test_helpers.dart
│   ├── unit/                         # 单元测试
│   │   ├── providers/
│   │   │   └── auth_provider_test.dart
│   │   └── repositories/
│   │       ├── auth_repository_test.dart
│   │       └── building_repository_test.dart
│   └── widgets/                      # Widget 测试
│       └── login_activity_test.dart
│
├── pubspec.yaml                      # 项目配置
├── analysis_options.yaml             # Dart 分析配置
├── REFACTOR_PLAN.md                  # 重构计划文档
└── README.md                         # 项目说明文档
```

---

## � API接口文档

### 基础信息

| 项目     | 说明                        |
| :------- | :-------------------------- |
| 基础路径 | `http://localhost:8080/api` |
| 认证方式 | Bearer Token (JWT)          |
| 数据格式 | JSON                        |
| 字符编码 | UTF-8                       |

### 通用响应格式

```json
{
  "code": 200,
  "message": "success",
  "data": { ... },
  "timestamp": 1704067200000,
  "requestId": "uuid"
}
```

### 接口列表

#### 认证模块

| 接口       | 方法 | 路径                       | 说明                   |
| :--------- | :--: | :------------------------- | :--------------------- |
| 用户登录   | POST | `/api/auth/login`          | 用户名/手机号/邮箱登录 |
| 用户注册   | POST | `/api/auth/register`       | 新用户注册             |
| 检查用户名 | GET  | `/api/auth/check-username` | 检查用户名是否可用     |
| 刷新令牌   | POST | `/api/auth/refresh`        | 刷新访问令牌           |
| 退出登录   | POST | `/api/auth/logout`         | 用户退出登录           |

#### 用户模块

| 接口         | 方法 | 路径                 | 说明             |
| :----------- | :--: | :------------------- | :--------------- |
| 获取用户信息 | GET  | `/api/user/profile`  | 获取当前用户信息 |
| 更新用户信息 | PUT  | `/api/user/profile`  | 更新个人信息     |
| 修改密码     | PUT  | `/api/user/password` | 修改登录密码     |
| 上传头像     | POST | `/api/user/avatar`   | 上传用户头像     |

#### 建筑模块

| 接口     |  方法  | 路径                    | 说明             |
| :------- | :----: | :---------------------- | :--------------- |
| 建筑列表 |  GET   | `/api/buildings`        | 分页获取建筑列表 |
| 建筑详情 |  GET   | `/api/buildings/{id}`   | 获取建筑详情     |
| 创建建筑 |  POST  | `/api/buildings`        | 创建建筑档案     |
| 更新建筑 |  PUT   | `/api/buildings/{id}`   | 更新建筑信息     |
| 删除建筑 | DELETE | `/api/buildings/{id}`   | 删除建筑档案     |
| 搜索建筑 |  GET   | `/api/buildings/search` | 模糊搜索建筑     |

#### 检测模块

| 接口     | 方法 | 路径                          | 说明             |
| :------- | :--: | :---------------------------- | :--------------- |
| 检测列表 | GET  | `/api/detections`             | 获取检测记录列表 |
| 检测详情 | GET  | `/api/detections/{id}`        | 获取检测详情     |
| 上传检测 | POST | `/api/detections`             | 上传图片进行检测 |
| AI 检测  | POST | `/api/ai/detect`              | AI 裂缝检测接口  |
| 更新状态 | PUT  | `/api/detections/{id}/status` | 更新检测状态     |

#### 报告模块

| 接口     | 方法 | 路径                         | 说明         |
| :------- | :--: | :--------------------------- | :----------- |
| 报告列表 | GET  | `/api/reports`               | 获取报告列表 |
| 报告详情 | GET  | `/api/reports/{id}`          | 获取报告详情 |
| 生成报告 | POST | `/api/reports/generate`      | 生成检测报告 |
| 下载报告 | GET  | `/api/reports/{id}/download` | 下载报告文件 |

#### 管理模块

| 接口       | 方法 | 路径                        | 说明           |
| :--------- | :--: | :-------------------------- | :------------- |
| 仪表盘数据 | GET  | `/api/admin/dashboard`      | 获取仪表盘统计 |
| 操作日志   | GET  | `/api/admin/operation-logs` | 获取操作日志   |

---

## 📝 开发规范

### 代码规范

- 遵循 [Effective Dart](https://dart.dev/guides/language/effective-dart) 规范
- 使用 `flutter analyze` 进行静态代码分析
- 所有公共 API 必须添加文档注释
- 使用 `const` 构造函数优化性能

### 命名规范

| 类型     | 规范       | 示例                   |
| :------- | :--------- | :--------------------- |
| 文件名   | snake_case | `auth_repository.dart` |
| 类名     | PascalCase | `AuthRepository`       |
| 变量名   | camelCase  | `currentUser`          |
| 常量名   | camelCase  | `apiTimeout`           |
| 私有成员 | \_前缀     | `_dioClient`           |

### 目录规范

```
feature/                    # 功能模块
├── feature_name.dart       # 主入口
├── feature_name_page.dart  # 页面
├── feature_name_provider.dart  # 状态管理
└── widgets/               # 子组件
    └── feature_widget.dart
```

### Git 提交规范

```
feat: 新功能
fix: 修复 Bug
docs: 文档更新
style: 代码格式调整
refactor: 重构
test: 测试相关
chore: 构建/工具相关
```

---

## 🧪 测试体系

### 测试结构

```
test/
├── helpers/                    # 测试辅助工具
│   ├── test_helpers.dart       # 通用测试辅助
│   └── widget_test_helpers.dart # Widget 测试辅助
├── unit/                       # 单元测试
│   ├── providers/              # Provider 测试
│   └── repositories/           # Repository 测试
├── widgets/                    # Widget 测试
└── integration/                # 集成测试
```

### 运行测试

```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/unit/repositories/auth_repository_test.dart

# 运行测试并生成覆盖率报告
flutter test --coverage

# 运行集成测试
flutter test integration_test/app_test.dart
```

### 测试覆盖

| 模块               | 测试类型    | 覆盖内容               |
| :----------------- | :---------- | :--------------------- |
| AuthRepository     | 单元测试    | 登录、注册、Token 管理 |
| BuildingRepository | 单元测试    | 建筑 CRUD 操作         |
| AuthProvider       | 单元测试    | 认证状态管理           |
| LoginActivity      | Widget 测试 | 登录界面交互           |
| App Flow           | 集成测试    | 完整用户流程           |

---

## ❓ 常见问题

### Q1: 登录后 Token 丢失？

**A:** 检查 `TokenManager` 是否正确初始化，确保 `SharedPreferences` 已正确配置。

### Q2: 网络请求超时？

**A:** 检查后端服务是否启动，确认 `baseUrl` 配置正确。Android 模拟器使用 `10.0.2.2` 访问宿主机。

### Q3: 图片上传失败？

**A:** 检查文件大小限制，确保请求头包含正确的 `Content-Type: multipart/form-data`。

### Q4: 检测结果解析错误？

**A:** 后端返回的 `detectResult` 字段可能是 JSON 对象或 JSON 字符串，代码已兼容两种格式。

### Q5: 路由跳转失败？

**A:** 使用 `AppRouter` 提供的导航方法，确保路由路径在 `app_routes.dart` 中定义。

---

## 🤝 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'feat: Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

---

## 📅 版本历史

### v3.3.0 (2026-04-15)

**本次 3.3 技术增量更新：**

- ✅ 统一移动端登录页品牌 Logo 资源，切换为最新项目标准图
- ✅ 登录页品牌展示改为直接引用项目图片资源，统一 App 与 Web 的视觉识别
- ✅ 账户安全能力继续与后端密码修改接口保持一致，支撑用户端与检测员端统一密码更新流程

### v3.2.0 (2026-04-13)

**本次 3.2 技术增量更新：**

- ✅ App 登录请求新增 `clientType = APP`，由后端统一校验 App 端登录权限
- ✅ 检测员与普通用户登录链路统一接入后端登录端校验
- ✅ “记住我”功能支持本地记住账号信息
- ✅ 会话时长与后端统一：普通登录 `1` 小时，勾选“记住我”后 `3` 天
- ✅ 主动退出登录时先通知后端拉黑当前 JWT，再清理本地认证状态
- ✅ 修复主动退出后误提示“登录已过期”的问题，主动退出与会话过期改为独立处理链路
- ✅ 登录恢复逻辑增加角色校验，管理员不能凭本地缓存会话进入 App
- ✅ 注册页新增再次输入密码，补齐用户名格式校验、用户名查重与手机号查重
- ✅ 登录、注册、资料修改等错误提示改为业务化文案，减少“服务器内部错误”式提示
- ✅ 首页改为双首页模式：普通用户进入简化首页，检测员进入完整业务首页
- ✅ 新增普通用户首页与普通用户资料页，普通用户功能聚焦为“快速检测、我的建筑、我的检测记录、我的信息”
- ✅ 建筑列表、建筑详情、报告详情补齐归属字段展示，`createdByRole` 统一显示中文角色名

### v3.2.1 (2026-04-14)

**本次 3.2.1 技术增量更新：**

- ✅ 交付检测员端“我的 > 系统与配置 > 账户与安全”入口
- ✅ 交付普通用户端“我的 > 账户信息 > 账户与安全”入口
- ✅ 新增统一账户安全页与账户密码页，覆盖原密码校验、新密码校验与确认密码校验
- ✅ 完成 App 数据层对 `PUT /api/user/password` 的接入，支持普通用户与检测员在移动端修改密码
- ✅ 按单一业务身份划分普通用户与检测员页面能力边界

### v3.1.0 (2026-03-23)

**本次 3.1 技术增量更新：**

- ✅ 报告页检测时间统一复用项目日期反序列化与格式化工具，移除原始 ISO 时间中的 `T`
- ✅ 检测详情页与报告页补齐 `READY / FAILED / CREATED` 状态下的主操作逻辑
- ✅ `READY` 且已上传原图的任务统一显示“开始检测”，无需重复上传图片
- ✅ 去掉结果页自动轮询，改为手动“刷新状态”，避免 AI 服务未启动时页面持续请求
- ✅ 开始检测与重新检测增加防重复点击保护，避免同一任务被重复触发
- ✅ 已生成正式报告的记录直接跳转/下载已有报告，不再重复生成
- ✅ 检测记录列表增加“建筑名 + 检测备注”区分显示，便于同一建筑多次检测追踪
- ✅ AI 检测页将检测备注调整为业务必填项，用于区分每次检测任务
- ✅ AI 服务不可用时，前端统一使用业务化提示
- ✅ 检测、报告等关键动作完成后增加刷新事件广播，减少首页、记录页与详情页之间的数据不同步

### v3.0.0 (2026-03)

**本次 3.0 技术实现更新日志：**

- ✅ 首页右上角消息图标改为基于真实通知数据动态显示角标
- ✅ 检测记录页作为主导航页面移除左上角返回键，首页“全部记录”保持同一导航体验
- ✅ 登录页新增“记住我”能力，支持本地回填账号与密码
- ✅ 登录态校验链路优化，Token 过期后统一清理登录态并跳转登录页
- ✅ 个人中心登录信息与真实用户资料同步，避免页面间状态不一致
- ✅ 检测流程升级为任务状态流：上传中、上传成功、已创建、就绪、检测中、完成或失败
- ✅ AI 检测支持多图上传、结果页支持多图识别结果展示
- ✅ 检测报告页支持多张识别结果图回显与正式报告生成闭环
- ✅ 检测记录与报告页统一复用检测详情数据模型，减少重复解析和重复查询
- ✅ 通知功能改为基于真实建筑、检测、报告数据聚合生成
- ✅ 支持离线检测草稿缓存与后续手动同步
- ✅ Web 端 PDF 下载链路优化，规避浏览器插件拦截 XHR 导致的下载失败

### v2.5.0 (2025-03)

**建筑档案图片功能：**

- ✅ Building 实体新增 `imagePath` 字段
- ✅ 数据库添加 `image_path` 列
- ✅ 后端新增 UploadController 处理建筑图片上传
- ✅ 建筑创建/编辑页面支持图片上传
- ✅ 建筑列表和详情页显示建筑图片

**检测详情页面优化：**

- ✅ 未评定检测页面按钮文本改为"去检测"
- ✅ 实现直接检测功能（无需创建检测任务）
- ✅ 检测完成后自动更新检测结果

**登录页面优化：**

- ✅ Logo 图片更换为 `app_logo_circular.png`
- ✅ 优化 Logo 容器尺寸和显示效果
- ✅ 添加阴影效果提升视觉层次

**检测报告详情优化：**

- ✅ 报告详情页显示检测图片和标注结果
- ✅ 支持图片缩放查看
- ✅ 添加检测描述字段显示
- ✅ 优化数据可视化布局

**图片路径处理优化：**

- ✅ 创建 `ImageUtils` 工具类统一处理图片路径
- ✅ 支持本地路径和网络路径自动识别
- ✅ 后端 `FileUploadUtil` 修复路径重复问题
- ✅ 前端灵活适配后端配置变化

**检测历史优化：**

- ✅ 检测历史显示检测描述（如"第一次巡检"）
- ✅ 检测描述为空时显示检测类型
- ✅ 优化检测卡片信息展示

**代码质量优化：**

- ✅ 移除未使用的导入和变量
- ✅ 清理冗余代码和注释
- ✅ 修复 flutter analyze 警告

**Bug 修复：**

- ✅ 修复图片路径重复 `/uploads//uploads/` 问题
- ✅ 修复检测报告缺少检测描述问题
- ✅ 修复 `DetectionResultDto` 导入缺失问题
- ✅ 修复图片显示 `errorBuilder` 参数错误

### v2.4.0 (2025-03)

**检测结果页面优化：**

- ✅ 新增 `_buildNoResultPage()` 方法处理无检测结果场景
- ✅ 添加橙色图标提示和"暂无检测结果"标题
- ✅ 实现拍照检测和相册选择两种上传方式
- ✅ 完整的上传-检测-刷新流程
- ✅ 添加上传和检测过程的加载状态显示

**登录页面优化：**

- ✅ 修复 Logo 图片未填满圆形框问题
- ✅ 将 `BoxFit.cover` 改为 `BoxFit.fill`
- ✅ 添加阴影效果提升视觉层次

**个人中心数据优化：**

- ✅ 新增 `MonthlyStatsProvider` 月度统计提供者
- ✅ 前端计算本月检测数量和环比增长率
- ✅ 前端计算本月高危建筑数量
- ✅ 移除后端月度数据依赖，改为前端实时计算
- ✅ 支持增长/下降趋势图标动态切换

**已归档危险建筑优化：**

- ✅ 修复 A 级建筑错误显示问题
- ✅ 调整风险等级筛选参数为 `['B', 'C', 'D']`
- ✅ 确保只显示真正的危险建筑

**数据模型更新：**

- ✅ `DetectionResultDto` 新增 `createdAt` 字段
- ✅ 支持按创建时间筛选检测记录

**Bug 修复：**

- ✅ 修复 `RefreshEvent` 参数错误（使用 `notifyDetectionUpdated` 方法）
- ✅ 修复检测完成后数据不刷新问题

### v2.3.0 (2025-03)

**风险评定优化：**

- ✅ 实现综合风险等级评定算法
- ✅ 创建 RiskCalculationUtil 工具类
- ✅ 已归档建筑页面显示综合风险等级
- ✅ 建筑详情页根据检测记录动态计算风险

**权限管理：**

- ✅ 创建 PermissionUtil 权限工具类
- ✅ 建筑删除权限验证（仅管理员/管理者可删除）
- ✅ 删除按钮根据权限动态显示/隐藏
- ✅ 权限不足时显示友好提示

**快速检测功能：**

- ✅ 建筑详情页底部添加快速检测按钮
- ✅ 一键跳转 AI 检测页面（自动预选建筑）
- ✅ 检测完成后自动刷新建筑信息

**检测备注功能：**

- ✅ AI 检测页面添加备注输入框
- ✅ 支持输入检测描述（如"第二次巡检"）
- ✅ 备注信息同步提交至后端

**Bug 修复：**

- ✅ 修复 MouseTracker Assertion failed 错误
- ✅ 优化批量数据更新避免频繁 setState
- ✅ 修复已归档建筑风险等级显示问题

### v2.2.0 (2025-03)

**架构重构：**

- ✅ 实现完整的企业级架构重构
- ✅ 引入 Clean Architecture 分层架构
- ✅ 添加 Domain 层（Entities、UseCases、Services）
- ✅ 实现 DataSource 抽象层

**基础设施优化：**

- ✅ 统一错误处理体系（AppException 层次结构）
- ✅ 实现 ErrorHandler 统一异常处理
- ✅ 增强 TokenManager（支持刷新令牌、过期检查）
- ✅ 优化 DioClient 和 AuthInterceptor

**状态管理重构：**

- ✅ 创建 BaseState 状态基类
- ✅ 实现 SimpleState 和 PaginatedState
- ✅ 创建 BaseNotifier 通知器基类
- ✅ 重构所有 Provider 使用新状态模型

**路由管理：**

- ✅ 引入 go_router 声明式路由
- ✅ 实现路由守卫（登录验证）
- ✅ 支持深链接
- ✅ 类型安全的导航方法

**UI 层优化：**

- ✅ 提取公共组件到 common_widgets.dart
- ✅ 实现 AppTheme 主题系统（明暗主题）
- ✅ 添加响应式布局工具
- ✅ 修复多处布局溢出问题

**代码质量：**

- ✅ 添加完整代码文档注释
- ✅ 建立测试体系（单元测试、Widget 测试、集成测试）
- ✅ 修复 176+ prefer_const_constructors 警告
- ✅ 修复 deprecated API 调用（withOpacity → withValues）
- ✅ 清理未使用的导入和变量

**Bug 修复：**

- ✅ 修复 detectResult 字段类型解析错误
- ✅ 修复用户信息接口路径错误
- ✅ 修复任务列表布局溢出问题

### v1.0.0 (2025-01)

**新功能：**

- 用户认证模块（登录、注册、Token 管理）
- 首页仪表盘（数据统计、风险分布）
- 建筑档案管理（CRUD）
- 拍摄检测模块（自定义相机、图片上传）
- 结果展示模块（裂缝标注、风险评级）
- 检测报告模块（报告列表、详情查看）
- 个人中心模块（用户信息、设置）

**技术特性：**

- Clean Architecture 架构
- Riverpod 状态管理
- JWT 认证
- Material 3 设计

### 规划中

**3.0 后续可继续演进的方向：**

- [ ] 离线缓存机制（sqflite）
- [ ] AI 实时引导（AR 辅助）
- [ ] 推送通知（FCM/极光推送）
- [ ] 多语言支持（i18n）
- [ ] 图片缩略图体系
- [ ] CDN 优先访问链路
- [ ] 头像小图、列表图、详情图的统一缓存分层策略
- [ ] 报告图与原图的统一资源治理

---

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

---

## 📞 联系方式

如有问题或建议，请通过以下方式联系：

- 提交 Issue：[GitHub Issues](../../issues)
- 邮件联系：项目维护团队

---

<div align="center">

**DangerHouse App** © 2024 - Present

**让危房检测更智能、更高效**

</div>
