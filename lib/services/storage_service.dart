import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants.dart';

/// Service for secure storage of sensitive data
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Active Service Account

  Future<void> setActiveServiceAccountId(int? id) async {
    if (id == null) {
      await _storage.delete(key: AppConstants.keyActiveServiceAccountId);
    } else {
      await _storage.write(
        key: AppConstants.keyActiveServiceAccountId,
        value: id.toString(),
      );
    }
  }

  Future<int?> getActiveServiceAccountId() async {
    final value = await _storage.read(
      key: AppConstants.keyActiveServiceAccountId,
    );
    if (value == null) return null;
    return int.tryParse(value);
  }

  // Supabase Configuration

  Future<void> setSupabaseUrl(String url) async {
    await _storage.write(
      key: '${AppConstants.keySupabaseUrl}_${_getCurrentServiceAccountId()}',
      value: url,
    );
  }

  Future<String?> getSupabaseUrl() async {
    return await _storage.read(
      key: '${AppConstants.keySupabaseUrl}_${_getCurrentServiceAccountId()}',
    );
  }

  Future<void> setSupabaseKey(String key) async {
    await _storage.write(
      key: '${AppConstants.keySupabaseKey}_${_getCurrentServiceAccountId()}',
      value: key,
    );
  }

  Future<String?> getSupabaseKey() async {
    return await _storage.read(
      key: '${AppConstants.keySupabaseKey}_${_getCurrentServiceAccountId()}',
    );
  }

  Future<void> clearSupabaseConfig() async {
    final serviceAccountId = await getActiveServiceAccountId();
    if (serviceAccountId != null) {
      await _storage.delete(
        key: '${AppConstants.keySupabaseUrl}_$serviceAccountId',
      );
      await _storage.delete(
        key: '${AppConstants.keySupabaseKey}_$serviceAccountId',
      );
    }
  }

  Future<void> clearAllData() async {
    await _storage.deleteAll();
  }

  Future<String?> _getCurrentServiceAccountId() async {
    final id = await getActiveServiceAccountId();
    return id?.toString();
  }
}
