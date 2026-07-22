import 'package:uuid/uuid.dart';

import '../../data/models/category.dart';
import '../../data/models/transaction_type.dart';

/// A blueprint for a default category (no id yet).
class _CategorySpec {
  const _CategorySpec(this.name, this.kind, this.emoji, this.colorValue);
  final String name;
  final TransactionType kind;
  final String emoji;
  final int colorValue;
}

/// The categories created on first launch. Income and expense have separate
/// sets, so the two sides of the form show different chips. Users can add their
/// own (and edit/delete the ones they add).
const List<_CategorySpec> _defaultSpecs = [
  // ---- Expense: what the money was spent on ----
  _CategorySpec('Food', TransactionType.expense, '🍔', 0xFFFF7043),
  _CategorySpec('Transport', TransactionType.expense, '🚌', 0xFF42A5F5),
  _CategorySpec('Bills', TransactionType.expense, '🧾', 0xFFAB47BC),
  _CategorySpec('Entertainment', TransactionType.expense, '🎬', 0xFFEC407A),
  _CategorySpec('Health', TransactionType.expense, '💗', 0xFF26A69A),

  // ---- Income: where the money came from ----
  _CategorySpec('Salary', TransactionType.income, '💰', 0xFF2E7D32),
  _CategorySpec('Gift', TransactionType.income, '🎁', 0xFFEC407A),
  _CategorySpec('Investment', TransactionType.income, '📈', 0xFF5C6BC0),
  _CategorySpec('Temporary', TransactionType.income, '💼', 0xFFF9A825),
  _CategorySpec('Sell', TransactionType.income, '🏪', 0xFF42A5F5),
  _CategorySpec('Content', TransactionType.income, '💻', 0xFF00ACC1),
  _CategorySpec('Affiliate', TransactionType.income, '🤝', 0xFF26A69A),
];

/// Builds the default categories (with fresh ids) for first-launch seeding.
List<Category> buildDefaultCategories() {
  const uuid = Uuid();
  return [
    for (final s in _defaultSpecs)
      Category(
        id: uuid.v4(),
        name: s.name,
        kind: s.kind,
        iconCodePoint: s.emoji.runes.first,
        colorValue: s.colorValue,
      ),
  ];
}

/// Keys identifying the built-in defaults, e.g. "income|Salary".
final Set<String> _defaultKeys = {
  for (final s in _defaultSpecs) '${s.kind.name}|${s.name}',
};

/// True for the built-in default categories (which can't be deleted).
/// A category the user added themselves returns false.
bool isDefaultCategory(Category category) =>
    _defaultKeys.contains('${category.kind.name}|${category.name}');
