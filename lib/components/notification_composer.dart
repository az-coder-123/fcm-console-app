import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notification_form_state.dart';
import '../providers/providers.dart';
import 'data_pairs_editor.dart';
import 'notification_form_fields.dart';
import 'notification_send_helper.dart';
import 'page_header.dart';
import 'profile_required_banner.dart';
import 'token_selection_section.dart';

/// Main notification composer widget for creating and sending FCM notifications
class NotificationComposer extends ConsumerWidget {
  const NotificationComposer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(notificationFormProvider);
    final activeAccountAsync = ref.watch(activeServiceAccountProvider);

    return Scaffold(
      appBar: AppBar(elevation: 0, toolbarHeight: 0),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileRequiredBanner(activeAccountAsync: activeAccountAsync),
              const PageHeader(
                title: 'Send Notification',
                subtitle:
                    'Compose and send Firebase Cloud Messaging notifications.',
              ),
              if (activeAccountAsync.value != null) ...[
                const SizedBox(height: 24),
                _buildTokenSelectionSection(formState.sendToTopic),
                _buildSelectedTokensInfo(formState.selectedTokens, ref),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildFormFields(context, ref, formState),
                  ),
                ),
                const SizedBox(height: 24),
                _buildDataPairsEditor(ref, formState),
                _buildActionButtons(ref, context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildSelectedTokensInfo(
    Set<String> selectedTokens,
    WidgetRef ref,
  ) {
    if (selectedTokens.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.blue.shade800),
              const SizedBox(width: 12),
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  '${selectedTokens.length} device token(s) selected for sending',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              ref.read(notificationFormProvider.notifier).clearSelectedTokens();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  static Widget _buildFormFields(
    BuildContext context,
    WidgetRef ref,
    NotificationFormState formState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Send mode toggle
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Device Tokens'),
              icon: Icon(Icons.devices),
            ),
            ButtonSegment(
              value: true,
              label: Text('Topic'),
              icon: Icon(Icons.topic),
            ),
          ],
          selected: {formState.sendToTopic},
          onSelectionChanged: (Set<bool> newSelection) {
            ref
                .read(notificationFormProvider.notifier)
                .setSendToTopic(newSelection.first);
          },
        ),
        const Divider(),
        const SizedBox(height: 16),
        // Form fields are rendered by NotificationFormFields component
        const NotificationFormFields(),
      ],
    );
  }

  static Widget _buildTokenSelectionSection(bool sendToTopic) {
    if (sendToTopic) {
      return const SizedBox.shrink();
    }
    return const TokenSelectionSection();
  }

  static Widget _buildDataPairsEditor(
    WidgetRef ref,
    NotificationFormState formState,
  ) {
    return Column(
      children: [
        DataPairsEditor(
          dataPairs: formState.currentModeData.dataPairs,
          onAddPair: (key, value) {
            ref.read(notificationFormProvider.notifier).addDataPair(key, value);
          },
          onRemovePair: (key) {
            ref.read(notificationFormProvider.notifier).removeDataPair(key);
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  static Widget _buildActionButtons(WidgetRef ref, BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _sendNotification(ref, context),
            icon: const Icon(Icons.send),
            label: const Text('Send Notification'),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ref.read(notificationFormProvider.notifier).reset();
            },
            icon: const Icon(Icons.clear),
            label: const Text('Clear Form'),
          ),
        ),
      ],
    );
  }

  static Future<void> _sendNotification(
    WidgetRef ref,
    BuildContext context,
  ) async {
    final formState = ref.read(notificationFormProvider);
    final currentData = formState.currentModeData;

    // Validate form
    if (currentData.title.trim().isEmpty || currentData.body.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in title and body'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (formState.sendToTopic && formState.topicData.topic.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a topic name'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!formState.sendToTopic && formState.selectedTokens.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one device token'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Ensure service account is available
    final isReady = await NotificationSendHelper.ensureServiceAccount(
      context,
      ref,
    );
    if (!isReady) {
      return;
    }

    final activeAccount = ref.read(activeServiceAccountProvider).value!;

    try {
      final fcmService = ref.read(fcmServiceProvider);
      final db = ref.read(databaseServiceProvider);

      final history = formState.sendToTopic
          ? await fcmService.sendNotificationToTopic(
              serviceAccount: activeAccount,
              topic: formState.topicData.topic,
              title: currentData.title,
              body: currentData.body,
              imageUrl: currentData.imageUrl.isEmpty
                  ? null
                  : currentData.imageUrl,
              data: currentData.dataPairs,
            )
          : await fcmService.sendNotificationToTokens(
              serviceAccount: activeAccount,
              tokens: formState.selectedTokens.toList(),
              title: currentData.title,
              body: currentData.body,
              imageUrl: currentData.imageUrl.isEmpty
                  ? null
                  : currentData.imageUrl,
              data: currentData.dataPairs,
            );

      await db.createNotificationHistory(history);

      if (context.mounted) {
        NotificationSendHelper.showResult(context, history.status);

        if (history.status == 'success') {
          ref.read(notificationFormProvider.notifier).reset();
        }

        ref.invalidate(notificationHistoryProvider(activeAccount.id));
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
      debugPrintStack();
      if (context.mounted) {
        NotificationSendHelper.showError(context, e.toString());
      }
    }
  }
}
