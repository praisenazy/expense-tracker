import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/summary_providers.dart';
import '../home/widgets/balance_card.dart';
import '../shared/empty_state.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/monthly_bar_chart.dart';

/// Monthly summary with charts. Everything here is derived from providers, so
/// changing the month or editing data updates the charts automatically.
class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(monthlySummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Summary')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.spaceM,
            AppConstants.spaceM,
            AppConstants.spaceM,
            110, // clear the floating nav bar
          ),
          children: [
            // Balance card carries its own month switcher.
            const BalanceCard(),
            const SizedBox(height: AppConstants.spaceL),

            if (summary.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: AppConstants.spaceXl),
                child: EmptyState(
                  icon: Icons.bar_chart_rounded,
                  title: 'No data for this month',
                  message:
                      'Add transactions in this month to see your summary and charts.',
                ),
              )
            else ...[
              // ---- Income vs Expense bar chart ----
              _ChartCard(
                title: 'Income vs Expense',
                child: MonthlyBarChart(
                  income: summary.totalIncome,
                  expense: summary.totalExpense,
                ),
              ),
              const SizedBox(height: AppConstants.spaceM),

              // ---- Expenses by category pie chart ----
              _ChartCard(
                title: 'Expenses by Category',
                child: summary.expenseByCategory.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(AppConstants.spaceL),
                        child: Text('No expenses recorded this month.'),
                      )
                    : CategoryPieChart(
                        expenseByCategory: summary.expenseByCategory,
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A titled card wrapper used for each chart.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppConstants.spaceM),
            child,
          ],
        ),
      ),
    );
  }
}
