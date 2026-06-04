import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/providers/network_providers.dart';
import '../../core/utils/risk_level_util.dart';
import '../../core/utils/service_error_message.dart';
import '../../data/models/building_models.dart';
import '../../data/models/detection_models.dart';
import '../../providers/refresh_notifier.dart';
import '../capture/ai_detection_page.dart';
import '../task/report_detail_page.dart';

class ResultActivity extends ConsumerStatefulWidget {
  final XFile? imageFile;
  final DetectionResultDto? result;
  final int? detectionId;

  const ResultActivity({
    super.key,
    this.imageFile,
    this.result,
    this.detectionId,
  });

  @override
  ConsumerState<ResultActivity> createState() => _ResultActivityState();
}

class _ResultActivityState extends ConsumerState<ResultActivity> {
  final PageController _pageController = PageController(viewportFraction: 1);

  DetectionResultDto? _data;
  bool _isLoading = false;
  bool _isGeneratingReport = false;
  bool _isStartingDetection = false;
  int _currentImageIndex = 0;
  List<_ResultImageFrame> _frames = const [];

  @override
  void initState() {
    super.initState();
    _data = widget.result;
    _bootstrap();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (_data == null && widget.detectionId != null) {
      await _loadDetail(widget.detectionId!);
      return;
    }

    if (_data != null) {
      await _loadImageFrames(_data!);
    } else if (widget.imageFile != null) {
      await _loadLocalFallback(widget.imageFile!);
    }
  }

  Future<void> _loadDetail(int id) async {
    setState(() => _isLoading = true);
    try {
      final detail = await ref.read(detectionRepositoryProvider).getDetectionDetail(id);
      if (!mounted) {
        return;
      }

      setState(() {
        _data = detail;
        _isLoading = false;
      });

      if (detail != null) {
        await _loadImageFrames(detail);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      _showSnack(ServiceErrorMessage.forDetection(e.toString()));
    }
  }

  Future<void> _loadLocalFallback(XFile file) async {
    final bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() {
      _frames = [
        _ResultImageFrame(
          displayBytes: bytes,
          originalBytes: bytes,
        ),
      ];
    });
  }

  Future<void> _loadImageFrames(DetectionResultDto detail) async {
    final images = detail.resolvedImages;
    if (images.isEmpty) {
      if (widget.imageFile != null && _frames.isEmpty) {
        await _loadLocalFallback(widget.imageFile!);
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final frames = <_ResultImageFrame>[];
      for (final image in images) {
        final original = await _downloadImageBytes(dio, image.fullImagePath);
        final result = await _downloadImageBytes(
          dio,
          image.fullResultImagePath ?? image.fullImagePath,
        );

        if (original == null && result == null) {
          continue;
        }

        frames.add(
          _ResultImageFrame(
            displayBytes: result ?? original!,
            originalBytes: original ?? result!,
          ),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _frames = frames;
        _currentImageIndex = 0;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Uint8List?> _downloadImageBytes(Dio dio, String? url) async {
    if (url == null || url.isEmpty) {
      return null;
    }

    final response = await dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null || data.isEmpty) {
      return null;
    }
    return Uint8List.fromList(data);
  }

  Future<void> _handleStartDetection() async {
    final detectionId = _data?.id ?? widget.detectionId;
    if (detectionId == null || _isStartingDetection) {
      return;
    }

    setState(() {
      _isStartingDetection = true;
      _isLoading = true;
    });
    try {
      final detail = await ref.read(detectionRepositoryProvider).startDetection(detectionId);
      if (detail == null) {
        throw Exception('检测任务启动失败，请稍后重试');
      }
      if (!mounted) {
        return;
      }
      setState(() => _data = detail);
      await _loadDetail(detectionId);
      if (!mounted) {
        return;
      }
      ref.read(refreshNotifierProvider.notifier).notifyDetectionUpdated(detectionId: detectionId);
      ref.read(refreshNotifierProvider.notifier).notifyRefreshAll();
      _showSnack('检测任务已提交，请稍后手动刷新状态');
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      _showSnack(ServiceErrorMessage.forDetection(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _isStartingDetection = false);
      }
    }
  }

  Future<void> _handleGenerateReport() async {
    final detectionId = _data?.id ?? widget.detectionId;
    if (detectionId == null || _isGeneratingReport) {
      return;
    }

    if (_data?.report?.id != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReportDetailPage(detectionId: detectionId),
        ),
      );
      return;
    }

    setState(() => _isGeneratingReport = true);
    try {
      final response = await ref.read(reportRepositoryProvider).generateReport(
            detectionId: detectionId,
            format: 'PDF',
          );

      if (!mounted) {
        return;
      }

      if (response == null) {
        throw Exception('报告生成失败');
      }

      ref.read(refreshNotifierProvider.notifier).notifyDetectionUpdated(detectionId: detectionId);
      ref.read(refreshNotifierProvider.notifier).notifyRefreshAll();
      _showSnack('正式检测报告已生成');

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReportDetailPage(detectionId: detectionId),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      _showSnack(ServiceErrorMessage.forReport(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _isGeneratingReport = false);
      }
    }
  }

  Future<void> _goToUploadImage() async {
    if (_data == null || _data!.buildingId == null) {
      return;
    }

    final result = await Navigator.push<DetectionResultDto>(
      context,
      MaterialPageRoute(
        builder: (_) => AIDetectionPage(
          preSelectedBuilding: Building(
            id: _data!.buildingId!,
            name: _data!.buildingName ?? '未命名建筑',
            address: _data!.buildingAddress ?? '',
            structureType: 'OTHER',
            initialRiskLevel: _data!.resolvedRiskLevel,
          ),
          existingDetectionId: _data!.id,
          returnResultOnSuccess: true,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() => _data = result);
      await _loadImageFrames(result);
    }
  }

  void _openOriginalImage() {
    if (_frames.isEmpty) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenImagePreview(
          imageBytes: _frames[_currentImageIndex].originalBytes,
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('加载中...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('详情')),
        body: const Center(child: Text('暂无数据或加载失败')),
      );
    }

    final status = _data!.status?.toUpperCase() ?? '';
    final hasNoResult = (status == 'CREATED' || status == 'READY' || status == 'PROCESSING' || status == 'FAILED') &&
        _data!.resolvedCrackCount == 0 &&
        _data!.resolvedDamageRatio == 0;

    if (hasNoResult) {
      return _buildNoResultPage(status);
    }

    final riskLevel = _data!.resolvedRiskLevel;
    final riskColor = RiskLevelUtil.getColor(riskLevel);
    final riskLabel = RiskLevelUtil.getLabel(riskLevel);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'AI识别结果',
          style: TextStyle(color: Color(0xFF111827), fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildImageArea(),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildRiskBanner(riskLevel, riskColor, riskLabel),
                  ),
                  _buildDamageRatioIndicator(_data!.resolvedDamageRatio, riskColor),
                  _buildMetricsGrid(),
                  _buildExpertAdvice(riskColor),
                  _buildNextStepsSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildNoResultPage(String status) {
    final building = _data?.buildingId != null
        ? Building(
            id: _data!.buildingId!,
            name: _data!.buildingName ?? '未查得建筑',
            address: _data!.buildingAddress ?? '',
            structureType: 'OTHER',
          )
        : null;

    final bool canUpload = building != null && widget.detectionId != null && status == 'CREATED';
    final bool canStart = widget.detectionId != null && status == 'READY' && (_data?.resolvedImages.isNotEmpty == true);
    final bool canRetry = widget.detectionId != null && status == 'FAILED';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '检测详情',
          style: TextStyle(color: Color(0xFF111827), fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C00).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pending_actions, size: 64, color: Color(0xFFFF8C00)),
            ),
            const SizedBox(height: 24),
            Text(
              _pendingTitle(status),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _pendingDescription(status),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    final id = _data?.id ?? widget.detectionId;
                    if (id != null) {
                      _loadDetail(id);
                    }
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('刷新状态'),
                ),
                if (canUpload)
                  ElevatedButton.icon(
                    onPressed: _goToUploadImage,
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('上传图片检测'),
                  ),
                if (canStart || canRetry)
                  ElevatedButton.icon(
                    onPressed: _isStartingDetection ? null : _handleStartDetection,
                    icon: _isStartingDetection
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Icon(canRetry ? Icons.refresh : Icons.play_arrow, size: 18),
                    label: Text(canRetry ? '重新检测' : '开始检测'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _pendingTitle(String status) {
    switch (status) {
      case 'PROCESSING':
        return 'AI 检测中';
      case 'READY':
        return '检测任务已就绪';
      case 'FAILED':
        return '检测任务执行失败';
      case 'CREATED':
      default:
        return '等待上传和检测';
    }
  }

  String _pendingDescription(String status) {
    switch (status) {
      case 'PROCESSING':
        return '当前任务正在排队或分析图纸，请稍后手动刷新状态查看进度。';
      case 'READY':
        return '检测图纸已上传成功，AI 服务恢复后可直接点击"开始检测"，无需重新上传图纸。';
      case 'FAILED':
        return ServiceErrorMessage.forDetection(_data?.errorMessage);
      case 'CREATED':
      default:
        return '当前任务还没有可展示的检测结果，请继续上传检测图纸并发起识别。';
    }
  }

  Widget _buildImageArea() {
    final hasImages = _frames.isNotEmpty;

    return Container(
      width: double.infinity,
      color: Colors.black,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_isLoading && !hasImages)
                  Container(
                    color: Colors.grey[900],
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(color: Colors.white54),
                  )
                else if (hasImages)
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _frames.length,
                    onPageChanged: (index) {
                      setState(() => _currentImageIndex = index);
                    },
                    itemBuilder: (_, index) {
                      return Image.memory(
                        _frames[index].displayBytes,
                        fit: BoxFit.cover,
                      );
                    },
                  )
                else
                  Container(
                    color: Colors.grey[900],
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, color: Colors.white54, size: 48),
                        SizedBox(height: 8),
                        Text('暂无识别图片', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          hasImages ? '识别完成 ${_currentImageIndex + 1}/${_frames.length}' : '识别中',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                      if (hasImages)
                        GestureDetector(
                          onTap: _openOriginalImage,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                SizedBox(width: 6),
                                Text('查看原图', style: TextStyle(color: Colors.white, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (hasImages && _frames.length > 1)
            Container(
              height: 84,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: const Color(0xFF111827),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _frames.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final active = index == _currentImageIndex;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active ? const Color(0xFF2F80ED) : Colors.white24,
                          width: active ? 2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.memory(_frames[index].displayBytes, fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRiskBanner(String riskLevel, Color riskColor, String riskLabel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: riskColor, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  riskLabel,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: riskColor),
                ),
                const SizedBox(height: 2),
                Text(
                  _data?.resolvedAnalysis ?? '请结合现场复核结果进行判断',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDamageRatioIndicator(double damageRatio, Color riskColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('损伤比例', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                Text(
                  '${damageRatio.toStringAsFixed(2)}%',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: riskColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (damageRatio / 100).clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: const Color(0xFFF3F4F6),
                valueColor: AlwaysStoppedAnimation<Color>(riskColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final riskColor = RiskLevelUtil.getColor(_data!.resolvedRiskLevel);
    final metrics = [
      {'label': '检测裂缝数量', 'value': '${_data!.resolvedCrackCount}', 'unit': '条', 'color': riskColor},
      {'label': '局部损伤比率', 'value': _data!.resolvedDamageRatio.toStringAsFixed(2), 'unit': '%', 'color': riskColor},
      {'label': '裂缝最大宽度', 'value': _data!.resolvedMaxWidth.toStringAsFixed(1), 'unit': 'px', 'color': const Color(0xFFFF8C00)},
      {'label': 'AI 置信度', 'value': _data!.resolvedConfidence.toStringAsFixed(2), 'unit': '%', 'color': const Color(0xFF2F80ED)},
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('检测数据', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
            ),
            itemCount: metrics.length,
            itemBuilder: (_, index) {
              final metric = metrics[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(metric['label'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          metric['value'] as String,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: metric['color'] as Color,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          metric['unit'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: metric['color'] as Color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpertAdvice(Color riskColor) {
    final advice = _data?.resolvedAnalysis ?? '建议结合现场复核结果，尽快安排结构安全复核和处置。';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(color: riskColor, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI 初步处置建议',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: riskColor.withOpacity(0.15)),
              ),
              child: Text(
                advice,
                style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextStepsSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(color: const Color(0xFF2F80ED), borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 8),
                const Text(
                  '检测对象',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _data!.buildingName ?? '未查得建筑',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _data!.description?.isNotEmpty == true
                              ? '检测备注: ${_data!.description}'
                              : '风险等级: ${_riskLabel(_data!.resolvedRiskLevel)}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: Color(0xFF9CA3AF)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    final status = _data?.status?.toUpperCase() ?? '';
    final hasUploadedImages = _data?.resolvedImages.isNotEmpty == true;
    final bool isCreatedWithoutImages = status == 'CREATED' && !hasUploadedImages;
    final bool isReadyToStart = status == 'READY' && hasUploadedImages;
    final bool isFailed = status == 'FAILED';
    final bool isCompleted = status == 'COMPLETED';

    String buttonText = '刷新状态';
    VoidCallback? onPressed = () {
      final id = _data?.id ?? widget.detectionId;
      if (id != null) {
        _loadDetail(id);
      }
    };
    Color buttonColor = const Color(0xFF2F80ED);
    IconData buttonIcon = Icons.refresh;

    if (isCreatedWithoutImages) {
      buttonText = '上传图片检测';
      onPressed = _goToUploadImage;
      buttonIcon = Icons.camera_alt;
    } else if (isReadyToStart) {
      buttonText = '开始检测';
      onPressed = _isStartingDetection ? null : _handleStartDetection;
      buttonIcon = Icons.play_arrow;
      buttonColor = const Color(0xFFFF8C00);
    } else if (isFailed) {
      buttonText = '重新检测';
      onPressed = _isStartingDetection ? null : _handleStartDetection;
      buttonIcon = Icons.refresh;
      buttonColor = const Color(0xFFFF8C00);
    } else if (isCompleted) {
      buttonText = '生成检测报告';
      onPressed = _isGeneratingReport ? null : _handleGenerateReport;
      buttonIcon = Icons.description;
      buttonColor = const Color(0xFF10B981);
    }

    if (_isStartingDetection && (isReadyToStart || isFailed)) {
      buttonText = '检测中...';
      onPressed = null;
    } else if (_isGeneratingReport && isCompleted) {
      buttonText = '生成中...';
      onPressed = null;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: _isStartingDetection || _isGeneratingReport
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Icon(buttonIcon, size: 18),
            label: Text(buttonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }

  String _riskLabel(String riskLevel) {
    return RiskLevelUtil.getLabel(riskLevel);
  }
}

class _ResultImageFrame {
  final Uint8List displayBytes;
  final Uint8List originalBytes;

  const _ResultImageFrame({
    required this.displayBytes,
    required this.originalBytes,
  });
}

class _FullScreenImagePreview extends StatelessWidget {
  final Uint8List imageBytes;

  const _FullScreenImagePreview({required this.imageBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('原图预览'),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.memory(imageBytes, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
