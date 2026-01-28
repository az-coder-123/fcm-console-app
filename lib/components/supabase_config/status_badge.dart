import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final bool isInitialized;
  const StatusBadge({super.key, required this.isInitialized});

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const SizedBox.shrink();
    }
    final color = Colors.green;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: color.shade800),
          const SizedBox(width: 12),
          Text(
            'Supabase is configured',
            style: TextStyle(
              color: color.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
