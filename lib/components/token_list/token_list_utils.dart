import 'package:flutter/material.dart';

/// Utility functions for token list display
class TokenListUtils {
  /// Pad a number with leading zeros
  static String pad(int n) => n.toString().padLeft(2, '0');

  /// Format a DateTime to "dd/mm/yyyy HH:mm:ss"
  static String formatDate(DateTime date) {
    final d = '${pad(date.day)}/${pad(date.month)}/${date.year}';
    final t = '${pad(date.hour)}:${pad(date.minute)}:${pad(date.second)}';
    return '$d $t';
  }

  /// Get platform icon based on platform name
  static IconData getPlatformIcon(String? platform) {
    switch ((platform ?? '').toLowerCase()) {
      case 'ios':
        return Icons.phone_iphone;
      case 'android':
        return Icons.android;
      case 'web':
        return Icons.web;
      default:
        return Icons.device_unknown;
    }
  }
}
