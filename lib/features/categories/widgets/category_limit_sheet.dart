import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/default_categories.dart';
import '../../../data/models/category.dart';
import '../../../data/models/transaction_type.dart';
import '../../../providers/category_providers.dart';
import '../../../providers/transaction_providers.dart';

/// Shows the "you've hit the category limit" sheet.
///
/// Returns true if the user deleted one of their categories (freeing a slot),
/// so the caller can then continue to create a new one.
Future<bool?> showCategoryLimitSheet(
  BuildContext context,
  TransactionType kind,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CategoryLimitSheet(kind: kind),
  );
}

class _CategoryLimitSheet extends ConsumerWidget {
  const _CategoryLimitSheet({required this.kind});

  final TransactionType kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final noun = kind.isIncome ? 'sources' : 'categories';

    // Only the user's own categories can be deleted (not the built-in ones).
    final custom = ref
        .watch(categoriesByKindProvider(kind))
        .where((c) => !isDefaultCategory(c))
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.spaceL,
          0,
          AppConstants.spaceL,
          AppConstants.spaceL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category limit reached',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppConstants.spaceS),
            Text(
              'You can have up to ${AppConstants.maxCategoriesPerKind} $noun. '
              'Delete one you added to make room for a new one.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppConstants.spaceM),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: custom.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final category = custom[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor:
                          category.color.withValues(alpha: 0.15),
                      child: Icon(category.icon, color: category.color),
                    ),
                    title: Text(
                      category.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => _confirmAndDelete(context, ref, category),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final inUse = ref
        .read(transactionsProvider)
        .where((t) => t.categoryId == category.id)
        .length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          inUse > 0
              ? '"${category.name}" is used by $inUse '
                  'transaction${inUse == 1 ? '' : 's'}, which will become '
                  'uncategorized.'
              : '"${category.name}" will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(categoriesProvider.notifier).remove(category.id);

    // A slot is now free — close the sheet and tell the caller to continue.
    if (context.mounted) Navigator.of(context).pop(true);
  }
}
