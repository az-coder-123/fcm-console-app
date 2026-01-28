/// Utility functions for JSON parsing and handling.
library;

import 'dart:convert';
import 'dart:io';

/// Parses a Firebase Service Account JSON file.
class ServiceAccountParser {
  ServiceAccountParser._();

  /// Parses a Service Account JSON file and returns a map.
  ///
  /// Throws [FormatException] if the file is not valid JSON.
  /// Throws [FileSystemException] if the file cannot be read.
  static Future<Map<String, dynamic>> parseFromFile(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }

    final content = await file.readAsString();
    return parseFromString(content);
  }

  /// Parses a Service Account JSON string and returns a map.
  ///
  /// Throws [FormatException] if the string is not valid JSON.
  static Map<String, dynamic> parseFromString(String jsonString) {
    try {
      final decoded = json.decode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid JSON structure');
      }
      return decoded;
    } on FormatException {
      rethrow;
    }
  }

  /// Validates that the JSON contains required Service Account fields.
  static bool isValidServiceAccount(Map<String, dynamic> json) {
    final requiredFields = [
      'type',
      'project_id',
      'private_key_id',
      'private_key',
      'client_email',
      'client_id',
    ];

    for (final field in requiredFields) {
      if (!json.containsKey(field) || json[field] == null) {
        return false;
      }
    }

    return json['type'] == 'service_account';
  }

  /// Extracts the project ID from a Service Account JSON.
  static String? getProjectId(Map<String, dynamic> json) {
    return json['project_id'] as String?;
  }

  /// Extracts the client email from a Service Account JSON.
  static String? getClientEmail(Map<String, dynamic> json) {
    return json['client_email'] as String?;
  }
}
