import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_project/data/models/expense_category.dart';
import 'package:my_project/data/models/transaction.dart';
import 'package:my_project/data/models/transaction_type.dart';
import 'package:my_project/providers/summary_providers.dart';
import 'package:my_project/providers/transaction_providers.dart';

/// Stub that feeds a fixed transaction list instead of reading Hive.
class _StubTransactions extends TransactionsNotifier {
  _StubTransactions(this._data);
  final List<Transaction> _data;

  @override
  List<Transaction> build() => _data;
}

/// Stub that pins the selected month to a fixed value.
class _StubMonth extends SelectedMonthNotifier {
  _StubMonth(this._month);
  final DateTime _month;

  @override
  DateTime build() => _month;
}

Transaction _tx({
  required String id,
  required double amount,
  required TransactionType type,
  ExpenseCategory category = ExpenseCategory.food,
  required DateTime date,
}) {
  return Transaction(
    id: id,
    title: id,
    amount: amount,
    type: type,
    category: category,
    date: date,
  );
}

void main() {
  test('summary totals only the selected month and groups expenses', () {
    final transactions = [
      _tx(
        id: 'income',
        amount: 1000,
        type: TransactionType.income,
        date: DateTime(2026, 6, 5),
      ),
      _tx(
        id: 'food',
        amount: 200,
        type: TransactionType.expense,
        category: ExpenseCategory.food,
        date: DateTime(2026, 6, 10),
      ),
      _tx(
        id: 'transport',
        amount: 300,
        type: TransactionType.expense,
        category: ExpenseCategory.transport,
        date: DateTime(2026, 6, 12),
      ),
      // Different month — must be excluded.
      _tx(
        id: 'may-food',
        amount: 50,
        type: TransactionType.expense,
        category: ExpenseCategory.food,
        date: DateTime(2026, 5, 30),
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        transactionsProvider.overrideWith(() => _StubTransactions(transactions)),
        selectedMonthProvider.overrideWith(() => _StubMonth(DateTime(2026, 6))),
      ],
    );
    addTearDown(container.dispose);

    final summary = container.read(monthlySummaryProvider);

    expect(summary.totalIncome, 1000);
    expect(summary.totalExpense, 500); // 200 + 300, May excluded
    expect(summary.balance, 500);
    expect(summary.expenseByCategory[ExpenseCategory.food], 200);
    expect(summary.expenseByCategory[ExpenseCategory.transport], 300);
    expect(summary.transactions, hasLength(3)); // June only
  });
}
