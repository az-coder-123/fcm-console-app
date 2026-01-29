import 'package:flutter/material.dart';

/// Error message panel with close action
class TokenListErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const TokenListErrorMessage({
    required this.message,
    required this.onClose,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.red.shade800)),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: onClose),
        ],
      ),
    );
  }
}
