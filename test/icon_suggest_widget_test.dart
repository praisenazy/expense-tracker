import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_project/data/models/transaction_type.dart';
import 'package:my_project/features/categories/category_editor_screen.dart';

void main() {
  testWidgets('typing a category name updates the suggested icon row',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CategoryEditorScreen(kind: TransactionType.expense),
        ),
      ),
    );

    // Before typing: an expense default (burger) is suggested.
    expect(find.text('🍔'), findsWidgets);

    await tester.enterText(find.byType(TextFormField), 'chocolate');
    await tester.pumpAndSettle();

    // After typing "chocolate", the chocolate emoji should be suggested.
    expect(find.text('🍫'), findsWidgets);
  });
}
