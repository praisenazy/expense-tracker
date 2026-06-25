import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_project/data/models/category.dart';
import 'package:my_project/data/models/transaction.dart';
import 'package:my_project/data/models/transaction_type.dart';
import 'package:my_project/providers/category_providers.dart';
import 'package:my_project/providers/summary_providers.dart';
import 'package:my_project/providers/transaction_providers.dart';

/// Stub that feeds a fixed transaction list instead of reading Hive.
class _StubTransactions extends TransactionsNotifier {
  _StubTransactions(this._data);
  final List<Transaction> _data;

  @override
  List<Transaction> build() => _data;
}

/// Stub that feeds a fixed category list instead of reading Hive.
class _StubCategories extends CategoriesNotifier {
  _StubCategories(this._data);
  final List<Category> _data;

  @override
  List<Category> build() => _data;
}

/// Stub that pins the selected month to a fixed value.
class _StubMonth extends SelectedMonthNotifier {
  _StubMonth(this._month);
  final DateTime _month;

  @override
  DateTime build() => _month;
}

Category _cat(String id, TransactionType kind) => Category(
      id: id,
      name: id,
      kind: kind,
      iconCodePoint: 0xe000,
      colorValue: 0xFF000000,
    );

Transaction _tx({
  required String id,
  required double amount,
  required TransactionType type,
  required String categoryId,
  required DateTime date,
}) {
  return Transaction(
    id: id,
    amount: amount,
    type: type,
    categoryId: categoryId,
    date: date,
  );
}

void main() {
  test('summary totals only the selected month and groups expenses', () {
    final categories = [
      _cat('food', TransactionType.expense),
      _cat('transport', TransactionType.expense),
      _cat('salary', TransactionType.income),
    ];

    final transactions = [
      _tx(
        id: 'income',
        amount: 1000,
        type: TransactionType.income,
        categoryId: 'salary',
        date: DateTime(2026, 6, 5),
      ),
      _tx(
        id: 'food1',
        amount: 200,
        type: TransactionType.expense,
        categoryId: 'food',
        date: DateTime(2026, 6, 10),
      ),
      _tx(
        id: 'transport1',
        amount: 300,
        type: TransactionType.expense,
        categoryId: 'transport',
        date: DateTime(2026, 6, 12),
      ),
      // Different month — must be excluded.
      _tx(
        id: 'may-food',
        amount: 50,
        type: TransactionType.expense,
        categoryId: 'food',
        date: DateTime(2026, 5, 30),
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        transactionsProvider.overrideWith(() => _StubTransactions(transactions)),
        categoriesProvider.overrideWith(() => _StubCategories(categories)),
        selectedMonthProvider.overrideWith(() => _StubMonth(DateTime(2026, 6))),
      ],
    );
    addTearDown(container.dispose);

    final summary = container.read(monthlySummaryProvider);

    expect(summary.totalIncome, 1000);
    expect(summary.totalExpense, 500); // 200 + 300, May excluded
    expect(summary.balance, 500);
    expect(summary.transactions, hasLength(3)); // June only

    // expenseByCategory is keyed by the resolved Category objects.
    final byName = {
      for (final entry in summary.expenseByCategory.entries)
        entry.key.name: entry.value,
    };
    expect(byName['food'], 200);
    expect(byName['transport'], 300);
  });
}
