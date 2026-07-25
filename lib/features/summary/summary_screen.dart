import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/category.dart';
import '../../providers/summary_providers.dart';
import '../../providers/transaction_providers.dart';
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

  /// A short, human insight: the biggest category and how this month compares
  /// to the last — the chart in words.
  Widget _insightCard(
    ThemeData theme,
    List<MapEntry<Category, double>> entries,
    double total,
    double prevTotal,
  ) {
    if (entries.isEmpty || total <= 0) return const SizedBox.shrink();

    final top = entries.first;
    final topPct = (top.value / total * 100).round();
    final role = _showIncome ? 'top income source' : 'biggest expense';

    // Comparison to last month.
    final verb = _showIncome ? 'earned' : 'spent';
    var compColor = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    IconData? compIcon;
    String comparison;
    if (prevTotal <= 0) {
      comparison = "First month you're tracking this — great start! 🎉";
    } else {
      final delta = (total - prevTotal) / prevTotal * 100;
      if (delta.abs() < 1) {
        comparison = 'About the same as last month.';
      } else {
        final dir = delta < 0 ? 'less' : 'more';
        final good = _showIncome ? delta > 0 : delta < 0;
        compColor = good ? _incomeColor : _expenseColor;
        compIcon = delta < 0
            ? Icons.trending_down_rounded
            : Icons.trending_up_rounded;
        comparison = 'You $verb ${delta.abs().round()}% $dir than last month';
      }
    }

    // Loss-framed budget nudge: the most at-risk expense category (≥80% used).
    // Framing what they're about to overspend motivates more than a gain.
    MapEntry<Category, double>? risk;
    var riskRatio = 0.0;
    if (!_showIncome) {
      for (final e in entries) {
        if (!e.key.hasBudget) continue;
        final r = e.value / e.key.monthlyBudget;
        if (r >= 0.8 && r > riskRatio) {
          risk = e;
          riskRatio = r;
        }
      }
    }
    final nudge = risk == null
        ? null
        : riskRatio > 1.0
            ? "You're ${Formatters.money(risk.value - risk.key.monthlyBudget)} "
                'over your ${risk.key.name} budget.'
            : "You've used ${(riskRatio * 100).round()}% of your "
                '${risk.key.name} budget.';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.spaceM),
      padding: const EdgeInsets.all(AppConstants.spaceM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(top.key.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: top.key.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(text: ' is your $role — '),
                      TextSpan(
                        text: '$topPct%',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (compIcon != null) ...[
                Icon(compIcon, size: 16, color: compColor),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  comparison,
                  style: TextStyle(
                    color: compColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (nudge != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: riskRatio > 1.0
                      ? const Color(0xFFE0544C)
                      : const Color(0xFFF2A93C),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    nudge,
                    style: TextStyle(
                      color: riskRatio > 1.0
                          ? const Color(0xFFE0544C)
                          : const Color(0xFFF2A93C),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
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

    // Same side's total for the PREVIOUS month, for a comparison insight.
    final prevMonth = DateTime(month.year, month.month - 1);
    var prevTotal = 0.0;
    for (final t in ref.watch(transactionsProvider)) {
      if (t.date.year == prevMonth.year &&
          t.date.month == prevMonth.month &&
          t.type.isIncome == _showIncome) {
        prevTotal += t.amount;
      }
    }

    return Scaffold(
      // Let content run full-bleed behind the floating nav (like Home); the
      // list's bottom padding keeps the rows clear of the pill.
      body: SafeArea(
        bottom: false,
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
                      title: _showIncome
                          ? 'No income yet this month'
                          : 'No expenses yet this month',
                      message: _showIncome
                          ? 'Log some income and watch this chart show exactly '
                              'where your money comes from.'
                          : 'Log a few expenses and this chart will show exactly '
                              'where your money goes.',
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 120),
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
                        _insightCard(theme, entries, total, prevTotal),
                        const SizedBox(height: AppConstants.spaceM),
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
                            // Budgets apply to the expense side only.
                            budget: _showIncome
                                ? 0
                                : entries[i].key.monthlyBudget,
                            spent: entries[i].value,
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
    this.budget = 0,
    this.spent = 0,
  });

  final Color color;
  final String emoji;
  final String name;
  final double percent;
  final String amountText;
  final Color amountColor;

  /// Monthly budget for this category (0 = none) and how much is spent so far.
  final double budget;
  final double spent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppConstants.spaceM,
            10,
            AppConstants.spaceM,
            budget > 0 ? 0 : 10,
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
        if (budget > 0) _budgetBar(theme, muted),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  /// A slim budget progress bar with a loss-framed status line: green while
  /// there's room, amber past 80%, red when over.
  Widget _budgetBar(ThemeData theme, Color muted) {
    const amber = Color(0xFFF2A93C);
    const red = Color(0xFFE0544C);
    final ratio = budget <= 0 ? 0.0 : spent / budget;
    final over = ratio > 1.0;
    final barColor = over
        ? red
        : ratio >= 0.8
            ? amber
            : color;

    final status = over
        ? 'Over by ${Formatters.money(spent - budget)}'
        : '${Formatters.money(spent)} of ${Formatters.money(budget)} '
            '• ${(ratio * 100).round()}% used';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceM + 44 + AppConstants.spaceM,
        4,
        AppConstants.spaceM,
        10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor:
                  theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.6,
              ),
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (over) ...[
                const Icon(Icons.warning_amber_rounded, size: 13, color: red),
                const SizedBox(width: 4),
              ],
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: over ? FontWeight.w700 : FontWeight.w500,
                  color: over ? red : muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
