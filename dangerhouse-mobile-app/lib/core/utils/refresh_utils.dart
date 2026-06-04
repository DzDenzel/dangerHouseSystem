import 'dart:async';
import 'package:flutter/material.dart';

class RefreshUtils {
  RefreshUtils._();

  static DateTime? _lastRefreshTime;
  static const Duration _minRefreshInterval = Duration(seconds: 2);

  static bool canRefresh() {
    final now = DateTime.now();
    if (_lastRefreshTime == null) {
      _lastRefreshTime = now;
      return true;
    }

    final elapsed = now.difference(_lastRefreshTime!);
    if (elapsed >= _minRefreshInterval) {
      _lastRefreshTime = now;
      return true;
    }
    return false;
  }

  static void resetRefreshTime() {
    _lastRefreshTime = null;
  }

  static Future<T?> withDebounce<T>({
    required Future<T> Function() action,
    Duration delay = const Duration(milliseconds: 300),
  }) async {
    await Future.delayed(delay);
    return await action();
  }
}

mixin RefreshMixin<T extends StatefulWidget> on State<T> {
  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;

  bool get isRefreshing => _isRefreshing;

  bool canRefresh() {
    final now = DateTime.now();
    if (_lastRefreshTime == null) {
      return true;
    }
    final elapsed = now.difference(_lastRefreshTime!);
    return elapsed >= const Duration(seconds: 2);
  }

  Future<void> performRefresh(Future<void> Function() refreshAction) async {
    if (_isRefreshing) return;

    if (!canRefresh()) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('刷新过于频繁，请稍后再试'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    _lastRefreshTime = DateTime.now();

    try {
      await refreshAction();
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _showErrorSnackbar(String error) {
    String errorMessage = '网络连接失败，请检查网络后重试';

    if (error.contains('SocketException') || error.contains('Connection refused')) {
      errorMessage = '网络连接失败，请检查网络后重试';
    } else if (error.contains('TimeoutException') || error.contains('timeout')) {
      errorMessage = '请求超时，请稍后重试';
    } else if (error.contains('401') || error.contains('Unauthorized')) {
      errorMessage = '登录已过期，请重新登录';
    } else if (error.contains('500')) {
      errorMessage = '服务器错误，请稍后重试';
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(errorMessage)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '重试',
          textColor: Colors.white,
          onPressed: () => performRefresh(refreshAction),
        ),
      ),
    );
  }

  Future<void> refreshAction();
}

class RefreshIndicatorWrapper extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final double displacement;

  const RefreshIndicatorWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.displacement = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      displacement: displacement,
      color: const Color(0xFF2F80ED),
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      child: child,
    );
  }
}
