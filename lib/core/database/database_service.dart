/// Database service for local data persistence using SQLite.
library;

import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../constants/app_constants.dart';
import '../models/models.dart';

/// Service for managing local SQLite database operations.
class DatabaseService {
  DatabaseService._();

  static DatabaseService? _instance;
  static Database? _database;

  /// Gets the singleton instance.
  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  /// Initializes the database.
  Future<void> initialize() async {
    if (_database != null) return;

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final appDir = await getApplicationSupportDirectory();
    final dbPath = '${appDir.path}/${DatabaseConstants.databaseName}';

    _database = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: DatabaseConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  /// Gets the database instance.
  Database get db {
    if (_database == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  /// Creates database tables.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE service_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        project_id TEXT NOT NULL,
        client_email TEXT NOT NULL,
        json_path TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE notification_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        service_account_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        target_type TEXT NOT NULL,
        targets TEXT NOT NULL,
        status TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        image_url TEXT,
        data TEXT,
        error_message TEXT,
        FOREIGN KEY (service_account_id) REFERENCES service_accounts(id)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_history_service_account 
      ON notification_history(service_account_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_history_timestamp 
      ON notification_history(timestamp DESC)
    ''');
  }

  /// Handles database upgrades.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations here.
  }

  /// Closes the database.
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

/// Repository for Service Account operations.
class ServiceAccountRepository {
  ServiceAccountRepository(this._db);

  final Database _db;

  /// Gets all service accounts.
  Future<List<ServiceAccountProfile>> getAll() async {
    final rows = await _db.query(
      'service_accounts',
      orderBy: 'created_at DESC',
    );
    return rows.map(ServiceAccountProfile.fromMap).toList();
  }

  /// Gets the currently active service account.
  Future<ServiceAccountProfile?> getActive() async {
    final rows = await _db.query(
      'service_accounts',
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ServiceAccountProfile.fromMap(rows.first);
  }

  /// Gets a service account by ID.
  Future<ServiceAccountProfile?> getById(int id) async {
    final rows = await _db.query(
      'service_accounts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ServiceAccountProfile.fromMap(rows.first);
  }

  /// Inserts a new service account.
  Future<int> insert({
    required String name,
    required String projectId,
    required String clientEmail,
    required String jsonPath,
  }) async {
    return _db.insert('service_accounts', {
      'name': name,
      'project_id': projectId,
      'client_email': clientEmail,
      'json_path': jsonPath,
      'created_at': DateTime.now().toIso8601String(),
      'is_active': 0,
    });
  }

  /// Sets a service account as active (deactivates others).
  Future<void> setActive(int id) async {
    await _db.transaction((txn) async {
      await txn.update('service_accounts', {'is_active': 0});
      await txn.update(
        'service_accounts',
        {'is_active': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// Deletes a service account.
  Future<void> delete(int id) async {
    await _db.transaction((txn) async {
      await txn.delete(
        'notification_history',
        where: 'service_account_id = ?',
        whereArgs: [id],
      );
      await txn.delete('service_accounts', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Updates a service account name.
  Future<void> updateName(int id, String name) async {
    await _db.update(
      'service_accounts',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

/// Repository for Notification History operations.
class NotificationHistoryRepository {
  NotificationHistoryRepository(this._db);

  final Database _db;

  /// Gets all history for a service account.
  Future<List<NotificationHistory>> getByServiceAccount(
    int serviceAccountId, {
    int limit = 100,
    int offset = 0,
  }) async {
    final rows = await _db.query(
      'notification_history',
      where: 'service_account_id = ?',
      whereArgs: [serviceAccountId],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(NotificationHistory.fromMap).toList();
  }

  /// Inserts a new history record.
  Future<int> insert(NotificationHistory history) async {
    final map = history.toMap();
    map.remove('id');
    return _db.insert('notification_history', map);
  }

  /// Deletes a history record.
  Future<void> delete(int id) async {
    await _db.delete('notification_history', where: 'id = ?', whereArgs: [id]);
  }

  /// Clears all history for a service account.
  Future<void> clearByServiceAccount(int serviceAccountId) async {
    await _db.delete(
      'notification_history',
      where: 'service_account_id = ?',
      whereArgs: [serviceAccountId],
    );
  }

  /// Gets the count of history records for a service account.
  Future<int> getCount(int serviceAccountId) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM notification_history WHERE service_account_id = ?',
      [serviceAccountId],
    );
    final count = result.first['count'];
    if (count is int) return count;
    return 0;
  }
}
