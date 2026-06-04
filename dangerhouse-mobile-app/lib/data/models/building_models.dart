import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/common_utils.dart';

part 'building_models.g.dart';

@JsonSerializable()
class Building {
  final int id;
  final String name;
  final String address;
  final String structureType;
  final int? buildYear;
  final int? floorCount;
  final int? undergroundFloorCount;
  final double? area;
  final String? description;
  final String? ownerName;
  final String? ownerPhone;
  final int? ownerUserId;
  final int? createdBy;
  final int? createdByRole;
  final String? createdByRoleName;
  final int? assignedInspectorId;
  final double? longitude;
  final double? latitude;
  final String? initialRiskLevel;
  final String? imagePath;

  const Building({
    required this.id,
    required this.name,
    required this.address,
    required this.structureType,
    this.buildYear,
    this.floorCount,
    this.undergroundFloorCount,
    this.area,
    this.description,
    this.ownerName,
    this.ownerPhone,
    this.ownerUserId,
    this.createdBy,
    this.createdByRole,
    this.createdByRoleName,
    this.assignedInspectorId,
    this.longitude,
    this.latitude,
    this.initialRiskLevel,
    this.imagePath,
  });

  factory Building.fromJson(Map<String, dynamic> json) => _$BuildingFromJson(json);
  Map<String, dynamic> toJson() => _$BuildingToJson(this);

  static const Map<String, String> structureTypeMap = {
    'BRICK_MIX': '砖混结构',
    'CONCRETE': '钢筋混凝土',
    'STEEL': '钢结构',
    'BRICK_WOOD': '砖木结构',
    'OTHER': '其他',
  };

  static const Map<String, String> structureTypeReverseMap = {
    '砖混结构': 'BRICK_MIX',
    '钢筋混凝土': 'CONCRETE',
    '钢结构': 'STEEL',
    '砖木结构': 'BRICK_WOOD',
    '其他': 'OTHER',
  };

  String get structureTypeLabel => structureTypeMap[structureType] ?? structureType;
  String? get fullImagePath => ImageUtils.getFullImageUrl(imagePath);

  Building copyWith({
    int? id,
    String? name,
    String? address,
    String? structureType,
    int? buildYear,
    int? floorCount,
    int? undergroundFloorCount,
    double? area,
    String? description,
    String? ownerName,
    String? ownerPhone,
    int? ownerUserId,
    int? createdBy,
    int? createdByRole,
    String? createdByRoleName,
    int? assignedInspectorId,
    double? longitude,
    double? latitude,
    String? initialRiskLevel,
    String? imagePath,
  }) {
    return Building(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      structureType: structureType ?? this.structureType,
      buildYear: buildYear ?? this.buildYear,
      floorCount: floorCount ?? this.floorCount,
      undergroundFloorCount: undergroundFloorCount ?? this.undergroundFloorCount,
      area: area ?? this.area,
      description: description ?? this.description,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      createdBy: createdBy ?? this.createdBy,
      createdByRole: createdByRole ?? this.createdByRole,
      createdByRoleName: createdByRoleName ?? this.createdByRoleName,
      assignedInspectorId: assignedInspectorId ?? this.assignedInspectorId,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      initialRiskLevel: initialRiskLevel ?? this.initialRiskLevel,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  String toString() {
    return 'Building(id: $id, name: $name, address: $address, structureType: $structureType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Building && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class CreateBuildingRequest {
  final String name;
  final String address;
  final String structureType;
  final int? buildYear;
  final int? floorCount;
  final int? undergroundFloorCount;
  final double? area;
  final String? description;
  final String? ownerName;
  final String? ownerPhone;
  final double? longitude;
  final double? latitude;
  final String? imagePath;

  const CreateBuildingRequest({
    required this.name,
    required this.address,
    required this.structureType,
    this.buildYear,
    this.floorCount,
    this.undergroundFloorCount,
    this.area,
    this.description,
    this.ownerName,
    this.ownerPhone,
    this.longitude,
    this.latitude,
    this.imagePath,
  });

  factory CreateBuildingRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateBuildingRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateBuildingRequestToJson(this);
}

@JsonSerializable()
class UpdateBuildingRequest {
  final String? name;
  final String? address;
  final String? structureType;
  final int? buildYear;
  final int? floorCount;
  final int? undergroundFloorCount;
  final double? area;
  final String? description;
  final String? ownerName;
  final String? ownerPhone;
  final double? longitude;
  final double? latitude;
  final String? imagePath;

  const UpdateBuildingRequest({
    this.name,
    this.address,
    this.structureType,
    this.buildYear,
    this.floorCount,
    this.undergroundFloorCount,
    this.area,
    this.description,
    this.ownerName,
    this.ownerPhone,
    this.longitude,
    this.latitude,
    this.imagePath,
  });

  factory UpdateBuildingRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateBuildingRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateBuildingRequestToJson(this);
}
