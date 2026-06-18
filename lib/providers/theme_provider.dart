import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../core/constants/app_constants.dart';

/// The small key-value box used for app settings (separate from transactions).
final settingsBoxProvider = Provider<Box>((ref) {
  return Hive.box(AppConstants.settingsBox);
});

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
