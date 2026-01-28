/// Notification History model.
library;

/// Represents a notification send history record.
class NotificationHistory {
  /// Creates a new [NotificationHistory].
  const NotificationHistory({
    required this.id,
    required this.serviceAccountId,
    required this.title,
    required this.body,
    required this.targetType,
    required this.targets,
    required this.status,
    required this.timestamp,
    this.imageUrl,
    this.data,
    this.errorMessage,
  });

  /// Creates a [NotificationHistory] from a database row.
  factory NotificationHistory.fromMap(Map<String, dynamic> map) {
    return NotificationHistory(
      id: map['id'] as int,
      serviceAccountId: map['service_account_id'] as int,
      title: map['title'] as String,
      body: map['body'] as String,
      targetType: NotificationTargetType.fromString(
        map['target_type'] as String,
      ),
      targets: (map['targets'] as String).split(','),
      status: NotificationStatus.fromString(map['status'] as String),
      timestamp: DateTime.parse(map['timestamp'] as String),
      imageUrl: map['image_url'] as String?,
      data: map['data'] as String?,
      errorMessage: map['error_message'] as String?,
    );
  }

  /// Unique identifier.
  final int id;

  /// ID of the Service Account used.
  final int serviceAccountId;

  /// Notification title.
  final String title;

  /// Notification body.
  final String body;

  /// Type of target (device tokens or topic).
  final NotificationTargetType targetType;

  /// List of target tokens or topic name.
  final List<String> targets;

  /// Send status.
  final NotificationStatus status;

  /// Timestamp when the notification was sent.
  final DateTime timestamp;

  /// Optional image URL.
  final String? imageUrl;

  /// Optional data payload as JSON string.
  final String? data;

  /// Error message if failed.
  final String? errorMessage;

  /// Converts this history to a database row.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service_account_id': serviceAccountId,
      'title': title,
      'body': body,
      'target_type': targetType.value,
      'targets': targets.join(','),
      'status': status.value,
      'timestamp': timestamp.toIso8601String(),
      'image_url': imageUrl,
      'data': data,
      'error_message': errorMessage,
    };
  }

  /// Creates a copy with the specified changes.
  NotificationHistory copyWith({
    int? id,
    int? serviceAccountId,
    String? title,
    String? body,
    NotificationTargetType? targetType,
    List<String>? targets,
    NotificationStatus? status,
    DateTime? timestamp,
    String? imageUrl,
    String? data,
    String? errorMessage,
  }) {
    return NotificationHistory(
      id: id ?? this.id,
      serviceAccountId: serviceAccountId ?? this.serviceAccountId,
      title: title ?? this.title,
      body: body ?? this.body,
      targetType: targetType ?? this.targetType,
      targets: targets ?? this.targets,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Type of notification target.
enum NotificationTargetType {
  /// Send to specific device tokens.
  token('token'),

  /// Send to a topic.
  topic('topic');

  const NotificationTargetType(this.value);

  /// Creates from string value.
  factory NotificationTargetType.fromString(String value) {
    return NotificationTargetType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationTargetType.token,
    );
  }

  /// String value for database storage.
  final String value;
}

/// Status of a notification send.
enum NotificationStatus {
  /// Notification sent successfully.
  success('success'),

  /// Notification partially sent (some tokens failed).
  partial('partial'),

  /// Notification failed to send.
  failed('failed');

  const NotificationStatus(this.value);

  /// Creates from string value.
  factory NotificationStatus.fromString(String value) {
    return NotificationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationStatus.failed,
    );
  }

  /// String value for database storage.
  final String value;
}
