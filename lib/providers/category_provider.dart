import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/category.dart';

class CategoryProvider with ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();
    _categories = await DatabaseHelper.instance.getCategories();
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
