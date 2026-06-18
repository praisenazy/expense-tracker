import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/expense_category.dart';

/// Lets the user pick one of the six categories.
///
/// "Controlled" widget: it does NOT own the selection. The parent form holds
/// the selected value and passes it in; this widget just renders the chips and
/// reports taps via [onSelected].
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ExpenseCategory selected;
  final ValueChanged<ExpenseCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppConstants.spaceS,
      runSpacing: AppConstants.spaceS,
      // Build a chip for every category automatically.
      children: ExpenseCategory.values.map((category) {
        final isSelected = category == selected;
        return ChoiceChip(
          selected: isSelected,
          onSelected: (_) => onSelected(category),
          avatar: Icon(
            category.icon,
            size: 18,
            color: isSelected ? Colors.white : category.color,
          ),
          label: Text(category.label),
          labelStyle: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          selectedColor: category.color,
          backgroundColor: category.color.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }).toList(),
    );
  }
}
