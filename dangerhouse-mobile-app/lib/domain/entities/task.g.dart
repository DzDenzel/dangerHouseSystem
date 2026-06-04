// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Task _$TaskFromJson(Map<String, dynamic> json) => Task(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      address: json['address'] as String,
      time: json['time'] as String,
      riskLevel: json['riskLevel'] as String,
      riskDescription: json['riskDescription'] as String,
      status: json['status'] as String,
      detectResult: json['detectResult'] as String?,
    );

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'address': instance.address,
      'time': instance.time,
      'riskLevel': instance.riskLevel,
      'riskDescription': instance.riskDescription,
      'status': instance.status,
      'detectResult': instance.detectResult,
    };
