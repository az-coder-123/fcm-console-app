// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceToken _$DeviceTokenFromJson(Map<String, dynamic> json) => DeviceToken(
  token: json['token'] as String,
  userId: json['userId'] as String?,
  platform: json['platform'] as String?,
  lastActive: json['lastActive'] == null
      ? null
      : DateTime.parse(json['lastActive'] as String),
);

Map<String, dynamic> _$DeviceTokenToJson(DeviceToken instance) =>
    <String, dynamic>{
      'token': instance.token,
      'userId': instance.userId,
      'platform': instance.platform,
      'lastActive': instance.lastActive?.toIso8601String(),
    };
