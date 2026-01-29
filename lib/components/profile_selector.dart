import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

import '../models/service_account.dart';
import '../providers/providers.dart';
import 'page_header.dart';

/// Profile selector component for managing Firebase Service Accounts
/// Allows users to add, select, and delete service account profiles
class ProfileSelector extends ConsumerStatefulWidget {
  const ProfileSelector({super.key});

  @override
  ConsumerState<ProfileSelector> createState() => _ProfileSelectorState();
}

class _ProfileSelectorState extends ConsumerState<ProfileSelector> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addProfile() async {
    try {
      // Open file picker for Service Account JSON
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'JSON',
        extensions: <String>['json'],
      );

      final XFile? file = await openFile(
        acceptedTypeGroups: <XTypeGroup>[typeGroup],
      );

      if (file == null) return;

      // Always read file content immediately to avoid permission issues on macOS
      // Files in Downloads folder often have restricted access permissions
      late String content;
      String finalPath = file.path;

      try {
        // Try to read the content directly from the selected file
        content = await file.readAsString();
      } catch (e) {
        debugPrint('Failed to read file content directly: $e');
        // Fallback: read as bytes and convert
        final bytes = await file.readAsBytes();
        content = String.fromCharCodes(bytes);
      }

      // Save a copy to application support directory for future access
      try {
        final bytes = await file.readAsBytes();
        final Directory appDocDir = await getApplicationSupportDirectory();
        finalPath = join(
          appDocDir.path,
          'service_account_${DateTime.now().millisecondsSinceEpoch}.json',
        );
        await File(finalPath).writeAsBytes(bytes);
        debugPrint('Saved service account copy to $finalPath');
      } catch (e) {
        debugPrint('Warning: Could not save service account copy: $e');
        // Continue anyway, we have the content
      }

      // Validate JSON looks like a Firebase service account
      try {
        final Map<String, dynamic> json = jsonDecode(content);
        final bool looksValid =
            json.containsKey('project_id') ||
            json['type'] == 'service_account' ||
            json.containsKey('client_email');
        if (!looksValid) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Selected file does not appear to be a valid Service Account JSON',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Show dialog to enter profile name
        final name = await _showNameDialog();
        if (name == null || name.isEmpty) return;

        // Create service account with JSON content
        final serviceAccount = ServiceAccount(
          id: 0, // Will be auto-generated
          name: name,
          filePath: finalPath,
          jsonContent: content, // Store JSON content directly
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Save to database
        final db = ref.read(databaseServiceProvider);
        await db.createServiceAccount(serviceAccount);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile "$name" added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Refresh the list
        ref.invalidate(serviceAccountsProvider);
      } catch (err) {
        debugPrint('Unable to read/parse selected file: $err');
        debugPrintStack();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to read/parse the selected file: $err'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    } catch (e, st) {
      debugPrint('Error adding profile: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showNameDialog() async {
    _nameController.clear();
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Profile Name'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Enter profile name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, _nameController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectProfile(ServiceAccount account) async {
    try {
      final storage = ref.read(storageServiceProvider);
      await storage.setActiveServiceAccountId(account.id);

      // Reset Supabase config when switching profiles
      await storage.clearSupabaseConfig();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile "${account.name}" activated'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Refresh providers
      ref.invalidate(activeServiceAccountProvider);
    } catch (e) {
      debugPrint('Error selecting profile: $e');
      debugPrintStack();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting profile: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  Future<void> _deleteProfile(ServiceAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text(
          'Are you sure you want to delete "${account.name}"? '
          'This will also delete all associated notification history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final db = ref.read(databaseServiceProvider);
      await db.deleteServiceAccount(account.id);

      // If deleting active profile, clear it
      final storage = ref.read(storageServiceProvider);
      final activeId = await storage.getActiveServiceAccountId();
      if (activeId == account.id) {
        await storage.setActiveServiceAccountId(null);
        ref.invalidate(activeServiceAccountProvider);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile "${account.name}" deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Refresh the list
      ref.invalidate(serviceAccountsProvider);
    } catch (e) {
      debugPrint('Error deleting profile: $e');
      debugPrintStack();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0, toolbarHeight: 0),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const PageHeader(
              title: 'Firebase Service Account Profiles',
              subtitle:
                  'Manage your Firebase Service Account profiles. Each profile represents a Firebase project.',
            ),
            const SizedBox(height: 24),

            // Add profile button
            OutlinedButton.icon(
              onPressed: _addProfile,
              icon: const Icon(Icons.add, color: Color(0xFF1E88E5)),
              label: const Text('Add New Profile', style: TextStyle(color: Color(0xFF1E88E5))),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // Profiles list
            Expanded(
              child: Consumer(
                builder: (BuildContext context, WidgetRef ref, Widget? child) {
                  final profilesAsync = ref.watch(serviceAccountsProvider);

                  return profilesAsync.when(
                    data: (profiles) {
                      if (profiles.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_open,
                                size: 64,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No profiles found',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add a Firebase Service Account JSON file to get started',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: profiles.length,
                        itemBuilder: (context, index) {
                          final profile = profiles[index];
                          return _buildProfileCard(profile);
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Text(
                        'Error loading profiles: $error',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(ServiceAccount profile) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        final activeProfileAsync = ref.watch(activeServiceAccountProvider);
        return activeProfileAsync.when(
          data: (activeProfile) {
            final isActive = activeProfile?.id == profile.id;
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _selectProfile(profile),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, isActive ? 0.06 : 0.03),
                      blurRadius: isActive ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          isActive ? Icons.check : Icons.person,
                          color: isActive
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'ID: ${profile.id}  •  Created: ${_formatDate(profile.createdAt)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Active',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      onPressed: () => _deleteProfile(profile),
                      tooltip: 'Delete Profile',
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Card(
            margin: EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Loading...'),
            ),
          ),
          error: (_, _) => Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(title: Text('Error loading active profile')),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
