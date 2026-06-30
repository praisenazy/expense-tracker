import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/category.dart';
import '../../providers/summary_providers.dart';
import '../shared/empty_state.dart';

/// Insights screen: an expense/income toggle, a donut chart of the selected
/// side's categories (warm-gradient segments), and a list of those categories
/// with a colored dot, percentage and amount.
class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  bool _showIncome = false;

  // Warm gradient: biggest slice is red, smallest is yellow.
  static const Color _warmStart = Color(0xFFE0544C);
  static const Color _warmEnd = Color(0xFFF6C945);
  static const Color _expenseColor = Color(0xFFE0544C);
  static const Color _incomeColor = Color(0xFF27AE60);
  static const Color _amber = Color(0xFFF2A93C);

  Color _colorFor(int index, int count) {
    if (count <= 1) return _warmStart;
    return Color.lerp(_warmStart, _warmEnd, index / (count - 1))!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = ref.watch(monthlySummaryProvider);
    final month = ref.watch(selectedMonthProvider);
    final monthCtrl = ref.read(selectedMonthProvider.notifier);

    final map = _showIncome
        ? summary.incomeByCategory
        : summary.expenseByCategory;
    final total = _showIncome ? summary.totalIncome : summary.totalExpense;

    // Categories sorted biggest first (drives both the donut and the list).
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ---- Date navigation (arrows close to the label, no clock) ----
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.spaceS,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: monthCtrl.previousMonth,
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: _amber,
                    iconSize: 30, // arrow size — adjust me
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 16), // gap before the label — adjust me
                  Text(
                    Formatters.monthYear(month),
                    style: theme.textTheme.titleLarge?.copyWith(
                      // label size — adjust me
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 16), // gap after the label — adjust me
                  IconButton(
                    onPressed: monthCtrl.nextMonth,
                    icon: const Icon(Icons.chevron_right_rounded),
                    color: _amber,
                    iconSize: 30, // arrow size — adjust me
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // ---- Expense / Income toggle ----
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _ToggleSide(
                      label: 'Expense',
                      amountText: '-${Formatters.money(summary.totalExpense)}',
                      active: !_showIncome,
                      activeColor: _expenseColor,
                      onTap: () => setState(() => _showIncome = false),
                    ),
                  ),
                  const VerticalDivider(width: 1, indent: 12, endIndent: 12),
                  Expanded(
                    child: _ToggleSide(
                      label: 'Income',
                      amountText: Formatters.money(summary.totalIncome),
                      active: _showIncome,
                      activeColor: _incomeColor,
                      onTap: () => setState(() => _showIncome = true),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ---- Donut + category list ----
            Expanded(
              child: entries.isEmpty
                  ? EmptyState(
                      icon: Icons.donut_large_rounded,
                      title: _showIncome ? 'No income' : 'No expenses',
                      message: _showIncome
                          ? 'Add income this month to see where it comes from.'
                          : 'Add expenses this month to see where your money goes.',
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 110),
                      children: [
                        const SizedBox(height: AppConstants.spaceL),
                        _Donut(
                          entries: entries,
                          colorFor: _colorFor,
                          centerColor: _amber,
                          // Black shadow vanishes on dark backgrounds, so use a
                          // red-tinted glow (the slice's color) in dark mode.
                          shadowColor: theme.brightness == Brightness.dark
                              ? _warmStart.withValues(alpha: 0.55)
                              : Colors.black.withValues(alpha: 0.30),
                          onSwap: () =>
                              setState(() => _showIncome = !_showIncome),
                        ),
                        const SizedBox(height: AppConstants.spaceL),
                        for (var i = 0; i < entries.length; i++)
                          _CategoryRow(
                            color: _colorFor(i, entries.length),
                            name: entries[i].key.name,
                            percent: total == 0
                                ? 0
                                : entries[i].value / total * 100,
                            amountText: _showIncome
                                ? Formatters.money(entries[i].value)
                                : '-${Formatters.money(entries[i].value)}',
                            amountColor: _showIncome
                                ? _incomeColor
                                : _expenseColor,
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One side of the expense/income toggle.
class _ToggleSide extends StatelessWidget {
  const _ToggleSide({
    required this.label,
    required this.amountText,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final String amountText;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.4);
    final color = active ? activeColor : muted;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceM),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                amountText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: active ? theme.colorScheme.onSurface : muted,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  active
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Donut chart with a "Category" center label and a swap control.
class _Donut extends StatelessWidget {
  const _Donut({
    required this.entries,
    required this.colorFor,
    required this.centerColor,
    required this.shadowColor,
    required this.onSwap,
  });

  final List<MapEntry<Category, double>> entries;
  final Color Function(int index, int count) colorFor;
  final Color centerColor;
  final Color shadowColor;
  final VoidCallback onSwap;

  // Donut geometry.
  static const double _centerSpace = 68;
  static const double _baseRadius = 30;
  static const double _topRadius = 38; // the biggest slice pops out a bit

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.5);

    final total = entries.fold<double>(0, (sum, e) => sum + e.value);
    // Sweep (radians) of the largest slice, starting at the top (-90°).
    final topSweep = total == 0
        ? 0.0
        : (entries.first.value / total) * 2 * math.pi;

    return SizedBox(
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft drop shadow under the biggest (red) slice.
          Positioned.fill(
            child: CustomPaint(
              painter: _SliceShadowPainter(
                startRadians: -math.pi / 2,
                sweepRadians: topSweep,
                ringRadius: _centerSpace + _topRadius / 2,
                strokeWidth: _topRadius,
                color: shadowColor,
              ),
            ),
          ),
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: _centerSpace,
              startDegreeOffset: -90,
              sections: [
                for (var i = 0; i < entries.length; i++)
                  PieChartSectionData(
                    value: entries[i].value,
                    color: colorFor(i, entries.length),
                    radius: i == 0 ? _topRadius : _baseRadius,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          // Center label.
          GestureDetector(
            onTap: onSwap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_offer_outlined, color: muted, size: 20),
                const SizedBox(height: 4),
                Text(
                  'Category',
                  style: TextStyle(
                    color: muted,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(Icons.swap_horiz_rounded, color: centerColor, size: 22),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A category row: colored dot, name + percentage, and amount.
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.color,
    required this.name,
    required this.percent,
    required this.amountText,
    required this.amountColor,
  });

  final Color color;
  final String name;
  final double percent;
  final String amountText;
  final Color amountColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spaceM,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppConstants.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${percent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.spaceS),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    amountText,
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}

/// Paints a soft, blurred drop shadow under a single donut slice (the biggest
/// one), offset down-right so the slice looks raised — like the reference.
class _SliceShadowPainter extends CustomPainter {
  _SliceShadowPainter({
    required this.startRadians,
    required this.sweepRadians,
    required this.ringRadius,
    required this.strokeWidth,
    required this.color,
  });

  final double startRadians;
  final double sweepRadians;
  final double ringRadius;
  final double strokeWidth;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (sweepRadians <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(
      center: center + const Offset(4, 8), // push the shadow down-right
      radius: ringRadius,
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(rect, startRadians, sweepRadians, false, paint);
  }

  @override
  bool shouldRepaint(_SliceShadowPainter old) =>
      old.startRadians != startRadians ||
      old.sweepRadians != sweepRadians ||
      old.ringRadius != ringRadius ||
      old.strokeWidth != strokeWidth ||
      old.color != color;
}
