/// Profile management screen for Service Account profiles.
library;

import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/ui/app_theme.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/json_parser.dart';
import '../../../features/auth/services/google_auth_service.dart';
import '../../../features/auth/services/secure_storage_service.dart';
import '../../../providers/providers.dart';

/// Screen for managing Service Account profiles.
class ProfileManagementScreen extends ConsumerStatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  ConsumerState<ProfileManagementScreen> createState() =>
      _ProfileManagementScreenState();
}

class _ProfileManagementScreenState
    extends ConsumerState<ProfileManagementScreen> {
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(serviceAccountsProvider);
    final activeProfileAsync = ref.watch(activeServiceAccountProvider);

    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: const Text('Service Account Profiles'),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.add),
              label: const Text('Import Profile'),
              onPressed: _isImporting ? null : _importServiceAccount,
            ),
          ],
        ),
      ),
      children: [
        profilesAsync.when(
          loading: () => AppWidgets.loading('Loading profiles...'),
          error: (error, stack) => AppWidgets.errorState(
            message: 'Failed to load profiles: $error',
            onRetry: () => ref.invalidate(serviceAccountsProvider),
          ),
          data: (profiles) {
            if (profiles.isEmpty) {
              return SizedBox(
                height: 300,
                child: AppWidgets.emptyState(
                  icon: FluentIcons.contact,
                  title: 'No Profiles',
                  subtitle:
                      'Import a Firebase Service Account JSON file to get started.',
                  action: FilledButton(
                    onPressed: _isImporting ? null : _importServiceAccount,
                    child: const Text('Import Service Account'),
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isImporting)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: InfoBar(
                      title: Text('Importing...'),
                      content: Text('Please wait while importing the profile.'),
                      severity: InfoBarSeverity.info,
                    ),
                  ),
                ...profiles.map((profile) {
                  final isActive =
                      activeProfileAsync.valueOrNull?.id == profile.id;
                  return _ProfileCard(
                    profile: profile,
                    isActive: isActive,
                    onActivate: () => _activateProfile(profile),
                    onDelete: () => _deleteProfile(profile),
                  );
                }),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _importServiceAccount() async {
    setState(() => _isImporting = true);

    try {
      const typeGroup = XTypeGroup(label: 'JSON files', extensions: ['json']);

      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) {
        setState(() => _isImporting = false);
        return;
      }

      final jsonContent = await File(file.path).readAsString();
      final jsonMap = ServiceAccountParser.parseFromString(jsonContent);

      if (!ServiceAccountParser.isValidServiceAccount(jsonMap)) {
        if (mounted) {
          await displayInfoBar(
            context,
            builder: (context, close) => InfoBar(
              title: const Text('Invalid Service Account'),
              content: const Text(
                'The selected file is not a valid Firebase Service Account JSON.',
              ),
              severity: InfoBarSeverity.error,
              action: IconButton(
                icon: const Icon(FluentIcons.clear),
                onPressed: close,
              ),
            ),
          );
        }
        setState(() => _isImporting = false);
        return;
      }

      final projectId = ServiceAccountParser.getProjectId(jsonMap)!;
      final clientEmail = ServiceAccountParser.getClientEmail(jsonMap)!;

      // Show dialog to enter profile name
      final name = await _showNameDialog(projectId);
      if (name == null || name.isEmpty) {
        setState(() => _isImporting = false);
        return;
      }

      // Add profile to database
      await ref
          .read(serviceAccountsProvider.notifier)
          .add(
            name: name,
            projectId: projectId,
            clientEmail: clientEmail,
            jsonPath: file.path,
          );

      // Store JSON content securely
      final profiles = await ref.read(serviceAccountsProvider.future);
      final newProfile = profiles.firstWhere((p) => p.projectId == projectId);
      await SecureStorageService.instance.saveServiceAccountJson(
        newProfile.id,
        jsonContent,
      );

      if (mounted) {
        await displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Profile Imported'),
            content: Text('Successfully imported profile: $name'),
            severity: InfoBarSeverity.success,
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: close,
            ),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        await displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Import Failed'),
            content: Text('Error: $e'),
            severity: InfoBarSeverity.error,
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: close,
            ),
          ),
        );
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<String?> _showNameDialog(String defaultName) async {
    final controller = TextEditingController(text: defaultName);

    return showDialog<String>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Profile Name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter a name for this profile:'),
            const SizedBox(height: AppSpacing.md),
            TextBox(
              controller: controller,
              placeholder: 'Profile name',
              autofocus: true,
            ),
          ],
        ),
        actions: [
          Button(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _activateProfile(ServiceAccountProfile profile) async {
    try {
      await ref.read(serviceAccountsProvider.notifier).setActive(profile.id);

      // Authenticate with the service account
      final jsonContent = await SecureStorageService.instance
          .getServiceAccountJson(profile.id);

      if (jsonContent != null) {
        await GoogleAuthService.instance.authenticateFromString(jsonContent);
        ref.read(isAuthenticatedProvider.notifier).state = true;
      }

      if (mounted) {
        await displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Profile Activated'),
            content: Text('Now using: ${profile.name}'),
            severity: InfoBarSeverity.success,
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: close,
            ),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        await displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Activation Failed'),
            content: Text('Error: $e'),
            severity: InfoBarSeverity.error,
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: close,
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteProfile(ServiceAccountProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Delete Profile'),
        content: Text(
          'Are you sure you want to delete "${profile.name}"?\n\n'
          'This will also delete all notification history for this profile.',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(serviceAccountsProvider.notifier).delete(profile.id);

      if (mounted) {
        await displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Profile Deleted'),
            content: Text('Deleted: ${profile.name}'),
            severity: InfoBarSeverity.warning,
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: close,
            ),
          ),
        );
      }
    }
  }
}

/// Card widget displaying a single profile.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.isActive,
    required this.onActivate,
    required this.onDelete,
  });

  final ServiceAccountProfile profile;
  final bool isActive;
  final VoidCallback onActivate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        backgroundColor: isActive ? Colors.blue.withAlpha(30) : null,
        borderColor: isActive ? Colors.blue : null,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive ? Colors.blue : Colors.grey[80],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                FluentIcons.contact,
                color: isActive ? Colors.white : Colors.grey[160],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.projectId,
                    style: TextStyle(color: Colors.grey[120], fontSize: 12),
                  ),
                  Text(
                    profile.clientEmail.truncate(40),
                    style: TextStyle(color: Colors.grey[120], fontSize: 12),
                  ),
                ],
              ),
            ),
            if (!isActive)
              Button(onPressed: onActivate, child: const Text('Activate')),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              icon: Icon(FluentIcons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
