import '../../data/models/detection_models.dart';

class RiskCalculationUtil {
  static const Map<String, int> _riskScores = {
    'A': 1,
    'LOW': 1,
    'B': 2,
    'MEDIUM': 2,
    'C': 3,
    'HIGH': 3,
    'D': 4,
    'CRITICAL': 4,
  };

  static String? calculateComprehensiveRiskLevel(
    List<DetectionResultDto> detections, {
    String? initialRiskLevel,
  }) {
    if (detections.isEmpty) {
      return initialRiskLevel;
    }

    final validDetections = detections.where((d) => d.riskLevel != null).toList();
    if (validDetections.isEmpty) {
      return initialRiskLevel;
    }

    int totalScore = 0;
    int maxScore = 0;

    for (final detection in validDetections) {
      final level = detection.riskLevel!.toUpperCase();
      final score = _riskScores[level] ?? 0;
      totalScore += score;
      if (score > maxScore) maxScore = score;
    }

    final avgScore = totalScore / validDetections.length;

    if (maxScore >= 4 || avgScore >= 3.5) {
      return 'D';
    } else if (maxScore >= 3 || avgScore >= 2.5) {
      return 'C';
    } else if (maxScore >= 2 || avgScore >= 1.5) {
      return 'B';
    } else {
      return 'A';
    }
  }

  static String? calculateFromRiskLevels(List<String?> riskLevels, {String? initialRiskLevel}) {
    if (riskLevels.isEmpty) {
      return initialRiskLevel;
    }

    final validLevels = riskLevels.where((l) => l != null).toList();
    if (validLevels.isEmpty) {
      return initialRiskLevel;
    }

    int totalScore = 0;
    int maxScore = 0;

    for (final level in validLevels) {
      final score = _riskScores[level!.toUpperCase()] ?? 0;
      totalScore += score;
      if (score > maxScore) maxScore = score;
    }

    final avgScore = totalScore / validLevels.length;

    if (maxScore >= 4 || avgScore >= 3.5) {
      return 'D';
    } else if (maxScore >= 3 || avgScore >= 2.5) {
      return 'C';
    } else if (maxScore >= 2 || avgScore >= 1.5) {
      return 'B';
    } else {
      return 'A';
    }
  }
}
