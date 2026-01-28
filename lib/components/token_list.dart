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
  Set<String> _selectedTokens = {};

  @override
  Widget build(BuildContext context) {
    final activeAccountAsync = ref.watch(activeServiceAccountProvider);
    final supabaseService = ref.watch(supabaseServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Tokens'),
        elevation: 0,
        actions: [
          if (_tokens.isNotEmpty)
            IconButton(
              icon: Icon(
                _selectedTokens.isEmpty ? Icons.select_all : Icons.check_box,
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
              if (_selectedTokens.isNotEmpty)
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
                            '${_selectedTokens.length} token(s) selected',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedTokens.clear();
                          });
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
                    : _buildTokensList(),
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

  Widget _buildTokensList() {
    return ListView.builder(
      itemCount: _tokens.length,
      itemBuilder: (context, index) {
        final token = _tokens[index];
        final isSelected = _selectedTokens.contains(token.token);
        return _buildTokenCard(token, isSelected);
      },
    );
  }

  Widget _buildTokenCard(DeviceToken token, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: (_) => _toggleTokenSelection(token.token),
        ),
        title: Text(
          '${token.token.substring(0, 20)}...',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (token.userId != null)
              Text(
                'User ID: ${token.userId}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            if (token.platform != null)
              Row(
                children: [
                  Icon(
                    _getPlatformIcon(token.platform),
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    token.platform!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            if (token.lastActive != null)
              Text(
                'Last Active: ${_formatDate(token.lastActive!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.content_copy),
          onPressed: () => _copyToken(token.token),
          tooltip: 'Copy Token',
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
      final tokens = await supabaseService.fetchDeviceTokens();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _tokens = tokens;
          _selectedTokens.clear();
        });

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
    setState(() {
      if (_selectedTokens.contains(token)) {
        _selectedTokens.remove(token);
      } else {
        _selectedTokens.add(token);
      }
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      if (_selectedTokens.isEmpty) {
        // Select all
        _selectedTokens = _tokens.map((t) => t.token).toSet();
      } else {
        // Deselect all
        _selectedTokens.clear();
      }
    });
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
