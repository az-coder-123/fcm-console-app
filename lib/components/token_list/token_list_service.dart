import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/device_token.dart';
import '../../providers/providers.dart';

/// Small helper service for token list operations
class TokenListService {
  /// Ensures Supabase is initialized and returns fetched tokens.
  /// Throws an Exception with a user-friendly message on failure.
  static Future<List<DeviceToken>> fetchTokensWithInit(
    WidgetRef ref,
    dynamic supabaseService,
  ) async {
    if (!supabaseService.isInitialized) {
      final storage = ref.read(storageServiceProvider);
      final url = await storage.getSupabaseUrl();
      final key = await storage.getSupabaseKey();

      if (url != null && key != null) {
        try {
          await supabaseService.initialize(url, key);
        } catch (e) {
          throw Exception('Failed to initialize Supabase: $e');
        }
      } else {
        throw Exception(
          'Supabase not initialized. Please configure Supabase first.',
        );
      }
    }

    final tokens = await supabaseService.fetchDeviceTokens();
    return tokens;
  }
}
