import 'package:fcmapp/components/supabase_config/help_panel.dart';
import 'package:fcmapp/components/supabase_config/status_badge.dart';
import 'package:flutter/material.dart';

class SupabaseConfigCard extends StatelessWidget {
  final TextEditingController urlController;
  final TextEditingController keyController;
  final GlobalKey<FormState> formKey;
  final bool obscureKey;
  final bool isLoading;
  final bool isInitialized;
  final bool isApplyEnabled;
  final VoidCallback onToggleObscure;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const SupabaseConfigCard({
    super.key,
    required this.urlController,
    required this.keyController,
    required this.formKey,
    required this.obscureKey,
    required this.isLoading,
    required this.isInitialized,
    required this.isApplyEnabled,
    required this.onToggleObscure,
    required this.onApply,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status indicator
                    StatusBadge(isInitialized: isInitialized),

                    // URL field
                    TextFormField(
                      controller: urlController,
                      keyboardType: TextInputType.url,
                      autofillHints: const [AutofillHints.url],
                      decoration: const InputDecoration(
                        labelText: 'Supabase URL',
                        hintText: 'https://your-project.supabase.co',
                        prefixIcon: Icon(Icons.link),
                        border: OutlineInputBorder(),
                      ),
                      enabled: !isLoading,
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) {
                          return 'Please enter Supabase URL';
                        }
                        final uri = Uri.tryParse(v);
                        if (uri == null ||
                            !(uri.scheme == 'http' || uri.scheme == 'https') ||
                            uri.host.isEmpty) {
                          return 'Please enter a valid URL (http/https)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Key field
                    TextFormField(
                      controller: keyController,
                      obscureText: obscureKey,
                      decoration: InputDecoration(
                        labelText: 'Supabase Anon/Service Key',
                        hintText: 'Enter your Supabase API key',
                        prefixIcon: const Icon(Icons.key),
                        suffixIcon: IconButton(
                          tooltip: obscureKey ? 'Show key' : 'Hide key',
                          icon: Icon(
                            obscureKey
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: onToggleObscure,
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      enabled: !isLoading,
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Please enter the API key'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Apply and Clear buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: (isApplyEnabled && !isLoading)
                                ? onApply
                                : null,
                            icon: isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check_circle),
                            label: Text(isLoading ? 'Applying...' : 'Apply'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isLoading || !isInitialized
                                ? null
                                : onClear,
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              foregroundColor: isInitialized
                                  ? Colors.red
                                  : Colors.red.withAlpha(128),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const HelpPanel(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
