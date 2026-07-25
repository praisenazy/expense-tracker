import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../core/constants/app_constants.dart';
import 'theme_provider.dart'; // settingsBoxProvider

/// The user's display name (used to personalize greetings). Empty when unset.
final userNameProvider =
    NotifierProvider<UserNameNotifier, String>(UserNameNotifier.new);

class UserNameNotifier extends Notifier<String> {
  Box get _box => ref.read(settingsBoxProvider);

  @override
  String build() =>
      (_box.get(AppConstants.userNameKey) as String?)?.trim() ?? '';

  Future<void> setName(String name) async {
    final trimmed = name.trim();
    state = trimmed;
    await _box.put(AppConstants.userNameKey, trimmed);
  }
}

/// Whether the first-run onboarding has been completed (persisted).
final onboardingCompleteProvider =
    NotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);

class OnboardingNotifier extends Notifier<bool> {
  Box get _box => ref.read(settingsBoxProvider);

  @override
  bool build() => _box.get(AppConstants.onboardingDoneKey) == true;

  Future<void> complete() async {
    state = true;
    await _box.put(AppConstants.onboardingDoneKey, true);
  }
}
