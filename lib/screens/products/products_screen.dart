import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../models/settings.dart';
import '../../utils/reports_pdf_generator.dart';
import '../../widgets/print_options_dialog.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final initialQuery = context.read<ProductProvider>().searchQuery;
    _searchController = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showProductDialog(BuildContext parentContext, {Product? product}) {
    final nameController = TextEditingController(text: product?.productName ?? '');
    final barcodeController = TextEditingController(text: product?.barcode ?? '');
    final purchasePriceController = TextEditingController(text: product != null ? product.purchasePrice.toString() : '');
    final sellingPriceController = TextEditingController(text: product != null ? product.sellingPrice.toString() : '');
    final stockController = TextEditingController(text: product != null ? product.stock.toString() : '');
    final minStockController = TextEditingController(text: product != null ? product.minimumStock.toString() : '');
    final unitController = TextEditingController(text: product != null ? (product.unit ?? '') : '');
    
    int? selectedCategory = product?.categoryId;
    String? successMessage;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final categories = context.watch<CategoryProvider>().categories;
            return AlertDialog(
              title: Text(product == null ? 'Add Product' : 'Edit Product'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: SizedBox(
                    width: 500,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (successMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF00875A)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Color(0xFF00875A), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    successMessage!,
                                    style: const TextStyle(color: Color(0xFF00875A), fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: nameController,
                                decoration: const InputDecoration(labelText: 'Product Name *'),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Product Name is required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: barcodeController,
                                decoration: const InputDecoration(labelText: 'Product Code / ID'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category *',
                            hintText: 'Select Category',
                          ),
                          items: categories.map((c) => DropdownMenuItem(
                            value: c.categoryId,
                            child: Text(c.categoryName),
                          )).toList(),
                          onChanged: (val) => setState(() => selectedCategory = val),
                          validator: (v) => v == null ? 'Category is required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: unitController,
                          decoration: const InputDecoration(labelText: 'Unit (e.g. pcs, kg, L)'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: purchasePriceController,
                                decoration: const InputDecoration(labelText: 'Purchase Price (₹)'),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return null;
                                  final numVal = double.tryParse(v.trim());
                                  if (numVal == null || numVal < 0) return 'Invalid Price';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: sellingPriceController,
                                decoration: const InputDecoration(labelText: 'Selling Price (₹)'),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return null;
                                  final numVal = double.tryParse(v.trim());
                                  if (numVal == null || numVal < 0) return 'Invalid Price';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: stockController,
                                decoration: const InputDecoration(labelText: 'Current Stock'),
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return null;
                                  final numVal = int.tryParse(v.trim());
                                  if (numVal == null || numVal < 0) return 'Invalid Stock';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: minStockController,
                                decoration: const InputDecoration(labelText: 'Minimum Stock'),
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return null;
                                  final numVal = int.tryParse(v.trim());
                                  if (numVal == null || numVal < 0) return 'Invalid Min Stock';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (dialogContext.mounted && Navigator.canPop(dialogContext)) Navigator.pop(dialogContext);
                  },
                  child: Text(product == null ? 'Close' : 'Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00875A),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        final addedName = nameController.text.trim();
                        final newProduct = Product(
                          productId: product?.productId,
                          productName: addedName,
                          barcode: barcodeController.text.trim().isEmpty ? null : barcodeController.text.trim(),
                          categoryId: selectedCategory,
                          unit: unitController.text.trim().isEmpty ? 'pcs' : unitController.text.trim(),
                          purchasePrice: double.tryParse(purchasePriceController.text.trim()) ?? 0.0,
                          sellingPrice: double.tryParse(sellingPriceController.text.trim()) ?? 0.0,
                          stock: int.tryParse(stockController.text.trim()) ?? 0,
                          minimumStock: int.tryParse(minStockController.text.trim()) ?? 0,
                          gst: 0.0,
                        );

                        final provider = parentContext.read<ProductProvider>();
                        if (product == null) {
                          await provider.addProduct(newProduct);
                          nameController.clear();
                          barcodeController.clear();
                          purchasePriceController.clear();
                          sellingPriceController.clear();
                          stockController.clear();
                          minStockController.clear();
                          unitController.clear();
                          setState(() {
                            selectedCategory = null;
                            successMessage = 'Product "$addedName" added! Add another product or click Close.';
                          });
                          formKey.currentState?.reset();
                        } else {
                          await provider.updateProduct(newProduct);
                          if (parentContext.mounted) {
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              const SnackBar(content: Text('Product updated successfully!'), backgroundColor: Color(0xFF00875A)),
                            );
                          }
                          if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
                            Navigator.pop(dialogContext);
                          }
                        }
                      } catch (e) {
                        if (parentContext.mounted) {
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to save product. Please verify inputs and try again.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: Text(product == null ? 'Add Product' : 'Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.productName}"?'),
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
              await context.read<ProductProvider>().deleteProduct(product.productId!);
              if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
                Navigator.pop(dialogContext);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product deleted successfully!')),
                );
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
    final categories = context.watch<CategoryProvider>().categories;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/sk_logo.png',
              height: 32,
              width: 32,
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, stack) => const Icon(Icons.store, color: Color(0xFF00875A), size: 28),
            ),
            const SizedBox(width: 10),
            const Text('Products Management'),
          ],
        ),
        actions: [
          // ── Print Product List (Print Dialog + Auto-Save) ──────────────
          Consumer2<ProductProvider, CategoryProvider>(
            builder: (context, prodProv, catProv, _) {
              return OutlinedButton.icon(
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('Print List'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00875A),
                  side: const BorderSide(color: Color(0xFF00875A)),
                ),
                onPressed: () {
                  final settings = context.read<SettingsProvider>().settings ?? Settings(
                    shopName: 'MS TRADERS',
                    address: 'No.144A, Mariyam Fathima Building, E.B.Road, Trichy',
                    phone: '7708906866',
                    gstNumber: '33CXGPS6190A1ZI',
                    fssaiNumber: '22421591000206',
                    invoicePrefix: 'INV',
                  );
                  if (prodProv.products.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No products available to print.'), backgroundColor: Colors.orange),
                    );
                    return;
                  }
                  PrintOptionsDialog.showReportDialog(
                    parentContext: context,
                    reportTitle: 'Product List Report',
                    reportFilename: 'Product_Management_Report',
                    buildPdfBytes: (format) async {
                      return ReportsPdfGenerator.buildProductListPdfBytes(
                        products: prodProv.products,
                        categories: catProv.categories,
                        settings: settings,
                        generatedBy: 'Admin',
                        pageFormat: format,
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),
          // ── Export to PDF (Silent Save) ────────────────────────────────
          Consumer2<ProductProvider, CategoryProvider>(
            builder: (context, prodProv, catProv, _) {
              return ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('Save PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF512DA8),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final settings = context.read<SettingsProvider>().settings ?? Settings(
                    shopName: 'MS TRADERS',
                    address: 'No.144A, Mariyam Fathima Building, E.B.Road, Trichy',
                    phone: '7708906866',
                    gstNumber: '33CXGPS6190A1ZI',
                    fssaiNumber: '22421591000206',
                    invoicePrefix: 'INV',
                  );
                  if (prodProv.products.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No products available to export.'), backgroundColor: Colors.orange),
                    );
                    return;
                  }
                  try {
                    final path = await ReportsPdfGenerator.exportProductListPdf(
                      products: prodProv.products,
                      categories: catProv.categories,
                      settings: settings,
                      generatedBy: 'Admin',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('PDF saved: $path'),
                          backgroundColor: const Color(0xFF00875A),
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to export PDF: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
              );
            },
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00875A),
              foregroundColor: Colors.white,
            ),
            onPressed: () => _showProductDialog(context),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Top Toolbar: Search & Category Filter
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;
                final searchField = TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products by name or barcode...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (val) => context.read<ProductProvider>().setSearchQuery(val),
                );

                final categoryDropdown = DropdownButtonFormField<int?>(
                  initialValue: context.watch<ProductProvider>().selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: 'Filter by Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('All Categories')),
                    ...categories.map((c) => DropdownMenuItem<int?>(
                      value: c.categoryId,
                      child: Text(c.categoryName),
                    )),
                  ],
                  onChanged: (val) => context.read<ProductProvider>().setSelectedCategory(val),
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      searchField,
                      const SizedBox(height: 12),
                      categoryDropdown,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(flex: 2, child: searchField),
                    const SizedBox(width: 16),
                    Expanded(flex: 1, child: categoryDropdown),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            // Product List Data Table
            Expanded(
              child: Consumer<ProductProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final products = provider.filteredProducts;
                  if (products.isEmpty) {
                    return const Center(child: Text('No products match your search or filter.'));
                  }

                  return Card(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: DataTable(
                                columnSpacing: 14,
                                horizontalMargin: 12,
                                dataRowMinHeight: 38,
                                dataRowMaxHeight: 44,
                                headingRowHeight: 40,
                                columns: const [
                                  DataColumn(label: Text('Code / ID')),
                                  DataColumn(label: Text('Product Name')),
                                  DataColumn(label: Text('Edit / Delete')),
                                  DataColumn(label: Text('Category')),
                                  DataColumn(label: Text('Stock')),
                                  DataColumn(label: Text('Min Stock')),
                                  DataColumn(label: Text('Buy Price')),
                                  DataColumn(label: Text('Sell Price')),
                                ],
                                rows: products.map((product) {
                                  final isLowStock = product.stock <= product.minimumStock;
                                  final categoryName = categories
                                      .firstWhere(
                                        (c) => c.categoryId == product.categoryId,
                                        orElse: () => Category(categoryName: 'Unassigned'),
                                      )
                                      .categoryName;
                                  final codeStr = product.codeOrId.isNotEmpty ? product.codeOrId : '#${product.productId ?? '-'}';

                                  return DataRow(
                                    cells: [
                                      DataCell(Text(codeStr, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF00875A)))),
                                      DataCell(Text(product.productName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue.shade700,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              onPressed: () => _showProductDialog(context, product: product),
                                              child: const Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                            const SizedBox(width: 6),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red.shade700,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              onPressed: () => _confirmDelete(context, product),
                                              child: const Text('Delete', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(Chip(label: Text(categoryName, style: const TextStyle(fontSize: 12)))),
                                      DataCell(
                                        Row(
                                          children: [
                                            Text('${product.stock} ${product.unit ?? 'pcs'}'),
                                            if (isLowStock) ...[
                                              const SizedBox(width: 6),
                                              const Tooltip(
                                                message: 'Low Stock Alert!',
                                                child: Icon(Icons.warning, color: Colors.orange, size: 18),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      DataCell(Text('${product.minimumStock}')),
                                      DataCell(Text('₹${product.purchasePrice.toStringAsFixed(2)}')),
                                      DataCell(Text('₹${product.sellingPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      },
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
