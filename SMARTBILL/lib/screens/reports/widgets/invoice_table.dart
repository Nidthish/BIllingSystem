import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/sale.dart';
import 'report_empty_state.dart';

/// Professional desktop DataTable for Invoice Reports.
class InvoiceTable extends StatefulWidget {
  final List<Sale> sales;
  final Set<int> selectedIds;
  final void Function(int saleId) onToggleSelect;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final void Function(Sale sale) onPrint;
  final void Function(Sale sale) onDelete;
  final void Function(Sale sale) onView;
  final VoidCallback onClearFilters;

  const InvoiceTable({
    super.key,
    required this.sales,
    required this.selectedIds,
    required this.onToggleSelect,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onPrint,
    required this.onDelete,
    required this.onView,
    required this.onClearFilters,
  });

  @override
  State<InvoiceTable> createState() => _InvoiceTableState();
}

class _InvoiceTableState extends State<InvoiceTable> {
  final _numFmt = NumberFormat('#,##0.00', 'en_IN');
  final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

  int? _sortColumnIndex;
  bool _sortAscending = true;
  int? _hoveredIndex;

  List<Sale> _sorted() {
    final list = [...widget.sales];
    if (_sortColumnIndex == null) return list;
    list.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 0: cmp = a.invoiceNo.compareTo(b.invoiceNo); break;
        case 1: cmp = a.date.compareTo(b.date); break;
        case 2: cmp = (a.customerName ?? '').compareTo(b.customerName ?? ''); break;
        case 3: cmp = (a.paymentMethod ?? '').compareTo(b.paymentMethod ?? ''); break;
        case 4: cmp = a.subtotal.compareTo(b.subtotal); break;
        case 5: cmp = a.gst.compareTo(b.gst); break;
        case 6: cmp = a.grandTotal.compareTo(b.grandTotal); break;
        default: cmp = 0;
      }
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sales.isEmpty) {
      return ReportEmptyState(onClearFilters: widget.onClearFilters);
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sorted = _sorted();
    final allSelected = widget.selectedIds.length == widget.sales.length && widget.sales.isNotEmpty;

    return Column(
      children: [
        // Selection toolbar
        if (widget.selectedIds.isNotEmpty)
          _SelectionToolbar(
            count: widget.selectedIds.length,
            onSelectAll: widget.onSelectAll,
            onClear: widget.onClearSelection,
          ),

        Expanded(
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 2,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                // Table header
                _TableHeader(
                  allSelected: allSelected,
                  onSelectAll: allSelected ? widget.onClearSelection : widget.onSelectAll,
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  onSort: (col, asc) => setState(() {
                    _sortColumnIndex = col;
                    _sortAscending = asc;
                  }),
                ),
                // Table body
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 1100,
                        child: Column(
                          children: sorted.asMap().entries.map((entry) {
                            final i = entry.key;
                            final sale = entry.value;
                            final isSelected = widget.selectedIds.contains(sale.saleId);
                            final isHovered = _hoveredIndex == i;
                            final isEven = i.isEven;

                            Color rowBg;
                            if (isSelected) {
                              rowBg = theme.colorScheme.primary.withValues(alpha: 0.15);
                            } else if (isHovered) {
                              rowBg = theme.colorScheme.primary.withValues(alpha: 0.08);
                            } else if (isEven) {
                              rowBg = isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white;
                            } else {
                              rowBg = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF0FDF4);
                            }

                            return MouseRegion(
                              onEnter: (_) => setState(() => _hoveredIndex = i),
                              onExit: (_) => setState(() => _hoveredIndex = null),
                              child: GestureDetector(
                                onTap: () {
                                  if (sale.saleId != null) widget.onToggleSelect(sale.saleId!);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 120),
                                  color: rowBg,
                                  child: SizedBox(
                                    height: 46,
                                    child: Row(
                                      children: [
                                        // Checkbox
                                        SizedBox(
                                          width: 48,
                                          child: Checkbox(
                                            value: isSelected,
                                            onChanged: (_) {
                                              if (sale.saleId != null) widget.onToggleSelect(sale.saleId!);
                                            },
                                            activeColor: theme.colorScheme.primary,
                                          ),
                                        ),
                                        // Invoice No
                                        SizedBox(
                                          width: 130,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text(
                                              sale.invoiceNo,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Date
                                        SizedBox(
                                          width: 140,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text(
                                              _dateFmt.format(DateTime.tryParse(sale.date) ?? DateTime.now()),
                                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ),
                                        // Customer
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text(
                                              sale.customerName ?? 'Walk-in Customer',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                         // Payment & GST Type
                                         SizedBox(
                                           width: 140,
                                           child: Row(
                                             mainAxisAlignment: MainAxisAlignment.center,
                                             children: [
                                               _PaymentChip(method: sale.paymentMethod ?? 'Cash'),
                                               const SizedBox(width: 4),
                                               Container(
                                                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                 decoration: BoxDecoration(
                                                   color: sale.isGstBill ? const Color(0xFFE8F5E9) : const Color(0xFFF1F5F9),
                                                   borderRadius: BorderRadius.circular(4),
                                                   border: Border.all(color: sale.isGstBill ? const Color(0xFFA7F3D0) : const Color(0xFFCBD5E1)),
                                                 ),
                                                 child: Text(
                                                   sale.isGstBill ? 'GST ${sale.gstRate.toStringAsFixed(0)}%' : 'Non-GST',
                                                   style: TextStyle(
                                                     fontSize: 10,
                                                     fontWeight: FontWeight.bold,
                                                     color: sale.isGstBill ? const Color(0xFF047857) : const Color(0xFF64748B),
                                                   ),
                                                 ),
                                               ),
                                             ],
                                           ),
                                         ),
                                        // Subtotal
                                        SizedBox(
                                          width: 105,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text(
                                              '₹${_numFmt.format(sale.subtotal)}',
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ),
                                        // GST
                                        SizedBox(
                                          width: 90,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text(
                                              '₹${_numFmt.format(sale.gst)}',
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.teal.shade700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Grand Total
                                        SizedBox(
                                          width: 115,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text(
                                              '₹${_numFmt.format(sale.grandTotal)}',
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Actions
                                        SizedBox(
                                          width: 160,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              _ActionBtn(
                                                icon: Icons.visibility_outlined,
                                                tooltip: 'View',
                                                color: Colors.blue,
                                                onTap: () => widget.onView(sale),
                                              ),
                                              _ActionBtn(
                                                icon: Icons.print_outlined,
                                                tooltip: 'Print',
                                                color: const Color(0xFF00875A),
                                                onTap: () => widget.onPrint(sale),
                                              ),
                                              _ActionBtn(
                                                icon: Icons.delete_outline,
                                                tooltip: 'Delete',
                                                color: Colors.red,
                                                onTap: () => widget.onDelete(sale),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
                // Grand total footer row
                _InvoiceTotalRow(sales: sorted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Table Header
// ─────────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  final bool allSelected;
  final VoidCallback onSelectAll;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int col, bool asc) onSort;

  const _TableHeader({
    required this.allSelected,
    required this.onSelectAll,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF13281E) : const Color(0xFF064E3B);

    Widget hCol(String label, int colIdx, double width, {TextAlign align = TextAlign.left}) {
      final isActive = sortColumnIndex == colIdx;
      return GestureDetector(
        onTap: () => onSort(colIdx, isActive ? !sortAscending : true),
        child: SizedBox(
          width: width,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: align == TextAlign.right ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 4),
                  Icon(
                    sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: const Color(0xFF34D399),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: bg,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1100,
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Checkbox(
                  value: allSelected,
                  onChanged: (_) => onSelectAll(),
                  activeColor: const Color(0xFF34D399),
                  checkColor: Colors.black,
                  side: const BorderSide(color: Colors.white54),
                ),
              ),
              hCol('Invoice No', 0, 130),
              hCol('Date & Time', 1, 140),
              Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('Customer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              )),
              hCol('Payment', 3, 100),
              hCol('Subtotal', 4, 105, align: TextAlign.right),
              hCol('GST', 5, 90, align: TextAlign.right),
              hCol('Grand Total', 6, 115, align: TextAlign.right),
              const SizedBox(width: 160, child: Center(child: Text('Actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)))),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Grand total footer
// ─────────────────────────────────────────────
class _InvoiceTotalRow extends StatelessWidget {
  final List<Sale> sales;
  const _InvoiceTotalRow({required this.sales});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'en_IN');
    final totalSubtotal = sales.fold(0.0, (s, sale) => s + sale.subtotal);
    final totalGst = sales.fold(0.0, (s, sale) => s + sale.gst);
    final grandTotal = sales.fold(0.0, (s, sale) => s + sale.grandTotal);

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFF047857),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1100,
          child: Row(
            children: [
              const SizedBox(width: 48),
              const SizedBox(
                width: 130,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('TOTAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5)),
                ),
              ),
              const SizedBox(width: 140),
              const Expanded(child: SizedBox()),
              const SizedBox(width: 100),
              SizedBox(
                width: 105,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('₹${fmt.format(totalSubtotal)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
              ),
              SizedBox(
                width: 90,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('₹${fmt.format(totalGst)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
              ),
              SizedBox(
                width: 115,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('₹${fmt.format(grandTotal)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w900, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 160),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Selection Toolbar
// ─────────────────────────────────────────────
class _SelectionToolbar extends StatelessWidget {
  final int count;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;

  const _SelectionToolbar({
    required this.count,
    required this.onSelectAll,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_box_outlined, color: Theme.of(context).colorScheme.primary, size: 18),
          const SizedBox(width: 8),
          Text('$count invoice${count != 1 ? 's' : ''} selected',
            style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
          const Spacer(),
          TextButton(onPressed: onSelectAll, child: const Text('Select All')),
          const SizedBox(width: 8),
          TextButton(onPressed: onClear, child: const Text('Clear Selection')),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Payment chip
// ─────────────────────────────────────────────
class _PaymentChip extends StatelessWidget {
  final String method;
  const _PaymentChip({required this.method});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (method.toUpperCase()) {
      'CASH'   => (const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
      'UPI'    => (const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
      'CARD'   => (const Color(0xFFFCE4EC), const Color(0xFFC62828)),
      'CREDIT' => (const Color(0xFFFFF8E1), const Color(0xFFE65100)),
      _        => (const Color(0xFFF3E5F5), const Color(0xFF6A1B9A)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(method, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ─────────────────────────────────────────────
// Action icon button
// ─────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.tooltip, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
