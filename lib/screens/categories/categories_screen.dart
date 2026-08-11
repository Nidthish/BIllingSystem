import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/category.dart';
import '../../models/product.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  int? _selectedCategoryId; // null = All Categories
  String _searchQuery = '';

  void _showCategoryDialog(BuildContext context, {Category? category}) {
    final nameController = TextEditingController(text: category?.categoryName ?? '');
    final descController = TextEditingController(text: category?.description ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(category == null ? 'Add Category' : 'Edit Category'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Category Name *'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Category Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (dialogContext.mounted && Navigator.canPop(dialogContext)) Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newCat = Category(
                  categoryId: category?.categoryId,
                  categoryName: nameController.text.trim(),
                  description: descController.text.trim(),
                );

                try {
                  final provider = context.read<CategoryProvider>();
                  if (category == null) {
                    await provider.addCategory(newCat);
                  } else {
                    await provider.updateCategory(newCat);
                  }
                  if (dialogContext.mounted && Navigator.canPop(dialogContext)) Navigator.pop(dialogContext);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: Text(category == null ? 'Add Category' : 'Save Changes'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete category "${category.categoryName}"?'),
        actions: [
          TextButton(
            onPressed: () {
              if (dialogContext.mounted && Navigator.canPop(dialogContext)) Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await context.read<CategoryProvider>().deleteCategory(category.categoryId!);
                if (_selectedCategoryId == category.categoryId) {
                  setState(() {
                    _selectedCategoryId = null;
                  });
                }
                if (dialogContext.mounted && Navigator.canPop(dialogContext)) Navigator.pop(dialogContext);
              } catch (e) {
                if (dialogContext.mounted && Navigator.canPop(dialogContext)) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoryProvider>();
    final prodProvider = context.watch<ProductProvider>();

    if (catProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final categories = catProvider.categories;
    final allProducts = prodProvider.products;

    // Filter products based on selected category & search query
    List<Product> filteredProducts = allProducts;
    if (_selectedCategoryId != null) {
      filteredProducts = filteredProducts.where((p) => p.categoryId == _selectedCategoryId).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filteredProducts = filteredProducts.where((p) {
        final nameMatch = p.productName.toLowerCase().contains(q);
        final codeMatch = p.codeOrId.toLowerCase().contains(q);
        final barcodeMatch = (p.barcode ?? '').toLowerCase().contains(q);
        return nameMatch || codeMatch || barcodeMatch;
      }).toList();
    }

    // Selected category object
    final selectedCatObj = _selectedCategoryId == null
        ? null
        : categories.firstWhere(
            (c) => c.categoryId == _selectedCategoryId,
            orElse: () => Category(categoryName: 'Unknown', description: ''),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories & Products'),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00875A),
              foregroundColor: Colors.white,
            ),
            onPressed: () => _showCategoryDialog(context),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── CATEGORY FILTER BUTTONS (COMPACT SMALL HEIGHT 3x3 GRID LAYOUT) ──
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 6.0,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 1 + categories.length,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = _selectedCategoryId == null;
                  return Material(
                    color: isSelected ? const Color(0xFF00875A) : const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(8),
                    elevation: isSelected ? 1 : 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = null;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.grid_view_rounded,
                              size: 16,
                              color: isSelected ? Colors.white : const Color(0xFF00875A),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'All Categories (${allProducts.length})',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: isSelected ? Colors.white : const Color(0xFF00875A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final cat = categories[index - 1];
                final isSelected = _selectedCategoryId == cat.categoryId;
                final catProductCount = allProducts.where((p) => p.categoryId == cat.categoryId).length;

                return Material(
                  color: isSelected ? const Color(0xFF00875A) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  elevation: isSelected ? 1 : 0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() {
                        _selectedCategoryId = isSelected ? null : cat.categoryId;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: isSelected ? Colors.white : const Color(0xFF00875A),
                            child: Text(
                              '$index',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFF00875A) : Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    cat.categoryName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                      color: isSelected ? Colors.white : Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '($catProductCount)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected ? Colors.white70 : Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // ── ACTIVE CATEGORY HEADER BANNER & SEARCH BAR ────────────
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: const Color(0xFFF4F9F5),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _selectedCategoryId == null
                                    ? 'All Categories'
                                    : '${selectedCatObj?.categoryName}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF004D25),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00875A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${filteredProducts.length} Products',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          if (_selectedCategoryId != null && selectedCatObj?.description != null && selectedCatObj!.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                selectedCatObj.description!,
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (selectedCatObj != null && selectedCatObj.categoryId != null) ...[
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Edit Category',
                        onPressed: () => _showCategoryDialog(context, category: selectedCatObj),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete Category',
                        onPressed: () => _confirmDelete(context, selectedCatObj),
                      ),
                      const SizedBox(width: 8),
                    ],
                    SizedBox(
                      width: 250,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search products in category...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── PRODUCTS GRID DISPLAY ──────────────────────────────────
            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No products match "$_searchQuery"'
                                : 'No products found in this category.',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 280,
                        childAspectRatio: 1.7,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        final catName = categories.firstWhere(
                          (c) => c.categoryId == product.categoryId,
                          orElse: () => Category(categoryName: 'General'),
                        ).categoryName;

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE6F4EA),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        product.codeOrId,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF00875A),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      catName,
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.productName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '₹${product.sellingPrice.toStringAsFixed(2)} / ${product.unit ?? "g"}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF00875A),
                                      ),
                                    ),
                                    Text(
                                      'Stock: ${product.stock}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: product.stock <= product.minimumStock ? Colors.red : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
