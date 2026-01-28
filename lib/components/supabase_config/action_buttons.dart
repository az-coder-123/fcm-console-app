import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final bool isLoading;
  final bool isInitialized;
  final bool isSaveEnabled;
  final bool isInitializeEnabled;
  final VoidCallback onSave;
  final VoidCallback onInitialize;
  final VoidCallback onClear;

  const ActionButtons({
    super.key,
    required this.isLoading,
    required this.isInitialized,
    required this.isSaveEnabled,
    required this.isInitializeEnabled,
    required this.onSave,
    required this.onInitialize,
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
                onPressed: (isSaveEnabled && !isLoading) ? onSave : null,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(isLoading ? 'Saving...' : 'Save'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading || !isInitialized ? null : onClear,
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: isInitialized
                      ? Colors.red
                      : Colors.red.withAlpha(128),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading || !isInitializeEnabled
                    ? null
                    : onInitialize,
                icon: const Icon(Icons.power_settings_new),
                label: const Text('Initialize'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
