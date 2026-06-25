import 'package:flutter/material.dart';

import '../add_edit/add_edit_transaction_screen.dart';
import '../home/home_screen.dart';
import '../summary/summary_screen.dart';

/// App shell: hosts the Home and Summary tabs plus a bottom navigation bar
/// with a floating "+" button in the middle that opens Add Transaction.
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
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final barColor =
        theme.brightness == Brightness.dark ? theme.colorScheme.surface : Colors.white;
    final inactive = theme.colorScheme.onSurface.withValues(alpha: 0.45);

    return Scaffold(
      // Keep both tabs alive so their state is preserved when switching.
      body: IndexedStack(
        index: _index,
        children: const [HomeScreen(), SummaryScreen()],
      ),

      // Middle floating "+" that rises above the bar.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 60,
        height: 60,
        child: FloatingActionButton(
          onPressed: _openAddTransaction,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 30),
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: barColor,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    activeIcon: Icons.home_rounded,
                    inactiveIcon: Icons.home_outlined,
                    label: 'Home',
                    active: _index == 0,
                    activeColor: primary,
                    inactiveColor: inactive,
                    onTap: () => setState(() => _index = 0),
                  ),
                ),
                // Space reserved for the floating + button.
                const SizedBox(width: 72),
                Expanded(
                  child: _NavItem(
                    activeIcon: Icons.pie_chart_rounded,
                    inactiveIcon: Icons.pie_chart_outline_rounded,
                    label: 'Summary',
                    active: _index == 1,
                    activeColor: primary,
                    inactiveColor: inactive,
                    onTap: () => setState(() => _index = 1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single bottom-nav destination (icon + label), colored when active.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : inactiveColor;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(active ? activeIcon : inactiveIcon, color: color, size: 26),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
