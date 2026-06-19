import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/transaction.dart';
import '../../providers/category_providers.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_providers.dart';
import '../add_edit/add_edit_transaction_screen.dart';
import '../shared/empty_state.dart';
import '../summary/summary_screen.dart';
import 'widgets/balance_card.dart';
import 'widgets/transaction_tile.dart';

/// The main dashboard: balance card + transaction list.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);

    // All-time totals for the balance card.
    double income = 0;
    double expense = 0;
    for (final t in transactions) {
      if (t.type.isIncome) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          // Dark-mode toggle: switch to the opposite of the current brightness.
          IconButton(
            tooltip: isDark ? 'Light mode' : 'Dark mode',
            icon: Icon(isDark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded),
            onPressed: () =>
                ref.read(themeModeProvider.notifier).toggleDark(!isDark),
          ),
          // Open the monthly summary / charts.
          IconButton(
            tooltip: 'Summary',
            icon: const Icon(Icons.pie_chart_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SummaryScreen()),
            ),
          ),
          const SizedBox(width: AppConstants.spaceS),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppConstants.spaceS),
              BalanceCard(
                income: income,
                expense: expense,
                balance: income - expense,
              ),
              const SizedBox(height: AppConstants.spaceL),
              Text(
                'Recent Transactions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppConstants.spaceS),
              Expanded(
                child: transactions.isEmpty
                    ? const EmptyState(
                        icon: Icons.receipt_long_rounded,
                        title: 'No transactions yet',
                        message:
                            'Tap the + button to add your first income or expense.',
                      )
                    : _TransactionList(transactions: transactions),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openForm(BuildContext context, {Transaction? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditTransactionScreen(existing: existing),
      ),
    );
  }
}

/// The scrollable list of transactions with swipe-to-delete + tap-to-edit.
class _TransactionList extends ConsumerWidget {
  const _TransactionList({required this.transactions});

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96), // clear the FAB
      itemCount: transactions.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return Dismissible(
          key: ValueKey(transaction.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceL),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_rounded, color: Colors.red),
          ),
          onDismissed: (_) => _deleteWithUndo(context, ref, transaction),
          child: TransactionTile(
            transaction: transaction,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    AddEditTransactionScreen(existing: transaction),
              ),
            ),
          ),
        );
      },
    );
  }

  void _deleteWithUndo(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
  ) {
    // Label the deleted item by its note, falling back to the category name.
    final note = transaction.note?.trim();
    final label = (note != null && note.isNotEmpty)
        ? note
        : ref.read(categoryByIdProvider)[transaction.categoryId]?.name ??
            'transaction';

    ref.read(transactionsProvider.notifier).remove(transaction.id);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Deleted "$label"'),
          action: SnackBarAction(
            label: 'UNDO',
            // Re-add the exact same transaction (same id) to restore it.
            onPressed: () =>
                ref.read(transactionsProvider.notifier).add(transaction),
          ),
        ),
      );
  }
}
