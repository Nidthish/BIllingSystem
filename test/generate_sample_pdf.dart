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

  test('Generate Real Printable Sample Invoice PDF with 40 Products', () async {
    final settings = Settings(
      shopName: 'MS TRADERS',
      address: '138, Mullai Street, Sanjeevi Nagar,\nTiruchirappalli - 620002, Tamil Nadu, India.',
      phone: '7708906866',
      gstNumber: '33ABCDE1234F1Z5',
      invoicePrefix: 'INV',
      accountNumber: '05390200000618',
      ifsc: 'BARB0TIRUCH',
      branch: 'TRICHY MAIN',
      bankName: 'BANK OF BARODA',
      accountType: 'CURRENT ACCOUNT',
    );

    final productNames = [
      'Chicken Masala', 'Mutton Masala', 'Fish Curry Masala', 'Garam Masala', 'Turmeric Powder',
      'Chilli Powder', 'Coriander Powder', 'Cumin Powder', 'Black Pepper', 'Cardamom',
      'Clove', 'Cinnamon Stick', 'Fennel Seeds', 'Mustard Seeds', 'Fenugreek Seeds',
      'Health Mix Powder', 'Rava / Sooji', 'Wheat Flour (Atta)', 'Rice Flour', 'Toor Dal',
      'Moong Dal', 'Urad Dal', 'Chana Dal', 'Whole Cashew Nut', 'Dry Raisins (Kishmish)',
      'Almonds (Badam)', 'Pistachios (Pista)', 'Asafoetida (Perungayam)', 'Star Anise', 'Bay Leaves',
      'Dry Ginger Powder', 'Nutmeg Powder', 'Tamarind Paste', 'Sesame Seeds', 'Groundnut Oil',
      'Gingelly Oil', 'Sunflower Oil', 'White Pepper', 'Kasoori Methi', 'Saffron (Kesar)'
    ];

    final items = <SaleItem>[];
    final products = <Product>[];
    double subtotal = 0;

    for (int i = 0; i < 40; i++) {
      final pId = i + 1;
      final price = (i + 1) * 12.0 + 25.0;
      final qty = (i % 3) + 1.0;
      final itemTotal = price * qty;
      subtotal += itemTotal;

      products.add(Product(
        productId: pId,
        productName: productNames[i],
        categoryId: (i % 5) + 1,
        purchasePrice: price * 0.7,
        sellingPrice: price,
        stock: 100,
        minimumStock: 10,
        gst: 5.0,
        unit: i % 4 == 0 ? 'pcs' : 'kg',
        barcode: 'SK${(i + 1).toString().padLeft(3, '0')}',
      ));

      items.add(SaleItem(
        saleId: 4040,
        productId: pId,
        quantity: qty,
        price: price,
        total: itemTotal,
      ));
    }

    final gst = subtotal * 0.05;
    final grandTotal = subtotal + gst;

    final sale = Sale(
      saleId: 4040,
      invoiceNo: 'INV-2026-040',
      customerId: 1,
      customerName: 'SRIRAM (SK TRADERS)',
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

    await InvoiceGenerator.generateAndPrintInvoice(
      sale: sale,
      items: items,
      customerName: 'SRIRAM (SK TRADERS)',
      customerPhone: '6382471361',
      customerAddress: 'TRICHY - 620002, TAMIL NADU',
      customerGst: '33AAACB1234C1Z1',
      settings: settings,
      allProducts: products,
    );

    print('Sample PDF with 40 products generated successfully!');
  });
}
