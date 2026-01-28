import 'package:fcmapp/components/supabase_config/action_buttons.dart';
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
  final VoidCallback onToggleObscure;
  final VoidCallback onSave;
  final VoidCallback onClear;

  const SupabaseConfigCard({
    super.key,
    required this.urlController,
    required this.keyController,
    required this.formKey,
    required this.obscureKey,
    required this.isLoading,
    required this.isInitialized,
    required this.onToggleObscure,
    required this.onSave,
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

                    // Buttons and actions
                    ActionButtons(
                      isLoading: isLoading,
                      isInitialized: isInitialized,
                      onSave: onSave,
                      onClear: onClear,
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
