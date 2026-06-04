import 'package:json_annotation/json_annotation.dart';

part 'detection_report.g.dart';

@JsonSerializable()
class DetectionReport {
  final int id;
  final int taskId;
  final String riskLevel;
  final String riskTitle;
  final String riskDescription;
  final double maxWidth;
  final double totalLength;
  final String morphology;
  final List<String> images;
  final List<RectificationSuggestion> suggestions;
  final int crackCount;
  final double damageRatio;
  final double confidenceScore;
  final String? analysis;

  DetectionReport({
    required this.id,
    required this.taskId,
    required this.riskLevel,
    required this.riskTitle,
    required this.riskDescription,
    required this.maxWidth,
    required this.totalLength,
    required this.morphology,
    required this.images,
    required this.suggestions,
    this.crackCount = 0,
    this.damageRatio = 0.0,
    this.confidenceScore = 0.0,
    this.analysis,
  });

  factory DetectionReport.fromJson(Map<String, dynamic> json) => _$DetectionReportFromJson(json);
  Map<String, dynamic> toJson() => _$DetectionReportToJson(this);
}

@JsonSerializable()
class RectificationSuggestion {
  final String title;
  final String description;
  final String iconType;

  RectificationSuggestion({
    required this.title,
    required this.description,
    required this.iconType,
  });

  factory RectificationSuggestion.fromJson(Map<String, dynamic> json) => _$RectificationSuggestionFromJson(json);
  Map<String, dynamic> toJson() => _$RectificationSuggestionToJson(this);
}
