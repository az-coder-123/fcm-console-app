// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceAccount _$ServiceAccountFromJson(Map<String, dynamic> json) =>
    ServiceAccount(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      filePath: json['filePath'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ServiceAccountToJson(ServiceAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'filePath': instance.filePath,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
