/// Notification composer screen for creating and sending notifications.
library;

import 'dart:convert';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/ui/app_theme.dart';
import '../../../features/auth/services/google_auth_service.dart';
import '../../../providers/providers.dart';

/// Screen for composing and sending push notifications.
class NotificationComposerScreen extends ConsumerStatefulWidget {
  const NotificationComposerScreen({super.key});

  @override
  ConsumerState<NotificationComposerScreen> createState() =>
      _NotificationComposerScreenState();
}

class _NotificationComposerScreenState
    extends ConsumerState<NotificationComposerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _topicController = TextEditingController();

  bool _sendToTopic = false;
  bool _isSending = false;
  final List<MapEntry<String, String>> _dataEntries = [];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _imageUrlController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final selectedTokens = ref
        .watch(deviceTokensProvider)
        .maybeWhen(
          data: (tokens) => tokens.where((t) => t.isSelected).toList(),
          orElse: () => <DeviceToken>[],
        );

    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Compose Notification')),
      children: [
        if (!isAuthenticated)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: InfoBar(
              title: const Text('Not Authenticated'),
              content: const Text(
                'Please activate a Service Account profile to send notifications.',
              ),
              severity: InfoBarSeverity.warning,
            ),
          ),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTargetSection(selectedTokens),
              const SizedBox(height: AppSpacing.lg),
              _buildContentSection(),
              const SizedBox(height: AppSpacing.lg),
              _buildDataSection(),
              const SizedBox(height: AppSpacing.lg),
              _buildActions(isAuthenticated, selectedTokens),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTargetSection(List<DeviceToken> selectedTokens) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppWidgets.sectionHeader('Target'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              RadioButton(
                checked: !_sendToTopic,
                onChanged: (checked) {
                  if (checked) setState(() => _sendToTopic = false);
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text('Send to Device Tokens'),
              const SizedBox(width: AppSpacing.lg),
              RadioButton(
                checked: _sendToTopic,
                onChanged: (checked) {
                  if (checked) setState(() => _sendToTopic = true);
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text('Send to Topic'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_sendToTopic)
            InfoLabel(
              label: 'Topic Name',
              child: TextBox(
                controller: _topicController,
                placeholder: 'e.g., news, updates, promotions',
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectedTokens.isEmpty)
                  const InfoBar(
                    title: Text('No Tokens Selected'),
                    content: Text(
                      'Go to the Token List to select target devices.',
                    ),
                    severity: InfoBarSeverity.warning,
                  )
                else
                  InfoBar(
                    title: Text('${selectedTokens.length} tokens selected'),
                    content: Text(
                      'Notification will be sent to ${selectedTokens.length} device(s).',
                    ),
                    severity: InfoBarSeverity.success,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppWidgets.sectionHeader('Notification Content'),
          const SizedBox(height: AppSpacing.sm),
          InfoLabel(
            label: 'Title *',
            child: TextBox(
              controller: _titleController,
              placeholder: 'Notification title',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoLabel(
            label: 'Body *',
            child: TextBox(
              controller: _bodyController,
              placeholder: 'Notification body text',
              maxLines: 4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoLabel(
            label: 'Image URL (optional)',
            child: TextBox(
              controller: _imageUrlController,
              placeholder: 'https://example.com/image.png',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppWidgets.sectionHeader('Custom Data (optional)'),
              ),
              IconButton(
                icon: const Icon(FluentIcons.add),
                onPressed: _addDataEntry,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_dataEntries.isEmpty)
            Text(
              'Add key-value pairs to include in the notification data payload.',
              style: TextStyle(color: Colors.grey[120]),
            )
          else
            ...List.generate(_dataEntries.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: TextBox(
                        placeholder: 'Key',
                        controller: TextEditingController(
                          text: _dataEntries[index].key,
                        ),
                        onChanged: (value) {
                          _dataEntries[index] = MapEntry(
                            value,
                            _dataEntries[index].value,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextBox(
                        placeholder: 'Value',
                        controller: TextEditingController(
                          text: _dataEntries[index].value,
                        ),
                        onChanged: (value) {
                          _dataEntries[index] = MapEntry(
                            _dataEntries[index].key,
                            value,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      icon: Icon(FluentIcons.delete, color: Colors.red),
                      onPressed: () => _removeDataEntry(index),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildActions(bool isAuthenticated, List<DeviceToken> selectedTokens) {
    final canSend =
        isAuthenticated &&
        _titleController.text.isNotEmpty &&
        _bodyController.text.isNotEmpty &&
        (_sendToTopic
            ? _topicController.text.isNotEmpty
            : selectedTokens.isNotEmpty);

    return Row(
      children: [
        FilledButton(
          onPressed: _isSending || !canSend
              ? null
              : () => _sendNotification(selectedTokens),
          child: _isSending
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressRing(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Sending...'),
                  ],
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.send),
                    SizedBox(width: 8),
                    Text('Send Notification'),
                  ],
                ),
        ),
        const SizedBox(width: AppSpacing.md),
        Button(onPressed: _clearForm, child: const Text('Clear Form')),
      ],
    );
  }

  void _addDataEntry() {
    setState(() {
      _dataEntries.add(const MapEntry('', ''));
    });
  }

  void _removeDataEntry(int index) {
    setState(() {
      _dataEntries.removeAt(index);
    });
  }

  void _clearForm() {
    _titleController.clear();
    _bodyController.clear();
    _imageUrlController.clear();
    _topicController.clear();
    setState(() {
      _dataEntries.clear();
    });
  }

  Future<void> _sendNotification(List<DeviceToken> selectedTokens) async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      await displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Validation Error'),
          content: const Text('Title and Body are required.'),
          severity: InfoBarSeverity.warning,
          action: IconButton(
            icon: const Icon(FluentIcons.clear),
            onPressed: close,
          ),
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final fcmService = ref.read(fcmServiceProvider);
      final title = _titleController.text.trim();
      final body = _bodyController.text.trim();
      final imageUrl = _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim();

      final data = _dataEntries.isNotEmpty
          ? Map.fromEntries(_dataEntries.where((e) => e.key.isNotEmpty))
          : null;

      List<FcmSendResult> results;
      NotificationTargetType targetType;
      List<String> targets;

      if (_sendToTopic) {
        final topic = _topicController.text.trim();
        final result = await fcmService.sendToTopic(
          topic: topic,
          title: title,
          body: body,
          imageUrl: imageUrl,
          data: data,
        );
        results = [result];
        targetType = NotificationTargetType.topic;
        targets = [topic];
      } else {
        final tokens = selectedTokens.map((t) => t.token).toList();
        results = await fcmService.sendToTokens(
          tokens: tokens,
          title: title,
          body: body,
          imageUrl: imageUrl,
          data: data,
        );
        targetType = NotificationTargetType.token;
        targets = tokens;
      }

      // Determine overall status
      final successCount = results.where((r) => r.success).length;
      final totalCount = results.length;
      NotificationStatus status;

      if (successCount == totalCount) {
        status = NotificationStatus.success;
      } else if (successCount > 0) {
        status = NotificationStatus.partial;
      } else {
        status = NotificationStatus.failed;
      }

      // Save to history
      final activeProfile = await ref.read(activeServiceAccountProvider.future);
      if (activeProfile != null) {
        final history = NotificationHistory(
          id: 0,
          serviceAccountId: activeProfile.id,
          title: title,
          body: body,
          targetType: targetType,
          targets: targets,
          status: status,
          timestamp: DateTime.now(),
          imageUrl: imageUrl,
          data: data != null ? json.encode(data) : null,
          errorMessage: status != NotificationStatus.success
              ? results.where((r) => !r.success).map((r) => r.error).join('; ')
              : null,
        );

        await ref.read(notificationHistoryProvider.notifier).add(history);
      }

      if (mounted) {
        final severity = status == NotificationStatus.success
            ? InfoBarSeverity.success
            : status == NotificationStatus.partial
            ? InfoBarSeverity.warning
            : InfoBarSeverity.error;

        await displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: Text(
              status == NotificationStatus.success
                  ? 'Notification Sent'
                  : status == NotificationStatus.partial
                  ? 'Partially Sent'
                  : 'Send Failed',
            ),
            content: Text('$successCount of $totalCount notifications sent.'),
            severity: severity,
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: close,
            ),
          ),
        );
      }

      if (status == NotificationStatus.success) {
        _clearForm();
      }
    } on Exception catch (e) {
      if (mounted) {
        await displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Error'),
            content: Text('Failed to send notification: $e'),
            severity: InfoBarSeverity.error,
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: close,
            ),
          ),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }
}
