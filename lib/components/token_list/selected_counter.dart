import 'package:flutter/material.dart';

/// Selected tokens counter with clear action
class TokenListSelectedCounter extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onClear;

  const TokenListSelectedCounter({
    required this.selectedCount,
    required this.onClear,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.blue.shade800),
              const SizedBox(width: 12),
              Text(
                '$selectedCount token(s) selected',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          TextButton(onPressed: onClear, child: const Text('Clear')),
        ],
      ),
    );
  }
}
