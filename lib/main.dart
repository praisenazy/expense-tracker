import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'data/models/category.dart';
import 'data/models/transaction.dart';
import 'data/repositories/category_repository.dart';
import 'hive_registrar.g.dart'; // generated: gives Hive.registerAdapters()

Future<void> main() async {
  // Required before any async work that runs before runApp().
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Prepare Hive's on-device storage.
  await Hive.initFlutter();

  // 2) Teach Hive about our custom types (Transaction, Category, the enum).
  //    This single call comes from the generated hive_registrar.g.dart.
  Hive.registerAdapters();

  // 3) Open the boxes BEFORE the UI starts, so data is ready immediately
  //    and survives restarts (this is the "local storage" requirement).
  final categoriesBox =
      await _openBoxSafely<Category>(AppConstants.categoriesBox);
  await _openBoxSafely<Transaction>(AppConstants.transactionsBox);
  final settingsBox = await Hive.openBox(AppConstants.settingsBox);

  // 4) First launch: fill in the default categories.
  final categoryRepository = CategoryRepository(categoriesBox);
  await categoryRepository.seedDefaultsIfEmpty();

  // 4b) One-time removal of the leftover "Others" category from older installs
  //     (it's no longer a default). Runs once, then never again.
  if (settingsBox.get(AppConstants.othersRemovedKey) != true) {
    await categoryRepository.removeCategoriesNamed('Others');
    await settingsBox.put(AppConstants.othersRemovedKey, true);
  }

  // 5) ProviderScope is the root that powers Riverpod for the whole app.
  runApp(const ProviderScope(child: ExpenseTrackerApp()));
}

/// Opens a typed box, recovering gracefully if existing data can't be read
/// (e.g. after a model/schema change during development): the box is wiped and
/// reopened empty instead of crashing the app at startup.
Future<Box<T>> _openBoxSafely<T>(String name) async {
  try {
    return await Hive.openBox<T>(name);
  } catch (_) {
    await Hive.deleteBoxFromDisk(name);
    return Hive.openBox<T>(name);
  }
}
