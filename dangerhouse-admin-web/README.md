<div align="center">

# 🏠 危房智能检测系统

**Dangerous House Intelligent Detection System — 管理端 Web**

[![Vue](https://img.shields.io/badge/Vue-3.4-4FC08D?style=flat-square&logo=vue.js&logoColor=white)](https://vuejs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.4-3178C6?style=flat-square&logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![Element Plus](https://img.shields.io/badge/Element%20Plus-2.7-409EFF?style=flat-square&logo=element&logoColor=white)](https://element-plus.org/)
[![Vite](https://img.shields.io/badge/Vite-5.2-646CFF?style=flat-square&logo=vite&logoColor=white)](https://vitejs.dev/)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Version](https://img.shields.io/badge/Version-v3.3-orange?style=flat-square)](#-版本历史)

**面向管理员的数据看板、建筑档案、检测管理与系统配置后台**

[项目简介](#-项目简介) • [核心能力](#-核心能力) • [技术架构](#-技术架构) • [快速开始](#-快速开始) • [版本历史](#-版本历史)

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
- [配置说明](#-配置说明)
- [构建与部署](#-构建与部署)
- [开发指南](#-开发指南)
- [常见问题](#-常见问题)
- [贡献指南](#-贡献指南)
- [版本历史](#-版本历史)
- [许可证](#-许可证)

---

## 📖 项目简介

`dangerhouse-admin-web` 是危房智能检测系统的 **管理端 Web 应用**，基于 **Vue 3 + TypeScript + Element Plus + Vite** 构建。仅 **管理员（ADMIN）** 可登录使用，提供数据看板、建筑档案、检测任务、报告管理、用户与检测员身份管理、操作日志等能力，通过 REST API 与 Java 后端通信。

### 系统定位

```
┌─────────────────────────────────────────────────────────────────┐
│                    危房智能检测系统整体架构                        │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐    ┌────────────┐ │
│  │ 管理端 Web      │    │  后端服务       │    │ AI 检测服务 │ │
│  │ (本项目)        │ ←→ │  Spring Boot    │ ←→ │  FastAPI    │ │
│  └─────────────────┘    └─────────────────┘    └────────────┘ │
│  ┌─────────────┐                                                │
│  │ 移动端 App  │ ←→ 同一后端 API                                 │
│  └─────────────┘                                                │
└─────────────────────────────────────────────────────────────────┘
```

### 核心价值

| 维度 | 说明 |
| :--- | :--- |
| **监管可视化** | ECharts 多维度图表展示检测统计、风险分布与趋势 |
| **权限隔离** | 登录携带 `clientType=WEB`，后端校验仅 ADMIN 可进入后台 |
| **账户安全** | 修改密码、退出拉黑 Token、记住账号不存密码 |
| **运维管理** | 用户状态、检测员身份切换、操作日志审计 |

---

## ✨ 核心能力

### 智能检测与档案

- **建筑档案**：列表、详情、创建/编辑、图片上传、归属与检测员字段展示
- **检测管理**：任务列表、详情、多图结果、状态流转与报告关联
- **报告管理**：报告生成、详情查看、PDF 下载

### 可视化看板

- 检测数据大屏：统计、风险分布、趋势分析
- 多图表联动：雷达图、饼图、柱状图、漏斗图

### 系统管理

- **用户管理**：分页查询、状态管理、设为/取消检测员
- **操作日志**：管理员操作审计与追溯
- **账户安全**：顶栏修改密码、退出确认对话框

---

## 🏗️ 技术架构

```
┌─────────────────────────────────────────────────────────────┐
│                        前端应用层                            │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐           │
│  │ 登录认证 │ │ 检测管理 │ │ 建筑档案 │ │ 系统设置 │           │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘           │
│       └───────────┴───────────┴───────────┘                 │
│                        Pinia 状态管理                        │
│                        Axios HTTP 客户端                     │
└────────────────────────┼────────────────────────────────────┘
                         │ HTTP/HTTPS  /api
┌────────────────────────┼────────────────────────────────────┐
│              Spring Boot 后端 + MySQL + Redis                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🛠️ 技术栈

| 层级 | 技术 | 版本 | 说明 |
| :--- | :--- | :--- | :--- |
| **框架** | Vue | 3.4.x | 渐进式前端框架 |
| **语言** | TypeScript | 5.4.x | 类型安全 |
| **UI** | Element Plus | 2.7.x | 企业级组件库 |
| **状态** | Pinia | 2.1.x | 官方推荐状态管理 |
| **路由** | Vue Router | 4.3.x | SPA 路由 |
| **构建** | Vite | 5.2.x | 开发与生产构建 |
| **HTTP** | Axios | 1.13.x | API 请求 |
| **图表** | ECharts | 5.5.x | 数据可视化 |
| **样式** | SCSS + UnoCSS | - | 样式与原子类 |
| **规范** | ESLint + Prettier + Stylelint | - | 代码质量工具 |

---

## 🚀 快速开始

### 环境要求

| 依赖 | 版本要求 |
| :--- | :--- |
| **Node.js** | >= 18.0.0 |
| **pnpm** | >= 8.0.0（项目强制使用 pnpm） |
| **后端服务** | `http://localhost:8080` 已启动 |

### 安装步骤

```bash
# 1. 克隆项目
git clone https://github.com/DzDenzel/dangerHouseSystem.git

# 2. 进入管理端目录
cd dangerHouseSystem/dangerhouse-admin-web

# 3. 安装依赖
pnpm install

# 4. 启动开发服务器（默认端口 3000）
pnpm run dev

# 5. 生产构建
pnpm run build:prod
```

开发环境默认通过 `.env.development` 将 API 代理到 `http://localhost:8080/api`。

---

## 📁 项目结构

```
dangerhouse-admin-web/
├── public/                  # 静态资源
├── src/
│   ├── api/                 # API 接口（auth、building、detection、report、user 等）
│   ├── assets/              # 图片、图标、样式
│   ├── components/          # 公共组件（Pagination、Upload、SvgIcon 等）
│   ├── layout/              # 布局（NavBar、Sidebar、TagsView）
│   ├── router/              # 路由与守卫
│   ├── store/               # Pinia 模块
│   ├── styles/              # 全局样式
│   ├── utils/               # 工具函数
│   ├── views/               # 页面（dashboard、building、detection、system、login）
│   ├── App.vue
│   └── main.ts
├── .env.development         # 开发环境变量
├── .env.production          # 生产环境变量
├── vite.config.ts
├── package.json
└── README.md
```

---

## ⚙️ 配置说明

### 环境变量（开发）

`.env.development` 常用项：

```env
VITE_APP_PORT=3000
VITE_APP_BASE_API=http://localhost:8080/api
VITE_MOCK_DEV_SERVER=false
VITE_SYSTEM_LOCAL_MODE=true
```

本地覆盖可在项目根目录创建 `.env.local`：

```env
VITE_APP_BASE_API=http://localhost:8080/api
VITE_SYSTEM_LOCAL_MODE=false
```

### 与后端协作要点

- 登录请求需携带 `clientType: "WEB"`。
- 请求头携带 `Authorization: Bearer <token>`。
- 退出调用 `POST /api/auth/logout`，确保 Token 进入后端黑名单。

---

## 📦 构建与部署

```bash
# 代码检查与格式化
pnpm run lint:eslint
pnpm run lint:prettier

# 生产构建（含 vue-tsc 类型检查）
pnpm run build:prod
```

构建产物输出至 `dist/`。部署时需：

1. 将 `VITE_APP_BASE_API` 指向生产后端地址。
2. 配置 Nginx 等反向代理的 `base` 路径与 SPA 回退。
3. 启用 HTTPS 并限制管理端访问来源。

---

## 📝 开发指南

### 分支管理

| 分支 | 说明 |
| :--- | :--- |
| `master` | 生产分支 |
| `develop` | 日常开发分支 |
| `feature/*` | 功能分支 |
| `hotfix/*` | 紧急修复 |

### 提交规范

采用 [Conventional Commits](https://www.conventionalcommits.org/)：

```bash
feat(detection): 新增检测报告导出功能
fix(auth): 修复 Token 刷新后路由守卫失效
docs: 更新管理端 README
```

### 代码规范

- 组件：**PascalCase**；文件：**kebab-case**
- 变量/函数：**camelCase**；常量：**UPPER_SNAKE_CASE**
- 提交前运行 `pnpm run lint:lint-staged`（Husky 已集成）

---

## ❓ 常见问题

### Q: 安装依赖失败？

**A:** 项目仅允许 pnpm。可尝试：

```bash
pnpm store prune
rm -rf node_modules
pnpm install
```

### Q: 开发服务器启动失败？

**A:** 检查 3000 端口占用，或在 `vite.config.ts` 中修改 `server.port`。

### Q: 登录后接口 401？

**A:** 确认后端已启动；检查 `VITE_APP_BASE_API`；确认使用管理员账号且 `clientType=WEB`。

### Q: 构建后页面空白？

**A:** 检查 `vite.config.ts` 的 `base` 是否与部署子路径一致。

### Q: 非管理员能打开页面？

**A:** 前端刷新时会校验 ADMIN 角色；非管理员应被清理会话并跳转登录页。若异常，检查后端角色与 Token 内容。

---

## 🤝 贡献指南

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'feat: add amazing feature'`)
4. 推送到分支并提交 Pull Request

---

## 📅 版本历史

### v3.3 (2026-04-15)

**本次 3.3 技术增量更新：**

- ✅ 顶部导航栏用户菜单新增稳定可用的「修改密码」入口
- ✅ 交付管理员修改密码对话框，覆盖原密码、新密码与确认密码的完整表单校验
- ✅ 退出登录确认由提示框升级为独立居中对话框
- ✅ 后台登录页与侧边栏统一切换为最新项目 Logo
- ✅ 顶栏用户操作区交互结构完成重构

### v3.2.1 (2026-04-14)

**本次 3.2.1 技术增量更新：**

- ✅ 用户管理页「设为检测员 / 取消检测员」操作入口
- ✅ Web 端 `USER` 与 `INSPECTOR` 单一业务身份切换
- ✅ 用户详情抽屉角色信息即时更新

### v3.2 (2026-04-13)

**本次 3.2 技术增量更新：**

- ✅ 登录请求新增 `clientType = WEB`，后端统一校验后台登录权限
- ✅ 「记住我」只记住账号，不再本地保存密码
- ✅ 主动退出调用 `/auth/logout`，旧 Token 立即失效
- ✅ 页面刷新增加管理员角色兜底校验
- ✅ 建筑/检测/报告页补齐归属字段展示
- ✅ 用户管理统计口径修正

### v3.1 及更早

- 数据看板、检测管理、报告下载、用户列表等基础后台能力
- 对接后端 v3.x 检测状态流与 Redis 缓存体系

---

## 📄 许可证

本项目基于 [MIT License](LICENSE) 开源协议发布。

---

## 📞 联系方式

- 🐛 Issue：[GitHub Issues](https://github.com/DzDenzel/dangerHouseSystem/issues)
- 📖 关联文档：[后端 README](../dangerhouse-backend/Readme.md) · [移动端 README](../dangerhouse-mobile-app/Readme.md) · [AI 服务 README](../dangerhouse-ai-service/Readme.md)

---

<div align="center">

**⭐ 如果这个项目对你有帮助，请给一个 Star 支持一下！⭐**

Made with ❤️ by Danger House Team

**让危房检测更智能、更高效**

</div>
