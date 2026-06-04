import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/notification_provider.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final Set<String> _readIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: notificationsAsync.when(
              data: (items) => items.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(notificationsProvider);
                        await ref.read(notificationsProvider.future);
                      },
                      child: _buildNotificationList(items),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildErrorState(error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => Navigator.pop(context),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                ),
                icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF374151)),
              ),
              const Expanded(
                child: Text(
                  '消息与通知',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            '暂无通知消息',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message.replaceAll('Exception: ', ''),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(notificationsProvider),
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<AppNotificationItem> notifications) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: notifications.length + 1,
      itemBuilder: (context, index) {
        if (index == notifications.length) {
          return _buildFooter();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildNotificationCard(notifications[index]),
        );
      },
    );
  }

  Widget _buildNotificationCard(AppNotificationItem notification) {
    final isRead = _readIds.contains(notification.id);
    final iconData = _getIconData(notification.type);
    final iconColor = _getIconColor(notification.type);
    final iconBg = _getIconBg(notification.type);

    return GestureDetector(
      onTap: () {
        setState(() => _readIds.add(notification.id));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isRead
              ? null
              : Border.all(color: const Color(0xFF2F80ED).withValues(alpha: 0.2)),
          boxShadow: const [
            BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF4D4F),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Color(0xFFD1D5DB)),
                        const SizedBox(width: 4),
                        Text(
                          notification.time,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          '没有更多消息了',
          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
        ),
      ),
    );
  }

  IconData _getIconData(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.alert:
        return Icons.warning_amber_rounded;
      case AppNotificationType.report:
        return Icons.description_outlined;
      case AppNotificationType.detection:
        return Icons.analytics_outlined;
    }
  }

  Color _getIconColor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.alert:
        return const Color(0xFFFF4D4F);
      case AppNotificationType.report:
        return const Color(0xFF2F80ED);
      case AppNotificationType.detection:
        return const Color(0xFF27AE60);
    }
  }

  Color _getIconBg(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.alert:
        return const Color(0xFFFF4D4F).withValues(alpha: 0.09);
      case AppNotificationType.report:
        return const Color(0xFF2F80ED).withValues(alpha: 0.09);
      case AppNotificationType.detection:
        return const Color(0xFF27AE60).withValues(alpha: 0.09);
    }
  }
}
