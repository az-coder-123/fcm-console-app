/// Represents a device token fetched from Supabase
class DeviceToken {
  final String token;
  final String? userId;
  final String? platform;
  final DateTime? lastActive;
  final DateTime? createdAt;

  DeviceToken({
    required this.token,
    this.userId,
    this.platform,
    this.lastActive,
    this.createdAt,
  });

  /// Manual fromJson to handle different key formats from Supabase (snake_case or camelCase)
  factory DeviceToken.fromJson(Map<String, dynamic> json) {
    String token = (json['token'] ?? json['token'] as String) as String;
    final userId = json['userId'] ?? json['user_id'] as String?;
    final platform = json['platform'] as String?;

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    final lastActive = parseDate(json['lastActive'] ?? json['last_active']);
    final createdAt = parseDate(json['createdAt'] ?? json['created_at']);

    return DeviceToken(
      token: token,
      userId: userId,
      platform: platform,
      lastActive: lastActive,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'token': token,
    'userId': userId,
    'platform': platform,
    'lastActive': lastActive?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
  };

  DeviceToken copyWith({
    String? token,
    String? userId,
    String? platform,
    DateTime? lastActive,
    DateTime? createdAt,
  }) {
    return DeviceToken(
      token: token ?? this.token,
      userId: userId ?? this.userId,
      platform: platform ?? this.platform,
      lastActive: lastActive ?? this.lastActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
