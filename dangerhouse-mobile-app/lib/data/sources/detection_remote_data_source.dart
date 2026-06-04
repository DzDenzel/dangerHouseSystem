import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/detection_models.dart';
import 'base_data_source.dart';

abstract class DetectionRemoteDataSource extends RemoteDataSource {
  Future<int> createDetection({
    required int buildingId,
    String? description,
    required List<File> images,
  });

  Future<int> createDetectionEmpty({required int buildingId, String? description});
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

  Future<DetectionResultDto> updateDetectionStatus(int id, String status);
  Future<void> deleteDetection(int id);
}

class DetectionRemoteDataSourceImpl extends DetectionRemoteDataSource {
  final DioClient _dioClient;

  DetectionRemoteDataSourceImpl({required DioClient dioClient})
      : _dioClient = dioClient;

  @override
  Future<int> createDetection({
    required int buildingId,
    String? description,
    required List<File> images,
  }) async {
    return safeCall(() async {
      AppLogger.api('POST', ApiConstants.detection);

      final formData = FormData();

      formData.fields.add(MapEntry('buildingId', buildingId.toString()));
      if (description != null && description.isNotEmpty) {
        formData.fields.add(MapEntry('description', description));
      }

      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        final fileName = file.path.split('/').last.split('\\').last;
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(file.path, filename: fileName),
          ),
        );
      }

      final response = await _dioClient.dio.post(
        ApiConstants.detection,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return _parseDetectionId(response.data);
    });
  }

  @override
  Future<int> createDetectionEmpty({required int buildingId, String? description}) async {
    return safeCall(() async {
      AppLogger.api('POST', ApiConstants.detection);

      final queryParams = <String, dynamic>{'buildingId': buildingId};
      if (description != null && description.isNotEmpty) {
        queryParams['description'] = description;
      }

      final response = await _dioClient.dio.post(
        ApiConstants.detection,
        queryParameters: queryParams,
      );

      return _parseDetectionId(response.data);
    });
  }

  @override
  Future<bool> uploadDetectionImages({
    required int detectionId,
    required List<List<int>> imageBytes,
    required List<String> fileNames,
  }) async {
    return safeCall(() async {
      AppLogger.api('POST', '${ApiConstants.detection}/$detectionId/images');

      final formData = FormData();

      for (int i = 0; i < imageBytes.length; i++) {
        formData.files.add(
          MapEntry(
            'images',
            MultipartFile.fromBytes(
              imageBytes[i],
              filename: fileNames[i],
            ),
          ),
        );
      }

      final response = await _dioClient.dio.post(
        '${ApiConstants.detection}/$detectionId/images',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final code = data['code'] as int?;
        return code == 0 || code == 200;
      }
      return true;
    });
  }

  @override
  Future<DetectionResultDto?> startDetection(int detectionId) async {
    return safeCall(() async {
      AppLogger.api('POST', '${ApiConstants.detection}/$detectionId/start');

      final response = await _dioClient.dio.post(
        '${ApiConstants.detection}/$detectionId/start',
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final code = data['code'] as int?;
        final message = data['message'] as String?;
        final responseData = data['data'] as Map<String, dynamic>?;

        if (code != null && code != 0 && code != 200) {
          throw ValidationException(
            message ?? '启动检测失败',
            statusCode: code,
          );
        }

        if (responseData == null) {
          return null;
        }

        return DetectionResultDto.fromJson(responseData);
      }

      return null;
    });
  }

  @override
  Future<DetectionResultDto?> getDetectionDetail(int id) async {
    return safeCall(() async {
      AppLogger.api('GET', '${ApiConstants.detection}/$id');

      final response = await _dioClient.dio.get('${ApiConstants.detection}/$id');

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final code = data['code'] as int?;
        final message = data['message'] as String?;
        final responseData = data['data'] as Map<String, dynamic>?;

        if (code != null && code != 0 && code != 200) {
          throw NotFoundException(
            message ?? '检测任务不存在',
            statusCode: code,
          );
        }

        if (responseData == null) {
          return null;
        }

        return DetectionResultDto.fromJson(responseData);
      }

      throw const UnknownException('获取检测详情响应格式错误');
    });
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
    return safeCall(() async {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };

      if (buildingId != null) {
        queryParams['buildingId'] = buildingId;
      }

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      if (startDate != null && startDate.isNotEmpty) {
        queryParams['startDate'] = startDate;
      }

      if (endDate != null && endDate.isNotEmpty) {
        queryParams['endDate'] = endDate;
      }

      AppLogger.api('GET', ApiConstants.detection, queryParams);

      final response = await _dioClient.dio.get(
        ApiConstants.detection,
        queryParameters: queryParams,
      );

      return _parseDetectionList(response.data);
    });
  }

  @override
  Future<DetectionResultDto> updateDetectionStatus(int id, String status) async {
    return safeCall(() async {
      AppLogger.api('PUT', '${ApiConstants.detection}/$id/status');

      final response = await _dioClient.dio.put(
        '${ApiConstants.detection}/$id/status',
        data: {'status': status},
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final code = data['code'] as int?;
        final message = data['message'] as String?;
        final responseData = data['data'] as Map<String, dynamic>?;

        if (code != null && code != 0 && code != 200) {
          throw ValidationException(
            message ?? '更新检测状态失败',
            statusCode: code,
          );
        }

        if (responseData == null) {
          throw const ValidationException('更新检测状态响应数据为空');
        }

        return DetectionResultDto.fromJson(responseData);
      }

      throw const UnknownException('更新检测状态响应格式错误');
    });
  }

  @override
  Future<void> deleteDetection(int id) async {
    return safeCall(() async {
      AppLogger.api('DELETE', '${ApiConstants.detection}/$id');

      final response = await _dioClient.dio.delete('${ApiConstants.detection}/$id');

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final code = data['code'] as int?;
        final message = data['message'] as String?;

        if (code != null && code != 0 && code != 200) {
          throw ValidationException(
            message ?? '删除检测任务失败',
            statusCode: code,
          );
        }
      }
    });
  }

  int _parseDetectionId(dynamic data) {
    if (data is Map<String, dynamic>) {
      final code = data['code'] as int?;
      final message = data['message'] as String?;
      final responseData = data['data'] as Map<String, dynamic>?;

      if (code != null && code != 0 && code != 200) {
        throw ValidationException(
          message ?? '创建检测任务失败',
          statusCode: code,
        );
      }

      if (responseData == null) {
        throw const ValidationException('创建检测任务响应数据为空');
      }

      return responseData['id'] as int? ?? responseData['detectionId'] as int? ?? 0;
    }

    throw const UnknownException('创建检测任务响应格式错误');
  }

  List<DetectionResultDto> _parseDetectionList(dynamic data) {
    if (data is Map<String, dynamic>) {
      final innerData = data['data'];
      if (innerData is Map && innerData.containsKey('records')) {
        return (innerData['records'] as List)
            .map((e) => DetectionResultDto.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (innerData is List) {
        return innerData
            .map((e) => DetectionResultDto.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } else if (data is List) {
      return data.map((e) => DetectionResultDto.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
