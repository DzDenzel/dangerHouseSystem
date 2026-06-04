import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/providers/network_providers.dart';
import '../../core/utils/service_error_message.dart';
import '../../data/models/building_models.dart';
import '../../data/models/detection_models.dart';
import '../../data/repositories/settings_repository.dart';
import '../../providers/detection_provider.dart';
import '../../providers/refresh_notifier.dart';
import '../result/result_activity.dart';
import 'building_selection_page.dart';
import 'capture_activity.dart';

class AIDetectionPage extends ConsumerStatefulWidget {
  const AIDetectionPage({
    super.key,
    this.preSelectedBuilding,
    this.existingDetectionId,
    this.returnResultOnSuccess = false,
  });

  final Building? preSelectedBuilding;
  final int? existingDetectionId;
  final bool returnResultOnSuccess;

  @override
  ConsumerState<AIDetectionPage> createState() => _AIDetectionPageState();
}

class _AIDetectionPageState extends ConsumerState<AIDetectionPage> {
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _imageFiles = [];

  Building? _selectedBuilding;
  bool _isDetecting = false;
  double _progress = 0;
  String _detectingStatus = '准备开始检测';

  @override
  void initState() {
    super.initState();
    _selectedBuilding = widget.preSelectedBuilding;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectBuilding() async {
    final building = await Navigator.push<Building>(
      context,
      MaterialPageRoute(builder: (_) => const BuildingSelectionPage()),
    );
    if (!mounted || building == null) {
      return;
    }
    setState(() => _selectedBuilding = building);
  }

  Future<void> _takePhoto() async {
    final file = await Navigator.push<XFile>(
      context,
      MaterialPageRoute(builder: (_) => const CaptureActivity()),
    );
    if (!mounted || file == null) {
      return;
    }
    setState(() => _imageFiles.add(file));
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage();
    if (!mounted || files.isEmpty) {
      return;
    }
    setState(() => _imageFiles.addAll(files));
  }

  Future<void> _handleDetect() async {
    final description = _descriptionController.text.trim();

    if (_imageFiles.isEmpty) {
      _showSnack('请先上传检测图片');
      return;
    }

    if (description.isEmpty) {
      _showSnack('请填写检测备注，用于区分每次检测记录');
      return;
    }

    if (widget.existingDetectionId == null && _selectedBuilding == null) {
      _showSnack('请先选择关联建筑');
      await _selectBuilding();
      return;
    }

    setState(() {
      _isDetecting = true;
      _progress = 0.05;
      _detectingStatus = '正在创建检测任务';
    });

    try {
      final result = widget.existingDetectionId != null
          ? await _performExistingDetection(widget.existingDetectionId!)
          : await ref.read(detectionProvider.notifier).uploadImages(
                _imageFiles,
                _selectedBuilding!.id,
                description: description,
                onProgress: _handleSubmissionProgress,
              );

      if (!mounted) {
        return;
      }

      setState(() {
        _isDetecting = false;
        _progress = 1;
        _detectingStatus = '检测流程已提交';
      });

      if (result == null) {
        _showSnack('检测提交失败，请稍后重试');
        return;
      }

      final notifier = ref.read(refreshNotifierProvider.notifier);
      if (widget.existingDetectionId != null) {
        notifier.notifyDetectionUpdated(detectionId: result.id);
      } else {
        notifier.notifyDetectionCreated(detectionId: result.id);
      }
      notifier.notifyRefreshAll();

      if (widget.returnResultOnSuccess) {
        Navigator.pop(context, result);
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultActivity(
            imageFile: _imageFiles.isNotEmpty ? _imageFiles.first : null,
            result: result,
            detectionId: result.id,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      final shouldCacheOffline = await _shouldCacheOffline();
      if (shouldCacheOffline &&
          _selectedBuilding != null &&
          _looksLikeNetworkFailure(e)) {
        final offlineRepository = ref.read(offlineDetectionRepositoryProvider);
        await offlineRepository.saveDraft(
          buildingId: _selectedBuilding!.id,
          buildingName: _selectedBuilding!.name,
          buildingAddress: _selectedBuilding!.address,
          description: description,
          images: _imageFiles,
        );
      }

      setState(() {
        _isDetecting = false;
        _detectingStatus = '检测失败';
      });

      final errorText = ServiceErrorMessage.forDetection(e.toString());
      if (shouldCacheOffline &&
          _selectedBuilding != null &&
          _looksLikeNetworkFailure(e)) {
        _showSnack('$errorText，已切换为离线缓存，联网后可在设置页同步');
      } else {
        _showSnack(errorText);
      }
    }
  }

  Future<DetectionResultDto?> _performExistingDetection(int detectionId) async {
    final repository = ref.read(detectionRepositoryProvider);

    _handleSubmissionProgress(
      DetectionSubmissionProgress(
        stage: DetectionSubmissionStage.uploading,
        message: '正在上传检测图片',
        detectionId: detectionId,
      ),
    );

    final imageBytes = <List<int>>[];
    final fileNames = <String>[];
    for (final image in _imageFiles) {
      imageBytes.add(await image.readAsBytes());
      fileNames.add(image.name);
    }

    final uploadSuccess = await repository.uploadDetectionImages(
      detectionId: detectionId,
      imageBytes: imageBytes,
      fileNames: fileNames,
    );
    if (!uploadSuccess) {
      throw Exception('检测图片上传失败');
    }

    _handleSubmissionProgress(
      DetectionSubmissionProgress(
        stage: DetectionSubmissionStage.uploadSuccess,
        message: '检测图片上传成功',
        detectionId: detectionId,
      ),
    );
    _handleSubmissionProgress(
      DetectionSubmissionProgress(
        stage: DetectionSubmissionStage.ready,
        message: '检测任务已就绪，等待进入识别',
        detectionId: detectionId,
      ),
    );

    final started = await repository.startDetection(detectionId);
    var latestDetail = started ?? await repository.getDetectionDetail(detectionId);
    if (latestDetail == null) {
      throw Exception(ServiceErrorMessage.forDetection('connection refused'));
    }

    _handleSubmissionProgress(
      DetectionSubmissionProgress(
        stage: _mapStatusToStage(latestDetail.status),
        message: _statusMessage(latestDetail.status),
        detectionId: detectionId,
        detail: latestDetail,
      ),
    );

    final initialStatus = (latestDetail.status ?? '').toUpperCase();
    if (initialStatus == 'READY' || initialStatus == 'CREATED') {
      return latestDetail;
    }

    for (var retry = 0; retry < 45; retry++) {
      await Future.delayed(const Duration(seconds: 1));
      final detail = await repository.getDetectionDetail(detectionId);
      if (detail != null) {
        latestDetail = detail;
        _handleSubmissionProgress(
          DetectionSubmissionProgress(
            stage: _mapStatusToStage(detail.status),
            message: _statusMessage(detail.status),
            detectionId: detectionId,
            detail: detail,
          ),
        );
      }
      if (detail?.status == 'COMPLETED') {
        return detail;
      }
      if (detail?.status == 'FAILED') {
        throw Exception(ServiceErrorMessage.forDetection(detail?.errorMessage));
      }
      if (detail?.status == 'READY') {
        return detail;
      }
    }

    return latestDetail;
  }

  void _handleSubmissionProgress(DetectionSubmissionProgress progress) {
    if (!mounted) {
      return;
    }

    setState(() {
      _detectingStatus = progress.message;
      _progress = _progressValue(progress.stage);
    });
  }

  double _progressValue(DetectionSubmissionStage stage) {
    switch (stage) {
      case DetectionSubmissionStage.created:
        return 0.12;
      case DetectionSubmissionStage.uploading:
        return 0.28;
      case DetectionSubmissionStage.uploadSuccess:
        return 0.42;
      case DetectionSubmissionStage.ready:
        return 0.56;
      case DetectionSubmissionStage.processing:
        return 0.76;
      case DetectionSubmissionStage.completed:
        return 1.0;
      case DetectionSubmissionStage.failed:
        return _progress.clamp(0.05, 0.95);
    }
  }

  DetectionSubmissionStage _mapStatusToStage(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'COMPLETED':
        return DetectionSubmissionStage.completed;
      case 'FAILED':
        return DetectionSubmissionStage.failed;
      case 'PROCESSING':
        return DetectionSubmissionStage.processing;
      case 'READY':
        return DetectionSubmissionStage.ready;
      case 'CREATED':
      default:
        return DetectionSubmissionStage.created;
    }
  }

  String _statusMessage(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'COMPLETED':
        return 'AI 检测已完成';
      case 'FAILED':
        return 'AI 检测失败';
      case 'PROCESSING':
        return '检测中，系统正在排队或分析图片';
      case 'READY':
        return '检测任务已就绪，等待进入识别';
      case 'CREATED':
      default:
        return '检测任务已创建';
    }
  }

  Future<bool> _shouldCacheOffline() async {
    final settings = await SettingsRepository().loadSettings();
    return settings['offlineCache'] == true;
  }

  bool _looksLikeNetworkFailure(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('socketexception') ||
        text.contains('connection error') ||
        text.contains('connection refused') ||
        text.contains('timeout') ||
        text.contains('xmlhttprequest') ||
        text.contains('network');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 检测')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: '检测对象',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.domain),
              title: Text(_selectedBuilding?.name ?? '未选择建筑'),
              subtitle: Text(_selectedBuilding?.address ?? '请选择本次检测关联建筑'),
              trailing: const Icon(Icons.chevron_right),
              onTap: widget.existingDetectionId == null ? _selectBuilding : null,
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: '检测备注',
            child: TextField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 2,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: '如：3月复检、南立面裂缝复核',
                helperText: '检测备注必填，用于区分同一建筑的不同检测记录',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: '检测图片',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_imageFiles.isEmpty)
                  Container(
                    height: 180,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('请上传现场检测图片'),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '已选择 ${_imageFiles.length} 张图片',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _imageFiles.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (_, index) => _ImagePreview(
                          file: _imageFiles[index],
                          onRemove: _isDetecting
                              ? null
                              : () => setState(() => _imageFiles.removeAt(index)),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isDetecting ? null : _takePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('拍照'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isDetecting ? null : _pickImages,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('相册多选'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isDetecting) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 8),
            Text('$_detectingStatus ${(_progress * 100).toStringAsFixed(0)}%'),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isDetecting ? null : _handleDetect,
              icon: const Icon(Icons.analytics),
              label: Text(_isDetecting ? '检测处理中...' : '开始 AI 检测'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.file, this.onRemove});

  final XFile file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        return Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFF3F4F6),
                ),
                clipBehavior: Clip.antiAlias,
                child: snapshot.hasData
                    ? InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                backgroundColor: Colors.black,
                                appBar: AppBar(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                ),
                                body: Center(
                                  child: Image.memory(snapshot.data!, fit: BoxFit.contain),
                                ),
                              ),
                            ),
                          );
                        },
                        child: Image.memory(snapshot.data!, fit: BoxFit.cover),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
            if (onRemove != null)
              Positioned(
                right: 6,
                top: 6,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
