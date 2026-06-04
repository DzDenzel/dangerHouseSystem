import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/network_providers.dart';
import '../../core/utils/risk_level_util.dart';
import '../../core/utils/risk_calculation_util.dart';
import '../../core/utils/common_utils.dart';
import '../../data/models/building_models.dart';
import '../../data/models/detection_models.dart';
import '../../providers/refresh_notifier.dart';
import '../capture/building_create_page.dart';
import '../capture/ai_detection_page.dart';
import 'building_details_page.dart';

class BuildingListPage extends ConsumerStatefulWidget {
  const BuildingListPage({super.key});

  @override
  ConsumerState<BuildingListPage> createState() => _BuildingListPageState();
}

class _BuildingListPageState extends ConsumerState<BuildingListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Building> _buildings = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _searchQuery = '';
  String _activeFilter = 'all';
  DateTime? _lastRefreshTime;
  final Map<int, String?> _calculatedRiskLevels = {};
  final Map<int, List<DetectionResultDto>> _buildingDetections = {};

  @override
  void initState() {
    super.initState();
    _loadBuildings();
    ref.listenManual<RefreshEvent?>(refreshNotifierProvider, (previous, next) {
      if (next != null && mounted) {
        _handleRefreshEvent(next);
      }
    });
  }

  void _handleRefreshEvent(RefreshEvent event) {
    if (event.type == RefreshEventType.buildingCreated ||
        event.type == RefreshEventType.buildingUpdated ||
        event.type == RefreshEventType.buildingDeleted ||
        event.type == RefreshEventType.detectionCreated ||
        event.type == RefreshEventType.all) {
      _loadBuildings();
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

  Future<void> _loadBuildings() async {
    if (_isRefreshing && !_canRefresh()) return;

    setState(() {
      _isLoading = true;
      _isRefreshing = true;
    });
    _lastRefreshTime = DateTime.now();

    try {
      final repository = ref.read(buildingRepositoryProvider);
      final result = await repository.getBuildings(query: _searchQuery, size: 100);

      if (mounted) {
        setState(() {
          _buildings = result;
          _isLoading = false;
          _isRefreshing = false;
        });

        _loadDetectionData();
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

  Future<void> _loadDetectionData() async {
    final detectionRepository = ref.read(detectionRepositoryProvider);
    final Map<int, String?> tempRiskLevels = {};
    final Map<int, List<DetectionResultDto>> tempDetections = {};

    for (final building in _buildings) {
      if (!mounted) return;
      
      try {
        final detections = await detectionRepository.getDetections(
          buildingId: building.id,
          size: 100,
        );
        
        tempDetections[building.id] = detections;
        tempRiskLevels[building.id] = RiskCalculationUtil.calculateComprehensiveRiskLevel(
          detections,
          initialRiskLevel: building.initialRiskLevel,
        );
      } catch (e) {
        tempRiskLevels[building.id] = building.initialRiskLevel;
      }
    }

    if (mounted) {
      setState(() {
        _buildingDetections.addAll(tempDetections);
        _calculatedRiskLevels.addAll(tempRiskLevels);
      });
    }
  }

  String? _getRiskLevel(Building building) {
    return _calculatedRiskLevels[building.id] ?? building.initialRiskLevel;
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
          onPressed: _loadBuildings,
        ),
      ),
    );
  }

  Map<String, int> get _riskCounts {
    final counts = {'all': _buildings.length, 'A': 0, 'B': 0, 'C': 0, 'D': 0};
    for (var b in _buildings) {
      final level = _mapRiskLevel(_getRiskLevel(b));
      if (level != null) counts[level] = (counts[level] ?? 0) + 1;
    }
    return counts;
  }

  String? _mapRiskLevel(String? level) {
    if (level == 'A' || level == 'LOW') return 'A';
    if (level == 'B' || level == 'MEDIUM') return 'B';
    if (level == 'C' || level == 'HIGH') return 'C';
    if (level == 'D' || level == 'CRITICAL') return 'D';
    return null;
  }

  List<Building> get _filteredBuildings {
    return _buildings.where((b) {
      final matchSearch = b.name.contains(_searchQuery) || b.address.contains(_searchQuery);
      if (_activeFilter == 'all') return matchSearch;
      
      final level = _mapRiskLevel(_getRiskLevel(b));
      final matchRisk = level == _activeFilter;

      return matchSearch && matchRisk;
    }).toList();
  }

  void _navigateToCreatePage() async {
    final newBuilding = await Navigator.push<Building>(
      context,
      MaterialPageRoute(builder: (context) => const BuildingCreatePage()),
    );

    if (newBuilding != null && mounted) {
      ref.read(refreshNotifierProvider.notifier).notifyBuildingCreated(buildingId: newBuilding.id);
      _loadBuildings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadBuildings,
                      displacement: 40.0,
                      color: const Color(0xFF2F80ED),
                      backgroundColor: Colors.white,
                      strokeWidth: 2.5,
                      child: _filteredBuildings.isEmpty
                          ? _buildEmptyState()
                          : _buildList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final filters = [
      {'key': 'all', 'label': '全部'},
      {'key': 'A', 'label': 'A级'},
      {'key': 'B', 'label': 'B级'},
      {'key': 'C', 'label': 'C级'},
      {'key': 'D', 'label': 'D级'},
    ];

    Color getFilterColor(String key) {
      if (key == 'all') return const Color(0xFF2F80ED);
      return RiskLevelUtil.getColor(key);
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '建筑档案',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '共 ${_buildings.length} 栋建筑已录入',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2F80ED),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2F80ED).withAlpha(89),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 24),
                  onPressed: _navigateToCreatePage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: '搜索建筑名称或地址',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2F80ED), width: 2),
              ),
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((f) {
                final isActive = _activeFilter == f['key'];
                final activeColor = getFilterColor(f['key'] as String);
                final count = _riskCounts[f['key']] ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _activeFilter = f['key'] as String),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? activeColor : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            f['label'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.white : const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.white.withAlpha(77) : const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 10,
                                color: isActive ? Colors.white : const Color(0xFF9CA3AF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
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
              Icon(Icons.domain_disabled, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text('暂无匹配的建筑档案', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredBuildings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final building = _filteredBuildings[index];
        final riskLevel = _getRiskLevel(building);
        return _BuildingCard(
          building: building,
          riskLevel: riskLevel,
          onTap: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => BuildingDetailsPage(building: building),
              ),
            );
            if (result == true && mounted) {
              ref.read(refreshNotifierProvider.notifier).notifyBuildingUpdated();
              _loadBuildings();
            }
          },
          onDetect: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AIDetectionPage(preSelectedBuilding: building)),
            );
          },
        );
      },
    );
  }
}

class _BuildingCard extends StatelessWidget {
  final Building building;
  final String? riskLevel;
  final VoidCallback onTap;
  final VoidCallback onDetect;

  const _BuildingCard({
    required this.building,
    required this.riskLevel,
    required this.onTap,
    required this.onDetect,
  });

  @override
  Widget build(BuildContext context) {
    final mappedLevel = _mapRiskLevel(riskLevel);
    final riskColors = {
      'A': const Color(0xFF27AE60),
      'B': const Color(0xFFF2A900),
      'C': const Color(0xFFFF8C00),
      'D': const Color(0xFFFF4D4F),
    };
    final riskLabels = {
      'A': 'A级 无危险点',
      'B': 'B级 有危险点',
      'C': 'C级 局部危房',
      'D': 'D级 整幢危房',
    };
    final riskColor = riskColors[mappedLevel] ?? const Color(0xFF9CA3AF);
    final riskLabel = riskLabels[mappedLevel] ?? '未知';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF9FAFB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: 128,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: building.imagePath != null && building.imagePath!.isNotEmpty
                        ? Image.network(
                            ImageUtils.getFullImageUrl(building.imagePath) ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(Icons.domain, size: 48, color: Colors.grey.shade400),
                            ),
                          )
                        : Center(
                            child: Icon(Icons.domain, size: 48, color: Colors.grey.shade400),
                          ),
                  ),
                ),
                Container(
                  height: 128,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withAlpha(153), Colors.transparent],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: riskColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      riskLabel,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 16,
                  child: Text(
                    building.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black26)],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _InfoItem(icon: Icons.location_on, text: building.address, truncate: true)),
                      Expanded(child: _InfoItem(icon: Icons.business, text: '${building.structureTypeLabel} · ${building.floorCount ?? "-"}F')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _InfoItem(icon: Icons.badge_outlined, text: '创建角色 ${building.createdByRoleName ?? building.createdByRole?.toString() ?? "-"}')),
                      Expanded(child: _InfoItem(icon: Icons.link, text: '绑定用户 ${building.ownerUserId?.toString() ?? "-"}')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onTap,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4B5563),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            minimumSize: const Size(0, 36),
                          ),
                          child: const Text('查看档案', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onDetect,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2F80ED),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            minimumSize: const Size(0, 36),
                            elevation: 0,
                          ),
                          child: const Text('发起检测', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _mapRiskLevel(String? level) {
    if (level == null) return null;
    if (level == 'A' || level == 'LOW') return 'A';
    if (level == 'B' || level == 'MEDIUM') return 'B';
    if (level == 'C' || level == 'HIGH') return 'C';
    if (level == 'D' || level == 'CRITICAL') return 'D';
    return null;
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool truncate;

  const _InfoItem({required this.icon, required this.text, this.truncate = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            maxLines: truncate ? 1 : 999,
            overflow: truncate ? TextOverflow.ellipsis : TextOverflow.clip,
          ),
        ),
      ],
    );
  }
}
