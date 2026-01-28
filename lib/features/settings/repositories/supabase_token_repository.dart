/// Repository for fetching device tokens from Supabase.
library;

import 'package:supabase/supabase.dart';

import '../../../core/models/models.dart';
import '../../../core/utils/exceptions.dart';

/// Repository for interacting with Supabase to fetch device tokens.
class SupabaseTokenRepository {
  SupabaseTokenRepository._();

  static SupabaseClient? _client;
  static SupabaseConfig? _currentConfig;

  /// Initializes the Supabase client with the given config.
  static void initialize(SupabaseConfig config) {
    if (_currentConfig != null &&
        _currentConfig!.url == config.url &&
        _currentConfig!.anonKey == config.anonKey) {
      return;
    }

    _currentConfig = config;
    _client = SupabaseClient(config.url, config.anonKey);
  }

  /// Gets the current Supabase client.
  static SupabaseClient? get client => _client;

  /// Checks if the client is initialized.
  static bool get isInitialized => _client != null;

  /// Resets the client (for profile switching).
  static void reset() {
    _client?.dispose();
    _client = null;
    _currentConfig = null;
  }

  /// Fetches all device tokens from the configured table.
  static Future<List<DeviceToken>> fetchTokens({
    int limit = 1000,
    int offset = 0,
  }) async {
    if (_client == null || _currentConfig == null) {
      throw SupabaseException('Supabase not initialized. Configure first.');
    }

    try {
      final response = await _client!
          .from(_currentConfig!.tableName)
          .select()
          .range(offset, offset + limit - 1);

      return (response as List<dynamic>)
          .map((e) => DeviceToken.fromMap(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw SupabaseException('Failed to fetch tokens: ${e.message}');
    } on Exception catch (e) {
      throw SupabaseException('Unexpected error: $e');
    }
  }

  /// Fetches device tokens with a custom query.
  static Future<List<DeviceToken>> fetchTokensWithFilter({
    required String column,
    required dynamic value,
    int limit = 1000,
  }) async {
    if (_client == null || _currentConfig == null) {
      throw SupabaseException('Supabase not initialized. Configure first.');
    }

    try {
      final response = await _client!
          .from(_currentConfig!.tableName)
          .select()
          .eq(column, value)
          .limit(limit);

      return (response as List<dynamic>)
          .map((e) => DeviceToken.fromMap(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw SupabaseException('Failed to fetch tokens: ${e.message}');
    }
  }

  /// Gets the total count of tokens.
  static Future<int> getTokenCount() async {
    if (_client == null || _currentConfig == null) {
      throw SupabaseException('Supabase not initialized. Configure first.');
    }

    try {
      final response = await _client!
          .from(_currentConfig!.tableName)
          .select('id')
          .count(CountOption.exact);

      return response.count;
    } on PostgrestException catch (e) {
      throw SupabaseException('Failed to get token count: ${e.message}');
    }
  }

  /// Tests the Supabase connection.
  static Future<bool> testConnection(SupabaseConfig config) async {
    try {
      final testClient = SupabaseClient(config.url, config.anonKey);

      await testClient.from(config.tableName).select().limit(1);

      testClient.dispose();
      return true;
    } on Exception {
      return false;
    }
  }
}
