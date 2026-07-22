import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../../core/constants/app_constants.dart';
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
    this.reusable = true,
  });

  /// Stable unique id (uuid). Transactions reference this.
  @HiveField(0)
  final String id;

  /// Editable display name, e.g. "Food" or "Salary".
  @HiveField(1)
  final String name;

  /// The chosen emoji's Unicode code point (rebuilt via [emoji]).
  @HiveField(2)
  final int iconCodePoint;

  /// The chosen color as an int (rebuilt via Color()).
  @HiveField(3)
  final int colorValue;

  /// Whether this category is for income or expense.
  @HiveField(4)
  final TransactionType kind;

  /// Whether this category is saved to the reusable category list (shown as a
  /// chip). A "use once" category (created for a single transaction) is stored
  /// with `false` so the transaction still resolves it, but it stays out of the
  /// picker/section. Defaults to true (including all built-in categories).
  @HiveField(5)
  final bool reusable;

  /// The emoji to display, rebuilt from the stored code point.
  String get emoji => String.fromCharCode(iconCodePoint);

  /// The color to display.
  Color get color => Color(colorValue);

  Category copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    int? colorValue,
    TransactionType? kind,
    bool? reusable,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      kind: kind ?? this.kind,
      reusable: reusable ?? this.reusable,
    );
  }
}
