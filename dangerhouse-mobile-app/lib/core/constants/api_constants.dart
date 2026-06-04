import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

class ApiConstants {
  ApiConstants._();

  static const String currentBaseUrl = String.fromEnvironment(
    'APP_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static String get baseUrl => currentBaseUrl;

  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;

  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String logout = '/api/auth/logout';
  static String checkUsername(String username) => '/api/auth/check-username/$username';
  static String checkPhone(String phone) => '/api/auth/check-phone/$phone';

  static const String userProfile = '/api/user/profile';
  static const String changePassword = '/api/user/password';
  static const String userAvatar = '/api/user/avatar';

  static const String users = '/api/users';
  static const String currentUser = '/api/user/profile';
  static const String updateUser = '/api/user/profile';
  static const String uploadAvatar = '/api/user/avatar';

  static const String buildings = '/api/buildings';
  static const String buildingsSearch = '/api/buildings/search';

  static const String detection = '/api/detections';
  static const String taskList = '/api/detections';

  static const String aiDetect = '/api/ai/detect';

  static const String reports = '/api/reports';
  static const String reportGenerate = '/api/reports/generate';

  static const String adminDashboard = '/api/admin/dashboard';
  static const String adminOperationLogs = '/api/admin/operation-logs';

  static const String health = '/api/health';
  static const String upload = '/api/upload';
}
