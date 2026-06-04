import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/network_providers.dart';
import '../core/state/base_state.dart';
import '../core/utils/permission_util.dart';
import '../data/models/auth_models.dart';
import '../data/repositories/auth_repository.dart';

class AuthNotifier extends StateNotifier<SimpleState<LoginResponse>> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const SimpleState.initial()) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final loggedIn = await _authRepository.isLoggedIn();
      if (!loggedIn) {
        state = const SimpleState.initial();
        return;
      }
      if (state.hasData || state.isLoading) return;

      final profile = await _authRepository.getProfile();
      if (_isValidProfile(profile) && PermissionUtil.canLoginApp(profile)) {
        state = SimpleState.data(profile);
      } else {
        await _authRepository.logout();
        state = const SimpleState.initial();
      }
    } catch (_) {
      state = const SimpleState.initial();
    }
  }

  Future<bool> login(String account, String password, {bool rememberMe = false}) async {
    state = const SimpleState.loading();

    try {
      final response = await _authRepository.login(account, password, rememberMe: rememberMe);

      if (response.success) {
        if (!PermissionUtil.canLoginApp(response)) {
          await _authRepository.logout();
          state = SimpleState.error('当前账号不允许登录 App，请联系管理员');
          return false;
        }
        state = SimpleState.data(response);
        return true;
      } else {
        state = SimpleState.error(response.message ?? '登录失败');
        return false;
      }
    } catch (e) {
      state = SimpleState.error(_resolveErrorMessage(e, fallback: '登录失败，请稍后重试'));
      return false;
    }
  }

  Future<bool> register(RegisterRequest request) async {
    state = const SimpleState.loading();

    try {
      final response = await _authRepository.register(request);

      if (response.id > 0) {
        state = SimpleState.data(
          LoginResponse(
            success: true,
            id: response.id,
            username: response.username,
            message: '注册成功',
          ),
        );
        return true;
      } else {
        state = SimpleState.error(response.message ?? '注册失败');
        return false;
      }
    } catch (e) {
      state = SimpleState.error(_resolveErrorMessage(e, fallback: '注册失败，请稍后重试'));
      return false;
    }
  }

  Future<bool> updateProfile(UpdateUserRequest request) async {
    state = const SimpleState.loading();

    try {
      final response = await _authRepository.updateProfile(request);

      if (response.success) {
        final updatedProfile = await _authRepository.getProfile();
        if (updatedProfile.success) {
          state = SimpleState.data(updatedProfile);
        }
        return true;
      } else {
        state = SimpleState.error(response.message ?? '更新失败');
        return false;
      }
    } catch (e) {
      state = SimpleState.error(_resolveErrorMessage(e, fallback: '更新失败，请稍后重试'));
      return false;
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    state = const SimpleState.loading();

    try {
      await _authRepository.updatePassword(
        PasswordUpdateRequest(
          oldPassword: oldPassword,
          newPassword: newPassword,
        ),
      );
      final profile = await _authRepository.getProfile();
      if (_isValidProfile(profile)) {
        state = SimpleState.data(profile);
      } else {
        state = const SimpleState.initial();
      }
      return true;
    } catch (e) {
      state = SimpleState.error(_resolveErrorMessage(e, fallback: '密码修改失败，请稍后重试'));
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = const SimpleState.initial();
  }

  Future<void> handleSessionExpired() async {
    await _authRepository.logout();
    state = const SimpleState.initial();
  }

  Future<void> refreshUserInfo() async {
    try {
      final loggedIn = await _authRepository.isLoggedIn();
      if (!loggedIn) {
        state = const SimpleState.initial();
        return;
      }
      final profile = await _authRepository.getProfile();
      if (_isValidProfile(profile) && PermissionUtil.canLoginApp(profile)) {
        state = SimpleState.data(profile);
      } else {
        await _authRepository.logout();
        state = const SimpleState.initial();
      }
    } catch (_) {
      state = const SimpleState.initial();
    }
  }

  bool _isValidProfile(LoginResponse profile) {
    return profile.success &&
        (profile.id != null ||
            (profile.username?.trim().isNotEmpty ?? false) ||
            (profile.nickname?.trim().isNotEmpty ?? false));
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _resolveErrorMessage(Object error, {required String fallback}) {
    final raw = error.toString().trim();
    if (raw.isEmpty) return fallback;
    return raw
        .replaceFirst('Exception: ', '')
        .replaceFirst('ValidationException: ', '')
        .replaceFirst('UnauthorizedException: ', '')
        .replaceFirst('ServerException: ', '')
        .trim();
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, SimpleState<LoginResponse>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});

final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.hasData;
});

final currentUserProvider = Provider<LoginResponse?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.data;
});

final authLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.error;
});
