import '../../core/auth/token_manager.dart';
import '../../core/errors/error_handler.dart';
import '../../core/errors/exceptions.dart';
import '../models/auth_models.dart';
import '../sources/auth_remote_data_source.dart';
import 'base_repository.dart';

abstract class AuthRepository extends BaseRepository {
  Future<LoginResponse> login(String account, String password, {bool rememberMe = false});
  Future<RegisterResponse> register(RegisterRequest request);
  Future<Map<String, dynamic>> checkUsername(String username);
  Future<Map<String, dynamic>> checkPhone(String phone);
  Future<Map<String, dynamic>> getCurrentUser();
  Future<void> logout();
  Future<Map<String, dynamic>> updateUser(UpdateUserRequest request);
  Future<void> updatePassword(PasswordUpdateRequest request);
  Future<bool> isLoggedIn();
  Future<LoginResponse> updateProfile(UpdateUserRequest request);
  Future<LoginResponse> getProfile();
  Future<String?> uploadAvatar(List<int> bytes, String fileName);
}

class AuthRepositoryImpl extends AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final TokenManager _tokenManager;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    TokenManager? tokenManager,
  })  : _remoteDataSource = remoteDataSource,
        _tokenManager = tokenManager ?? TokenManager.instance;

  @override
  Future<LoginResponse> login(String account, String password, {bool rememberMe = false}) async {
    try {
      return await _remoteDataSource.login(account, password, rememberMe: rememberMe);
    } on AppException catch (e) {
      return LoginResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      final errorMsg = ErrorHandler.getErrorMessage(e, defaultMsg: '登录失败，请重试');
      return LoginResponse(
        success: false,
        message: errorMsg,
      );
    }
  }

  @override
  Future<RegisterResponse> register(RegisterRequest request) async {
    return _remoteDataSource.register(request);
  }

  @override
  Future<Map<String, dynamic>> checkUsername(String username) async {
    return _remoteDataSource.checkUsername(username);
  }

  @override
  Future<Map<String, dynamic>> checkPhone(String phone) async {
    return _remoteDataSource.checkPhone(phone);
  }

  @override
  Future<Map<String, dynamic>> getCurrentUser() async {
    return _remoteDataSource.getCurrentUser();
  }

  @override
  Future<void> logout() async {
    await _remoteDataSource.logout();
  }

  @override
  Future<Map<String, dynamic>> updateUser(UpdateUserRequest request) async {
    return _remoteDataSource.updateUser(request);
  }

  @override
  Future<void> updatePassword(PasswordUpdateRequest request) async {
    await _remoteDataSource.updatePassword(request);
  }

  @override
  Future<bool> isLoggedIn() async {
    return _tokenManager.hasToken();
  }

  @override
  Future<LoginResponse> updateProfile(UpdateUserRequest request) async {
    try {
      final response = await _remoteDataSource.updateUser(request);
      return LoginResponse(
        success: true,
        message: '更新成功',
        id: response['id'] as int?,
        username: response['username'] as String?,
        phone: response['phone'] as String?,
        email: response['email'] as String?,
        nickname: response['nickname'] as String?,
        avatar: response['avatar'] as String?,
      );
    } on AppException catch (e) {
      return LoginResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      final errorMsg = ErrorHandler.getErrorMessage(e, defaultMsg: '更新失败，请重试');
      return LoginResponse(
        success: false,
        message: errorMsg,
      );
    }
  }

  @override
  Future<LoginResponse> getProfile() async {
    try {
      final response = await _remoteDataSource.getCurrentUser();
      final hasIdentity =
          response['id'] != null ||
          (response['username'] is String && (response['username'] as String).trim().isNotEmpty) ||
          (response['nickname'] is String && (response['nickname'] as String).trim().isNotEmpty);

      if (!hasIdentity) {
        return LoginResponse(
          success: false,
          message: '未获取到有效的用户信息',
        );
      }

      return LoginResponse(
        success: true,
        id: response['id'] as int?,
        username: response['username'] as String?,
        phone: response['phone'] as String?,
        email: response['email'] as String?,
        nickname: response['nickname'] as String?,
        avatar: response['avatar'] as String?,
        roles: (response['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      );
    } on AppException catch (e) {
      return LoginResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      final errorMsg = ErrorHandler.getErrorMessage(e, defaultMsg: '获取用户信息失败');
      return LoginResponse(
        success: false,
        message: errorMsg,
      );
    }
  }

  @override
  Future<String?> uploadAvatar(List<int> bytes, String fileName) async {
    try {
      return await _remoteDataSource.uploadAvatar(bytes, fileName);
    } catch (e) {
      ErrorHandler.handleError(e, context: '上传头像');
      return null;
    }
  }
}
