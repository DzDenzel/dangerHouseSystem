import 'package:dio/dio.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/providers/network_providers.dart';
import '../core/state/base_state.dart';
import '../core/utils/common_utils.dart';
import '../core/utils/service_error_message.dart';
import '../data/models/detection_models.dart';
import '../data/repositories/detection_repository.dart';

enum DetectionSubmissionStage {
  uploading,
  uploadSuccess,
  created,
  ready,
  processing,
  completed,
  failed,
}

class DetectionSubmissionProgress {
  final DetectionSubmissionStage stage;
  final String message;
  final int? detectionId;
  final DetectionResultDto? detail;

  const DetectionSubmissionProgress({
    required this.stage,
    required this.message,
    this.detectionId,
    this.detail,
  });
}

class DetectionNotifier extends StateNotifier<SimpleState<DetectionResultDto>> {
  DetectionNotifier(this._repository) : super(const SimpleState.initial());

  final DetectionRepository _repository;

  static const int _maxFileSizeBytes = 5 * 1024 * 1024;
  static const int _defaultPollAttempts = 45;

  Future<DetectionResultDto?> uploadImages(
    List<XFile> imageFiles,
    int buildingId, {
    String? description,
    void Function(DetectionSubmissionProgress progress)? onProgress,
  }) async {
    state = const SimpleState.loading();
    int? createdDetectionId;
    DetectionResultDto? latestDetail;

    try {
      if (imageFiles.isEmpty) {
        throw Exception('请先选择至少一张检测图片');
      }

      for (final imageFile in imageFiles) {
        final fileSize = await imageFile.length();
        if (fileSize > _maxFileSizeBytes) {
          final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
          throw Exception('图片 ${imageFile.name} 大小 ${sizeMB}MB 超过限制，请压缩后重试');
        }
      }

      EasyLoading.show(status: '创建检测任务中...');
      createdDetectionId = await _repository.createDetectionEmpty(
        buildingId: buildingId,
        description: description,
      );
      if (createdDetectionId == null) {
        throw Exception('检测任务创建失败');
      }

      latestDetail = await _repository.getDetectionDetail(createdDetectionId);
      _notifyProgress(
        onProgress,
        stage: DetectionSubmissionStage.created,
        message: _buildStatusMessage(latestDetail?.status ?? 'CREATED'),
        detectionId: createdDetectionId,
        detail: latestDetail,
      );

      _notifyProgress(
        onProgress,
        stage: DetectionSubmissionStage.uploading,
        message: '正在上传检测图片',
        detectionId: createdDetectionId,
        detail: latestDetail,
      );

      EasyLoading.show(status: '正在上传检测图片...');
      final imageBytes = <List<int>>[];
      final fileNames = <String>[];
      for (final imageFile in imageFiles) {
        imageBytes.add(await imageFile.readAsBytes());
        fileNames.add(imageFile.name);
      }

      final uploadSuccess = await _repository.uploadDetectionImages(
        detectionId: createdDetectionId,
        imageBytes: imageBytes,
        fileNames: fileNames,
      );
      if (!uploadSuccess) {
        throw Exception('检测图片上传失败');
      }

      latestDetail = await _repository.getDetectionDetail(createdDetectionId) ?? latestDetail;
      _notifyProgress(
        onProgress,
        stage: DetectionSubmissionStage.uploadSuccess,
        message: '检测图片上传成功',
        detectionId: createdDetectionId,
        detail: latestDetail,
      );
      _notifyProgress(
        onProgress,
        stage: DetectionSubmissionStage.ready,
        message: _buildStatusMessage(latestDetail?.status ?? 'READY'),
        detectionId: createdDetectionId,
        detail: latestDetail,
      );

      EasyLoading.show(status: '检测任务已提交，准备开始识别...');
      final startResult = await _repository.startDetection(createdDetectionId);
      latestDetail = startResult ?? await _repository.getDetectionDetail(createdDetectionId) ?? latestDetail;

      if (latestDetail == null) {
        throw Exception('检测任务启动失败');
      }

      _notifyProgress(
        onProgress,
        stage: _mapStatusToStage(latestDetail.status),
        message: _buildStatusMessage(latestDetail.status ?? 'PROCESSING'),
        detectionId: createdDetectionId,
        detail: latestDetail,
      );

      final initialStatus = (latestDetail.status ?? '').toUpperCase();
      if (initialStatus == 'READY' || initialStatus == 'CREATED') {
        EasyLoading.dismiss();
        state = SimpleState.data(latestDetail);
        return latestDetail;
      }

      for (var retryCount = 0; retryCount < _defaultPollAttempts; retryCount++) {
        await Future.delayed(const Duration(seconds: 1));
        final detail = await _repository.getDetectionDetail(createdDetectionId);
        if (detail == null) {
          continue;
        }

        latestDetail = detail;
        _notifyProgress(
          onProgress,
          stage: _mapStatusToStage(detail.status),
          message: _buildStatusMessage(detail.status),
          detectionId: createdDetectionId,
          detail: detail,
        );

        if ((detail.status ?? '').toUpperCase() == 'COMPLETED') {
          EasyLoading.dismiss();
          state = SimpleState.data(detail);
          return detail;
        }

        if ((detail.status ?? '').toUpperCase() == 'FAILED') {
          state = SimpleState.data(detail);
          throw Exception(ServiceErrorMessage.forDetection(detail.errorMessage));
        }

        if ((detail.status ?? '').toUpperCase() == 'READY') {
          EasyLoading.dismiss();
          state = SimpleState.data(detail);
          return detail;
        }
      }

      EasyLoading.dismiss();
      if (latestDetail != null) {
        state = SimpleState.data(latestDetail);
        return latestDetail;
      }

      throw Exception('分析任务仍在处理中，请稍后在检测记录中查看结果');
    } catch (e) {
      EasyLoading.dismiss();
      final rawErrorMsg = e is DioException
          ? NetworkErrorUtils.getErrorMessage(e, defaultMsg: '检测失败，请稍后重试')
          : e.toString().replaceAll('Exception: ', '');
      final errorMsg = ServiceErrorMessage.forDetection(rawErrorMsg);
      _notifyProgress(
        onProgress,
        stage: DetectionSubmissionStage.failed,
        message: errorMsg,
        detectionId: createdDetectionId,
        detail: latestDetail,
      );
      EasyLoading.showError(errorMsg);
      state = SimpleState.error(errorMsg);
      return null;
    }
  }

  Future<DetectionResultDto?> uploadImage(
    XFile imageFile,
    int buildingId, {
    String? description,
    void Function(DetectionSubmissionProgress progress)? onProgress,
  }) {
    return uploadImages(
      [imageFile],
      buildingId,
      description: description,
      onProgress: onProgress,
    );
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

  String _buildStatusMessage(String? status) {
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

  void _notifyProgress(
    void Function(DetectionSubmissionProgress progress)? onProgress, {
    required DetectionSubmissionStage stage,
    required String message,
    int? detectionId,
    DetectionResultDto? detail,
  }) {
    onProgress?.call(
      DetectionSubmissionProgress(
        stage: stage,
        message: message,
        detectionId: detectionId,
        detail: detail,
      ),
    );
  }

  void reset() {
    state = const SimpleState.initial();
  }
}

final detectionProvider = StateNotifierProvider<DetectionNotifier, SimpleState<DetectionResultDto>>((ref) {
  final repository = ref.watch(detectionRepositoryProvider);
  return DetectionNotifier(repository);
});

final detectionResultProvider = Provider<DetectionResultDto?>((ref) {
  final state = ref.watch(detectionProvider);
  return state.data;
});

final detectionLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(detectionProvider);
  return state.isLoading;
});

final detectionErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(detectionProvider);
  return state.error;
});
