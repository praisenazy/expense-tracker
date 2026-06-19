import 'package:flutter/material.dart';

import '../../../data/models/transaction_type.dart';

/// An animated sliding pill toggle for Expense vs Income.
///
/// A colored "thumb" slides between the two halves, animating both its
/// position (AnimatedAlign) and its color (AnimatedContainer): red on the
/// Expense side, blue on the Income side. The active label is white.
///
/// Controlled widget: the parent owns [value]; tapping reports via [onChanged].
class TypeToggle extends StatelessWidget {
  const TypeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final TransactionType value;
  final ValueChanged<TransactionType> onChanged;

  static const Color _expenseColor = Color(0xFFEF5350); // red
  static const Color _incomeColor = Color(0xFF4285F4); // blue
  static const Duration _duration = Duration(milliseconds: 280);
  static const Curve _curve = Curves.easeInOutCubic;

  static const double _height = 56;
  static const double _inset = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = value == TransactionType.expense;

    // Light-grey track that still looks right in dark mode.
    final trackColor = theme.brightness == Brightness.dark
        ? const Color(0xFF2A2A2D)
        : const Color(0xFFEFEFEF);
    final thumbColor = isExpense ? _expenseColor : _incomeColor;
    final mutedText = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Container(
      height: _height,
      padding: const EdgeInsets.all(_inset),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(_height / 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The thumb covers exactly half of the inner (padded) width.
          final thumbWidth = constraints.maxWidth / 2;

          return Stack(
            children: [
              // The sliding, color-changing thumb.
              AnimatedAlign(
                duration: _duration,
                curve: _curve,
                alignment:
                    isExpense ? Alignment.centerLeft : Alignment.centerRight,
                child: AnimatedContainer(
                  duration: _duration,
                  curve: _curve,
                  width: thumbWidth,
                  height: _height - _inset * 2,
                  decoration: BoxDecoration(
                    color: thumbColor,
                    borderRadius: BorderRadius.circular(_height / 2),
                    boxShadow: [
                      BoxShadow(
                        color: thumbColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),

              // The two tappable labels sit on top of the thumb.
              Row(
                children: [
                  _half(
                    label: 'Expense',
                    icon: Icons.arrow_upward_rounded,
                    selected: isExpense,
                    mutedText: mutedText,
                    onTap: () => onChanged(TransactionType.expense),
                  ),
                  _half(
                    label: 'Income',
                    icon: Icons.arrow_downward_rounded,
                    selected: !isExpense,
                    mutedText: mutedText,
                    onTap: () => onChanged(TransactionType.income),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _half({
    required String label,
    required IconData icon,
    required bool selected,
    required Color mutedText,
    required VoidCallback onTap,
  }) {
    final color = selected ? Colors.white : mutedText;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: _height - _inset * 2,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon color cross-fades smoothly as the thumb slides.
                AnimatedSwitcher(
                  duration: _duration,
                  child: Icon(
                    icon,
                    key: ValueKey(selected),
                    size: 18,
                    color: color,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedDefaultTextStyle(
                  duration: _duration,
                  curve: _curve,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
