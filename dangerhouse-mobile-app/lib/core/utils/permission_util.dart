import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/auth_models.dart';
import '../../providers/auth_provider.dart';

class PermissionUtil {
  static const String roleAdmin = 'ADMIN';
  static const String roleInspector = 'INSPECTOR';
  static const String roleUser = 'USER';

  static List<String> _roles(LoginResponse? user) =>
      (user?.roles ?? []).map((role) => role.toUpperCase()).toList();

  static bool isAdmin(LoginResponse? user) {
    if (user == null) return false;
    if (user.admin == true) return true;
    return _roles(user).contains(roleAdmin);
  }

  static bool isInspector(LoginResponse? user) {
    if (user == null) return false;
    final roles = _roles(user);
    return roles.contains(roleInspector);
  }

  static bool isUser(LoginResponse? user) {
    if (user == null) return false;
    final roles = _roles(user);
    return roles.contains(roleUser) && !isInspector(user) && !isAdmin(user);
  }

  static bool canDeleteBuilding(LoginResponse? user) {
    return isInspector(user);
  }

  static bool canLoginApp(LoginResponse? user) {
    return isUser(user) || isInspector(user);
  }

  static bool canEditBuilding(LoginResponse? user) {
    return user != null;
  }

  static bool canCreateBuilding(LoginResponse? user) {
    return user != null;
  }

  static bool canPerformDetection(LoginResponse? user) {
    return user != null;
  }

  static String getRoleDisplayName(LoginResponse? user) {
    if (user == null) return '未登录';
    if (isAdmin(user)) return '管理员';
    if (isInspector(user)) return '检测员';
    return '普通用户';
  }

  static List<String> getUserRoles(LoginResponse? user) {
    return user?.roles ?? [];
  }
}

final canDeleteBuildingProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return PermissionUtil.canDeleteBuilding(user);
});

final canEditBuildingProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return PermissionUtil.canEditBuilding(user);
});

final canPerformDetectionProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return PermissionUtil.canPerformDetection(user);
});

final userRoleDisplayNameProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return PermissionUtil.getRoleDisplayName(user);
});
