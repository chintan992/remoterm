## Task: Implement Presentation Layer Core for Remote Terminal Companion Flutter App

You are implementing the **presentation layer core** (theme, color scheme, and shared widgets) of the Remote Terminal Companion Flutter app.

### Your task:
Create all files in `lib/presentation/core/` directory.

---

## Files to Create

### 1. `lib/presentation/core/theme/color_scheme.dart`

```dart
/// Color scheme definitions for the Remote Terminal Companion app.
/// 
/// Defines both light and dark color schemes using Material Design 3.
/// The terminal always uses a dark theme regardless of system theme.
import 'package:flutter/material.dart';

/// Primary seed color for Material 3 dynamic color generation
const Color kSeedColor = Color(0xFF00BCD4); // Cyan - terminal-inspired

/// Terminal-specific colors (always dark theme)
const Color kTerminalBackground = Color(0xFF0D1117); // GitHub dark background
const Color kTerminalForeground = Color(0xFFE6EDF3); // Light text
const Color kTerminalCursor = Color(0xFF58A6FF); // Blue cursor
const Color kTerminalSelection = Color(0xFF264F78); // Selection highlight

/// ANSI color palette for terminal
const Color kTerminalBlack = Color(0xFF484F58);
const Color kTerminalRed = Color(0xFFFF7B72);
const Color kTerminalGreen = Color(0xFF3FB950);
const Color kTerminalYellow = Color(0xFFD29922);
const Color kTerminalBlue = Color(0xFF58A6FF);
const Color kTerminalMagenta = Color(0xFFBC8CFF);
const Color kTerminalCyan = Color(0xFF39C5CF);
const Color kTerminalWhite = Color(0xFFB1BAC4);

/// Bright ANSI colors
const Color kTerminalBrightBlack = Color(0xFF6E7681);
const Color kTerminalBrightRed = Color(0xFFFFA198);
const Color kTerminalBrightGreen = Color(0xFF56D364);
const Color kTerminalBrightYellow = Color(0xFFE3B341);
const Color kTerminalBrightBlue = Color(0xFF79C0FF);
const Color kTerminalBrightMagenta = Color(0xFFD2A8FF);
const Color kTerminalBrightCyan = Color(0xFF56D4DD);
const Color kTerminalBrightWhite = Color(0xFFCDD9E5);

/// Status indicator colors
const Color kStatusConnected = Color(0xFF3FB950); // Green
const Color kStatusConnecting = Color(0xFFD29922); // Yellow/amber
const Color kStatusDisconnected = Color(0xFF6E7681); // Gray
const Color kStatusError = Color(0xFFFF7B72); // Red

/// Light color scheme
final ColorScheme kLightColorScheme = ColorScheme.fromSeed(
  seedColor: kSeedColor,
  brightness: Brightness.light,
);

/// Dark color scheme
final ColorScheme kDarkColorScheme = ColorScheme.fromSeed(
  seedColor: kSeedColor,
  brightness: Brightness.dark,
);
```

### 2. `lib/presentation/core/theme/app_theme.dart`

```dart
/// Application theme configuration for Remote Terminal Companion.
/// 
/// Provides Material Design 3 themes for both light and dark modes.
/// Uses dynamic color generation from the seed color.
import 'package:flutter/material.dart';
import 'color_scheme.dart';

/// Application theme configuration.
/// 
/// Provides [lightTheme] and [darkTheme] for the app.
/// Both themes use Material Design 3 with the cyan seed color.
class AppTheme {
  AppTheme._(); // Prevent instantiation

  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: kLightColorScheme,
      // AppBar theme
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: kLightColorScheme.surface,
        foregroundColor: kLightColorScheme.onSurface,
      ),
      // Card theme
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: kLightColorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kLightColorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: kLightColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: kLightColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: kLightColorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: kLightColorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
      ),
      // Filled button theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      // Dialog theme
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 3,
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: kDarkColorScheme,
      // AppBar theme
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: kDarkColorScheme.surface,
        foregroundColor: kDarkColorScheme.onSurface,
      ),
      // Card theme
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: kDarkColorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kDarkColorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: kDarkColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: kDarkColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: kDarkColorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: kDarkColorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
      ),
      // Filled button theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      // Dialog theme
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 3,
      ),
    );
  }
}
```

### 3. `lib/presentation/core/widgets/error_dialog.dart`

```dart
/// Reusable error dialog widget for displaying SSH connection errors.
/// 
/// Shows a user-friendly error message with retry and go-back options.
import 'package:flutter/material.dart';

/// A dialog widget for displaying error messages with action buttons.
/// 
/// Used throughout the app to show connection errors, authentication
/// failures, and other error conditions in a consistent way.
/// 
/// Example usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => ErrorDialog(
///     title: 'Connection Error',
///     message: 'Host unreachable: 192.168.1.100',
///     onRetry: () => _retryConnection(),
///   ),
/// );
/// ```
class ErrorDialog extends StatelessWidget {
  /// The dialog title (e.g., "Connection Error")
  final String title;

  /// The detailed error message to display
  final String message;

  /// Optional callback for the "Retry" button.
  /// If null, the retry button is not shown.
  final VoidCallback? onRetry;

  /// Optional callback for the "Go Back" button.
  /// If null, defaults to Navigator.pop.
  final VoidCallback? onGoBack;

  /// Optional icon to display (defaults to warning icon)
  final IconData icon;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.onGoBack,
    this.icon = Icons.warning_amber_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      icon: Icon(
        icon,
        color: colorScheme.error,
        size: 32,
      ),
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        // Go Back button
        TextButton(
          onPressed: onGoBack ?? () => Navigator.of(context).pop(),
          child: const Text('Go Back'),
        ),
        // Retry button (only shown if onRetry is provided)
        if (onRetry != null)
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            child: const Text('Retry'),
          ),
      ],
    );
  }

  /// Shows this dialog as a modal dialog.
  /// 
  /// Convenience method to show the dialog without needing to call showDialog.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
    VoidCallback? onGoBack,
    IconData icon = Icons.warning_amber_rounded,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        onRetry: onRetry,
        onGoBack: onGoBack,
        icon: icon,
      ),
    );
  }
}
```

### 4. `lib/presentation/core/widgets/loading_overlay.dart`

```dart
/// Loading overlay widget for displaying connection progress.
/// 
/// Shows a semi-transparent overlay with a loading indicator
/// and optional status message.
import 'package:flutter/material.dart';

/// A full-screen loading overlay with a progress indicator and message.
/// 
/// Used during SSH connection establishment to provide visual feedback.
/// 
/// Example usage:
/// ```dart
/// Stack(
///   children: [
///     // Main content
///     MyContent(),
///     // Loading overlay (shown conditionally)
///     if (isLoading)
///       LoadingOverlay(message: 'Connecting to 192.168.1.100...'),
///   ],
/// )
/// ```
class LoadingOverlay extends StatelessWidget {
  /// The message to display below the loading indicator
  final String message;

  /// Whether to show a cancel button
  final bool showCancel;

  /// Callback when cancel is pressed
  final VoidCallback? onCancel;

  const LoadingOverlay({
    super.key,
    this.message = 'Connecting...',
    this.showCancel = false,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (showCancel && onCancel != null) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An inline loading indicator with optional message.
/// 
/// Lighter alternative to [LoadingOverlay] for use within content areas.
class InlineLoader extends StatelessWidget {
  /// The message to display next to the indicator
  final String? message;

  /// Size of the progress indicator
  final double size;

  const InlineLoader({
    super.key,
    this.message,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
        if (message != null) ...[
          const SizedBox(width: 12),
          Text(
            message!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
```

---

## Important Notes:
- All files must be placed in the exact paths specified
- Use proper Dart documentation comments (`///`) for all public APIs
- Use Material Design 3 APIs (useMaterial3: true, ColorScheme.fromSeed, etc.)
- The `withOpacity` method is used on Color objects - this is valid Flutter API
- After creating all files, use `attempt_completion` to report what was done
- After creating all files, run "Flutter Analyze" and fix errors/warnings if any exists

Only perform the work described here and nothing else.