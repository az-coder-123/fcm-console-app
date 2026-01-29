import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Data pairs editor for adding custom key-value pairs to notifications
class DataPairsEditor extends ConsumerWidget {
  final Map<String, String> dataPairs;
  final Function(String, String) onAddPair;
  final Function(String) onRemovePair;

  const DataPairsEditor({
    required this.dataPairs,
    required this.onAddPair,
    required this.onRemovePair,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataKeyController = TextEditingController();
    final dataValueController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data Pairs (Optional)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),

        // Add data pair section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: dataKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Key',
                        hintText: 'e.g., action',
                        prefixIcon: Icon(Icons.vpn_key),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: dataValueController,
                      decoration: const InputDecoration(
                        labelText: 'Value',
                        hintText: 'e.g., open_app',
                        prefixIcon: Icon(Icons.text_fields),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _addDataPair(dataKeyController, dataValueController);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Pair'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Display data pairs
        if (dataPairs.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dataPairs.entries.length,
              itemBuilder: (context, index) {
                final entry = dataPairs.entries.elementAt(index);
                return ListTile(
                  leading: const Icon(Icons.data_object),
                  title: Text(entry.key),
                  subtitle: Text(entry.value),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      onRemovePair(entry.key);
                    },
                  ),
                );
              },
            ),
          )
        else if (dataPairs.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              'No data pairs added yet. Add custom key-value pairs to enhance your notifications.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
      ],
    );
  }

  void _addDataPair(
    TextEditingController keyController,
    TextEditingController valueController,
  ) {
    final key = keyController.text.trim();
    final value = valueController.text.trim();

    if (key.isEmpty || value.isEmpty) return;

    onAddPair(key, value);
    keyController.clear();
    valueController.clear();
  }
}
