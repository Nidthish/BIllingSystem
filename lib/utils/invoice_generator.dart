import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../models/product.dart';
import '../models/settings.dart';
import 'app_folder_storage.dart';

class InvoiceGenerator {
  static pw.Font? _tamilFontRegular;
  static pw.Font? _tamilFontBold;
  static pw.MemoryImage? _skLogoImage;
  static pw.MemoryImage? _qrPaymentImage;
  static pw.MemoryImage? _qrLocationImage;
  static pw.MemoryImage? _productsWeOfferImage;
  static bool _assetsLoaded = false;

  static Future<void> preloadAssets() async {
    if (_assetsLoaded) return;
    try {
      final regData = await rootBundle.load('assets/fonts/NotoSansTamil-Regular.ttf');
      _tamilFontRegular = pw.Font.ttf(regData);
    } catch (_) {}
    try {
      final boldData = await rootBundle.load('assets/fonts/NotoSansTamil-Bold.ttf');
      _tamilFontBold = pw.Font.ttf(boldData);
    } catch (_) {}
    try {
      final logoBytes = await rootBundle.load('assets/images/sk_logo.png');
      _skLogoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}
    try {
      final qrPayBytes = await rootBundle.load('assets/images/qr_payment.jpg');
      _qrPaymentImage = pw.MemoryImage(qrPayBytes.buffer.asUint8List());
    } catch (_) {}
    try {
      final qrLocBytes = await rootBundle.load('assets/images/qr_location.jpg');
      _qrLocationImage = pw.MemoryImage(qrLocBytes.buffer.asUint8List());
    } catch (_) {}
    try {
      final offerBytes = await rootBundle.load('assets/images/products_we_offer.jpg');
      _productsWeOfferImage = pw.MemoryImage(offerBytes.buffer.asUint8List());
    } catch (_) {}
    _assetsLoaded = true;
  }

  /// Builds Invoice PDF bytes with specified paper format (A4 or A5).
  static Future<Uint8List> buildInvoicePdfBytes({
    required Sale sale,
    required List<SaleItem> items,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    String? customerGst,
    required Settings settings,
    required List<Product> allProducts,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    // [DEBUG-START] Log PDF paper size
    debugPrint('Generating PDF dimensions: ${pageFormat.width.toStringAsFixed(2)} x ${pageFormat.height.toStringAsFixed(2)} pts');
    // [DEBUG-END]

    await preloadAssets();

    final primaryGreen = PdfColor.fromHex('#004D25');
    final fontReg = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    final fallbacks = <pw.Font>[];
    if (_tamilFontRegular != null) fallbacks.add(_tamilFontRegular!);
    if (_tamilFontBold != null) fallbacks.add(_tamilFontBold!);

    final pdf = pw.Document();
    final productMap = {for (var p in allProducts) p.productId: p.productName};

    final isA5 = pageFormat.width <= PdfPageFormat.a5.width + 10;
    final contentPadding = isA5 ? 12.0 : 18.0;

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(contentPadding),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // TOP HEADER
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 6,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          settings.shopName.isEmpty ? 'MS TRADERS' : settings.shopName.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: isA5 ? 20 : 26,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryGreen,
                            font: fontBold,
                            fontFallback: fallbacks,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Container(height: 1.2, width: isA5 ? 140 : 180, color: primaryGreen),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          settings.address.isEmpty
                              ? '138, Mullai Street, Sanjeevi Nagar,\nTiruchirappalli- 620002, Tamil Nadu, India'
                              : settings.address,
                          style: pw.TextStyle(
                            fontSize: isA5 ? 7 : 8.5,
                            fontWeight: pw.FontWeight.bold,
                            font: fontReg,
                            fontFallback: fallbacks,
                            lineSpacing: 1.1,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'GSTIN : ${settings.gstNumber.isEmpty ? "33CXGPS6190A1ZI" : settings.gstNumber}',
                          style: pw.TextStyle(
                            fontSize: isA5 ? 6.5 : 7.5,
                            fontWeight: pw.FontWeight.bold,
                            font: fontBold,
                            fontFallback: fallbacks,
                          ),
                        ),
                        pw.Text(
                          'FSSAI : ${settings.fssaiNumber.isEmpty ? "22421591000206" : settings.fssaiNumber}',
                          style: pw.TextStyle(
                            fontSize: isA5 ? 6.5 : 7.5,
                            fontWeight: pw.FontWeight.bold,
                            font: fontBold,
                            fontFallback: fallbacks,
                          ),
                        ),
                        pw.Text(
                          'PHONE NO : ${settings.phone.isEmpty ? "7708906866" : settings.phone}',
                          style: pw.TextStyle(
                            fontSize: isA5 ? 6.5 : 7.5,
                            fontWeight: pw.FontWeight.bold,
                            font: fontBold,
                            fontFallback: fallbacks,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Container(
                      alignment: pw.Alignment.topRight,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          if (_skLogoImage != null)
                            pw.Image(_skLogoImage!, width: isA5 ? 120 : 150, height: isA5 ? 42 : 55, fit: pw.BoxFit.contain)
                          else
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: pw.BoxDecoration(
                                color: primaryGreen,
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Text(
                                'SK MASALA',
                                style: pw.TextStyle(
                                  fontSize: isA5 ? 12 : 14,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                  fontFallback: fallbacks,
                                ),
                              ),
                            ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'HOTEL STYLE MASALA',
                            style: pw.TextStyle(
                              fontSize: isA5 ? 6 : 7.5,
                              fontWeight: pw.FontWeight.bold,
                              font: fontBold,
                              fontFallback: fallbacks,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.Text(
                            '( Minimum Usage Maximum Saving )',
                            style: pw.TextStyle(
                              fontSize: isA5 ? 5.5 : 7,
                              fontWeight: pw.FontWeight.bold,
                              font: fontBold,
                              fontFallback: fallbacks,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 3),
              pw.Container(height: 1, color: primaryGreen),
              pw.SizedBox(height: 4),

              // CUSTOMER & INVOICE INFO
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: pw.BoxDecoration(
                              color: primaryGreen,
                              borderRadius: pw.BorderRadius.circular(2),
                            ),
                            child: pw.Text(
                              'TO',
                              style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: isA5 ? 6.5 : 7.5, fontFallback: fallbacks),
                            ),
                          ),
                          pw.SizedBox(width: 4),
                          pw.Text(
                            customerName.isEmpty ? 'WALK-IN CUSTOMER' : customerName.toUpperCase(),
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: isA5 ? 7.5 : 8.5, font: fontBold, fontFallback: fallbacks),
                          ),
                        ],
                      ),
                      if (customerAddress.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 1.5),
                          child: pw.Text(
                            customerAddress.toUpperCase(),
                            style: pw.TextStyle(fontSize: isA5 ? 6.5 : 7.5, font: fontReg, fontFallback: fallbacks),
                          ),
                        ),
                      if (customerPhone.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 1),
                          child: pw.Text(
                            'PH: $customerPhone',
                            style: pw.TextStyle(fontSize: isA5 ? 6.5 : 7.5, font: fontReg, fontFallback: fallbacks),
                          ),
                        ),
                      if (customerGst != null && customerGst.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 1),
                          child: pw.Text(
                            'GSTIN: $customerGst',
                            style: pw.TextStyle(fontSize: isA5 ? 6.5 : 7.5, font: fontBold, fontFallback: fallbacks),
                          ),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text('INVOICE NO  :  ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: isA5 ? 7 : 8, fontFallback: fallbacks)),
                          pw.Text(sale.invoiceNo, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: isA5 ? 7 : 8, fontFallback: fallbacks)),
                        ],
                      ),
                      pw.SizedBox(height: 1.5),
                      pw.Row(
                        children: [
                          pw.Text('DATE               :  ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: isA5 ? 7 : 8, fontFallback: fallbacks)),
                          pw.Text(_formatDate(sale.date), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: isA5 ? 7 : 8, fontFallback: fallbacks)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 4),

              // PRODUCT TABLE
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
                columnWidths: const {
                  0: pw.FixedColumnWidth(24),  // S.NO
                  1: pw.FlexColumnWidth(1),    // PRODUCTS
                  2: pw.FixedColumnWidth(36),  // QTY
                  3: pw.FixedColumnWidth(48),  // RATE
                  4: pw.FixedColumnWidth(54),  // TOTAL
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: primaryGreen),
                    children: [
                      _buildHeaderCell('S.NO', fontBold, fallbacks, align: pw.TextAlign.center, isA5: isA5),
                      _buildHeaderCell('PRODUCTS', fontBold, fallbacks, align: pw.TextAlign.left, padLeft: 4, isA5: isA5),
                      _buildHeaderCell('QTY', fontBold, fallbacks, align: pw.TextAlign.center, isA5: isA5),
                      _buildHeaderCell('RATE', fontBold, fallbacks, align: pw.TextAlign.right, padRight: 4, isA5: isA5),
                      _buildHeaderCell('TOTAL', fontBold, fallbacks, align: pw.TextAlign.right, padRight: 4, isA5: isA5),
                    ],
                  ),
                  ...items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final pName = productMap[item.productId] ?? 'Item #${item.productId}';
                    final qtyStr = item.quantity % 1 == 0 ? '${item.quantity.toInt()}g' : '${item.quantity.toStringAsFixed(1)}g';
                    final rateStr = item.price % 1 == 0 ? item.price.toInt().toString() : item.price.toStringAsFixed(2);
                    final totalStr = 'Rs.${item.total.toStringAsFixed(item.total % 1 == 0 ? 0 : 2)}';
                    final isCompact = items.length > 12 || isA5;

                    return pw.TableRow(
                      children: [
                        _buildDataCell('${index + 1}', fontBold, fallbacks, align: pw.TextAlign.center, isCompact: isCompact, isA5: isA5),
                        _buildDataCell(pName, fontReg, fallbacks, align: pw.TextAlign.left, padLeft: 4, isCompact: isCompact, isA5: isA5),
                        _buildDataCell(qtyStr, fontReg, fallbacks, align: pw.TextAlign.center, isCompact: isCompact, isA5: isA5),
                        _buildDataCell(rateStr, fontReg, fallbacks, align: pw.TextAlign.right, padRight: 4, isCompact: isCompact, isA5: isA5),
                        _buildDataCell(totalStr, fontBold, fallbacks, align: pw.TextAlign.right, padRight: 4, isCompact: isCompact, isA5: isA5),
                      ],
                    );
                  }),
                ],
              ),

              pw.Spacer(),

              // BOTTOM SECTION
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // BANK DETAILS
                  pw.Expanded(
                    flex: 34,
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: primaryGreen, width: 0.8),
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: double.infinity,
                            padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                            decoration: pw.BoxDecoration(
                              color: primaryGreen,
                              borderRadius: const pw.BorderRadius.only(
                                topLeft: pw.Radius.circular(2),
                                topRight: pw.Radius.circular(2),
                              ),
                            ),
                            child: pw.Text(
                              'BANK DETAILS',
                              style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: isA5 ? 6 : 7, fontFallback: fallbacks),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                _buildBankRow('A/C NO:', settings.accountNumber, fontBold, fallbacks, isA5),
                                _buildBankRow('IFSC:', settings.ifsc, fontBold, fallbacks, isA5),
                                _buildBankRow('BRANCH:', settings.branch, fontBold, fallbacks, isA5),
                                _buildBankRow('BANK:', settings.bankName, fontBold, fallbacks, isA5),
                                _buildBankRow('TYPE:', settings.accountType, fontBold, fallbacks, isA5),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 4),

                  // DUAL QR CODES
                  pw.Expanded(
                    flex: 30,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              if (_qrLocationImage != null)
                                pw.Image(_qrLocationImage!, width: isA5 ? 38 : 46, height: isA5 ? 38 : 46)
                              else
                                pw.BarcodeWidget(
                                  data: 'https://maps.google.com/?q=${settings.address}',
                                  barcode: pw.Barcode.qrCode(),
                                  width: isA5 ? 38 : 46,
                                  height: isA5 ? 38 : 46,
                                ),
                              pw.SizedBox(height: 1),
                              pw.Text(
                                'Website',
                                style: pw.TextStyle(fontSize: isA5 ? 5.5 : 6.5, fontWeight: pw.FontWeight.bold, font: fontBold, color: primaryGreen),
                              ),
                            ],
                          ),
                          pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              if (_qrPaymentImage != null)
                                pw.Image(_qrPaymentImage!, width: isA5 ? 38 : 46, height: isA5 ? 38 : 46)
                              else
                                pw.BarcodeWidget(
                                  data: 'upi://pay?pa=${settings.phone}@upi&pn=${settings.shopName}',
                                  barcode: pw.Barcode.qrCode(),
                                  width: isA5 ? 38 : 46,
                                  height: isA5 ? 38 : 46,
                                ),
                              pw.SizedBox(height: 1),
                              pw.Text(
                                'Location',
                                style: pw.TextStyle(fontSize: isA5 ? 5.5 : 6.5, fontWeight: pw.FontWeight.bold, font: fontBold, color: primaryGreen),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 4),

                  // TOTAL SUMMARY & GRAND TOTAL
                  pw.Expanded(
                    flex: 36,
                    child: pw.Column(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey600, width: 0.6),
                            borderRadius: pw.BorderRadius.circular(2),
                          ),
                          child: pw.Column(
                            children: [
                              _buildSummaryRow('TOTAL', 'Rs.${sale.subtotal.toStringAsFixed(2)}', fontBold, fallbacks, isA5),
                              _buildSummaryRow('CGST (${sale.cgstRate.toStringAsFixed(1)}%)', 'Rs.${sale.cgstAmount.toStringAsFixed(2)}', fontReg, fallbacks, isA5),
                              _buildSummaryRow('SGST (${sale.sgstRate.toStringAsFixed(1)}%)', 'Rs.${sale.sgstAmount.toStringAsFixed(2)}', fontReg, fallbacks, isA5),
                              _buildSummaryRow('TOTAL TAX', 'Rs.${sale.gst.toStringAsFixed(2)}', fontBold, fallbacks, isA5),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.symmetric(vertical: 2),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: primaryGreen, width: 1),
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                          child: pw.Column(
                            children: [
                              pw.Text(
                                'GRAND TOTAL',
                                style: pw.TextStyle(fontSize: isA5 ? 6 : 7, fontWeight: pw.FontWeight.bold, font: fontBold, fontFallback: fallbacks),
                              ),
                              pw.Text(
                                'Rs.${sale.grandTotal.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                  fontSize: isA5 ? 10 : 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: primaryGreen,
                                  font: fontBold,
                                  fontFallback: fallbacks,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),

              // PRODUCTS WE OFFER & SIGNATURE
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Expanded(
                    flex: 62,
                    child: _productsWeOfferImage != null
                        ? pw.Container(
                            height: isA5 ? 44 : 54,
                            alignment: pw.Alignment.centerLeft,
                            child: pw.Image(
                              _productsWeOfferImage!,
                              fit: pw.BoxFit.contain,
                            ),
                          )
                        : pw.Container(
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: primaryGreen, width: 0.8),
                              borderRadius: pw.BorderRadius.circular(3),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Container(
                                  width: double.infinity,
                                  padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                                  decoration: pw.BoxDecoration(
                                    color: primaryGreen,
                                    borderRadius: const pw.BorderRadius.only(
                                      topLeft: pw.Radius.circular(2),
                                      topRight: pw.Radius.circular(2),
                                    ),
                                  ),
                                  child: pw.Text(
                                    'PRODUCTS WE OFFER :',
                                    style: pw.TextStyle(
                                      color: PdfColors.white,
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: isA5 ? 6.5 : 7.5,
                                      font: fontBold,
                                    ),
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  child: pw.Row(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Expanded(
                                        child: pw.Column(
                                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                                          children: [
                                            _buildOfferBullet('மசாலா வகைகள்', fontBold, fallbacks, isA5),
                                            _buildOfferBullet('மசாலா மூலப்பொருட்கள்', fontBold, fallbacks, isA5),
                                            _buildOfferBullet('மாவு வகைகள்', fontBold, fallbacks, isA5),
                                            _buildOfferBullet('பருப்பு வகைகள்', fontBold, fallbacks, isA5),
                                          ],
                                        ),
                                      ),
                                      pw.Expanded(
                                        child: pw.Column(
                                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                                          children: [
                                            _buildOfferBullet('முந்திரி வகைகள்', fontBold, fallbacks, isA5),
                                            _buildOfferBullet('உலர் பழ வகைகள்', fontBold, fallbacks, isA5),
                                            _buildOfferBullet('வாசனை மசாலா பொருட்கள்', fontBold, fallbacks, isA5),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    flex: 38,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text(
                          'FOR ${settings.shopName.isEmpty ? 'MS TRADERS' : settings.shopName.toUpperCase()}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: isA5 ? 6.5 : 7.5, font: fontBold),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: isA5 ? 20 : 26),
                        pw.Container(width: 100, height: 0.5, color: PdfColors.grey700),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'AUTHORIZED SIGNATURE',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: isA5 ? 6 : 7, font: fontBold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),

              // THANK YOU BANNER
              pw.Center(
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('---  ', style: pw.TextStyle(fontSize: isA5 ? 6.5 : 8, color: primaryGreen, fontFallback: fallbacks)),
                    pw.Text(
                      'THANK YOU !!!',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: isA5 ? 8 : 10,
                        color: primaryGreen,
                        font: fontBold,
                        fontFallback: fallbacks,
                      ),
                    ),
                    pw.Text('  ---', style: pw.TextStyle(fontSize: isA5 ? 6.5 : 8, color: primaryGreen, fontFallback: fallbacks)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  static Future<Uint8List> generateAndSaveInvoice({
    required Sale sale,
    required List<SaleItem> items,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    String? customerGst,
    required Settings settings,
    required List<Product> allProducts,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    final pdfBytes = await buildInvoicePdfBytes(
      sale: sale,
      items: items,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      customerGst: customerGst,
      settings: settings,
      allProducts: allProducts,
      pageFormat: pageFormat,
    );

    try {
      await AppFolderStorage.saveInvoicePdf(pdfBytes, sale.invoiceNo);
    } catch (_) {}

    return pdfBytes;
  }

  static Future<bool> directPrintInvoiceBytes({
    required Uint8List pdfBytes,
    required String invoiceNo,
    Printer? printer,
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    try {
      // [DEBUG-START]
      debugPrint('Direct printing format: ${format.width.toStringAsFixed(2)} x ${format.height.toStringAsFixed(2)} pts');
      // [DEBUG-END]

      final printers = await Printing.listPrinters();

      bool isVirtualPrinter(Printer p) {
        final name = p.name.toLowerCase();
        return name.contains('print to pdf') ||
            name.contains('xps') ||
            name.contains('fax') ||
            name.contains('onenote');
      }

      Printer? physicalPrinter = printer;
      if (physicalPrinter == null && printers.isNotEmpty) {
        try {
          physicalPrinter = printers.firstWhere(
            (p) => p.isDefault && !isVirtualPrinter(p) && p.url.isNotEmpty,
            orElse: () => printers.firstWhere(
              (p) => !isVirtualPrinter(p) && p.url.isNotEmpty,
              orElse: () => printers.first,
            ),
          );
        } catch (_) {}
      }

      if (physicalPrinter != null && isVirtualPrinter(physicalPrinter)) {
        return false;
      }

      if (physicalPrinter != null && physicalPrinter.url.isNotEmpty) {
        return await Printing.directPrintPdf(
          printer: physicalPrinter,
          onLayout: (PdfPageFormat defaultFormat) async => pdfBytes,
          name: invoiceNo,
          format: format,
          usePrinterSettings: false,
        );
      }
    } catch (e) {
      debugPrint('Direct print error: $e');
    }
    return false;
  }

  static Future<void> printInvoiceBytes({
    required Uint8List pdfBytes,
    required String invoiceNo,
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    try {
      // [DEBUG-START]
      debugPrint('Printing layout format: ${format.width.toStringAsFixed(2)} x ${format.height.toStringAsFixed(2)} pts');
      // [DEBUG-END]

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat defaultFormat) => pdfBytes,
        name: invoiceNo,
        format: format,
        usePrinterSettings: false,
      );
    } catch (e) {
      debugPrint('Printing layout error: $e');
    }
  }

  static Future<void> generateAndPrintInvoice({
    required Sale sale,
    required List<SaleItem> items,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    String? customerGst,
    required Settings settings,
    required List<Product> allProducts,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    final pdfBytes = await generateAndSaveInvoice(
      sale: sale,
      items: items,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      customerGst: customerGst,
      settings: settings,
      allProducts: allProducts,
      pageFormat: pageFormat,
    );

    await printInvoiceBytes(
      pdfBytes: pdfBytes,
      invoiceNo: sale.invoiceNo,
      format: pageFormat,
    );
  }

  // --- Helper Widgets ---

  static pw.Widget _buildHeaderCell(
    String text,
    pw.Font font,
    List<pw.Font> fallbacks, {
    pw.TextAlign align = pw.TextAlign.left,
    double padLeft = 0,
    double padRight = 0,
    bool isA5 = false,
  }) {
    pw.Alignment containerAlignment;
    if (align == pw.TextAlign.right) {
      containerAlignment = pw.Alignment.centerRight;
    } else if (align == pw.TextAlign.center) {
      containerAlignment = pw.Alignment.center;
    } else {
      containerAlignment = pw.Alignment.centerLeft;
    }

    final leftPad = padLeft > 0 ? padLeft : 2.0;
    final rightPad = padRight > 0 ? padRight : 2.0;

    return pw.Container(
      alignment: containerAlignment,
      padding: pw.EdgeInsets.only(top: isA5 ? 2 : 3, bottom: isA5 ? 2 : 3, left: leftPad, right: rightPad),
      child: pw.Text(
        text,
        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: isA5 ? 6.5 : 7.5, font: font, fontFallback: fallbacks),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildDataCell(
    String text,
    pw.Font font,
    List<pw.Font> fallbacks, {
    pw.TextAlign align = pw.TextAlign.left,
    double padLeft = 0,
    double padRight = 0,
    bool isCompact = false,
    bool isA5 = false,
  }) {
    pw.Alignment containerAlignment;
    if (align == pw.TextAlign.right) {
      containerAlignment = pw.Alignment.centerRight;
    } else if (align == pw.TextAlign.center) {
      containerAlignment = pw.Alignment.center;
    } else {
      containerAlignment = pw.Alignment.centerLeft;
    }

    final vPad = isCompact ? 1.5 : (isA5 ? 2.5 : 3.5);
    final fSize = isCompact ? (isA5 ? 6.0 : 7.0) : (isA5 ? 6.8 : 8.0);
    final leftPad = padLeft > 0 ? padLeft : 2.0;
    final rightPad = padRight > 0 ? padRight : 2.0;

    return pw.Container(
      alignment: containerAlignment,
      padding: pw.EdgeInsets.only(top: vPad, bottom: vPad, left: leftPad, right: rightPad),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: fSize, font: font, fontFallback: fallbacks),
        textAlign: align,
        maxLines: 1,
      ),
    );
  }

  static pw.Widget _buildBankRow(String label, String value, pw.Font font, List<pw.Font> fallbacks, bool isA5) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: isA5 ? 36 : 42,
            child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: isA5 ? 5.5 : 6.5, font: font, fontFallback: fallbacks)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(fontSize: isA5 ? 5.5 : 6.5, font: font, fontFallback: fallbacks), maxLines: 1),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value, pw.Font font, List<pw.Font> fallbacks, bool isA5) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 0.8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: isA5 ? 5.5 : 6.5, font: font, fontFallback: fallbacks)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: isA5 ? 5.5 : 6.5, font: font, fontFallback: fallbacks)),
        ],
      ),
    );
  }

  static pw.Widget _buildOfferBullet(String text, pw.Font defaultFont, List<pw.Font> fallbacks, bool isA5) {
    final primaryTamilFont = _tamilFontBold ?? _tamilFontRegular ?? defaultFont;
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text('> ', style: pw.TextStyle(fontSize: isA5 ? 6 : 7.5, font: defaultFont, fontWeight: pw.FontWeight.bold)),
          pw.Text(text, style: pw.TextStyle(fontSize: isA5 ? 6 : 7.5, font: primaryTamilFont, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static String _formatDate(String dateStr) {
    if (dateStr.trim().isEmpty) return DateFormat("dd.MM.yyyy").format(DateTime.now());
    final parsed = DateTime.tryParse(dateStr);
    if (parsed != null) {
      return DateFormat("dd.MM.yyyy").format(parsed);
    }
    try {
      final d = DateFormat("dd/MM/yyyy").parse(dateStr);
      return DateFormat("dd.MM.yyyy").format(d);
    } catch (_) {}
    return dateStr;
  }

  static String generateInvoiceNumber({
    required String prefix,
    required DateTime date,
    required List<Sale> existingSales,
  }) {
    final cleanPrefix = prefix.trim().isEmpty ? 'INV' : prefix.trim();
    final year = date.year;
    final month = date.month;

    int startYear;
    int endYearShort;

    if (month >= 4) {
      startYear = year;
      endYearShort = (year + 1) % 100;
    } else {
      startYear = year - 1;
      endYearShort = year % 100;
    }

    final fyStr = '$startYear-${endYearShort.toString().padLeft(2, '0')}';
    final prefixWithFy = '$cleanPrefix/$fyStr/';

    int maxSeq = 0;
    for (final s in existingSales) {
      if (s.invoiceNo.startsWith(prefixWithFy)) {
        final parts = s.invoiceNo.split('/');
        if (parts.length >= 3) {
          final seqNum = int.tryParse(parts.last) ?? 0;
          if (seqNum > maxSeq) maxSeq = seqNum;
        }
      }
    }

    final nextSeq = maxSeq + 1;
    final seqStr = nextSeq.toString().padLeft(3, '0');
    return '$prefixWithFy$seqStr';
  }
}