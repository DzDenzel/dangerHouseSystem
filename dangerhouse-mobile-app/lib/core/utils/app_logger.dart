import 'package:flutter/foundation.dart';

class AppLogger {
  static bool _isEnabled = kDebugMode;
  static const String _tag = 'DangerHouse';

  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  static void d(String message, [String? tag]) {
    if (_isEnabled) {
      debugPrint('[${tag ?? _tag}] DEBUG: $message');
    }
  }

  static void i(String message, [String? tag]) {
    if (_isEnabled) {
      debugPrint('[${tag ?? _tag}] INFO: $message');
    }
  }

  static void w(String message, [String? tag]) {
    if (_isEnabled) {
      debugPrint('[${tag ?? _tag}] WARN: $message');
    }
  }

  static void e(String message, [dynamic error, String? tag]) {
    if (_isEnabled) {
      debugPrint('[${tag ?? _tag}] ERROR: $message${error != null ? ' - $error' : ''}');
    }
  }

  static void api(String method, String url, [Map? data]) {
    if (_isEnabled) {
      debugPrint('[API] $method $url${data != null ? ' - $data' : ''}');
    }
  }

  static void response(String url, int statusCode, [dynamic data]) {
    if (_isEnabled) {
      debugPrint('[RESPONSE] $url [$statusCode]${data != null ? ' - $data' : ''}');
    }
  }

  static void network(String message) {
    if (_isEnabled) {
      debugPrint('[NETWORK] $message');
    }
  }

  static void repository(String repositoryName, String action, [dynamic data]) {
    if (_isEnabled) {
      debugPrint('[$repositoryName] $action${data != null ? ': $data' : ''}');
    }
  }
}
