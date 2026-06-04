import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userIdKey = 'user_id';

  static TokenManager? _instance;

  static TokenManager get instance => _instance ??= TokenManager._();

  TokenManager._();

  Future<void> saveToken({
    required String token,
    String? refreshToken,
    DateTime? expiryTime,
    int? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_tokenKey, token),
      if (refreshToken != null) prefs.setString(_refreshTokenKey, refreshToken),
      if (expiryTime != null) prefs.setString(_tokenExpiryKey, expiryTime.toIso8601String()),
      if (userId != null) prefs.setInt(_userIdKey, userId),
    ]);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<DateTime?> getTokenExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryStr = prefs.getString(_tokenExpiryKey);
    if (expiryStr == null) return null;
    try {
      return DateTime.parse(expiryStr);
    } catch (_) {
      return null;
    }
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_tokenKey),
      prefs.remove(_refreshTokenKey),
      prefs.remove(_tokenExpiryKey),
      prefs.remove(_userIdKey),
    ]);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return false;
    }
    if (await isTokenExpired()) {
      await clearToken();
      return false;
    }
    return true;
  }

  Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry() ?? await _getJwtExpiry();
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry);
  }

  Future<bool> isTokenExpiringSoon({Duration threshold = const Duration(minutes: 5)}) async {
    final expiry = await getTokenExpiry() ?? await _getJwtExpiry();
    if (expiry == null) return false;
    return DateTime.now().add(threshold).isAfter(expiry);
  }

  Future<bool> needsRefresh() async {
    if (!await hasToken()) return false;
    return await isTokenExpired() || await isTokenExpiringSoon();
  }

  Future<DateTime?> _getJwtExpiry() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return null;

    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final exp = map['exp'];
      if (exp is num) {
        return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}
