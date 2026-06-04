import 'package:flutter/material.dart';

class RiskLevelUtil {
  static const Color colorA = Color(0xFF27AE60);
  static const Color colorB = Color(0xFFF2A900);
  static const Color colorC = Color(0xFFFF8C00);
  static const Color colorD = Color(0xFFFF4D4F);
  static const Color colorUnknown = Color(0xFF9CA3AF);

  static String getLabel(String? level) {
    if (level == null) return '未评定';
    
    switch (level.toUpperCase()) {
      case 'LOW':
      case 'A':
        return 'A级';
      case 'MEDIUM':
      case 'B':
        return 'B级';
      case 'HIGH':
      case 'C':
        return 'C级';
      case 'CRITICAL':
      case 'D':
        return 'D级';
      default:
        return '未评定';
    }
  }

  static String getShortLabel(String? level) {
    if (level == null) return '未知';
    
    switch (level.toUpperCase()) {
      case 'LOW':
      case 'A':
        return '安全';
      case 'MEDIUM':
      case 'B':
        return '有险';
      case 'HIGH':
      case 'C':
        return '局危';
      case 'CRITICAL':
      case 'D':
        return '整危';
      default:
        return '未知';
    }
  }

  static String getFullLabel(String? level) {
    if (level == null) return '未评定';

    switch (level.toUpperCase()) {
      case 'LOW':
      case 'A':
        return 'A级 - 无危险点';
      case 'MEDIUM':
      case 'B':
        return 'B级 - 有危险点';
      case 'HIGH':
      case 'C':
        return 'C级 - 局部危房';
      case 'CRITICAL':
      case 'D':
        return 'D级 - 整幢危房';
      default:
        return '未评定';
    }
  }

  static Color getColor(String? level) {
    if (level == null) return colorUnknown;

    switch (level.toUpperCase()) {
      case 'LOW':
      case 'A':
        return colorA;
      case 'MEDIUM':
      case 'B':
        return colorB;
      case 'HIGH':
      case 'C':
        return colorC;
      case 'CRITICAL':
      case 'D':
        return colorD;
      default:
        return colorUnknown;
    }
  }

  static String getDescription(String? level) {
    if (level == null) return '暂无评估描述';

    switch (level.toUpperCase()) {
      case 'LOW':
      case 'A':
        return '结构安全，承重结构未发现危险点，非承重结构完好。';
      case 'MEDIUM':
      case 'B':
        return '结构基本安全，个别结构构件处于危险状态，但不影响主体结构安全。';
      case 'HIGH':
      case 'C':
        return '局部危房，部分承重结构不能满足安全使用要求，构成局部危房。';
      case 'CRITICAL':
      case 'D':
        return '整幢危房，承重结构已不能满足安全使用要求，房屋整体处于危险状态。';
      default:
        return '暂无评估描述';
    }
  }

  static String getSubLabel(String? level) {
    if (level == null) return '';
    
    switch (level.toUpperCase()) {
      case 'LOW':
      case 'A':
        return '无危险点';
      case 'MEDIUM':
      case 'B':
        return '有危险点';
      case 'HIGH':
      case 'C':
        return '局部危房';
      case 'CRITICAL':
      case 'D':
        return '整幢危房';
      default:
        return '';
    }
  }

  static bool isDangerous(String? level) {
    if (level == null) return false;
    final upper = level.toUpperCase();
    return upper == 'HIGH' || upper == 'C' || upper == 'CRITICAL' || upper == 'D';
  }

  static bool matchesFilter(String? level, String filter) {
    if (filter == '全部') return true;
    
    final normalizedLevel = getLabel(level).replaceAll('级', '');
    final normalizedFilter = filter.replaceAll('级', '');
    return normalizedLevel == normalizedFilter;
  }

  static String getTitle(String? level) {
    if (level == null) return '待评估';

    switch (level.toUpperCase()) {
      case 'LOW':
      case 'A':
        return '结构状况良好';
      case 'MEDIUM':
      case 'B':
        return '轻度损伤区域';
      case 'HIGH':
      case 'C':
        return '中度危险区域';
      case 'CRITICAL':
      case 'D':
        return '严重危险区域';
      default:
        return '待评估';
    }
  }

  static String getReportDescription(String? level) {
    if (level == null) return '请等待专业人员进行评估。';

    switch (level.toUpperCase()) {
      case 'LOW':
      case 'A':
        return '该区域结构状况良好，未发现明显损伤。建议定期进行常规检查。';
      case 'MEDIUM':
      case 'B':
        return '该区域存在轻度损伤，建议加强监测频率，关注损伤发展趋势。';
      case 'HIGH':
      case 'C':
        return '局部承重结构存在危险隐患，建议限制区域使用并专业评估加固。';
      case 'CRITICAL':
      case 'D':
        return '承重结构存在严重安全隐患，建议立即停止使用并采取紧急处置措施。';
      default:
        return '请等待专业人员进行评估。';
    }
  }

  static List<String> get dangerousLevels => ['B', 'C', 'D', 'MEDIUM', 'HIGH', 'CRITICAL'];
}
