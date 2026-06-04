import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';
import 'auth_interceptor.dart';
import '../auth/token_manager.dart';

/// HTTP网络请求客户端
///
/// 基于 [Dio] 封装的HTTP客户端，提供统一的网络请求处理。
/// 支持自动Token注入、错误处理、日志记录和CORS配置。
///
/// 特性:
/// - 自动添加认证Token
/// - 统一错误处理
/// - 请求/响应日志记录
/// - Web端CORS支持
/// - 文件上传支持
///
/// 示例:
/// ```dart
/// final client = DioClient();
/// final response = await client.get('/api/users');
/// ```
class DioClient {
  late Dio _dio;
  final TokenManager _tokenManager;

  /// 创建HTTP客户端实例
  ///
  /// [tokenManager] Token管理器，默认使用单例实例
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

  /// 获取底层Dio实例
  ///
  /// 用于需要直接使用Dio功能的场景。
  Dio get dio => _dio;

  /// 发送GET请求
  ///
  /// [path] 请求路径
  /// [queryParameters] 查询参数
  /// [options] 请求选项
  /// [cancelToken] 取消令牌
  ///
  /// 返回响应数据。
  ///
  /// 示例:
  /// ```dart
  /// final response = await client.get('/api/users', queryParameters: {'page': 1});
  /// ```
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

  /// 发送POST请求
  ///
  /// [path] 请求路径
  /// [data] 请求体数据
  /// [queryParameters] 查询参数
  /// [options] 请求选项
  /// [cancelToken] 取消令牌
  ///
  /// 返回响应数据。
  ///
  /// 示例:
  /// ```dart
  /// final response = await client.post('/api/users', data: {'name': 'John'});
  /// ```
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

  /// 发送PUT请求
  ///
  /// [path] 请求路径
  /// [data] 请求体数据
  /// [queryParameters] 查询参数
  /// [options] 请求选项
  /// [cancelToken] 取消令牌
  ///
  /// 返回响应数据。
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

  /// 发送DELETE请求
  ///
  /// [path] 请求路径
  /// [data] 请求体数据
  /// [queryParameters] 查询参数
  /// [options] 请求选项
  /// [cancelToken] 取消令牌
  ///
  /// 返回响应数据。
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

  /// 上传文件
  ///
  /// [path] 请求路径
  /// [formData] 表单数据
  /// [options] 请求选项
  /// [cancelToken] 取消令牌
  /// [onSendProgress] 上传进度回调
  ///
  /// 返回响应数据。
  ///
  /// 示例:
  /// ```dart
  /// final formData = FormData.fromMap({
  ///   'file': await MultipartFile.fromFile('/path/to/file.jpg'),
  /// });
  /// final response = await client.upload('/api/upload', formData: formData);
  /// ```
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

  /// 解析响应数据为单个对象
  ///
  /// 从响应中提取数据并使用提供的工厂函数转换为对象。
  /// 支持嵌套的 `data` 字段结构。
  ///
  /// [response] HTTP响应
  /// [fromJson] JSON转对象的工厂函数
  ///
  /// 返回解析后的对象，如果数据为空则返回null。
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

  /// 解析响应数据为列表
  ///
  /// 从响应中提取数据并转换为对象列表。
  /// 支持分页结构（`data.records`）和普通列表结构。
  ///
  /// [response] HTTP响应
  /// [fromJson] JSON转对象的工厂函数
  ///
  /// 返回解析后的对象列表。
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

  /// 检查响应是否成功
  ///
  /// 根据响应状态码和业务码判断请求是否成功。
  ///
  /// [response] HTTP响应
  ///
  /// 返回true表示成功。
  bool isSuccessResponse(Response response) {
    final data = response.data;
    if (data is Map) {
      final code = data['code'];
      return code == 0 || code == 200;
    }
    return response.statusCode == 200;
  }

  /// 获取错误消息
  ///
  /// 从响应中提取错误消息。
  ///
  /// [response] HTTP响应
  ///
  /// 返回错误消息，如果没有则返回null。
  String? getErrorMessage(Response response) {
    final data = response.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return null;
  }
}
