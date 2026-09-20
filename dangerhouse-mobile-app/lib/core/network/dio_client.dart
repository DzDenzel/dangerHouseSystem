import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';
import 'auth_interceptor.dart';
import '../auth/token_manager.dart';

/// 基于 [Dio] 封装的HTTP客户端
///
/// 请求链路上挂载日志、认证（Token 注入）和 Web 端 CORS 拦截器。
class DioClient {
  late Dio _dio;
  final TokenManager _tokenManager;

  DioClient({TokenManager? tokenManager})
      : _tokenManager = tokenManager ?? TokenManager.instance {
    _dio = Dio(_createBaseOptions());
    _configureInterceptors();
  }

  BaseOptions _createBaseOptions() {
    return BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
      contentType: 'application/json',
      headers: _getDefaultHeaders(),
      extra: {'withCredentials': false},
    );
  }

  Map<String, dynamic> _getDefaultHeaders() {
    final headers = <String, dynamic>{
      'Accept': 'application/json',
    };
    if (kIsWeb) {
      headers.addAll({
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
      });
    }
    return headers;
  }

  void _configureInterceptors() {
    _dio.interceptors.addAll([
      _createLoggingInterceptor(),
      AuthInterceptor(_tokenManager),
      if (kIsWeb) _createCorsInterceptor(),
    ]);
  }

  Interceptor _createLoggingInterceptor() {
    return LogInterceptor(
      requestBody: kDebugMode,
      responseBody: kDebugMode,
      error: true,
      requestHeader: false,
      responseHeader: false,
    );
  }

  Interceptor _createCorsInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (kIsWeb) {
          options.headers['Access-Control-Allow-Origin'] = '*';
          options.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS';
          options.headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Authorization';
        }
        return handler.next(options);
      },
    );
  }

  /// 底层 [Dio] 实例，供需要直接使用 Dio 功能的场景
  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e, st) {
      throw AppException.fromDioError(e, stackTrace: st);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e, st) {
      throw AppException.fromDioError(e, stackTrace: st);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e, st) {
      throw AppException.fromDioError(e, stackTrace: st);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e, st) {
      throw AppException.fromDioError(e, stackTrace: st);
    }
  }

  /// 以 multipart/form-data 上传文件
  Future<Response<T>> upload<T>(
    String path, {
    required FormData formData,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: formData,
        options: (options ?? Options()).copyWith(
          contentType: 'multipart/form-data',
        ),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e, st) {
      throw AppException.fromDioError(e, stackTrace: st);
    }
  }

  /// 解析响应为单个对象，兼容外层 `data` 字段嵌套
  T? parseResponseData<T>(Response response, T Function(Map<String, dynamic>) fromJson) {
    final data = response.data;
    if (data == null) return null;

    if (data is Map<String, dynamic>) {
      if (data.containsKey('data')) {
        final innerData = data['data'];
        if (innerData is Map<String, dynamic>) {
          return fromJson(innerData);
        }
      }
      return fromJson(data);
    }
    return null;
  }

  /// 解析响应为对象列表，兼容分页结构（`data.records`）和裸列表结构
  List<T> parseResponseList<T>(Response response, T Function(Map<String, dynamic>) fromJson) {
    final data = response.data;
    if (data == null) return [];

    if (data is Map && data.containsKey('data')) {
      final innerData = data['data'];
      if (innerData is Map && innerData.containsKey('records')) {
        return (innerData['records'] as List)
            .map((e) => fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (innerData is List) {
        return innerData
            .map((e) => fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } else if (data is List) {
      return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 业务码 0/200 视为成功，无业务码时回退到 HTTP 状态码
  bool isSuccessResponse(Response response) {
    final data = response.data;
    if (data is Map) {
      final code = data['code'];
      return code == 0 || code == 200;
    }
    return response.statusCode == 200;
  }

  String? getErrorMessage(Response response) {
    final data = response.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return null;
  }
}
