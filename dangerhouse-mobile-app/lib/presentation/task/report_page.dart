import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/network_providers.dart';

import '../../core/utils/common_utils.dart' as app_utils;

import '../../core/utils/detection_status_util.dart';

import '../../core/utils/risk_level_util.dart';

import '../../domain/entities/task.dart';

import '../../providers/refresh_notifier.dart';

import 'report_detail_page.dart';



class ReportPage extends ConsumerStatefulWidget {

  const ReportPage({super.key});



  @override

  ConsumerState<ReportPage> createState() => _ReportPageState();

}



class _ReportPageState extends ConsumerState<ReportPage> {

  final TextEditingController _searchController = TextEditingController();

  List<Task> _tasks = [];

  bool _isLoading = true;

  bool _isRefreshing = false;

  String _activeRiskFilter = '全部';

  String _activeStatusFilter = '全部';

  bool _showGradeStandard = false;

  String _sortBy = 'time';

  bool _sortAscending = false;

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

      final repository = ref.read(taskRepositoryProvider);

      final result = await repository.getTasks();



      if (mounted) {

        setState(() {

          _tasks = result;

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



  List<Task> get _filteredTasks {

    var list = _tasks.where((t) {

      final matchSearch = t.title.contains(_searchController.text) ||

                         t.address.contains(_searchController.text) ||

                         (t.description?.contains(_searchController.text) ?? false);

      

      bool matchRisk = true;

      if (_activeRiskFilter != '全部') {

        final normalizedLevel = RiskLevelUtil.getLabel(t.riskLevel).replaceAll('级', '');

        matchRisk = normalizedLevel == _activeRiskFilter.replaceAll('级', '');

      }



      final matchStatus = DetectionStatusUtil.matchesFilter(t.status, _activeStatusFilter);



      return matchSearch && matchRisk && matchStatus;

    }).toList();



    list.sort((a, b) {

      if (_sortBy == 'level') {

        final levelOrder = {'D': 0, 'C': 1, 'B': 2, 'A': 3, 'UNKNOWN': 4};

        final aLevel = levelOrder[RiskLevelUtil.getLabel(a.riskLevel).replaceAll('级', '')] ?? 4;

        final bLevel = levelOrder[RiskLevelUtil.getLabel(b.riskLevel).replaceAll('级', '')] ?? 4;

        return _sortAscending ? aLevel.compareTo(bLevel) : bLevel.compareTo(aLevel);

      } else {

        return _sortAscending ? a.time.compareTo(b.time) : b.time.compareTo(a.time);

      }

    });



    return list;

  }



  Map<String, int> get _riskCounts {

    int a = 0, b = 0, c = 0, d = 0;

    for (var t in _tasks) {

      final label = RiskLevelUtil.getLabel(t.riskLevel);

      if (label == 'A级') {

        a++;

      } else if (label == 'B级') {

        b++;

      } else if (label == 'C级') {

        c++;

      } else if (label == 'D级') {

        d++;

      }

    }

    return {'A': a, 'B': b, 'C': c, 'D': d};

  }



  int get _pendingReviewCount {
    return _tasks.where((t) => DetectionStatusUtil.matchesFilter(t.status, DetectionStatusUtil.statusPending)).length;

  }



  @override

  Widget build(BuildContext context) {

    final counts = _riskCounts;

    final total = counts['A']! + counts['B']! + counts['C']! + counts['D']!;

    final pendingCount = _pendingReviewCount;



    return Scaffold(

      backgroundColor: const Color(0xFFF5F7FA),

      body: Column(

        children: [

          Container(

            color: Colors.white,

            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 16),

            child: Row(

              children: [

                Expanded(

                  child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    const Text(

                      '检测记录',

                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),

                    ),

                    const SizedBox(height: 2),

                    Text(

                      '共$total 条检测记录',

                      style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),

                    ),

                  ],

                ),

                ),

                const SizedBox(width: 12),

                if (pendingCount > 0)

                  Container(

                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

                    decoration: BoxDecoration(

                      color: const Color(0xFFFF8C00).withValues(alpha: 0.15),

                      borderRadius: BorderRadius.circular(20),

                      border: Border.all(color: const Color(0xFFFF8C00), width: 1.5),

                    ),

                    child: Row(

                      mainAxisSize: MainAxisSize.min,

                      children: [

                        const Icon(Icons.pending_actions, size: 14, color: Color(0xFFFF8C00)),

                        const SizedBox(width: 4),

                        Text(

                          '$pendingCount${DetectionStatusUtil.statusPending}',

                          style: const TextStyle(

                            fontSize: 11,

                            fontWeight: FontWeight.bold,

                            color: Color(0xFFFF8C00),

                          ),

                        ),

                      ],

                    ),

                  ),

                const SizedBox(width: 8),

                Row(

                  children: [

                    IconButton(

                      icon: Icon(

                        _showGradeStandard ? Icons.info : Icons.info_outline,

                        color: _showGradeStandard ? const Color(0xFF2F80ED) : const Color(0xFF6B7280),

                      ),

                      onPressed: () => setState(() => _showGradeStandard = !_showGradeStandard),

                      tooltip: '分级标准说明',

                    ),

                    PopupMenuButton<String>(

                      icon: const Icon(Icons.sort, color: Color(0xFF6B7280)),

                      onSelected: (value) {

                        if (value.startsWith('sort_')) {

                          setState(() {

                            _sortBy = value.replaceAll('sort_', '');

                            _sortAscending = !_sortAscending;

                          });

                        }

                      },

                      itemBuilder: (context) => [

                        PopupMenuItem(

                          value: 'sort_time',

                          child: Row(

                            children: [

                              Icon(Icons.access_time, size: 18, color: _sortBy == 'time' ? const Color(0xFF2F80ED) : const Color(0xFF9CA3AF)),

                              const SizedBox(width: 8),

                              Text('按时间排序', style: TextStyle(color: _sortBy == 'time' ? const Color(0xFF2F80ED) : const Color(0xFF374151))),

                              if (_sortBy == 'time') Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16, color: const Color(0xFF2F80ED)),

                            ],

                          ),

                        ),

                        PopupMenuItem(

                          value: 'sort_level',

                          child: Row(

                            children: [

                              Icon(Icons.priority_high, size: 18, color: _sortBy == 'level' ? const Color(0xFF2F80ED) : const Color(0xFF9CA3AF)),

                              const SizedBox(width: 8),

                              Text('按等级排序', style: TextStyle(color: _sortBy == 'level' ? const Color(0xFF2F80ED) : const Color(0xFF374151))),

                              if (_sortBy == 'level') Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16, color: const Color(0xFF2F80ED)),

                            ],

                          ),

                        ),

                      ],

                    ),

                  ],

                ),

              ],

            ),

          ),

          if (_showGradeStandard) _buildGradeStandardCard(),

          

          _buildRiskFilterSection(counts),

          

          _buildSearchAndFilterSection(),

          

          Expanded(

            child: _isLoading

                ? const Center(child: CircularProgressIndicator())

                : RefreshIndicator(

                    onRefresh: _loadData,

                    displacement: 40.0,

                    color: const Color(0xFF2F80ED),

                    backgroundColor: Colors.white,

                    strokeWidth: 2.5,

                    child: _filteredTasks.isEmpty

                        ? _buildEmptyState()

                        : _buildTaskList(),

                  ),

          ),

        ],

      ),

    );

  }



  Widget _buildGradeStandardCard() {

    return Container(

      margin: const EdgeInsets.all(16),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              const Icon(Icons.assignment, size: 20, color: Color(0xFF2F80ED)),

              const SizedBox(width: 8),

              const Text('建筑检测分级标识', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),

              const Spacer(),

              IconButton(

                icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),

                onPressed: () => setState(() => _showGradeStandard = false),

                padding: EdgeInsets.zero,

                constraints: const BoxConstraints(),

              ),

            ],

          ),

          const SizedBox(height: 16),

          _buildGradeRow('A级', '结构状况良好', '非重点结构安全，非重点结构良好', const Color(0xFF10B981)),

          const SizedBox(height: 12),

          _buildGradeRow('B级', '存在轻度损伤', '个别构件轻微损伤，不影响主体结构', const Color(0xFFF59E0B)),

          const SizedBox(height: 12),

          _buildGradeRow('C级', '存在局部危险', '局部承载结构危险，需限制使用并专业评审', const Color(0xFFFF8C00)),

          const SizedBox(height: 12),

          _buildGradeRow('D级', '严重安全危险', '承重结构严重损坏，建议立即停止使用', const Color(0xFFEF4444)),

        ],

      ),

    );

  }



  Widget _buildGradeRow(String level, String title, String desc, Color color) {

    return Row(

      children: [

        Container(

          width: 40,

          height: 40,

          decoration: BoxDecoration(

            color: color.withValues(alpha: 0.1),

            borderRadius: BorderRadius.circular(8),

          ),

          alignment: Alignment.center,

          child: Text(

            level,

            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),

          ),

        ),

        const SizedBox(width: 12),

        Expanded(

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111827))),

              Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),

            ],

          ),

        ),

      ],

    );

  }



  Widget _buildRiskFilterSection(Map<String, int> counts) {

    return Container(

      margin: const EdgeInsets.all(16),

      child: Row(

        children: [

          _buildRiskFilterChip('A级', counts['A']!, const Color(0xFF10B981)),

          const SizedBox(width: 8),

          _buildRiskFilterChip('B级', counts['B']!, const Color(0xFFF59E0B)),

          const SizedBox(width: 8),

          _buildRiskFilterChip('C级', counts['C']!, const Color(0xFFFF8C00)),

          const SizedBox(width: 8),

          _buildRiskFilterChip('D级', counts['D']!, const Color(0xFFEF4444)),

          const SizedBox(width: 8),

          _buildRiskFilterChip('全部', counts['A']! + counts['B']! + counts['C']! + counts['D']!, const Color(0xFF6B7280)),

        ],

      ),

    );

  }



  Widget _buildRiskFilterChip(String label, int count, Color color) {

    final isActive = _activeRiskFilter == label;

    return Expanded(

      child: GestureDetector(

        onTap: () => setState(() => _activeRiskFilter = isActive ? '全部' : label),

        child: Container(

          padding: const EdgeInsets.symmetric(vertical: 10),

          decoration: BoxDecoration(

            color: isActive ? color : Colors.white,

            borderRadius: BorderRadius.circular(10),

            border: Border.all(color: isActive ? color : const Color(0xFFE5E7EB)),

            boxShadow: isActive ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))] : [],

          ),

          child: Column(

            children: [

              Text(

                label,

                style: TextStyle(fontSize: 11, color: isActive ? Colors.white : const Color(0xFF6B7280), fontWeight: FontWeight.bold),

              ),

              const SizedBox(height: 2),

              Text(

                '$count',

                style: TextStyle(fontSize: 14, color: isActive ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold),

              ),

            ],

          ),

        ),

      ),

    );

  }



  Widget _buildSearchAndFilterSection() {

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

      child: Column(

        children: [

          TextField(

            controller: _searchController,

            onChanged: (val) => setState(() {}),

            decoration: InputDecoration(

              hintText: '搜索检测编号或地址',

              prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),

              filled: true,

              fillColor: Colors.white,

              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),

              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),

            ),

          ),

          const SizedBox(height: 12),

          SingleChildScrollView(

            scrollDirection: Axis.horizontal,

            child: Row(

              children: [

                _buildStatusChip(DetectionStatusUtil.statusAll),

                _buildStatusChip(DetectionStatusUtil.statusArchived),

                _buildStatusChip(DetectionStatusUtil.statusProcessing),

                _buildStatusChip(DetectionStatusUtil.statusPending),

              ],

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildStatusChip(String label) {

    final isActive = _activeStatusFilter == label;

    return Padding(

      padding: const EdgeInsets.only(right: 8),

      child: InkWell(

        onTap: () => setState(() => _activeStatusFilter = label),

        borderRadius: BorderRadius.circular(20),

        child: Container(

          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),

          decoration: BoxDecoration(

            color: isActive ? const Color(0xFF374151) : Colors.white,

            borderRadius: BorderRadius.circular(20),

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

      ),

    );

  }



  Widget _buildEmptyState() {

    return SingleChildScrollView(

      physics: const AlwaysScrollableScrollPhysics(),

      child: SizedBox(

        height: MediaQuery.of(context).size.height * 0.4,

        child: Center(

          child: Column(

            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              Container(

                padding: const EdgeInsets.all(20),

                decoration: const BoxDecoration(

                  color: Color(0xFFF3F4F6),

                  shape: BoxShape.circle,

                ),

                child: const Icon(Icons.assignment_outlined, size: 48, color: Color(0xFF9CA3AF)),

              ),

              const SizedBox(height: 16),

              const Text(

                '暂无检测记录',

                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontWeight: FontWeight.w500),

              ),

              const SizedBox(height: 8),

              const Text(

                '点击下方"检测"按钮开始新的检测',

                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),

              ),

            ],

          ),

        ),

      ),

    );

  }



  Widget _buildTaskList() {

    return ListView.separated(

      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

      itemCount: _filteredTasks.length,

      separatorBuilder: (context, index) => const SizedBox(height: 12),

      itemBuilder: (context, index) {

        return _buildTaskCard(_filteredTasks[index]);

      },

    );

  }



  Widget _buildTaskCard(Task task) {

    final riskColor = RiskLevelUtil.getColor(task.riskLevel);

    final riskLabel = RiskLevelUtil.getLabel(task.riskLevel);

    

    final statusText = DetectionStatusUtil.getSpecificLabel(task.status);

    final statusColor = DetectionStatusUtil.getSpecificColor(task.status);

    final statusIcon = DetectionStatusUtil.getStatusIcon(task.status);



    return Container(

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],

      ),

      child: Column(

        children: [

          Container(

            padding: const EdgeInsets.all(16),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Row(

                  children: [

                    Container(

                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

                      decoration: BoxDecoration(

                        color: riskColor.withValues(alpha: 0.1),

                        borderRadius: BorderRadius.circular(6),

                      ),

                      child: Row(

                        mainAxisSize: MainAxisSize.min,

                        children: [

                          Icon(Icons.warning_amber, size: 12, color: riskColor),

                          const SizedBox(width: 4),

                          Text(

                            riskLabel,

                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: riskColor),

                          ),

                        ],

                      ),

                    ),

                    const SizedBox(width: 8),

                    Container(

                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

                      decoration: BoxDecoration(

                        color: statusColor.withValues(alpha: 0.1),

                        borderRadius: BorderRadius.circular(6),

                      ),

                      child: Row(

                        mainAxisSize: MainAxisSize.min,

                        children: [

                          Icon(statusIcon, size: 12, color: statusColor),

                          const SizedBox(width: 4),

                          Text(

                            statusText,

                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),

                          ),

                        ],

                      ),

                    ),

                    const Spacer(),

                    Text(

                      app_utils.DateUtils.formatDateTime(task.time),

                      style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),

                    ),

                  ],

                ),

                const SizedBox(height: 12),

                Text(

                  task.description?.isNotEmpty == true

                      ? '${task.title} · ${task.description}'

                      : task.title,

                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827)),

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                ),

                const SizedBox(height: 4),

                Row(

                  children: [

                    const Icon(Icons.location_on, size: 12, color: Color(0xFF9CA3AF)),

                    const SizedBox(width: 4),

                    Expanded(

                      child: Text(

                        task.address,

                        style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),

                        overflow: TextOverflow.ellipsis,

                      ),

                    ),

                  ],

                ),

              ],

            ),

          ),

          Container(

            decoration: const BoxDecoration(

              border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),

            ),

            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

            child: Row(

              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [

                Expanded(

                  child: Row(

                    children: [

                      const Icon(Icons.analytics, size: 14, color: Color(0xFF9CA3AF)),

                      const SizedBox(width: 4),

                      Expanded(

                        child: Text(

                          '风险: ${task.riskDescription}',

                          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),

                          overflow: TextOverflow.ellipsis,

                        ),

                      ),

                    ],

                  ),

                ),

                InkWell(

                  onTap: () {

                    Navigator.push(

                      context,

                      MaterialPageRoute(builder: (context) => ReportDetailPage(task: task)),

                    );

                  },

                  child: const Row(

                    children: [

                      Text('查看详情', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2F80ED))),

                      Icon(Icons.chevron_right, size: 16, color: Color(0xFF2F80ED)),

                    ],

                  ),

                ),

              ],

            ),

          ),

        ],

      ),

    );

  }

}
