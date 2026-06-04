import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_info.dart';
import '../../core/state/base_state.dart';
import '../../providers/offline_detection_provider.dart';
import '../../providers/settings_provider.dart';

class AnalysisSettingsPage extends ConsumerStatefulWidget {
  const AnalysisSettingsPage({super.key});

  @override
  ConsumerState<AnalysisSettingsPage> createState() => _AnalysisSettingsPageState();
}

class _AnalysisSettingsPageState extends ConsumerState<AnalysisSettingsPage> {
  bool? _fasterRcnnEnabled;
  bool? _riskAnalysisEnabled;
  bool? _dbscanEnabled;
  bool? _autoUpload;
  bool? _offlineCache;
  bool? _wifiOnly;
  double? _sensitivity;
  double? _confThreshold;

  bool _isSaved = false;
  bool _initialized = false;
  bool _isSyncingDrafts = false;

  void _initStateFromSettings(Map<String, dynamic> settings) {
    if (_initialized) {
      return;
    }
    _initialized = true;

    _fasterRcnnEnabled = settings['fasterRcnnEnabled'] ?? true;
    _riskAnalysisEnabled = settings['riskAnalysisEnabled'] ?? true;
    _dbscanEnabled = settings['dbscanEnabled'] ?? true;
    _autoUpload = settings['autoUpload'] ?? true;
    _offlineCache = settings['offlineCache'] ?? true;
    _wifiOnly = settings['wifiOnly'] ?? false;
    _sensitivity = settings['sensitivity'] ?? 85.0;
    _confThreshold = settings['confThreshold'] ?? 0.72;
  }

  void _handleSave() {
    setState(() => _isSaved = true);

    final newSettings = {
      'fasterRcnnEnabled': _fasterRcnnEnabled ?? true,
      'riskAnalysisEnabled': _riskAnalysisEnabled ?? true,
      'dbscanEnabled': _dbscanEnabled ?? true,
      'autoUpload': _autoUpload ?? true,
      'offlineCache': _offlineCache ?? true,
      'wifiOnly': _wifiOnly ?? false,
      'sensitivity': _sensitivity ?? 85.0,
      'confThreshold': _confThreshold ?? 0.72,
    };

    ref.read(settingsProvider.notifier).saveSettings(newSettings);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('配置已保存'),
        backgroundColor: Color(0xFF27AE60),
        duration: Duration(seconds: 1),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isSaved = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final offlineDraftCount = ref.watch(offlineDetectionDraftCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '分析模型及基础设置',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(settingsState, offlineDraftCount),
    );
  }

  Widget _buildBody(SimpleState<Map<String, dynamic>> settingsState, int offlineDraftCount) {
    if (settingsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (settingsState.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${settingsState.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(settingsProvider.notifier).loadSettings(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final settings = settingsState.data;
    if (settings != null) {
      _initStateFromSettings(settings);
    }

    return _buildContent(offlineDraftCount);
  }

  Widget _buildContent(int offlineDraftCount) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModelVersionCard(),
              const SizedBox(height: 20),
              _buildSectionHeader(Icons.memory, '推理模型开关'),
              _buildModelSwitches(),
              const SizedBox(height: 20),
              _buildSectionHeader(Icons.tune, '检测参数'),
              _buildDetectionParams(),
              const SizedBox(height: 20),
              _buildSectionHeader(Icons.storage, '存储与同步'),
              _buildStorageSettings(),
              const SizedBox(height: 12),
              _buildOfflineDraftCard(offlineDraftCount),
              const SizedBox(height: 40),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: ElevatedButton(
                onPressed: _isSaved ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F80ED),
                  disabledBackgroundColor: const Color(0xFF9CA3AF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  _isSaved ? '已保存' : '保存配置',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModelVersionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                '当前模型版本',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppInfo.modelDisplayVersion,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '自动上传与离线缓存已接入当前检测流程',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildModelSwitches() {
    return _buildCard(
      child: Column(
        children: [
          _buildSwitchRow(
            'Faster R-CNN 图像识别',
            '用于裂缝区域定位与识别',
            _fasterRcnnEnabled ?? true,
            (v) => setState(() => _fasterRcnnEnabled = v),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 16),
          _buildSwitchRow(
            '联合风险分析推理',
            '综合识别结果生成危险等级判定',
            _riskAnalysisEnabled ?? true,
            (v) => setState(() => _riskAnalysisEnabled = v),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 16),
          _buildSwitchRow(
            'DBSCAN 空间聚类去重',
            '减少重复框选，提高结果稳定性',
            _dbscanEnabled ?? true,
            (v) => setState(() => _dbscanEnabled = v),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionParams() {
    return _buildCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSliderRow(
            '检测灵敏度',
            '值越高越容易识别细微损伤',
            _sensitivity ?? 85.0,
            50,
            100,
            (v) => setState(() => _sensitivity = v),
            const Color(0xFF2F80ED),
            '%',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFF3F4F6)),
          ),
          _buildSliderRow(
            '置信度阈值',
            '低于该值的检测结果会被过滤',
            (_confThreshold ?? 0.72) * 100,
            50,
            95,
            (v) => setState(() => _confThreshold = v / 100),
            const Color(0xFF27AE60),
            '%',
          ),
        ],
      ),
    );
  }

  Widget _buildStorageSettings() {
    return _buildCard(
      child: Column(
        children: [
          _buildSwitchRow(
            '自动上传检测结果',
            '检测完成后自动同步到云端服务器',
            _autoUpload ?? true,
            (v) => setState(() => _autoUpload = v),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 16),
          _buildSwitchRow(
            '离线缓存模式',
            '无网络时保存到本地，联网后再同步',
            _offlineCache ?? true,
            (v) => setState(() => _offlineCache = v),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 16),
          _buildSwitchRow(
            '仅 Wi-Fi 同步',
            '仅在 Wi-Fi 环境下自动同步',
            _wifiOnly ?? false,
            (v) => setState(() => _wifiOnly = v),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineDraftCard(int offlineDraftCount) {
    return _buildCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_sync_outlined, color: Color(0xFF2F80ED)),
              const SizedBox(width: 8),
              Text(
                '离线草稿待同步 $offlineDraftCount 条',
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '无网络时会把检测图片和备注保存在本地，联网后可以手动同步到云端服务器。',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.5),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isSyncingDrafts || offlineDraftCount == 0 ? null : _handleSyncDrafts,
              icon: _isSyncingDrafts
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(_isSyncingDrafts ? '正在同步...' : '立即同步离线草稿'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding,
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
      child: child,
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6B7280), size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(color: Color(0xFF374151), fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Color(0xFF111827), fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: const Color(0xFF6B7280).withValues(alpha: 0.8), fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF2F80ED).withValues(alpha: 0.5),
            activeThumbColor: const Color(0xFF2F80ED),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    Color color,
    String suffix,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(color: Color(0xFF111827), fontSize: 15, fontWeight: FontWeight.w500),
            ),
            Text(
              '${value.toStringAsFixed(0)}$suffix',
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: const Color(0xFF6B7280).withValues(alpha: 0.8), fontSize: 12),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color.withValues(alpha: 0.3),
            inactiveTrackColor: const Color(0xFFE5E7EB),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.1),
            trackHeight: 6,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Future<void> _handleSyncDrafts() async {
    setState(() => _isSyncingDrafts = true);
    try {
      final synced = await ref.read(offlineDetectionNotifierProvider.notifier).syncAllDrafts();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(synced > 0 ? '已同步 $synced 条离线草稿' : '暂无可同步的离线草稿'),
          backgroundColor: synced > 0 ? const Color(0xFF27AE60) : const Color(0xFF6B7280),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncingDrafts = false);
      }
    }
  }
}
