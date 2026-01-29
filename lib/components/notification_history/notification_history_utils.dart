import 'package:flutter/material.dart';

import '../display_utils.dart';

/// Utility functions for notification history display
class NotificationHistoryUtils {
  /// Format a DateTime to a readable string (dd/mm/yyyy at HH:MM)
  static String formatDate(DateTime date) => DisplayUtils.formatDateHuman(date);

  /// Build status icon based on notification status
  static Widget buildStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return CircleAvatar(
          radius: 20,
          backgroundColor: Colors.green.shade100,
          child: Icon(Icons.check_circle, color: Colors.green.shade700),
        );
      case 'partial':
        return CircleAvatar(
          radius: 20,
          backgroundColor: Colors.orange.shade100,
          child: Icon(Icons.error_outline, color: Colors.orange.shade700),
        );
      case 'failed':
        return CircleAvatar(
          radius: 20,
          backgroundColor: Colors.red.shade100,
          child: Icon(Icons.cancel, color: Colors.red.shade700),
        );
      default:
        return CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey.shade100,
          child: Icon(Icons.help_outline, color: Colors.grey.shade700),
        );
    }
  }

  /// Build status chip with color and label
  static Widget buildStatusChip(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'success':
        color = Colors.green.shade700;
        label = 'Success';
        break;
      case 'partial':
        color = Colors.orange.shade800;
        label = 'Partial';
        break;
      case 'failed':
        color = Colors.red.shade700;
        label = 'Failed';
        break;
      default:
        color = Colors.grey.shade700;
        label = 'Unknown';
    }

    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }
}
