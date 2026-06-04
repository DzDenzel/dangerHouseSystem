import 'package:json_annotation/json_annotation.dart';

part 'report_models.g.dart';

@JsonSerializable()
class ReportGenerateResponse {
  final int reportId;
  final String reportNo;
  final String? downloadUrl;
  final String? status;
  final String? createdAt;

  ReportGenerateResponse({
    required this.reportId,
    required this.reportNo,
    this.downloadUrl,
    this.status,
    this.createdAt,
  });

  factory ReportGenerateResponse.fromJson(Map<String, dynamic> json) =>
      _$ReportGenerateResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ReportGenerateResponseToJson(this);
}

@JsonSerializable()
class ReportDto {
  final int id;
  final String reportNo;
  final int detectionId;
  final int? buildingId;
  final String? buildingName;
  final String? buildingAddress;
  final String? riskLevel;
  final String? riskTitle;
  final String? riskDescription;
  final double? maxWidth;
  final double? totalLength;
  final String? morphology;
  final String? status;
  final String? createdAt;
  final String? downloadUrl;
  final String? filePath;
  final String? fileType;
  final String? generatedAt;

  ReportDto({
    required this.id,
    required this.reportNo,
    required this.detectionId,
    this.buildingId,
    this.buildingName,
    this.buildingAddress,
    this.riskLevel,
    this.riskTitle,
    this.riskDescription,
    this.maxWidth,
    this.totalLength,
    this.morphology,
    this.status,
    this.createdAt,
    this.downloadUrl,
    this.filePath,
    this.fileType,
    this.generatedAt,
  });

  factory ReportDto.fromJson(Map<String, dynamic> json) =>
      _$ReportDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ReportDtoToJson(this);
}
