import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../providers/theme_provider.dart';

/// Opens the theme-color picker as a bottom sheet. Selecting a color updates
/// the whole app theme immediately (and persists it).
Future<void> showThemeColorSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _ThemeColorSheet(),
  );
}

class _ThemeColorSheet extends ConsumerWidget {
  const _ThemeColorSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selected = ref.watch(themeColorProvider);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.spaceL,
          0,
          AppConstants.spaceL,
          AppConstants.spaceXl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎨 + "Theme color".
            Row(
              children: [
                Icon(
                  Icons.palette_rounded,
                  color: theme.colorScheme.onSurface,
                  size: 24,
                ),
                const SizedBox(width: AppConstants.spaceS),
                Text(
                  'Theme color',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spaceXs),
            Text(
              'Pick a color for the whole app.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppConstants.spaceXl),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppConstants.spaceXl,
              crossAxisSpacing: AppConstants.spaceM,
              childAspectRatio: 0.82,
              children: [
                for (final option in kThemeColors)
                  _ColorChoice(
                    option: option,
                    isSelected:
                        option.color.toARGB32() == selected.toARGB32(),
                    onTap: () {
                      ref
                          .read(themeColorProvider.notifier)
                          .setColor(option.color);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final ThemeColorOption option;
  final bool isSelected;
  final VoidCallback onTap;

  // Fixed footprint so selecting (which adds an outer ring) never shifts the
  // layout: the ring is drawn at [_outer], the filled circle at [_inner].
  static const double _outer = 74;
  static const double _inner = 56;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _outer,
            height: _outer,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Detached colored ring (with a white gap) when selected.
                if (isSelected)
                  Container(
                    width: _outer,
                    height: _outer,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: option.color, width: 4),
                    ),
                  ),
                // The filled color circle with a soft shadow.
                Container(
                  width: _inner,
                  height: _inner,
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
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 26)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spaceS),
          Text(
            option.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
