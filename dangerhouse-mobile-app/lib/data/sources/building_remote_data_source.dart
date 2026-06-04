import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/building_models.dart';
import 'base_data_source.dart';

abstract class BuildingRemoteDataSource extends RemoteDataSource {
  Future<List<Building>> getBuildings({
    String? query,
    int page,
    int size,
    String? address,
    List<String>? riskLevels,
  });

  Future<Building?> getBuildingById(int id);
  Future<Building> createBuilding(CreateBuildingRequest request);
  Future<Building> updateBuilding(int id, UpdateBuildingRequest request);
  Future<void> deleteBuilding(int id);
  Future<List<Building>> searchBuildings(String query);
}

class BuildingRemoteDataSourceImpl extends BuildingRemoteDataSource {
  final DioClient _dioClient;

  BuildingRemoteDataSourceImpl({required DioClient dioClient})
      : _dioClient = dioClient;

  @override
  Future<List<Building>> getBuildings({
    String? query,
    int page = 1,
    int size = 10,
    String? address,
    List<String>? riskLevels,
  }) async {
    return safeCall(() async {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };

      if (query != null && query.isNotEmpty) {
        queryParams['query'] = query;
      }

      if (address != null && address.isNotEmpty) {
        queryParams['address'] = address;
      }

      if (riskLevels != null && riskLevels.isNotEmpty) {
        queryParams['riskLevels'] = riskLevels.join(',');
      }

      AppLogger.api('GET', ApiConstants.buildings, queryParams);

      final response = await _dioClient.dio.get(
        ApiConstants.buildings,
        queryParameters: queryParams,
      );

      return _parseBuildingList(response.data);
    });
  }

  @override
  Future<Building?> getBuildingById(int id) async {
    return safeCall(() async {
      AppLogger.api('GET', '${ApiConstants.buildings}/$id');

      final response = await _dioClient.dio.get('${ApiConstants.buildings}/$id');

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final responseData = data['data'] as Map<String, dynamic>?;
        if (responseData == null) {
          throw const NotFoundException('建筑不存在');
        }
        return Building.fromJson(responseData);
      }

      throw const UnknownException('获取建筑详情响应格式错误');
    });
  }

  @override
  Future<Building> createBuilding(CreateBuildingRequest request) async {
    return safeCall(() async {
      AppLogger.api('POST', ApiConstants.buildings);

      final response = await _dioClient.dio.post(
        ApiConstants.buildings,
        data: request.toJson(),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final code = data['code'] as int?;
        final message = data['message'] as String?;
        final responseData = data['data'] as Map<String, dynamic>?;

        if (code != null && code != 0 && code != 200) {
          throw ValidationException(
            message ?? '创建建筑失败',
            statusCode: code,
          );
        }

        if (responseData == null) {
          throw const ValidationException('创建建筑响应数据为空');
        }

        return Building.fromJson(responseData);
      }

      throw const UnknownException('创建建筑响应格式错误');
    });
  }

  @override
  Future<Building> updateBuilding(int id, UpdateBuildingRequest request) async {
    return safeCall(() async {
      AppLogger.api('PUT', '${ApiConstants.buildings}/$id');

      final response = await _dioClient.dio.put(
        '${ApiConstants.buildings}/$id',
        data: request.toJson(),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final code = data['code'] as int?;
        final message = data['message'] as String?;
        final responseData = data['data'] as Map<String, dynamic>?;

        if (code != null && code != 0 && code != 200) {
          throw ValidationException(
            message ?? '更新建筑失败',
            statusCode: code,
          );
        }

        if (responseData == null) {
          throw const ValidationException('更新建筑响应数据为空');
        }

        return Building.fromJson(responseData);
      }

      throw const UnknownException('更新建筑响应格式错误');
    });
  }

  @override
  Future<void> deleteBuilding(int id) async {
    return safeCall(() async {
      AppLogger.api('DELETE', '${ApiConstants.buildings}/$id');

      final response = await _dioClient.dio.delete('${ApiConstants.buildings}/$id');

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final code = data['code'] as int?;
        final message = data['message'] as String?;

        if (code != null && code != 0 && code != 200) {
          throw ValidationException(
            message ?? '删除建筑失败',
            statusCode: code,
          );
        }
      }
    });
  }

  @override
  Future<List<Building>> searchBuildings(String query) async {
    return safeCall(() async {
      AppLogger.api('GET', ApiConstants.buildingsSearch, {'query': query});

      final response = await _dioClient.dio.get(
        ApiConstants.buildingsSearch,
        queryParameters: {'query': query},
      );

      return _parseBuildingList(response.data);
    });
  }

  List<Building> _parseBuildingList(dynamic data) {
    if (data is Map<String, dynamic>) {
      final innerData = data['data'];
      if (innerData is Map && innerData.containsKey('records')) {
        return (innerData['records'] as List)
            .map((e) => Building.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (innerData is List) {
        return innerData
            .map((e) => Building.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } else if (data is List) {
      return data.map((e) => Building.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
