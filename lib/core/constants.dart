/// Application constants
class AppConstants {
  // Database
  static const String databaseName = 'fcm_app.db';
  static const int databaseVersion = 1;

  // Table names
  static const String tableServiceAccounts = 'service_accounts';
  static const String tableNotificationHistory = 'notification_history';

  // Supabase
  static const String defaultDeviceTokenTable = 'device_tokens';

  // FCM
  static const String fcmEndpoint = 'https://fcm.googleapis.com/v1/projects';
  static const int maxRetries = 3;

  // Storage keys
  static const String keyActiveServiceAccountId = 'active_service_account_id';
  static const String keySupabaseUrl = 'supabase_url';
  static const String keySupabaseKey = 'supabase_key';
}
