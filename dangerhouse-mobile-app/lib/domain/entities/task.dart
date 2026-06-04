import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'task.g.dart';

@JsonSerializable()
class Task {
  final int id;
  final String title;
  final String address;
  final String? description;
  final String time;
  final String riskLevel;
  final String riskDescription;
  final String status;
  final String? detectResult;

  Task({
    required this.id,
    required this.title,
    required this.address,
    this.description,
    required this.time,
    required this.riskLevel,
    required this.riskDescription,
    required this.status,
    this.detectResult,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    final riskLevel = json['riskLevel'] as String? ?? 'LOW';

    Map<String, dynamic>? detectResultMap;
    final detectResultRaw = json['detectResult'];

    if (detectResultRaw is Map<String, dynamic>) {
      detectResultMap = detectResultRaw;
    } else if (detectResultRaw is String && detectResultRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(detectResultRaw);
        if (decoded is Map<String, dynamic>) {
          detectResultMap = decoded;
        }
      } catch (_) {
        detectResultMap = null;
      }
    }

    String description = 'Unknown risk';
    if (detectResultMap != null) {
      final analysis = detectResultMap['analysis'] as String? ?? '';
      description = analysis.isNotEmpty ? analysis : 'No analysis available';
    } else {
      description = _getDescriptionFromLevel(riskLevel);
    }

    return Task(
      id: json['id'] as int? ?? 0,
      title: json['buildingName'] as String? ?? 'Unknown building',
      address: json['buildingAddress'] as String? ?? 'Unknown address',
      description: json['description'] as String?,
      time: json['detectTime'] as String? ?? '',
      riskLevel: riskLevel,
      riskDescription: description,
      status: json['status'] as String? ?? 'UNKNOWN',
      detectResult: detectResultRaw?.toString(),
    );
  }

  static String _getDescriptionFromLevel(String level) {
    switch (level.toUpperCase()) {
      case 'CRITICAL':
      case 'D':
        return 'Severe risk';
      case 'HIGH':
      case 'C':
        return 'High risk';
      case 'MEDIUM':
      case 'B':
        return 'Moderate risk';
      case 'LOW':
      case 'A':
        return 'Low risk';
      default:
        return 'Unknown risk';
    }
  }

  Map<String, dynamic> toJson() => _$TaskToJson(this);
}
