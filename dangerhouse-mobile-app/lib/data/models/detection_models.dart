import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/common_utils.dart';

part 'detection_models.g.dart';

@JsonSerializable()
class DetectionResultDto {
  final int id;
  final int? buildingId;
  final String? buildingName;
  final String? buildingAddress;
  final int? userId;
  final String? username;
  final String? status;
  final int? crackCount;
  final double? damageRatio;
  final String? riskLevel;
  final double? confidence;
  final String? detectTime;
  final String? createdAt;
  final String? updatedAt;
  final DetectResult? resultDetails;
  final String? description;
  final String? errorMessage;
  final String? analysis;
  final String? severityLevel;
  final double? damageRatioPercent;
  final List<DetectionImage>? images;
  final DetectionReportInfo? report;

  DetectionResultDto({
    required this.id,
    this.buildingId,
    this.buildingName,
    this.buildingAddress,
    this.userId,
    this.username,
    this.status,
    this.crackCount,
    this.damageRatio,
    this.riskLevel,
    this.confidence,
    this.detectTime,
    this.createdAt,
    this.updatedAt,
    this.resultDetails,
    this.description,
    this.errorMessage,
    this.analysis,
    this.severityLevel,
    this.damageRatioPercent,
    this.images,
    this.report,
  });

  factory DetectionResultDto.fromJson(Map<String, dynamic> json) {
    final detectResult = _parseDetectResult(json['detectResult']);
    DetectResult? resultDetails;
    String? analysis;
    String? severityLevel;
    double? damageRatioPercent;
    int? crackCountFromResult;
    double? confidenceFromResult;
    
    if (detectResult != null) {
      final normalizedResult = Map<String, dynamic>.from(detectResult);
      normalizedResult['totalCracks'] ??= detectResult['crackCount'];
      normalizedResult['severityLevel'] ??= detectResult['riskLevel'];
      normalizedResult['confidenceScore'] ??= detectResult['confidence'];
      normalizedResult['damageRatio'] ??= detectResult['damageRatio'];
      resultDetails = DetectResult.fromJson(normalizedResult);
      analysis = detectResult['analysis'] as String?;
      severityLevel = detectResult['severityLevel'] as String?;
      damageRatioPercent = (detectResult['damageRatio'] as num?)?.toDouble();
      crackCountFromResult = (detectResult['crackCount'] as num?)?.toInt();
      confidenceFromResult = (detectResult['confidenceScore'] as num?)?.toDouble();
    }

    final imagesList = json['images'] as List<dynamic>?;
    List<DetectionImage>? images;
    if (imagesList != null) {
      images = imagesList.map((e) => DetectionImage.fromJson(e as Map<String, dynamic>)).toList();
    }

    final reportJson = json['report'];
    final report = reportJson is Map<String, dynamic>
        ? DetectionReportInfo.fromJson(reportJson)
        : (reportJson is Map
            ? DetectionReportInfo.fromJson(
                reportJson.map((key, value) => MapEntry(key.toString(), value)),
              )
            : null);

    return DetectionResultDto(
      id: json['id'] as int? ?? 0,
      buildingId: json['buildingId'] as int?,
      buildingName: json['buildingName'] as String?,
      buildingAddress: json['buildingAddress'] as String?,
      userId: json['userId'] as int?,
      username: json['username'] as String?,
      status: json['status'] as String?,
      crackCount: crackCountFromResult ?? json['crackCount'] as int?,
      damageRatio: damageRatioPercent ?? (json['damageRatio'] as num?)?.toDouble(),
      riskLevel: severityLevel ?? json['riskLevel'] as String?,
      confidence: confidenceFromResult ?? (json['confidence'] as num?)?.toDouble(),
      detectTime: json['detectTime'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      resultDetails: resultDetails,
      description: json['description'] as String?,
      errorMessage: json['errorMessage'] as String?,
      analysis: analysis,
      severityLevel: severityLevel,
      damageRatioPercent: damageRatioPercent,
      images: images,
      report: report,
    );
  }
  
  Map<String, dynamic> toJson() => _$DetectionResultDtoToJson(this);

  String get resolvedRiskLevel => riskLevel ?? severityLevel ?? resultDetails?.severityLevel ?? 'UNKNOWN';

  String? get resolvedAnalysis => analysis ?? resultDetails?.analysis;

  int get resolvedCrackCount =>
      crackCount ?? resultDetails?.totalCracks ?? resultDetails?.cracks?.length ?? 0;

  double get resolvedDamageRatio =>
      damageRatioPercent ?? damageRatio ?? resultDetails?.damageRatio ?? 0.0;

  double get resolvedConfidence =>
      confidence ?? resultDetails?.confidenceScore ?? 0.0;

  double get resolvedMaxWidth {
    final directValue = resultDetails?.maxWidth;
    if (directValue != null && directValue > 0) {
      return directValue;
    }

    final cracks = resultDetails?.cracks;
    if (cracks == null || cracks.isEmpty) {
      return 0.0;
    }

    return cracks
        .map((item) => (item.width ?? 0).toDouble())
        .fold<double>(0.0, (value, element) => element > value ? element : value);
  }

  int get resolvedTotalCracks => resultDetails?.totalCracks ?? resolvedCrackCount;

  List<DetectionImage> get resolvedImages => images ?? const <DetectionImage>[];
}

@JsonSerializable()
class DetectionReportInfo {
  final int? id;
  final String? reportNo;
  final String? filePath;
  final String? generatedAt;

  const DetectionReportInfo({
    this.id,
    this.reportNo,
    this.filePath,
    this.generatedAt,
  });

  factory DetectionReportInfo.fromJson(Map<String, dynamic> json) =>
      _$DetectionReportInfoFromJson(json);
  Map<String, dynamic> toJson() => _$DetectionReportInfoToJson(this);

  String? get fullFilePath => ImageUtils.getFullFileUrl(filePath);
}

Map<String, dynamic>? _parseDetectResult(dynamic source) {
  if (source == null) {
    return null;
  }

  if (source is Map<String, dynamic>) {
    return source;
  }

  if (source is Map) {
    return source.map((key, value) => MapEntry(key.toString(), value));
  }

  if (source is String) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      return null;
    }
  }

  return null;
}

@JsonSerializable()
class DetectResult {
  final List<CrackDto>? cracks;
  final int? totalCracks;
  final double? maxWidth;
  final List<String>? damageAreas;
  final List<String>? recommendations;
  final String? analysis;
  final String? severityLevel;
  final double? confidenceScore;
  final double? damageRatio;

  DetectResult({
    this.cracks,
    this.totalCracks,
    this.maxWidth,
    this.damageAreas,
    this.recommendations,
    this.analysis,
    this.severityLevel,
    this.confidenceScore,
    this.damageRatio,
  });

  factory DetectResult.fromJson(Map<String, dynamic> json) =>
      _$DetectResultFromJson(json);
  Map<String, dynamic> toJson() => _$DetectResultToJson(this);
}

@JsonSerializable()
class CrackDto {
  final int? id;
  final String? type;
  final String? typeName;
  final double? confidence;
  final List<double>? bbox;
  final List<double>? center;
  final int? width;
  final int? height;
  final int? area;

  CrackDto({
    this.id,
    this.type,
    this.typeName,
    this.confidence,
    this.bbox,
    this.center,
    this.width,
    this.height,
    this.area,
  });

  factory CrackDto.fromJson(Map<String, dynamic> json) =>
      _$CrackDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CrackDtoToJson(this);
}

@JsonSerializable()
class DetectionImage {
  final int? id;
  final String? imagePath;
  final String? resultImagePath;
  final String? imageType;
  final String? uploadTime;

  DetectionImage({
    this.id,
    this.imagePath,
    this.resultImagePath,
    this.imageType,
    this.uploadTime,
  });

  factory DetectionImage.fromJson(Map<String, dynamic> json) =>
      _$DetectionImageFromJson(json);
  Map<String, dynamic> toJson() => _$DetectionImageToJson(this);

  String? get fullImagePath => ImageUtils.getFullImageUrl(imagePath);
  String? get fullResultImagePath => ImageUtils.getFullImageUrl(resultImagePath);
}
