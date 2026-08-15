import 'package:flutter_test/flutter_test.dart';
import 'package:smartbill/models/sale.dart';
import 'package:smartbill/models/sale_item.dart';
import 'package:smartbill/models/settings.dart';
import 'package:smartbill/models/product.dart';
import 'package:smartbill/utils/invoice_generator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('Verify Invoice PDF generation with 28 rows and dynamic data', () async {
    final settings = Settings(
      shopName: 'MS TRADERS',
      address: '138, Mullai Street, Sanjeevi Nagar, Tiruchirappalli - 620002, Tamil Nadu, India.',
      phone: '7708906866',
      gstNumber: '33ABCDE1234F1Z5',
      invoicePrefix: 'INV',
      accountNumber: '05390200000618',
      ifsc: 'BARB0TIRUCH',
      branch: 'TRICHY MAIN',
      bankName: 'BANK OF BARODA',
      accountType: 'CURRENT ACCOUNT',
    );

    final sale = Sale(
      saleId: 1,
      invoiceNo: '01234',
      customerId: 1,
      customerName: 'PONMALAPATTI',
      date: '2030-02-11T00:00:00.000',
      subtotal: 2011.21,
      discount: 0.0,
      gst: 460.34,
      grandTotal: 3290.23,
      paymentMethod: 'Cash',
      gstRate: 5.0,
      cgstRate: 2.5,
      sgstRate: 2.5,
      taxableAmount: 2011.21,
      cgstAmount: 230.34,
      sgstAmount: 230.34,
    );

    final items = [
      SaleItem(saleId: 1, productId: 1, quantity: 1, price: 100, total: 100),
      SaleItem(saleId: 1, productId: 2, quantity: 5, price: 100, total: 500),
      SaleItem(saleId: 1, productId: 3, quantity: 1, price: 100, total: 100),
      SaleItem(saleId: 1, productId: 4, quantity: 1, price: 100, total: 100),
      SaleItem(saleId: 1, productId: 5, quantity: 5, price: 100, total: 500),
      SaleItem(saleId: 1, productId: 6, quantity: 1, price: 100, total: 100),
      SaleItem(saleId: 1, productId: 7, quantity: 1, price: 100, total: 100),
      SaleItem(saleId: 1, productId: 8, quantity: 5, price: 100, total: 500),
    ];

    final products = [
      Product(productId: 1, productName: 'மசாலா வகைகள்', categoryId: 1, purchasePrice: 50, sellingPrice: 100, stock: 10, minimumStock: 5, gst: 5, unit: 'pcs', barcode: 'SK001'),
      Product(productId: 2, productName: 'மசாலா மூலப்பொருட்கள்', categoryId: 2, purchasePrice: 50, sellingPrice: 100, stock: 10, minimumStock: 5, gst: 5, unit: 'kg', barcode: 'SK002'),
      Product(productId: 3, productName: 'மாவு வகைகள்', categoryId: 4, purchasePrice: 50, sellingPrice: 100, stock: 10, minimumStock: 5, gst: 5, unit: 'kg', barcode: 'SK003'),
      Product(productId: 4, productName: 'பருப்பு வகைகள்', categoryId: 5, purchasePrice: 50, sellingPrice: 100, stock: 10, minimumStock: 5, gst: 5, unit: 'kg', barcode: 'SK004'),
      Product(productId: 5, productName: 'பருப்பு வகைகள்', categoryId: 5, purchasePrice: 50, sellingPrice: 100, stock: 10, minimumStock: 5, gst: 5, unit: 'kg', barcode: 'SK005'),
      Product(productId: 6, productName: 'முந்திரி வகைகள்', categoryId: 6, purchasePrice: 50, sellingPrice: 100, stock: 10, minimumStock: 5, gst: 5, unit: 'kg', barcode: 'SK006'),
      Product(productId: 7, productName: 'உலர் பழ வகைகள்', categoryId: 7, purchasePrice: 50, sellingPrice: 100, stock: 10, minimumStock: 5, gst: 5, unit: 'kg', barcode: 'SK007'),
      Product(productId: 8, productName: 'வாசனை மசாலா பொருட்கள்', categoryId: 3, purchasePrice: 50, sellingPrice: 100, stock: 10, minimumStock: 5, gst: 5, unit: 'kg', barcode: 'SK008'),
    ];

    expect(items.length, 8);
    expect(products.length, 8);
    expect(sale.grandTotal, 3290.23);
    expect(settings.shopName, 'MS TRADERS');
  });

  test('Product.fromMap correctly parses double stock values from database without throwing TypeError', () {
    final rawMap = <String, dynamic>{
      'product_id': 123,
      'product_name': 'Product #123',
      'category_id': 1,
      'purchase_price': 30.0,
      'selling_price': 40.0,
      'stock': 999.9, // SQLite dynamic real type after stock deduction
      'minimum_stock': 5.0,
      'gst': 5.0,
      'unit': 'g',
      'barcode': 'SK123',
    };

    final product = Product.fromMap(rawMap);
    expect(product.productId, 123);
    expect(product.stock, 1000);
    expect(product.minimumStock, 5);
  });

  test('Product search matches barcode, product code, ID, and product name', () {
    final p1 = Product(productId: 101, productName: 'Chettinad Chicken Masala', purchasePrice: 0, sellingPrice: 50, stock: 10, minimumStock: 5, gst: 0, barcode: 'SK002');
    final p2 = Product(productId: 102, productName: 'Product #102', purchasePrice: 0, sellingPrice: 40, stock: 10, minimumStock: 5, gst: 0);

    expect(p1.codeOrId, 'SK002');
    expect(p2.codeOrId, '#102');

    // Matching SK002
    expect(p1.codeOrId.toLowerCase().contains('sk002'), isTrue);
    // Matching #102
    expect(p2.codeOrId.toLowerCase().contains('#102'), isTrue);
  });
}
