import 'package:json_annotation/json_annotation.dart';

part 'service_account.g.dart';

/// Represents a Firebase Service Account profile
/// Each profile corresponds to a specific project context
@JsonSerializable()
class ServiceAccount {
  final int id;
  final String name;
  final String filePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceAccount({
    required this.id,
    required this.name,
    required this.filePath,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceAccount.fromJson(Map<String, dynamic> json) =>
      _$ServiceAccountFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceAccountToJson(this);

  ServiceAccount copyWith({
    int? id,
    String? name,
    String? filePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
