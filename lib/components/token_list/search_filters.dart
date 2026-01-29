import 'package:flutter/material.dart';

/// Search input and platform filters
class TokenListSearchFilters extends StatelessWidget {
  final TextEditingController searchController;
  final String platformFilter;
  final VoidCallback onSearchChanged;
  final ValueChanged<String> onPlatformSelected;

  const TokenListSearchFilters({
    required this.searchController,
    required this.platformFilter,
    required this.onSearchChanged,
    required this.onPlatformSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            onChanged: (_) => onSearchChanged(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search tokens or userId',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Wrap(
          spacing: 8,
          children: ['All', 'iOS', 'Android', 'Web'].map((platform) {
            final selected = platformFilter == platform;
            return ChoiceChip(
              label: Text(platform),
              selected: selected,
              onSelected: (_) => onPlatformSelected(platform),
            );
          }).toList(),
        ),
      ],
    );
  }
}
