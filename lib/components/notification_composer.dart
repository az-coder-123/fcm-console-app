import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_account.dart';
import '../providers/providers.dart';
import 'data_pairs_editor.dart';
import 'notification_form_fields.dart';
import 'notification_send_helper.dart';
import 'token_selection_section.dart';

/// Main notification composer widget for creating and sending FCM notifications
/// Orchestrates form fields, token selection, and data pairs editing
class NotificationComposer extends ConsumerStatefulWidget {
  const NotificationComposer({super.key});

  @override
  ConsumerState<NotificationComposer> createState() =>
      _NotificationComposerState();
}

class _NotificationComposerState extends ConsumerState<NotificationComposer> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for profile changes and reset form when profile changes
    Future.microtask(() {
      ref.listen(activeServiceAccountProvider, (previous, next) {
        // Check if the profile ID changed
        int? previousId;
        int? currentId;

        previous?.whenData((acc) {
          if (acc != null) previousId = acc.id;
        });

        next.whenData((acc) {
          if (acc != null) currentId = acc.id;
        });

        if (previousId != null &&
            currentId != null &&
            previousId != currentId) {
          // Profile changed, reset form
          _resetForm();
        }
      });
    });
  }

  void _resetForm() {
    ref.read(notificationTitleProvider.notifier).state = '';
    ref.read(notificationBodyProvider.notifier).state = '';
    ref.read(notificationImageUrlProvider.notifier).state = '';
    ref.read(notificationTopicProvider.notifier).state = '';
    ref.read(notificationDataPairsProvider.notifier).state = {};
    ref.read(notificationSendToTopicProvider.notifier).state = false;
    ref.read(selectedDeviceTokensProvider.notifier).state = {};
  }

  @override
  Widget build(BuildContext context) {
    final activeAccountAsync = ref.watch(activeServiceAccountProvider);
    final selectedTokens = ref.watch(selectedDeviceTokensProvider);
    final sendToTopic = ref.watch(notificationSendToTopicProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Send Notification'), elevation: 0),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDescription(context),
              const SizedBox(height: 24),
              _buildProfileCheck(activeAccountAsync),
              if (activeAccountAsync.value != null) ...[
                const SizedBox(height: 24),
                _buildSelectedTokensInfo(selectedTokens),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: NotificationFormFields(sendToTopic: sendToTopic),
                  ),
                ),
                const SizedBox(height: 24),
                TokenSelectionSection(),
                DataPairsEditor(),
                _buildActionButtons(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      'Compose and send Firebase Cloud Messaging notifications.',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildProfileCheck(AsyncValue<ServiceAccount?> activeAccountAsync) {
    return activeAccountAsync.when(
      data: (account) {
        if (account == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade800),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Please select a Firebase Service Account profile first',
                    style: TextStyle(color: Colors.orange.shade800),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildSelectedTokensInfo(Set<String> selectedTokens) {
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
              ref.read(selectedDeviceTokensProvider.notifier).state =
                  <String>{};
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _sendNotification,
            icon: const Icon(Icons.send),
            label: const Text('Send Notification'),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _resetForm,
            icon: const Icon(Icons.clear),
            label: const Text('Clear Form'),
          ),
        ),
      ],
    );
  }

  Future<void> _sendNotification() async {
    // Validate form
    if (!NotificationSendHelper.validateForm(context, ref)) {
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

    // Get form data
    final title = ref.read(notificationTitleProvider).trim();
    final body = ref.read(notificationBodyProvider).trim();
    final imageUrl = ref.read(notificationImageUrlProvider).trim();
    final topic = ref.read(notificationTopicProvider).trim();
    final dataPairs = ref.read(notificationDataPairsProvider);
    final sendToTopic = ref.read(notificationSendToTopicProvider);
    final selectedTokens = ref.read(selectedDeviceTokensProvider);
    final activeAccount = ref.read(activeServiceAccountProvider).value!;

    setState(() {});

    try {
      final fcmService = ref.read(fcmServiceProvider);
      final db = ref.read(databaseServiceProvider);

      final history = sendToTopic
          ? await fcmService.sendNotificationToTopic(
              serviceAccount: activeAccount,
              topic: topic,
              title: title,
              body: body,
              imageUrl: imageUrl.isEmpty ? null : imageUrl,
              data: dataPairs,
            )
          : await fcmService.sendNotificationToTokens(
              serviceAccount: activeAccount,
              tokens: selectedTokens.toList(),
              title: title,
              body: body,
              imageUrl: imageUrl.isEmpty ? null : imageUrl,
              data: dataPairs,
            );

      await db.createNotificationHistory(history);

      if (mounted) {
        setState(() {});
        NotificationSendHelper.showResult(context, history.status);

        if (history.status == 'success') {
          _resetForm();
        }

        ref.invalidate(notificationHistoryProvider(activeAccount.id));
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
      debugPrintStack();
      if (mounted) {
        setState(() {});
        NotificationSendHelper.showError(context, e.toString());
      }
    }
  }
}
