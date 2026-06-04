// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detection_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DetectionResultDto _$DetectionResultDtoFromJson(Map<String, dynamic> json) =>
    DetectionResultDto(
      id: (json['id'] as num).toInt(),
      buildingId: (json['buildingId'] as num?)?.toInt(),
      buildingName: json['buildingName'] as String?,
      buildingAddress: json['buildingAddress'] as String?,
      userId: (json['userId'] as num?)?.toInt(),
      username: json['username'] as String?,
      status: json['status'] as String?,
      crackCount: (json['crackCount'] as num?)?.toInt(),
      damageRatio: (json['damageRatio'] as num?)?.toDouble(),
      riskLevel: json['riskLevel'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      detectTime: json['detectTime'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      resultDetails: json['resultDetails'] == null
          ? null
          : DetectResult.fromJson(
              json['resultDetails'] as Map<String, dynamic>),
      description: json['description'] as String?,
      errorMessage: json['errorMessage'] as String?,
      analysis: json['analysis'] as String?,
      severityLevel: json['severityLevel'] as String?,
      damageRatioPercent: (json['damageRatioPercent'] as num?)?.toDouble(),
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => DetectionImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      report: json['report'] == null
          ? null
          : DetectionReportInfo.fromJson(json['report'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DetectionResultDtoToJson(DetectionResultDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'buildingId': instance.buildingId,
      'buildingName': instance.buildingName,
      'buildingAddress': instance.buildingAddress,
      'userId': instance.userId,
      'username': instance.username,
      'status': instance.status,
      'crackCount': instance.crackCount,
      'damageRatio': instance.damageRatio,
      'riskLevel': instance.riskLevel,
      'confidence': instance.confidence,
      'detectTime': instance.detectTime,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'resultDetails': instance.resultDetails,
      'description': instance.description,
      'errorMessage': instance.errorMessage,
      'analysis': instance.analysis,
      'severityLevel': instance.severityLevel,
      'damageRatioPercent': instance.damageRatioPercent,
      'images': instance.images,
      'report': instance.report,
    };

DetectionReportInfo _$DetectionReportInfoFromJson(Map<String, dynamic> json) =>
    DetectionReportInfo(
      id: (json['id'] as num?)?.toInt(),
      reportNo: json['reportNo'] as String?,
      filePath: json['filePath'] as String?,
      generatedAt: json['generatedAt'] as String?,
    );

Map<String, dynamic> _$DetectionReportInfoToJson(
        DetectionReportInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reportNo': instance.reportNo,
      'filePath': instance.filePath,
      'generatedAt': instance.generatedAt,
    };

DetectResult _$DetectResultFromJson(Map<String, dynamic> json) => DetectResult(
      cracks: (json['cracks'] as List<dynamic>?)
          ?.map((e) => CrackDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCracks: (json['totalCracks'] as num?)?.toInt(),
      maxWidth: (json['maxWidth'] as num?)?.toDouble(),
      damageAreas: (json['damageAreas'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      analysis: json['analysis'] as String?,
      severityLevel: json['severityLevel'] as String?,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble(),
      damageRatio: (json['damageRatio'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$DetectResultToJson(DetectResult instance) =>
    <String, dynamic>{
      'cracks': instance.cracks,
      'totalCracks': instance.totalCracks,
      'maxWidth': instance.maxWidth,
      'damageAreas': instance.damageAreas,
      'recommendations': instance.recommendations,
      'analysis': instance.analysis,
      'severityLevel': instance.severityLevel,
      'confidenceScore': instance.confidenceScore,
      'damageRatio': instance.damageRatio,
    };

CrackDto _$CrackDtoFromJson(Map<String, dynamic> json) => CrackDto(
      id: (json['id'] as num?)?.toInt(),
      type: json['type'] as String?,
      typeName: json['typeName'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      bbox: (json['bbox'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      center: (json['center'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      area: (json['area'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CrackDtoToJson(CrackDto instance) => <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'typeName': instance.typeName,
      'confidence': instance.confidence,
      'bbox': instance.bbox,
      'center': instance.center,
      'width': instance.width,
      'height': instance.height,
      'area': instance.area,
    };

DetectionImage _$DetectionImageFromJson(Map<String, dynamic> json) =>
    DetectionImage(
      id: (json['id'] as num?)?.toInt(),
      imagePath: json['imagePath'] as String?,
      resultImagePath: json['resultImagePath'] as String?,
      imageType: json['imageType'] as String?,
      uploadTime: json['uploadTime'] as String?,
    );

Map<String, dynamic> _$DetectionImageToJson(DetectionImage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'imagePath': instance.imagePath,
      'resultImagePath': instance.resultImagePath,
      'imageType': instance.imageType,
      'uploadTime': instance.uploadTime,
    };
