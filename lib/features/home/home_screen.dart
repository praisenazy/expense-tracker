import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction.dart';
import '../../providers/category_providers.dart';
import '../../providers/summary_providers.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_providers.dart';
import '../add_edit/add_edit_transaction_screen.dart';
import '../shared/empty_state.dart';
import 'widgets/transaction_tile.dart';

/// The home dashboard: a full-bleed colored header (balance + income/expense
/// card) and a full-width white sheet listing recent transactions. The
/// income/expense card straddles the boundary, attached to the sheet.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // Fixed brand color for the header so it stays readable in light & dark.
  static const Color _header = AppColors.seed;
  static const Color _darkCard = Color(0xFF2A2D3A);
  static const Color _green = Color(0xFF2BD17E);
  static const Color _red = Color(0xFFFF6B6B);

  // The full-width income/expense card extends well below the sheet's top so
  // it sits behind the sheet's rounded corner notches (covering the header
  // color that would otherwise peek through). [_sheetTop] is where the white
  // sheet begins — i.e. how much of the card stays visible above it.
  static const double _cardHeight = 124;
  static const double _sheetTop = 80;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final summary = ref.watch(monthlySummaryProvider);
    final month = ref.watch(selectedMonthProvider);
    final monthCtrl = ref.read(selectedMonthProvider.notifier);
    final transactions = summary.transactions; // selected month, newest first

    // Split "June 2026" so the month can be bold and the year medium.
    final monthParts = Formatters.monthYear(month).split(' ');
    final monthName = monthParts.first;
    final yearLabel = monthParts.skip(1).join(' ');

    final total = summary.totalIncome + summary.totalExpense;
    final incomeRatio = total == 0 ? 0.0 : summary.totalIncome / total;

    // Remaining balance for the month — never shown as negative.
    final remainingBalance =
        summary.balance < 0 ? 0.0 : summary.balance;

    return Scaffold(
      backgroundColor: _header,
      body: Column(
        children: [
          // ===== Colored header (down to the balance) =====
          SafeArea(
            bottom: false,
            child: Padding(
              // Vertical only — horizontal padding is applied per child so the
              // balance row can run full-bleed and the arrows hug the edges.
              padding: const EdgeInsets.only(
                top: AppConstants.spaceS,
                bottom: 50, // extra space below the balance before the card
              ),
              child: Column(
                children: [
                  // App bar: title + theme toggle.
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spaceM,
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Expense Tracker',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: isDark ? 'Light mode' : 'Dark mode',
                          icon: Icon(
                            isDark
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => ref
                              .read(themeModeProvider.notifier)
                              .toggleDark(!isDark),
                        ),
                      ],
                    ),
                  ),

                  // Month / year label — year aligned to the TOP, not baseline.
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$monthName ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          yearLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Balance with the month-switch arrows centered on it.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MonthArrow(
                        pointLeft: true,
                        onTap: monthCtrl.previousMonth,
                      ),
                      Text(
                        Formatters.money(remainingBalance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      _MonthArrow(pointLeft: false, onTap: monthCtrl.nextMonth),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ===== Full-width card (behind) + white sheet on top of its bottom =====
          Expanded(
            child: Stack(
              children: [
                // Full-width income/expense card, drawn behind the sheet.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    height: _cardHeight,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(
                        AppConstants.spaceM,
                        AppConstants.spaceM,
                        AppConstants.spaceM,
                        AppConstants.spaceL,
                      ),
                      decoration: const BoxDecoration(
                        color: _darkCard,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _InlineStat(
                                label: 'Income',
                                amount: summary.totalIncome,
                                color: _green,
                              ),
                              _InlineStat(
                                label: 'Expenses',
                                amount: summary.totalExpense,
                                color: _red,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.spaceM),
                          _ProgressBar(
                            fraction: incomeRatio,
                            color: _green, // income portion
                            trackColor: _red, // expense portion
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // White sheet ON TOP, covering the card's bottom edge.
                Positioned(
                  top: _sheetTop,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? theme.colorScheme.surface : Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppConstants.spaceM,
                            AppConstants.spaceM,
                            AppConstants.spaceM,
                            AppConstants.spaceS,
                          ),
                          child: Text(
                            'Recent Transactions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A thin, custom-drawn chevron (‹ or ›) used to switch months.
class _MonthArrow extends StatelessWidget {
  const _MonthArrow({required this.pointLeft, required this.onTap});

  final bool pointLeft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 50),
        child: CustomPaint(
          size: const Size(9, 20),
          painter: _ChevronPainter(
            pointLeft: pointLeft,
            color: Colors.white54,
            strokeWidth: 2.4, // thin stroke
          ),
        ),
      ),
    );
  }
}

/// Draws a thin chevron with a controllable [strokeWidth].
class _ChevronPainter extends CustomPainter {
  _ChevronPainter({
    required this.pointLeft,
    required this.color,
    required this.strokeWidth,
  });

  final bool pointLeft;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    if (pointLeft) {
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height / 2);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(0, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ChevronPainter old) =>
      old.pointLeft != pointLeft ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}

/// "Income: ₦8,500.00" style inline figure on the dark card.
class _InlineStat extends StatelessWidget {
  const _InlineStat({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: color, // label matches its amount color
            fontSize: 14,
          ),
        ),
        Text(
          Formatters.money(amount),
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Rounded progress bar: [fraction] (0..1) filled with [color] (income) over a
/// [trackColor] track (expense).
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.fraction,
    required this.color,
    required this.trackColor,
  });

  final double fraction;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Container(height: 8, color: trackColor),
          FractionallySizedBox(
            widthFactor: fraction.clamp(0.0, 1.0),
            child: Container(height: 8, color: color),
          ),
        ],
      ),
    );
  }
}

/// Flat list of transactions with swipe-to-delete + tap-to-edit.
class _TransactionList extends ConsumerWidget {
  const _TransactionList({required this.transactions});

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 110), // clear the floating nav bar
      itemCount: transactions.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return Dismissible(
          key: ValueKey(transaction.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            color: Colors.red.withValues(alpha: 0.12),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spaceL,
            ),
            child: const Icon(Icons.delete_rounded, color: Colors.red),
          ),
          onDismissed: (_) => _deleteWithUndo(context, ref, transaction),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spaceM,
            ),
            child: TransactionTile(
              transaction: transaction,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AddEditTransactionScreen(existing: transaction),
                ),
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
    final note = transaction.note?.trim();
    final label = (note != null && note.isNotEmpty)
        ? note
        : ref.read(categoryByIdProvider)[transaction.categoryId]?.name ??
              'transaction';

    ref.read(transactionsProvider.notifier).remove(transaction.id);

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Text('Deleted "$label"'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () =>
              ref.read(transactionsProvider.notifier).add(transaction),
        ),
      ),
    );

    // Some devices/emulators with system animations disabled don't fire the
    // SnackBar's built-in auto-dismiss timer, so force-close it after 3s.
    var closed = false;
    controller.closed.then((_) => closed = true);
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (!closed) controller.close();
    });
  }
}
