import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/network_providers.dart';
import '../../core/utils/common_utils.dart' as app_utils;
import '../../core/utils/risk_calculation_util.dart';
import '../../core/utils/risk_level_util.dart';
import '../../data/models/building_models.dart';
import '../../data/models/detection_models.dart';
import 'building_details_page.dart';

class ArchivedDangerousBuildingsPage extends ConsumerStatefulWidget {
  const ArchivedDangerousBuildingsPage({super.key});

  @override
  ConsumerState<ArchivedDangerousBuildingsPage> createState() => _ArchivedDangerousBuildingsPageState();
}

class _ArchivedDangerousBuildingsPageState extends ConsumerState<ArchivedDangerousBuildingsPage> {
  String _activeFilter = '全部';
  List<Building> _allBuildings = [];
  bool _isLoading = true;
  final Map<int, String?> _calculatedRiskLevels = {};
  final Map<int, List<DetectionResultDto>> _buildingDetections = {};

  static const List<String> _dangerousLevels = ['B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final buildingRepository = ref.read(buildingRepositoryProvider);
    final result = await buildingRepository.getBuildings(riskLevels: _dangerousLevels);

    if (!mounted) {
      return;
    }

    setState(() {
      _allBuildings = result;
      _isLoading = false;
    });

    await _loadDetectionData();
  }

  Future<void> _loadDetectionData() async {
    final detectionRepository = ref.read(detectionRepositoryProvider);
    final tempRiskLevels = <int, String?>{};
    final tempDetections = <int, List<DetectionResultDto>>{};

    for (final building in _allBuildings) {
      if (!mounted) {
        return;
      }

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
      } catch (_) {
        tempDetections[building.id] = const [];
        tempRiskLevels[building.id] = building.initialRiskLevel;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _buildingDetections
        ..clear()
        ..addAll(tempDetections);
      _calculatedRiskLevels
        ..clear()
        ..addAll(tempRiskLevels);
    });
  }

  String? _getRiskLevel(Building building) {
    return _calculatedRiskLevels[building.id] ?? building.initialRiskLevel;
  }

  Map<String, int> get _counts {
    var b = 0;
    var c = 0;
    var d = 0;
    for (final item in _allBuildings) {
      final level = (_getRiskLevel(item) ?? '').toUpperCase();
      if (level == 'MEDIUM' || level == 'B') {
        b++;
      } else if (level == 'HIGH' || level == 'C') {
        c++;
      } else if (level == 'CRITICAL' || level == 'D') {
        d++;
      }
    }
    return {
      '全部': _allBuildings.length,
      'D级': d,
      'C级': c,
      'B级': b,
    };
  }

  List<Building> get _filteredList {
    if (_activeFilter == '全部') {
      return _allBuildings;
    }

    return _allBuildings.where((item) {
      final level = (_getRiskLevel(item) ?? '').toUpperCase();
      if (_activeFilter == 'B级') {
        return level == 'MEDIUM' || level == 'B';
      }
      if (_activeFilter == 'C级') {
        return level == 'HIGH' || level == 'C';
      }
      if (_activeFilter == 'D级') {
        return level == 'CRITICAL' || level == 'D';
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final counts = _counts;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(counts),
          _buildWarningBanner(counts),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                    ? _buildEmptyState()
                    : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, int> counts) {
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
                      '已归档危险建筑',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('全部', counts['全部']!, const Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    _buildFilterChip('D级', counts['D级']!, const Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    _buildFilterChip('C级', counts['C级']!, const Color(0xFFFF8C00)),
                    const SizedBox(width: 8),
                    _buildFilterChip('B级', counts['B级']!, const Color(0xFFF59E0B)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, Color color) {
    final isActive = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : color,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isActive ? Colors.white.withValues(alpha: 0.25) : color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner(Map<String, int> counts) {
    final highRiskTotal = (counts['C级'] ?? 0) + (counts['D级'] ?? 0);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4D4F).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF4D4F).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFF4D4F),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: const Icon(Icons.shield, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '共有 $highRiskTotal 栋建筑需要重点关注',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF4D4F),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '其中 ${counts['D级'] ?? 0} 栋 D 级建筑需优先处置',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            '暂无相关归档',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _filteredList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildCard(_filteredList[index]),
    );
  }

  Widget _buildCard(Building building) {
    final riskLevel = _getRiskLevel(building);
    final color = RiskLevelUtil.getColor(riskLevel);
    final riskLabel = RiskLevelUtil.getFullLabel(riskLevel);
    final detections = _buildingDetections[building.id] ?? const <DetectionResultDto>[];
    final latestDetection = detections.isNotEmpty ? detections.first : null;
    final latestTime = latestDetection?.detectTime ?? latestDetection?.createdAt;
    final totalCracks = detections.fold<int>(0, (sum, item) => sum + item.resolvedCrackCount);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BuildingDetailsPage(building: building),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
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
                              building.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 12, color: Color(0xFF9CA3AF)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    building.address,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 12, color: color),
                            const SizedBox(width: 4),
                            Text(
                              riskLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildMetric('${detections.length}', '累计检测次数')),
                      Expanded(child: _buildMetric('$totalCracks', '累计裂缝识别')),
                      Expanded(child: _buildMetric(building.structureTypeLabel, '结构类型')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 12, color: Color(0xFF9CA3AF)),
                          const SizedBox(width: 4),
                          Text(
                            latestTime != null
                                ? '末次检测 ${app_utils.DateUtils.formatDateTime(latestTime)}'
                                : '暂无检测时间',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                          ),
                        ],
                      ),
                      const Row(
                        children: [
                          Text(
                            '定期监测中',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2F80ED)),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 14, color: Color(0xFF2F80ED)),
                        ],
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

  Widget _buildMetric(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}
