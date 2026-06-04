import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/risk_level_util.dart';
import '../../core/utils/common_utils.dart' as app_utils;
import '../../data/models/detection_models.dart';
import '../../providers/home_stats_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/refresh_notifier.dart';
import 'home_providers.dart';
import '../profile/notifications_page.dart';
import '../result/result_activity.dart';

class HomeContent extends ConsumerStatefulWidget {
  const HomeContent({super.key});

  @override
  ConsumerState<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<HomeContent> {
  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    ref.listenManual<RefreshEvent?>(refreshNotifierProvider, (previous, next) {
      if (next != null && mounted) {
        _handleRefreshEvent(next);
      }
    });
  }

  void _handleRefreshEvent(RefreshEvent event) {
    if (event.type == RefreshEventType.detectionCreated ||
        event.type == RefreshEventType.detectionUpdated ||
        event.type == RefreshEventType.detectionDeleted ||
        event.type == RefreshEventType.all) {
      _performRefresh();
    }
  }

  bool _canRefresh() {
    final now = DateTime.now();
    if (_lastRefreshTime == null) return true;
    return now.difference(_lastRefreshTime!) >= const Duration(seconds: 2);
  }

  Future<void> _performRefresh() async {
    if (_isRefreshing || !_canRefresh()) return;

    setState(() => _isRefreshing = true);
    _lastRefreshTime = DateTime.now();

    try {
      ref.invalidate(homeStatsProvider);
      await ref.read(homeStatsProvider.future);
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _showErrorSnackbar(String error) {
    String errorMessage = '网络连接失败，请检查网络后重试';

    if (error.contains('SocketException') || error.contains('Connection refused')) {
      errorMessage = '网络连接失败，请检查网络后重试';
    } else if (error.contains('TimeoutException') || error.contains('timeout')) {
      errorMessage = '请求超时，请稍后重试';
    } else if (error.contains('401') || error.contains('Unauthorized')) {
      errorMessage = '登录已过期，请重新登录';
    } else if (error.contains('500')) {
      errorMessage = '服务器错误，请稍后重试';
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(errorMessage)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '重试',
          textColor: Colors.white,
          onPressed: _performRefresh,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(homeStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _performRefresh,
                displacement: 40.0,
                color: const Color(0xFF2F80ED),
                backgroundColor: Colors.white,
                strokeWidth: 2.5,
                child: statsAsync.when(
                  data: (stats) => _HomeContentData(
                    stats: stats,
                    onOpenAllRecords: () {
                      ref.read(homeTabProvider.notifier).state = 3;
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => _HomeContentData(
                    stats: HomeStats.error(),
                    onOpenAllRecords: () {
                      ref.read(homeTabProvider.notifier).state = 3;
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final now = DateTime.now();
    final notificationCountAsync = ref.watch(notificationBadgeCountProvider);
    final notificationCount = notificationCountAsync.maybeWhen(
      data: (count) => count,
      orElse: () => 0,
    );
    final badgeText = notificationCount > 99 ? '99+' : '$notificationCount';
    final weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    final dateStr = '${now.year}年${now.month.toString().padLeft(2, '0')}月${now.day.toString().padLeft(2, '0')}日 ${weekdays[now.weekday - 1]}';
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, color: Color(0xFF2F80ED), size: 14),
                    SizedBox(width: 6),
                    Text(
                      '长沙市',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.notifications_none, size: 18, color: Color(0xFF6B7280)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationsPage()),
                        );
                      },
                    ),
                  ),
                  if (notificationCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4D4F),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFF5F7FA), width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          badgeText,
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '危房智能检测',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827), letterSpacing: -0.5),
          ),
          const SizedBox(height: 2),
          Text(
            dateStr,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}

class _HomeContentData extends StatelessWidget {
  final HomeStats stats;
  final VoidCallback onOpenAllRecords;

  const _HomeContentData({
    required this.stats,
    required this.onOpenAllRecords,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildStatsCard(),
          const SizedBox(height: 20),
          _buildRiskSummary(),
          const SizedBox(height: 24),
          _buildTaskListHeader(context),
          const SizedBox(height: 12),
          _buildTaskList(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F80ED), Color(0xFF1A66FF)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F80ED).withValues(alpha: 0.3),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -32,
            top: -32,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -16,
            top: 32,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics_outlined, color: Colors.white.withValues(alpha: 0.9), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '今日 AI 检测简报',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('${stats.todayCount}', '新增检测'),
                  _buildStatItem('${stats.criticalCount}', '高风险建筑', valueColor: const Color(0xFFFF8A65)),
                  _buildStatItem('${stats.aiConfidence}%', 'AI置信度', valueColor: const Color(0xFF6CDCA8), isPercent: true),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.68,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.trending_up, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  const Text('较昨日 +3', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, {Color? valueColor, bool isPercent = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value.replaceAll('%', ''),
                style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
              if (isPercent)
                TextSpan(
                  text: '%',
                  style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRiskSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '本月检测建筑风险分布',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280), letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRiskItem('A', stats.levelACount, '安全', const Color(0xFF27AE60)),
              _buildRiskItem('B', stats.levelBCount, '有险', const Color(0xFFF2A900)),
              _buildRiskItem('C', stats.levelCCount, '局危', const Color(0xFFFF8C00)),
              _buildRiskItem('D', stats.levelDCount, '整危', const Color(0xFFFF4D4F)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskItem(String level, int count, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$level级/$label',
          style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
        ),
      ],
    );
  }

  Widget _buildTaskListHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '最近检测记录',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
        ),
        InkWell(
          onTap: () {
            onOpenAllRecords();
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '全部记录',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF2F80ED)),
              ),
              Icon(Icons.chevron_right, size: 14, color: Color(0xFF2F80ED)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList() {
    if (stats.recentDetections.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        alignment: Alignment.center,
        child: const Text('暂无检测记录', style: TextStyle(color: Colors.grey)),
      );
    }

    return _TaskListWithFilter(detections: stats.recentDetections);
  }
}

class _TaskListWithFilter extends StatefulWidget {
  final List<DetectionResultDto> detections;
  
  const _TaskListWithFilter({required this.detections});

  @override
  State<_TaskListWithFilter> createState() => _TaskListWithFilterState();
}

class _TaskListWithFilterState extends State<_TaskListWithFilter> {
  String _activeFilter = '全部';

  @override
  Widget build(BuildContext context) {
    final filteredDetections = widget.detections.where((detection) {
      return RiskLevelUtil.matchesFilter(detection.riskLevel, _activeFilter);
    }).toList();

    final displayDetections = filteredDetections.take(3).toList();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('全部'),
              _buildFilterChip('A级'),
              _buildFilterChip('B级'),
              _buildFilterChip('C级'),
              _buildFilterChip('D级'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        displayDetections.isEmpty 
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text('暂无相关记录', style: TextStyle(color: Colors.grey)),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayDetections.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _TaskCard(detection: displayDetections[index]);
                },
              ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isActive = _activeFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2F80ED) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? null : Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final DetectionResultDto detection;

  const _TaskCard({required this.detection});

  @override
  Widget build(BuildContext context) {
    final statusColor = RiskLevelUtil.getColor(detection.riskLevel);
    final statusLabel = RiskLevelUtil.getLabel(detection.riskLevel);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultActivity(result: detection, detectionId: detection.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF9FAFB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: Container(color: statusColor),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detection.buildingName ?? '检测任务 #${detection.id}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (detection.description?.isNotEmpty == true) ...[
                                const SizedBox(height: 4),
                                Text(
                                  detection.description!,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                app_utils.DateUtils.formatDateTime(detection.detectTime ?? ''),
                                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (detection.confidence != null)
                          Expanded(
                            child: _buildInfoItem(
                              Icons.psychology_outlined,
                              '${detection.confidence!.toStringAsFixed(0)}%',
                              '置信度',
                            ),
                          ),
                        Expanded(
                          child: _buildInfoItem(
                            Icons.warning_amber_outlined,
                            '${detection.crackCount ?? 0}',
                            '裂缝数',
                          ),
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            Icons.assessment_outlined,
                            '${(detection.damageRatio ?? 0).toStringAsFixed(1)}%',
                            '损伤率',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
              TextSpan(
                text: ' $label',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
