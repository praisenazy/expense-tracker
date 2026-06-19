import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/category.dart';

/// A blueprint for a default category (no id yet).
class _CategorySpec {
  const _CategorySpec(this.name, this.icon, this.colorValue);
  final String name;
  final IconData icon;
  final int colorValue;
}

/// The original six categories, shared by income and expense transactions.
/// Users can add their own later (and edit/delete the ones they add).
const List<_CategorySpec> _defaultSpecs = [
  _CategorySpec('Food', Icons.restaurant_rounded, 0xFFFF7043),
  _CategorySpec('Transport', Icons.directions_bus_rounded, 0xFF42A5F5),
  _CategorySpec('Bills', Icons.receipt_long_rounded, 0xFFAB47BC),
  _CategorySpec('Entertainment', Icons.movie_rounded, 0xFFEC407A),
  _CategorySpec('Health', Icons.favorite_rounded, 0xFF26A69A),
  _CategorySpec('Others', Icons.category_rounded, 0xFF78909C),
];

/// Builds the default categories (with fresh ids) for first-launch seeding.
List<Category> buildDefaultCategories() {
  const uuid = Uuid();
  return [
    for (final s in _defaultSpecs)
      Category(
        id: uuid.v4(),
        name: s.name,
        iconCodePoint: s.icon.codePoint,
        colorValue: s.colorValue,
      ),
  ];
}

/// Names of the built-in defaults (which can't be deleted).
final Set<String> _defaultNames = {for (final s in _defaultSpecs) s.name};

/// True for the built-in default categories. A category the user added
/// themselves returns false.
bool isDefaultCategory(Category category) =>
    _defaultNames.contains(category.name);
