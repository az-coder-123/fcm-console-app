import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/device_token.dart';

/// Service for Supabase integration
/// Fetches device tokens from Supabase database
class SupabaseService {
  final Logger _logger = Logger();
  SupabaseClient? _client;

  /// Initialize Supabase client with provided credentials
  Future<void> initialize(String url, String key) async {
    try {
      // If Supabase is already initialized, dispose the existing instance
      // so calling initialize will actually reinitialize with new credentials.
      try {
        if (Supabase.instance.isInitialized) {
          _logger.i(
            'Supabase already initialized - disposing to allow reinitialization',
          );
          await Supabase.instance.dispose();
          _client = null;
        }
      } catch (disposeErr) {
        _logger.w(
          'Error disposing existing Supabase instance before reinitialize: $disposeErr',
        );
      }

      final supabase = await Supabase.initialize(url: url, anonKey: key);
      _client = supabase.client;

      // Basic verification: try a lightweight query to ensure credentials work.
      try {
        await _client!.from('fcm_user_tokens').select().limit(1);
      } catch (verifyErr) {
        _logger.e('Supabase initialization verification failed: $verifyErr');
        // Dispose instance as verification failed
        try {
          if (Supabase.instance.isInitialized) {
            await Supabase.instance.dispose();
          }
        } catch (_) {
          // ignore dispose errors
        }
        _client = null;
        rethrow;
      }

      _logger.i('Supabase client initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize Supabase client: $e');
      debugPrint('Failed to initialize Supabase client: $e');
      debugPrintStack();
      rethrow;
    }
  }

  /// Get current Supabase client
  SupabaseClient get client {
    return _client ??
        (throw Exception(
          'Supabase client not initialized. Call initialize() first.',
        ));
  }

  /// Check if Supabase is initialized
  bool get isInitialized => _client != null;

  /// Fetch all device tokens from the specified table
  Future<List<DeviceToken>> fetchDeviceTokens({
    String tableName = 'fcm_user_tokens',
  }) async {
    if (!isInitialized) {
      throw Exception('Supabase not initialized');
    }

    try {
      final response = await client
          .from(tableName)
          .select()
          .order('last_active', ascending: false);

      if (response.isEmpty) {
        _logger.w('No tokens found in table: $tableName');
        return [];
      }

      final tokens = <DeviceToken>[];
      for (final item in response) {
        try {
          final token = DeviceToken.fromJson(item);
          tokens.add(token);
        } catch (e) {
          _logger.w('Failed to parse token: $e');
          debugPrint('Failed to parse token: $e');
          debugPrintStack();
        }
      }

      _logger.i('Fetched ${tokens.length} device tokens');
      return tokens;
    } catch (e) {
      _logger.e('Failed to fetch device tokens: $e');
      debugPrint('Failed to fetch device tokens: $e');
      debugPrintStack();
      rethrow;
    }
  }

  /// Fetch device tokens filtered by user ID
  Future<List<DeviceToken>> fetchTokensByUserId({
    required String userId,
    String tableName = 'fcm_user_tokens',
  }) async {
    if (!isInitialized) {
      throw Exception('Supabase not initialized');
    }

    try {
      final response = await client
          .from(tableName)
          .select()
          .eq('user_id', userId)
          .order('last_active', ascending: false);

      if (response.isEmpty) {
        return [];
      }

      final tokens = <DeviceToken>[];
      for (final item in response) {
        try {
          final token = DeviceToken.fromJson(item);
          tokens.add(token);
        } catch (e) {
          _logger.w('Failed to parse token: $e');
          debugPrint('Failed to parse token: $e');
          debugPrintStack();
        }
      }

      _logger.i('Fetched ${tokens.length} tokens for user: $userId');
      return tokens;
    } catch (e) {
      _logger.e('Failed to fetch tokens by user ID: $e');
      debugPrint('Failed to fetch tokens by user ID: $e');
      debugPrintStack();
      rethrow;
    }
  }

  /// Fetch device tokens filtered by platform
  Future<List<DeviceToken>> fetchTokensByPlatform({
    required String platform,
    String tableName = 'fcm_user_tokens',
  }) async {
    if (!isInitialized) {
      throw Exception('Supabase not initialized');
    }

    try {
      final response = await client
          .from(tableName)
          .select()
          .eq('platform', platform)
          .order('last_active', ascending: false);

      if (response.isEmpty) {
        return [];
      }

      final tokens = <DeviceToken>[];
      for (final item in response) {
        try {
          final token = DeviceToken.fromJson(item);
          tokens.add(token);
        } catch (e) {
          _logger.w('Failed to parse token: $e');
          debugPrint('Failed to parse token: $e');
          debugPrintStack();
        }
      }

      _logger.i('Fetched ${tokens.length} tokens for platform: $platform');
      return tokens;
    } catch (e) {
      _logger.e('Failed to fetch tokens by platform: $e');
      debugPrint('Failed to fetch tokens by platform: $e');
      debugPrintStack();
      rethrow;
    }
  }

  /// Test Supabase connection
  Future<bool> testConnection() async {
    if (!isInitialized) {
      return false;
    }

    try {
      // Simple query to test connection
      await client.from('fcm_user_tokens').select().limit(1);
      _logger.i('Supabase connection test successful');
      return true;
    } catch (e) {
      _logger.e('Supabase connection test failed: $e');
      debugPrint('Supabase connection test failed: $e');
      debugPrintStack();
      return false;
    }
  }

  /// Reset Supabase client
  Future<void> reset() async {
    // Dispose Supabase instance if initialized, then clear local client reference
    try {
      if (Supabase.instance.isInitialized) {
        await Supabase.instance.dispose();
      }
    } catch (e) {
      _logger.w('Error disposing Supabase instance during reset: $e');
    }

    _client = null;
    _logger.i('Supabase client reset');
  }
}
