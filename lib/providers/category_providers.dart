import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../core/constants/app_constants.dart';
import '../data/models/category.dart';
import '../data/repositories/category_repository.dart';

/// The already-open Hive box of categories.
final categoriesBoxProvider = Provider<Box<Category>>((ref) {
  return Hive.box<Category>(AppConstants.categoriesBox);
});

/// The category repository, built from the box.
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(categoriesBoxProvider));
});

/// The live list of all categories the UI watches.
final categoriesProvider =
    NotifierProvider<CategoriesNotifier, List<Category>>(CategoriesNotifier.new);

class CategoriesNotifier extends Notifier<List<Category>> {
  CategoryRepository get _repo => ref.read(categoryRepositoryProvider);

  @override
  List<Category> build() => _repo.getAll();

  Future<void> add(Category category) async {
    await _repo.add(category);
    state = _repo.getAll();
  }

  Future<void> update(Category category) async {
    await _repo.update(category);
    state = _repo.getAll();
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    state = _repo.getAll();
  }
}

/// id -> Category lookup, so a transaction row can resolve its category fast.
final categoryByIdProvider = Provider<Map<String, Category>>((ref) {
  final all = ref.watch(categoriesProvider);
  return {for (final c in all) c.id: c};
});
