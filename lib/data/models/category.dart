import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_icons.dart';
import 'transaction_type.dart';

part 'category.g.dart';

/// A category — editable DATA stored in Hive (not a hardcoded enum), so users
/// can rename, restyle, add, and delete them. Each category belongs to either
/// income or expense (its [kind]), so the two sides show different chips.
///
/// Icon and color are stored as their underlying numbers because Hive can't
/// store IconData/Color objects directly; the getters rebuild them.
@HiveType(typeId: AppConstants.categoryTypeId)
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    required this.kind,
  });

  /// Stable unique id (uuid). Transactions reference this.
  @HiveField(0)
  final String id;

  /// Editable display name, e.g. "Food" or "Salary".
  @HiveField(1)
  final String name;

  /// The chosen icon's codePoint (rebuilt via AppIcons).
  @HiveField(2)
  final int iconCodePoint;

  /// The chosen color as an int (rebuilt via Color()).
  @HiveField(3)
  final int colorValue;

  /// Whether this category is for income or expense.
  @HiveField(4)
  final TransactionType kind;

  /// The icon to display (kept valid by AppIcons' safelist).
  IconData get icon => AppIcons.fromCodePoint(iconCodePoint);

  /// The color to display.
  Color get color => Color(colorValue);

  Category copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    int? colorValue,
    TransactionType? kind,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      kind: kind ?? this.kind,
    );
  }
}
