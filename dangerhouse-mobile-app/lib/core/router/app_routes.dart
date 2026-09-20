/// 应用路由路径常量
abstract class AppRoutes {
  AppRoutes._();

  /// 启动页
  static const String splash = '/';

  /// 登录页
  static const String login = '/login';

  /// 注册页
  static const String register = '/register';

  /// 首页
  static const String home = '/home';

  /// 建筑详情页（带参数）
  static const String buildingDetail = '/building/:id';

  /// 建筑详情路径（用于拼接）
  static const String buildingDetailPath = '/building';

  /// 创建建筑页
  static const String buildingCreate = '/building/create';

  /// 编辑建筑页（带参数）
  static const String buildingEdit = '/building/:id/edit';

  /// 编辑建筑路径（用于拼接）
  static const String buildingEditPath = '/building/edit';

  /// 建筑列表页
  static const String buildingList = '/buildings';

  /// 已归档危险建筑页
  static const String archivedBuildings = '/buildings/archived';

  /// 拍摄页
  static const String capture = '/capture';

  /// 建筑选择页
  static const String buildingSelection = '/capture/building-selection';

  /// AI检测页
  static const String aiDetection = '/capture/ai-detection';

  /// 检测结果页
  static const String result = '/result';

  /// 检测结果详情页（带参数）
  static const String resultDetail = '/result/:id';

  /// 检测结果详情路径（用于拼接）
  static const String resultDetailPath = '/result';

  /// 个人中心页
  static const String profile = '/profile';

  /// 编辑个人信息页
  static const String profileEdit = '/profile/edit';

  /// 通知设置页
  static const String notifications = '/profile/notifications';

  /// 帮助页
  static const String help = '/profile/help';

  /// 分析设置页
  static const String analysisSettings = '/profile/analysis-settings';

  /// 我的检测档案页
  static const String myArchives = '/profile/archives';

  /// 报告页
  static const String report = '/report';

  /// 报告详情页（带参数）
  static const String reportDetail = '/report/:id';

  /// 报告详情路径（用于拼接）
  static const String reportDetailPath = '/report';
}

/// 路由名称常量，用于命名路由导航
abstract class RouteNames {
  RouteNames._();

  /// 启动页
  static const String splash = 'splash';

  /// 登录页
  static const String login = 'login';

  /// 注册页
  static const String register = 'register';

  /// 首页
  static const String home = 'home';

  /// 建筑详情页
  static const String buildingDetail = 'building_detail';

  /// 创建建筑页
  static const String buildingCreate = 'building_create';

  /// 编辑建筑页
  static const String buildingEdit = 'building_edit';

  /// 建筑列表页
  static const String buildingList = 'building_list';

  /// 已归档危险建筑页
  static const String archivedBuildings = 'archived_buildings';

  /// 拍摄页
  static const String capture = 'capture';

  /// 建筑选择页
  static const String buildingSelection = 'building_selection';

  /// AI检测页
  static const String aiDetection = 'ai_detection';

  /// 检测结果页
  static const String result = 'result';

  /// 检测结果详情页
  static const String resultDetail = 'result_detail';

  /// 个人中心页
  static const String profile = 'profile';

  /// 编辑个人信息页
  static const String profileEdit = 'profile_edit';

  /// 通知设置页
  static const String notifications = 'notifications';

  /// 帮助页
  static const String help = 'help';

  /// 分析设置页
  static const String analysisSettings = 'analysis_settings';

  /// 我的检测档案页
  static const String myArchives = 'my_archives';

  /// 报告页
  static const String report = 'report';

  /// 报告详情页
  static const String reportDetail = 'report_detail';
}
