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

/// 远程数据源
///
/// 用于网络API请求的数据源基类。
/// 通常与 [DioClient] 配合使用。
///
/// 示例:
/// ```dart
/// class UserRemoteDataSource extends RemoteDataSource {
///   final DioClient _client;
///
///   Future<User> getUser(int id) {
///     return safeCall(() async {
///       final response = await _client.get('/users/$id');
///       return User.fromJson(response.data);
///     });
///   }
/// }
/// ```
abstract class RemoteDataSource extends BaseDataSource {
  const RemoteDataSource();
}

/// 本地数据源
///
/// 用于本地存储（数据库、SharedPreferences等）的数据源基类。
/// 需要实现初始化和清理方法。
///
/// 示例:
/// ```dart
/// class UserLocalDataSource extends LocalDataSource {
///   final SharedPreferences _prefs;
///
///   @override
///   Future<void> init() async {
///     // 初始化本地存储
///   }
///
///   @override
///   Future<void> clear() async {
///     await _prefs.clear();
///   }
/// }
/// ```
abstract class LocalDataSource extends BaseDataSource {
  const LocalDataSource();

  /// 清理本地数据
  ///
  /// 清除所有本地存储的数据，通常在用户登出时调用。
  Future<void> clear();

  /// 初始化本地数据源
  ///
  /// 初始化本地存储，如打开数据库连接等。
  Future<void> init();
}
