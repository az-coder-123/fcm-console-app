import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// Notification composer component for creating and sending FCM notifications
/// Supports sending to device tokens or topics
class NotificationComposer extends ConsumerStatefulWidget {
  const NotificationComposer({super.key});

  @override
  ConsumerState<NotificationComposer> createState() =>
      _NotificationComposerState();
}

class _NotificationComposerState extends ConsumerState<NotificationComposer> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _topicController = TextEditingController();
  final _dataKeyController = TextEditingController();
  final _dataValueController = TextEditingController();

  final Map<String, String> _dataPairs = {};
  bool _isSending = false;
  bool _sendToTopic = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _imageUrlController.dispose();
    _topicController.dispose();
    _dataKeyController.dispose();
    _dataValueController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    // Validation
    if (_titleController.text.trim().isEmpty ||
        _bodyController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in title and body'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_sendToTopic && _topicController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a topic name'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final activeAccount = ref.read(activeServiceAccountProvider).value;
    if (activeAccount == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a profile first'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final fcmService = ref.read(fcmServiceProvider);
      final db = ref.read(databaseServiceProvider);

      final history = _sendToTopic
          ? await fcmService.sendNotificationToTopic(
              serviceAccount: activeAccount,
              topic: _topicController.text.trim(),
              title: _titleController.text.trim(),
              body: _bodyController.text.trim(),
              imageUrl: _imageUrlController.text.trim().isEmpty
                  ? null
                  : _imageUrlController.text.trim(),
              data: _dataPairs,
            )
          : await fcmService.sendNotificationToTokens(
              serviceAccount: activeAccount,
              tokens: _getSelectedTokens(),
              title: _titleController.text.trim(),
              body: _bodyController.text.trim(),
              imageUrl: _imageUrlController.text.trim().isEmpty
                  ? null
                  : _imageUrlController.text.trim(),
              data: _dataPairs,
            );

      // Save to database
      await db.createNotificationHistory(history);

      if (mounted) {
        setState(() {
          _isSending = false;
        });

        // Show result
        final message = history.status == 'success'
            ? 'Notification sent successfully!'
            : history.status == 'partial'
            ? 'Notification sent with some errors'
            : 'Failed to send notification';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: history.status == 'success'
                ? Colors.green
                : Colors.orange,
          ),
        );

        // Clear form on success
        if (history.status == 'success') {
          _clearForm();
        }

        // Refresh history
        ref.invalidate(notificationHistoryProvider(activeAccount.id));
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
      debugPrintStack();
      if (mounted) {
        setState(() {
          _isSending = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<String> _getSelectedTokens() {
    // In a real implementation, this would get selected tokens from TokenList
    // For now, return empty list as placeholder
    return [];
  }

  void _clearForm() {
    _titleController.clear();
    _bodyController.clear();
    _imageUrlController.clear();
    _topicController.clear();
    _dataPairs.clear();
  }

  void _addDataPair() {
    final key = _dataKeyController.text.trim();
    final value = _dataValueController.text.trim();

    if (key.isEmpty || value.isEmpty) return;

    setState(() {
      _dataPairs[key] = value;
      _dataKeyController.clear();
      _dataValueController.clear();
    });
  }

  void _removeDataPair(String key) {
    setState(() {
      _dataPairs.remove(key);
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeAccountAsync = ref.watch(activeServiceAccountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Send Notification'), elevation: 0),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description
              Text(
                'Compose and send Firebase Cloud Messaging notifications.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Active profile check
              activeAccountAsync.when(
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
              ),

              if (activeAccountAsync.value != null) ...[
                const SizedBox(height: 24),

                // Notification form
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
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
                          selected: {_sendToTopic},
                          onSelectionChanged: (Set<bool> newSelection) {
                            setState(() {
                              _sendToTopic = newSelection.first;
                            });
                          },
                        ),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Topic field (only visible when sending to topic)
                        if (_sendToTopic)
                          TextField(
                            controller: _topicController,
                            decoration: const InputDecoration(
                              labelText: 'Topic Name',
                              hintText: 'e.g., news, updates',
                              prefixIcon: Icon(Icons.topic),
                              border: OutlineInputBorder(),
                            ),
                            enabled: !_isSending,
                          ),
                        if (_sendToTopic) const SizedBox(height: 16),

                        // Title field
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title *',
                            hintText: 'Notification title',
                            prefixIcon: Icon(Icons.title),
                            border: OutlineInputBorder(),
                          ),
                          enabled: !_isSending,
                        ),
                        const SizedBox(height: 16),

                        // Body field
                        TextField(
                          controller: _bodyController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Body *',
                            hintText: 'Notification body',
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(),
                          ),
                          enabled: !_isSending,
                        ),
                        const SizedBox(height: 16),

                        // Image URL field
                        TextField(
                          controller: _imageUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Image URL (Optional)',
                            hintText: 'https://example.com/image.png',
                            prefixIcon: Icon(Icons.image),
                            border: OutlineInputBorder(),
                          ),
                          enabled: !_isSending,
                        ),
                        const SizedBox(height: 24),

                        // Data pairs section
                        Text(
                          'Data Pairs (Optional)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),

                        // Add data pair form
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _dataKeyController,
                                decoration: const InputDecoration(
                                  labelText: 'Key',
                                  hintText: 'data_key',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                enabled: !_isSending,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _dataValueController,
                                decoration: const InputDecoration(
                                  labelText: 'Value',
                                  hintText: 'data_value',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                enabled: !_isSending,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _isSending ? null : _addDataPair,
                              tooltip: 'Add Data Pair',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Data pairs list
                        if (_dataPairs.isNotEmpty)
                          ..._dataPairs.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Chip(
                                label: Text('${entry.key}: ${entry.value}'),
                                onDeleted: () => _removeDataPair(entry.key),
                                deleteIcon: const Icon(Icons.close),
                              ),
                            );
                          }),

                        const SizedBox(height: 24),

                        // Send button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSending ? null : _sendNotification,
                            icon: _isSending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send),
                            label: Text(
                              _isSending ? 'Sending...' : 'Send Notification',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
