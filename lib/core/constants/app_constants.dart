/// Application-wide constants.
library;

/// FCM API related constants.
class FcmConstants {
  FcmConstants._();

  /// Base URL for FCM v1 API.
  static const String fcmBaseUrl =
      'https://fcm.googleapis.com/v1/projects/{project_id}/messages:send';

  /// OAuth2 scope required for FCM.
  static const String fcmScope =
      'https://www.googleapis.com/auth/firebase.messaging';
}

/// Secure storage keys.
class StorageKeys {
  StorageKeys._();

  /// Key for storing Supabase URL.
  static const String supabaseUrl = 'supabase_url';

  /// Key for storing Supabase anon key.
  static const String supabaseAnonKey = 'supabase_anon_key';

  /// Prefix for profile-specific Supabase config.
  static const String supabaseConfigPrefix = 'supabase_config_';
}

/// Database constants.
class DatabaseConstants {
  DatabaseConstants._();

  /// Database file name.
  static const String databaseName = 'fcm_console.db';

  /// Current database version.
  static const int databaseVersion = 1;
}
