import 'package:flutter/material.dart';

import '../display_utils.dart';

/// Utility functions for token list display
class TokenListUtils {
  /// Pad a number with leading zeros
  static String pad(int n) => n.toString().padLeft(2, '0');

  /// Format a DateTime to "dd/mm/yyyy HH:mm:ss"
  static String formatDate(DateTime date) => DisplayUtils.formatDateTime(date);

  /// Get platform icon based on platform name
  static IconData getPlatformIcon(String? platform) =>
      DisplayUtils.getPlatformIcon(platform);
}
