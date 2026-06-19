import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:my_project/core/constants/app_constants.dart';
import 'package:my_project/data/models/transaction.dart';
import 'package:my_project/data/models/transaction_type.dart';
import 'package:my_project/data/repositories/transaction_repository.dart';
import 'package:my_project/hive_registrar.g.dart';

/// Helper to build a transaction with sensible defaults for tests.
Transaction _tx({
  required String id,
  double amount = 100,
  TransactionType type = TransactionType.expense,
  String categoryId = 'cat-food',
  DateTime? date,
}) {
  return Transaction(
    id: id,
    amount: amount,
    type: type,
    categoryId: categoryId,
    date: date ?? DateTime(2026, 6, 1),
  );
}

void main() {
  late Directory tempDir;
  late Box<Transaction> box;
  late TransactionRepository repository;

  setUp(() async {
    // Use a throwaway directory so tests never touch real app data.
    tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(AppConstants.transactionTypeId)) {
      Hive.registerAdapters();
    }
    box = await Hive.openBox<Transaction>(AppConstants.transactionsBox);
    repository = TransactionRepository(box);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('add then getAll returns the stored transaction', () async {
    await repository.add(_tx(id: 'a'));

    final all = repository.getAll();
    expect(all, hasLength(1));
    expect(all.first.id, 'a');
  });

  test('getAll returns transactions newest first', () async {
    await repository.add(_tx(id: 'old', date: DateTime(2026, 1, 1)));
    await repository.add(_tx(id: 'new', date: DateTime(2026, 6, 1)));

    final all = repository.getAll();
    expect(all.map((t) => t.id), ['new', 'old']);
  });

  test('update overwrites the transaction with the same id', () async {
    await repository.add(_tx(id: 'a', amount: 100));
    await repository.update(_tx(id: 'a', amount: 250));

    final all = repository.getAll();
    expect(all, hasLength(1)); // not duplicated
    expect(all.first.amount, 250);
  });

  test('delete removes the transaction', () async {
    await repository.add(_tx(id: 'a'));
    await repository.delete('a');

    expect(repository.getAll(), isEmpty);
  });
}
