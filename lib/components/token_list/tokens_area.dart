import 'package:flutter/material.dart';

import '../../models/device_token.dart';
import 'token_card.dart';

/// Area that displays either empty state, no-match message, or token list
class TokenListArea extends StatelessWidget {
  final bool hasTokens;
  final List<DeviceToken> visibleTokens;
  final bool isInitialized;
  final Set<String> selectedTokens;
  final ValueChanged<String> onToggleToken;

  const TokenListArea({
    required this.hasTokens,
    required this.visibleTokens,
    required this.isInitialized,
    required this.selectedTokens,
    required this.onToggleToken,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasTokens) {
      return _buildEmptyState(context, isInitialized);
    }

    if (visibleTokens.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          'No tokens match your filters.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.separated(
      itemCount: visibleTokens.length,
      separatorBuilder: (context, index) => const Divider(height: 0),
      itemBuilder: (context, index) {
        final token = visibleTokens[index];
        final isSelected = selectedTokens.contains(token.token);
        return TokenCard(
          token: token,
          isSelected: isSelected,
          onTap: () => onToggleToken(token.token),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isConfigured) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isConfigured ? Icons.devices : Icons.settings,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            isConfigured ? 'No tokens found' : 'Supabase not configured',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            isConfigured
                ? 'Click "Fetch Tokens" to load device tokens from Supabase'
                : 'Please configure Supabase first in the Supabase Config section',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
