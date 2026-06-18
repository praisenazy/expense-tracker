import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

part 'expense_category.g.dart';

/// The spending categories from the requirements.
///
/// Stored inside each Transaction, so it has its own Hive type id.
@HiveType(typeId: AppConstants.expenseCategoryId)
enum ExpenseCategory {
  @HiveField(0)
  food,

  @HiveField(1)
  transport,

  @HiveField(2)
  bills,

  @HiveField(3)
  entertainment,

  @HiveField(4)
  health,

  @HiveField(5)
  others;
}

/// Presentation info attached to each category via an extension.
///
/// An `extension` adds getters to an existing type. This lets the UI call
/// `category.label`, `category.icon`, `category.color` and stay consistent
/// everywhere (rows, picker, and the pie chart all match).
extension ExpenseCategoryX on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.bills:
        return 'Bills';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.health:
        return 'Health';
      case ExpenseCategory.others:
        return 'Others';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.transport:
        return Icons.directions_bus_rounded;
      case ExpenseCategory.bills:
        return Icons.receipt_long_rounded;
      case ExpenseCategory.entertainment:
        return Icons.movie_rounded;
      case ExpenseCategory.health:
        return Icons.favorite_rounded;
      case ExpenseCategory.others:
        return Icons.category_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return AppColors.food;
      case ExpenseCategory.transport:
        return AppColors.transport;
      case ExpenseCategory.bills:
        return AppColors.bills;
      case ExpenseCategory.entertainment:
        return AppColors.entertainment;
      case ExpenseCategory.health:
        return AppColors.health;
      case ExpenseCategory.others:
        return AppColors.others;
    }
  }
}
