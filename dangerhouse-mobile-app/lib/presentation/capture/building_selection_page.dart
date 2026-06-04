import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/network_providers.dart';
import '../../core/utils/risk_calculation_util.dart';
import '../../core/utils/risk_level_util.dart';
import '../../data/models/building_models.dart';
import '../../data/models/detection_models.dart';
import 'building_create_page.dart';

class BuildingSelectionPage extends ConsumerStatefulWidget {
  final void Function(BuildContext, Building)? onBuildingSelected;

  const BuildingSelectionPage({super.key, this.onBuildingSelected});

  @override
  ConsumerState<BuildingSelectionPage> createState() => _BuildingSelectionPageState();
}

class _BuildingSelectionPageState extends ConsumerState<BuildingSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Building> _buildings = [];
  List<Building> _filteredBuildings = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  final Map<int, String?> _calculatedRiskLevels = {};
  final Map<int, List<DetectionResultDto>> _buildingDetections = {};

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBuildings() async {
    setState(() {
      _isLoading = true;
      _isRefreshing = true;
    });
    final repository = ref.read(buildingRepositoryProvider);
    final result = await repository.getBuildings();

    if (mounted) {
      setState(() {
        _buildings = result;
        _filteredBuildings = result;
        _isLoading = false;
        _isRefreshing = false;
      });
      await _loadDetectionData();
    }
  }

  Future<void> _loadDetectionData() async {
    final detectionRepository = ref.read(detectionRepositoryProvider);
    final tempRiskLevels = <int, String?>{};
    final tempDetections = <int, List<DetectionResultDto>>{};

    for (final building in _buildings) {
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

  void _filterBuildings(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBuildings = _buildings;
      } else {
        _filteredBuildings = _buildings.where((b) {
          final nameMatch = b.name.toLowerCase().contains(query.toLowerCase());
          final addressMatch = b.address.toLowerCase().contains(query.toLowerCase());
          return nameMatch || addressMatch;
        }).toList();
      }
    });
  }

  void _navigateToCreatePage() async {
    final newBuilding = await Navigator.push<Building>(
      context,
      MaterialPageRoute(builder: (context) => const BuildingCreatePage()),
    );

    if (newBuilding != null && mounted) {
      if (widget.onBuildingSelected != null) {
        widget.onBuildingSelected!(context, newBuilding);
      } else {
        Navigator.pop(context, newBuilding);
      }
    } else {
      _loadBuildings();
    }
  }

  void _onBuildingTap(Building building) {
    if (widget.onBuildingSelected != null) {
      widget.onBuildingSelected!(context, building);
    } else {
      Navigator.pop(context, building);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: const Text(
          '选择检测建筑',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadBuildings,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: '搜索建筑名称或地址...',
                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF9CA3AF), size: 18),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                onChanged: _filterBuildings,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _navigateToCreatePage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F80ED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2F80ED).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.add, color: Color(0xFF2F80ED), size: 20),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '添加新建筑并检测',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F80ED),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '或选择已有建筑',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B7280),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _filteredBuildings.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.domain_outlined, size: 40, color: Colors.grey[300]),
                              const SizedBox(height: 8),
                              const Text(
                                '未找到相关建筑',
                                style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: _filteredBuildings.map((building) {
                          final buildingRiskLevel = _getRiskLevel(building);
                          final hasRiskLevel = buildingRiskLevel?.isNotEmpty == true;
                          final riskColor = RiskLevelUtil.getColor(buildingRiskLevel);
                          final riskLabel = hasRiskLevel
                              ? RiskLevelUtil.getLabel(buildingRiskLevel)
                              : '未评定';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () => _onBuildingTap(building),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: const Color(0xFFF3F4F6),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: (building.fullImagePath?.isNotEmpty ?? false)
                                          ? Image.network(
                                              building.fullImagePath!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: const Color(0xFFF3F4F6),
                                                  alignment: Alignment.center,
                                                  child: const Icon(
                                                    Icons.domain,
                                                    color: Color(0xFF9CA3AF),
                                                    size: 24,
                                                  ),
                                                );
                                              },
                                              loadingBuilder: (context, child, progress) {
                                                if (progress == null) {
                                                  return child;
                                                }
                                                return Container(
                                                  color: const Color(0xFFF3F4F6),
                                                  alignment: Alignment.center,
                                                  child: const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  ),
                                                );
                                              },
                                            )
                                          : const Center(
                                              child: Icon(Icons.domain, color: Color(0xFF9CA3AF), size: 24),
                                            ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  building.name,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF111827),
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: riskColor.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: riskColor.withValues(alpha: 0.18),
                                                  ),
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
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on, size: 12, color: Color(0xFF9CA3AF)),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  building.address,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF6B7280),
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '危险等级: $riskLabel',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: riskColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if ((_buildingDetections[building.id]?.isNotEmpty ?? false))
                                            Text(
                                              '检测记录: ${_buildingDetections[building.id]!.length} 条',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF9CA3AF),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right, size: 16, color: Color(0xFFD1D5DB)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
          ],
        ),
      ),
    );
  }
}
