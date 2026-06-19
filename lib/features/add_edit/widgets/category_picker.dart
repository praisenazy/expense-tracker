import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/category.dart';

/// Lets the user pick a category, with an "Edit" chip at the end that opens
/// the Manage Categories page.
///
/// "Controlled" widget: it doesn't own the selection. The parent form holds the
/// selected id and passes it in; this widget renders chips and reports taps.
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    required this.onEditPressed,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback onEditPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: AppConstants.spaceS,
      runSpacing: AppConstants.spaceS,
      children: [
        // One chip per category.
        ...categories.map((category) {
          final isSelected = category.id == selectedId;
          return ChoiceChip(
            selected: isSelected,
            onSelected: (_) => onSelected(category.id),
            avatar: Icon(
              category.icon,
              size: 18,
              color: isSelected ? Colors.white : category.color,
            ),
            label: Text(category.name),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            selectedColor: category.color,
            backgroundColor: category.color.withValues(alpha: 0.12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );
        }),

        // Trailing "Edit" chip -> opens Manage Categories.
        ActionChip(
          onPressed: onEditPressed,
          avatar: Icon(Icons.edit_rounded, size: 18, color: scheme.primary),
          label: const Text('Edit'),
          labelStyle: TextStyle(
            color: scheme.primary,
            fontWeight: FontWeight.w700,
          ),
          backgroundColor: scheme.primary.withValues(alpha: 0.10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: scheme.primary.withValues(alpha: 0.4)),
          ),
        ),
      ],
    );
  }
}
