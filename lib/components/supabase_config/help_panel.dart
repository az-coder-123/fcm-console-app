import 'package:flutter/material.dart';

class HelpPanel extends StatelessWidget {
  const HelpPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Help',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Supabase configuration is required to fetch device tokens. Make sure your fcm_user_tokens table is properly set up.',
                  style: TextStyle(color: onSurfaceVariant, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
