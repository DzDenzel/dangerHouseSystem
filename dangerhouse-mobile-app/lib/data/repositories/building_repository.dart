import '../sources/building_remote_data_source.dart';
import '../../core/errors/error_handler.dart';
import '../models/building_models.dart';
import 'base_repository.dart';

abstract class BuildingRepository extends BaseRepository {
  Future<List<Building>> getBuildings({
    String? query,
    int page,
    int size,
    String? address,
    List<String>? riskLevels,
  });

  Future<Building?> getBuildingById(int id);
  Future<Building?> createBuilding(CreateBuildingRequest request);
  Future<Building?> updateBuilding(int id, UpdateBuildingRequest request);
  Future<bool> deleteBuilding(int id);
  Future<List<Building>> searchBuildings(String query);
}

class BuildingRepositoryImpl extends BuildingRepository {
  final BuildingRemoteDataSource _remoteDataSource;

  BuildingRepositoryImpl({required BuildingRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<Building>> getBuildings({
    String? query,
    int page = 1,
    int size = 10,
    String? address,
    List<String>? riskLevels,
  }) async {
    try {
      return await _remoteDataSource.getBuildings(
        query: query,
        page: page,
        size: size,
        address: address,
        riskLevels: riskLevels,
      );
    } catch (e) {
      ErrorHandler.handleError(e, context: '获取建筑列表');
      return [];
    }
  }

  @override
  Future<Building?> getBuildingById(int id) async {
    try {
      return await _remoteDataSource.getBuildingById(id);
    } catch (e) {
      ErrorHandler.handleError(e, context: '获取建筑详情');
      return null;
    }
  }

  @override
  Future<Building?> createBuilding(CreateBuildingRequest request) async {
    try {
      return await _remoteDataSource.createBuilding(request);
    } catch (e) {
      ErrorHandler.handleError(e, context: '创建建筑');
      return null;
    }
  }

  @override
  Future<Building?> updateBuilding(int id, UpdateBuildingRequest request) async {
    try {
      return await _remoteDataSource.updateBuilding(id, request);
    } catch (e) {
      ErrorHandler.handleError(e, context: '更新建筑');
      return null;
    }
  }

  @override
  Future<bool> deleteBuilding(int id) async {
    try {
      await _remoteDataSource.deleteBuilding(id);
      return true;
    } catch (e) {
      ErrorHandler.handleError(e, context: '删除建筑');
      return false;
    }
  }

  @override
  Future<List<Building>> searchBuildings(String query) async {
    try {
      return await _remoteDataSource.searchBuildings(query);
    } catch (e) {
      ErrorHandler.handleError(e, context: '搜索建筑');
      return [];
    }
  }
}
