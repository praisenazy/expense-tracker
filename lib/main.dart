import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'data/models/transaction.dart';
import 'hive_registrar.g.dart'; // generated: gives Hive.registerAdapters()

Future<void> main() async {
  // Required before any async work that runs before runApp().
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Prepare Hive's on-device storage.
  await Hive.initFlutter();

  // 2) Teach Hive about our custom types (Transaction, the two enums).
  //    This single call comes from the generated hive_registrar.g.dart.
  Hive.registerAdapters();

  // 3) Open the boxes BEFORE the UI starts, so data is ready immediately
  //    and survives restarts (this is the "local storage" requirement).
  await Hive.openBox<Transaction>(AppConstants.transactionsBox);
  await Hive.openBox(AppConstants.settingsBox);

  // 4) ProviderScope is the root that powers Riverpod for the whole app.
  runApp(const ProviderScope(child: ExpenseTrackerApp()));
}
