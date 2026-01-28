import 'package:json_annotation/json_annotation.dart';

part 'notification_history.g.dart';

/// Represents a history entry of sent notifications
/// History is tied to the specific Service Account currently active
@JsonSerializable()
class NotificationHistory {
  final int id;
  final int serviceAccountId;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic> data;
  final List<String> targetTokens;
  final String? topic;
  final String status; // 'success', 'failed'
  final String? errorMessage;
  final DateTime sentAt;

  NotificationHistory({
    required this.id,
    required this.serviceAccountId,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.data,
    required this.targetTokens,
    this.topic,
    required this.status,
    this.errorMessage,
    required this.sentAt,
  });

  factory NotificationHistory.fromJson(Map<String, dynamic> json) =>
      _$NotificationHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationHistoryToJson(this);

  NotificationHistory copyWith({
    int? id,
    int? serviceAccountId,
    String? title,
    String? body,
    String? imageUrl,
    Map<String, dynamic>? data,
    List<String>? targetTokens,
    String? topic,
    String? status,
    String? errorMessage,
    DateTime? sentAt,
  }) {
    return NotificationHistory(
      id: id ?? this.id,
      serviceAccountId: serviceAccountId ?? this.serviceAccountId,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      targetTokens: targetTokens ?? this.targetTokens,
      topic: topic ?? this.topic,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      sentAt: sentAt ?? this.sentAt,
    );
  }
}
