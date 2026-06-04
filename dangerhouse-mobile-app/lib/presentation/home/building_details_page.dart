import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/network_providers.dart';
import '../../core/utils/common_utils.dart' as app_utils;
import '../../core/utils/risk_level_util.dart';
import '../../core/utils/risk_calculation_util.dart';
import '../../core/utils/permission_util.dart';
import '../../data/models/building_models.dart';
import '../../data/models/detection_models.dart';
import '../../domain/entities/task.dart';
import '../../providers/auth_provider.dart';
import '../capture/building_edit_page.dart';
import '../capture/ai_detection_page.dart';
import '../task/report_detail_page.dart';

class BuildingDetailsPage extends ConsumerStatefulWidget {
  final Building building;

  const BuildingDetailsPage({super.key, required this.building});

  @override
  ConsumerState<BuildingDetailsPage> createState() => _BuildingDetailsPageState();
}

class _BuildingDetailsPageState extends ConsumerState<BuildingDetailsPage> {
  late Building _building;
  bool _isLoading = false;
  List<DetectionResultDto> _detections = [];
  bool _isLoadingDetections = false;
  String _activeTab = 'info';

  String? _calculateComprehensiveRiskLevel() {
    return RiskCalculationUtil.calculateComprehensiveRiskLevel(
      _detections,
      initialRiskLevel: _building.initialRiskLevel,
    );
  }

  @override
  void initState() {
    super.initState();
    _building = widget.building;
    _refreshBuildingDetail();
    _loadDetections();
  }

  Future<void> _loadDetections() async {
    setState(() => _isLoadingDetections = true);
    try {
      final repository = ref.read(detectionRepositoryProvider);
      final detections = await repository.getDetections(
        buildingId: _building.id,
        size: 10,
      );
      if (mounted) {
        setState(() {
          _detections = detections;
          _isLoadingDetections = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDetections = false);
      }
    }
  }

  Future<void> _refreshBuildingDetail() async {
    setState(() => _isLoading = true);
    final repository = ref.read(buildingRepositoryProvider);
    
    try {
      final updatedBuilding = await repository.getBuildingById(_building.id);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (updatedBuilding != null) {
            _building = updatedBuilding;
          }
        });
        _loadDetections();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (e.toString().contains('404') || e.toString().contains('建筑不存在')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('建筑已被删除')),
          );
          Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _handleEdit() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BuildingEditPage(building: _building)),
    );

    if (result == true && mounted) {
      _refreshBuildingDetail();
    }
  }

  Future<void> _handleDelete() async {
    final currentUser = ref.read(currentUserProvider);
    if (!PermissionUtil.canDeleteBuilding(currentUser)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('权限不足：仅检测员可删除建筑档案'),
          backgroundColor: Color(0xFFFF4D4F),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除建筑"${_building.name}"吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(buildingRepositoryProvider);
      final success = await repository.deleteBuilding(_building.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('建筑档案已删除')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除失败，请重试')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  Future<void> _handleQuickDetection() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AIDetectionPage(preSelectedBuilding: _building),
      ),
    );

    if (result == true && mounted) {
      _refreshBuildingDetail();
      _loadDetections();
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskLevel = _calculateComprehensiveRiskLevel();
    final riskColor = RiskLevelUtil.getColor(riskLevel);
    final riskLabel = RiskLevelUtil.getSubLabel(riskLevel);
    final isSafeLevel = riskLevel == 'A' || riskLevel == 'B' || riskLevel == 'LOW' || riskLevel == 'MEDIUM';
    final canDelete = ref.watch(canDeleteBuildingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: _refreshBuildingDetail,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 208,
              pinned: true,
              backgroundColor: Colors.white,
              leading: const SizedBox(),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    _building.imagePath != null && _building.imagePath!.isNotEmpty
                        ? Image.network(
                            _building.fullImagePath ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: Icon(Icons.domain, size: 64, color: Colors.white54),
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Icon(Icons.domain, size: 64, color: Colors.white54),
                            ),
                          ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withAlpha(77),
                            Colors.black.withAlpha(77),
                            Colors.transparent,
                            Colors.black.withAlpha(179),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(77),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: riskColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSafeLevel ? Icons.verified : Icons.warning_amber_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      RiskLevelUtil.getFullLabel(riskLevel),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _handleEdit,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(77),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 18),
                                ),
                              ),
                              if (canDelete) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _handleDelete,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF4D4F).withAlpha(204),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.delete, color: Colors.white, size: 18),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _building.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black26)],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _building.address,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
            ),
            SliverToBoxAdapter(
              child: _buildStatsCard(),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  children: [
                    _buildTabBar(),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    if (_activeTab == 'info') ...[
                      _buildInfoCard(),
                      const SizedBox(height: 12),
                      _buildContactCard(),
                      const SizedBox(height: 12),
                      _buildOwnershipCard(),
                      const SizedBox(height: 12),
                      _buildRiskCard(riskLevel, riskColor, riskLabel),
                    ] else ...[
                      _buildDetectionList(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: ElevatedButton.icon(
            onPressed: _handleQuickDetection,
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            label: const Text(
              '快速检测',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F80ED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '基本信息',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.apartment, label: '结构类型', value: _building.structureTypeLabel),
          const Divider(height: 24, color: Color(0xFFF3F4F6)),
          _InfoRow(icon: Icons.calendar_today, label: '建造年份', value: _building.buildYear != null ? '${_building.buildYear} 年' : '-'),
          const Divider(height: 24, color: Color(0xFFF3F4F6)),
          _InfoRow(icon: Icons.layers, label: '建筑层数', value: '地上 ${_building.floorCount ?? "-"} 层'),
          const Divider(height: 24, color: Color(0xFFF3F4F6)),
          _InfoRow(icon: Icons.straighten, label: '建筑面积', value: _building.area != null ? '${_building.area} m²' : '-'),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '产权联系方',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.person, label: '负责人', value: _building.ownerName ?? '-', iconColor: const Color(0xFF27AE60)),
          const Divider(height: 24, color: Color(0xFFF3F4F6)),
          _InfoRow(icon: Icons.phone, label: '联系电话', value: _building.ownerPhone ?? '-', iconColor: const Color(0xFF27AE60)),
        ],
      ),
    );
  }

  Widget _buildOwnershipCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '档案归属',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.link,
            label: '绑定用户 ID',
            value: _building.ownerUserId?.toString() ?? '-',
            iconColor: const Color(0xFF2F80ED),
          ),
          const Divider(height: 24, color: Color(0xFFF3F4F6)),
          _InfoRow(
            icon: Icons.person_outline,
            label: '创建人 ID',
            value: _building.createdBy?.toString() ?? '-',
            iconColor: const Color(0xFF2F80ED),
          ),
          const Divider(height: 24, color: Color(0xFFF3F4F6)),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: '创建角色',
            value: _building.createdByRoleName ?? _building.createdByRole?.toString() ?? '-',
            iconColor: const Color(0xFF2F80ED),
          ),
          const Divider(height: 24, color: Color(0xFFF3F4F6)),
          _InfoRow(
            icon: Icons.manage_accounts_outlined,
            label: '跟进检测员 ID',
            value: _building.assignedInspectorId?.toString() ?? '-',
            iconColor: const Color(0xFF2F80ED),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskCard(String? riskLevel, Color riskColor, String riskLabel) {
    final isSafeLevel = riskLevel == 'A' || riskLevel == 'B' || riskLevel == 'LOW' || riskLevel == 'MEDIUM';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: riskColor.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '当前危险等级',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      riskLevel?.toUpperCase() ?? '-',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: riskColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      riskLabel.isNotEmpty ? riskLabel : '待评估',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: riskColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  RiskLevelUtil.getDescription(riskLevel),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: riskColor.withAlpha(40),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isSafeLevel ? Icons.verified : Icons.warning_amber_rounded,
              color: riskColor,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _StatItem(value: '${_detections.length}', label: '累计检测')),
          Container(width: 1, height: 32, color: const Color(0xFFF3F4F6)),
          Expanded(child: _StatItem(value: '${_building.buildYear ?? "-"}', label: '建造年份')),
          Container(width: 1, height: 32, color: const Color(0xFFF3F4F6)),
          Expanded(child: _StatItem(value: '${_building.floorCount ?? "-"}F', label: '建筑层数')),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 'info'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _activeTab == 'info' ? const Color(0xFF2F80ED) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '建筑信息',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _activeTab == 'info' ? Colors.white : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 'history'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _activeTab == 'history' ? const Color(0xFF2F80ED) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '检测历史 (${_detections.length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _activeTab == 'history' ? Colors.white : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionList() {
    if (_isLoadingDetections) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_detections.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.description_outlined, size: 56, color: Color(0xFFE5E7EB)),
              SizedBox(height: 12),
              Text(
                '暂无检测记录',
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _detections.asMap().entries.map((entry) {
        final index = entry.key;
        final detection = entry.value;
        return Padding(
          padding: EdgeInsets.only(bottom: index < _detections.length - 1 ? 12 : 0),
          child: _DetectionCard(
            detection: detection,
            onTap: () {
              final task = Task(
                id: detection.id,
                title: detection.buildingName ?? '检测任务',
                address: _building.address,
                time: detection.detectTime ?? '',
                riskLevel: detection.riskLevel ?? 'LOW',
                riskDescription: RiskLevelUtil.getFullLabel(detection.riskLevel),
                status: detection.status ?? 'UNKNOWN',
              );
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ReportDetailPage(task: task)),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = const Color(0xFF2F80ED),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
      ],
    );
  }
}

class _DetectionCard extends StatelessWidget {
  final DetectionResultDto detection;
  final VoidCallback onTap;

  const _DetectionCard({required this.detection, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final riskColor = RiskLevelUtil.getColor(detection.riskLevel);
    final riskLabel = RiskLevelUtil.getFullLabel(detection.riskLevel);
    final time = app_utils.DateUtils.formatDateTime(detection.detectTime);
    final type = detection.status == 'COMPLETED' ? '完成检测' : (detection.status == 'PROCESSING' ? '检测中' : '新建任务');
    final displayTitle = detection.description?.isNotEmpty == true ? detection.description! : type;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.assignment_outlined, size: 20, color: Color(0xFF4B5563)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle,
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
                    '$type · $time',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: riskColor.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                riskLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: riskColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}
