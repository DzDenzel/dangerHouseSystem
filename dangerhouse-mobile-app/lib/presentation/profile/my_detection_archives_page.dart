import 'package:dangerhouse_app/core/utils/common_utils.dart' as app_utils;
import 'package:dangerhouse_app/core/utils/detection_status_util.dart';
import 'package:dangerhouse_app/core/utils/risk_level_util.dart';
import 'package:dangerhouse_app/data/models/detection_models.dart';
import 'package:dangerhouse_app/presentation/result/result_activity.dart';
import 'package:dangerhouse_app/providers/refresh_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/network_providers.dart';

class MyDetectionArchivesPage extends ConsumerStatefulWidget {
  const MyDetectionArchivesPage({super.key});

  @override
  ConsumerState<MyDetectionArchivesPage> createState() => _MyDetectionArchivesPageState();
}

class _MyDetectionArchivesPageState extends ConsumerState<MyDetectionArchivesPage> {
  final TextEditingController _searchController = TextEditingController();
  List<DetectionResultDto> _allTasks = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _activeStatusFilter = DetectionStatusUtil.statusAll;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    _loadData();
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
      _loadData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _canRefresh() {
    final now = DateTime.now();
    if (_lastRefreshTime == null) return true;
    return now.difference(_lastRefreshTime!) >= const Duration(seconds: 2);
  }

  Future<void> _loadData() async {
    if (_isRefreshing && !_canRefresh()) return;

    setState(() {
      _isLoading = true;
      _isRefreshing = true;
    });
    _lastRefreshTime = DateTime.now();

    try {
      final repository = ref.read(detectionRepositoryProvider);
      final result = await repository.getDetections(size: 100);

      if (mounted) {
        setState(() {
          _allTasks = result;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
        _showErrorSnackbar(e.toString());
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
          onPressed: _loadData,
        ),
      ),
    );
  }

  Map<String, int> get _stats {
    return DetectionStatusUtil.countByStatus(
      _allTasks.map((t) => t.status).toList(),
    );
  }

  List<DetectionResultDto> get _filteredList {
    return _allTasks.where((t) {
      final name = t.buildingName ?? '检测任务 #${t.id}';
      final matchSearch = name.contains(_searchController.text);
      final matchStatus = DetectionStatusUtil.matchesFilter(t.status, _activeStatusFilter);
      return matchSearch && matchStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(stats),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    displacement: 40.0,
                    color: const Color(0xFF2F80ED),
                    backgroundColor: Colors.white,
                    strokeWidth: 2.5,
                    child: _filteredList.isEmpty
                        ? _buildEmptyState()
                        : _buildArchiveList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, int> stats) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF374151)),
                  ),
                  const Expanded(
                    child: Text(
                      '我的检测数据档案',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildStatChip(
                        DetectionStatusUtil.statusAll,
                        stats[DetectionStatusUtil.statusAll] ?? 0,
                        const Color(0xFF2F80ED),
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        DetectionStatusUtil.statusArchived,
                        stats[DetectionStatusUtil.statusArchived] ?? 0,
                        const Color(0xFF27AE60),
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        DetectionStatusUtil.statusPending,
                        stats[DetectionStatusUtil.statusPending] ?? 0,
                        const Color(0xFFFF8C00),
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        DetectionStatusUtil.statusProcessing,
                        stats[DetectionStatusUtil.statusProcessing] ?? 0,
                        const Color(0xFF9B59B6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSearchBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    final isActive = _activeStatusFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeStatusFilter = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, color.r.toInt(), color.g.toInt(), color.b.toInt()).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: isActive ? Border.all(color: color, width: 2) : null,
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 13),
        decoration: const InputDecoration(
          hintText: '搜索建筑名称或检测点',
          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.description_outlined, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                '暂无匹配档案',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArchiveList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildArchiveCard(_filteredList[index]);
      },
    );
  }

  Widget _buildArchiveCard(DetectionResultDto item) {
    final riskColor = RiskLevelUtil.getColor(item.riskLevel);
    final riskLabel = RiskLevelUtil.getLabel(item.riskLevel);

    final statusLabel = DetectionStatusUtil.getSpecificLabel(item.status);
    final statusColor = DetectionStatusUtil.getSpecificColor(item.status);

    final buildingName = item.buildingName ?? '未知建筑';
    final description = (item.description != null && item.description!.isNotEmpty) 
        ? item.description! 
        : '第${item.id}次检测';
    final time = app_utils.DateUtils.formatDateTime(item.detectTime);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultActivity(result: item, detectionId: item.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: riskColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  buildingName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: riskColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              riskLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: riskColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 12, color: Color(0xFF9CA3AF)),
                              const SizedBox(width: 4),
                              Text(
                                time,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right, size: 14, color: Color(0xFFD1D5DB)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
