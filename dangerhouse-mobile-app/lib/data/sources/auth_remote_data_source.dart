import 'package:dio/dio.dart';

import '../../core/auth/token_manager.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/auth_interceptor.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/auth_models.dart';
import 'base_data_source.dart';

abstract class AuthRemoteDataSource extends RemoteDataSource {
  Future<LoginResponse> login(String account, String password, {bool rememberMe = false});
  Future<RegisterResponse> register(RegisterRequest request);
  Future<Map<String, dynamic>> checkUsername(String username);
  Future<Map<String, dynamic>> checkPhone(String phone);
  Future<Map<String, dynamic>> getCurrentUser();
  Future<void> logout();
  Future<Map<String, dynamic>> updateUser(UpdateUserRequest request);
  Future<void> updatePassword(PasswordUpdateRequest request);
  Future<String?> uploadAvatar(List<int> bytes, String fileName);
}

class AuthRemoteDataSourceImpl extends AuthRemoteDataSource {
  final DioClient _dioClient;
  final TokenManager _tokenManager;

  AuthRemoteDataSourceImpl({
    required DioClient dioClient,
    TokenManager? tokenManager,
  })  : _dioClient = dioClient,
        _tokenManager = tokenManager ?? TokenManager.instance;

  @override
  Future<LoginResponse> login(String account, String password, {bool rememberMe = false}) async {
    return safeCall(() async {
      AppLogger.api('POST', ApiConstants.login);

      final request = LoginRequest(
        account: account,
        password: password,
        rememberMe: rememberMe,
        clientType: 'APP',
      );
      final response = await _dioClient.dio.post(
        ApiConstants.login,
        data: request.toJson(),
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const UnknownException('登录响应格式错误');
      }

      final code = data['code'] as int?;
      final message = data['message'] as String?;
      final responseData = data['data'] as Map<String, dynamic>?;

      if (code != null && code != 0 && code != 200) {
        throw ValidationException(
          message ?? '登录失败',
          statusCode: code,
        );
      }

      if (responseData == null) {
        throw const ValidationException('登录响应数据为空');
      }

      final loginResponse = LoginResponse.fromJson(responseData);
      if (loginResponse.token != null) {
        await _tokenManager.saveToken(
          token: loginResponse.token!,
          userId: loginResponse.id,
        );
      }

      return LoginResponse(
        success: true,
        message: message ?? '登录成功',
        token: loginResponse.token,
        id: loginResponse.id,
        username: loginResponse.username,
        phone: loginResponse.phone,
        email: loginResponse.email,
        roles: loginResponse.roles,
        nickname: loginResponse.nickname,
        avatar: loginResponse.avatar,
        admin: loginResponse.admin,
      );
    });
  }

  @override
  Future<RegisterResponse> register(RegisterRequest request) async {
    return safeCall(() async {
      AppLogger.api('POST', ApiConstants.register);

      final response = await _dioClient.dio.post(
        ApiConstants.register,
        data: request.toJson(),
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const UnknownException('注册响应格式错误');
      }

      final code = data['code'] as int?;
      final message = data['message'] as String?;
      final responseData = data['data'] as Map<String, dynamic>?;

      if (code != null && code != 0 && code != 200) {
        throw ValidationException(
          message ?? '注册失败',
          statusCode: code,
        );
      }

      if (responseData == null) {
        throw const ValidationException('注册响应数据为空');
      }

      return RegisterResponse.fromJson(responseData);
    });
  }

  @override
  Future<Map<String, dynamic>> checkUsername(String username) async {
    return safeCall(() async {
      final url = ApiConstants.checkUsername(username);
      AppLogger.api('GET', '$url?username=$username');

      final response = await _dioClient.dio.get(
        url,
        queryParameters: {'username': username},
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }

      throw const UnknownException('用户名校验响应格式错误');
    });
  }

  @override
  Future<Map<String, dynamic>> checkPhone(String phone) async {
    return safeCall(() async {
      final url = ApiConstants.checkPhone(phone);
      AppLogger.api('GET', '$url?phone=$phone');

      final response = await _dioClient.dio.get(
        url,
        queryParameters: {'phone': phone},
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }

      throw const UnknownException('手机号校验响应格式错误');
    });
  }

  @override
  Future<Map<String, dynamic>> getCurrentUser() async {
    return safeCall(() async {
      AppLogger.api('GET', ApiConstants.currentUser);

      final response = await _dioClient.dio.get(ApiConstants.currentUser);
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const UnknownException('获取用户信息响应格式错误');
      }

      final code = data['code'] as int?;
      final message = data['message'] as String?;
      final responseData = data['data'] as Map<String, dynamic>?;

      if (code != null && code != 0 && code != 200) {
        throw UnauthorizedException(
          message ?? '获取用户信息失败',
          statusCode: code,
        );
      }

      return responseData ?? {};
    });
  }

  @override
  Future<void> logout() async {
    return safeCall(() async {
      AuthInterceptor.beginManualLogout();
      try {
        final token = await _tokenManager.getToken();
        if (token != null && token.isNotEmpty) {
          final expired = await _tokenManager.isTokenExpired();
          if (expired) {
            return;
          }
          await _dioClient.dio.post(
            ApiConstants.logout,
            options: Options(
              extra: const {
                'skipUnauthorizedRedirect': true,
                'manualLogout': true,
              },
            ),
          );
        }
      } on DioException {
        // Keep logout best-effort so local cleanup always completes.
      } finally {
        await _tokenManager.clearToken();
        AuthInterceptor.endManualLogout();
      }
    });
  }

  @override
  Future<Map<String, dynamic>> updateUser(UpdateUserRequest request) async {
    return safeCall(() async {
      AppLogger.api('PUT', ApiConstants.updateUser);

      final response = await _dioClient.dio.put(
        ApiConstants.updateUser,
        data: request.toJson(),
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const UnknownException('更新用户信息响应格式错误');
      }

      final code = data['code'] as int?;
      final message = data['message'] as String?;
      final responseData = data['data'] as Map<String, dynamic>?;

      if (code != null && code != 0 && code != 200) {
        throw ValidationException(
          message ?? '更新用户信息失败',
          statusCode: code,
        );
      }

      return responseData ?? {};
    });
  }

  @override
  Future<void> updatePassword(PasswordUpdateRequest request) async {
    return safeCall(() async {
      AppLogger.api('PUT', ApiConstants.changePassword);

      final response = await _dioClient.dio.put(
        ApiConstants.changePassword,
        data: request.toJson(),
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const UnknownException('密码修改响应格式错误');
      }

      final code = data['code'] as int?;
      final message = data['message'] as String?;
      if (code != null && code != 0 && code != 200) {
        throw ValidationException(
          message ?? '密码修改失败',
          statusCode: code,
        );
      }
    });
  }

  @override
  Future<String?> uploadAvatar(List<int> bytes, String fileName) async {
    return safeCall(() async {
      AppLogger.api('POST', ApiConstants.uploadAvatar);

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final response = await _dioClient.dio.post(
        ApiConstants.uploadAvatar,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const UnknownException('上传头像响应格式错误');
      }

      final code = data['code'] as int?;
      final message = data['message'] as String?;
      if (code != null && code != 0 && code != 200) {
        throw ValidationException(
          message ?? '上传头像失败',
          statusCode: code,
        );
      }

      final avatarPath = data['data'];
      return avatarPath is String ? avatarPath : null;
    });
  }
}
