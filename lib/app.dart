import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/root/root_screen.dart';
import 'providers/theme_provider.dart';

/// Root of the app.
///
/// A ConsumerWidget can read Riverpod providers (note the extra `ref` in
/// build). We watch the theme mode so toggling dark mode rebuilds MaterialApp
/// with the new theme.
class ExpenseTrackerApp extends ConsumerWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode, // light / dark / system
      home: const RootScreen(),
    );
  }
}
