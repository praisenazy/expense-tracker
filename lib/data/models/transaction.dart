import 'package:hive_ce/hive.dart';

import '../../core/constants/app_constants.dart';
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
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.note,
  });

  /// Stable unique id (generated with the `uuid` package). Used to find this
  /// exact record when editing or deleting.
  @HiveField(0)
  final String id;

  /// Always POSITIVE. The sign comes from [type] (see [signedAmount]).
  @HiveField(1)
  final double amount;

  /// Income or expense.
  @HiveField(2)
  final TransactionType type;

  /// The id of the Category this belongs to (income source or expense type).
  /// We store the id (not the Category object) so renaming/restyling a category
  /// is reflected everywhere automatically.
  @HiveField(3)
  final String categoryId;

  /// When the transaction happened.
  @HiveField(4)
  final DateTime date;

  /// Optional free-text description. This is what shows on the transaction row;
  /// when empty, the UI falls back to the category name.
  @HiveField(5)
  final String? note;

  /// +amount for income, -amount for expense. Handy for summing a balance.
  double get signedAmount => type.isIncome ? amount : -amount;

  /// Returns a copy with the given fields replaced. Anything not passed keeps
  /// its current value. This is how we "edit" an immutable object.
  Transaction copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? categoryId,
    DateTime? date,
    String? note,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}
