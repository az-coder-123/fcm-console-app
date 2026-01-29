import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/device_token.dart';
import '../providers/notification_form_state.dart';
import '../providers/providers.dart';

/// Token selection section for sending notifications to device tokens
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

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(notificationFormProvider);

    if (formState.sendToTopic) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Device Tokens',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),

        // Fetch tokens button and error message
        Row(
          children: [
            ElevatedButton.icon(
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
            if (_tokenError != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _tokenError!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
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
        else if (_availableTokens.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _availableTokens.length,
              itemBuilder: (context, index) {
                final token = _availableTokens[index];
                final isSelected = formState.selectedTokens.contains(
                  token.token,
                );

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    ref
                        .read(notificationFormProvider.notifier)
                        .toggleToken(token.token);
                  },
                  title: Text(
                    token.token,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  subtitle: Text(
                    'Platform: ${token.platform ?? 'Unknown'}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _fetchTokensForSelection() async {
    setState(() {
      _isLoadingTokens = true;
      _tokenError = null;
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
            debugPrint('Error initializing Supabase: $e');
            if (mounted) {
              setState(() {
                _isLoadingTokens = false;
                _tokenError = 'Failed to initialize Supabase: $e';
              });
            }
            return;
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoadingTokens = false;
              _tokenError =
                  'Supabase not initialized. Please configure Supabase first.';
            });
          }
          return;
        }
      }

      final tokens = await supabaseService.fetchDeviceTokens();

      if (mounted) {
        setState(() {
          _isLoadingTokens = false;
          _availableTokens = tokens;
          _tokenError = null;
        });
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
}
