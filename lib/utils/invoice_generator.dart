import 'dart:typed_data';
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
    // Preload assets and fonts
    await preloadAssets();

    final primaryGreen = PdfColor.fromHex('#004D25');
    final fontReg = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    // Fallbacks array for Tamil Unicode characters
    final fallbacks = <pw.Font>[];
    if (_tamilFontRegular != null) fallbacks.add(_tamilFontRegular!);
    if (_tamilFontBold != null) fallbacks.add(_tamilFontBold!);

    final pdf = pw.Document();

    final productMap = {for (var p in allProducts) p.productId: p.productName};

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.only(left: 18, right: 18, top: 12, bottom: 12),
        build: (pw.Context context) => [
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
                          'MS TRADERS',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryGreen,
                            font: fontBold,
                            fontFallback: fallbacks,
                          ),
                        ),
                        pw.SizedBox(height: 1),
                        pw.Container(height: 1.2, width: 130, color: primaryGreen),
                        pw.SizedBox(height: 2),
                        pw.Text(
                            '138, Mullai Street, Sanjeevi Nagar,\n'
                            'Tiruchirappalli- 620002, Tamil Nadu, India',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            font: fontReg,
                            fontFallback: fallbacks,
                            lineSpacing: 1.1,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'PHO.NO :7708906866',
                          style: pw.TextStyle(
                            fontSize: 8,
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
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        if (_skLogoImage != null)
                          pw.Image(_skLogoImage!, width: 185, height: 68, fit: pw.BoxFit.contain)
                        else
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                            decoration: pw.BoxDecoration(
                              color: primaryGreen,
                              borderRadius: pw.BorderRadius.circular(20),
                            ),
                            child: pw.Text(
                              'SK MASALA',
                              style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontFallback: fallbacks),
                            ),
                          ),
                        pw.SizedBox(height: 1),
                        pw.Container(
                          width: 185,
                          alignment: pw.Alignment.centerRight,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                'HOTEL STYLE MASALA',
                                style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, font: fontBold, fontFallback: fallbacks),
                                textAlign: pw.TextAlign.right,
                              ),
                              pw.SizedBox(height: 1),
                              pw.Text(
                                'TRADITIONAL CHETTINAD STYLE MASALAS',
                                style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, font: fontBold, fontFallback: fallbacks),
                                textAlign: pw.TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Container(height: 1.2, color: primaryGreen),
              pw.SizedBox(height: 3),

              // CUSTOMER & INVOICE INFO
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: pw.BoxDecoration(
                          color: primaryGreen,
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                        child: pw.Text(
                          'TO',
                          style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 7.5, fontFallback: fallbacks),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        customerName.isEmpty ? 'WALK-IN CUSTOMER' : customerName.toUpperCase(),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, font: fontBold, fontFallback: fallbacks),
                      ),
                      if (customerAddress.isNotEmpty)
                        pw.Text(
                          customerAddress.toUpperCase(),
                          style: pw.TextStyle(fontSize: 7.5, font: fontReg, fontFallback: fallbacks),
                        ),
                      if (customerPhone.isNotEmpty)
                        pw.Text(
                          'PH: $customerPhone',
                          style: pw.TextStyle(fontSize: 7.5, font: fontReg, fontFallback: fallbacks),
                        ),
                      if (customerGst != null && customerGst.isNotEmpty)
                        pw.Text(
                          'GSTIN: $customerGst',
                          style: pw.TextStyle(fontSize: 7.5, font: fontBold, fontFallback: fallbacks),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text('INVOICE NO  :  ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, fontFallback: fallbacks)),
                          pw.Text(sale.invoiceNo, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, fontFallback: fallbacks)),
                        ],
                      ),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        children: [
                          pw.Text('DATE              :  ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, fontFallback: fallbacks)),
                          pw.Text(_formatDate(sale.date), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, fontFallback: fallbacks)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 3),

              // PRODUCT TABLE (DYNAMIC ROWS - ONLY ACTUAL ITEMS)
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.6),
                columnWidths: const {
                  0: pw.FixedColumnWidth(30),  // S.NO
                  1: pw.FlexColumnWidth(1),    // PRODUCTS
                  2: pw.FixedColumnWidth(42),  // QTY
                  3: pw.FixedColumnWidth(60),  // RATE
                  4: pw.FixedColumnWidth(70),  // TOTAL
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: primaryGreen),
                    children: [
                      _buildHeaderCell('S.NO', fontBold, fallbacks),
                      _buildHeaderCell('PRODUCTS', fontBold, fallbacks, align: pw.TextAlign.center),
                      _buildHeaderCell('QTY', fontBold, fallbacks, align: pw.TextAlign.center),
                      _buildHeaderCell('RATE', fontBold, fallbacks, align: pw.TextAlign.center),
                      _buildHeaderCell('TOTAL', fontBold, fallbacks, align: pw.TextAlign.center),
                    ],
                  ),
                  ...items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final pName = productMap[item.productId] ?? 'Item #${item.productId}';
                    final qtyStr = item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString();
                    final rateStr = item.price.toStringAsFixed(0);
                    final totalStr = 'Rs.${item.total.toStringAsFixed(item.total % 1 == 0 ? 0 : 2)}';
                    final isCompact = items.length > 18;

                    return pw.TableRow(
                      children: [
                        _buildDataCell('${index + 1}', fontBold, fallbacks, align: pw.TextAlign.center, isCompact: isCompact),
                        _buildDataCell(pName, fontReg, fallbacks, align: pw.TextAlign.left, padLeft: 6, isCompact: isCompact),
                        _buildDataCell(qtyStr, fontReg, fallbacks, align: pw.TextAlign.center, isCompact: isCompact),
                        _buildDataCell(rateStr, fontReg, fallbacks, align: pw.TextAlign.center, isCompact: isCompact),
                        _buildDataCell(totalStr, fontBold, fallbacks, align: pw.TextAlign.right, padRight: 5, isCompact: isCompact),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: items.length > 18 ? 4 : 8),

              // BOTTOM SECTION
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // BANK DETAILS
                  pw.Expanded(
                    flex: 34,
                    child: pw.Container(
                      height: 68,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: primaryGreen, width: 1),
                        borderRadius: pw.BorderRadius.circular(4),
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
                                topLeft: pw.Radius.circular(3),
                                topRight: pw.Radius.circular(3),
                              ),
                            ),
                            child: pw.Text(
                              'BANK DETAILS',
                              style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 7.5, fontFallback: fallbacks),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                _buildBankRow('A/C NO:', settings.accountNumber, fontBold, fallbacks),
                                _buildBankRow('IFSC:', settings.ifsc, fontBold, fallbacks),
                                _buildBankRow('BRANCH:', settings.branch, fontBold, fallbacks),
                                _buildBankRow('BANK:', settings.bankName, fontBold, fallbacks),
                                _buildBankRow('TYPE:', settings.accountType, fontBold, fallbacks),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 6),

                  // DUAL QR CODES
                  pw.Expanded(
                    flex: 32,
                    child: pw.Container(
                      height: 68,
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          if (_qrPaymentImage != null)
                            pw.Image(_qrPaymentImage!, width: 60, height: 60)
                          else
                            pw.BarcodeWidget(
                              data: 'upi://pay?pa=${settings.phone}@upi&pn=${settings.shopName}',
                              barcode: pw.Barcode.qrCode(),
                              width: 60,
                              height: 60,
                            ),
                          if (_qrLocationImage != null)
                            pw.Image(_qrLocationImage!, width: 60, height: 60)
                          else
                            pw.BarcodeWidget(
                              data: 'https://maps.google.com/?q=${settings.address}',
                              barcode: pw.Barcode.qrCode(),
                              width: 60,
                              height: 60,
                            ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 6),

                  // TOTAL SUMMARY & GRAND TOTAL
                  pw.Expanded(
                    flex: 34,
                    child: pw.Column(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey600, width: 0.8),
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                          child: pw.Column(
                            children: [
                              _buildSummaryRow('TOTAL', 'Rs.${sale.subtotal.toStringAsFixed(2)}', fontBold, fallbacks),
                              _buildSummaryRow('CGST (${sale.cgstRate.toStringAsFixed(1)}%)', 'Rs.${sale.cgstAmount.toStringAsFixed(2)}', fontReg, fallbacks),
                              _buildSummaryRow('SGST (${sale.sgstRate.toStringAsFixed(1)}%)', 'Rs.${sale.sgstAmount.toStringAsFixed(2)}', fontReg, fallbacks),
                              _buildSummaryRow('TOTAL TAX', 'Rs.${sale.gst.toStringAsFixed(2)}', fontBold, fallbacks),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.symmetric(vertical: 3),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: primaryGreen, width: 1.2),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Column(
                            children: [
                              pw.Text(
                                'GRAND TOTAL',
                                style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, font: fontBold, fontFallback: fallbacks),
                              ),
                              pw.Text(
                                'Rs.${sale.grandTotal.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                  fontSize: 13,
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
              pw.SizedBox(height: 10),

              // PRODUCTS WE OFFER BOX & SIGNATURE AREA
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 62,
                    child: _productsWeOfferImage != null
                        ? pw.Transform.translate(
                            offset: const PdfPoint(-6, 6),
                            child: pw.Container(
                              height: 62,
                              alignment: pw.Alignment.centerLeft,
                              child: pw.Image(
                                _productsWeOfferImage!,
                                fit: pw.BoxFit.contain,
                              ),
                            ),
                          )
                        : pw.Container(
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: primaryGreen, width: 1),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Container(
                                  width: double.infinity,
                                  padding: const pw.EdgeInsets.symmetric(vertical: 3.5, horizontal: 8),
                                  decoration: pw.BoxDecoration(
                                    color: primaryGreen,
                                    borderRadius: const pw.BorderRadius.only(
                                      topLeft: pw.Radius.circular(3),
                                      topRight: pw.Radius.circular(3),
                                    ),
                                  ),
                                  child: pw.Text(
                                    'PRODUCTS WE OFFER :',
                                    style: pw.TextStyle(
                                      color: PdfColors.white,
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8.5,
                                      font: fontBold,
                                    ),
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  child: pw.Row(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Expanded(
                                        child: pw.Column(
                                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                                          children: [
                                            _buildOfferBullet('மசாலா வகைகள்', fontBold, fallbacks),
                                            _buildOfferBullet('மசாலா மூலப்பொருட்கள்', fontBold, fallbacks),
                                            _buildOfferBullet('மாவு வகைகள்', fontBold, fallbacks),
                                            _buildOfferBullet('பருப்பு வகைகள்', fontBold, fallbacks),
                                          ],
                                        ),
                                      ),
                                      pw.Expanded(
                                        child: pw.Column(
                                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                                          children: [
                                            _buildOfferBullet('முந்திரி வகைகள்', fontBold, fallbacks),
                                            _buildOfferBullet('உலர் பழ வகைகள்', fontBold, fallbacks),
                                            _buildOfferBullet('வாசனை மசாலா பொருட்கள்', fontBold, fallbacks),
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
                  pw.SizedBox(width: 12),

                  pw.Expanded(
                    flex: 38,
                    child: pw.Container(
                      height: 62,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'FOR ${settings.shopName.isEmpty ? 'MS TRADERS' : settings.shopName.toUpperCase()}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, font: fontBold),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.Column(
                            children: [
                              pw.Container(
                                width: 120,
                                child: pw.Text(
                                  '----------------------------------------',
                                  style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                                  textAlign: pw.TextAlign.center,
                                  maxLines: 1,
                                ),
                              ),
                              pw.SizedBox(height: 1),
                              pw.Text(
                                'AUTHORIZED SIGNATURE',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5, font: fontBold),
                                textAlign: pw.TextAlign.center,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              // FOOTER
              pw.Center(
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('---  ', style: pw.TextStyle(fontSize: 9, color: primaryGreen, fontFallback: fallbacks)),
                    pw.Text(
                      'THANK YOU !!!',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: primaryGreen, font: fontBold, fontFallback: fallbacks),
                    ),
                    pw.Text('  ---', style: pw.TextStyle(fontSize: 9, color: primaryGreen, fontFallback: fallbacks)),
                  ],
                ),
              ),
            ],
      ),
    );

    return await pdf.save();
  }

  /// Auto-saves Invoice PDF quietly to <AppDir>/Invoices/ (default A4 format).
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

  /// Direct Silent Print to printer without opening system print/save dialog.
  static Future<bool> directPrintInvoiceBytes({
    required Uint8List pdfBytes,
    required String invoiceNo,
    Printer? printer,
  }) async {
    try {
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
        // Look for standard physical printer first
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

      // If the only printer found is a virtual "Microsoft Print to PDF" printer,
      // skip Windows "Save Print Output As" dialog because the file is ALREADY auto-saved in Invoices/!
      if (physicalPrinter != null && isVirtualPrinter(physicalPrinter)) {
        return false;
      }

      if (physicalPrinter != null && physicalPrinter.url.isNotEmpty) {
        return await Printing.directPrintPdf(
          printer: physicalPrinter,
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: 'Invoice_$invoiceNo',
        );
      }
    } catch (e) {
      print('Direct print error: $e');
    }
    return false;
  }

  /// Sends PDF bytes to system print layout dialog.
  static Future<void> printInvoiceBytes({
    required Uint8List pdfBytes,
    required String invoiceNo,
  }) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) => pdfBytes,
        name: 'Invoice_$invoiceNo',
      );
    } catch (e) {
      print('Printing layout error: $e');
    }
  }

  /// Legacy helper method: generates, auto-saves to Invoices folder, and opens print dialog.
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

    await printInvoiceBytes(pdfBytes: pdfBytes, invoiceNo: sale.invoiceNo);
  }

  // --- Helper Widgets ---

  static pw.Widget _buildHeaderCell(String text, pw.Font font, List<pw.Font> fallbacks, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
      child: pw.Text(
        text,
        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8, font: font, fontFallback: fallbacks),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildDataCell(String text, pw.Font font, List<pw.Font> fallbacks, {pw.TextAlign align = pw.TextAlign.left, double padLeft = 0, double padRight = 0, bool isCompact = false}) {
    final vPad = isCompact ? 1.4 : 3.5;
    final fSize = isCompact ? 7.6 : 8.5;
    return pw.Padding(
      padding: pw.EdgeInsets.only(top: vPad, bottom: vPad, left: padLeft > 0 ? padLeft : 2, right: padRight > 0 ? padRight : 2),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: fSize, font: font, fontFallback: fallbacks),
        textAlign: align,
        maxLines: 1,
      ),
    );
  }

  static pw.Widget _buildBankRow(String label, String value, pw.Font font, List<pw.Font> fallbacks) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1.5),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 44,
            child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6.5, font: font, fontFallback: fallbacks)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(fontSize: 6.5, font: font, fontFallback: fallbacks), maxLines: 1),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value, pw.Font font, List<pw.Font> fallbacks) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7, font: font, fontFallback: fallbacks)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7, font: font, fontFallback: fallbacks)),
        ],
      ),
    );
  }

  static pw.Widget _buildOfferBullet(String text, pw.Font defaultFont, List<pw.Font> fallbacks) {
    final primaryTamilFont = _tamilFontBold ?? _tamilFontRegular ?? defaultFont;
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text('> ', style: pw.TextStyle(fontSize: 8.5, font: defaultFont, fontWeight: pw.FontWeight.bold)),
          pw.Text(text, style: pw.TextStyle(fontSize: 8.5, font: primaryTamilFont, fontWeight: pw.FontWeight.bold)),
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
}
