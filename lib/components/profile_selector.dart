import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

import '../models/service_account.dart';
import '../providers/providers.dart';

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

      // If file.path is empty or file doesn't exist, save the picked bytes to a local file
      String finalPath = file.path;
      if (finalPath.isEmpty || !await File(finalPath).exists()) {
        final bytes = await file.readAsBytes();
        final Directory appDocDir = await getApplicationSupportDirectory();
        finalPath = join(
          appDocDir.path,
          'service_account_${DateTime.now().millisecondsSinceEpoch}.json',
        );
        await File(finalPath).writeAsBytes(bytes);
        debugPrint('Saved service account to $finalPath');
      }

      // Validate JSON looks like a Firebase service account
      try {
        final content = await File(finalPath).readAsString();
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
      } catch (err) {
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

      // Show dialog to enter profile name
      final name = await _showNameDialog();
      if (name == null || name.isEmpty) return;

      // Create service account
      final serviceAccount = ServiceAccount(
        id: 0, // Will be auto-generated
        name: name,
        filePath: finalPath,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting profile: $e'),
            backgroundColor: Colors.red,
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
      appBar: AppBar(
        title: const Text('Firebase Service Account Profiles'),
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            Text(
              'Manage your Firebase Service Account profiles. Each profile represents a Firebase project.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Add profile button
            ElevatedButton.icon(
              onPressed: _addProfile,
              icon: const Icon(Icons.add),
              label: const Text('Add New Profile'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
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
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: isActive ? 4 : 1,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    isActive ? Icons.check : Icons.cloud,
                    color: isActive
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                title: Text(
                  profile.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID: ${profile.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Created: ${_formatDate(profile.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isActive)
                      Chip(
                        label: const Text('Active'),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
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
                onTap: () => _selectProfile(profile),
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
