import 'package:dio/dio.dart';

/// 应用程序异常基类
///
/// 所有应用程序异常都继承自此类，提供统一的异常处理接口。
/// 支持从 [DioException] 自动转换为对应的异常类型。
///
/// 示例:
/// ```dart
/// try {
///   await dio.get('/api/data');
/// } on DioException catch (e) {
///   throw AppException.fromDioError(e);
/// }
/// ```
abstract class AppException implements Exception {
  /// 异常消息
  final String message;

  /// HTTP状态码
  final int? statusCode;

  /// 原始错误对象
  final dynamic originalError;

  /// 堆栈跟踪
  final StackTrace? stackTrace;

  /// 创建应用异常
  ///
  /// [message] 异常消息
  /// [statusCode] HTTP状态码（可选）
  /// [originalError] 原始错误对象（可选）
  /// [stackTrace] 堆栈跟踪（可选）
  const AppException(
    this.message, {
    this.statusCode,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => message;

  /// 从 [DioException] 创建对应的异常类型
  ///
  /// 根据错误类型自动映射到适当的异常子类：
  /// - 超时错误 -> [NetworkTimeoutException]
  /// - 连接错误 -> [NetworkConnectionException]
  /// - 401错误 -> [UnauthorizedException]
  /// - 403错误 -> [ForbiddenException]
  /// - 404错误 -> [NotFoundException]
  /// - 400错误 -> [ValidationException]
  /// - 429错误 -> [RateLimitException]
  /// - 5xx错误 -> [ServerException]
  static AppException fromDioError(DioException e, {StackTrace? stackTrace}) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkTimeoutException(
          '网络连接超时，请检查网络后重试',
          originalError: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.connectionError:
        return NetworkConnectionException(
          '网络连接失败，请检查网络或服务器是否正常运行',
          originalError: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.badResponse:
        return _handleResponseError(e, stackTrace);
      case DioExceptionType.cancel:
        return RequestCancelledException(
          '请求已取消',
          originalError: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.badCertificate:
        return ServerException(
          '证书验证失败',
          originalError: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.unknown:
        if (e.message?.contains('XMLHttpRequest') ?? false) {
          return CorsException(
            '跨域请求失败，请检查后端CORS配置',
            originalError: e,
            stackTrace: stackTrace,
          );
        }
        return UnknownException(
          '操作失败，请重试',
          originalError: e,
          stackTrace: stackTrace,
        );
    }
  }

  static AppException _handleResponseError(DioException e, StackTrace? stackTrace) {
    final response = e.response;
    final statusCode = response?.statusCode;
    final data = response?.data;

    String message = _getDefaultMessageForStatus(statusCode);
    
    if (data is Map && data['message'] != null) {
      final serverMessage = data['message'].toString();
      if (serverMessage.isNotEmpty && serverMessage != 'Unauthorized') {
        message = serverMessage;
      }
    }

    switch (statusCode) {
      case 400:
        return ValidationException(message, statusCode: statusCode, originalError: e, stackTrace: stackTrace);
      case 401:
        return UnauthorizedException(message, statusCode: statusCode, originalError: e, stackTrace: stackTrace);
      case 403:
        return ForbiddenException(message, statusCode: statusCode, originalError: e, stackTrace: stackTrace);
      case 404:
        return NotFoundException(message, statusCode: statusCode, originalError: e, stackTrace: stackTrace);
      case 429:
        return RateLimitException(message, statusCode: statusCode, originalError: e, stackTrace: stackTrace);
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(message, statusCode: statusCode, originalError: e, stackTrace: stackTrace);
      default:
        return ServerException(message, statusCode: statusCode, originalError: e, stackTrace: stackTrace);
    }
  }

  static String _getDefaultMessageForStatus(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '请求参数错误';
      case 401:
        return '登录已过期，请重新登录';
      case 403:
        return '无权限访问';
      case 404:
        return '请求的资源不存在';
      case 429:
        return '请求过于频繁，请稍后重试';
      case 500:
        return '服务器内部错误';
      case 502:
        return '网关错误';
      case 503:
        return '服务暂时不可用';
      case 504:
        return '网关超时';
      default:
        return '请求失败 ($statusCode)';
    }
  }
}

/// 网络超时异常
///
/// 当网络请求超时时抛出，包括连接超时、发送超时和接收超时。
class NetworkTimeoutException extends AppException {
  const NetworkTimeoutException(String message, {int? statusCode, dynamic originalError, StackTrace? stackTrace})
      : super(message, statusCode: statusCode, originalError: originalError, stackTrace: stackTrace);
}

/// 网络连接异常
///
/// 当无法建立网络连接时抛出，通常是由于网络不可用或服务器无法访问。
class NetworkConnectionException extends AppException {
  const NetworkConnectionException(String message, {int? statusCode, dynamic originalError, StackTrace? stackTrace})
      : super(message, statusCode: statusCode, originalError: originalError, stackTrace: stackTrace);
}

/// 服务器异常
///
/// 当服务器返回5xx错误或发生服务器端错误时抛出。
class ServerException extends AppException {
  const ServerException(String message, {int? statusCode, dynamic originalError, StackTrace? stackTrace})
      : super(message, statusCode: statusCode, originalError: originalError, stackTrace: stackTrace);
}

/// 未授权异常
///
/// 当用户未登录或登录已过期时抛出（HTTP 401）。
///
/// 通常需要引导用户重新登录。
class UnauthorizedException extends AppException {
  const UnauthorizedException(String message, {int? statusCode, dynamic originalError, StackTrace? stackTrace})
      : super(message, statusCode: statusCode, originalError: originalError, stackTrace: stackTrace);

  const UnauthorizedException.defaultMessage({int? statusCode, dynamic originalError, StackTrace? stackTrace})
      : super('登录已过期，请重新登录', statusCode: statusCode, originalError: originalError, stackTrace: stackTrace);
}

/// 禁止访问异常
///
/// 当用户没有权限访问资源时抛出（HTTP 403）。
class ForbiddenException extends AppException {
  const ForbiddenException(String message, {int? statusCode, dynamic originalError, StackTrace? stackTrace})
      : super(message, statusCode: statusCode, originalError: originalError, stackTrace: stackTrace);
}

/// 资源不存在异常
///
/// 当请求的资源不存在时抛出（HTTP 404）。
class NotFoundException extends AppException {
  const NotFoundException(String message, {int? statusCode, dynamic originalError, StackTrace? stackTrace})
      : super(message, statusCode: statusCode, originalError: originalError, stackTrace: stackTrace);

  const NotFoundException.defaultMessage({int? statusCode, dynamic originalError, StackTrace? stackTrace})
      : super('请求的资源不存在', statusCode: statusCode, originalError: originalError, stackTrace: stackTrace);
}

/// 验证异常
///
/// 当请求参数验证失败时抛出（HTTP 400）。
class ValidationException extends AppException {
  const ValidationException(String message, {int? statusCode, dynamic originalError, StackTrace? stackTrace})
      : super(message, statusCode: statusCode, originalError: originalError, stackTrace: stackTrace);
}

/// 请求取消异常
///
/// 当请求被主动取消时抛出。
class RequestCancelledException extends AppException {
  const RequestCancelledException(String message, {int? statusCode, dynamic originalError, StackTrace? stackTrace})
      : super(message, statusCode: statusCode, originalError: originalError, stackTrace: stackTrace);
}

/// 请求频率限制异常
///
/// 当请求过于频繁被服务器限制时抛出（HTTP 429）。
class RateLimitException extends AppException {
  const RateLimitException(String message, {int? statusCode, dynamic originalError, StackTrace? stackTrace})
      : super(message, statusCode: statusCode, originalError: originalError, stackTrace: stackTrace);
}

/// 跨域请求异常
///
/// 当Web端跨域请求失败时抛出，通常需要后端配置CORS。
class CorsException extends AppException {
  const CorsException(String message, {int? statusCode, dynamic originalError, StackTrace? stackTrace})
      : super(message, statusCode: statusCode, originalError: originalError, stackTrace: stackTrace);
}

/// 未知异常
///
/// 当无法确定具体错误类型时抛出。
class UnknownException extends AppException {
  const UnknownException(String message, {int? statusCode, dynamic originalError, StackTrace? stackTrace})
      : super(message, statusCode: statusCode, originalError: originalError, stackTrace: stackTrace);
}

/// 缓存异常
///
/// 当本地缓存操作失败时抛出。
class CacheException extends AppException {
  const CacheException(String message, {int? statusCode, dynamic originalError, StackTrace? stackTrace})
      : super(message, statusCode: statusCode, originalError: originalError, stackTrace: stackTrace);
}

/// 解析异常
///
/// 当数据解析失败时抛出，如JSON解析错误。
class ParseException extends AppException {
  const ParseException(String message, {int? statusCode, dynamic originalError, StackTrace? stackTrace})
      : super(message, statusCode: statusCode, originalError: originalError, stackTrace: stackTrace);
}
