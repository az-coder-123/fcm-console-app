import 'package:flutter/material.dart';

/// Shared display utilities for formatting dates, shortening tokens, and platform icons
class DisplayUtils {
  static String pad(int n) => n.toString().padLeft(2, '0');

  /// Format date as dd/mm/yyyy
  static String formatDate(DateTime date) {
    return '${pad(date.day)}/${pad(date.month)}/${date.year}';
  }

  /// Format nullable DateTime to `yyyy-MM-dd HH:mm` (returns '-' when null)
  static String formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
    final d = dt.toLocal();
    return '${d.year}-${pad(d.month)}-${pad(d.day)} ${pad(d.hour)}:${pad(d.minute)}';
  }

  /// Human-readable format like `dd/mm/yyyy at HH:MM`
  static String formatDateHuman(DateTime date) {
    final d = date.toLocal();
    return '${pad(d.day)}/${pad(d.month)}/${d.year} at ${pad(d.hour)}:${pad(d.minute)}';
  }

  /// Return platform icon for token platform string
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

  /// Shorten token for display
  static String shortenToken(String token) {
    if (token.length <= 36) return token;
    return '${token.substring(0, 20)}...${token.substring(token.length - 8)}';
  }
}
