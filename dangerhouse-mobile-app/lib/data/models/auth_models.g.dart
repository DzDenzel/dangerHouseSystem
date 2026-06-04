// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
      account: json['account'] as String,
      password: json['password'] as String,
      rememberMe: json['rememberMe'] as bool? ?? false,
      clientType: json['clientType'] as String? ?? 'APP',
    );

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'account': instance.account,
      'password': instance.password,
      'rememberMe': instance.rememberMe,
      'clientType': instance.clientType,
    };

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    LoginResponse(
      token: json['token'] as String?,
      id: (json['id'] as num?)?.toInt(),
      username: json['username'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      roles:
          (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList(),
      nickname: json['nickname'] as String?,
      avatar: json['avatar'] as String?,
      admin: json['admin'] as bool?,
    );

Map<String, dynamic> _$LoginResponseToJson(LoginResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'id': instance.id,
      'username': instance.username,
      'phone': instance.phone,
      'email': instance.email,
      'roles': instance.roles,
      'nickname': instance.nickname,
      'avatar': instance.avatar,
      'admin': instance.admin,
    };

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      username: json['username'] as String,
      password: json['password'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
      'phone': instance.phone,
      'role': instance.role,
    };

RegisterResponse _$RegisterResponseFromJson(Map<String, dynamic> json) =>
    RegisterResponse(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      message: json['message'] as String?,
      createTime: DateTime.parse(json['createTime'] as String),
    );

Map<String, dynamic> _$RegisterResponseToJson(RegisterResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'phone': instance.phone,
      'role': instance.role,
      'message': instance.message,
      'createTime': instance.createTime.toIso8601String(),
    };

UpdateUserRequest _$UpdateUserRequestFromJson(Map<String, dynamic> json) =>
    UpdateUserRequest(
      username: json['username'] as String?,
      nickname: json['nickname'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      avatar: json['avatar'] as String?,
    );

Map<String, dynamic> _$UpdateUserRequestToJson(UpdateUserRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'nickname': instance.nickname,
      'phone': instance.phone,
      'email': instance.email,
      'avatar': instance.avatar,
    };
