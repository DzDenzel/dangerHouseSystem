import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

@JsonSerializable()
class LoginRequest {
  final String account;
  final String password;
  final bool rememberMe;
  final String clientType;

  LoginRequest({
    required this.account,
    required this.password,
    this.rememberMe = false,
    this.clientType = 'APP',
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class LoginResponse {
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool success;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? message;

  final String? token;
  final int? id;
  final String? username;
  final String? phone;
  final String? email;
  final List<String>? roles;
  final String? nickname;
  final String? avatar;
  final bool? admin;

  LoginResponse({
    this.success = true,
    this.message,
    this.token,
    this.id,
    this.username,
    this.phone,
    this.email,
    this.roles,
    this.nickname,
    this.avatar,
    this.admin,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}

@JsonSerializable()
class RegisterRequest {
  final String username;
  final String password;
  final String phone;
  final String role;

  RegisterRequest({
    required this.username,
    required this.password,
    required this.phone,
    required this.role,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

@JsonSerializable()
class RegisterResponse {
  final int id;
  final String username;
  final String phone;
  final String role;
  final String? message;
  final DateTime createTime;

  RegisterResponse({
    required this.id,
    required this.username,
    required this.phone,
    required this.role,
    this.message,
    required this.createTime,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      _$RegisterResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterResponseToJson(this);
}

@JsonSerializable()
class UpdateUserRequest {
  final String? username;
  final String? nickname;
  final String? phone;
  final String? email;
  final String? avatar;

  UpdateUserRequest({
    this.username,
    this.nickname,
    this.phone,
    this.email,
    this.avatar,
  });

  factory UpdateUserRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateUserRequestToJson(this);
}

class PasswordUpdateRequest {
  final String oldPassword;
  final String newPassword;

  const PasswordUpdateRequest({
    required this.oldPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      };
}
