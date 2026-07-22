import 'package:hive_ce/hive.dart';

import '../../core/constants/default_categories.dart';
import '../../core/theme/app_icons.dart';
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

  /// Repairs categories saved BEFORE the emoji migration, whose stored code
  /// point is a Material/Cupertino icon glyph living in a Unicode Private Use
  /// Area. In a normal [Text] widget those render as an empty "tofu" box, so we
  /// re-derive a real emoji from the category name. Returns how many were fixed.
  Future<int> repairIconGlyphs() async {
    var fixed = 0;
    for (final category in _box.values.toList()) {
      if (!_isPrivateUse(category.iconCodePoint)) continue;
      final emoji = AppIcons.suggest(category.name).first;
      await _box.put(
        category.id,
        category.copyWith(iconCodePoint: AppIcons.codePointOf(emoji)),
      );
      fixed++;
    }
    return fixed;
  }

  /// True for code points in a Unicode Private Use Area — where icon fonts
  /// (Material, Cupertino) place their glyphs, and where no emoji ever lives.
  static bool _isPrivateUse(int cp) =>
      (cp >= 0xE000 && cp <= 0xF8FF) || // BMP PUA
      (cp >= 0xF0000 && cp <= 0xFFFFD) || // Supplementary PUA-A
      (cp >= 0x100000 && cp <= 0x10FFFD); // Supplementary PUA-B

  /// Deletes any stored categories whose name matches [name] (case-insensitive).
  /// Used to clear a leftover category from older installs.
  Future<void> removeCategoriesNamed(String name) async {
    final target = name.trim().toLowerCase();
    final ids = _box.values
        .where((c) => c.name.trim().toLowerCase() == target)
        .map((c) => c.id)
        .toList();
    for (final id in ids) {
      await _box.delete(id);
    }
  }
}
