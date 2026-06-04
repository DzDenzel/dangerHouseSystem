class DashboardDto {
  final int? userCount;
  final int? buildingCount;
  final int? detectionCount;
  final int? highRiskCount;

  DashboardDto({
    this.userCount,
    this.buildingCount,
    this.detectionCount,
    this.highRiskCount,
  });

  factory DashboardDto.fromJson(Map<String, dynamic> json) {
    return DashboardDto(
      userCount: json['userCount'] as int?,
      buildingCount: json['buildingCount'] as int?,
      detectionCount: json['detectionCount'] as int?,
      highRiskCount: json['highRiskCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userCount': userCount,
      'buildingCount': buildingCount,
      'detectionCount': detectionCount,
      'highRiskCount': highRiskCount,
    };
  }
}
