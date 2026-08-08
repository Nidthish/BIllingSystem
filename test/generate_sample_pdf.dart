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

  test('Generate Real Printable Sample Invoice PDF with 5 Products', () async {
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

    final sale = Sale(
      saleId: 101,
      invoiceNo: 'INV-01234',
      customerId: 1,
      customerName: 'PONMALAPATTI',
      date: '2030-02-11T10:30:00.000',
      subtotal: 2930.00,
      discount: 0.0,
      gst: 146.50,
      grandTotal: 3076.50,
      paymentMethod: 'Cash',
      gstRate: 5.0,
      cgstRate: 2.5,
      sgstRate: 2.5,
      taxableAmount: 2930.00,
      cgstAmount: 73.25,
      sgstAmount: 73.25,
    );

    final items = [
      SaleItem(saleId: 101, productId: 1, quantity: 2, price: 120, total: 240),
      SaleItem(saleId: 101, productId: 2, quantity: 1, price: 450, total: 450),
      SaleItem(saleId: 101, productId: 3, quantity: 3, price: 180, total: 540),
      SaleItem(saleId: 101, productId: 4, quantity: 5, price: 160, total: 800),
      SaleItem(saleId: 101, productId: 5, quantity: 1, price: 900, total: 900),
    ];

    final products = [
      Product(productId: 1, productName: 'மசாலா வகைகள் (Chicken Masala)', categoryId: 1, purchasePrice: 80, sellingPrice: 120, stock: 50, minimumStock: 5, gst: 5, unit: 'pcs', barcode: 'SK001'),
      Product(productId: 2, productName: 'மசாலா மூலப்பொருட்கள் (Black Pepper)', categoryId: 2, purchasePrice: 300, sellingPrice: 450, stock: 30, minimumStock: 5, gst: 5, unit: 'kg', barcode: 'SKMI009'),
      Product(productId: 3, productName: 'மாவு வகைகள் (Health Mix Powder)', categoryId: 4, purchasePrice: 120, sellingPrice: 180, stock: 40, minimumStock: 5, gst: 5, unit: 'kg', barcode: 'SK058'),
      Product(productId: 4, productName: 'பருப்பு வகைகள் (Toor Dal)', categoryId: 5, purchasePrice: 120, sellingPrice: 160, stock: 100, minimumStock: 5, gst: 5, unit: 'kg', barcode: 'SKDV02'),
      Product(productId: 5, productName: 'முந்திரி வகைகள் (Whole Cashew)', categoryId: 6, purchasePrice: 700, sellingPrice: 900, stock: 20, minimumStock: 5, gst: 5, unit: 'kg', barcode: 'SKCV05'),
    ];

    await InvoiceGenerator.generateAndPrintInvoice(
      sale: sale,
      items: items,
      customerName: 'PONMALAPATTI',
      customerPhone: '9876543210',
      customerAddress: 'TRICHY - 4, TAMILNADU',
      customerGst: '33AAACB1234C1Z1',
      settings: settings,
      allProducts: products,
    );

    print('Sample PDF generated successfully!');
  });
}
