<div align="center">

# 🏠 危房智能检测系统

**Dangerous House Intelligent Detection System**

[![Vue](https://img.shields.io/badge/Vue-3.x-4FC08D?style=flat-square&logo=vue.js&logoColor=white)](https://vuejs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178C6?style=flat-square&logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![Element Plus](https://img.shields.io/badge/Element%20Plus-2.x-409EFF?style=flat-square&logo=element&logoColor=white)](https://element-plus.org/)
[![Vite](https://img.shields.io/badge/Vite-5.x-646CFF?style=flat-square&logo=vite&logoColor=white)](https://vitejs.dev/)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

**一套集成深度学习与空间聚类算法的高精度建筑安全检测解决方案**

[功能特性](#-功能特性) • [技术架构](#-技术架构) • [快速开始](#-快速开始) • [项目结构](#-项目结构) • [开发指南](#-开发指南)

</div>

---

## 📖 项目简介

危房智能检测系统是一套面向建筑安全监管领域的智能化解决方案，通过深度学习模型与空间聚类算法的深度融合，实现了从图像采集到风险判别的全链路 AI 自动化分析。系统旨在提升建筑安全隐患排查效率，降低人工检测成本，为城市建筑安全管理提供数据驱动的决策支持。

### 核心技术亮点

| 技术模块 | 实现方案 | 技术优势 |
|---------|---------|---------|
| **深度特征识别** | Faster R-CNN ResNet50 v2 | 针对建筑裂缝、墙体剥落及结构变形进行亚像素级特征提取与分类识别 |
| **空间聚类分析** | DBSCAN 聚类算法 | 对多源检测数据进行空间降噪与关联聚合，自动消除重复检测点并识别核心风险区域 |
| **自动化评估** | 权重模型 + 规则引擎 | 结合隐患密度与严重程度自动生成风险评级，支持 A/B/C/D 四级风险分类 |

---

## ✨ 功能特性

### 🔍 智能检测分析
- **多维度特征识别**：支持裂缝宽度、剥落面积、变形程度等多维度检测指标
- **实时数据处理**：毫秒级响应，支持批量图像并发处理
- **置信度评估**：每项检测结果附带置信度评分，便于人工复核

### 📊 可视化看板
- **检测数据大屏**：实时展示检测统计、风险分布、趋势分析
- **多图表联动**：雷达图、饼图、柱状图、漏斗图多维数据可视化
- **地理信息集成**：支持建筑位置标注与风险热力图展示

### 🚨 预警管理系统
- **动态预警机制**：高风险建筑自动标注与预警推送
- **多级响应策略**：根据风险等级自动匹配处置流程
- **闭环跟踪**：从预警发起到处置完成的全流程追踪

### 📁 文档与报告
- **自动化报告生成**：检测完成后自动生成标准化报告
- **云端存储集成**：深度接入阿里云 OSS，实现报告持久化存储与安全下载
- **多格式导出**：支持 PDF、Word 等多种格式导出

### 👥 用户权限管理
- **RBAC 权限模型**：基于角色的精细化权限控制
- **检测员身份切换**：管理员可在用户管理页执行“设为检测员 / 取消检测员”，按单一身份进行角色切换
- **多租户支持**：支持按部门/区域进行数据隔离
- **操作日志审计**：完整的用户操作记录与追溯

---

## 🏗️ 技术架构

```
┌─────────────────────────────────────────────────────────────┐
│                        前端应用层                            │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐           │
│  │ 登录认证 │ │ 检测管理 │ │ 建筑档案 │ │ 系统设置 │           │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘           │
│       │           │           │           │                 │
│  ┌────┴───────────┴───────────┴───────────┴────┐           │
│  │              Pinia 状态管理                  │           │
│  └─────────────────────┬───────────────────────┘           │
│                        │                                    │
│  ┌─────────────────────┴───────────────────────┐           │
│  │              Axios HTTP 客户端               │           │
│  └─────────────────────┬───────────────────────┘           │
└────────────────────────┼────────────────────────────────────┘
                         │ HTTP/HTTPS
┌────────────────────────┼────────────────────────────────────┐
│                        │         后端服务层                   │
│  ┌─────────────────────┴───────────────────────┐           │
│  │              Spring Boot API                 │           │
│  └─────────────────────┬───────────────────────┘           │
│                        │                                    │
│  ┌──────────┬──────────┼──────────┬──────────┐            │
│  │ MySQL    │  Redis   │ 阿里云OSS │ AI 模型   │            │
│  │ 数据存储  │  缓存    │ 文件存储  │ 推理服务  │            │
│  └──────────┴──────────┴──────────┴──────────┘            │
└─────────────────────────────────────────────────────────────┘
```

### 技术栈详情

| 层级 | 技术 | 版本 | 说明 |
|-----|------|-----|------|
| **框架** | Vue | 3.x | 渐进式 JavaScript 框架 |
| **语言** | TypeScript | 5.x | JavaScript 的超集，提供类型安全 |
| **UI 组件** | Element Plus | 2.x | 基于 Vue 3 的企业级 UI 组件库 |
| **状态管理** | Pinia | 2.x | Vue 官方推荐的状态管理库 |
| **路由** | Vue Router | 4.x | Vue.js 官方路由管理器 |
| **构建工具** | Vite | 5.x | 下一代前端构建工具 |
| **HTTP 客户端** | Axios | 1.x | 基于 Promise 的 HTTP 客户端 |
| **图表库** | ECharts | 5.x | 功能强大的数据可视化图表库 |
| **CSS 预处理** | SCSS | - | 成熟稳定的 CSS 预处理器 |
| **代码规范** | ESLint + Prettier | - | 代码质量与格式化工具 |

---

## 🚀 快速开始

### 环境要求

- **Node.js**: >= 18.0.0
- **pnpm**: >= 8.0.0 (推荐) 或 npm/yarn
- **浏览器**: Chrome >= 90, Firefox >= 88, Safari >= 14, Edge >= 90

### 安装步骤

```bash
# 1. 克隆项目
git clone https://github.com/DzDenzel/dangerHouseSystem.git

# 2. 进入项目目录
cd dangerHouseSystem/dangerhouse-admin-web

# 3. 安装依赖 (推荐使用 pnpm)
pnpm install

# 4. 启动开发服务器
pnpm run dev

# 5. 构建生产版本
pnpm run build

# 6. 代码格式化
pnpm run lint
```

### 环境配置

在项目根目录创建 `.env.local` 文件进行本地环境配置：

```env
# API 基础地址
VITE_API_BASE_URL=http://localhost:8080/api

# 是否启用本地模拟数据
VITE_SYSTEM_LOCAL_MODE=false
```

---

## 📁 项目结构

```
dangerhouse-admin-web/
├── docs/                    # 项目文档
├── public/                  # 静态资源
├── src/
│   ├── api/                 # API 接口定义
│   │   ├── auth/           # 认证相关接口
│   │   ├── building/       # 建筑档案接口
│   │   ├── detection/      # 检测管理接口
│   │   ├── menu/           # 菜单管理接口
│   │   ├── report/         # 报告管理接口
│   │   └── user/           # 用户管理接口
│   ├── assets/             # 静态资源 (图片、图标、样式)
│   ├── components/         # 公共组件
│   │   ├── Breadcrumb/     # 面包屑组件
│   │   ├── Pagination/     # 分页组件
│   │   ├── SvgIcon/        # SVG 图标组件
│   │   └── Upload/         # 文件上传组件
│   ├── enums/              # 枚举定义
│   ├── lang/               # 国际化配置
│   ├── layout/             # 布局组件
│   │   ├── components/     # 布局子组件
│   │   │   ├── NavBar/    # 顶部导航栏
│   │   │   ├── Sidebar/   # 侧边栏菜单
│   │   │   ├── TagsView/  # 标签页视图
│   │   │   └── Settings/  # 设置面板
│   ├── plugins/            # 插件配置
│   ├── router/             # 路由配置
│   ├── store/              # 状态管理
│   │   └── modules/       # 状态模块
│   ├── styles/             # 全局样式
│   ├── typings/            # TypeScript 类型定义
│   ├── utils/              # 工具函数
│   ├── views/              # 页面视图
│   │   ├── building/      # 建筑档案管理
│   │   ├── dashboard/     # 数据看板
│   │   ├── detection/     # 检测管理
│   │   ├── login/         # 登录页面
│   │   └── system/        # 系统管理
│   ├── App.vue             # 根组件
│   └── main.ts             # 入口文件
├── .env                    # 环境变量
├── .eslintrc.js            # ESLint 配置
├── .prettierrc             # Prettier 配置
├── index.html              # HTML 模板
├── package.json            # 项目配置
├── tsconfig.json           # TypeScript 配置
└── vite.config.ts          # Vite 配置
```

---

## 📐 开发指南

### 分支管理

| 分支 | 说明 |
|-----|------|
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

**Type 类型说明：**

| 类型 | 说明 |
|-----|------|
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
feat(detection): 新增检测报告导出功能

- 支持 PDF 格式导出
- 支持 Word 格式导出
- 添加导出进度提示

Closes #123
```

### 代码规范

- 遵循 ESLint 规则进行代码检查
- 使用 Prettier 进行代码格式化
- 组件命名采用 PascalCase
- 文件命名采用 kebab-case
- 变量/函数命名采用 camelCase
- 常量命名采用 UPPER_SNAKE_CASE

---

## 📅 更新日志

### v3.3.0 (2026-04-15)

**本次 3.3 技术增量更新：**

- ✅ 顶部导航栏用户菜单新增稳定可用的“修改密码”入口
- ✅ 交付管理员修改密码对话框，覆盖原密码、新密码与确认密码的完整表单校验
- ✅ 退出登录确认由提示框交互升级为独立居中对话框，提升后台操作一致性
- ✅ 后台登录页与侧边栏统一切换为最新项目 Logo 资源
- ✅ 顶栏用户操作区交互结构完成重构，提升账户安全与退出操作的可发现性

### v3.2.0 (2026-04-13)

**本次 3.2 技术增量更新：**

- ✅ Web 登录请求新增 `clientType = WEB`
- ✅ 非管理员账号由后端统一执行后台登录权限校验
- ✅ 登录失败提示支持单次弹出与统一错误反馈
- ✅ 请求拦截器错误提示统一收口，减少模糊的服务器错误反馈
- ✅ “记住我”改为只记住账号，不再本地保存密码
- ✅ 主动退出登录改为调用后端 `/auth/logout`，确保旧 Token 立即失效
- ✅ 页面刷新恢复会话时增加管理员角色兜底校验，非管理员自动清理状态并跳回登录页
- ✅ 建筑列表页新增创建角色、绑定用户摘要展示
- ✅ 建筑详情页补齐 `ownerUserId / createdBy / createdByRole / assignedInspectorId`
- ✅ 检测详情页与报告页补齐建筑归属信息展示
- ✅ 用户管理统计口径修正，避免总数与数据库真实数据不一致

### v3.2.1 (2026-04-14)

**本次 3.2.1 技术增量更新：**

- ✅ 交付用户管理页“设为检测员 / 取消检测员”操作入口
- ✅ 完成 Web 端 `USER` 与 `INSPECTOR` 单一业务身份切换管理
- ✅ 完成用户详情抽屉中的角色信息即时更新
- ✅ 统一后台角色展示与角色切换交互文案

## � 常见问题

### Q: 安装依赖失败？

**A:** 尝试以下解决方案：
```bash
# 清除缓存
pnpm store prune

# 删除 node_modules 重新安装
rm -rf node_modules
pnpm install
```

### Q: 开发服务器启动失败？

**A:** 检查端口是否被占用，或修改 `vite.config.ts` 中的端口配置：
```ts
export default defineConfig({
  server: {
    port: 3000  // 修改为其他端口
  }
})
```

### Q: 构建后页面空白？

**A:** 检查 `vite.config.ts` 中的 `base` 配置是否正确：
```ts
export default defineConfig({
  base: '/'  // 根据部署路径调整
})
```

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

## 📄 许可证

本项目基于 [MIT License](LICENSE) 开源协议发布。

---

## 📞 联系方式

如有问题或建议，欢迎通过以下方式联系我们：

- 📧 Email: support@example.com
- 🐛 Issue: [GitHub Issues](https://github.com/DzDenzel/dangerHouseSystem/issues)
- 📖 文档: [项目文档](./docs)

---

<div align="center">

**⭐ 如果这个项目对你有帮助，请给一个 Star 支持一下！⭐**

Made with ❤️ by Danger House Team

</div>
