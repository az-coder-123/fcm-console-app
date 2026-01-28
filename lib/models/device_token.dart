import 'package:json_annotation/json_annotation.dart';

part 'device_token.g.dart';

/// Represents a device token fetched from Supabase
@JsonSerializable()
class DeviceToken {
  final String token;
  final String? userId;
  final String? platform;
  final DateTime? lastActive;

  DeviceToken({
    required this.token,
    this.userId,
    this.platform,
    this.lastActive,
  });

  factory DeviceToken.fromJson(Map<String, dynamic> json) =>
      _$DeviceTokenFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceTokenToJson(this);

  DeviceToken copyWith({
    String? token,
    String? userId,
    String? platform,
    DateTime? lastActive,
  }) {
    return DeviceToken(
      token: token ?? this.token,
      userId: userId ?? this.userId,
      platform: platform ?? this.platform,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
