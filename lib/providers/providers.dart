import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_history.dart';
import '../models/service_account.dart';
import '../services/database_service.dart';
import '../services/fcm_service.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';

// Service Providers

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService();
});

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

// Service Account State

final serviceAccountsProvider = FutureProvider<List<ServiceAccount>>((
  ref,
) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getAllServiceAccounts();
});

final activeServiceAccountProvider = FutureProvider<ServiceAccount?>((
  ref,
) async {
  final storage = ref.watch(storageServiceProvider);
  final activeId = await storage.getActiveServiceAccountId();

  if (activeId == null) return null;

  final db = ref.watch(databaseServiceProvider);
  return db.getServiceAccount(activeId);
});

// Notification History State

final notificationHistoryProvider =
    FutureProvider.family<List<NotificationHistory>, int>((
      ref,
      serviceAccountId,
    ) async {
      final db = ref.watch(databaseServiceProvider);
      return db.getNotificationHistory(serviceAccountId);
    });

// Loading States

final isLoadingProvider = StateProvider<bool>((ref) => false);

final errorMessageProvider = StateProvider<String?>((ref) => null);

// Token Selection State

final selectedDeviceTokensProvider = StateProvider<Set<String>>(
  (ref) => <String>{},
);
// Notification Composer Persistent State

/// Title input for notification
final notificationTitleProvider = StateProvider<String>((ref) => '');

/// Body input for notification
final notificationBodyProvider = StateProvider<String>((ref) => '');

/// Image URL input for notification
final notificationImageUrlProvider = StateProvider<String>((ref) => '');

/// Topic name input for sending to topic
final notificationTopicProvider = StateProvider<String>((ref) => '');

/// Data pairs (key-value pairs) for notification
final notificationDataPairsProvider = StateProvider<Map<String, String>>(
  (ref) => {},
);

/// Tab selection (false = Device Tokens, true = Topic)
final notificationSendToTopicProvider = StateProvider<bool>((ref) => false);
