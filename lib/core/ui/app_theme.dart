/// Common UI widgets and theme configuration.
library;

import 'package:fluent_ui/fluent_ui.dart';

/// Application theme configuration.
class AppTheme {
  AppTheme._();

  /// Light theme for the application.
  static FluentThemeData get light {
    return FluentThemeData(
      brightness: Brightness.light,
      accentColor: Colors.blue,
      visualDensity: VisualDensity.standard,
    );
  }

  /// Dark theme for the application.
  static FluentThemeData get dark {
    return FluentThemeData(
      brightness: Brightness.dark,
      accentColor: Colors.blue,
      visualDensity: VisualDensity.standard,
    );
  }
}

/// Common spacing values.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Common widget utilities.
class AppWidgets {
  AppWidgets._();

  /// Creates a standard card with consistent styling.
  static Widget card({required Widget child, EdgeInsetsGeometry? padding}) {
    return Card(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: child,
    );
  }

  /// Creates a section header.
  static Widget sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Creates a loading indicator with optional message.
  static Widget loading([String? message]) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ProgressRing(),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(message),
          ],
        ],
      ),
    );
  }

  /// Creates an empty state widget.
  static Widget emptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey[100]),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[120]),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action,
          ],
        ],
      ),
    );
  }

  /// Creates an error state widget.
  static Widget errorState({required String message, VoidCallback? onRetry}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FluentIcons.error, size: 64, color: Colors.red),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Button(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

/// Extension for responsive layout building.
extension ResponsiveExtension on BuildContext {
  /// Gets the current window width.
  double get windowWidth => MediaQuery.of(this).size.width;

  /// Gets the current window height.
  double get windowHeight => MediaQuery.of(this).size.height;

  /// Checks if the window is considered small.
  bool get isSmallWindow => windowWidth < 640;

  /// Checks if the window is considered medium.
  bool get isMediumWindow => windowWidth >= 640 && windowWidth < 1024;

  /// Checks if the window is considered large.
  bool get isLargeWindow => windowWidth >= 1024;
}
