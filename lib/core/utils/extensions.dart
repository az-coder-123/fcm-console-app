/// Extension methods for common operations.
library;

import 'package:intl/intl.dart';

/// Extension methods for DateTime.
extension DateTimeExtension on DateTime {
  /// Formats the date as a human-readable string.
  String toFormattedString() {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(this);
  }

  /// Formats the date as a short string (date only).
  String toShortString() {
    return DateFormat('yyyy-MM-dd').format(this);
  }
}

/// Extension methods for String.
extension StringExtension on String {
  /// Truncates the string to the specified length with ellipsis.
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }

  /// Checks if the string is a valid URL.
  bool get isValidUrl {
    try {
      final uri = Uri.parse(this);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }
}

/// Extension methods for Map.
extension MapExtension<K, V> on Map<K, V> {
  /// Returns a new map with null values removed.
  Map<K, V> get withoutNulls {
    return Map.fromEntries(entries.where((e) => e.value != null));
  }
}
