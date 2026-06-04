import 'package:flutter/material.dart';

class DetectionStatusUtil {
  static const String statusAll = '全部';
  static const String statusArchived = '已归档';
  static const String statusPending = '待处理';
  static const String statusProcessing = '分析中';
  static const String statusFailed = '失败';

  static const List<String> allStatusFilters = [
    statusAll,
    statusArchived,
    statusPending,
    statusProcessing,
  ];

  static const Color colorArchived = Color(0xFF27AE60);
  static const Color colorPending = Color(0xFFFF8C00);
  static const Color colorProcessing = Color(0xFF9B59B6);
  static const Color colorFailed = Color(0xFFFF4D4F);

  static String getDisplayStatus(String? status) {
    if (status == null || status.isEmpty) return '未知';

    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return statusArchived;
      case 'CREATED':
      case 'READY':
      case 'CANCELLED':
        return statusPending;
      case 'PROCESSING':
        return statusProcessing;
      case 'FAILED':
        return statusFailed;
      default:
        return '未知';
    }
  }

  static Color getStatusColor(String? status) {
    if (status == null || status.isEmpty) return Colors.grey;

    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return colorArchived;
      case 'CREATED':
      case 'READY':
      case 'CANCELLED':
        return colorPending;
      case 'PROCESSING':
        return colorProcessing;
      case 'FAILED':
        return colorFailed;
      default:
        return Colors.grey;
    }
  }

  static String getSpecificLabel(String? status) {
    if (status == null || status.isEmpty) return '未知';

    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return '已归档';
      case 'CREATED':
        return '已创建';
      case 'READY':
        return '就绪';
      case 'PROCESSING':
        return '分析中';
      case 'FAILED':
        return '失败';
      case 'CANCELLED':
        return '已取消';
      default:
        return '未知';
    }
  }

  static Color getSpecificColor(String? status) {
    if (status == null || status.isEmpty) return Colors.grey;

    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return const Color(0xFF27AE60);
      case 'CREATED':
        return const Color(0xFF9CA3AF);
      case 'READY':
        return const Color(0xFF2F80ED);
      case 'PROCESSING':
        return const Color(0xFF9B59B6);
      case 'FAILED':
        return const Color(0xFFEF4444);
      case 'CANCELLED':
        return const Color(0xFF6B7280);
      default:
        return Colors.grey;
    }
  }

  static bool matchesFilter(String? status, String filter) {
    if (filter == statusAll) return true;

    final upperStatus = status?.toUpperCase() ?? '';

    switch (filter) {
      case statusArchived:
        return upperStatus == 'COMPLETED';
      case statusPending:
        return upperStatus == 'CREATED' ||
            upperStatus == 'READY' ||
            upperStatus == 'CANCELLED';
      case statusProcessing:
        return upperStatus == 'PROCESSING';
      case statusFailed:
        return upperStatus == 'FAILED';
      default:
        return true;
    }
  }

  static Map<String, int> countByStatus(List<String?> statuses) {
    int completed = 0, pending = 0, processing = 0;

    for (var status in statuses) {
      final upperStatus = status?.toUpperCase() ?? '';
      if (upperStatus == 'COMPLETED') {
        completed++;
      } else if (upperStatus == 'PROCESSING') {
        processing++;
      } else if (upperStatus == 'CREATED' ||
          upperStatus == 'READY' ||
          upperStatus == 'CANCELLED') {
        pending++;
      }
    }

    return {
      statusAll: statuses.length,
      statusArchived: completed,
      statusPending: pending,
      statusProcessing: processing,
    };
  }

  static String getStatusDescription(String? status) {
    if (status == null || status.isEmpty) return '状态未知';

    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return '检测已完成，报告已生成';
      case 'CREATED':
        return '任务已创建，等待开始';
      case 'READY':
        return '任务就绪，准备检测';
      case 'PROCESSING':
        return '正在分析中，请稍候';
      case 'CANCELLED':
        return '任务已取消';
      case 'FAILED':
        return '检测失败，请重试';
      default:
        return '状态未知';
    }
  }

  static bool isTerminal(String? status) {
    if (status == null || status.isEmpty) return false;
    final upperStatus = status.toUpperCase();
    return upperStatus == 'COMPLETED' ||
        upperStatus == 'FAILED' ||
        upperStatus == 'CANCELLED';
  }

  static bool isActive(String? status) {
    if (status == null || status.isEmpty) return false;
    final upperStatus = status.toUpperCase();
    return upperStatus == 'PROCESSING' || upperStatus == 'READY';
  }

  static IconData getStatusIcon(String? status) {
    if (status == null || status.isEmpty) return Icons.help_outline;

    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Icons.check_circle;
      case 'PROCESSING':
        return Icons.autorenew;
      case 'CREATED':
        return Icons.add_circle_outline;
      case 'READY':
        return Icons.pending_outlined;
      case 'FAILED':
        return Icons.error_outline;
      case 'CANCELLED':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule;
    }
  }
}
