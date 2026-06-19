import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/category.dart';
import '../data/models/transaction.dart';
import 'category_providers.dart';
import 'transaction_providers.dart';

/// The month currently shown on the Summary screen.
///
/// Stored as the FIRST day of the month (e.g. 2026-06-01) so comparisons are
/// simple. Defaults to the current month.
final selectedMonthProvider =
    NotifierProvider<SelectedMonthNotifier, DateTime>(SelectedMonthNotifier.new);

class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void nextMonth() => state = DateTime(state.year, state.month + 1);

  void previousMonth() => state = DateTime(state.year, state.month - 1);
}

/// Plain value object holding the numbers for one month.
class MonthlySummary {
  const MonthlySummary({
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.expenseByCategory,
    required this.transactions,
  });

  final DateTime month;
  final double totalIncome;
  final double totalExpense;

  /// Expense totals per category — drives the pie chart.
  final Map<Category, double> expenseByCategory;

  /// The transactions that fall in this month (newest first).
  final List<Transaction> transactions;

  /// Income minus expense.
  double get balance => totalIncome - totalExpense;

  /// True when there's nothing to show for this month.
  bool get isEmpty => transactions.isEmpty;
}

/// Derived summary for the selected month. Recomputes automatically whenever
/// transactions or the selected month change. Stores no state of its own.
final monthlySummaryProvider = Provider<MonthlySummary>((ref) {
  final all = ref.watch(transactionsProvider);
  final month = ref.watch(selectedMonthProvider);
  final categoriesById = ref.watch(categoryByIdProvider);

  // Keep only transactions in the selected month/year.
  final inMonth = all
      .where((t) => t.date.year == month.year && t.date.month == month.month)
      .toList();

  double income = 0;
  double expense = 0;
  final byCategory = <Category, double>{};

  for (final t in inMonth) {
    if (t.type.isIncome) {
      income += t.amount;
    } else {
      expense += t.amount;
      // Resolve the category; skip if it was deleted (orphaned transaction).
      final category = categoriesById[t.categoryId];
      if (category != null) {
        byCategory[category] = (byCategory[category] ?? 0) + t.amount;
      }
    }
  }

  return MonthlySummary(
    month: month,
    totalIncome: income,
    totalExpense: expense,
    expenseByCategory: byCategory,
    transactions: inMonth,
  );
});
