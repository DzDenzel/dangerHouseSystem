import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/app_logger.dart';

class SystemRepository {
  final DioClient _dioClient;

  SystemRepository(this._dioClient);

  Future<Map<String, dynamic>?> getDashboard() async {
    try {
      AppLogger.api('GET', ApiConstants.adminDashboard);

      final response = await _dioClient.dio.get(ApiConstants.adminDashboard);

      if (_dioClient.isSuccessResponse(response)) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      AppLogger.e('获取仪表盘数据失败', e);
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getOperationLogs({
    int page = 1,
    int size = 10,
    String? operationType,
    String? startTime,
    String? endTime,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };

      if (operationType != null && operationType.isNotEmpty) {
        queryParams['operationType'] = operationType;
      }

      if (startTime != null && startTime.isNotEmpty) {
        queryParams['startTime'] = startTime;
      }

      if (endTime != null && endTime.isNotEmpty) {
        queryParams['endTime'] = endTime;
      }

      AppLogger.api('GET', ApiConstants.adminOperationLogs, queryParams);

      final response = await _dioClient.dio.get(
        ApiConstants.adminOperationLogs,
        queryParameters: queryParams,
      );

      final data = response.data['data'];
      if (data is Map && data.containsKey('records')) {
        return List<Map<String, dynamic>>.from(data['records']);
      } else if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      AppLogger.e('获取操作日志失败', e);
      return [];
    }
  }

  Future<Map<String, dynamic>?> healthCheck() async {
    try {
      AppLogger.api('GET', ApiConstants.health);

      final response = await _dioClient.dio.get(ApiConstants.health);

      if (_dioClient.isSuccessResponse(response)) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      AppLogger.e('健康检查失败', e);
      return null;
    }
  }
}
