import '../../core/errors/error_handler.dart';
import '../../core/errors/exceptions.dart';

/// 仓库基类
///
/// 所有仓库的抽象基类，提供统一的错误处理和结果封装。
/// 仓库负责协调数据源，为上层提供统一的数据访问接口。
///
/// 特性:
/// - 自动错误处理
/// - 结果封装为 [Result] 类型
/// - 支持可空值处理
///
/// 示例:
/// ```dart
/// class UserRepository extends BaseRepository {
///   final UserRemoteDataSource _remote;
///   final UserLocalDataSource _local;
///
///   Future<Result<User>> getUser(int id) {
///     return safeCall(() => _remote.getUser(id));
///   }
/// }
/// ```
abstract class BaseRepository {
  const BaseRepository();

  /// 安全调用
  ///
  /// 包装仓库操作，自动捕获异常并返回 [Result] 类型。
  ///
  /// [call] 要执行的数据操作
  ///
  /// 返回 [Result.success] 或 [Result.failure]。
  ///
  /// 示例:
  /// ```dart
  /// final result = await safeCall(() => _dataSource.getData());
  /// result.when(
  ///   success: (data) => print(data),
  ///   failure: (error) => print(error.message),
  /// );
  /// ```
  Future<Result<T>> safeCall<T>(Future<T> Function() call) async {
    try {
      final data = await call();
      return Result.success(data);
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e, st) {
      return Result.failure(ErrorHandler.wrap(e, st));
    }
  }

  /// 安全调用（可空值）
  ///
  /// 类似于 [safeCall]，但处理可空返回值。
  /// 当返回null时，自动转换为 [NotFoundException]。
  ///
  /// [call] 要执行的数据操作
  ///
  /// 返回 [Result.success] 或 [Result.failure]。
  Future<Result<T>> safeCallNullable<T>(Future<T?> Function() call) async {
    try {
      final data = await call();
      if (data == null) {
        return Result.failure(const NotFoundException('数据不存在'));
      }
      return Result.success(data);
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e, st) {
      return Result.failure(ErrorHandler.wrap(e, st));
    }
  }
}

/// CRUD仓库接口
///
/// 提供标准CRUD操作的仓库接口。
///
/// 类型参数:
/// - [T] 实体类型
/// - [CreateRequest] 创建请求类型
/// - [UpdateRequest] 更新请求类型
///
/// 示例:
/// ```dart
/// class BuildingRepository extends CrudRepository<Building, CreateBuildingRequest, UpdateBuildingRequest> {
///   @override
///   Future<Result<List<Building>>> getAll({int page = 1, int size = 10}) {
///     return safeCall(() => _dataSource.getBuildings(page: page, size: size));
///   }
///
///   // ... 实现其他方法
/// }
/// ```
abstract class CrudRepository<T, CreateRequest, UpdateRequest> extends BaseRepository {
  /// 获取所有实体
  ///
  /// [page] 页码，从1开始
  /// [size] 每页数量
  ///
  /// 返回实体列表。
  Future<Result<List<T>>> getAll({int page = 1, int size = 10});

  /// 根据ID获取实体
  ///
  /// [id] 实体ID
  ///
  /// 返回实体，不存在时返回null。
  Future<Result<T?>> getById(int id);

  /// 创建实体
  ///
  /// [request] 创建请求
  ///
  /// 返回创建的实体。
  Future<Result<T>> create(CreateRequest request);

  /// 更新实体
  ///
  /// [id] 实体ID
  /// [request] 更新请求
  ///
  /// 返回更新后的实体。
  Future<Result<T>> update(int id, UpdateRequest request);

  /// 删除实体
  ///
  /// [id] 实体ID
  ///
  /// 返回操作结果。
  Future<Result<void>> delete(int id);
}

/// 只读仓库接口
///
/// 提供只读操作的仓库接口，适用于不需要修改的数据。
///
/// 类型参数:
/// - [T] 实体类型
///
/// 示例:
/// ```dart
/// class ConfigRepository extends ReadOnlyRepository<AppConfig> {
///   @override
///   Future<Result<List<AppConfig>>> getAll({int page = 1, int size = 10}) {
///     return safeCall(() => _dataSource.getConfigs());
///   }
///
///   @override
///   Future<Result<AppConfig?>> getById(int id) {
///     return safeCallNullable(() => _dataSource.getConfig(id));
///   }
/// }
/// ```
abstract class ReadOnlyRepository<T> extends BaseRepository {
  /// 获取所有实体
  ///
  /// [page] 页码，从1开始
  /// [size] 每页数量
  ///
  /// 返回实体列表。
  Future<Result<List<T>>> getAll({int page = 1, int size = 10});

  /// 根据ID获取实体
  ///
  /// [id] 实体ID
  ///
  /// 返回实体，不存在时返回null。
  Future<Result<T?>> getById(int id);
}
