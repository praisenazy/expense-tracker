import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Defines the light and dark themes for the whole app.
///
/// `MaterialApp` is given `theme: AppTheme.light` and `darkTheme: AppTheme.dark`,
/// then a `ThemeMode` decides which one is shown. Dark mode "just works"
/// because both themes are fully defined here.
class AppTheme {
  AppTheme._();

  /// Light theme.
  static ThemeData get light => _base(Brightness.light);

  /// Dark theme.
  static ThemeData get dark => _base(Brightness.dark);

  /// Shared builder so light & dark don't duplicate settings.
  /// Only the [brightness] differs; the seed color generates the rest.
  static ThemeData _base(Brightness brightness) {
    // From ONE seed color, Material 3 generates a full, harmonious palette
    // that adapts to light or dark automatically.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,

      // Apply the "Inter" font to all text, tinted for the current brightness.
      textTheme: GoogleFonts.interTextTheme(
        brightness == Brightness.dark
            ? ThemeData.dark().textTheme
            : ThemeData.light().textTheme,
      ),

      // Consistent app bar across every screen.
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),

      // Every Card gets the same rounded corners and subtle elevation.
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Rounded text fields by default.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),

      // Rounded, comfortable buttons.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
