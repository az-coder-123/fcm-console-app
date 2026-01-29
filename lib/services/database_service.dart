import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/constants.dart';
import '../models/notification_history.dart';
import '../models/service_account.dart';

/// Service for managing local SQLite database
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI-based sqflite on desktop platforms and set the global factory
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final Directory appDocDir = await getApplicationSupportDirectory();
    final String dbPath = join(appDocDir.path, AppConstants.databaseName);

    return await openDatabase(
      dbPath,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create service_accounts table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableServiceAccounts} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create notification_history table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableNotificationHistory} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        service_account_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        image_url TEXT,
        data TEXT NOT NULL,
        target_tokens TEXT NOT NULL,
        topic TEXT,
        status TEXT NOT NULL,
        error_message TEXT,
        sent_at INTEGER NOT NULL,
        FOREIGN KEY (service_account_id) REFERENCES ${AppConstants.tableServiceAccounts} (id)
      )
    ''');

    // Create indexes for better query performance
    await db.execute('''
      CREATE INDEX idx_notification_service_account 
      ON ${AppConstants.tableNotificationHistory} (service_account_id)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration: Add json_content column to service_accounts table
    if (oldVersion < 2) {
      try {
        await db.execute('''
          ALTER TABLE ${AppConstants.tableServiceAccounts}
          ADD COLUMN json_content TEXT
        ''');
      } catch (e) {
        // Column might already exist
        debugPrint('Migration error (can be ignored if column exists): $e');
      }
    }
  }

  // Service Account Operations

  Future<int> createServiceAccount(ServiceAccount account) async {
    final db = await database;
    return await db.insert(AppConstants.tableServiceAccounts, {
      'name': account.name,
      'file_path': account.filePath,
      'json_content': account.jsonContent,
      'created_at': account.createdAt.millisecondsSinceEpoch,
      'updated_at': account.updatedAt.millisecondsSinceEpoch,
    });
  }

  Future<List<ServiceAccount>> getAllServiceAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableServiceAccounts,
      orderBy: 'updated_at DESC',
    );

    return List.generate(maps.length, (i) {
      return ServiceAccount(
        id: maps[i]['id'],
        name: maps[i]['name'],
        filePath: maps[i]['file_path'],
        jsonContent: maps[i]['json_content'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(maps[i]['created_at']),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(maps[i]['updated_at']),
      );
    });
  }

  Future<ServiceAccount?> getServiceAccount(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableServiceAccounts,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return ServiceAccount(
      id: maps[0]['id'],
      name: maps[0]['name'],
      filePath: maps[0]['file_path'],
      jsonContent: maps[0]['json_content'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(maps[0]['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(maps[0]['updated_at']),
    );
  }

  Future<int> updateServiceAccount(ServiceAccount account) async {
    final db = await database;
    return await db.update(
      AppConstants.tableServiceAccounts,
      {
        'name': account.name,
        'file_path': account.filePath,
        'json_content': account.jsonContent,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteServiceAccount(int id) async {
    final db = await database;
    // Also delete associated notification history
    await db.delete(
      AppConstants.tableNotificationHistory,
      where: 'service_account_id = ?',
      whereArgs: [id],
    );
    return await db.delete(
      AppConstants.tableServiceAccounts,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Notification History Operations

  Future<int> createNotificationHistory(NotificationHistory history) async {
    final db = await database;
    return await db.insert(AppConstants.tableNotificationHistory, {
      'service_account_id': history.serviceAccountId,
      'title': history.title,
      'body': history.body,
      'image_url': history.imageUrl,
      'data': _encodeMap(history.data),
      'target_tokens': _encodeList(history.targetTokens),
      'topic': history.topic,
      'status': history.status,
      'error_message': history.errorMessage,
      'sent_at': history.sentAt.millisecondsSinceEpoch,
    });
  }

  Future<List<NotificationHistory>> getNotificationHistory(
    int serviceAccountId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableNotificationHistory,
      where: 'service_account_id = ?',
      whereArgs: [serviceAccountId],
      orderBy: 'sent_at DESC',
    );

    return List.generate(maps.length, (i) {
      return NotificationHistory(
        id: maps[i]['id'],
        serviceAccountId: maps[i]['service_account_id'],
        title: maps[i]['title'],
        body: maps[i]['body'],
        imageUrl: maps[i]['image_url'],
        data: _decodeMap(maps[i]['data']),
        targetTokens: _decodeList(maps[i]['target_tokens']),
        topic: maps[i]['topic'],
        status: maps[i]['status'],
        errorMessage: maps[i]['error_message'],
        sentAt: DateTime.fromMillisecondsSinceEpoch(maps[i]['sent_at']),
      );
    });
  }

  Future<int> deleteNotificationHistory(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.tableNotificationHistory,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearNotificationHistory(int serviceAccountId) async {
    final db = await database;
    return await db.delete(
      AppConstants.tableNotificationHistory,
      where: 'service_account_id = ?',
      whereArgs: [serviceAccountId],
    );
  }

  // Helper methods for encoding/decoding complex types

  String _encodeMap(Map<String, dynamic> map) {
    return map.entries.map((e) => '${e.key}:${e.value}').join(',');
  }

  Map<String, dynamic> _decodeMap(String encoded) {
    if (encoded.isEmpty) return {};
    return Map.fromEntries(
      encoded.split(',').map((e) {
        final parts = e.split(':');
        return MapEntry(parts[0], parts[1]);
      }),
    );
  }

  String _encodeList(List<String> list) {
    return list.join(',');
  }

  List<String> _decodeList(String encoded) {
    if (encoded.isEmpty) return [];
    return encoded.split(',');
  }

  /// Recover service account content for records with missing json_content
  /// This handles backward compatibility for service accounts created before the json_content column
  Future<void> recoverServiceAccountContent(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        AppConstants.tableServiceAccounts,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        debugPrint('Service account not found: $id');
        return;
      }

      final filePath = maps[0]['file_path'];
      final existingContent = maps[0]['json_content'];

      // If content already exists, skip recovery
      if (existingContent != null && (existingContent as String).isNotEmpty) {
        debugPrint('Service account already has json_content: $id');
        return;
      }

      // Try to read from the stored file path
      final file = File(filePath);
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          // Validate it's valid JSON
          jsonDecode(content);

          // Save the content to the database
          await db.update(
            AppConstants.tableServiceAccounts,
            {'json_content': content},
            where: 'id = ?',
            whereArgs: [id],
          );

          debugPrint('Recovered json_content for service account: $id');
        } catch (e) {
          debugPrint('Failed to recover content from file: $e');
        }
      } else {
        debugPrint('Service account file not found: $filePath');
      }
    } catch (e) {
      debugPrint('Error recovering service account content: $e');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
