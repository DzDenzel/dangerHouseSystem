import 'package:dio/dio.dart';
import '../../core/errors/exceptions.dart';

abstract class BaseDataSource {
  const BaseDataSource();

  Future<T> safeCall<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    } catch (e) {
      throw UnknownException(
        '数据源操作失败: ${e.toString()}',
        originalError: e,
      );
    }
  }
}

/// 远程数据源基类，通常与 [DioClient] 配合使用
abstract class RemoteDataSource extends BaseDataSource {
  const RemoteDataSource();
}

/// 本地数据源基类（数据库、SharedPreferences 等）
abstract class LocalDataSource extends BaseDataSource {
  const LocalDataSource();

  /// 清除所有本地存储的数据，通常在用户登出时调用
  Future<void> clear();

  /// 初始化本地存储，如打开数据库连接等
  Future<void> init();
}
