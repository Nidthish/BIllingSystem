import 'dart:io';
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

  test('Generate Sample Invoice PDF', () async {
    final settings = Settings(
      shopName: 'MS TRADERS',
      address: '138, Mullai Street, Sanjeevi Nagar,\nTiruchirappalli- 620002, Tamil Nadu, India',
      phone: '7708906866',
      gstNumber: '33CXGPS6190A1ZI',
      fssaiNumber: '22421591000206',
      invoicePrefix: 'INV',
      accountNumber: '05390200000618',
      ifsc: 'BARB0TIRUCH',
      branch: 'TRICHY MAIN',
      bankName: 'BANK OF BARODA',
      accountType: 'CURRENT ACCOUNT',
    );

    final productNames = [
      'Ajwain (1kg)',
      'Almonds (Badam)',
      'Chicken Masala',
      'Turmeric Powder',
      'Chilli Powder',
    ];

    final items = <SaleItem>[];
    final products = <Product>[];
    double subtotal = 0;

    for (int i = 0; i < 5; i++) {
      final pId = i + 1;
      final price = (i + 1) * 120.0;
      final qty = (i % 2) + 1.0;
      final itemTotal = price * qty;
      subtotal += itemTotal;

      products.add(Product(
        productId: pId,
        productName: productNames[i],
        categoryId: 1,
        purchasePrice: price * 0.7,
        sellingPrice: price,
        stock: 100,
        minimumStock: 10,
        gst: 5.0,
        unit: 'kg',
        barcode: 'SK00${i + 1}',
      ));

      items.add(SaleItem(
        saleId: 1,
        productId: pId,
        quantity: qty,
        price: price,
        total: itemTotal,
      ));
    }

    final gst = subtotal * 0.05;
    final grandTotal = subtotal + gst;

    final sale = Sale(
      saleId: 1,
      invoiceNo: 'INV/2026-27/001',
      customerId: 1,
      customerName: 'NIDTHISH',
      date: DateTime.now().toIso8601String(),
      subtotal: subtotal,
      discount: 0.0,
      gst: gst,
      grandTotal: grandTotal,
      paymentMethod: 'Cash',
      gstRate: 5.0,
      cgstRate: 2.5,
      sgstRate: 2.5,
      taxableAmount: subtotal,
      cgstAmount: gst / 2,
      sgstAmount: gst / 2,
    );

    final bytes = await InvoiceGenerator.generateAndSaveInvoice(
      sale: sale,
      items: items,
      customerName: 'NIDTHISH',
      customerPhone: '6374518061',
      customerAddress: 'NO:13, MULLAI STREET, SANJEEVI NAGAR',
      customerGst: '33AAACB1234C1Z1',
      settings: settings,
      allProducts: products,
    );

    final file = File('Invoices/INV_2026_27_001.pdf');
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    await file.writeAsBytes(bytes);

    print('Sample Invoice PDF created at: ${file.absolute.path}');
  });
}
