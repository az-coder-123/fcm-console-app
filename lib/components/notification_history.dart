import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_history.dart';
import '../providers/providers.dart';

/// Notification history component for viewing sent notifications
/// Displays a list of all sent notifications with their status
class NotificationHistoryView extends ConsumerStatefulWidget {
  const NotificationHistoryView({super.key});

  @override
  ConsumerState<NotificationHistoryView> createState() =>
      _NotificationHistoryViewState();
}

class _NotificationHistoryViewState
    extends ConsumerState<NotificationHistoryView> {
  @override
  Widget build(BuildContext context) {
    final activeAccountAsync = ref.watch(activeServiceAccountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notification History'), elevation: 0),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            Text(
              'View history of sent notifications for the active profile.',
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
                return _buildHistoryList(account.id);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(int accountId) {
    final historyAsync = ref.watch(notificationHistoryProvider(accountId));

    return Expanded(
      child: historyAsync.when(
        data: (history) {
          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notification history',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Notifications you send will appear here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final entry = history[index];
              return _buildHistoryCard(entry);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading history',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(NotificationHistory entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildStatusIcon(entry.status),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(entry.sentAt),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusChip(entry.status),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleHistoryAction(value, entry),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'copy',
                      child: Text('Copy payload'),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: Text('Export JSON'),
                    ),
                    if (entry.status.toLowerCase() != 'success')
                      const PopupMenuItem(
                        value: 'retry',
                        child: Text('Retry send'),
                      ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Body
                Text(
                  'Body:',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(entry.body),
                const SizedBox(height: 16),

                // Target info -- show summary + expand for more
                if (entry.topic != null) ...[
                  Text(
                    'Topic:',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Chip(
                        label: Text(entry.topic!),
                        avatar: const Icon(Icons.topic, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${entry.targetTokens.length} target token(s)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.copy_outlined),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: entry.topic!),
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Topic copied to clipboard'),
                            ),
                          );
                        },
                        tooltip: 'Copy topic',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else if (entry.targetTokens.isNotEmpty) ...[
                  Text(
                    'Target Tokens: ${entry.targetTokens.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: entry.targetTokens.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final t = entry.targetTokens[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 240,
                                child: Text(
                                  t.length > 40
                                      ? '${t.substring(0, 30)}...${t.substring(t.length - 8)}'
                                      : t,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.copy_outlined, size: 18),
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: t),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Token copied'),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Image URL
                if (entry.imageUrl != null) ...[
                  Text(
                    'Image URL:',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.imageUrl!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_new_outlined),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Open image in browser (not implemented)',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Data
                if (entry.data.isNotEmpty) ...[
                  Text(
                    'Data Pairs:',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.data.entries.map((kv) {
                      return Chip(
                        label: Text('${kv.key}: ${kv.value}'),
                        avatar: const Icon(Icons.data_object, size: 20),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Error message
                if (entry.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade800,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
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

  Widget _buildStatusChip(String status) {
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

  void _handleHistoryAction(String action, NotificationHistory entry) async {
    switch (action) {
      case 'copy':
        final payload = {
          'title': entry.title,
          'body': entry.body,
          'imageUrl': entry.imageUrl,
          'topic': entry.topic,
          'data': entry.data,
          'tokens': entry.targetTokens,
          'status': entry.status,
          'sentAt': entry.sentAt.toIso8601String(),
        };
        await Clipboard.setData(ClipboardData(text: jsonEncode(payload)));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payload copied to clipboard')),
        );
        break;
      case 'export':
        // Placeholder: export not implemented, show snackbar
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exported JSON (not implemented)')),
        );
        break;
      case 'retry':
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Retry not implemented')),
          );
        }
        break;
      case 'delete':
        try {
          final db = ref.read(databaseServiceProvider);
          await db.deleteNotificationHistory(entry.id);
          ref.invalidate(notificationHistoryProvider(entry.serviceAccountId));
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Deleted notification history')),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
        break;
    }
  }

  String _formatDate(DateTime date) {
    final d = date.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year;
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day/$month/$year at $hour:$minute';
  }
}
