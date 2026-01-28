/// Service Account Profile model.
library;

/// Represents a Firebase Service Account profile.
class ServiceAccountProfile {
  /// Creates a new [ServiceAccountProfile].
  const ServiceAccountProfile({
    required this.id,
    required this.name,
    required this.projectId,
    required this.clientEmail,
    required this.jsonPath,
    required this.createdAt,
    this.isActive = false,
  });

  /// Creates a [ServiceAccountProfile] from a database row.
  factory ServiceAccountProfile.fromMap(Map<String, dynamic> map) {
    return ServiceAccountProfile(
      id: map['id'] as int,
      name: map['name'] as String,
      projectId: map['project_id'] as String,
      clientEmail: map['client_email'] as String,
      jsonPath: map['json_path'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      isActive: (map['is_active'] as int) == 1,
    );
  }

  /// Unique identifier for the profile.
  final int id;

  /// Display name for the profile.
  final String name;

  /// Firebase project ID extracted from the Service Account.
  final String projectId;

  /// Client email from the Service Account.
  final String clientEmail;

  /// Path to the Service Account JSON file.
  final String jsonPath;

  /// Timestamp when the profile was created.
  final DateTime createdAt;

  /// Whether this profile is currently active.
  final bool isActive;

  /// Converts this profile to a database row.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'project_id': projectId,
      'client_email': clientEmail,
      'json_path': jsonPath,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  /// Creates a copy of this profile with the specified changes.
  ServiceAccountProfile copyWith({
    int? id,
    String? name,
    String? projectId,
    String? clientEmail,
    String? jsonPath,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return ServiceAccountProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      projectId: projectId ?? this.projectId,
      clientEmail: clientEmail ?? this.clientEmail,
      jsonPath: jsonPath ?? this.jsonPath,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() =>
      'ServiceAccountProfile(name: $name, project: $projectId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceAccountProfile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
