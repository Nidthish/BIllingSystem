import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../models/sales_analysis_row.dart';
import '../models/report_filter_model.dart';
import '../models/settings.dart';
import 'app_folder_storage.dart';
import 'invoice_generator.dart';

// ─────────────────────────────────────────────────────────────────
// Theme constants for the PDF
// ─────────────────────────────────────────────────────────────────
const _primaryColor = PdfColor.fromInt(0xFF512DA8); // deep purple 700
const _accentColor  = PdfColor.fromInt(0xFFFFA000); // amber 700
const _headerBg     = PdfColor.fromInt(0xFF4527A0); // deep purple 800
const _rowAlt       = PdfColor.fromInt(0xFFF3F4F8);
const _totalRowBg   = PdfColor.fromInt(0xFF311B92); // deep purple 900
const _textDark     = PdfColor.fromInt(0xFF212121);
const _textLight    = PdfColor.fromInt(0xFF757575);
const _borderColor  = PdfColor.fromInt(0xFFCCCCCC);

final _numFmt = NumberFormat('#,##0.00', 'en_IN');
final _qtyFmt = NumberFormat('#,##0.##', 'en_IN');
final _dateFmt = DateFormat('dd-MMM-yyyy');
final _timeFmt = DateFormat('hh:mm a');

// ─────────────────────────────────────────────────────────────────
// Public entry points
// ─────────────────────────────────────────────────────────────────
class ReportsPdfGenerator {

  /// Print the Dashboard Sales report via print dialog and auto-save copy to Reports folder.
  static Future<void> printDashboardReport({
    required double todaySales,
    required double weekSales,
    required double monthSales,
    required int lowStockCount,
    required Settings settings,
    required String generatedBy,
  }) async {
    final bytes = await _buildDashboardPdf(
      todaySales: todaySales,
      weekSales: weekSales,
      monthSales: monthSales,
      lowStockCount: lowStockCount,
      settings: settings,
      generatedBy: generatedBy,
    );
    try {
      await AppFolderStorage.saveReportPdf(Uint8List.fromList(bytes), 'Dashboard_Executive_Report');
    } catch (_) {}

    try {
      await InvoiceGenerator.directPrintInvoiceBytes(
        pdfBytes: Uint8List.fromList(bytes),
        invoiceNo: 'Dashboard_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}',
      );
    } catch (e) {
      print('Printing layout error: $e');
    }
  }

  /// Export Dashboard Sales report to a PDF file in Reports folder.
  static Future<String> exportDashboardPdf({
    required double todaySales,
    required double weekSales,
    required double monthSales,
    required int lowStockCount,
    required Settings settings,
    required String generatedBy,
  }) async {
    final bytes = await _buildDashboardPdf(
      todaySales: todaySales,
      weekSales: weekSales,
      monthSales: monthSales,
      lowStockCount: lowStockCount,
      settings: settings,
      generatedBy: generatedBy,
    );
    final savedFile = await AppFolderStorage.saveReportPdf(Uint8List.fromList(bytes), 'Dashboard_Executive_Report');
    return savedFile.path;
  }

  static Future<List<int>> _buildDashboardPdf({
    required double todaySales,
    required double weekSales,
    required double monthSales,
    required int lowStockCount,
    required Settings settings,
    required String generatedBy,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => _buildPageHeader(settings, 'Dashboard Analytics Executive Report', now, generatedBy, null, null),
        footer: (ctx) => _buildPageFooter(ctx, settings, generatedBy, now),
        build: (ctx) => [
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.teal50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.teal200),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(child: pw.Text('Today Sales: Rs. ${_numFmt.format(todaySales)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: _primaryColor))),
                pw.Expanded(child: pw.Text('This Week Sales: Rs. ${_numFmt.format(weekSales)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: _primaryColor))),
                pw.Expanded(child: pw.Text('This Month Sales: Rs. ${_numFmt.format(monthSales)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: _primaryColor))),
                pw.Expanded(child: pw.Text('Low Stock Alerts: $lowStockCount Items', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: _accentColor), textAlign: pw.TextAlign.right)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          _buildSectionTitle('Executive Summary'),
          pw.SizedBox(height: 8),
          pw.Text(
            'This report summarizes current business metrics, sales trends, and catalog status as of ${DateFormat('dd MMM yyyy hh:mm a').format(now)}.',
            style: const pw.TextStyle(fontSize: 10, color: _textLight),
          ),
          pw.SizedBox(height: 20),
          _buildSignatureSection(),
        ],
      ),
    );

    return Uint8List.fromList(await pdf.save());
  }

  /// Print the Sales Analysis report via the system print dialog and auto-saves copy to Reports folder.
  static Future<void> printSalesAnalysis({
    required List<SalesAnalysisRow> rows,
    required ReportSummary summary,
    required ReportFilterModel filter,
    required Settings settings,
    required String generatedBy,
  }) async {
    final bytes = await _buildSalesAnalysisPdf(
      rows: rows, summary: summary, filter: filter,
      settings: settings, generatedBy: generatedBy,
    );
    try {
      await AppFolderStorage.saveReportPdf(Uint8List.fromList(bytes), 'SalesReport_Analysis');
    } catch (_) {}

    try {
      await InvoiceGenerator.directPrintInvoiceBytes(
        pdfBytes: Uint8List.fromList(bytes),
        invoiceNo: 'SalesAnalysis_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}',
      );
    } catch (e) {
      print('Printing layout error: $e');
    }
  }

  /// Export Sales Analysis report to a PDF file in Reports folder.
  static Future<String> exportSalesAnalysisPdf({
    required List<SalesAnalysisRow> rows,
    required ReportSummary summary,
    required ReportFilterModel filter,
    required Settings settings,
    required String generatedBy,
  }) async {
    final bytes = await _buildSalesAnalysisPdf(
      rows: rows, summary: summary, filter: filter,
      settings: settings, generatedBy: generatedBy,
    );
    final savedFile = await AppFolderStorage.saveReportPdf(Uint8List.fromList(bytes), 'SalesReport_Analysis');
    return savedFile.path;
  }

  /// Print the Invoice Report via the system print dialog and auto-saves copy to Reports folder.
  static Future<void> printInvoiceReport({
    required List<Sale> sales,
    required Settings settings,
    required String generatedBy,
    required String searchQuery,
    required String paymentMethod,
    required DateTime? startDate,
    required DateTime? endDate,
  }) async {
    final bytes = await _buildInvoiceReportPdf(
      sales: sales, settings: settings, generatedBy: generatedBy,
      searchQuery: searchQuery, paymentMethod: paymentMethod,
      startDate: startDate, endDate: endDate,
    );
    try {
      await AppFolderStorage.saveReportPdf(Uint8List.fromList(bytes), 'InvoiceReport');
    } catch (_) {}

    try {
      await InvoiceGenerator.directPrintInvoiceBytes(
        pdfBytes: Uint8List.fromList(bytes),
        invoiceNo: 'InvoiceReport_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}',
      );
    } catch (e) {
      print('Printing layout error: $e');
    }
  }

  /// Export Invoice Report to file in Reports folder.
  static Future<String> exportInvoiceReportPdf({
    required List<Sale> sales,
    required Settings settings,
    required String generatedBy,
    required String searchQuery,
    required String paymentMethod,
    required DateTime? startDate,
    required DateTime? endDate,
  }) async {
    final bytes = await _buildInvoiceReportPdf(
      sales: sales, settings: settings, generatedBy: generatedBy,
      searchQuery: searchQuery, paymentMethod: paymentMethod,
      startDate: startDate, endDate: endDate,
    );
    final savedFile = await AppFolderStorage.saveReportPdf(Uint8List.fromList(bytes), 'InvoiceReport');
    return savedFile.path;
  }

  /// Builds Sales Analysis PDF bytes with pageFormat parameter.
  static Future<Uint8List> buildSalesAnalysisPdfBytes({
    required List<SalesAnalysisRow> rows,
    required ReportSummary summary,
    required ReportFilterModel filter,
    required Settings settings,
    required String generatedBy,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    return _buildSalesAnalysisPdf(
      rows: rows, summary: summary, filter: filter,
      settings: settings, generatedBy: generatedBy,
      pageFormat: pageFormat,
    );
  }

  /// Builds Invoice Report PDF bytes with pageFormat parameter.
  static Future<Uint8List> buildInvoiceReportPdfBytes({
    required List<Sale> sales,
    required Settings settings,
    required String generatedBy,
    required String searchQuery,
    required String paymentMethod,
    required DateTime? startDate,
    required DateTime? endDate,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    return _buildInvoiceReportPdf(
      sales: sales, settings: settings, generatedBy: generatedBy,
      searchQuery: searchQuery, paymentMethod: paymentMethod,
      startDate: startDate, endDate: endDate,
      pageFormat: pageFormat,
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // SALES ANALYSIS PDF BUILDER
  // ─────────────────────────────────────────────────────────────────
  static Future<Uint8List> _buildSalesAnalysisPdf({
    required List<SalesAnalysisRow> rows,
    required ReportSummary summary,
    required ReportFilterModel filter,
    required Settings settings,
    required String generatedBy,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final (startDate, endDate) = filter.effectiveDateRange;

    // Determine visible columns
    final opts = filter.analysisOptions;
    final columns = _buildSalesColumns(filter);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => _buildPageHeader(settings, 'Sales Analysis Report', now, generatedBy, startDate, endDate),
        footer: (ctx) => _buildPageFooter(ctx, settings, generatedBy, now),
        build: (ctx) => [
          pw.SizedBox(height: 8),
          _buildReportInfoSection(now, generatedBy, startDate, endDate, filter.datePreset.label),
          pw.SizedBox(height: 8),
          _buildSummarySection(summary),
          pw.SizedBox(height: 10),
          _buildSectionTitle('Detailed Analysis'),
          pw.SizedBox(height: 4),
          _buildSalesTable(rows, columns, opts),
          pw.SizedBox(height: 4),
          _buildSalesGrandTotal(summary, rows, columns, opts),
          pw.SizedBox(height: 20),
          _buildSignatureSection(),
        ],
      ),
    );

    return Uint8List.fromList(await pdf.save());
  }

  // ─────────────────────────────────────────────────────────────────
  // INVOICE REPORT PDF BUILDER
  // ─────────────────────────────────────────────────────────────────
  static Future<Uint8List> _buildInvoiceReportPdf({
    required List<Sale> sales,
    required Settings settings,
    required String generatedBy,
    required String searchQuery,
    required String paymentMethod,
    required DateTime? startDate,
    required DateTime? endDate,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    final totalSales = sales.fold(0.0, (s, sale) => s + sale.grandTotal);
    final totalGst = sales.fold(0.0, (s, sale) => s + sale.gst);
    final totalDiscount = sales.fold(0.0, (s, sale) => s + sale.discount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => _buildPageHeader(settings, 'Invoice Report', now, generatedBy, startDate, endDate),
        footer: (ctx) => _buildPageFooter(ctx, settings, generatedBy, now),
        build: (ctx) => [
          pw.SizedBox(height: 8),
          _buildReportInfoSection(now, generatedBy, startDate, endDate, paymentMethod != 'All' ? paymentMethod : 'All Payments'),
          pw.SizedBox(height: 8),
          _buildInvoiceSummarySection(sales.length, totalSales, totalGst, totalDiscount),
          pw.SizedBox(height: 10),
          _buildSectionTitle('Invoice List'),
          pw.SizedBox(height: 4),
          _buildInvoiceTable(sales),
          pw.SizedBox(height: 4),
          _buildInvoiceGrandTotal(sales.length, totalSales, totalGst, totalDiscount),
          pw.SizedBox(height: 20),
          _buildSignatureSection(),
        ],
      ),
    );

    return Uint8List.fromList(await pdf.save());
  }

  // ─────────────────────────────────────────────────────────────────
  // PRODUCT MANAGEMENT PDF
  // ─────────────────────────────────────────────────────────────────

  /// Print current product list via system print dialog and auto-saves to Reports/Product Management/.
  static Future<void> printProductList({
    required List<dynamic> products,      // List<Product>
    required List<dynamic> categories,    // List<Category>
    required Settings settings,
    required String generatedBy,
  }) async {
    final bytes = await _buildProductListPdf(
      products: products,
      categories: categories,
      settings: settings,
      generatedBy: generatedBy,
    );
    try {
      await AppFolderStorage.saveProductManagementPdf(Uint8List.fromList(bytes), 'Product_Management_Report');
    } catch (_) {}

    try {
      await InvoiceGenerator.directPrintInvoiceBytes(
        pdfBytes: Uint8List.fromList(bytes),
        invoiceNo: 'ProductList_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}',
      );
    } catch (e) {
      print('Printing layout error: $e');
    }
  }

  /// Export current product list PDF and auto-saves to Reports/Product Management/.
  static Future<String> exportProductListPdf({
    required List<dynamic> products,
    required List<dynamic> categories,
    required Settings settings,
    required String generatedBy,
  }) async {
    final bytes = await _buildProductListPdf(
      products: products,
      categories: categories,
      settings: settings,
      generatedBy: generatedBy,
    );
    final savedFile = await AppFolderStorage.saveProductManagementPdf(
        Uint8List.fromList(bytes), 'Product_Management_Report');
    return savedFile.path;
  }

  /// Builds Product List PDF Bytes for printing/saving with pageFormat parameter.
  static Future<Uint8List> buildProductListPdfBytes({
    required List<dynamic> products,
    required List<dynamic> categories,
    required Settings settings,
    required String generatedBy,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    return Uint8List.fromList(await _buildProductListPdf(
      products: products,
      categories: categories,
      settings: settings,
      generatedBy: generatedBy,
      pageFormat: pageFormat,
    ));
  }

  static Future<List<int>> _buildProductListPdf({
    required List<dynamic> products,
    required List<dynamic> categories,
    required Settings settings,
    required String generatedBy,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    // Build category name lookup
    final catMap = <int, String>{};
    for (final c in categories) {
      final id = (c.categoryId as num?)?.toInt();
      final name = c.categoryName as String?;
      if (id != null && name != null) {
        catMap[id] = name;
      }
    }

    final lowStockCount = products.where((p) {
      final stk = (p.stock as num?)?.toInt() ?? 0;
      final minStk = (p.minimumStock as num?)?.toInt() ?? 0;
      return stk <= minStk;
    }).length;

    final colWidths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(25),   // #
      1: const pw.FixedColumnWidth(55),   // Code / ID
      2: const pw.FixedColumnWidth(130),  // Product Name
      3: const pw.FixedColumnWidth(80),   // Category
      4: const pw.FixedColumnWidth(45),   // Unit
      5: const pw.FixedColumnWidth(40),   // Stock
      6: const pw.FixedColumnWidth(40),   // Min Stock
      7: const pw.FixedColumnWidth(65),   // Buy Price
      8: const pw.FixedColumnWidth(65),   // Sell Price
      9: const pw.FixedColumnWidth(30),   // Status
    };

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => _buildPageHeader(settings, 'Product Management - Current Stock Report', now, generatedBy, null, null),
        footer: (ctx) => _buildPageFooter(ctx, settings, generatedBy, now),
        build: (ctx) => [
          pw.SizedBox(height: 10),
          // Summary row
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.teal50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.teal200),
            ),
            child: pw.Row(
              children: [
                pw.Text('Total Products: ${products.length}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: _primaryColor)),
                pw.SizedBox(width: 30),
                pw.Text('Low Stock Items: $lowStockCount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: _accentColor)),
                pw.SizedBox(width: 30),
                pw.Text('Generated: ${DateFormat('dd MMM yyyy hh:mm a').format(now)}', style: const pw.TextStyle(fontSize: 9, color: _textLight)),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          // Table
          pw.Table(
            border: pw.TableBorder.all(color: _borderColor, width: 0.5),
            columnWidths: colWidths,
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _headerBg),
                children: [
                  _cell('#', bold: true, color: PdfColors.white, align: pw.TextAlign.center, bg: null, fontSize: 7.5),
                  _cell('Code / ID', bold: true, color: PdfColors.white, bg: null, fontSize: 7.5),
                  _cell('Product Name', bold: true, color: PdfColors.white, bg: null, fontSize: 7.5),
                  _cell('Category', bold: true, color: PdfColors.white, bg: null, fontSize: 7.5),
                  _cell('Unit', bold: true, color: PdfColors.white, align: pw.TextAlign.center, bg: null, fontSize: 7.5),
                  _cell('Stock', bold: true, color: PdfColors.white, align: pw.TextAlign.right, bg: null, fontSize: 7.5),
                  _cell('Min Stk', bold: true, color: PdfColors.white, align: pw.TextAlign.right, bg: null, fontSize: 7.5),
                  _cell('Buy Price', bold: true, color: PdfColors.white, align: pw.TextAlign.right, bg: null, fontSize: 7.5),
                  _cell('Sell Price', bold: true, color: PdfColors.white, align: pw.TextAlign.right, bg: null, fontSize: 7.5),
                  _cell('Status', bold: true, color: PdfColors.white, align: pw.TextAlign.center, bg: null, fontSize: 7.5),
                ],
              ),
              // Data rows
              ...products.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                final stk = (p.stock as num?)?.toInt() ?? 0;
                final minStk = (p.minimumStock as num?)?.toInt() ?? 0;
                final isLow = stk <= minStk;
                final bg = isLow ? const PdfColor.fromInt(0xFFFFF3CD) : (i.isEven ? null : _rowAlt);
                final barcode = p.barcode as String?;
                final codeStr = (barcode != null && barcode.isNotEmpty)
                    ? barcode
                    : '#${p.productId ?? '-'}';
                final catId = (p.categoryId as num?)?.toInt();
                final catName = catId != null ? (catMap[catId] ?? 'Unassigned') : 'Unassigned';
                final prodName = (p.productName as String?) ?? 'Unnamed';
                final unitStr = (p.unit as String?) ?? 'pcs';
                final purchasePrice = (p.purchasePrice as num?)?.toDouble() ?? 0.0;
                final sellingPrice = (p.sellingPrice as num?)?.toDouble() ?? 0.0;

                return pw.TableRow(children: [
                  _cell('${i + 1}', align: pw.TextAlign.center, bg: bg, fontSize: 7),
                  _cell(codeStr, bg: bg, fontSize: 7, bold: true),
                  _cell(prodName, bg: bg, fontSize: 7, bold: true),
                  _cell(catName, bg: bg, fontSize: 7),
                  _cell(unitStr, align: pw.TextAlign.center, bg: bg, fontSize: 7),
                  _cell('$stk', align: pw.TextAlign.right, bg: bg, fontSize: 7, color: isLow ? PdfColors.red700 : null, bold: isLow),
                  _cell('$minStk', align: pw.TextAlign.right, bg: bg, fontSize: 7),
                  _cell('Rs. ${_numFmt.format(purchasePrice)}', align: pw.TextAlign.right, bg: bg, fontSize: 7),
                  _cell('Rs. ${_numFmt.format(sellingPrice)}', align: pw.TextAlign.right, bg: bg, fontSize: 7, bold: true),
                  _cell(isLow ? 'LOW' : 'OK', align: pw.TextAlign.center, bg: bg, fontSize: 7, bold: true, color: isLow ? PdfColors.red700 : PdfColors.green800),
                ]);
              }),
            ],
          ),
          pw.SizedBox(height: 16),
          _buildSignatureSection(),
        ],
      ),
    );

    return Uint8List.fromList(await pdf.save());
  }

  // ─────────────────────────────────────────────────────────────────
  // SHARED SECTION BUILDERS
  // ─────────────────────────────────────────────────────────────────

  /// Company header shown at the top of every page.
  static pw.Widget _buildPageHeader(
    Settings settings,
    String reportTitle,
    DateTime now,
    String generatedBy,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    final cleanTitle = reportTitle.replaceAll('—', '-').replaceAll('–', '-');
    final shopName = (settings.shopName.isEmpty || settings.shopName == 'SK Masala') ? 'MS TRADERS' : settings.shopName;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const pw.BoxDecoration(
            color: _headerBg,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    shopName,
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(settings.address, style: const pw.TextStyle(fontSize: 8.5, color: PdfColor(1, 1, 1, 0.8))),
                  pw.Text('Phone: ${settings.phone}${settings.gstNumber.isNotEmpty ? '   GST: ${settings.gstNumber}' : ''}',
                      style: const pw.TextStyle(fontSize: 8.5, color: PdfColor(1, 1, 1, 0.8))),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(cleanTitle,
                      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _accentColor)),
                  pw.SizedBox(height: 2),
                  pw.Text('Generated: ${_dateFmt.format(now)} ${_timeFmt.format(now)}',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColor(1, 1, 1, 0.8))),
                  pw.Text('By: $generatedBy',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColor(1, 1, 1, 0.8))),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
      ],
    );
  }

  /// Footer shown at the bottom of every page.
  static pw.Widget _buildPageFooter(pw.Context ctx, Settings settings, String generatedBy, DateTime now) {
    return pw.Column(
      children: [
        pw.Divider(color: _borderColor, height: 1),
        pw.SizedBox(height: 3),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Generated using SmartBill Billing System  |  Printed by: $generatedBy',
                style: const pw.TextStyle(fontSize: 7, color: _textLight)),
            pw.Text('GST: ${settings.gstNumber}  |  ${_dateFmt.format(now)} ${_timeFmt.format(now)}',
                style: const pw.TextStyle(fontSize: 7, color: _textLight)),
            pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: _primaryColor)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildReportInfoSection(
    DateTime now,
    String generatedBy,
    DateTime? startDate,
    DateTime? endDate,
    String preset,
  ) {
    final rows = <(String, String)>[
      ('Generated On', _dateFmt.format(now)),
      ('Generated At', _timeFmt.format(now)),
      ('Generated By', generatedBy),
      ('Period', preset),
      if (startDate != null) ('Date From', _dateFmt.format(startDate)),
      if (endDate != null) ('Date To', _dateFmt.format(endDate)),
    ];

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        color: PdfColors.grey50,
      ),
      child: pw.Row(
        children: rows.map((r) => pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(r.$1, style: const pw.TextStyle(fontSize: 7, color: _textLight)),
              pw.Text(r.$2, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _textDark)),
            ],
          ),
        )).toList(),
      ),
    );
  }



  static pw.Widget _buildSummarySection(ReportSummary summary) {
    final cards = [
      ('Products', summary.totalProducts.toString(), PdfColors.blue800),
      ('Invoices', summary.totalInvoices.toString(), PdfColors.green800),
      ('Qty Sold', _qtyFmt.format(summary.totalQtySold), PdfColors.orange800),
      ('Total Sales', 'Rs. ${_numFmt.format(summary.totalSales)}', _primaryColor),
      ('Total GST', 'Rs. ${_numFmt.format(summary.totalGst)}', PdfColors.teal800),
      ('Total Profit', 'Rs. ${_numFmt.format(summary.totalProfit)}', PdfColors.indigo800),
      ('Grand Total', 'Rs. ${_numFmt.format(summary.grandTotal)}', _totalRowBg),
    ];

    return pw.Row(
      children: cards.map((c) => pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.symmetric(horizontal: 2),
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: c.$3, width: 1.2),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(c.$1, style: pw.TextStyle(fontSize: 6.5, color: c.$3, fontWeight: pw.FontWeight.bold), maxLines: 1),
              pw.SizedBox(height: 2),
              pw.Text(c.$2, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: c.$3), maxLines: 1),
            ],
          ),
        ),
      )).toList(),
    );
  }

  static pw.Widget _buildInvoiceSummarySection(int count, double total, double gst, double discount) {
    final cards = [
      ('Total Invoices', count.toString(), PdfColors.blue800),
      ('Total Sales', 'Rs. ${_numFmt.format(total)}', _primaryColor),
      ('Total GST', 'Rs. ${_numFmt.format(gst)}', PdfColors.teal800),
      ('Total Discount', 'Rs. ${_numFmt.format(discount)}', PdfColors.orange800),
      ('Avg Invoice', 'Rs. ${_numFmt.format(count > 0 ? total / count : 0)}', PdfColors.indigo800),
    ];
    return pw.Row(
      children: cards.map((c) => pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.symmetric(horizontal: 3),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: c.$3, width: 1.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(c.$1, style: pw.TextStyle(fontSize: 7, color: c.$3)),
              pw.SizedBox(height: 3),
              pw.Text(c.$2, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: c.$3)),
            ],
          ),
        ),
      )).toList(),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const pw.BoxDecoration(
        color: _primaryColor,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(title,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // SALES ANALYSIS TABLE
  // ─────────────────────────────────────────────────────────────────

  static List<_ColDef> _buildSalesColumns(ReportFilterModel filter) {
    final opts = filter.analysisOptions;
    final cols = <_ColDef>[
      _ColDef('#', 20, pw.TextAlign.center),
      _ColDef('Group / Product', 120, pw.TextAlign.left),
      _ColDef('Category', 70, pw.TextAlign.left),
    ];
    if (opts.showQtySold) cols.add(_ColDef('Qty Sold', 50, pw.TextAlign.right));
    if (opts.showSaleAmount) cols.add(_ColDef('Sales Amt', 70, pw.TextAlign.right));
    if (opts.showGst) cols.add(_ColDef('GST', 55, pw.TextAlign.right));
    if (opts.showDiscount) cols.add(_ColDef('Discount', 55, pw.TextAlign.right));
    if (opts.showPurchaseCost) cols.add(_ColDef('Pur. Cost', 65, pw.TextAlign.right));
    if (opts.showProfit) cols.add(_ColDef('Profit', 60, pw.TextAlign.right));
    if (opts.showAvgSellingPrice) cols.add(_ColDef('Avg Price', 60, pw.TextAlign.right));
    if (opts.showFinalAmount) cols.add(_ColDef('Final Amt', 72, pw.TextAlign.right));
    if (opts.showAvgProfit) cols.add(_ColDef('Avg Profit', 60, pw.TextAlign.right));
    cols.add(_ColDef('Invoices', 45, pw.TextAlign.center));
    return cols;
  }

  static pw.Widget _buildSalesTable(
    List<SalesAnalysisRow> rows,
    List<_ColDef> columns,
    AnalysisOptions opts,
  ) {
    if (rows.isEmpty) {
      return pw.Center(
        child: pw.Text('No data found for the selected filters.',
            style: const pw.TextStyle(fontSize: 10, color: _textLight)),
      );
    }

    final colWidths = <int, pw.TableColumnWidth>{};
    for (int i = 0; i < columns.length; i++) {
      colWidths[i] = pw.FixedColumnWidth(columns[i].width);
    }

    return pw.Table(
      border: pw.TableBorder.all(color: _borderColor, width: 0.5),
      columnWidths: colWidths,
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _headerBg),
          children: columns.map((c) => _cell(c.label, bold: true, color: PdfColors.white, align: c.align, bg: null, fontSize: 7.5)).toList(),
        ),
        // Data rows
        ...rows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          final bg = i.isEven ? null : _rowAlt;
          final cells = <pw.Widget>[
            _cell('${i + 1}', align: pw.TextAlign.center, bg: bg, fontSize: 7),
            _cell(row.groupLabel, align: pw.TextAlign.left, bg: bg, bold: true, fontSize: 7),
            _cell(row.categoryName, align: pw.TextAlign.left, bg: bg, fontSize: 7),
          ];
          if (opts.showQtySold) cells.add(_cell(_qtyFmt.format(row.qtySold), align: pw.TextAlign.right, bg: bg, fontSize: 7));
          if (opts.showSaleAmount) cells.add(_cell('Rs. ${_numFmt.format(row.saleAmount)}', align: pw.TextAlign.right, bg: bg, fontSize: 7));
          if (opts.showGst) cells.add(_cell('Rs. ${_numFmt.format(row.gstAmount)}', align: pw.TextAlign.right, bg: bg, fontSize: 7));
          if (opts.showDiscount) cells.add(_cell('Rs. ${_numFmt.format(row.discount)}', align: pw.TextAlign.right, bg: bg, fontSize: 7));
          if (opts.showPurchaseCost) cells.add(_cell('Rs. ${_numFmt.format(row.purchaseCost)}', align: pw.TextAlign.right, bg: bg, fontSize: 7));
          if (opts.showProfit) {
            final profitColor = row.profit >= 0 ? PdfColors.green800 : PdfColors.red800;
            cells.add(_cell('Rs. ${_numFmt.format(row.profit)}', align: pw.TextAlign.right, bg: bg, fontSize: 7, color: profitColor));
          }
          if (opts.showAvgSellingPrice) cells.add(_cell('Rs. ${_numFmt.format(row.avgSellingPrice)}', align: pw.TextAlign.right, bg: bg, fontSize: 7));
          if (opts.showFinalAmount) cells.add(_cell('Rs. ${_numFmt.format(row.finalAmount)}', align: pw.TextAlign.right, bg: bg, bold: true, fontSize: 7));
          if (opts.showAvgProfit) cells.add(_cell('Rs. ${_numFmt.format(row.avgProfit)}', align: pw.TextAlign.right, bg: bg, fontSize: 7));
          cells.add(_cell('${row.invoiceCount}', align: pw.TextAlign.center, bg: bg, fontSize: 7));
          return pw.TableRow(children: cells);
        }),
      ],
    );
  }

  static pw.Widget _buildSalesGrandTotal(ReportSummary summary, List<SalesAnalysisRow> rows, List<_ColDef> cols, AnalysisOptions opts) {
    final cells = <pw.Widget>[
      _cell('TOTAL', align: pw.TextAlign.center, bg: _totalRowBg, bold: true, color: PdfColors.white, fontSize: 8),
      _cell('SUMMARY ALL ROWS', align: pw.TextAlign.left, bg: _totalRowBg, bold: true, color: PdfColors.white, fontSize: 8),
      _cell('-', align: pw.TextAlign.center, bg: _totalRowBg, bold: true, color: PdfColors.white, fontSize: 8),
    ];
    if (opts.showQtySold) cells.add(_cell(_qtyFmt.format(summary.totalQtySold), align: pw.TextAlign.right, bg: _totalRowBg, bold: true, color: PdfColors.white, fontSize: 8));
    if (opts.showSaleAmount) cells.add(_cell('Rs. ${_numFmt.format(summary.totalSales)}', align: pw.TextAlign.right, bg: _totalRowBg, bold: true, color: PdfColors.white, fontSize: 8));
    if (opts.showGst) cells.add(_cell('Rs. ${_numFmt.format(summary.totalGst)}', align: pw.TextAlign.right, bg: _totalRowBg, bold: true, color: PdfColors.white, fontSize: 8));
    if (opts.showDiscount) cells.add(_cell('Rs. ${_numFmt.format(summary.totalDiscount)}', align: pw.TextAlign.right, bg: _totalRowBg, bold: true, color: PdfColors.white, fontSize: 8));
    if (opts.showPurchaseCost) cells.add(_cell('Rs. ${_numFmt.format(summary.totalPurchaseCost)}', align: pw.TextAlign.right, bg: _totalRowBg, bold: true, color: PdfColors.white, fontSize: 8));
    if (opts.showProfit) cells.add(_cell('Rs. ${_numFmt.format(summary.totalProfit)}', align: pw.TextAlign.right, bg: _totalRowBg, bold: true, color: _accentColor, fontSize: 8));
    if (opts.showAvgSellingPrice) cells.add(_cell('', bg: _totalRowBg, color: PdfColors.white, fontSize: 8));
    if (opts.showFinalAmount) cells.add(_cell('Rs. ${_numFmt.format(summary.grandTotal)}', align: pw.TextAlign.right, bg: _totalRowBg, bold: true, color: _accentColor, fontSize: 8));
    if (opts.showAvgProfit) cells.add(_cell('', bg: _totalRowBg, color: PdfColors.white, fontSize: 8));
    cells.add(_cell('${summary.totalInvoices}', align: pw.TextAlign.center, bg: _totalRowBg, bold: true, color: PdfColors.white, fontSize: 8));

    final colWidths = <int, pw.TableColumnWidth>{};
    for (int i = 0; i < cols.length; i++) {
      colWidths[i] = pw.FixedColumnWidth(cols[i].width);
    }

    return pw.Table(
      border: pw.TableBorder.all(color: _borderColor, width: 0.5),
      columnWidths: colWidths,
      children: [pw.TableRow(children: cells)],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // INVOICE TABLE
  // ─────────────────────────────────────────────────────────────────

  static pw.Widget _buildInvoiceTable(List<Sale> sales) {
    final colWidths = {
      0: const pw.FixedColumnWidth(30),
      1: const pw.FixedColumnWidth(80),
      2: const pw.FixedColumnWidth(70),
      3: const pw.FlexColumnWidth(2.0),
      4: const pw.FixedColumnWidth(70),
      5: const pw.FixedColumnWidth(75),
      6: const pw.FixedColumnWidth(60),
      7: const pw.FixedColumnWidth(75),
      8: const pw.FixedColumnWidth(80),
    };

    return pw.Table(
      border: pw.TableBorder.all(color: _borderColor, width: 0.5),
      columnWidths: colWidths,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _headerBg),
          children: [
            _cell('#', bold: true, color: PdfColors.white, align: pw.TextAlign.center, bg: null, fontSize: 7.5),
            _cell('Invoice No', bold: true, color: PdfColors.white, bg: null, fontSize: 7.5),
            _cell('Date', bold: true, color: PdfColors.white, bg: null, fontSize: 7.5),
            _cell('Customer', bold: true, color: PdfColors.white, bg: null, fontSize: 7.5),
            _cell('Payment', bold: true, color: PdfColors.white, align: pw.TextAlign.center, bg: null, fontSize: 7.5),
            _cell('Subtotal', bold: true, color: PdfColors.white, align: pw.TextAlign.right, bg: null, fontSize: 7.5),
            _cell('GST', bold: true, color: PdfColors.white, align: pw.TextAlign.right, bg: null, fontSize: 7.5),
            _cell('Discount', bold: true, color: PdfColors.white, align: pw.TextAlign.right, bg: null, fontSize: 7.5),
            _cell('Grand Total', bold: true, color: PdfColors.white, align: pw.TextAlign.right, bg: null, fontSize: 7.5),
          ],
        ),
        ...sales.asMap().entries.map((entry) {
          final i = entry.key;
          final sale = entry.value;
          final bg = i.isEven ? null : _rowAlt;
          final dateStr = _dateFmt.format(DateTime.tryParse(sale.date) ?? DateTime.now());
          return pw.TableRow(children: [
            _cell('${i + 1}', align: pw.TextAlign.center, bg: bg, fontSize: 7),
            _cell(sale.invoiceNo, bold: true, bg: bg, fontSize: 7),
            _cell(dateStr, bg: bg, fontSize: 7),
            _cell(sale.customerName ?? 'Walk-in', bg: bg, fontSize: 7),
            _cell(sale.paymentMethod ?? 'Cash', align: pw.TextAlign.center, bg: bg, fontSize: 7),
            _cell('Rs. ${_numFmt.format(sale.subtotal)}', align: pw.TextAlign.right, bg: bg, fontSize: 7),
            _cell('Rs. ${_numFmt.format(sale.gst)}', align: pw.TextAlign.right, bg: bg, fontSize: 7),
            _cell('Rs. ${_numFmt.format(sale.discount)}', align: pw.TextAlign.right, bg: bg, fontSize: 7),
            _cell('Rs. ${_numFmt.format(sale.grandTotal)}', align: pw.TextAlign.right, bg: bg, bold: true, fontSize: 7),
          ]);
        }),
      ],
    );
  }

  static pw.Widget _buildInvoiceGrandTotal(int count, double total, double gst, double discount) {
    const colWidths = {
      0: pw.FixedColumnWidth(30),
      1: pw.FixedColumnWidth(80),
      2: pw.FixedColumnWidth(70),
      3: pw.FlexColumnWidth(2.0),
      4: pw.FixedColumnWidth(70),
      5: pw.FixedColumnWidth(75),
      6: pw.FixedColumnWidth(60),
      7: pw.FixedColumnWidth(75),
      8: pw.FixedColumnWidth(80),
    };
    return pw.Table(
      border: pw.TableBorder.all(color: _borderColor, width: 0.5),
      columnWidths: colWidths,
      children: [
        pw.TableRow(children: [
          _cell('$count', align: pw.TextAlign.center, bg: _totalRowBg, bold: true, color: PdfColors.white, fontSize: 8),
          _cell('TOTAL', bg: _totalRowBg, bold: true, color: PdfColors.white, fontSize: 8),
          _cell('', bg: _totalRowBg, color: PdfColors.white, fontSize: 8),
          _cell('', bg: _totalRowBg, color: PdfColors.white, fontSize: 8),
          _cell('', bg: _totalRowBg, color: PdfColors.white, fontSize: 8),
          _cell('Rs. ${_numFmt.format(total - gst)}', align: pw.TextAlign.right, bg: _totalRowBg, bold: true, color: PdfColors.white, fontSize: 8),
          _cell('Rs. ${_numFmt.format(gst)}', align: pw.TextAlign.right, bg: _totalRowBg, bold: true, color: PdfColors.white, fontSize: 8),
          _cell('Rs. ${_numFmt.format(discount)}', align: pw.TextAlign.right, bg: _totalRowBg, bold: true, color: PdfColors.white, fontSize: 8),
          _cell('Rs. ${_numFmt.format(total)}', align: pw.TextAlign.right, bg: _totalRowBg, bold: true, color: _accentColor, fontSize: 8),
        ]),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // SIGNATURE SECTION
  // ─────────────────────────────────────────────────────────────────

  static pw.Widget _buildSignatureSection() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        children: ['Prepared By', 'Verified By', 'Approved By'].map((label) => pw.Expanded(
          child: pw.Column(
            children: [
              pw.SizedBox(height: 30),
              pw.Divider(color: _primaryColor, height: 1),
              pw.SizedBox(height: 4),
              pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _textLight),
                  textAlign: pw.TextAlign.center),
            ],
          ),
        )).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // UTILITY
  // ─────────────────────────────────────────────────────────────────

  static pw.Widget _cell(
    String text, {
    bool bold = false,
    PdfColor? color,
    PdfColor? bg,
    pw.TextAlign align = pw.TextAlign.left,
    double fontSize = 8,
  }) {
    return pw.Container(
      color: bg,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? _textDark,
        ),
      ),
    );
  }
}

class _ColDef {
  final String label;
  final double width;
  final pw.TextAlign align;
  _ColDef(this.label, this.width, this.align);
}
