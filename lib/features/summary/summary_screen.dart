import 'dart:async';
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

  // Distinct color per category, assigned by rank (biggest first). Cycles if
  // there are more categories than colors.
  // Segment colors assigned by rank — biggest spending first — exactly per the
  // reference design.
  static const List<Color> _palette = [
    Color(0xFFF05A28), // largest
    Color(0xFFF2385A), // 2nd
    Color(0xFF7B2FBE), // 3rd
    Color(0xFF9C27B0), // 4th
    Color(0xFF4A90D9), // 5th
    Color(0xFF5BC8F5), // 6th
    Color(0xFF3DBFA8), // 7th
    Color(0xFF4CAF50), // 8th
    Color(0xFF2E7D32), // 9th
    Color(0xFF8BC34A), // smallest
  ];
  static const Color _expenseColor = Color(0xFFE0544C);
  static const Color _incomeColor = Color(0xFF27AE60);
  static const Color _amber = Color(0xFFF2A93C);

  Color _colorFor(int index, int count) => _palette[index % _palette.length];

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
                          isIncome: _showIncome,
                          onSwap: () =>
                              setState(() => _showIncome = !_showIncome),
                        ),
                        const SizedBox(height: AppConstants.spaceL),
                        for (var i = 0; i < entries.length; i++)
                          _CategoryRow(
                            color: _colorFor(i, entries.length),
                            emoji: entries[i].key.emoji,
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

/// Donut chart matching the reference design: a "Total" label in the center,
/// each category's emoji in a white circle around the ring, a percentage by
/// each slice, and — when a slice is tapped — its amount popping out for a few
/// seconds. Tapping the center swaps between expense and income.
class _Donut extends StatefulWidget {
  const _Donut({
    required this.entries,
    required this.colorFor,
    required this.onSwap,
    required this.isIncome,
  });

  final List<MapEntry<Category, double>> entries;
  final Color Function(int index, int count) colorFor;
  final VoidCallback onSwap;
  final bool isIncome;

  @override
  State<_Donut> createState() => _DonutState();
}

class _DonutState extends State<_Donut> {
  // Donut geometry (radii measured from the chart center).
  static const double _centerSpace = 84; // empty hole for the total label
  static const double _ringRadius = 65; // ring thickness (bigger, wider ring)
  // Icons float just OUTSIDE the ring's outer edge, at each segment's edge.
  static const double _rIcon = _centerSpace + _ringRadius + 13;
  static const double _height = 360;

  // The slice the user last tapped; its amount pops out for a few seconds.
  int? _selected;
  Timer? _revertTimer;

  @override
  void dispose() {
    _revertTimer?.cancel();
    super.dispose();
  }

  void _selectSlice(int entryIndex) {
    setState(() => _selected = entryIndex);
    _revertTimer?.cancel();
    _revertTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _selected = null);
    });
  }

  /// A point at [radius] from the center on the given slice-[fraction]
  /// (0 = top, increasing clockwise), for placing labels/icons/bubbles.
  Offset _polar(double fraction, double radius) {
    final theta = fraction * 2 * math.pi;
    return Offset(radius * math.sin(theta), -radius * math.cos(theta));
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.55);

    // Give every category a minimum wedge so tiny ones stay visible on the
    // ring (the list below still shows the true amounts/percentages).
    final rawTotal = entries.fold<double>(0, (sum, e) => sum + e.value);
    final minValue = rawTotal * 0.04; // each slice is at least ~4% of the ring
    final displayValues = [
      for (final e in entries) math.max(e.value, minValue),
    ];
    final displayTotal = displayValues.fold<double>(0, (sum, v) => sum + v);

    // Mid-angle fraction of each slice — where its icon/label/bubble sits.
    final midFrac = <double>[];
    var before = 0.0;
    for (var i = 0; i < entries.length; i++) {
      midFrac.add(
        displayTotal == 0 ? 0 : (before + displayValues[i] / 2) / displayTotal,
      );
      before += displayValues[i];
    }

    final sections = [
      for (var i = 0; i < entries.length; i++)
        PieChartSectionData(
          value: displayValues[i],
          color: widget.colorFor(i, entries.length),
          radius: _ringRadius + (_selected == i ? 10 : 0), // tapped pops out
          // Percentage sits INSIDE the slice, in white.
          showTitle: true,
          title:
              '${(rawTotal == 0 ? 0 : entries[i].value / rawTotal * 100).round()}%',
          titlePositionPercentageOffset: 0.5,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
    ];

    return SizedBox(
      height: _height,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none, // let icons/labels sit outside the ring
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: _centerSpace,
              startDegreeOffset: -90, // first slice starts at the top
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (event is! FlTapUpEvent) return;
                  final i = response?.touchedSection?.touchedSectionIndex ?? -1;
                  if (i >= 0 && i < entries.length) _selectSlice(i);
                },
              ),
              sections: sections,
            ),
          ),

          // Center total — tap to swap expense/income.
          GestureDetector(
            onTap: widget.onSwap,
            behavior: HitTestBehavior.opaque,
            child: _centerTotal(rawTotal, muted),
          ),

          // Emoji icon circles sitting on the ring's outer edge. The tapped
          // slice shows its amount bubble instead of the icon.
          for (var i = 0; i < entries.length; i++)
            if (_selected != i)
              Align(
                child: Transform.translate(
                  offset: _polar(midFrac[i], _rIcon),
                  child: _iconCircle(
                    entries[i].key,
                    widget.colorFor(i, entries.length),
                  ),
                ),
              ),

          // Amount bubble that pops out where the tapped slice's icon was.
          if (_selected != null)
            Align(
              child: Transform.translate(
                offset: _polar(midFrac[_selected!], _rIcon),
                child: _amountBubble(entries[_selected!]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _centerTotal(double total, Color muted) {
    return SizedBox(
      width: 116,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.isIncome ? 'Total Income' : 'Total Expenses',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              Formatters.money(total),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A category's emoji in a white circle with a colored ring — the badges
  /// sitting around the donut in the reference design.
  Widget _iconCircle(Category category, Color color) {
    return Container(
      width: 60,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(category.emoji, style: const TextStyle(fontSize: 26)),
    );
  }

  /// The amount bubble that pops out on the tapped slice, with a white ring
  /// and a bouncy entrance (like the reference).
  Widget _amountBubble(MapEntry<Category, double> entry) {
    final sign = widget.isIncome ? '' : '-';
    final color = widget.colorFor(_selected!, widget.entries.length);

    return TweenAnimationBuilder<double>(
      key: ValueKey(_selected),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          '$sign${Formatters.money(entry.value)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// A category row: colored dot, name + percentage, and amount.
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.color,
    required this.emoji,
    required this.name,
    required this.percent,
    required this.amountText,
    required this.amountColor,
  });

  final Color color;
  final String emoji;
  final String name;
  final double percent;
  final String amountText;
  final Color amountColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spaceM,
            vertical: 10,
          ),
          child: Row(
            children: [
              // Emoji in a colored circle matching the segment color.
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: AppConstants.spaceM),
              // Category name.
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Percentage.
              Text(
                '${percent.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppConstants.spaceM),
              // Amount.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    amountText,
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
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
