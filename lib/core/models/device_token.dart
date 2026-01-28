/// Device Token model.
library;

/// Represents a device token fetched from Supabase.
class DeviceToken {
  /// Creates a new [DeviceToken].
  const DeviceToken({
    required this.id,
    required this.token,
    this.userId,
    this.platform,
    this.createdAt,
    this.updatedAt,
    this.isSelected = false,
  });

  /// Creates a [DeviceToken] from a Supabase row.
  factory DeviceToken.fromMap(Map<String, dynamic> map) {
    return DeviceToken(
      id: map['id']?.toString() ?? '',
      token: map['token'] as String? ?? map['device_token'] as String? ?? '',
      userId: map['user_id'] as String?,
      platform: map['platform'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }

  /// Unique identifier.
  final String id;

  /// FCM device token.
  final String token;

  /// Optional user ID associated with this token.
  final String? userId;

  /// Platform (android, ios, web).
  final String? platform;

  /// When the token was created.
  final DateTime? createdAt;

  /// When the token was last updated.
  final DateTime? updatedAt;

  /// Whether this token is selected for sending.
  final bool isSelected;

  /// Creates a copy with the specified changes.
  DeviceToken copyWith({
    String? id,
    String? token,
    String? userId,
    String? platform,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSelected,
  }) {
    return DeviceToken(
      id: id ?? this.id,
      token: token ?? this.token,
      userId: userId ?? this.userId,
      platform: platform ?? this.platform,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  String toString() =>
      'DeviceToken(id: $id, token: ${token.substring(0, 20)}...)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceToken &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
