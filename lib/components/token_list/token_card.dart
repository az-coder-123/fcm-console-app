import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/device_token.dart';
import 'token_list_utils.dart';

/// Card widget for displaying a single device token
class TokenCard extends ConsumerWidget {
  final DeviceToken token;
  final bool isSelected;
  final VoidCallback onTap;

  const TokenCard({
    required this.token,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutedStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 6 : 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Checkbox(value: isSelected, onChanged: (_) => onTap),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Token value
                    Tooltip(
                      message: token.token,
                      child: Text(
                        token.token,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Platform and User ID
                    Row(
                      children: [
                        if (token.platform != null) ...[
                          Icon(
                            TokenListUtils.getPlatformIcon(token.platform),
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(token.platform!, style: mutedStyle),
                          const SizedBox(width: 12),
                        ],
                        if (token.userId != null) ...[
                          Icon(
                            Icons.person,
                            size: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text('User: ${token.userId}', style: mutedStyle),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Timestamps
                    Row(
                      children: [
                        if (token.lastActive != null) ...[
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Last Active: ${TokenListUtils.formatDate(token.lastActive!)}',
                            style: mutedStyle,
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (token.createdAt != null) ...[
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Created: ${TokenListUtils.formatDate(token.createdAt!)}',
                            style: mutedStyle,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.content_copy),
                onPressed: () => _copyToken(context),
                tooltip: 'Copy token',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyToken(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: token.token));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
