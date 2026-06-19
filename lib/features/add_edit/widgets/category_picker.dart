import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/category.dart';

/// Lets the user pick a category. Each chip is filled with its category color
/// and white text; the selected one gets a white ring + check + stronger glow.
/// An "Edit" chip at the end opens the create-your-own-category screen.
///
/// "Controlled" widget: the parent owns the selection and passes it in.
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
        // One filled chip per category.
        ...categories.map((category) {
          final isSelected = category.id == selectedId;
          return GestureDetector(
            onTap: () => onSelected(category.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spaceM,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: category.color,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: category.color
                        .withValues(alpha: isSelected ? 0.5 : 0.25),
                    blurRadius: isSelected ? 12 : 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? Icons.check_rounded : category.icon,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        // Trailing "Edit" chip -> opens the new-category editor.
        GestureDetector(
          onTap: onEditPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spaceM,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Edit',
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
