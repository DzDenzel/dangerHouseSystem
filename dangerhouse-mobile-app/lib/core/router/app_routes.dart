/// 应用路由路径常量
///
/// 定义所有应用内路由的路径字符串。
/// 使用静态常量确保路径的一致性和类型安全。
///
/// 示例:
/// ```dart
/// context.go(AppRoutes.home);
/// context.go('${AppRoutes.buildingDetailPath}/123');
/// ```
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

/// 路由名称常量
///
/// 定义所有路由的名称，用于命名路由导航。
///
/// 示例:
/// ```dart
/// context.goNamed(RouteNames.home);
/// context.goNamed(
///   RouteNames.buildingDetail,
///   pathParameters: {'id': '123'},
/// );
/// ```
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

/// 路由参数常量
///
/// 定义路由中使用的参数名称。
class RouteParams {
  RouteParams._();

  /// 通用ID参数
  static const String id = 'id';

  /// 建筑ID参数
  static const String buildingId = 'buildingId';

  /// 检测ID参数
  static const String detectionId = 'detectionId';

  /// 图片路径列表参数
  static const String imagePaths = 'imagePaths';
}

/// 深链接配置
///
/// 定义应用的深链接Scheme和Host。
///
/// 深链接格式: `dangerhouse://app/<path>`
///
/// 示例:
/// - `dangerhouse://app/home` - 打开首页
/// - `dangerhouse://app/building/123` - 打开建筑详情
/// - `dangerhouse://app/profile` - 打开个人中心
class DeepLinkSchemes {
  DeepLinkSchemes._();

  /// URL Scheme
  static const String scheme = 'dangerhouse';

  /// URL Host
  static const String host = 'app';

  /// 完整前缀
  static const String prefix = 'dangerhouse://app';
}
