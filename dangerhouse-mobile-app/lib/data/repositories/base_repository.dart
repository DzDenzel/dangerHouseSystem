import '../../core/errors/error_handler.dart';
import '../../core/errors/exceptions.dart';

/// 仓库基类：统一错误处理与结果封装
abstract class BaseRepository {
  const BaseRepository();

  /// 包装仓库操作，捕获异常并返回 [Result]
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

  /// 同 [safeCall]，但返回 null 时转为 [NotFoundException]
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
/// [T] 实体类型，[CreateRequest] 创建请求，[UpdateRequest] 更新请求。
abstract class CrudRepository<T, CreateRequest, UpdateRequest> extends BaseRepository {
  /// 分页从 1 开始
  Future<Result<List<T>>> getAll({int page = 1, int size = 10});

  Future<Result<T?>> getById(int id);

  Future<Result<T>> create(CreateRequest request);

  Future<Result<T>> update(int id, UpdateRequest request);

  Future<Result<void>> delete(int id);
}

/// 只读仓库接口，适用于不需要修改的数据
abstract class ReadOnlyRepository<T> extends BaseRepository {
  /// 分页从 1 开始
  Future<Result<List<T>>> getAll({int page = 1, int size = 10});

  Future<Result<T?>> getById(int id);
}
