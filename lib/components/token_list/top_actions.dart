import 'package:flutter/material.dart';

/// Top header actions: Fetch, Select All, Clear
class TokenListTopActions extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onFetch;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;
  final bool selectAllEnabled;

  const TokenListTopActions({
    required this.isLoading,
    required this.onFetch,
    required this.onSelectAll,
    required this.onClear,
    required this.selectAllEnabled,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: isLoading ? null : onFetch,
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          label: Text(isLoading ? 'Loading...' : 'Fetch Tokens'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: selectAllEnabled ? onSelectAll : null,
          child: const Text('Select All'),
        ),
        const SizedBox(width: 8),
        TextButton(onPressed: onClear, child: const Text('Clear')),
      ],
    );
  }
}
