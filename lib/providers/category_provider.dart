import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/category.dart';

class CategoryProvider with ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  static const List<String> _desiredCategoryOrder = [
    'masala varieties',
    'masala ingredients',
    'flour varieties',
    'aroma masala ingredients',
    'dal varieties',
    'cashew varieties',
    'dry fruits',
  ];

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();
    final list = await DatabaseHelper.instance.getCategories();
    list.sort((a, b) {
      final nameA = a.categoryName.trim().toLowerCase();
      final nameB = b.categoryName.trim().toLowerCase();
      final idxA = _desiredCategoryOrder.indexOf(nameA);
      final idxB = _desiredCategoryOrder.indexOf(nameB);
      if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
      if (idxA != -1) return -1;
      if (idxB != -1) return 1;
      return (a.categoryId ?? 0).compareTo(b.categoryId ?? 0);
    });
    _categories = list;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addCategory(Category category) async {
    // Check duplicate
    if (_categories.any((c) => c.categoryName.toLowerCase() == category.categoryName.toLowerCase())) {
      throw Exception('Category "${category.categoryName}" already exists.');
    }
    await DatabaseHelper.instance.insertCategory(category);
    await loadCategories();
    return true;
  }

  Future<bool> updateCategory(Category category) async {
    if (_categories.any((c) => c.categoryId != category.categoryId && c.categoryName.toLowerCase() == category.categoryName.toLowerCase())) {
      throw Exception('Category "${category.categoryName}" already exists.');
    }
    await DatabaseHelper.instance.updateCategory(category);
    await loadCategories();
    return true;
  }

  Future<void> deleteCategory(int categoryId) async {
    await DatabaseHelper.instance.deleteCategory(categoryId);
    await loadCategories();
  }
}
