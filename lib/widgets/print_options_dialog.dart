import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:smartbill/models/sale.dart';
import 'package:smartbill/models/sale_item.dart';
import 'package:smartbill/models/settings.dart';
import 'package:smartbill/models/product.dart';
import 'package:smartbill/utils/invoice_generator.dart';

class PrintOptionsDialog {
  /// Shows Print Options Dialog for Invoices (A4 / A5 radio buttons + Direct Silent Print)
  static void showInvoiceDialog({
    required BuildContext parentContext,
    required Sale sale,
    required List<SaleItem> items,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    String? customerGst,
    required Settings settings,
    required List<Product> allProducts,
  }) {
    String selectedPaperFormat = 'A4';

    showDialog(
      context: parentContext,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF00875A), size: 28),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Invoice Saved Successfully!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invoice #${sale.invoiceNo} has been saved to your "Invoices" folder.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Paper Format for Printing:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2D27) : const Color(0xFFF4F9F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00875A).withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          value: 'A4',
                          groupValue: selectedPaperFormat,
                          activeColor: const Color(0xFF00875A),
                          title: const Text('A4 Paper Format (Default - Standard Sheet)', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text('Full A4 sheet (210 x 297 mm)'),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedPaperFormat = val);
                          },
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        RadioListTile<String>(
                          value: 'A5',
                          groupValue: selectedPaperFormat,
                          activeColor: const Color(0xFF00875A),
                          title: const Text('A5 Paper Format (Compact Sheet)', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text('Half A4 sheet (148 x 210 mm)'),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedPaperFormat = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text('Close (No Hard Copy)'),
                  onPressed: () {
                    if (dialogCtx.mounted && Navigator.canPop(dialogCtx)) {
                      Navigator.pop(dialogCtx);
                    }
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.print),
                  label: const Text('Print Invoice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00875A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () async {
                    if (dialogCtx.mounted && Navigator.canPop(dialogCtx)) {
                      Navigator.pop(dialogCtx);
                    }

                    final format = selectedPaperFormat == 'A5' ? PdfPageFormat.a5 : PdfPageFormat.a4;
                    final pdfBytes = await InvoiceGenerator.buildInvoicePdfBytes(
                      sale: sale,
                      items: items,
                      customerName: customerName,
                      customerPhone: customerPhone,
                      customerAddress: customerAddress,
                      customerGst: customerGst,
                      settings: settings,
                      allProducts: allProducts,
                      pageFormat: format,
                    );

                    bool printed = false;
                    try {
                      printed = await InvoiceGenerator.directPrintInvoiceBytes(
                        pdfBytes: pdfBytes,
                        invoiceNo: sale.invoiceNo,
                      );
                    } catch (e) {
                      debugPrint('Print error: $e');
                    }

                    if (parentContext.mounted) {
                      if (printed) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            content: Text('Invoice sent directly to printer!'),
                            backgroundColor: Color(0xFF00875A),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            content: Text('Invoice saved in "Invoices" folder! Connect a paper printer to print hard copies.'),
                            backgroundColor: Color(0xFF00875A),
                            duration: Duration(seconds: 4),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Shows Print Options Dialog for Reports (A4 / A5 radio buttons + Direct Silent Print)
  static void showReportDialog({
    required BuildContext parentContext,
    required String reportTitle,
    required String reportFilename,
    required Future<Uint8List> Function(PdfPageFormat format) buildPdfBytes,
  }) {
    String selectedPaperFormat = 'A4';

    showDialog(
      context: parentContext,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF00875A), size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$reportTitle Saved!',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report has been generated and saved to your "Reports" folder.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Paper Format for Printing:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2D27) : const Color(0xFFF4F9F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00875A).withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          value: 'A4',
                          groupValue: selectedPaperFormat,
                          activeColor: const Color(0xFF00875A),
                          title: const Text('A4 Paper Format (Default)', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text('Full A4 sheet (210 x 297 mm)'),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedPaperFormat = val);
                          },
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        RadioListTile<String>(
                          value: 'A5',
                          groupValue: selectedPaperFormat,
                          activeColor: const Color(0xFF00875A),
                          title: const Text('A5 Paper Format (Compact)', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text('Half A4 sheet (148 x 210 mm)'),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedPaperFormat = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text('Close (No Hard Copy)'),
                  onPressed: () {
                    if (dialogCtx.mounted && Navigator.canPop(dialogCtx)) {
                      Navigator.pop(dialogCtx);
                    }
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.print),
                  label: const Text('Print Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00875A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () async {
                    if (dialogCtx.mounted && Navigator.canPop(dialogCtx)) {
                      Navigator.pop(dialogCtx);
                    }

                    final format = selectedPaperFormat == 'A5' ? PdfPageFormat.a5 : PdfPageFormat.a4;
                    final pdfBytes = await buildPdfBytes(format);

                    bool printed = false;
                    try {
                      printed = await InvoiceGenerator.directPrintInvoiceBytes(
                        pdfBytes: pdfBytes,
                        invoiceNo: reportFilename,
                      );
                    } catch (e) {
                      debugPrint('Print error: $e');
                    }

                    if (parentContext.mounted) {
                      if (printed) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            content: Text('Report sent directly to printer!'),
                            backgroundColor: Color(0xFF00875A),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            content: Text('Report saved in "Reports" folder! Connect a paper printer to print hard copies.'),
                            backgroundColor: Color(0xFF00875A),
                            duration: Duration(seconds: 4),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
