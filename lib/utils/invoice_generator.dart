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
  static Future<void> generateAndPrintInvoice({
    required Sale sale,
    required List<SaleItem> items,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    String? customerGst,
    required Settings settings,
    required List<Product> allProducts,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(settings.shopName, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                      pw.Text('SK MASALA (Min. Usage Max. Savings)', style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 6),
                      pw.Text(settings.address, style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Cell: ${settings.phone}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('GSTIN: ${settings.gstNumber}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('FSSAI: 22421591000206', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('INVOICE', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#00875A'))),
                      pw.Text('No: ${sale.invoiceNo}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Date: ${_formatDate(sale.date)}'),
                      pw.Text('Payment: ${sale.paymentMethod ?? "Cash"}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 14),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Customer Info Section
              pw.Text('Billed To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.Text(customerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              if (customerAddress.isNotEmpty) pw.Text(customerAddress),
              if (customerPhone.isNotEmpty) pw.Text('Phone: $customerPhone'),
              if (customerGst != null && customerGst.isNotEmpty) pw.Text('GSTIN: $customerGst'),

              pw.SizedBox(height: 16),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FixedColumnWidth(40),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FixedColumnWidth(50),
                  3: const pw.FixedColumnWidth(70),
                  4: const pw.FixedColumnWidth(70),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F0FDF4')),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Sl', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Product Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Price (Rs)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total (Rs)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  // Table Rows
                  ...items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final productList = allProducts.where((p) => p.productId == item.productId);
                    final productName = productList.isNotEmpty ? productList.first.productName : 'Product #${item.productId}';
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${index + 1}')),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(productName)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${item.quantity}', textAlign: pw.TextAlign.right)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.price.toStringAsFixed(2), textAlign: pw.TextAlign.right)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.total.toStringAsFixed(2), textAlign: pw.TextAlign.right)),
                      ],
                    );
                  }),
                ],
              ),
              
              pw.SizedBox(height: 16),

              // Totals Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 250,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Subtotal:'),
                            pw.Text('Rs. ${sale.subtotal.toStringAsFixed(2)}'),
                          ],
                        ),
                        if (sale.discount > 0) ...[
                          pw.SizedBox(height: 3),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Discount:'),
                              pw.Text('- Rs. ${sale.discount.toStringAsFixed(2)}'),
                            ],
                          ),
                        ],
                        pw.SizedBox(height: 3),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Taxable Amount:'),
                            pw.Text('Rs. ${sale.taxableAmount.toStringAsFixed(2)}'),
                          ],
                        ),
                        if (sale.isGstBill) ...[
                          pw.SizedBox(height: 3),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('CGST (${sale.cgstRate.toStringAsFixed(1)}%):'),
                              pw.Text('Rs. ${sale.cgstAmount.toStringAsFixed(2)}'),
                            ],
                          ),
                          pw.SizedBox(height: 3),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('SGST (${sale.sgstRate.toStringAsFixed(1)}%):'),
                              pw.Text('Rs. ${sale.sgstAmount.toStringAsFixed(2)}'),
                            ],
                          ),
                          pw.SizedBox(height: 3),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Total GST (${sale.gstRate.toStringAsFixed(0)}%):'),
                              pw.Text('Rs. ${sale.gst.toStringAsFixed(2)}'),
                            ],
                          ),
                        ] else ...[
                          pw.SizedBox(height: 3),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('GST (0%):'),
                              pw.Text('Rs. 0.00'),
                            ],
                          ),
                        ],
                        pw.Divider(),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Grand Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                            pw.Text('Rs. ${sale.grandTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColor.fromHex('#00875A'))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),
              pw.Divider(),
              pw.Center(
                child: pw.Text('Thank You Visit Again', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColor.fromHex('#00875A'))),
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();

    // Auto-save copy to App storage Invoices folder
    try {
      await AppFolderStorage.saveInvoicePdf(pdfBytes, sale.invoiceNo);
    } catch (_) {}

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Invoice_${sale.invoiceNo}',
    );
  }

  static String _formatDate(String dateStr) {
    if (dateStr.trim().isEmpty) return DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now());
    final parsed = DateTime.tryParse(dateStr);
    if (parsed != null) {
      return DateFormat("dd/MM/yyyy HH:mm").format(parsed);
    }
    try {
      final d = DateFormat("dd/MM/yyyy HH:mm").parse(dateStr);
      return DateFormat("dd/MM/yyyy HH:mm").format(d);
    } catch (_) {}
    try {
      final d2 = DateFormat("dd/MM/yyyy").parse(dateStr);
      return DateFormat("dd/MM/yyyy HH:mm").format(d2);
    } catch (_) {}
    return dateStr;
  }
}
