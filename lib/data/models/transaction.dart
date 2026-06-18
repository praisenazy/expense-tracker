import 'package:hive_ce/hive.dart';

import '../../core/constants/app_constants.dart';
import 'expense_category.dart';
import 'transaction_type.dart';

// The generated TransactionAdapter is written into this part file by
// build_runner. It doesn't exist until you run the generator.
part 'transaction.g.dart';

/// A single income or expense record.
///
/// The class is IMMUTABLE: every field is `final`, so a Transaction never
/// changes after it's created. To "edit" one, we build a modified copy with
/// [copyWith]. Immutability makes state changes predictable and bug-resistant.
@HiveType(typeId: AppConstants.transactionTypeId)
class Transaction {
  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note,
  });

  /// Stable unique id (generated with the `uuid` package). Used to find this
  /// exact record when editing or deleting.
  @HiveField(0)
  final String id;

  /// Short description, e.g. "Groceries".
  @HiveField(1)
  final String title;

  /// Always POSITIVE. The sign comes from [type] (see [signedAmount]).
  @HiveField(2)
  final double amount;

  /// Income or expense.
  @HiveField(3)
  final TransactionType type;

  /// One of the six spending categories.
  @HiveField(4)
  final ExpenseCategory category;

  /// When the transaction happened.
  @HiveField(5)
  final DateTime date;

  /// Optional free-text note.
  @HiveField(6)
  final String? note;

  /// +amount for income, -amount for expense. Handy for summing a balance.
  double get signedAmount => type.isIncome ? amount : -amount;

  /// Returns a copy with the given fields replaced. Anything not passed keeps
  /// its current value. This is how we "edit" an immutable object.
  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    ExpenseCategory? category,
    DateTime? date,
    String? note,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}
