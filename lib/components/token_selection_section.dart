import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/device_token.dart';
import '../providers/notification_form_state.dart';
import '../providers/providers.dart';
import 'token_list/token_list_service.dart';

/// Token selection section for sending notifications to device tokens
/// Enhanced UI: search, platform filters, select-all, copy and metadata
class TokenSelectionSection extends ConsumerStatefulWidget {
  const TokenSelectionSection({super.key});

  @override
  ConsumerState<TokenSelectionSection> createState() =>
      _TokenSelectionSectionState();
}

class _TokenSelectionSectionState extends ConsumerState<TokenSelectionSection> {
  bool _isLoadingTokens = false;
  List<DeviceToken> _availableTokens = [];
  String? _tokenError;

  final TextEditingController _searchController = TextEditingController();
  String _platformFilter = 'All'; // 'All', 'iOS', 'Android', 'Web'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(notificationFormProvider);

    if (formState.sendToTopic) {
      return const SizedBox.shrink();
    }

    final visibleTokens = _filterTokens(
      _availableTokens,
      _searchController.text,
      _platformFilter,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Text(
                'Select Device Tokens',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton.icon(
              onPressed: _isLoadingTokens ? null : _fetchTokensForSelection,
              icon: _isLoadingTokens
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_isLoadingTokens ? 'Loading...' : 'Fetch Tokens'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: visibleTokens.isEmpty ? null : _selectAllVisibleTokens,
              child: const Text('Select All'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => ref
                  .read(notificationFormProvider.notifier)
                  .clearSelectedTokens(),
              child: const Text('Clear'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Search and platform filters
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
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
                final selected = _platformFilter == platform;
                return ChoiceChip(
                  label: Text(platform),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _platformFilter = platform;
                  }),
                );
              }).toList(),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Info bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text('${visibleTokens.length} tokens'),
              const SizedBox(width: 12),
              const VerticalDivider(width: 1),
              const SizedBox(width: 12),
              Text('${formState.selectedTokens.length} selected'),
              const Spacer(),
              if (_tokenError != null)
                Flexible(
                  child: Text(
                    _tokenError!,
                    style: TextStyle(color: Colors.red.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Token list or empty state
        if (_availableTokens.isEmpty && !_isLoadingTokens)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              'No tokens available. Click "Fetch Tokens" to load device tokens.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else if (visibleTokens.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleTokens.length,
              separatorBuilder: (context, index) => const Divider(height: 0),
              itemBuilder: (context, index) {
                final token = visibleTokens[index];
                final isSelected = formState.selectedTokens.contains(
                  token.token,
                );

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Icon(_getPlatformIcon(token.platform), size: 18),
                  ),
                  title: Tooltip(
                    message: token.token,
                    child: Text(
                      _shortenToken(token.token),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (token.userId != null) Text('User: ${token.userId}'),
                      Text('Platform: ${token.platform ?? 'Unknown'}'),
                      Row(
                        children: [
                          if (token.lastActive != null)
                            Text('Last: ${_formatDate(token.lastActive)}'),
                          const SizedBox(width: 12),
                          if (token.createdAt != null)
                            Text('Created: ${_formatDate(token.createdAt)}'),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isSelected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                        ),
                        onPressed: () => ref
                            .read(notificationFormProvider.notifier)
                            .toggleToken(token.token),
                        tooltip: isSelected ? 'Deselect token' : 'Select token',
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_outlined),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: token.token),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Token copied to clipboard'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        else if (visibleTokens.isEmpty && !_isLoadingTokens)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              'No tokens match your filters.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),

        const SizedBox(height: 16),
      ],
    );
  }

  List<DeviceToken> _filterTokens(
    List<DeviceToken> tokens,
    String query,
    String platform,
  ) {
    final q = query.trim().toLowerCase();
    return tokens.where((t) {
      if (platform != 'All' &&
          (t.platform ?? '').toLowerCase() != platform.toLowerCase()) {
        return false;
      }
      if (q.isEmpty) return true;
      return (t.token.toLowerCase().contains(q) ||
          (t.userId ?? '').toLowerCase().contains(q));
    }).toList();
  }

  IconData _getPlatformIcon(String? platform) {
    switch ((platform ?? '').toLowerCase()) {
      case 'ios':
        return Icons.phone_iphone;
      case 'android':
        return Icons.android;
      case 'web':
        return Icons.language;
      default:
        return Icons.device_unknown;
    }
  }

  String _shortenToken(String token) {
    if (token.length <= 36) return token;
    return '${token.substring(0, 20)}...${token.substring(token.length - 8)}';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    final d = dt.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _fetchTokensForSelection() async {
    setState(() {
      _isLoadingTokens = true;
      _tokenError = null;
    });

    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      final tokens = await TokenListService.fetchTokensWithInit(
        ref,
        supabaseService,
      );

      if (mounted) {
        setState(() {
          _isLoadingTokens = false;
          _availableTokens = tokens;
          _tokenError = null;
        });
        if (tokens.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fetched ${tokens.length} device tokens'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching tokens: $e');
      if (mounted) {
        setState(() {
          _isLoadingTokens = false;
          _tokenError = e.toString();
        });
      }
    }
  }

  void _selectAllVisibleTokens() {
    final visibleTokens = _filterTokens(
      _availableTokens,
      _searchController.text,
      _platformFilter,
    );
    for (final t in visibleTokens) {
      ref.read(notificationFormProvider.notifier).toggleToken(t.token);
    }
  }
}
