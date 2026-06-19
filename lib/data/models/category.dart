import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_icons.dart';
import 'transaction_type.dart';

part 'category.g.dart';

/// A spending or income category — now editable DATA stored in Hive
/// (not a hardcoded enum), so users can rename, restyle, add, and delete them.
///
/// Icon and color are stored as their underlying numbers because Hive can't
/// store IconData/Color objects directly; the getters rebuild them.
@HiveType(typeId: AppConstants.categoryTypeId)
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.kind,
    required this.iconCodePoint,
    required this.colorValue,
  });

  /// Stable unique id (uuid). Transactions reference this.
  @HiveField(0)
  final String id;

  /// Editable display name, e.g. "Salary" or "Food".
  @HiveField(1)
  final String name;

  /// Whether this category is for income or expense.
  @HiveField(2)
  final TransactionType kind;

  /// The chosen icon's codePoint (rebuilt via AppIcons).
  @HiveField(3)
  final int iconCodePoint;

  /// The chosen color as an int (rebuilt via Color()).
  @HiveField(4)
  final int colorValue;

  /// The icon to display (kept valid by AppIcons' safelist).
  IconData get icon => AppIcons.fromCodePoint(iconCodePoint);

  /// The color to display.
  Color get color => Color(colorValue);

  Category copyWith({
    String? id,
    String? name,
    TransactionType? kind,
    int? iconCodePoint,
    int? colorValue,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}
