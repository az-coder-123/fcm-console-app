import 'package:flutter/material.dart';

/// Info bar showing counts and optional error
class TokenListInfoBar extends StatelessWidget {
  final int visibleCount;
  final int selectedCount;
  final String? errorMessage;

  const TokenListInfoBar({
    required this.visibleCount,
    required this.selectedCount,
    this.errorMessage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text('$visibleCount tokens'),
          const SizedBox(width: 12),
          const VerticalDivider(width: 1),
          const SizedBox(width: 12),
          Text('$selectedCount selected'),
          const Spacer(),
          if (errorMessage != null)
            Flexible(
              child: Text(
                errorMessage!,
                style: TextStyle(color: Colors.red.shade700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
