import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/common_utils.dart' as app_utils;
import '../../data/models/detection_models.dart';
import '../../core/providers/network_providers.dart';

class HomeStats {
  final int todayCount;
  final int criticalCount;
  final int aiConfidence;
  final int levelACount;
  final int levelBCount;
  final int levelCCount;
  final int levelDCount;
  final List<DetectionResultDto> recentDetections;

  const HomeStats({
    required this.todayCount,
    required this.criticalCount,
    required this.aiConfidence,
    required this.levelACount,
    required this.levelBCount,
    required this.levelCCount,
    required this.levelDCount,
    required this.recentDetections,
  });

  factory HomeStats.empty() {
    return const HomeStats(
      todayCount: 0,
      criticalCount: 0,
      aiConfidence: 0,
      levelACount: 0,
      levelBCount: 0,
      levelCCount: 0,
      levelDCount: 0,
      recentDetections: [],
    );
  }

  factory HomeStats.error() {
    return const HomeStats(
      todayCount: 0,
      criticalCount: 0,
      aiConfidence: 0,
      levelACount: 0,
      levelBCount: 0,
      levelCCount: 0,
      levelDCount: 0,
      recentDetections: [],
    );
  }
}

final homeStatsProvider = FutureProvider<HomeStats>((ref) async {
  final repository = ref.watch(detectionRepositoryProvider);
  final now = DateTime.now();

  final todayStart = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final todayEnd = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  final monthStart = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
  final monthEnd = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  final weekAgo = now.subtract(const Duration(days: 7));
  final weekStart = '${weekAgo.year}-${weekAgo.month.toString().padLeft(2, '0')}-${weekAgo.day.toString().padLeft(2, '0')}';
  final weekEnd = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  try {
    AppLogger.d('开始获取首页统计数据');

    final todayDetections = await repository.getDetections(
      startDate: todayStart,
      endDate: todayEnd,
    );

    final monthDetections = await repository.getDetections(
      startDate: monthStart,
      endDate: monthEnd,
    );

    final recentDetections = await repository.getDetections(
      startDate: weekStart,
      endDate: weekEnd,
    );

    int levelA = 0;
    int levelB = 0;
    int levelC = 0;
    int levelD = 0;
    int criticalCount = 0;

    for (var detection in monthDetections) {
      final riskLevel = detection.riskLevel;
      if (riskLevel == 'A' || riskLevel == 'LOW') levelA++;
      if (riskLevel == 'B' || riskLevel == 'MEDIUM') levelB++;
      if (riskLevel == 'C' || riskLevel == 'HIGH') {
        levelC++;
        criticalCount++;
      }
      if (riskLevel == 'D' || riskLevel == 'CRITICAL') {
        levelD++;
        criticalCount++;
      }
    }

    recentDetections.sort((a, b) {
      return app_utils.DateUtils.compareDateTime(a.detectTime, b.detectTime);
    });

    int aiConfidence = 0;
    if (recentDetections.isNotEmpty) {
      double totalConfidence = 0;
      int validCount = 0;
      for (var detection in recentDetections) {
        if (detection.confidence != null) {
          totalConfidence += detection.confidence!;
          validCount++;
        }
      }
      if (validCount > 0) {
        aiConfidence = (totalConfidence / validCount).round();
      }
    }

    AppLogger.i('首页统计数据获取成功: 今日${todayDetections.length}条, 高风险$criticalCount个');

    return HomeStats(
      todayCount: todayDetections.length,
      criticalCount: criticalCount,
      aiConfidence: aiConfidence,
      levelACount: levelA,
      levelBCount: levelB,
      levelCCount: levelC,
      levelDCount: levelD,
      recentDetections: recentDetections.take(10).toList(),
    );
  } catch (e) {
    AppLogger.e('获取首页统计数据失败', e);
    return HomeStats.error();
  }
});

final todayDetectionsProvider = FutureProvider<List<DetectionResultDto>>((ref) async {
  final repository = ref.watch(detectionRepositoryProvider);
  final now = DateTime.now();

  final todayStart = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final todayEnd = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  try {
    final detections = await repository.getDetections(
      startDate: todayStart,
      endDate: todayEnd,
    );

    detections.sort((a, b) {
      return app_utils.DateUtils.compareDateTime(a.detectTime, b.detectTime);
    });

    return detections;
  } catch (e) {
    AppLogger.e('获取今日检测记录失败', e);
    return [];
  }
});

final monthDetectionsProvider = FutureProvider<List<DetectionResultDto>>((ref) async {
  final repository = ref.watch(detectionRepositoryProvider);
  final now = DateTime.now();

  final monthStart = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
  final monthEnd = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  try {
    final detections = await repository.getDetections(
      startDate: monthStart,
      endDate: monthEnd,
    );
    return detections;
  } catch (e) {
    AppLogger.e('获取本月检测记录失败', e);
    return [];
  }
});

final recentDetectionsProvider = FutureProvider<List<DetectionResultDto>>((ref) async {
  final repository = ref.watch(detectionRepositoryProvider);
  final now = DateTime.now();

  final weekAgo = now.subtract(const Duration(days: 7));
  final weekStart = '${weekAgo.year}-${weekAgo.month.toString().padLeft(2, '0')}-${weekAgo.day.toString().padLeft(2, '0')}';
  final weekEnd = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  try {
    final detections = await repository.getDetections(
      startDate: weekStart,
      endDate: weekEnd,
    );

    detections.sort((a, b) {
      return app_utils.DateUtils.compareDateTime(a.detectTime, b.detectTime);
    });

    return detections;
  } catch (e) {
    AppLogger.e('获取最近检测记录失败', e);
    return [];
  }
});
