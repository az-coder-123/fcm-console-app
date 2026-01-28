import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final bool isLoading;
  final bool isInitialized;
  final VoidCallback onSave;
  final VoidCallback onTest;
  final VoidCallback onClear;

  const ActionButtons({
    super.key,
    required this.isLoading,
    required this.isInitialized,
    required this.onSave,
    required this.onTest,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onSave,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(isLoading ? 'Saving...' : 'Save Configuration'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading || !isInitialized ? null : onTest,
                icon: const Icon(Icons.wifi_tethering),
                label: const Text('Test Connection'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: isLoading ? null : onClear,
            icon: const Icon(Icons.clear),
            label: const Text('Clear Configuration'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ),
      ],
    );
  }
}
