import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// Helper class for handling notification sending logic
class NotificationSendHelper {
  /// Validate form inputs before sending
  static bool validateForm(BuildContext context, WidgetRef ref) {
    final title = ref.read(notificationTitleProvider).trim();
    final body = ref.read(notificationBodyProvider).trim();
    final topic = ref.read(notificationTopicProvider).trim();
    final sendToTopic = ref.read(notificationSendToTopicProvider);
    final selectedTokens = ref.read(selectedDeviceTokensProvider);

    if (title.isEmpty || body.isEmpty) {
      _showSnackBar(context, 'Please fill in title and body', Colors.red);
      return false;
    }

    if (sendToTopic && topic.isEmpty) {
      _showSnackBar(context, 'Please enter a topic name', Colors.red);
      return false;
    }

    if (!sendToTopic && selectedTokens.isEmpty) {
      _showSnackBar(
        context,
        'Please select at least one device token',
        Colors.red,
      );
      return false;
    }

    return true;
  }

  /// Ensure service account is available and json_content is cached
  static Future<bool> ensureServiceAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    var activeAccount = ref.read(activeServiceAccountProvider).value;
    if (activeAccount == null) {
      if (context.mounted) {
        _showSnackBar(context, 'Please select a profile first', Colors.red);
      }
      return false;
    }

    // Attempt to recover missing json_content for backward compatibility
    final dbService = ref.read(databaseServiceProvider);
    if (activeAccount.jsonContent == null ||
        activeAccount.jsonContent!.isEmpty) {
      await dbService.recoverServiceAccountContent(activeAccount.id);
      ref.invalidate(activeServiceAccountProvider);
      activeAccount = ref.read(activeServiceAccountProvider).value;
      if (activeAccount == null) {
        if (context.mounted) {
          _showSnackBar(context, 'Failed to load service account', Colors.red);
        }
        return false;
      }
    }

    return true;
  }

  /// Show error message with optional action hint
  static void showError(BuildContext context, String error) {
    String errorMessage = error;
    String? actionHint;

    if (errorMessage.contains('Operation not permitted') ||
        errorMessage.contains('Downloads')) {
      errorMessage =
          'Cannot access service account file. The file may be in a restricted location (Downloads folder on macOS).';
      actionHint =
          'Solution: Re-upload the Firebase service account JSON from Settings.';
    } else if (errorMessage.contains('not found')) {
      errorMessage = 'Service account file not found. Please re-upload it.';
      actionHint =
          'Go to Settings and upload the Firebase service account JSON again.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Error: $errorMessage'),
            if (actionHint != null) ...[
              const SizedBox(height: 8),
              Text(
                actionHint,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Show success/result message
  static void showResult(BuildContext context, String status) {
    final message = status == 'success'
        ? 'Notification sent successfully!'
        : status == 'partial'
        ? 'Notification sent with some errors'
        : 'Failed to send notification';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: status == 'success' ? Colors.green : Colors.orange,
      ),
    );
  }

  static void _showSnackBar(
    BuildContext context,
    String message,
    Color backgroundColor,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }
}
