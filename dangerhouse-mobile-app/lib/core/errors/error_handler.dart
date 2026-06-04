import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'exceptions.dart';
import '../utils/app_logger.dart';
import '../utils/service_error_message.dart';

/// 错误处理工具类
///
/// 提供统一的错误处理、转换和显示功能。
/// 支持将各种异常类型转换为 [AppException]，并提供便捷的错误显示方法。
///
/// 示例:
/// ```dart
/// try {
///   await apiCall();
/// } catch (e) {
///   ErrorHandler.handleError(e, context: '获取用户信息');
/// }
/// ```
class ErrorHandler {
  ErrorHandler._();

  static bool _enableToast = true;

  static void setEnableToast(bool enable) {
    _enableToast = enable;
  }

  /// 获取错误消息
  ///
  /// 从各种错误类型中提取用户友好的错误消息。
  ///
  /// [error] 错误对象
  /// [defaultMsg] 默认错误消息
  ///
  /// 返回格式化的错误消息字符串。
  static String getErrorMessage(dynamic error, {String defaultMsg = '操作失败，请重试'}) {
    final normalized = _normalizeBusinessMessage(error, defaultMsg: defaultMsg);
    if (normalized != null) {
      return normalized;
    }
    if (error is AppException) {
      return error.message;
    }
    if (error is DioException) {
      return AppException.fromDioError(error).message;
    }
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return defaultMsg;
  }

  /// 将错误包装为 [AppException]
  ///
  /// 将任意错误类型转换为统一的 [AppException] 类型。
  ///
  /// [error] 原始错误对象
  /// [stackTrace] 堆栈跟踪（可选）
  ///
  /// 返回对应的 [AppException] 实例。
  static AppException wrap(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppException) {
      return error;
    }
    if (error is DioException) {
      return AppException.fromDioError(error, stackTrace: stackTrace);
    }
    return UnknownException(
      error?.toString() ?? '未知错误',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// 处理错误
  ///
  /// 统一处理错误，支持日志记录、Toast显示和未授权回调。
  ///
  /// [error] 错误对象
  /// [context] 错误上下文描述（用于日志）
  /// [showToast] 是否显示Toast提示，默认为true
  /// [logError] 是否记录错误日志，默认为true
  /// [onUnauthorized] 未授权时的回调函数
  static void handleError(
    dynamic error, {
    String? context,
    bool showToast = true,
    bool logError = true,
    VoidCallback? onUnauthorized,
  }) {
    final appException = wrap(error);

    if (logError) {
      if (context != null) {
        AppLogger.e('$context: ${appException.message}', error, 'ErrorHandler');
      } else {
        AppLogger.e(appException.message, error, 'ErrorHandler');
      }
    }

    if (error is UnauthorizedException && onUnauthorized != null) {
      onUnauthorized();
      return;
    }

    if (showToast && _enableToast) {
      EasyLoading.showError(
        _normalizeBusinessMessage(error, defaultMsg: appException.message) ??
            appException.message,
      );
    }
  }

  static String? _normalizeBusinessMessage(dynamic error, {required String defaultMsg}) {
    final raw = error?.toString();
    final lower = (raw ?? '').toLowerCase();
    if (lower.isEmpty) {
      return null;
    }
    if (_looksLikeReportContext(lower, defaultMsg)) {
      return ServiceErrorMessage.forReport(raw);
    }
    if (_looksLikeDetectionContext(lower, defaultMsg)) {
      return ServiceErrorMessage.forDetection(raw);
    }
    return null;
  }

  static bool _looksLikeDetectionContext(String raw, String defaultMsg) {
    final hint = defaultMsg.toLowerCase();
    return raw.contains('detect_damage') ||
        raw.contains('ai detection request failed') ||
        raw.contains('connection refused') ||
        raw.contains(':8000') ||
        hint.contains('检测') ||
        hint.contains('识别');
  }

  static bool _looksLikeReportContext(String raw, String defaultMsg) {
    final hint = defaultMsg.toLowerCase();
    return raw.contains('/api/reports') ||
        raw.contains('.pdf') ||
        hint.contains('报告') ||
        hint.contains('下载');
  }

  /// 处理API错误
  ///
  /// 专门用于处理API请求错误的便捷方法。
  ///
  /// [error] 错误对象
  /// [context] 错误上下文描述，默认为'API请求'
  /// [showToast] 是否显示Toast提示，默认为true
  /// [onUnauthorized] 未授权时的回调函数
  static void handleApiError(
    dynamic error, {
    String context = 'API请求',
    bool showToast = true,
    VoidCallback? onUnauthorized,
  }) {
    handleError(
      error,
      context: context,
      showToast: showToast,
      onUnauthorized: onUnauthorized,
    );
  }

  /// 检查是否为网络错误
  ///
  /// 判断错误是否为网络相关错误（超时、连接失败等）。
  ///
  /// [error] 错误对象
  ///
  /// 返回true表示是网络错误。
  static bool isNetworkError(dynamic error) {
    if (error is NetworkTimeoutException || error is NetworkConnectionException) {
      return true;
    }
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError;
    }
    return false;
  }

  /// 检查是否为未授权错误
  ///
  /// 判断错误是否为401未授权错误。
  ///
  /// [error] 错误对象
  ///
  /// 返回true表示是未授权错误。
  static bool isUnauthorized(dynamic error) {
    return error is UnauthorizedException ||
        (error is DioException && error.response?.statusCode == 401);
  }

  /// 检查是否为服务器错误
  ///
  /// 判断错误是否为5xx服务器错误。
  ///
  /// [error] 错误对象
  ///
  /// 返回true表示是服务器错误。
  static bool isServerError(dynamic error) {
    if (error is ServerException) return true;
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      return statusCode != null && statusCode >= 500;
    }
    return false;
  }

  /// 检查是否为客户端错误
  ///
  /// 判断错误是否为4xx客户端错误。
  ///
  /// [error] 错误对象
  ///
  /// 返回true表示是客户端错误。
  static bool isClientError(dynamic error) {
    if (error is ValidationException || error is NotFoundException || error is ForbiddenException) {
      return true;
    }
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      return statusCode != null && statusCode >= 400 && statusCode < 500;
    }
    return false;
  }
}

/// 结果类型
///
/// 用于表示操作成功或失败的封装类型，类似于Rust的Result类型。
/// 可以包含成功值 [T] 或错误 [AppException]。
///
/// 示例:
/// ```dart
/// Result<User> result = await fetchUser();
/// result.when(
///   success: (user) => print('用户: ${user.name}'),
///   failure: (error) => print('错误: ${error.message}'),
/// );
/// ```
class Result<T> {
  final T? _data;
  final AppException? _error;
  final bool isSuccess;

  const Result._success(this._data)
      : _error = null,
        isSuccess = true;

  const Result._failure(this._error)
      : _data = null,
        isSuccess = false;

  /// 创建成功结果
  ///
  /// [data] 成功时包含的数据
  factory Result.success(T data) => Result._success(data);

  /// 创建失败结果
  ///
  /// [error] 失败时包含的错误
  factory Result.failure(AppException error) => Result._failure(error);

  /// 从值创建成功结果
  ///
  /// [value] 成功值
  factory Result.fromValue(T value) => Result._success(value);

  /// 从错误创建失败结果
  ///
  /// [error] 任意错误对象，会被包装为 [AppException]
  factory Result.fromError(dynamic error) => Result._failure(ErrorHandler.wrap(error));

  /// 获取成功数据
  ///
  /// 如果结果为失败状态，会抛出 [StateError]。
  T get data {
    if (!isSuccess || _error != null) {
      throw StateError('Cannot access data on a failed Result');
    }
    return _data as T;
  }

  /// 获取错误
  ///
  /// 如果结果为成功状态，会抛出 [StateError]。
  AppException get error {
    if (isSuccess) {
      throw StateError('Cannot access error on a successful Result');
    }
    final err = _error;
    if (err == null) {
      throw StateError('Error is null on a failed Result');
    }
    return err;
  }

  /// 模式匹配处理结果
  ///
  /// 根据结果状态调用对应的处理函数。
  ///
  /// [success] 成功时的处理函数
  /// [failure] 失败时的处理函数
  ///
  /// 返回处理函数的结果。
  R when<R>({
    required R Function(T data) success,
    required R Function(AppException error) failure,
  }) {
    if (isSuccess) {
      return success(_data as T);
    }
    final err = _error;
    if (err == null) {
      throw StateError('Result is in an invalid state');
    }
    return failure(err);
  }

  /// 可选的模式匹配处理
  ///
  /// 类似于 [when]，但处理函数为可选，提供默认处理。
  ///
  /// [success] 成功时的处理函数（可选）
  /// [failure] 失败时的处理函数（可选）
  /// [orElse] 默认处理函数
  R whenOrNull<R>({
    R Function(T data)? success,
    R Function(AppException error)? failure,
    required R Function() orElse,
  }) {
    if (isSuccess && success != null) {
      return success(_data as T);
    } else if (!isSuccess && failure != null) {
      final err = _error;
      if (err != null) {
        return failure(err);
      }
    }
    return orElse();
  }

  /// 获取数据或默认值
  ///
  /// 如果成功返回数据，否则返回默认值。
  ///
  /// [orElse] 默认值生成函数
  T getOrElse(T Function() orElse) {
    return isSuccess ? (_data as T) : orElse();
  }

  /// 获取数据或null
  ///
  /// 如果成功返回数据，否则返回null。
  T? getOrNull() => isSuccess ? _data : null;

  /// 获取错误或null
  ///
  /// 如果失败返回错误，否则返回null。
  AppException? getErrorOrNull() => isSuccess ? null : _error;

  /// 映射成功值
  ///
  /// 将成功值转换为另一种类型。
  ///
  /// [transform] 转换函数
  ///
  /// 返回新的 [Result] 实例。
  Result<R> map<R>(R Function(T data) transform) {
    if (isSuccess) {
      try {
        return Result.success(transform(_data as T));
      } catch (e) {
        return Result.failure(ErrorHandler.wrap(e));
      }
    }
    final err = _error;
    if (err == null) {
      throw StateError('Result is in an invalid state');
    }
    return Result.failure(err);
  }

  /// 扁平映射
  ///
  /// 将成功值转换为另一个 [Result]。
  ///
  /// [transform] 转换函数，返回新的 [Result]
  ///
  /// 返回转换后的 [Result]。
  Result<R> flatMap<R>(Result<R> Function(T data) transform) {
    if (isSuccess) {
      try {
        return transform(_data as T);
      } catch (e) {
        return Result.failure(ErrorHandler.wrap(e));
      }
    }
    final err = _error;
    if (err == null) {
      throw StateError('Result is in an invalid state');
    }
    return Result.failure(err);
  }

  /// 从错误中恢复
  ///
  /// 如果失败，使用恢复函数生成新值。
  ///
  /// [recover] 恢复函数，接收错误并返回新值
  ///
  /// 返回成功结果。
  Result<T> recover(T Function(AppException error) recover) {
    if (isSuccess) return this;
    final err = _error;
    if (err == null) {
      throw StateError('Result is in an invalid state');
    }
    return Result.success(recover(err));
  }

  /// 从错误中恢复（简化版）
  ///
  /// 如果失败，使用恢复函数生成新值。
  ///
  /// [recover] 恢复函数，返回新值
  ///
  /// 返回成功结果。
  Result<T> recoverFromError(T Function() recover) {
    if (isSuccess) return this;
    return Result.success(recover());
  }
}

/// [Future] 扩展，提供便捷的 [Result] 转换
extension ResultExtensions<T> on Future<T> {
  /// 将 [Future] 转换为 [Future<Result>]
  ///
  /// 自动捕获异常并转换为 [Result] 类型。
  ///
  /// 示例:
  /// ```dart
  /// final result = await apiCall().toResult();
  /// ```
  Future<Result<T>> toResult() async {
    try {
      final value = await this;
      return Result.success(value);
    } catch (e, st) {
      return Result.failure(ErrorHandler.wrap(e, st));
    }
  }
}
