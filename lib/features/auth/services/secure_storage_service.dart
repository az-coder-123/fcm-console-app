/// Secure storage service for sensitive data.
library;

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/models.dart';

/// Service for secure storage of sensitive credentials.
class SecureStorageService {
  SecureStorageService._();

  static SecureStorageService? _instance;
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Gets the singleton instance.
  static SecureStorageService get instance {
    _instance ??= SecureStorageService._();
    return _instance!;
  }

  /// Saves Supabase config for a profile.
  Future<void> saveSupabaseConfig(int profileId, SupabaseConfig config) async {
    final key = '${StorageKeys.supabaseConfigPrefix}$profileId';
    await _storage.write(key: key, value: json.encode(config.toMap()));
  }

  /// Gets Supabase config for a profile.
  Future<SupabaseConfig?> getSupabaseConfig(int profileId) async {
    final key = '${StorageKeys.supabaseConfigPrefix}$profileId';
    final value = await _storage.read(key: key);

    if (value == null) return null;

    try {
      final map = json.decode(value) as Map<String, dynamic>;
      return SupabaseConfig.fromMap(map);
    } on FormatException {
      return null;
    }
  }

  /// Deletes Supabase config for a profile.
  Future<void> deleteSupabaseConfig(int profileId) async {
    final key = '${StorageKeys.supabaseConfigPrefix}$profileId';
    await _storage.delete(key: key);
  }

  /// Saves Service Account JSON content securely.
  Future<void> saveServiceAccountJson(int profileId, String jsonContent) async {
    final key = 'service_account_json_$profileId';
    await _storage.write(key: key, value: jsonContent);
  }

  /// Gets Service Account JSON content.
  Future<String?> getServiceAccountJson(int profileId) async {
    final key = 'service_account_json_$profileId';
    return _storage.read(key: key);
  }

  /// Deletes Service Account JSON content.
  Future<void> deleteServiceAccountJson(int profileId) async {
    final key = 'service_account_json_$profileId';
    await _storage.delete(key: key);
  }

  /// Clears all stored data.
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
