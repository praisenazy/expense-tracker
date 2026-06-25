import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/summary_providers.dart';

/// Premium full-width balance card for the home screen.
///
/// Shows the selected month (with ‹ › to switch), the net balance, and the
/// month's income & expense. All text is white on a deep indigo gradient.
class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  static const Color _deep1 = Color(0xFF4338CA); // deep indigo
  static const Color _deep2 = Color(0xFF6D28D9); // violet
  static const Color _incomeGreen = Color(0xFF2BD17E);
  static const Color _expenseRed = Color(0xFFFF6B6B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(monthlySummaryProvider);
    final month = ref.watch(selectedMonthProvider);
    final monthCtrl = ref.read(selectedMonthProvider.notifier);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spaceL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_deep1, _deep2],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _deep1.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // ---- Month switcher ----
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RoundIconButton(
                icon: Icons.chevron_left_rounded,
                onTap: monthCtrl.previousMonth,
              ),
              Text(
                Formatters.monthYear(month),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _RoundIconButton(
                icon: Icons.chevron_right_rounded,
                onTap: monthCtrl.nextMonth,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spaceL),

          // ---- Balance ----
          Text(
            'Total Balance',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppConstants.spaceXs),
          Text(
            Formatters.money(summary.balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppConstants.spaceL),

          // ---- Income / Expense ----
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Income',
                  amount: summary.totalIncome,
                  icon: Icons.arrow_downward_rounded,
                  color: _incomeGreen,
                ),
              ),
              const SizedBox(width: AppConstants.spaceM),
              Expanded(
                child: _MiniStat(
                  label: 'Expense',
                  amount: summary.totalExpense,
                  icon: Icons.arrow_upward_rounded,
                  color: _expenseRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Translucent round button for the month arrows.
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

/// One income/expense figure inside the card.
class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceM),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white,
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppConstants.spaceS),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                Formatters.money(amount),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
