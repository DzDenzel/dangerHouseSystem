// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'building_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Building _$BuildingFromJson(Map<String, dynamic> json) => Building(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      address: json['address'] as String,
      structureType: json['structureType'] as String,
      buildYear: (json['buildYear'] as num?)?.toInt(),
      floorCount: (json['floorCount'] as num?)?.toInt(),
      undergroundFloorCount: (json['undergroundFloorCount'] as num?)?.toInt(),
      area: (json['area'] as num?)?.toDouble(),
      description: json['description'] as String?,
      ownerName: json['ownerName'] as String?,
      ownerPhone: json['ownerPhone'] as String?,
      ownerUserId: (json['ownerUserId'] as num?)?.toInt(),
      createdBy: (json['createdBy'] as num?)?.toInt(),
      createdByRole: (json['createdByRole'] as num?)?.toInt(),
      createdByRoleName: json['createdByRoleName'] as String?,
      assignedInspectorId: (json['assignedInspectorId'] as num?)?.toInt(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      initialRiskLevel: json['initialRiskLevel'] as String?,
      imagePath: json['imagePath'] as String?,
    );

Map<String, dynamic> _$BuildingToJson(Building instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'structureType': instance.structureType,
      'buildYear': instance.buildYear,
      'floorCount': instance.floorCount,
      'undergroundFloorCount': instance.undergroundFloorCount,
      'area': instance.area,
      'description': instance.description,
      'ownerName': instance.ownerName,
      'ownerPhone': instance.ownerPhone,
      'ownerUserId': instance.ownerUserId,
      'createdBy': instance.createdBy,
      'createdByRole': instance.createdByRole,
      'createdByRoleName': instance.createdByRoleName,
      'assignedInspectorId': instance.assignedInspectorId,
      'longitude': instance.longitude,
      'latitude': instance.latitude,
      'initialRiskLevel': instance.initialRiskLevel,
      'imagePath': instance.imagePath,
    };

CreateBuildingRequest _$CreateBuildingRequestFromJson(
        Map<String, dynamic> json) =>
    CreateBuildingRequest(
      name: json['name'] as String,
      address: json['address'] as String,
      structureType: json['structureType'] as String,
      buildYear: (json['buildYear'] as num?)?.toInt(),
      floorCount: (json['floorCount'] as num?)?.toInt(),
      undergroundFloorCount: (json['undergroundFloorCount'] as num?)?.toInt(),
      area: (json['area'] as num?)?.toDouble(),
      description: json['description'] as String?,
      ownerName: json['ownerName'] as String?,
      ownerPhone: json['ownerPhone'] as String?,
      longitude: (json['longitude'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      imagePath: json['imagePath'] as String?,
    );

Map<String, dynamic> _$CreateBuildingRequestToJson(
        CreateBuildingRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'address': instance.address,
      'structureType': instance.structureType,
      'buildYear': instance.buildYear,
      'floorCount': instance.floorCount,
      'undergroundFloorCount': instance.undergroundFloorCount,
      'area': instance.area,
      'description': instance.description,
      'ownerName': instance.ownerName,
      'ownerPhone': instance.ownerPhone,
      'longitude': instance.longitude,
      'latitude': instance.latitude,
      'imagePath': instance.imagePath,
    };

UpdateBuildingRequest _$UpdateBuildingRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateBuildingRequest(
      name: json['name'] as String?,
      address: json['address'] as String?,
      structureType: json['structureType'] as String?,
      buildYear: (json['buildYear'] as num?)?.toInt(),
      floorCount: (json['floorCount'] as num?)?.toInt(),
      undergroundFloorCount: (json['undergroundFloorCount'] as num?)?.toInt(),
      area: (json['area'] as num?)?.toDouble(),
      description: json['description'] as String?,
      ownerName: json['ownerName'] as String?,
      ownerPhone: json['ownerPhone'] as String?,
      longitude: (json['longitude'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      imagePath: json['imagePath'] as String?,
    );

Map<String, dynamic> _$UpdateBuildingRequestToJson(
        UpdateBuildingRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'address': instance.address,
      'structureType': instance.structureType,
      'buildYear': instance.buildYear,
      'floorCount': instance.floorCount,
      'undergroundFloorCount': instance.undergroundFloorCount,
      'area': instance.area,
      'description': instance.description,
      'ownerName': instance.ownerName,
      'ownerPhone': instance.ownerPhone,
      'longitude': instance.longitude,
      'latitude': instance.latitude,
      'imagePath': instance.imagePath,
    };
