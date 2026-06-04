import 'dart:io';
import '../sources/detection_remote_data_source.dart';
import '../../core/errors/error_handler.dart';
import '../models/detection_models.dart';
import 'base_repository.dart';

abstract class DetectionRepository extends BaseRepository {
  Future<int?> createDetection({
    required int buildingId,
    String? description,
    required List<File> images,
  });

  Future<int?> createDetectionEmpty({required int buildingId, String? description});
  Future<bool> uploadDetectionImages({
    required int detectionId,
    required List<List<int>> imageBytes,
    required List<String> fileNames,
  });

  Future<DetectionResultDto?> startDetection(int detectionId);
  Future<DetectionResultDto?> getDetectionDetail(int id);
  Future<List<DetectionResultDto>> getDetections({
    int? buildingId,
    String? status,
    String? startDate,
    String? endDate,
    int page,
    int size,
  });

  Future<DetectionResultDto?> updateDetectionStatus(int id, String status);
  Future<bool> deleteDetection(int id);
}

class DetectionRepositoryImpl extends DetectionRepository {
  final DetectionRemoteDataSource _remoteDataSource;

  DetectionRepositoryImpl({required DetectionRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<int?> createDetection({
    required int buildingId,
    String? description,
    required List<File> images,
  }) async {
    try {
      return await _remoteDataSource.createDetection(
        buildingId: buildingId,
        description: description,
        images: images,
      );
    } catch (e) {
      ErrorHandler.handleError(e, context: '创建检测任务');
      return null;
    }
  }

  @override
  Future<int?> createDetectionEmpty({required int buildingId, String? description}) async {
    try {
      return await _remoteDataSource.createDetectionEmpty(buildingId: buildingId, description: description);
    } catch (e) {
      ErrorHandler.handleError(e, context: '创建检测任务');
      return null;
    }
  }

  @override
  Future<bool> uploadDetectionImages({
    required int detectionId,
    required List<List<int>> imageBytes,
    required List<String> fileNames,
  }) async {
    try {
      return await _remoteDataSource.uploadDetectionImages(
        detectionId: detectionId,
        imageBytes: imageBytes,
        fileNames: fileNames,
      );
    } catch (e) {
      ErrorHandler.handleError(e, context: '上传检测图片');
      return false;
    }
  }

  @override
  Future<DetectionResultDto?> startDetection(int detectionId) async {
    try {
      return await _remoteDataSource.startDetection(detectionId);
    } catch (e) {
      ErrorHandler.handleError(e, context: '启动检测');
      return null;
    }
  }

  @override
  Future<DetectionResultDto?> getDetectionDetail(int id) async {
    try {
      return await _remoteDataSource.getDetectionDetail(id);
    } catch (e) {
      ErrorHandler.handleError(e, context: '获取检测详情');
      return null;
    }
  }

  @override
  Future<List<DetectionResultDto>> getDetections({
    int? buildingId,
    String? status,
    String? startDate,
    String? endDate,
    int page = 1,
    int size = 10,
  }) async {
    try {
      return await _remoteDataSource.getDetections(
        buildingId: buildingId,
        status: status,
        startDate: startDate,
        endDate: endDate,
        page: page,
        size: size,
      );
    } catch (e) {
      ErrorHandler.handleError(e, context: '获取检测列表');
      return [];
    }
  }

  @override
  Future<DetectionResultDto?> updateDetectionStatus(int id, String status) async {
    try {
      return await _remoteDataSource.updateDetectionStatus(id, status);
    } catch (e) {
      ErrorHandler.handleError(e, context: '更新检测状态');
      return null;
    }
  }

  @override
  Future<bool> deleteDetection(int id) async {
    try {
      await _remoteDataSource.deleteDetection(id);
      return true;
    } catch (e) {
      ErrorHandler.handleError(e, context: '删除检测任务');
      return false;
    }
  }
}
