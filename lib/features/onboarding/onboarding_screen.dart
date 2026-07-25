import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/transaction_type.dart';
import '../../providers/category_providers.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../root/root_screen.dart';

/// First-run onboarding: welcome + name → theme color → all set.
///
/// Progress starts at step 1 of 3 (never at 0%) so it feels like momentum, and
/// the final button says "Start tracking" — the user is building something,
/// not filling a form.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _pages = 3;

  final _pageController = PageController();
  final _nameController = TextEditingController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == 0) {
      ref.read(userNameProvider.notifier).setName(_nameController.text);
    }
    if (_page < _pages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await ref.read(userNameProvider.notifier).setName(_nameController.text);
    await ref.read(onboardingCompleteProvider.notifier).complete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, _, _) => const RootScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = ref.watch(themeColorProvider);
    // Progress never starts at zero — step 1 of 3 already shows momentum.
    final progress = (_page + 1) / _pages;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress + skip.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spaceL,
                AppConstants.spaceM,
                AppConstants.spaceL,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 320),
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor: theme
                              .colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spaceM),
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _welcomePage(theme, accent),
                  _colorPage(theme, accent),
                  _readyPage(theme, accent),
                ],
              ),
            ),

            // Continue / Start button.
            Padding(
              padding: const EdgeInsets.all(AppConstants.spaceL),
              child: _PrimaryButton(
                color: accent,
                label: _page == _pages - 1 ? 'Start tracking' : 'Continue',
                onTap: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Page 1: welcome + name ----
  Widget _welcomePage(ThemeData theme, Color accent) {
    return _PageBody(
      children: [
        _badge('👋', accent),
        const SizedBox(height: AppConstants.spaceL),
        Text('Welcome!', style: _titleStyle(theme)),
        const SizedBox(height: AppConstants.spaceS),
        Text(
          "Let's make this yours. What should we call you?",
          textAlign: TextAlign.center,
          style: _subtitleStyle(theme),
        ),
        const SizedBox(height: AppConstants.spaceXl),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          textAlign: TextAlign.center,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          decoration: const InputDecoration(
            hintText: 'Your name',
          ),
        ),
        const SizedBox(height: AppConstants.spaceS),
        Text(
          "Optional — you can skip if you'd rather.",
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  // ---- Page 2: theme color ----
  Widget _colorPage(ThemeData theme, Color accent) {
    return _PageBody(
      children: [
        _badge('🎨', accent),
        const SizedBox(height: AppConstants.spaceL),
        Text('Pick your color', style: _titleStyle(theme)),
        const SizedBox(height: AppConstants.spaceS),
        Text(
          'It themes the whole app. Change it anytime from Home.',
          textAlign: TextAlign.center,
          style: _subtitleStyle(theme),
        ),
        const SizedBox(height: AppConstants.spaceXl),
        Wrap(
          spacing: AppConstants.spaceL,
          runSpacing: AppConstants.spaceL,
          alignment: WrapAlignment.center,
          children: [
            for (final option in kThemeColors)
              _colorDot(option, accent),
          ],
        ),
      ],
    );
  }

  Widget _colorDot(ThemeColorOption option, Color accent) {
    final selected = option.color.toARGB32() == accent.toARGB32();
    return GestureDetector(
      onTap: () =>
          ref.read(themeColorProvider.notifier).setColor(option.color),
      child: SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (selected)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: option.color, width: 3),
                ),
              ),
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: option.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: option.color.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 24)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ---- Page 3: all set + starter categories ----
  Widget _readyPage(ThemeData theme, Color accent) {
    final name = _nameController.text.trim();
    final expenseCats =
        ref.watch(categoriesByKindProvider(TransactionType.expense)).take(6);

    return _PageBody(
      children: [
        _badge('🎉', accent),
        const SizedBox(height: AppConstants.spaceL),
        Text(
          name.isEmpty ? "You're all set!" : "You're all set, $name!",
          textAlign: TextAlign.center,
          style: _titleStyle(theme),
        ),
        const SizedBox(height: AppConstants.spaceS),
        Text(
          'Your starter categories are ready. Log your first transaction and '
          'watch your money story unfold.',
          textAlign: TextAlign.center,
          style: _subtitleStyle(theme),
        ),
        const SizedBox(height: AppConstants.spaceXl),
        Wrap(
          spacing: AppConstants.spaceS,
          runSpacing: AppConstants.spaceS,
          alignment: WrapAlignment.center,
          children: [
            for (final c in expenseCats)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: c.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(c.emoji, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 6),
                    Text(
                      c.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ---- Shared bits ----
  Widget _badge(String emoji, Color accent) {
    return Container(
      width: 88,
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 40)),
    );
  }

  TextStyle _titleStyle(ThemeData theme) => TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: theme.colorScheme.onSurface,
      );

  TextStyle? _subtitleStyle(ThemeData theme) => theme.textTheme.bodyMedium
      ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6));
}

/// Centered, padded body used by every onboarding page.
class _PageBody extends StatelessWidget {
  const _PageBody({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppConstants.spaceXl),
          ...children,
          const SizedBox(height: AppConstants.spaceXl),
        ],
      ),
    );
  }
}

/// Full-width gradient primary button (matches the chosen theme color).
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.color,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final darker = Color.lerp(color, Colors.black, 0.18)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, darker]),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 16,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
