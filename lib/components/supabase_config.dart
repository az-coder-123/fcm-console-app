import 'package:fcmapp/components/supabase_config/form_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import 'page_header.dart';
import 'profile_required_banner.dart';

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

  // Track original values to detect unsaved changes
  String _originalUrl = '';
  String _originalKey = '';
  bool _isDirty = false;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();

    // Listen for input changes to update dirty state
    _urlController.addListener(_onInputChanged);
    _keyController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _urlController.removeListener(_onInputChanged);
    _keyController.removeListener(_onInputChanged);
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
        _originalUrl = url ?? '';
        _originalKey = key ?? '';
        _urlController.text = _originalUrl;
        _keyController.text = _originalKey;
        _isInitialized = url != null && key != null;
        _isDirty = false;
        _isValid = _isInputValid();
      });
    }
  }

  Future<void> _applyConfig() async {
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
      final url = _urlController.text.trim();
      final key = _keyController.text.trim();

      // Save to storage
      await storage.setSupabaseUrl(url);
      await storage.setSupabaseKey(key);

      // Initialize Supabase client
      final supabaseService = ref.read(supabaseServiceProvider);
      await supabaseService.initialize(url, key);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialized = true;
          _originalUrl = url;
          _originalKey = key;
          _isDirty = false;
          _isValid = _isInputValid();
        });

        _showSnack(
          'Supabase configuration applied successfully',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      debugPrint('Error applying Supabase config: $e');
      debugPrintStack();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        _showSnack(
          'Error applying configuration: $e',
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
      await supabaseService.reset();

      if (mounted) {
        setState(() {
          _urlController.clear();
          _keyController.clear();
          _originalUrl = '';
          _originalKey = '';
          _isInitialized = false;
          _isDirty = false;
          _isValid = false;
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

  void _onInputChanged() {
    final url = _urlController.text.trim();
    final key = _keyController.text.trim();
    final dirty = url != _originalUrl || key != _originalKey;
    final valid = _isInputValid();
    if (mounted && (dirty != _isDirty || valid != _isValid)) {
      setState(() {
        _isDirty = dirty;
        _isValid = valid;
      });
    }
  }

  bool _isInputValid() {
    final v = _urlController.text.trim();
    if (v.isEmpty) return false;
    final uri = Uri.tryParse(v);
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty) {
      return false;
    }
    final k = _keyController.text.trim();
    if (k.isEmpty) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final activeAccountAsync = ref.watch(activeServiceAccountProvider);

    return Scaffold(
      appBar: AppBar(elevation: 0, toolbarHeight: 0),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const PageHeader(
              title: 'Supabase Configuration',
              subtitle:
                  'Configure Supabase connection to fetch device tokens for the active profile.',
            ),
            const SizedBox(height: 24),

            // Active profile warning
            ProfileRequiredBanner(activeAccountAsync: activeAccountAsync),

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
                  isApplyEnabled: !_isLoading && _isDirty && _isValid,
                  onToggleObscure: () =>
                      setState(() => _obscureKey = !_obscureKey),
                  onApply: _applyConfig,
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
