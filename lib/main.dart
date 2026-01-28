/// Main application entry point.
library;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/database/database_service.dart';
import 'core/ui/app_theme.dart';
import 'features/auth/screens/profile_management_screen.dart';
import 'features/dashboard/screens/history_screen.dart';
import 'features/dashboard/screens/notification_composer_screen.dart';
import 'features/dashboard/screens/token_list_screen.dart';
import 'features/settings/screens/supabase_config_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database
  await DatabaseService.instance.initialize();

  runApp(const ProviderScope(child: FCMConsoleApp()));
}

/// Main application widget.
class FCMConsoleApp extends StatelessWidget {
  const FCMConsoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp.router(
      title: 'FCM Console',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}

/// Application router configuration.
final _router = GoRouter(
  initialLocation: '/composer',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/profiles',
          builder: (context, state) => const ProfileManagementScreen(),
        ),
        GoRoute(
          path: '/supabase',
          builder: (context, state) => const SupabaseConfigScreen(),
        ),
        GoRoute(
          path: '/tokens',
          builder: (context, state) => const TokenListScreen(),
        ),
        GoRoute(
          path: '/composer',
          builder: (context, state) => const NotificationComposerScreen(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
      ],
    ),
  ],
);

/// Main shell widget with navigation.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 3; // Default to Composer

  List<NavigationPaneItem> get _navItems => [
    PaneItem(
      icon: const Icon(FluentIcons.contact),
      title: const Text('Profiles'),
      body: widget.child,
    ),
    PaneItem(
      icon: const Icon(FluentIcons.database),
      title: const Text('Supabase'),
      body: widget.child,
    ),
    PaneItem(
      icon: const Icon(FluentIcons.cell_phone),
      title: const Text('Tokens'),
      body: widget.child,
    ),
    PaneItem(
      icon: const Icon(FluentIcons.send),
      title: const Text('Composer'),
      body: widget.child,
    ),
    PaneItem(
      icon: const Icon(FluentIcons.history),
      title: const Text('History'),
      body: widget.child,
    ),
  ];

  final _routes = [
    '/profiles',
    '/supabase',
    '/tokens',
    '/composer',
    '/history',
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: const NavigationAppBar(
        automaticallyImplyLeading: false,
        title: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text('FCM Console'),
        ),
        actions: SizedBox.shrink(),
      ),
      pane: NavigationPane(
        selected: _selectedIndex,
        onChanged: (index) {
          setState(() => _selectedIndex = index);
          context.go(_routes[index]);
        },
        displayMode: context.isSmallWindow
            ? PaneDisplayMode.compact
            : PaneDisplayMode.open,
        items: _navItems,
      ),
    );
  }
}
