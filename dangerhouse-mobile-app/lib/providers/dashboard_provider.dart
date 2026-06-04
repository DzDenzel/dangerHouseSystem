import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/network_providers.dart';
import '../../core/utils/app_logger.dart';
import '../../data/models/dashboard_models.dart';

final dashboardProvider = FutureProvider<DashboardDto>((ref) async {
  final repository = ref.watch(systemRepositoryProvider);

  try {
    AppLogger.api('GET', '/api/admin/dashboard');

    final result = await repository.getDashboard();
    if (result != null) {
      return DashboardDto.fromJson(result);
    }
    throw Exception('获取仪表盘数据失败');
  } catch (e) {
    AppLogger.e('获取仪表盘数据失败', e);
    rethrow;
  }
});

final dashboardDataProvider = Provider<DashboardDto?>((ref) {
  final asyncValue = ref.watch(dashboardProvider);
  return asyncValue.valueOrNull;
});

final dashboardLoadingProvider = Provider<bool>((ref) {
  final asyncValue = ref.watch(dashboardProvider);
  return asyncValue.isLoading;
});

final dashboardErrorProvider = Provider<String?>((ref) {
  final asyncValue = ref.watch(dashboardProvider);
  return asyncValue.error?.toString();
});
