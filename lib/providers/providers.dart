/// Riverpod providers for the application.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/database_service.dart';
import '../core/models/models.dart';
import '../features/auth/services/google_auth_service.dart';
import '../features/auth/services/secure_storage_service.dart';
import '../features/settings/repositories/supabase_token_repository.dart';

/// Provider for the database service.
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

/// Provider for the service account repository.
final serviceAccountRepositoryProvider = Provider<ServiceAccountRepository>((
  ref,
) {
  final db = ref.watch(databaseServiceProvider);
  return ServiceAccountRepository(db.db);
});

/// Provider for the notification history repository.
final notificationHistoryRepositoryProvider =
    Provider<NotificationHistoryRepository>((ref) {
      final db = ref.watch(databaseServiceProvider);
      return NotificationHistoryRepository(db.db);
    });

/// Provider for secure storage service.
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService.instance;
});

/// Provider for Google auth service.
final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService.instance;
});

/// Provider for all service account profiles.
final serviceAccountsProvider =
    AsyncNotifierProvider<ServiceAccountsNotifier, List<ServiceAccountProfile>>(
      ServiceAccountsNotifier.new,
    );

/// Notifier for managing service account profiles.
class ServiceAccountsNotifier
    extends AsyncNotifier<List<ServiceAccountProfile>> {
  @override
  Future<List<ServiceAccountProfile>> build() async {
    final repository = ref.watch(serviceAccountRepositoryProvider);
    return repository.getAll();
  }

  /// Refreshes the list of service accounts.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(serviceAccountRepositoryProvider);
      return repository.getAll();
    });
  }

  /// Adds a new service account.
  Future<void> add({
    required String name,
    required String projectId,
    required String clientEmail,
    required String jsonPath,
  }) async {
    final repository = ref.read(serviceAccountRepositoryProvider);
    await repository.insert(
      name: name,
      projectId: projectId,
      clientEmail: clientEmail,
      jsonPath: jsonPath,
    );
    await refresh();
  }

  /// Sets a service account as active.
  Future<void> setActive(int id) async {
    final repository = ref.read(serviceAccountRepositoryProvider);
    await repository.setActive(id);

    // Reset Supabase connection when switching accounts
    SupabaseTokenRepository.reset();

    await refresh();
    ref.invalidate(activeServiceAccountProvider);
    ref.invalidate(supabaseConfigProvider);
  }

  /// Deletes a service account.
  Future<void> delete(int id) async {
    final repository = ref.read(serviceAccountRepositoryProvider);
    final secureStorage = ref.read(secureStorageProvider);

    await secureStorage.deleteSupabaseConfig(id);
    await secureStorage.deleteServiceAccountJson(id);
    await repository.delete(id);

    await refresh();
  }
}

/// Provider for the currently active service account.
final activeServiceAccountProvider = FutureProvider<ServiceAccountProfile?>((
  ref,
) async {
  final repository = ref.watch(serviceAccountRepositoryProvider);
  return repository.getActive();
});

/// Provider for the Supabase config of the active profile.
final supabaseConfigProvider =
    AsyncNotifierProvider<SupabaseConfigNotifier, SupabaseConfig?>(
      SupabaseConfigNotifier.new,
    );

/// Notifier for managing Supabase configuration.
class SupabaseConfigNotifier extends AsyncNotifier<SupabaseConfig?> {
  @override
  Future<SupabaseConfig?> build() async {
    final activeProfile = await ref.watch(activeServiceAccountProvider.future);
    if (activeProfile == null) return null;

    final secureStorage = ref.read(secureStorageProvider);
    return secureStorage.getSupabaseConfig(activeProfile.id);
  }

  /// Saves the Supabase configuration.
  Future<void> save(SupabaseConfig config) async {
    final activeProfile = await ref.read(activeServiceAccountProvider.future);
    if (activeProfile == null) return;

    final secureStorage = ref.read(secureStorageProvider);
    await secureStorage.saveSupabaseConfig(activeProfile.id, config);

    // Initialize Supabase with the new config
    SupabaseTokenRepository.initialize(config);

    state = AsyncValue.data(config);
  }

  /// Clears the Supabase configuration.
  Future<void> clear() async {
    final activeProfile = await ref.read(activeServiceAccountProvider.future);
    if (activeProfile == null) return;

    final secureStorage = ref.read(secureStorageProvider);
    await secureStorage.deleteSupabaseConfig(activeProfile.id);

    SupabaseTokenRepository.reset();

    state = const AsyncValue.data(null);
  }
}

/// Provider for device tokens from Supabase.
final deviceTokensProvider =
    AsyncNotifierProvider<DeviceTokensNotifier, List<DeviceToken>>(
      DeviceTokensNotifier.new,
    );

/// Notifier for managing device tokens.
class DeviceTokensNotifier extends AsyncNotifier<List<DeviceToken>> {
  @override
  Future<List<DeviceToken>> build() async {
    final config = await ref.watch(supabaseConfigProvider.future);
    if (config == null || !config.isValid) return [];

    SupabaseTokenRepository.initialize(config);
    return SupabaseTokenRepository.fetchTokens();
  }

  /// Refreshes the token list.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final config = await ref.read(supabaseConfigProvider.future);
      if (config == null || !config.isValid) return [];

      SupabaseTokenRepository.initialize(config);
      return SupabaseTokenRepository.fetchTokens();
    });
  }

  /// Toggles selection state of a token.
  void toggleSelection(String tokenId) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current.map((token) {
        if (token.id == tokenId) {
          return token.copyWith(isSelected: !token.isSelected);
        }
        return token;
      }).toList(),
    );
  }

  /// Selects all tokens.
  void selectAll() {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current.map((token) => token.copyWith(isSelected: true)).toList(),
    );
  }

  /// Deselects all tokens.
  void deselectAll() {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current.map((token) => token.copyWith(isSelected: false)).toList(),
    );
  }

  /// Gets selected tokens.
  List<DeviceToken> get selectedTokens {
    return (state.valueOrNull ?? []).where((t) => t.isSelected).toList();
  }
}

/// Provider for notification history.
final notificationHistoryProvider =
    AsyncNotifierProvider<
      NotificationHistoryNotifier,
      List<NotificationHistory>
    >(NotificationHistoryNotifier.new);

/// Notifier for managing notification history.
class NotificationHistoryNotifier
    extends AsyncNotifier<List<NotificationHistory>> {
  @override
  Future<List<NotificationHistory>> build() async {
    final activeProfile = await ref.watch(activeServiceAccountProvider.future);
    if (activeProfile == null) return [];

    final repository = ref.read(notificationHistoryRepositoryProvider);
    return repository.getByServiceAccount(activeProfile.id);
  }

  /// Refreshes the history.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final activeProfile = await ref.read(activeServiceAccountProvider.future);
      if (activeProfile == null) return [];

      final repository = ref.read(notificationHistoryRepositoryProvider);
      return repository.getByServiceAccount(activeProfile.id);
    });
  }

  /// Adds a history record.
  Future<void> add(NotificationHistory history) async {
    final repository = ref.read(notificationHistoryRepositoryProvider);
    await repository.insert(history);
    await refresh();
  }

  /// Deletes a history record.
  Future<void> delete(int id) async {
    final repository = ref.read(notificationHistoryRepositoryProvider);
    await repository.delete(id);
    await refresh();
  }

  /// Clears all history for the active profile.
  Future<void> clearAll() async {
    final activeProfile = await ref.read(activeServiceAccountProvider.future);
    if (activeProfile == null) return;

    final repository = ref.read(notificationHistoryRepositoryProvider);
    await repository.clearByServiceAccount(activeProfile.id);
    await refresh();
  }
}

/// Provider for FCM service.
final fcmServiceProvider = Provider<FcmService>((ref) {
  final authService = ref.watch(googleAuthServiceProvider);
  return FcmService(authService);
});

/// Provider for authentication state.
final isAuthenticatedProvider = StateProvider<bool>((ref) {
  return GoogleAuthService.instance.isAuthenticated;
});
