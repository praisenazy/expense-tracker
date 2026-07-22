import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../core/constants/app_constants.dart';

/// The small key-value box used for app settings (separate from transactions).
final settingsBoxProvider = Provider<Box>((ref) {
  return Hive.box(AppConstants.settingsBox);
});

/// A selectable app theme color (name + color).
class ThemeColorOption {
  const ThemeColorOption(this.name, this.color);
  final String name;
  final Color color;
}

/// The 6 theme colors the user can choose from. The first is the default.
const List<ThemeColorOption> kThemeColors = [
  ThemeColorOption('Ocean Blue', Color(0xFF2196F3)),
  ThemeColorOption('Royal Purple', Color(0xFF7B2FBE)),
  ThemeColorOption('Sunset Orange', Color(0xFFF05A28)),
  ThemeColorOption('Emerald Green', Color(0xFF2E7D32)),
  ThemeColorOption('Rose Pink', Color(0xFFE91E8C)),
  ThemeColorOption('Crimson Red', Color(0xFFE53935)),
];

/// The chosen theme (seed) color, persisted to Hive so it survives restarts.
/// Defaults to Ocean Blue the first time.
final themeColorProvider =
    NotifierProvider<ThemeColorNotifier, Color>(ThemeColorNotifier.new);

class ThemeColorNotifier extends Notifier<Color> {
  Box get _box => ref.read(settingsBoxProvider);

  @override
  Color build() {
    final saved = _box.get(AppConstants.themeColorKey) as int?;
    return saved != null ? Color(saved) : kThemeColors.first.color;
  }

  /// Pick a new theme color and remember it.
  Future<void> setColor(Color color) async {
    state = color; // repaints the whole app immediately
    await _box.put(AppConstants.themeColorKey, color.toARGB32());
  }
}

/// Current theme mode (light / dark / system), persisted to Hive so the
/// choice survives app restarts.
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  Box get _box => ref.read(settingsBoxProvider);

  @override
  ThemeMode build() {
    // Read the saved choice; default to "follow the system" the first time.
    final saved = _box.get(AppConstants.themeModeKey) as String?;
    return _decode(saved);
  }

  /// Set an explicit mode and remember it.
  Future<void> setMode(ThemeMode mode) async {
    state = mode; // update UI immediately
    await _box.put(AppConstants.themeModeKey, mode.name); // persist
  }

  /// Convenience for a simple light/dark switch in the UI.
  Future<void> toggleDark(bool isDark) =>
      setMode(isDark ? ThemeMode.dark : ThemeMode.light);

  ThemeMode _decode(String? name) {
    switch (name) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
