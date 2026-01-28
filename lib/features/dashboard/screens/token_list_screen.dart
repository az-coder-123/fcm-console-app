/// Token list screen showing device tokens from Supabase.
library;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/ui/app_theme.dart';
import '../../../core/utils/extensions.dart';
import '../../../providers/providers.dart';

/// Screen displaying the list of device tokens.
class TokenListScreen extends ConsumerStatefulWidget {
  const TokenListScreen({super.key});

  @override
  ConsumerState<TokenListScreen> createState() => _TokenListScreenState();
}

class _TokenListScreenState extends ConsumerState<TokenListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _platformFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(supabaseConfigProvider);
    final tokensAsync = ref.watch(deviceTokensProvider);

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Device Tokens'),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Refresh'),
              onPressed: () =>
                  ref.read(deviceTokensProvider.notifier).refresh(),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.check_list),
              label: const Text('Select All'),
              onPressed: () =>
                  ref.read(deviceTokensProvider.notifier).selectAll(),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.cancel),
              label: const Text('Deselect All'),
              onPressed: () =>
                  ref.read(deviceTokensProvider.notifier).deselectAll(),
            ),
          ],
        ),
      ),
      content: configAsync.when(
        loading: () => AppWidgets.loading(),
        error: (error, _) => AppWidgets.errorState(message: error.toString()),
        data: (config) {
          if (config == null || !config.isValid) {
            return AppWidgets.emptyState(
              icon: FluentIcons.database,
              title: 'Supabase Not Configured',
              subtitle: 'Please configure Supabase settings first.',
            );
          }

          return tokensAsync.when(
            loading: () => AppWidgets.loading('Loading tokens...'),
            error: (error, _) => AppWidgets.errorState(
              message: 'Failed to load tokens: $error',
              onRetry: () => ref.read(deviceTokensProvider.notifier).refresh(),
            ),
            data: (tokens) => _buildTokenList(tokens),
          );
        },
      ),
    );
  }

  Widget _buildTokenList(List<DeviceToken> tokens) {
    if (tokens.isEmpty) {
      return AppWidgets.emptyState(
        icon: FluentIcons.cell_phone,
        title: 'No Device Tokens',
        subtitle: 'No device tokens found in the configured Supabase table.',
        action: Button(
          onPressed: () => ref.read(deviceTokensProvider.notifier).refresh(),
          child: const Text('Refresh'),
        ),
      );
    }

    final filteredTokens = _filterTokens(tokens);
    final selectedCount = tokens.where((t) => t.isSelected).length;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilters(),
          const SizedBox(height: AppSpacing.md),
          InfoBar(
            title: Text('$selectedCount of ${tokens.length} tokens selected'),
            content: Text('Showing ${filteredTokens.length} tokens'),
            severity: InfoBarSeverity.info,
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(child: _buildTokenTable(filteredTokens)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: TextBox(
            controller: _searchController,
            placeholder: 'Search tokens or user IDs...',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(FluentIcons.search),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value.toLowerCase());
            },
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        ComboBox<String>(
          value: _platformFilter,
          items: [
            'All',
            'android',
            'ios',
            'web',
          ].map((p) => ComboBoxItem(value: p, child: Text(p))).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _platformFilter = value);
            }
          },
        ),
      ],
    );
  }

  List<DeviceToken> _filterTokens(List<DeviceToken> tokens) {
    return tokens.where((token) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          token.token.toLowerCase().contains(_searchQuery) ||
          (token.userId?.toLowerCase().contains(_searchQuery) ?? false);

      final matchesPlatform =
          _platformFilter == 'All' ||
          token.platform?.toLowerCase() == _platformFilter.toLowerCase();

      return matchesSearch && matchesPlatform;
    }).toList();
  }

  Widget _buildTokenTable(List<DeviceToken> tokens) {
    return ListView.builder(
      itemCount: tokens.length,
      itemBuilder: (context, index) {
        final token = tokens[index];
        return _TokenListTile(
          token: token,
          onToggleSelection: () {
            ref.read(deviceTokensProvider.notifier).toggleSelection(token.id);
          },
        );
      },
    );
  }
}

/// List tile for a single token.
class _TokenListTile extends StatelessWidget {
  const _TokenListTile({required this.token, required this.onToggleSelection});

  final DeviceToken token;
  final VoidCallback onToggleSelection;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        backgroundColor: token.isSelected ? Colors.blue.withAlpha(30) : null,
        borderColor: token.isSelected ? Colors.blue : null,
        child: Row(
          children: [
            Checkbox(
              checked: token.isSelected,
              onChanged: (_) => onToggleSelection(),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    token.token.truncate(50),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (token.userId != null) ...[
                        Icon(
                          FluentIcons.contact,
                          size: 12,
                          color: Colors.grey[120],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          token.userId!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[120],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      if (token.platform != null) _buildPlatformBadge(),
                      const Spacer(),
                      if (token.updatedAt != null)
                        Text(
                          token.updatedAt!.toFormattedString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[120],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformBadge() {
    final platform = token.platform!;
    Color color;
    switch (platform.toLowerCase()) {
      case 'android':
        color = Colors.green;
      case 'ios':
        color = Colors.blue;
      case 'web':
        color = Colors.orange;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(50),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        platform.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
