import { SizeEnum } from "./enums/SizeEnum";
import { LayoutEnum } from "./enums/LayoutEnum";
import { ThemeEnum } from "./enums/ThemeEnum";
import { LanguageEnum } from "./enums/LanguageEnum";

// 注释：pkg.name 是从 package.json 读取的项目名（原 vue3-element-admin），直接替换为自定义名称
// const { pkg } = __APP_INFO__;

const defaultSettings: AppSettings = {
  // 左侧顶部标题
  title: "危房智诊管理系统",
  // 版本号
  version: "1.0.0",
  showSettings: true,
  tagsView: true,
  fixedHeader: true,
  sidebarLogo: true,
  layout: LayoutEnum.LEFT,
  theme: ThemeEnum.LIGHT,
  size: SizeEnum.DEFAULT,
  language: LanguageEnum.ZH_CN,
  themeColor: "#409EFF",
  watermarkEnabled: false,
  // 水印文本（如果开启水印，显示「危房智诊」）
  watermarkContent: "危房智诊",
};

export default defaultSettings;
