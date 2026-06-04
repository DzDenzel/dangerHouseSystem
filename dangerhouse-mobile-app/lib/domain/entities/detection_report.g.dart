// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detection_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DetectionReport _$DetectionReportFromJson(Map<String, dynamic> json) =>
    DetectionReport(
      id: (json['id'] as num).toInt(),
      taskId: (json['taskId'] as num).toInt(),
      riskLevel: json['riskLevel'] as String,
      riskTitle: json['riskTitle'] as String,
      riskDescription: json['riskDescription'] as String,
      maxWidth: (json['maxWidth'] as num).toDouble(),
      totalLength: (json['totalLength'] as num).toDouble(),
      morphology: json['morphology'] as String,
      images:
          (json['images'] as List<dynamic>).map((e) => e as String).toList(),
      suggestions: (json['suggestions'] as List<dynamic>)
          .map((e) =>
              RectificationSuggestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      crackCount: (json['crackCount'] as num?)?.toInt() ?? 0,
      damageRatio: (json['damageRatio'] as num?)?.toDouble() ?? 0.0,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      analysis: json['analysis'] as String?,
    );

Map<String, dynamic> _$DetectionReportToJson(DetectionReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'taskId': instance.taskId,
      'riskLevel': instance.riskLevel,
      'riskTitle': instance.riskTitle,
      'riskDescription': instance.riskDescription,
      'maxWidth': instance.maxWidth,
      'totalLength': instance.totalLength,
      'morphology': instance.morphology,
      'images': instance.images,
      'suggestions': instance.suggestions,
      'crackCount': instance.crackCount,
      'damageRatio': instance.damageRatio,
      'confidenceScore': instance.confidenceScore,
      'analysis': instance.analysis,
    };

RectificationSuggestion _$RectificationSuggestionFromJson(
        Map<String, dynamic> json) =>
    RectificationSuggestion(
      title: json['title'] as String,
      description: json['description'] as String,
      iconType: json['iconType'] as String,
    );

Map<String, dynamic> _$RectificationSuggestionToJson(
        RectificationSuggestion instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'iconType': instance.iconType,
    };
