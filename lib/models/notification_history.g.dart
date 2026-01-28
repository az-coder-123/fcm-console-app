// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationHistory _$NotificationHistoryFromJson(Map<String, dynamic> json) =>
    NotificationHistory(
      id: (json['id'] as num).toInt(),
      serviceAccountId: (json['serviceAccountId'] as num).toInt(),
      title: json['title'] as String,
      body: json['body'] as String,
      imageUrl: json['imageUrl'] as String?,
      data: json['data'] as Map<String, dynamic>,
      targetTokens: (json['targetTokens'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      topic: json['topic'] as String?,
      status: json['status'] as String,
      errorMessage: json['errorMessage'] as String?,
      sentAt: DateTime.parse(json['sentAt'] as String),
    );

Map<String, dynamic> _$NotificationHistoryToJson(
  NotificationHistory instance,
) => <String, dynamic>{
  'id': instance.id,
  'serviceAccountId': instance.serviceAccountId,
  'title': instance.title,
  'body': instance.body,
  'imageUrl': instance.imageUrl,
  'data': instance.data,
  'targetTokens': instance.targetTokens,
  'topic': instance.topic,
  'status': instance.status,
  'errorMessage': instance.errorMessage,
  'sentAt': instance.sentAt.toIso8601String(),
};
