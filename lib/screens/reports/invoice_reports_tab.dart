import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/invoice_reports_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/invoice_generator.dart';
import '../../utils/reports_pdf_generator.dart';
import '../../utils/reports_excel_generator.dart';
import '../../models/sale.dart';
import '../../models/sale_item.dart';
import '../../models/settings.dart';
import '../../models/report_filter_model.dart';
import '../../database/database_helper.dart';
import 'widgets/invoice_table.dart';
import 'widgets/report_summary_cards.dart';
import 'widgets/report_loading.dart';

class InvoiceReportsTab extends StatefulWidget {
  const InvoiceReportsTab({super.key});

  @override
  State<InvoiceReportsTab> createState() => _InvoiceReportsTabState();
}

class _InvoiceReportsTabState extends State<InvoiceReportsTab> {
  final _searchCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceReportsProvider>().loadData();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _reprintInvoice(Sale sale) async {
    try {
      final provider = context.read<InvoiceReportsProvider>();
      final settings = context.read<SettingsProvider>().settings ?? Settings(
        shopName: 'SK Masala',
        address: '15 Market Street, Coimbatore, TN 641001',
        phone: '0422-2345678',
        gstNumber: '33ABCDE1234F1Z5',
        invoicePrefix: 'INV',
      );

      List<SaleItem> items = sale.saleId != null ? provider.getItemsForSale(sale.saleId!) : [];
      if (items.isEmpty && sale.saleId != null) {
        items = await DatabaseHelper.instance.getSaleItems(sale.saleId!);
      }

      final products = provider.allProducts.isNotEmpty
          ? provider.allProducts
          : await DatabaseHelper.instance.getProducts();

      await InvoiceGenerator.generateAndPrintInvoice(
        sale: sale,
        items: items,
        customerName: sale.customerName ?? 'Walk-in Customer',
        customerPhone: '',
        customerAddress: '',
        settings: settings,
        allProducts: products,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to print invoice: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _viewInvoice(Sale sale) {
    showDialog(
      context: context,
      builder: (ctx) => _InvoiceViewDialog(sale: sale),
    );
  }

  void _confirmDelete(Sale sale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Invoice'),
        content: Text(
          'Delete invoice "${sale.invoiceNo}"?\n\nThis will restore item stock back to inventory.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (ctx.mounted && Navigator.canPop(ctx)) Navigator.pop(ctx);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (ctx.mounted && Navigator.canPop(ctx)) Navigator.pop(ctx);
              await context.read<InvoiceReportsProvider>().deleteSale(sale.saleId!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Invoice ${sale.invoiceNo} deleted.')),
                );
              }
            },
            child: const Text('Delete & Restore Stock'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    final provider = context.read<InvoiceReportsProvider>();
    final settings = context.read<SettingsProvider>().settings;
    if (settings == null) return;

    try {
      final path = await ReportsPdfGenerator.exportInvoiceReportPdf(
        sales: provider.filteredSales,
        settings: settings,
        generatedBy: 'Admin',
        searchQuery: provider.searchQuery,
        paymentMethod: provider.paymentMethodFilter,
        startDate: provider.startDate,
        endDate: provider.endDate,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF saved: $path')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _printReport() async {
    final provider = context.read<InvoiceReportsProvider>();
    final settings = context.read<SettingsProvider>().settings;
    if (settings == null) return;

    await ReportsPdfGenerator.printInvoiceReport(
      sales: provider.filteredSales,
      settings: settings,
      generatedBy: 'Admin',
      searchQuery: provider.searchQuery,
      paymentMethod: provider.paymentMethodFilter,
      startDate: provider.startDate,
      endDate: provider.endDate,
    );
  }

  Future<void> _exportExcel() async {
    final provider = context.read<InvoiceReportsProvider>();
    try {
      final path = await ReportsExcelGenerator.exportInvoicesToExcel(provider.filteredSales);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excel saved: $path')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InvoiceReportsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return const ReportLoading();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Filter Bar ──────────────────────────────────
            _FilterBar(
              searchCtrl: _searchCtrl,
              provider: provider,
              startDate: _startDate,
              endDate: _endDate,
              onSearch: (q) => provider.setSearchQuery(q),
              onCustomerChanged: (id) => provider.setCustomerFilter(id),
              onPaymentChanged: (m) => provider.setPaymentMethodFilter(m),
              onDateRangeChanged: (s, e) {
                setState(() { _startDate = s; _endDate = e; });
                provider.setDateRange(s, e);
              },
              onClearFilters: () {
                _searchCtrl.clear();
                setState(() { _startDate = null; _endDate = null; });
                provider.clearFilters();
              },
              onRefresh: () => provider.loadData(),
              onPrint: _printReport,
              onExportPdf: _exportPdf,
              onExportExcel: _exportExcel,
            ),

            const SizedBox(height: 12),

            // ── KPI Summary Cards ──────────────────────────
            ReportSummaryCards.forInvoices(
              totalInvoices: provider.filteredSales.length,
              totalSales: provider.totalSales,
              totalGst: provider.totalGst,
              avgInvoiceValue: provider.avgInvoiceValue,
              todaySales: provider.todaySales,
              highestInvoiceAmount: provider.highestInvoiceAmount,
            ),

            const SizedBox(height: 12),

            // ── Results count + pagination ─────────────────
            _TableToolbar(provider: provider),

            const SizedBox(height: 8),

            // ── Invoice Table ──────────────────────────────
            Expanded(
              child: InvoiceTable(
                sales: provider.pagedSales,
                selectedIds: provider.selectedSaleIds,
                onToggleSelect: provider.toggleSelection,
                onSelectAll: provider.selectAll,
                onClearSelection: provider.clearSelection,
                onPrint: _reprintInvoice,
                onDelete: _confirmDelete,
                onView: _viewInvoice,
                onClearFilters: () {
                  _searchCtrl.clear();
                  provider.clearFilters();
                },
              ),
            ),

            // ── Pagination ─────────────────────────────────
            if (provider.totalPages > 1)
              _PaginationBar(provider: provider),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Filter Bar
// ─────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final InvoiceReportsProvider provider;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<String> onSearch;
  final ValueChanged<int?> onCustomerChanged;
  final ValueChanged<String> onPaymentChanged;
  final void Function(DateTime?, DateTime?) onDateRangeChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onRefresh;
  final VoidCallback onPrint;
  final VoidCallback onExportPdf;
  final VoidCallback onExportExcel;

  const _FilterBar({
    required this.searchCtrl,
    required this.provider,
    required this.startDate,
    required this.endDate,
    required this.onSearch,
    required this.onCustomerChanged,
    required this.onPaymentChanged,
    required this.onDateRangeChanged,
    required this.onClearFilters,
    required this.onRefresh,
    required this.onPrint,
    required this.onExportPdf,
    required this.onExportExcel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 1150;
          
          Widget searchField() => TextField(
            controller: searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by Invoice No or Customer...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () { searchCtrl.clear(); onSearch(''); },
                    )
                  : null,
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: onSearch,
          );

          Widget customerField() => DropdownButtonFormField<int?>(
            value: provider.customerFilterId,
            decoration: InputDecoration(
              labelText: 'Customer',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('All Customers')),
              ...provider.allCustomers.map((c) => DropdownMenuItem(
                value: c.customerId, child: Text(c.customerName, overflow: TextOverflow.ellipsis))),
            ],
            onChanged: onCustomerChanged,
            isExpanded: true,
          );

          Widget paymentField() => DropdownButtonFormField<String>(
            initialValue: provider.paymentMethodFilter,
            decoration: InputDecoration(
              labelText: 'Payment',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: ['All', 'Cash', 'UPI', 'Card', 'Credit']
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => onPaymentChanged(v ?? 'All'),
          );

          Widget gstField() => DropdownButtonFormField<InvoiceGstFilter>(
            initialValue: provider.invoiceGstFilter,
            decoration: InputDecoration(
              labelText: 'GST Filter',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: InvoiceGstFilter.values
                .map((f) => DropdownMenuItem(value: f, child: Text(f.label, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) => provider.setInvoiceGstFilter(v ?? InvoiceGstFilter.all),
          );

          Widget actionButtons() => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _DateRangeButton(startDate: startDate, endDate: endDate, onChanged: onDateRangeChanged),
                const SizedBox(width: 8),
                _ActionIconBtn(icon: Icons.filter_list_off, tooltip: 'Clear Filters', onTap: onClearFilters),
                const SizedBox(width: 4),
                _ActionIconBtn(icon: Icons.refresh, tooltip: 'Refresh', onTap: onRefresh),
                const SizedBox(width: 8),
                _ExportButton(icon: Icons.print, label: 'Print', color: theme.colorScheme.primary, onTap: onPrint),
                const SizedBox(width: 6),
                _ExportButton(icon: Icons.picture_as_pdf, label: 'PDF', color: Colors.red.shade700, onTap: onExportPdf),
                const SizedBox(width: 6),
                _ExportButton(icon: Icons.table_chart, label: 'Excel', color: Colors.green.shade700, onTap: onExportExcel),
              ],
            ),
          );

          if (isNarrow) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(flex: 3, child: searchField()),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: customerField()),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: paymentField()),
                    const SizedBox(width: 8),
                    Expanded(child: gstField()),
                  ],
                ),
                const SizedBox(height: 8),
                actionButtons(),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: searchField()),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: customerField()),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: paymentField()),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: gstField()),
              const SizedBox(width: 8),
              Expanded(child: actionButtons()),
            ],
          );
        },
      ),
    );
  }
}

class _DateRangeButton extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(DateTime?, DateTime?) onChanged;

  const _DateRangeButton({required this.startDate, required this.endDate, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = (startDate != null && endDate != null)
        ? '${DateFormat('dd/MM/yy').format(startDate!)} - ${DateFormat('dd/MM/yy').format(endDate!)}'
        : 'Date Range';

    return OutlinedButton.icon(
      icon: Icon(Icons.date_range, size: 16, color: isDark ? const Color(0xFF34D399) : const Color(0xFF00875A)),
      label: Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
      onPressed: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: startDate != null && endDate != null
              ? DateTimeRange(start: startDate!, end: endDate!)
              : null,
        );
        if (range != null) {
          onChanged(range.start, range.end.add(const Duration(hours: 23, minutes: 59, seconds: 59)));
        } else if (startDate != null) {
          onChanged(null, null);
        }
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        side: BorderSide(color: isDark ? const Color(0xFF34D399) : const Color(0xFF00875A)),
        backgroundColor: isDark ? const Color(0xFF13281E) : Colors.transparent,
      ),
    );
  }
}

class _ActionIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIconBtn({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
            color: isDark ? const Color(0xFF13281E) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: isDark ? Colors.white70 : Colors.grey.shade600),
        ),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ExportButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 15, color: Colors.white),
      label: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 1,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Table toolbar (count + page indicator)
// ─────────────────────────────────────────────
class _TableToolbar extends StatelessWidget {
  final InvoiceReportsProvider provider;
  const _TableToolbar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '${provider.filteredSales.length} invoice${provider.filteredSales.length != 1 ? 's' : ''} found',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        if (provider.totalPages > 1)
          Text(
            'Page ${provider.currentPage + 1} of ${provider.totalPages}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Pagination Bar
// ─────────────────────────────────────────────
class _PaginationBar extends StatelessWidget {
  final InvoiceReportsProvider provider;
  const _PaginationBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: provider.currentPage > 0 ? () => provider.goToPage(0) : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: provider.currentPage > 0 ? provider.prevPage : null,
          ),
          ...List.generate(provider.totalPages, (i) {
            if (provider.totalPages > 7) {
              final current = provider.currentPage;
              if (i != 0 && i != provider.totalPages - 1 &&
                  (i < current - 2 || i > current + 2)) return const SizedBox.shrink();
            }
            return _PageBtn(
              page: i,
              isActive: i == provider.currentPage,
              onTap: () => provider.goToPage(i),
            );
          }),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: provider.currentPage < provider.totalPages - 1 ? provider.nextPage : null,
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed: provider.currentPage < provider.totalPages - 1
                ? () => provider.goToPage(provider.totalPages - 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final int page;
  final bool isActive;
  final VoidCallback onTap;

  const _PageBtn({required this.page, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).colorScheme.primary : null,
          border: Border.all(color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${page + 1}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.white : null,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Invoice View Dialog
// ─────────────────────────────────────────────
class _InvoiceViewDialog extends StatelessWidget {
  final Sale sale;
  const _InvoiceViewDialog({required this.sale});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'en_IN');
    final date = DateTime.tryParse(sale.date) ?? DateTime.now();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sale.invoiceNo,
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(DateFormat('dd MMM yyyy, hh:mm a').format(date),
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _DetailRow('Customer', sale.customerName ?? 'Walk-in Customer'),
                  _DetailRow('Payment Method', sale.paymentMethod ?? 'Cash'),
                  const Divider(),
                  _DetailRow('Subtotal', '₹${fmt.format(sale.subtotal)}'),
                  _DetailRow('GST', '₹${fmt.format(sale.gst)}'),
                  _DetailRow('Discount', '₹${fmt.format(sale.discount)}'),
                  const Divider(),
                  _DetailRow('Grand Total', '₹${fmt.format(sale.grandTotal)}', bold: true, color: Theme.of(context).colorScheme.primary),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  const Spacer(),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const _DetailRow(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Spacer(),
          Text(value, style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            fontSize: bold ? 15 : 13,
            color: color,
          )),
        ],
      ),
    );
  }
}
