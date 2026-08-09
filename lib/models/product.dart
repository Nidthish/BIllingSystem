class Product {
  final int? productId;
  final String productName;
  final int? categoryId;
  final double purchasePrice;
  final double sellingPrice;
  final int stock;
  final int minimumStock;
  final double gst;
  final String? unit;
  final String? barcode;
  final String? createdAt;

  Product({
    this.productId,
    required this.productName,
    this.categoryId,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stock,
    required this.minimumStock,
    required this.gst,
    this.unit,
    this.barcode,
    this.createdAt,
  });

  String get codeOrId {
    if (barcode != null && barcode!.trim().isNotEmpty) {
      return barcode!.trim();
    }
    return productId != null ? '#$productId' : '';
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      productId: map['product_id'],
      productName: map['product_name'] ?? '',
      categoryId: map['category_id'],
      purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0.0,
      stock: map['stock'] ?? 0,
      minimumStock: map['minimum_stock'] ?? 0,
      gst: (map['gst'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'],
      barcode: map['barcode'],
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'product_name': productName,
      'category_id': categoryId,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'stock': stock,
      'minimum_stock': minimumStock,
      'gst': gst,
      'unit': unit,
      'barcode': barcode,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
    if (productId != null) {
      map['product_id'] = productId;
    }
    return map;
  }
}
