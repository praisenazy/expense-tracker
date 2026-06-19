import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/category.dart';
import '../../data/models/transaction_type.dart';

/// A blueprint for a default category (no id yet).
class _CategorySpec {
  const _CategorySpec(this.name, this.kind, this.icon, this.colorValue);
  final String name;
  final TransactionType kind;
  final IconData icon;
  final int colorValue;
}

/// The categories created the first time the app runs.
///
/// Income categories describe WHERE money came from; expense categories
/// describe WHAT it was spent on. Users can add their own later.
const List<_CategorySpec> _defaultSpecs = [
  // ---- Income: where the money came from ----
  _CategorySpec('Salary', TransactionType.income, Icons.payments_rounded, 0xFF2E7D32),
  _CategorySpec('Gift', TransactionType.income, Icons.card_giftcard_rounded, 0xFFEC407A),
  _CategorySpec('Investment', TransactionType.income, Icons.trending_up_rounded, 0xFF5C6BC0),
  _CategorySpec('Temporary', TransactionType.income, Icons.work_rounded, 0xFFF9A825),
  _CategorySpec('Sell', TransactionType.income, Icons.storefront_rounded, 0xFF42A5F5),
  _CategorySpec('Content', TransactionType.income, Icons.laptop_mac_rounded, 0xFF00ACC1),
  _CategorySpec('Affiliate', TransactionType.income, Icons.handshake_rounded, 0xFF26A69A),

  // ---- Expense: what the money was spent on ----
  _CategorySpec('Food', TransactionType.expense, Icons.restaurant_rounded, 0xFFFF7043),
  _CategorySpec('Transport', TransactionType.expense, Icons.directions_bus_rounded, 0xFF42A5F5),
  _CategorySpec('Bills', TransactionType.expense, Icons.receipt_long_rounded, 0xFFAB47BC),
  _CategorySpec('Entertainment', TransactionType.expense, Icons.movie_rounded, 0xFFEC407A),
  _CategorySpec('Health', TransactionType.expense, Icons.favorite_rounded, 0xFF26A69A),
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
        iconCodePoint: s.icon.codePoint,
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
