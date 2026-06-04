import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/network_providers.dart';
import '../core/utils/common_utils.dart';

enum AppNotificationType {
  alert,
  detection,
  report,
}

class AppNotificationItem {
  final String id;
  final AppNotificationType type;
  final String title;
  final String message;
  final String time;
  final String sortTime;

  const AppNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    required this.sortTime,
  });
}

final notificationsProvider = FutureProvider<List<AppNotificationItem>>((ref) async {
  final detectionRepository = ref.read(detectionRepositoryProvider);
  final detections = await detectionRepository.getDetections(page: 1, size: 50);

  final items = <AppNotificationItem>[];

  for (final detection in detections) {
    final eventTime = detection.detectTime ?? detection.updatedAt ?? detection.createdAt ?? '';
    final buildingName = detection.buildingName ?? '未知建筑';
    final remark = detection.description?.trim();
    final status = (detection.status ?? 'CREATED').toUpperCase();
    final riskLevel = detection.resolvedRiskLevel.toUpperCase();
    final isHighRisk = riskLevel == 'C' || riskLevel == 'D' || riskLevel == 'HIGH' || riskLevel == 'CRITICAL';

    String title;
    String message;
    AppNotificationType type;

    switch (status) {
      case 'FAILED':
        title = '检测任务失败';
        message = '$buildingName 的检测任务执行失败，请重新上传图片或稍后重试。';
        type = AppNotificationType.alert;
        break;
      case 'PROCESSING':
        title = '检测任务进行中';
        message = '$buildingName 的检测任务正在排队或分析中，可稍后查看最终结果。';
        type = AppNotificationType.detection;
        break;
      case 'READY':
        title = '检测任务已就绪';
        message = '$buildingName 的检测图片已上传成功，任务正在进入识别流程。';
        type = AppNotificationType.detection;
        break;
      case 'COMPLETED':
        if (isHighRisk) {
          title = '发现高风险建筑';
          message = '$buildingName 的检测已完成，当前风险等级为 ${detection.resolvedRiskLevel}，请尽快查看报告并处置。';
          type = AppNotificationType.alert;
        } else {
          title = '检测任务已完成';
          message = '$buildingName 的检测已完成，可查看识别结果和正式报告。';
          type = AppNotificationType.detection;
        }
        break;
      case 'CREATED':
      default:
        title = '检测任务已创建';
        message = '$buildingName 已创建检测任务，请继续上传图片并发起识别。';
        type = AppNotificationType.detection;
        break;
    }

    if (remark != null && remark.isNotEmpty) {
      message = '$message 备注：$remark';
    }

    items.add(
      AppNotificationItem(
        id: 'detection_${detection.id}',
        type: type,
        title: title,
        message: message,
        time: DateUtils.formatFriendly(eventTime),
        sortTime: eventTime,
      ),
    );

    final report = detection.report;
    if (report != null && report.id != null) {
      final reportTime = report.generatedAt ?? detection.updatedAt ?? eventTime;
      items.add(
        AppNotificationItem(
          id: 'report_${report.id}',
          type: AppNotificationType.report,
          title: '正式报告已生成',
          message: '$buildingName 的正式检测报告已生成，报告编号 ${report.reportNo ?? '未编号'}，可直接下载或查看详情。',
          time: DateUtils.formatFriendly(reportTime),
          sortTime: reportTime,
        ),
      );
    }
  }

  items.sort((a, b) => DateUtils.compareDateTime(a.sortTime, b.sortTime));
  return items;
});

final notificationBadgeCountProvider = Provider<AsyncValue<int>>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.whenData((items) => items.length);
});
