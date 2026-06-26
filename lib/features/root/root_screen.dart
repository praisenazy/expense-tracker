import 'package:flutter/material.dart';

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

  void _openAddTransaction() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()),
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
