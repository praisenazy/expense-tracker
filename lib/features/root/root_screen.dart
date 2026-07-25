import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/transaction.dart';
import '../add_edit/add_edit_transaction_screen.dart';
import '../home/home_screen.dart';
import '../summary/summary_screen.dart';
import 'widgets/liquid_glass_nav_bar.dart';

/// App shell: hosts the Home and Summary tabs with a floating "liquid glass"
/// pill nav bar (Home / + / Summary).
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  Future<void> _openAddTransaction() async {
    final saved = await Navigator.of(context).push<Transaction>(
      MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()),
    );
    if (saved == null || !mounted) return;
    _showSavedConfirmation(saved);
  }

  /// A brief, friendly confirmation after a transaction is added.
  void _showSavedConfirmation(Transaction t) {
    final theme = Theme.of(context);
    final isIncome = t.type.isIncome;
    final green = const Color(0xFF2BD17E);
    final sign = isIncome ? '+' : '-';
    final label = isIncome ? 'Income' : 'Expense';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: theme.colorScheme.inverseSurface,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 86),
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: green, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$label added  •  $sign${Formatters.money(t.amount)}',
                  style: TextStyle(
                    color: theme.colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      // Let the page show behind the floating bar so the glass can blur it.
      extendBody: true,
      // Keep both tabs alive so their state is preserved when switching.
      body: IndexedStack(
        index: _index,
        children: const [HomeScreen(), SummaryScreen()],
      ),
      bottomNavigationBar: LiquidGlassNavBar(
        currentIndex: _index,
        primary: primary,
        onTabSelected: (i) => setState(() => _index = i),
        onAddPressed: _openAddTransaction,
      ),
    );
  }
}
