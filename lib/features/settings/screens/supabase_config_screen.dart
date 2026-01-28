/// Supabase configuration screen.
library;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/ui/app_theme.dart';
import '../../../providers/providers.dart';
import '../repositories/supabase_token_repository.dart';

/// Screen for configuring Supabase connection settings.
class SupabaseConfigScreen extends ConsumerStatefulWidget {
  const SupabaseConfigScreen({super.key});

  @override
  ConsumerState<SupabaseConfigScreen> createState() =>
      _SupabaseConfigScreenState();
}

class _SupabaseConfigScreenState extends ConsumerState<SupabaseConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();
  final _tableController = TextEditingController(text: 'device_tokens');
  final _columnController = TextEditingController(text: 'token');

  bool _isTesting = false;
  bool _isSaving = false;
  bool? _testResult;

  @override
  void initState() {
    super.initState();
    _loadExistingConfig();
  }

  Future<void> _loadExistingConfig() async {
    final config = await ref.read(supabaseConfigProvider.future);
    if (config != null) {
      _urlController.text = config.url;
      _keyController.text = config.anonKey;
      _tableController.text = config.tableName;
      _columnController.text = config.tokenColumn;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    _tableController.dispose();
    _columnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = ref.watch(activeServiceAccountProvider);
    final configAsync = ref.watch(supabaseConfigProvider);

    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Supabase Configuration')),
      children: [
        activeProfile.when(
          loading: () => AppWidgets.loading(),
          error: (error, _) => AppWidgets.errorState(message: error.toString()),
          data: (profile) {
            if (profile == null) {
              return SizedBox(
                height: 300,
                child: AppWidgets.emptyState(
                  icon: FluentIcons.database,
                  title: 'No Active Profile',
                  subtitle:
                      'Please select a Service Account profile first to configure Supabase.',
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoBar(
                  title: Text('Active Profile: ${profile.name}'),
                  content: Text('Project: ${profile.projectId}'),
                  severity: InfoBarSeverity.info,
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildConfigForm(configAsync),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildConfigForm(AsyncValue<SupabaseConfig?> configAsync) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppWidgets.sectionHeader('Connection Settings'),
          const SizedBox(height: AppSpacing.sm),
          InfoLabel(
            label: 'Supabase URL',
            child: TextBox(
              controller: _urlController,
              placeholder: 'https://your-project.supabase.co',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoLabel(
            label: 'Anon / Service Key',
            child: PasswordBox(
              controller: _keyController,
              placeholder: 'Your Supabase anon or service key',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppWidgets.sectionHeader('Table Configuration'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: InfoLabel(
                  label: 'Table Name',
                  child: TextBox(
                    controller: _tableController,
                    placeholder: 'device_tokens',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: InfoLabel(
                  label: 'Token Column',
                  child: TextBox(
                    controller: _columnController,
                    placeholder: 'token',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_testResult != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: InfoBar(
                title: Text(
                  _testResult! ? 'Connection Successful' : 'Connection Failed',
                ),
                content: Text(
                  _testResult!
                      ? 'Successfully connected to Supabase.'
                      : 'Failed to connect. Please check your credentials.',
                ),
                severity: _testResult!
                    ? InfoBarSeverity.success
                    : InfoBarSeverity.error,
              ),
            ),
          Row(
            children: [
              Button(
                onPressed: _isTesting ? null : _testConnection,
                child: _isTesting
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: ProgressRing(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Testing...'),
                        ],
                      )
                    : const Text('Test Connection'),
              ),
              const SizedBox(width: AppSpacing.md),
              FilledButton(
                onPressed: _isSaving ? null : _saveConfig,
                child: _isSaving
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: ProgressRing(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Saving...'),
                        ],
                      )
                    : const Text('Save Configuration'),
              ),
              const Spacer(),
              if (configAsync.valueOrNull != null)
                Button(
                  onPressed: _clearConfig,
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.all(Colors.red),
                  ),
                  child: const Text('Clear Configuration'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _testConnection() async {
    if (_urlController.text.isEmpty || _keyController.text.isEmpty) {
      await displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Validation Error'),
          content: const Text('Please fill in URL and Key fields.'),
          severity: InfoBarSeverity.warning,
          action: IconButton(
            icon: const Icon(FluentIcons.clear),
            onPressed: close,
          ),
        ),
      );
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final config = SupabaseConfig(
        url: _urlController.text.trim(),
        anonKey: _keyController.text.trim(),
        tableName: _tableController.text.trim(),
        tokenColumn: _columnController.text.trim(),
      );

      final success = await SupabaseTokenRepository.testConnection(config);

      setState(() => _testResult = success);
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _saveConfig() async {
    if (_urlController.text.isEmpty || _keyController.text.isEmpty) {
      await displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Validation Error'),
          content: const Text('Please fill in URL and Key fields.'),
          severity: InfoBarSeverity.warning,
          action: IconButton(
            icon: const Icon(FluentIcons.clear),
            onPressed: close,
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final config = SupabaseConfig(
        url: _urlController.text.trim(),
        anonKey: _keyController.text.trim(),
        tableName: _tableController.text.trim(),
        tokenColumn: _columnController.text.trim(),
      );

      await ref.read(supabaseConfigProvider.notifier).save(config);

      if (mounted) {
        await displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Configuration Saved'),
            content: const Text('Supabase configuration has been saved.'),
            severity: InfoBarSeverity.success,
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: close,
            ),
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _clearConfig() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Clear Configuration'),
        content: const Text(
          'Are you sure you want to clear the Supabase configuration?',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(supabaseConfigProvider.notifier).clear();
      _urlController.clear();
      _keyController.clear();
      _tableController.text = 'device_tokens';
      _columnController.text = 'token';
      setState(() => _testResult = null);
    }
  }
}
