import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import 'notification_history/notification_history_card.dart';
import 'page_header.dart';
import 'profile_required_banner.dart';

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
      appBar: AppBar(elevation: 0, toolbarHeight: 0),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const PageHeader(
              title: 'Notification History',
              subtitle:
                  'View history of sent notifications for the active profile.',
            ),
            const SizedBox(height: 24),

            // Active profile check
            ProfileRequiredBanner(activeAccountAsync: activeAccountAsync),
            activeAccountAsync.when(
              data: (account) {
                if (account == null) {
                  return const SizedBox.shrink();
                }
                return _buildHistoryList(account.id);
              },
              loading: () => const SizedBox.shrink(),
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
              return NotificationHistoryCard(entry: entry);
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
}
