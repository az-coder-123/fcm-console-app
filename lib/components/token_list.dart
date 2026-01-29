import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/device_token.dart';
import '../providers/notification_form_state.dart';
import '../providers/providers.dart';
import 'token_list/error_message.dart';
import 'token_list/info_bar.dart';
import 'token_list/search_filters.dart';
import 'token_list/selected_counter.dart';
import 'token_list/token_list_service.dart';
import 'token_list/tokens_area.dart';
import 'token_list/top_actions.dart';

/// Token list component for displaying device tokens from Supabase
/// Displays fetched tokens with filtering and selection capabilities
class TokenList extends ConsumerStatefulWidget {
  const TokenList({super.key});

  @override
  ConsumerState<TokenList> createState() => _TokenListState();
}

class _TokenListState extends ConsumerState<TokenList> {
  List<DeviceToken> _tokens = [];
  bool _isLoading = false;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  String _platformFilter = 'All'; // All, iOS, Android, Web

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeAccountAsync = ref.watch(activeServiceAccountProvider);
    final supabaseService = ref.watch(supabaseServiceProvider);
    final formState = ref.watch(notificationFormProvider);

    final visibleTokens = _filterTokens(
      _tokens,
      _searchController.text,
      _platformFilter,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Tokens'),
        elevation: 0,
        actions: [
          if (_tokens.isNotEmpty)
            IconButton(
              icon: Icon(
                formState.selectedTokens.isEmpty
                    ? Icons.select_all
                    : Icons.check_box,
              ),
              onPressed: _toggleSelectionMode,
              tooltip: 'Toggle Selection',
            ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            Text(
              'View and select device tokens from your Supabase database.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Active profile check
            activeAccountAsync.when(
              data: (account) {
                if (account == null) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange.shade800),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Please select a Firebase Service Account profile first',
                            style: TextStyle(color: Colors.orange.shade800),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const SizedBox.shrink(),
            ),

            if (activeAccountAsync.value != null) ...[
              const SizedBox(height: 24),

              TokenListTopActions(
                isLoading: _isLoading,
                onFetch: _fetchTokens,
                onSelectAll: _selectAllVisibleTokens,
                onClear: () => ref
                    .read(notificationFormProvider.notifier)
                    .clearSelectedTokens(),
                selectAllEnabled: visibleTokens.isNotEmpty,
              ),

              const SizedBox(height: 12),

              TokenListSearchFilters(
                searchController: _searchController,
                platformFilter: _platformFilter,
                onSearchChanged: () => setState(() {}),
                onPlatformSelected: (p) => setState(() => _platformFilter = p),
              ),

              const SizedBox(height: 12),

              TokenListInfoBar(
                visibleCount: visibleTokens.length,
                selectedCount: formState.selectedTokens.length,
                errorMessage: _errorMessage,
              ),

              const SizedBox(height: 12),

              if (_errorMessage != null)
                TokenListErrorMessage(
                  message: _errorMessage!,
                  onClose: () => setState(() => _errorMessage = null),
                ),

              if (formState.selectedTokens.isNotEmpty)
                TokenListSelectedCounter(
                  selectedCount: formState.selectedTokens.length,
                  onClear: () => ref
                      .read(notificationFormProvider.notifier)
                      .clearSelectedTokens(),
                ),

              // Tokens list area
              Expanded(
                child: TokenListArea(
                  hasTokens: _tokens.isNotEmpty,
                  visibleTokens: visibleTokens,
                  isInitialized: supabaseService.isInitialized,
                  selectedTokens: formState.selectedTokens,
                  onToggleToken: _toggleTokenSelection,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleTokenSelection(String token) {
    ref.read(notificationFormProvider.notifier).toggleToken(token);
  }

  void _toggleSelectionMode() {
    final formState = ref.read(notificationFormProvider);
    if (formState.selectedTokens.isEmpty) {
      // Select all
      for (final token in _tokens) {
        ref.read(notificationFormProvider.notifier).toggleToken(token.token);
      }
    } else {
      // Deselect all
      ref.read(notificationFormProvider.notifier).clearSelectedTokens();
    }
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
      if (q.isEmpty) {
        return true;
      }
      return (t.token.toLowerCase().contains(q) ||
          (t.userId ?? '').toLowerCase().contains(q));
    }).toList();
  }

  Future<void> _fetchTokens() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      final tokens = await TokenListService.fetchTokensWithInit(
        ref,
        supabaseService,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _tokens = tokens;
        _errorMessage = null;
      });

      // Clear previous selections
      ref.read(notificationFormProvider.notifier).clearSelectedTokens();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fetched ${tokens.length} device tokens'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error fetching tokens: $e');
      debugPrintStack();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching tokens: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _selectAllVisibleTokens() {
    final visibleTokens = _filterTokens(
      _tokens,
      _searchController.text,
      _platformFilter,
    );
    for (final t in visibleTokens) {
      ref.read(notificationFormProvider.notifier).toggleToken(t.token);
    }
  }
}
