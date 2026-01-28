/// Supabase configuration model.
library;

/// Represents Supabase connection configuration.
class SupabaseConfig {
  /// Creates a new [SupabaseConfig].
  const SupabaseConfig({
    required this.url,
    required this.anonKey,
    this.tableName = 'device_tokens',
    this.tokenColumn = 'token',
  });

  /// Creates a [SupabaseConfig] from a map.
  factory SupabaseConfig.fromMap(Map<String, dynamic> map) {
    return SupabaseConfig(
      url: map['url'] as String,
      anonKey: map['anon_key'] as String,
      tableName: map['table_name'] as String? ?? 'device_tokens',
      tokenColumn: map['token_column'] as String? ?? 'token',
    );
  }

  /// Supabase project URL.
  final String url;

  /// Supabase anon/service key.
  final String anonKey;

  /// Name of the table containing device tokens.
  final String tableName;

  /// Column name for the token field.
  final String tokenColumn;

  /// Converts to a map for storage.
  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'anon_key': anonKey,
      'table_name': tableName,
      'token_column': tokenColumn,
    };
  }

  /// Checks if the configuration is valid.
  bool get isValid => url.isNotEmpty && anonKey.isNotEmpty;

  /// Creates a copy with the specified changes.
  SupabaseConfig copyWith({
    String? url,
    String? anonKey,
    String? tableName,
    String? tokenColumn,
  }) {
    return SupabaseConfig(
      url: url ?? this.url,
      anonKey: anonKey ?? this.anonKey,
      tableName: tableName ?? this.tableName,
      tokenColumn: tokenColumn ?? this.tokenColumn,
    );
  }
}
