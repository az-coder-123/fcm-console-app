import 'package:fcmapp/components/supabase_config/form_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// Supabase configuration component
/// Allows users to configure Supabase connection for the active profile
class SupabaseConfig extends ConsumerStatefulWidget {
  const SupabaseConfig({super.key});

  @override
  ConsumerState<SupabaseConfig> createState() => _SupabaseConfigState();
}

class _SupabaseConfigState extends ConsumerState<SupabaseConfig> {
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureKey = true;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final storage = ref.read(storageServiceProvider);
    final url = await storage.getSupabaseUrl();
    final key = await storage.getSupabaseKey();

    if (mounted) {
      setState(() {
        _urlController.text = url ?? '';
        _keyController.text = key ?? '';
        _isInitialized = url != null && key != null;
      });
    }
  }

  Future<void> _saveConfig() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showSnack('Please fix validation errors', backgroundColor: Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final storage = ref.read(storageServiceProvider);
      await storage.setSupabaseUrl(_urlController.text.trim());
      await storage.setSupabaseKey(_keyController.text.trim());

      // Initialize Supabase client
      final supabaseService = ref.read(supabaseServiceProvider);
      await supabaseService.initialize(
        _urlController.text.trim(),
        _keyController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialized = true;
        });

        _showSnack(
          'Supabase configuration saved',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      debugPrint('Error saving Supabase config: $e');
      debugPrintStack();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        _showSnack(
          'Error saving configuration: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  void _showSnack(String message, {Color? backgroundColor}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  Future<void> _testConnection() async {
    final activeAccount = ref.read(activeServiceAccountProvider).value;
    if (activeAccount == null) {
      _showSnack('Please select a profile first', backgroundColor: Colors.red);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
    });

    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      final success = await supabaseService.testConnection();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        _showSnack(
          success
              ? 'Connection successful!'
              : 'Connection failed. Please check your credentials.',
          backgroundColor: success ? Colors.green : Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        _showSnack('Connection test failed: $e', backgroundColor: Colors.red);
      }
    }
  }

  Future<void> _clearConfig() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Configuration'),
        content: const Text(
          'Are you sure you want to clear the Supabase configuration?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      final storage = ref.read(storageServiceProvider);
      await storage.clearSupabaseConfig();

      final supabaseService = ref.read(supabaseServiceProvider);
      supabaseService.reset();

      if (mounted) {
        setState(() {
          _urlController.clear();
          _keyController.clear();
          _isInitialized = false;
        });

        _showSnack('Configuration cleared', backgroundColor: Colors.green);
      }
    } catch (e) {
      debugPrint('Error clearing Supabase configuration: $e');
      debugPrintStack();
      if (mounted) {
        _showSnack(
          'Error clearing configuration: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeAccountAsync = ref.watch(activeServiceAccountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Supabase Configuration'), elevation: 0),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            Text(
              'Configure Supabase connection to fetch device tokens for the active profile.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Active profile warning
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

              // Configuration form
              Expanded(
                child: SupabaseConfigCard(
                  urlController: _urlController,
                  keyController: _keyController,
                  formKey: _formKey,
                  obscureKey: _obscureKey,
                  isLoading: _isLoading,
                  isInitialized: _isInitialized,
                  onToggleObscure: () =>
                      setState(() => _obscureKey = !_obscureKey),
                  onSave: _saveConfig,
                  onTest: _testConnection,
                  onClear: _clearConfig,
                ),
              ), // Expanded
            ],
          ],
        ),
      ),
    );
  }
}
