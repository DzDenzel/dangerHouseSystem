import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/network_providers.dart';

class MonthlyStats {
  final int monthlyDetectionCount;
  final int monthlyHighRiskCount;
  final double growthRate;

  MonthlyStats({
    required this.monthlyDetectionCount,
    required this.monthlyHighRiskCount,
    required this.growthRate,
  });
}

class MonthlyStatsNotifier extends StateNotifier<AsyncValue<MonthlyStats>> {
  final Ref ref;

  MonthlyStatsNotifier(this.ref) : super(const AsyncValue.loading());

  Future<void> fetchMonthlyStats() async {
    state = const AsyncValue.loading();
    
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      
      final monthStartStr = monthStart.toIso8601String().split('T')[0];
      final nowStr = now.toIso8601String().split('T')[0];
      final lastMonthStartStr = lastMonthStart.toIso8601String().split('T')[0];
      final monthEndStr = monthStart.subtract(const Duration(seconds: 1)).toIso8601String().split('T')[0];

      final detectionRepo = ref.read(detectionRepositoryProvider);
      
      final currentMonthDetections = await detectionRepo.getDetections(
        startDate: monthStartStr,
        endDate: nowStr,
        size: 1000,
      );

      final lastMonthDetections = await detectionRepo.getDetections(
        startDate: lastMonthStartStr,
        endDate: monthEndStr,
        size: 1000,
      );

      int monthlyHighRiskCount = 0;
      for (final detection in currentMonthDetections) {
        if (detection.riskLevel == 'C' || detection.riskLevel == 'D') {
          monthlyHighRiskCount++;
        }
      }

      final currentMonthCount = currentMonthDetections.length;
      final lastMonthCount = lastMonthDetections.length;
      
      double growthRate = 0.0;
      if (lastMonthCount > 0) {
        growthRate = ((currentMonthCount - lastMonthCount) / lastMonthCount) * 100;
      } else if (currentMonthCount > 0) {
        growthRate = 100.0;
      }

      state = AsyncValue.data(MonthlyStats(
        monthlyDetectionCount: currentMonthCount,
        monthlyHighRiskCount: monthlyHighRiskCount,
        growthRate: growthRate,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final monthlyStatsProvider = StateNotifierProvider<MonthlyStatsNotifier, AsyncValue<MonthlyStats>>((ref) {
  final notifier = MonthlyStatsNotifier(ref);
  notifier.fetchMonthlyStats();
  return notifier;
});
