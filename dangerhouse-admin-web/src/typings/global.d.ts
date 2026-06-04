declare global {
  /**
   * 分页查询参数
   */
  interface PageQuery {
    pageNum: number;
    pageSize: number;
  }

  /**
   * 通用分页结果对象
   */
  interface PageResult<T> {
    /** 数据列表 */
    list: T;
    /** 总数 */
    total: number;
  }

  interface PageResponse<T> {
    records: T;
    total: number;
    current: number;
    size: number;
    pages: number;
  }

  /**
   * 标签视图模型
   */
  interface TagView {
    /** 标签名称 */
    name: string;
    /** 标签标题 */
    title: string;
    /** 路由路径 */
    path: string;
    /** 完整路由路径 */
    fullPath: string;
    /** 可选图标 */
    icon?: string;
    /** 是否固定 */
    affix?: boolean;
    /** 是否缓存视图 */
    keepAlive?: boolean;
    /** 路由查询对象 */
    query?: any;
  }

  /**
   * 应用设置
   */
  interface AppSettings {
    /** 应用标题 */
    title: string;
    /** 应用版本 */
    version: string;
    /** 是否显示设置面板 */
    showSettings: boolean;
    /** 是否固定头部 */
    fixedHeader: boolean;
    /** 是否启用标签视图 */
    tagsView: boolean;
    /** 是否显示侧边栏Logo */
    sidebarLogo: boolean;
    /** 布局模式: left, top, mix */
    layout: string;
    /** 主题颜色 */
    themeColor: string;
    /** 主题模式: dark 或 light */
    theme: string;
    /** 组件尺寸 */
    size: string;
    /** 语言代码 */
    language: string;
    /** 是否启用水印 */
    watermarkEnabled: boolean;
    /** 水印内容 */
    watermarkContent: string;
  }

  /**
   * 通用选项项
   */
  interface OptionType {
    /** 选项值 */
    value: string | number;
    /** 选项标签 */
    label: string;
    /** 嵌套选项 */
    children?: OptionType[];
  }
}

export {};
