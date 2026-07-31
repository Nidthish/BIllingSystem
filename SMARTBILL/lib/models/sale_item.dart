class SaleItem {
  final int? saleItemId;
  final int saleId;
  final int productId;
  final double quantity;
  final double price;
  final double total;

  SaleItem({
    this.saleItemId,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.total,
  });

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      saleItemId: map['sale_item_id'],
      saleId: map['sale_id'],
      productId: map['product_id'],
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sale_item_id': saleItemId,
      'sale_id': saleId,
      'product_id': productId,
      'quantity': quantity,
      'price': price,
      'total': total,
    };
  }
}
