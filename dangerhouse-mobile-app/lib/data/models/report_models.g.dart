// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportGenerateResponse _$ReportGenerateResponseFromJson(
        Map<String, dynamic> json) =>
    ReportGenerateResponse(
      reportId: (json['reportId'] as num).toInt(),
      reportNo: json['reportNo'] as String,
      downloadUrl: json['downloadUrl'] as String?,
      status: json['status'] as String?,
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$ReportGenerateResponseToJson(
        ReportGenerateResponse instance) =>
    <String, dynamic>{
      'reportId': instance.reportId,
      'reportNo': instance.reportNo,
      'downloadUrl': instance.downloadUrl,
      'status': instance.status,
      'createdAt': instance.createdAt,
    };

ReportDto _$ReportDtoFromJson(Map<String, dynamic> json) => ReportDto(
      id: (json['id'] as num).toInt(),
      reportNo: json['reportNo'] as String,
      detectionId: (json['detectionId'] as num).toInt(),
      buildingId: (json['buildingId'] as num?)?.toInt(),
      buildingName: json['buildingName'] as String?,
      buildingAddress: json['buildingAddress'] as String?,
      riskLevel: json['riskLevel'] as String?,
      riskTitle: json['riskTitle'] as String?,
      riskDescription: json['riskDescription'] as String?,
      maxWidth: (json['maxWidth'] as num?)?.toDouble(),
      totalLength: (json['totalLength'] as num?)?.toDouble(),
      morphology: json['morphology'] as String?,
      status: json['status'] as String?,
      createdAt: json['createdAt'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
      filePath: json['filePath'] as String?,
      fileType: json['fileType'] as String?,
      generatedAt: json['generatedAt'] as String?,
    );

Map<String, dynamic> _$ReportDtoToJson(ReportDto instance) => <String, dynamic>{
      'id': instance.id,
      'reportNo': instance.reportNo,
      'detectionId': instance.detectionId,
      'buildingId': instance.buildingId,
      'buildingName': instance.buildingName,
      'buildingAddress': instance.buildingAddress,
      'riskLevel': instance.riskLevel,
      'riskTitle': instance.riskTitle,
      'riskDescription': instance.riskDescription,
      'maxWidth': instance.maxWidth,
      'totalLength': instance.totalLength,
      'morphology': instance.morphology,
      'status': instance.status,
      'createdAt': instance.createdAt,
      'downloadUrl': instance.downloadUrl,
      'filePath': instance.filePath,
      'fileType': instance.fileType,
      'generatedAt': instance.generatedAt,
    };
