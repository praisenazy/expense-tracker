import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/transaction.dart';
import '../../../providers/category_providers.dart';

/// A single transaction row: category icon, title, date, and signed amount.
///
/// Now a ConsumerWidget so it can resolve the transaction's category (by id)
/// from the categories provider, with a graceful fallback if it was deleted.
class TransactionTile extends ConsumerWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  final Transaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isIncome = transaction.type.isIncome;
    final amountColor = isIncome ? AppColors.income : AppColors.expense;
    final sign = isIncome ? '+' : '-';

    // Resolve the category; fall back if it no longer exists.
    final category = ref.watch(categoryByIdProvider)[transaction.categoryId];
    final categoryName = category?.name ?? 'Uncategorized';
    final categoryIcon = category?.icon ?? AppIcons.fallback;
    final categoryColor = category?.color ?? AppColors.others;

    // The note is the row's description; when empty, show the category name.
    final note = transaction.note?.trim();
    final hasNote = note != null && note.isNotEmpty;
    final primaryText = hasNote ? note : categoryName;
    final secondaryText = hasNote
        ? '$categoryName • ${Formatters.date(transaction.date)}'
        : Formatters.date(transaction.date);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: categoryColor.withValues(alpha: 0.15),
        child: Icon(categoryIcon, color: categoryColor),
      ),
      title: Text(
        primaryText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        secondaryText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '$sign${Formatters.money(transaction.amount)}',
        style: theme.textTheme.titleSmall?.copyWith(
          color: amountColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
