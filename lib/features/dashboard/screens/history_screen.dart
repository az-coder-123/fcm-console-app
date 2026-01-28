/// Notification history screen.
library;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/ui/app_theme.dart';
import '../../../core/utils/extensions.dart';
import '../../../providers/providers.dart';

/// Screen displaying the notification history.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(notificationHistoryProvider);
    final activeProfile = ref.watch(activeServiceAccountProvider);

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Notification History'),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Refresh'),
              onPressed: () =>
                  ref.read(notificationHistoryProvider.notifier).refresh(),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.delete),
              label: const Text('Clear All'),
              onPressed: () => _confirmClearAll(context, ref),
            ),
          ],
        ),
      ),
      content: activeProfile.when(
        loading: () => AppWidgets.loading(),
        error: (error, _) => AppWidgets.errorState(message: error.toString()),
        data: (profile) {
          if (profile == null) {
            return AppWidgets.emptyState(
              icon: FluentIcons.history,
              title: 'No Active Profile',
              subtitle: 'Please select a Service Account profile first.',
            );
          }

          return historyAsync.when(
            loading: () => AppWidgets.loading('Loading history...'),
            error: (error, _) => AppWidgets.errorState(
              message: 'Failed to load history: $error',
              onRetry: () =>
                  ref.read(notificationHistoryProvider.notifier).refresh(),
            ),
            data: (history) => _buildHistoryList(context, ref, history),
          );
        },
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    WidgetRef ref,
    List<NotificationHistory> history,
  ) {
    if (history.isEmpty) {
      return AppWidgets.emptyState(
        icon: FluentIcons.history,
        title: 'No History',
        subtitle: 'Sent notifications will appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return _HistoryCard(
          history: item,
          onDelete: () => _confirmDelete(context, ref, item),
          onViewDetails: () => _showDetails(context, item),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    NotificationHistory item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Delete History'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          Button(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(notificationHistoryProvider.notifier).delete(item.id);
    }
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Clear All History'),
        content: const Text(
          'Are you sure you want to delete all notification history?',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(notificationHistoryProvider.notifier).clearAll();
    }
  }

  void _showDetails(BuildContext context, NotificationHistory item) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Notification Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Title', item.title),
              _detailRow('Body', item.body),
              _detailRow('Type', item.targetType.value.toUpperCase()),
              _detailRow('Targets', item.targets.join(', ').truncate(100)),
              _detailRow('Status', item.status.value.toUpperCase()),
              _detailRow('Sent At', item.timestamp.toFormattedString()),
              if (item.imageUrl != null)
                _detailRow('Image URL', item.imageUrl!),
              if (item.data != null) _detailRow('Data', item.data!),
              if (item.errorMessage != null)
                _detailRow('Error', item.errorMessage!),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }
}

/// Card widget for displaying a history item.
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.history,
    required this.onDelete,
    required this.onViewDetails,
  });

  final NotificationHistory history;
  final VoidCallback onDelete;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusIcon(),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          history.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      _buildStatusBadge(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    history.body.truncate(100),
                    style: TextStyle(color: Colors.grey[120]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        history.targetType == NotificationTargetType.topic
                            ? FluentIcons.people
                            : FluentIcons.cell_phone,
                        size: 14,
                        color: Colors.grey[120],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        history.targetType == NotificationTargetType.topic
                            ? 'Topic: ${history.targets.first}'
                            : '${history.targets.length} device(s)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[120]),
                      ),
                      const Spacer(),
                      Text(
                        history.timestamp.toFormattedString(),
                        style: TextStyle(fontSize: 12, color: Colors.grey[120]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              children: [
                IconButton(
                  icon: const Icon(FluentIcons.info),
                  onPressed: onViewDetails,
                ),
                IconButton(
                  icon: Icon(FluentIcons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (history.status) {
      case NotificationStatus.success:
        icon = FluentIcons.check_mark;
        color = Colors.green;
      case NotificationStatus.partial:
        icon = FluentIcons.warning;
        color = Colors.orange;
      case NotificationStatus.failed:
        icon = FluentIcons.error;
        color = Colors.red;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;

    switch (history.status) {
      case NotificationStatus.success:
        color = Colors.green;
        text = 'SUCCESS';
      case NotificationStatus.partial:
        color = Colors.orange;
        text = 'PARTIAL';
      case NotificationStatus.failed:
        color = Colors.red;
        text = 'FAILED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
