import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_account.dart';

/// Shared banner shown when no active profile is selected.
class ProfileRequiredBanner extends StatelessWidget {
  const ProfileRequiredBanner({super.key, required this.activeAccountAsync});

  final AsyncValue<ServiceAccount?> activeAccountAsync;

  @override
  Widget build(BuildContext context) {
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
}
