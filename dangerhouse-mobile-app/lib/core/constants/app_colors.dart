import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2F80ED);
  static const Color primaryLight = Color(0xFF56CCF2);
  static const Color primaryDark = Color(0xFF1A5F9E5);
  static const Color primaryWithOpacity10 = Color(0x1A2F80ED);
  static const Color primaryWithOpacity20 = Color(0x332F80ED);

  static const Color secondary = Color(0xFF27AE60);
  static const Color secondaryLight = Color(0xFF6FCF97);

  static const Color accent = Color(0xFFFF9500);
  static const Color accentLight = Color(0xFFFFE0E0);

  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const Color background = Color(0xFFF5F7FA);
  static const Color backgroundDark = Color(0xFFE5E7EB);
  static const Color backgroundLight = Color(0xFFFFFFFF);

  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF8F9FA);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF374151);
  static const Color textTertiary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFD1D5DB);
  static const Color textOnPrimary = Colors.white;
  static const Color textOnDark = Color(0xFFF3F4F6);

  static const Color divider = Color(0xFFE5E7EB);
  static const Color dividerDark = Color(0xFFD1D5DB);

  static const Color border = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFFD1D5DB);
  static const Color borderLight = Color(0xFFF3F4F6);

  static const Color shadow = Color(0xFF000000);
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);

  static const Color overlay = Color(0x80000000);

  static const Map<String, Color> riskLevelColors = {
    'A': Color(0xFF27AE60),
    'B': Color(0xFF2F80ED),
    'C': Color(0xFFF59E0B),
    'D': Color(0xFFEF4444),
    'LOW': Color(0xFF27AE60),
    'MEDIUM': Color(0xFF2F80ED),
    'HIGH': Color(0xFFF59E0B),
    'CRITICAL': Color(0xFFEF4444),
  };

  static Color getRiskColor(String? level) {
    if (level == null) return textHint;
    return riskLevelColors[level.toUpperCase()] ?? textHint;
  }

  static Color getRiskBackgroundColor(String? level) {
    final color = getRiskColor(level);
    return color.withValues(alpha: 0);
  }

  static Color withAlpha(Color color, double alpha) {
    return color.withValues(alpha: alpha);
  }
}
