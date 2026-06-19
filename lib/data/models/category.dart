import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_icons.dart';

part 'category.g.dart';

/// A category — editable DATA stored in Hive (not a hardcoded enum), so users
/// can rename, restyle, add, and delete them. One shared set is used for both
/// income and expense transactions.
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
  });

  /// Stable unique id (uuid). Transactions reference this.
  @HiveField(0)
  final String id;

  /// Editable display name, e.g. "Food".
  @HiveField(1)
  final String name;

  /// The chosen icon's codePoint (rebuilt via AppIcons).
  @HiveField(2)
  final int iconCodePoint;

  /// The chosen color as an int (rebuilt via Color()).
  @HiveField(3)
  final int colorValue;

  /// The icon to display (kept valid by AppIcons' safelist).
  IconData get icon => AppIcons.fromCodePoint(iconCodePoint);

  /// The color to display.
  Color get color => Color(colorValue);

  Category copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    int? colorValue,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}
