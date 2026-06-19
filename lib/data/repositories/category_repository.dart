import 'package:hive_ce/hive.dart';

import '../../core/constants/default_categories.dart';
import '../models/category.dart';

/// The single place that talks to Hive for categories.
///
/// Categories are keyed by their id, so update/delete are exact operations.
class CategoryRepository {
  CategoryRepository(this._box);

  final Box<Category> _box;

  /// All categories (insertion order preserved).
  List<Category> getAll() => _box.values.toList();

  Future<void> add(Category category) => _box.put(category.id, category);

  Future<void> update(Category category) => _box.put(category.id, category);

  Future<void> delete(String id) => _box.delete(id);

  /// On first launch the box is empty — fill it with the default categories
  /// so the app is usable immediately.
  Future<void> seedDefaultsIfEmpty() async {
    if (_box.isNotEmpty) return;
    for (final category in buildDefaultCategories()) {
      await _box.put(category.id, category);
    }
  }

  /// One-time cleanup for installs that were seeded before the generic
  /// "Other"/"Others" categories were removed. Deletes those leftovers so they
  /// no longer appear as chips.
  Future<void> removeLegacyOtherCategories() async {
    final ids = _box.values
        .where((c) => c.name == 'Other' || c.name == 'Others')
        .map((c) => c.id)
        .toList();
    for (final id in ids) {
      await _box.delete(id);
    }
  }
}
