import 'dart:io';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import '../models/sale.dart';
import 'app_folder_storage.dart';

class ReportExporter {
  static Future<String> exportToExcel(List<Sale> sales) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sales Report'];
    excel.setDefaultSheet('Sales Report');

    // Header
    sheetObject.appendRow([
      TextCellValue('Invoice No'),
      TextCellValue('Date'),
      TextCellValue('Payment Method'),
      TextCellValue('Subtotal'),
      TextCellValue('GST'),
      TextCellValue('Grand Total'),
    ]);

    // Data
    for (var sale in sales) {
      sheetObject.appendRow([
        TextCellValue(sale.invoiceNo),
        TextCellValue(DateFormat('dd/MM/yyyy').format(DateTime.parse(sale.date))),
        TextCellValue(sale.paymentMethod ?? 'N/A'),
        DoubleCellValue(sale.subtotal),
        DoubleCellValue(sale.gst),
        DoubleCellValue(sale.grandTotal),
      ]);
    }

    var fileBytes = excel.save();
    if (fileBytes != null) {
      final savedFile = await AppFolderStorage.saveReportExcel(fileBytes, 'SalesReport');
      return savedFile.path;
    }
    return '';
  }

  static Future<String> exportToPDF(List<Sale> sales) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(level: 0, child: pw.Text('SmartBill Sales Report', style: pw.TextStyle(fontSize: 24))),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Invoice No')),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Date')),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Total')),
                  ]
                ),
                ...sales.map((sale) => pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(sale.invoiceNo)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(sale.date)))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Rs. ${sale.grandTotal.toStringAsFixed(2)}')),
                  ]
                ))
              ]
            ),
          ];
        }
      ),
    );

    final pdfBytes = await pdf.save();
    final savedFile = await AppFolderStorage.saveReportPdf(pdfBytes, 'SalesReport');
    return savedFile.path;
  }
}
