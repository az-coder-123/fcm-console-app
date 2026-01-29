import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/notification_history.dart';
import '../../providers/providers.dart';
import 'notification_history_utils.dart';

/// Card component for displaying a single notification history entry
class NotificationHistoryCard extends ConsumerWidget {
  final NotificationHistory entry;

  const NotificationHistoryCard({required this.entry, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: NotificationHistoryUtils.buildStatusIcon(entry.status),
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
                    NotificationHistoryUtils.formatDate(entry.sentAt),
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
                NotificationHistoryUtils.buildStatusChip(entry.status),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      _handleHistoryAction(value, context, ref),
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
                _buildBodySection(context),
                const SizedBox(height: 16),
                if (entry.topic != null)
                  _buildTopicSection(context)
                else if (entry.targetTokens.isNotEmpty)
                  _buildTokensSection(context),
                if (entry.imageUrl != null) _buildImageSection(context),
                if (entry.data.isNotEmpty) _buildDataSection(context),
                if (entry.errorMessage != null) _buildErrorSection(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Body:',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(entry.body),
      ],
    );
  }

  Widget _buildTopicSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Topic:',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
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
                await Clipboard.setData(ClipboardData(text: entry.topic!));
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Topic copied to clipboard')),
                );
              },
              tooltip: 'Copy topic',
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTokensSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Tokens: ${entry.targetTokens.length}',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: entry.targetTokens.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final t = entry.targetTokens[i];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                        await Clipboard.setData(ClipboardData(text: t));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Token copied')),
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
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Image URL:',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                entry.imageUrl!,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new_outlined),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Open image in browser (not implemented)'),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDataSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data Pairs:',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildErrorSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade800, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.errorMessage!,
              style: TextStyle(color: Colors.red.shade800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleHistoryAction(
    String action,
    BuildContext context,
    WidgetRef ref,
  ) async {
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
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payload copied to clipboard')),
        );
        break;
      case 'export':
        if (!context.mounted) {
          return;
        }
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
          if (!context.mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Deleted notification history')),
          );
        } catch (e) {
          if (!context.mounted) {
            return;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
        break;
    }
  }
}
