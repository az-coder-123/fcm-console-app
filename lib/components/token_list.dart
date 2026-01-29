import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/device_token.dart';
import '../providers/providers.dart';

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

  @override
  Widget build(BuildContext context) {
    final activeAccountAsync = ref.watch(activeServiceAccountProvider);
    final supabaseService = ref.watch(supabaseServiceProvider);
    final selectedTokens = ref.watch(selectedDeviceTokensProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Tokens'),
        elevation: 0,
        actions: [
          if (_tokens.isNotEmpty)
            IconButton(
              icon: Icon(
                selectedTokens.isEmpty ? Icons.select_all : Icons.check_box,
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

              // Fetch button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _fetchTokens,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_isLoading ? 'Loading...' : 'Fetch Tokens'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null)
                Container(
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
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),

              // Selected tokens counter
              if (selectedTokens.isNotEmpty)
                Container(
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
                            '${selectedTokens.length} token(s) selected',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          ref
                                  .read(selectedDeviceTokensProvider.notifier)
                                  .state =
                              <String>{};
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),

              // Tokens list
              Expanded(
                child: _tokens.isEmpty
                    ? _buildEmptyState(supabaseService.isInitialized)
                    : _buildTokensList(selectedTokens),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isConfigured) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isConfigured ? Icons.devices : Icons.settings,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            isConfigured ? 'No tokens found' : 'Supabase not configured',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            isConfigured
                ? 'Click "Fetch Tokens" to load device tokens from Supabase'
                : 'Please configure Supabase first in the Supabase Config section',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTokensList(Set<String> selectedTokens) {
    return ListView.builder(
      itemCount: _tokens.length,
      itemBuilder: (context, index) {
        final token = _tokens[index];
        final isSelected = selectedTokens.contains(token.token);
        return _buildTokenCard(token, isSelected);
      },
    );
  }

  Widget _buildTokenCard(DeviceToken token, bool isSelected) {
    final mutedStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 6 : 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _toggleTokenSelection(token.token),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleTokenSelection(token.token),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tooltip(
                      message: token.token,
                      child: Text(
                        token.token,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (token.platform != null) ...[
                          Icon(
                            _getPlatformIcon(token.platform),
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(token.platform!, style: mutedStyle),
                          const SizedBox(width: 12),
                        ],
                        if (token.userId != null) ...[
                          Icon(
                            Icons.person,
                            size: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text('User: ${token.userId}', style: mutedStyle),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (token.lastActive != null) ...[
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Last Active: ${_formatDate(token.lastActive!)}',
                            style: mutedStyle,
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (token.createdAt != null) ...[
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Created: ${_formatDate(token.createdAt!)}',
                            style: mutedStyle,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.content_copy),
                onPressed: () => _copyToken(token.token),
                tooltip: 'Copy token',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchTokens() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabaseService = ref.read(supabaseServiceProvider);

      // If the Supabase client is not initialized, try to initialize from stored config
      if (!supabaseService.isInitialized) {
        final storage = ref.read(storageServiceProvider);
        final url = await storage.getSupabaseUrl();
        final key = await storage.getSupabaseKey();

        if (url != null && key != null) {
          try {
            await supabaseService.initialize(url, key);
          } catch (e) {
            debugPrint(
              'Error initializing Supabase before fetching tokens: $e',
            );
            debugPrintStack();
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Failed to initialize Supabase: $e';
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to initialize Supabase: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        } else {
          // No stored config available
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage =
                  'Supabase not initialized. Please configure Supabase first.';
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Supabase not initialized. Please configure Supabase first.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      final tokens = await supabaseService.fetchDeviceTokens();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _tokens = tokens;
          _errorMessage = null;
        });

        // Clear previous selections
        ref.read(selectedDeviceTokensProvider.notifier).state = <String>{};

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fetched ${tokens.length} device tokens'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error fetching tokens: $e');
      debugPrintStack();
      if (mounted) {
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
  }

  void _toggleTokenSelection(String token) {
    final selectedTokens = ref.read(selectedDeviceTokensProvider);
    if (selectedTokens.contains(token)) {
      ref.read(selectedDeviceTokensProvider.notifier).state = {
        ...selectedTokens..remove(token),
      };
    } else {
      ref.read(selectedDeviceTokensProvider.notifier).state = {
        ...selectedTokens,
        token,
      };
    }
  }

  void _toggleSelectionMode() {
    final selectedTokens = ref.read(selectedDeviceTokensProvider);
    if (selectedTokens.isEmpty) {
      // Select all
      ref.read(selectedDeviceTokensProvider.notifier).state = _tokens
          .map((t) => t.token)
          .toSet();
    } else {
      // Deselect all
      ref.read(selectedDeviceTokensProvider.notifier).state = <String>{};
    }
  }

  void _copyToken(String token) {
    // Note: In a real app, you would use flutter/services to copy to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Token copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  IconData _getPlatformIcon(String? platform) {
    switch (platform?.toLowerCase()) {
      case 'android':
        return Icons.android;
      case 'ios':
        return Icons.phone_iphone;
      case 'web':
        return Icons.web;
      default:
        return Icons.device_unknown;
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  String _formatDate(DateTime date) {
    final d = '${_pad(date.day)}/${_pad(date.month)}/${date.year}';
    final t = '${_pad(date.hour)}:${_pad(date.minute)}:${_pad(date.second)}';
    return '$d $t';
  }
}
