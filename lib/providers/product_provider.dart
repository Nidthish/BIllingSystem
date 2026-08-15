import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/product.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  String _searchQuery = '';
  int? _selectedCategoryId;
  bool _isLoading = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;

  List<Product> get filteredProducts {
    final query = _searchQuery.trim().toLowerCase();
    return _products.where((p) {
      final matchesSearch = query.isEmpty ||
          p.productName.toLowerCase().contains(query) ||
          p.codeOrId.toLowerCase().contains(query) ||
          (p.barcode != null && p.barcode!.toLowerCase().contains(query)) ||
          (p.productId != null && p.productId.toString() == query) ||
          ('#${p.productId}').toLowerCase() == query;
      final matchesCategory = _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    _products = await DatabaseHelper.instance.getProducts();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    await DatabaseHelper.instance.insertProduct(product);
    await loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    await DatabaseHelper.instance.updateProduct(product);
    await loadProducts();
  }

  Future<void> deleteProduct(int productId) async {
    await DatabaseHelper.instance.deleteProduct(productId);
    await loadProducts();
  }

  Future<void> updateStock(int productId, int quantityChange) async {
    await DatabaseHelper.instance.updateStock(productId, quantityChange);
    await loadProducts();
  }
}
