import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../models/sales_analysis_row.dart';
import '../models/report_filter_model.dart';

/// Generates Excel exports for Invoice and Sales Analysis reports.
/// Architecture is ready for CSV support as well.
class ReportsExcelGenerator {

  static final _dateFmt = DateFormat('dd/MM/yyyy');

  // ── Invoice Excel ──────────────────────────────────────────────

  static Future<String> exportInvoicesToExcel(List<Sale> sales) async {
    final excel = Excel.createExcel();
    final sheet = excel['Invoice Report'];
    excel.setDefaultSheet('Invoice Report');

    // Header row
    final headers = [
      'Invoice No', 'Date', 'Customer', 'Payment Method',
      'Subtotal', 'GST', 'Discount', 'Grand Total',
    ];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    // Data rows
    for (final sale in sales) {
      sheet.appendRow([
        TextCellValue(sale.invoiceNo),
        TextCellValue(_dateFmt.format(DateTime.tryParse(sale.date) ?? DateTime.now())),
        TextCellValue(sale.customerName ?? 'Walk-in Customer'),
        TextCellValue(sale.paymentMethod ?? 'Cash'),
        DoubleCellValue(sale.subtotal),
        DoubleCellValue(sale.gst),
        DoubleCellValue(sale.discount),
        DoubleCellValue(sale.grandTotal),
      ]);
    }

    // Totals row
    sheet.appendRow([
      TextCellValue('TOTAL'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      DoubleCellValue(sales.fold(0.0, (s, sale) => s + sale.subtotal)),
      DoubleCellValue(sales.fold(0.0, (s, sale) => s + sale.gst)),
      DoubleCellValue(sales.fold(0.0, (s, sale) => s + sale.discount)),
      DoubleCellValue(sales.fold(0.0, (s, sale) => s + sale.grandTotal)),
    ]);

    return _save(excel, 'SmartBill_InvoiceReport');
  }

  // ── Sales Analysis Excel ───────────────────────────────────────

  static Future<String> exportAnalysisToExcel({
    required List<SalesAnalysisRow> rows,
    required ReportFilterModel filter,
    required ReportSummary summary,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sales Analysis'];
    excel.setDefaultSheet('Sales Analysis');

    final opts = filter.analysisOptions;

    // Build dynamic header
    final headers = <TextCellValue>[
      TextCellValue('#'),
      TextCellValue('Group / Product'),
      TextCellValue('Category'),
    ];
    if (opts.showQtySold) headers.add(TextCellValue('Qty Sold'));
    if (opts.showSaleAmount) headers.add(TextCellValue('Sales Amount'));
    if (opts.showGst) headers.add(TextCellValue('GST Amount'));
    if (opts.showDiscount) headers.add(TextCellValue('Discount'));
    if (opts.showPurchaseCost) headers.add(TextCellValue('Purchase Cost'));
    if (opts.showProfit) headers.add(TextCellValue('Profit'));
    if (opts.showAvgSellingPrice) headers.add(TextCellValue('Avg Selling Price'));
    if (opts.showFinalAmount) headers.add(TextCellValue('Final Amount'));
    if (opts.showAvgProfit) headers.add(TextCellValue('Avg Profit'));
    headers.add(TextCellValue('Invoice Count'));

    sheet.appendRow(headers);

    // Data rows
    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final cells = <CellValue>[
        IntCellValue(i + 1),
        TextCellValue(row.groupLabel),
        TextCellValue(row.categoryName),
      ];
      if (opts.showQtySold) cells.add(DoubleCellValue(row.qtySold));
      if (opts.showSaleAmount) cells.add(DoubleCellValue(row.saleAmount));
      if (opts.showGst) cells.add(DoubleCellValue(row.gstAmount));
      if (opts.showDiscount) cells.add(DoubleCellValue(row.discount));
      if (opts.showPurchaseCost) cells.add(DoubleCellValue(row.purchaseCost));
      if (opts.showProfit) cells.add(DoubleCellValue(row.profit));
      if (opts.showAvgSellingPrice) cells.add(DoubleCellValue(row.avgSellingPrice));
      if (opts.showFinalAmount) cells.add(DoubleCellValue(row.finalAmount));
      if (opts.showAvgProfit) cells.add(DoubleCellValue(row.avgProfit));
      cells.add(IntCellValue(row.invoiceCount));
      sheet.appendRow(cells);
    }

    // Grand total row
    final totalCells = <CellValue>[
      TextCellValue(''),
      TextCellValue('GRAND TOTAL'),
      TextCellValue(''),
    ];
    if (opts.showQtySold) totalCells.add(DoubleCellValue(summary.totalQtySold));
    if (opts.showSaleAmount) totalCells.add(DoubleCellValue(summary.totalSales));
    if (opts.showGst) totalCells.add(DoubleCellValue(summary.totalGst));
    if (opts.showDiscount) totalCells.add(DoubleCellValue(summary.totalDiscount));
    if (opts.showPurchaseCost) totalCells.add(DoubleCellValue(summary.totalPurchaseCost));
    if (opts.showProfit) totalCells.add(DoubleCellValue(summary.totalProfit));
    if (opts.showAvgSellingPrice) totalCells.add(TextCellValue(''));
    if (opts.showFinalAmount) totalCells.add(DoubleCellValue(summary.grandTotal));
    if (opts.showAvgProfit) totalCells.add(TextCellValue(''));
    totalCells.add(IntCellValue(summary.totalInvoices));
    sheet.appendRow(totalCells);

    return _save(excel, 'SmartBill_SalesAnalysis');
  }

  static Future<String> _save(Excel excel, String baseName) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = '${baseName}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = p.join(dir.path, fileName);
    final fileBytes = excel.save();
    if (fileBytes != null) {
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
    }
    return filePath;
  }
}
