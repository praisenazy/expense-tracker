import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Defines the light and dark themes for the whole app.
///
/// `MaterialApp` is given `theme: AppTheme.light(seed)` and
/// `darkTheme: AppTheme.dark(seed)`, then a `ThemeMode` decides which one is
/// shown. The [seed] is the user's chosen theme color, so the whole palette
/// re-derives when they pick a new one.
class AppTheme {
  AppTheme._();

  /// Light theme built from the chosen [seed] color.
  static ThemeData light(Color seed) => _base(Brightness.light, seed);

  /// Dark theme built from the chosen [seed] color.
  static ThemeData dark(Color seed) => _base(Brightness.dark, seed);

  /// Shared builder so light & dark don't duplicate settings.
  /// Only the [brightness] differs; the [seed] color generates the rest.
  static ThemeData _base(Brightness brightness, Color seed) {
    // From ONE seed color, Material 3 generates a full, harmonious palette
    // that adapts to light or dark automatically.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    // No ink splash / highlight anywhere when tapping.
    final noOverlay = WidgetStateProperty.all<Color>(Colors.transparent);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,

      // Kill the tap ripple/highlight globally (InkWell, ListTile, chips, etc.).
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,

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

      // Rounded, comfortable buttons — all with no tap overlay.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ).copyWith(overlayColor: noOverlay),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(overlayColor: noOverlay),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(overlayColor: noOverlay),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(overlayColor: noOverlay),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(overlayColor: noOverlay),
      ),
    );
  }
}
