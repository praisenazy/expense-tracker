import 'package:hive_ce/hive.dart';

import '../models/transaction.dart';

/// The single place that talks to Hive for transactions.
///
/// The rest of the app (providers, UI) calls these methods and never touches
/// Hive directly. If storage ever changes, only this file changes.
///
/// Each transaction is stored KEYED BY ITS id, so update/delete are simple,
/// exact operations with no searching.
class TransactionRepository {
  TransactionRepository(this._box);

  final Box<Transaction> _box;

  /// All transactions, newest first.
  List<Transaction> getAll() {
    final items = _box.values.toList();
    items.sort((a, b) => b.date.compareTo(a.date)); // newest first
    return items;
  }

  /// Insert a new transaction (its id becomes the key).
  Future<void> add(Transaction transaction) {
    return _box.put(transaction.id, transaction);
  }

  /// Update an existing transaction. Because we key by id, putting the same
  /// id overwrites the old record.
  Future<void> update(Transaction transaction) {
    return _box.put(transaction.id, transaction);
  }

  /// Remove a transaction by its id.
  Future<void> delete(String id) {
    return _box.delete(id);
  }
}
