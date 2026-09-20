import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'exceptions.dart';
import '../utils/app_logger.dart';
import '../utils/service_error_message.dart';

/// 错误处理工具类
///
/// 统一的错误转换与展示入口，所有异常在此归一到 [AppException]。
class ErrorHandler {
  ErrorHandler._();

  static bool _enableToast = true;

  static void setEnableToast(bool enable) {
    _enableToast = enable;
  }

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

  /// 将任意错误类型转换为统一的 [AppException]
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

  /// 统一处理错误：日志记录、Toast 提示和未授权回调
  ///
  /// [context] 仅用于日志前缀。
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

  static bool isUnauthorized(dynamic error) {
    return error is UnauthorizedException ||
        (error is DioException && error.response?.statusCode == 401);
  }

  static bool isServerError(dynamic error) {
    if (error is ServerException) return true;
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      return statusCode != null && statusCode >= 500;
    }
    return false;
  }

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

/// 结果类型：封装成功值 [T] 或错误 [AppException]
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

  factory Result.success(T data) => Result._success(data);

  factory Result.failure(AppException error) => Result._failure(error);

  factory Result.fromValue(T value) => Result._success(value);

  /// [error] 任意错误对象，会被包装为 [AppException]
  factory Result.fromError(dynamic error) => Result._failure(ErrorHandler.wrap(error));

  /// 失败状态下访问会抛出 [StateError]
  T get data {
    if (!isSuccess || _error != null) {
      throw StateError('Cannot access data on a failed Result');
    }
    return _data as T;
  }

  /// 成功状态下访问会抛出 [StateError]
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

  /// 与 [when] 相同，但各分支可选，未命中时走 [orElse]
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

  T getOrElse(T Function() orElse) {
    return isSuccess ? (_data as T) : orElse();
  }

  T? getOrNull() => isSuccess ? _data : null;

  AppException? getErrorOrNull() => isSuccess ? null : _error;

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

  /// 失败时用 [recover] 生成新值，返回成功结果
  Result<T> recover(T Function(AppException error) recover) {
    if (isSuccess) return this;
    final err = _error;
    if (err == null) {
      throw StateError('Result is in an invalid state');
    }
    return Result.success(recover(err));
  }

  Result<T> recoverFromError(T Function() recover) {
    if (isSuccess) return this;
    return Result.success(recover());
  }
}

/// [Future] 扩展：捕获异常并转为 [Result]
extension ResultExtensions<T> on Future<T> {
  Future<Result<T>> toResult() async {
    try {
      final value = await this;
      return Result.success(value);
    } catch (e, st) {
      return Result.failure(ErrorHandler.wrap(e, st));
    }
  }
}
