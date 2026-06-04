import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../main.dart';
import '../auth/token_manager.dart';
import '../errors/exceptions.dart';
import '../../providers/auth_provider.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenManager);

  final TokenManager _tokenManager;

  static bool _handlingUnauthorized = false;
  static bool _manualLogoutInProgress = false;
  static DateTime? _manualLogoutSuppressedUntil;

  static const List<String> _publicPaths = [
    '/api/auth/login',
    '/api/auth/register',
    '/api/auth/check-username',
    '/api/auth/check-phone',
    '/api/health',
  ];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_isPublicPath(options.path)) {
      handler.next(options);
      return;
    }

    final skipUnauthorizedRedirect =
        options.extra['skipUnauthorizedRedirect'] == true;
    final manualLogout = options.extra['manualLogout'] == true;

    if (await _tokenManager.isTokenExpired()) {
      if (!manualLogout && !_shouldSuppressUnauthorized()) {
        await appContainer.read(authNotifierProvider.notifier).handleSessionExpired();
      }
      if (!skipUnauthorizedRedirect && !manualLogout && !_shouldSuppressUnauthorized()) {
        _navigateToLogin();
      }
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 401,
            data: const {
              'code': 401,
              'message': '登录已过期，请重新登录',
              'data': null,
            },
          ),
          error: const UnauthorizedException('登录已过期，请重新登录'),
        ),
      );
      return;
    }

    final token = await _tokenManager.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final skipUnauthorizedRedirect =
        err.requestOptions.extra['skipUnauthorizedRedirect'] == true;
    final manualLogout = err.requestOptions.extra['manualLogout'] == true;
    if (err.response?.statusCode == 401 &&
        !_isPublicPath(err.requestOptions.path) &&
        !skipUnauthorizedRedirect &&
        !manualLogout &&
        !_shouldSuppressUnauthorized()) {
      await appContainer.read(authNotifierProvider.notifier).handleSessionExpired();
      _navigateToLogin();
    }

    final appException = AppException.fromDioError(err);
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: appException,
      ),
    );
  }

  bool _isPublicPath(String path) {
    return _publicPaths.any(path.contains);
  }

  static void beginManualLogout() {
    _manualLogoutInProgress = true;
    _manualLogoutSuppressedUntil = DateTime.now().add(const Duration(seconds: 3));
  }

  static void endManualLogout() {
    _manualLogoutInProgress = false;
  }

  static bool _shouldSuppressUnauthorized() {
    if (_manualLogoutInProgress) {
      return true;
    }
    final suppressedUntil = _manualLogoutSuppressedUntil;
    if (suppressedUntil == null) {
      return false;
    }
    final active = DateTime.now().isBefore(suppressedUntil);
    if (!active) {
      _manualLogoutSuppressedUntil = null;
    }
    return active;
  }

  void _navigateToLogin() {
    if (_handlingUnauthorized) return;

    final context = navigatorKey.currentContext ?? navigatorKey.currentState?.context;
    if (context == null) return;

    _handlingUnauthorized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.go('/login');
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('登录已过期，请重新登录'),
            backgroundColor: Color(0xFFFF8C00),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        _handlingUnauthorized = false;
      }
    });
  }
}
