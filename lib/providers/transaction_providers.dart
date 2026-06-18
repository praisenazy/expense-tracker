import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../core/constants/app_constants.dart';
import '../data/models/transaction.dart';
import '../data/repositories/transaction_repository.dart';

/// Provides the already-open Hive box of transactions.
///
/// The box is opened once in main.dart before the app starts, so here we just
/// hand out the existing one.
final transactionsBoxProvider = Provider<Box<Transaction>>((ref) {
  return Hive.box<Transaction>(AppConstants.transactionsBox);
});

/// Provides the repository, built from the box above.
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(transactionsBoxProvider));
});

/// The live list of all transactions (newest first) that the UI watches.
///
/// Calling add/update/remove writes to storage, then refreshes `state` by
/// re-reading from the repository — so the in-memory list always matches disk.
final transactionsProvider =
    NotifierProvider<TransactionsNotifier, List<Transaction>>(
  TransactionsNotifier.new,
);

class TransactionsNotifier extends Notifier<List<Transaction>> {
  TransactionRepository get _repo => ref.read(transactionRepositoryProvider);

  @override
  List<Transaction> build() => _repo.getAll();

  /// Add a brand-new transaction.
  Future<void> add(Transaction transaction) async {
    await _repo.add(transaction);
    state = _repo.getAll();
  }

  /// Save changes to an existing transaction (matched by its id).
  Future<void> update(Transaction transaction) async {
    await _repo.update(transaction);
    state = _repo.getAll();
  }

  /// Delete a transaction by id.
  Future<void> remove(String id) async {
    await _repo.delete(id);
    state = _repo.getAll();
  }
}
