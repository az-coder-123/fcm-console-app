import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/notification_composer.dart';
import '../components/notification_history.dart';
import '../components/profile_selector.dart';
import '../components/supabase_config.dart';
import '../components/token_list.dart';
import '../providers/providers.dart';

/// Main dashboard screen for FCM Console App
/// Provides a responsive layout for desktop platforms
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ProfileSelectorPage(),
    const SupabaseConfigPage(),
    const TokenListPage(),
    const NotificationComposerPage(),
    const NotificationHistoryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive design for desktop
          if (constraints.maxWidth > 1200) {
            return _buildWideLayout();
          } else {
            return _buildNarrowLayout();
          }
        },
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        // Navigation sidebar
        _buildNavigationRail(),
        const VerticalDivider(thickness: 1, width: 1),
        // Main content area
        Expanded(child: _pages[_selectedIndex]),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Row(
      children: [
        // Compact navigation sidebar
        _buildCompactNavigationRail(),
        const VerticalDivider(thickness: 1, width: 1),
        // Main content area
        Expanded(child: _pages[_selectedIndex]),
      ],
    );
  }

  Widget _buildNavigationRail() {
    return Container(
      width: 250,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          // App header
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.notifications_active,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  'FCM Console',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Push Notification Manager',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(
                  icon: Icons.account_circle,
                  label: 'Profiles',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.settings_applications,
                  label: 'Supabase Config',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.devices,
                  label: 'Device Tokens',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.send,
                  label: 'Send Notification',
                  index: 3,
                ),
                _buildNavItem(icon: Icons.history, label: 'History', index: 4),
              ],
            ),
          ),
          // Active account info
          const Divider(height: 1),
          _buildActiveAccountInfo(),
        ],
      ),
    );
  }

  Widget _buildCompactNavigationRail() {
    return Container(
      width: 80,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          // App icon
          Container(
            padding: const EdgeInsets.all(16),
            child: Icon(
              Icons.notifications_active,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Divider(height: 1),
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildCompactNavItem(icon: Icons.account_circle, index: 0),
                _buildCompactNavItem(
                  icon: Icons.settings_applications,
                  index: 1,
                ),
                _buildCompactNavItem(icon: Icons.devices, index: 2),
                _buildCompactNavItem(icon: Icons.send, index: 3),
                _buildCompactNavItem(icon: Icons.history, index: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }

  Widget _buildCompactNavItem({required IconData icon, required int index}) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: IconButton(
        icon: Icon(
          icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
        onPressed: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        style: IconButton.styleFrom(
          backgroundColor: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
        ),
      ),
    );
  }

  Widget _buildActiveAccountInfo() {
    final activeAccountAsync = ref.watch(activeServiceAccountProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Profile',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          activeAccountAsync.when(
            data: (account) {
              if (account == null) {
                return Row(
                  children: [
                    Icon(
                      Icons.warning,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No profile selected',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ID: ${account.id}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, _) => Text(
              'Error loading profile',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

// Page widgets for each navigation item

class ProfileSelectorPage extends StatelessWidget {
  const ProfileSelectorPage({super.key});
  @override
  Widget build(BuildContext context) => const ProfileSelector();
}

class SupabaseConfigPage extends StatelessWidget {
  const SupabaseConfigPage({super.key});
  @override
  Widget build(BuildContext context) => const SupabaseConfig();
}

class TokenListPage extends StatelessWidget {
  const TokenListPage({super.key});
  @override
  Widget build(BuildContext context) => const TokenList();
}

class NotificationComposerPage extends StatelessWidget {
  const NotificationComposerPage({super.key});
  @override
  Widget build(BuildContext context) => const NotificationComposer();
}

class NotificationHistoryPage extends StatelessWidget {
  const NotificationHistoryPage({super.key});
  @override
  Widget build(BuildContext context) => const NotificationHistoryView();
}
