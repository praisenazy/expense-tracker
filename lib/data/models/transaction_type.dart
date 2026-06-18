import 'package:hive_ce/hive.dart';

import '../../core/constants/app_constants.dart';

part 'transaction_type.g.dart';

/// Whether a transaction is money coming IN or going OUT.
///
/// An enum is a fixed set of named options. Stored inside each Transaction,
/// so it needs its own Hive type id (see AppConstants).
@HiveType(typeId: AppConstants.transactionTypeEnumId)
enum TransactionType {
  @HiveField(0)
  income,

  @HiveField(1)
  expense;

  /// Human-friendly label for the UI.
  String get label => this == TransactionType.income ? 'Income' : 'Expense';

  /// Convenience checks that read nicely at call sites.
  bool get isIncome => this == TransactionType.income;
  bool get isExpense => this == TransactionType.expense;
}
