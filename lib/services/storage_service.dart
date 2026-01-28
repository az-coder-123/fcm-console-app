import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

import '../core/constants.dart';

/// Service for storing application configuration and settings using JSON file storage
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final Map<String, String> _cache = {};
  String? _filePath;
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final dir = await getApplicationSupportDirectory();
      _filePath = join(dir.path, 'app_storage.json');
      final file = File(_filePath!);
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);
        data.forEach((k, v) {
          _cache[k] = v.toString();
        });
        debugPrint(
          '[StorageService] Loaded ${_cache.length} items from storage',
        );
      }
    } catch (e) {
      debugPrint('[StorageService] Error loading storage: $e');
      debugPrintStack(stackTrace: StackTrace.current);
    }
    _loaded = true;
  }

  Future<void> _save() async {
    try {
      if (_filePath == null) {
        final dir = await getApplicationSupportDirectory();
        _filePath = join(dir.path, 'app_storage.json');
      }
      final file = File(_filePath!);
      await file.writeAsString(jsonEncode(_cache));
      debugPrint('[StorageService] Saved ${_cache.length} items to storage');
    } catch (e) {
      debugPrint('[StorageService] Error saving storage: $e');
      debugPrintStack(stackTrace: StackTrace.current);
    }
  }

  // Helper methods for read/write/delete operations
  Future<void> _write(String key, String value) async {
    try {
      await _ensureLoaded();
      _cache[key] = value;
      await _save();
    } catch (e) {
      debugPrint('[StorageService] Error writing $key: $e');
      debugPrintStack(stackTrace: StackTrace.current);
    }
  }

  Future<String?> _read(String key) async {
    try {
      await _ensureLoaded();
      return _cache[key];
    } catch (e) {
      debugPrint('[StorageService] Error reading $key: $e');
      debugPrintStack(stackTrace: StackTrace.current);
      return null;
    }
  }

  Future<void> _delete(String key) async {
    try {
      await _ensureLoaded();
      _cache.remove(key);
      await _save();
    } catch (e) {
      debugPrint('[StorageService] Error deleting $key: $e');
      debugPrintStack(stackTrace: StackTrace.current);
    }
  }

  Future<void> _deleteAll() async {
    try {
      await _ensureLoaded();
      _cache.clear();
      await _save();
    } catch (e) {
      debugPrint('[StorageService] Error clearing storage: $e');
      debugPrintStack(stackTrace: StackTrace.current);
    }
  }

  // Active Service Account

  Future<void> setActiveServiceAccountId(int? id) async {
    if (id == null) {
      await _delete(AppConstants.keyActiveServiceAccountId);
    } else {
      await _write(AppConstants.keyActiveServiceAccountId, id.toString());
    }
  }

  Future<int?> getActiveServiceAccountId() async {
    final value = await _read(AppConstants.keyActiveServiceAccountId);
    if (value == null) return null;
    return int.tryParse(value);
  }

  // Supabase Configuration

  Future<void> setSupabaseUrl(String url) async {
    final key =
        '${AppConstants.keySupabaseUrl}_${await _getCurrentServiceAccountId()}';
    await _write(key, url);
  }

  Future<String?> getSupabaseUrl() async {
    final key =
        '${AppConstants.keySupabaseUrl}_${await _getCurrentServiceAccountId()}';
    return await _read(key);
  }

  Future<void> setSupabaseKey(String key) async {
    final k =
        '${AppConstants.keySupabaseKey}_${await _getCurrentServiceAccountId()}';
    await _write(k, key);
  }

  Future<String?> getSupabaseKey() async {
    final k =
        '${AppConstants.keySupabaseKey}_${await _getCurrentServiceAccountId()}';
    return await _read(k);
  }

  Future<void> clearSupabaseConfig() async {
    final serviceAccountId = await getActiveServiceAccountId();
    if (serviceAccountId != null) {
      await _delete('${AppConstants.keySupabaseUrl}_$serviceAccountId');
      await _delete('${AppConstants.keySupabaseKey}_$serviceAccountId');
    }
  }

  Future<void> clearAllData() async {
    await _deleteAll();
  }

  Future<String?> _getCurrentServiceAccountId() async {
    final id = await getActiveServiceAccountId();
    return id?.toString();
  }
}
