import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/sales_analysis_row.dart';
import '../../../models/report_filter_model.dart';
import 'report_empty_state.dart';

/// Dynamic, scrollable, sortable desktop table for Sales Analysis.
class AnalysisTable extends StatefulWidget {
  final List<SalesAnalysisRow> rows;
  final ReportSummary summary;
  final AnalysisOptions options;
  final GroupBy groupBy;
  final VoidCallback onClearFilters;

  const AnalysisTable({
    super.key,
    required this.rows,
    required this.summary,
    required this.options,
    required this.groupBy,
    required this.onClearFilters,
  });

  @override
  State<AnalysisTable> createState() => _AnalysisTableState();
}

class _AnalysisTableState extends State<AnalysisTable> {
  final _numFmt = NumberFormat('#,##0.00', 'en_IN');
  final _qtyFmt = NumberFormat('#,##0.##', 'en_IN');
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) {
      return ReportEmptyState(onClearFilters: widget.onClearFilters);
    }

    final columns = _buildColumns();
    final double tableWidth = columns.fold(0.0, (s, c) => s + c.width);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 2,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                // Sticky header
                _AnalysisHeader(columns: columns, tableWidth: tableWidth),
                // Scrollable body
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: tableWidth,
                        child: Column(
                          children: widget.rows.asMap().entries.map((entry) {
                            final i = entry.key;
                            final row = entry.value;
                            final isHovered = _hoveredIndex == i;
                            final isEven = i.isEven;

                            final rowBg = isHovered
                                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                                : isEven
                                    ? (isDark ? const Color(0xFF13281E) : Colors.white)
                                    : (isDark ? const Color(0xFF1A3528) : const Color(0xFFF0FDF4));

                            return MouseRegion(
                              onEnter: (_) => setState(() => _hoveredIndex = i),
                              onExit: (_) => setState(() => _hoveredIndex = null),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                color: rowBg,
                                height: 44,
                                child: Row(
                                  children: _buildRowCells(i, row, columns, theme, isDark),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
                // Grand total
                _GrandTotalRow(
                  summary: widget.summary,
                  rows: widget.rows,
                  columns: columns,
                  tableWidth: tableWidth,
                  numFmt: _numFmt,
                  qtyFmt: _qtyFmt,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRowCells(int i, SalesAnalysisRow row, List<_ColSpec> cols, ThemeData theme, bool isDark) {
    final cells = <Widget>[];
    final textStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white : const Color(0xFF0F172A));

    for (final col in cols) {
      Widget cell;
      switch (col.id) {
        case 'no':
          cell = _cell('${i + 1}', col.width, align: TextAlign.center, style: textStyle.copyWith(color: Colors.grey.shade600));
          break;
        case 'group':
          cell = _cell(row.groupLabel, col.width, style: textStyle.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary));
          break;
        case 'category':
          cell = _cell(row.categoryName, col.width, style: textStyle.copyWith(color: isDark ? Colors.white70 : Colors.grey.shade800));
          break;
        case 'gstType':
          final isGst = row.gstCategory == 'With GST';
          cell = SizedBox(
            width: col.width,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isGst ? const Color(0xFFE8F5E9) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isGst ? const Color(0xFFA7F3D0) : const Color(0xFFCBD5E1)),
                ),
                child: Text(
                  row.gstCategory,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isGst ? const Color(0xFF047857) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
          break;
        case 'qty':
          cell = _cell(_qtyFmt.format(row.qtySold), col.width, align: TextAlign.right, style: textStyle);
          break;
        case 'sales':
          cell = _cell('₹${_numFmt.format(row.saleAmount)}', col.width, align: TextAlign.right, style: textStyle);
          break;
        case 'gst':
          cell = _cell('₹${_numFmt.format(row.gstAmount)}', col.width, align: TextAlign.right, style: textStyle.copyWith(color: Colors.teal.shade700));
          break;
        case 'discount':
          cell = _cell('₹${_numFmt.format(row.discount)}', col.width, align: TextAlign.right, style: textStyle.copyWith(color: Colors.amber.shade800));
          break;
        case 'purchase':
          cell = _cell('₹${_numFmt.format(row.purchaseCost)}', col.width, align: TextAlign.right, style: textStyle);
          break;
        case 'profit':
          final isPos = row.profit >= 0;
          cell = _cell(
            '₹${_numFmt.format(row.profit)}',
            col.width,
            align: TextAlign.right,
            style: textStyle.copyWith(
              color: isPos ? const Color(0xFF00875A) : Colors.red.shade700,
              fontWeight: FontWeight.w700,
            ),
          );
          break;
        case 'avgPrice':
          cell = _cell('₹${_numFmt.format(row.avgSellingPrice)}', col.width, align: TextAlign.right, style: textStyle);
          break;
        case 'finalAmt':
          cell = _cell(
            '₹${_numFmt.format(row.finalAmount)}',
            col.width,
            align: TextAlign.right,
            style: textStyle.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary),
          );
          break;
        case 'avgProfit':
          cell = _cell('₹${_numFmt.format(row.avgProfit)}', col.width, align: TextAlign.right, style: textStyle);
          break;
        case 'invoices':
          cell = _cell(row.invoiceCount.toString(), col.width, align: TextAlign.center, style: textStyle);
          break;
        default:
          cell = _cell('', col.width, style: textStyle);
      }
      cells.add(cell);
    }
    return cells;
  }

  static Widget _cell(String text, double width, {TextAlign align = TextAlign.left, TextStyle? style}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          text,
          textAlign: align,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: style ?? const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  List<_ColSpec> _buildColumns() {
    final opts = widget.options;
    final groupLabel = _groupLabel(widget.groupBy);

    return [
      _ColSpec('no', '#', 44, TextAlign.center),
      _ColSpec('group', groupLabel, 170, TextAlign.left),
      _ColSpec('category', 'Category', 110, TextAlign.left),
      _ColSpec('gstType', 'GST Context', 105, TextAlign.center),
      if (opts.showQtySold) _ColSpec('qty', 'Qty Sold', 80, TextAlign.right),
      if (opts.showSaleAmount) _ColSpec('sales', 'Sales Amt', 110, TextAlign.right),
      if (opts.showGst) _ColSpec('gst', 'GST', 90, TextAlign.right),
      if (opts.showDiscount) _ColSpec('discount', 'Discount', 90, TextAlign.right),
      if (opts.showPurchaseCost) _ColSpec('purchase', 'Pur. Cost', 100, TextAlign.right),
      if (opts.showProfit) _ColSpec('profit', 'Profit', 100, TextAlign.right),
      if (opts.showAvgSellingPrice) _ColSpec('avgPrice', 'Avg Price', 95, TextAlign.right),
      if (opts.showFinalAmount) _ColSpec('finalAmt', 'Final Amt', 115, TextAlign.right),
      if (opts.showAvgProfit) _ColSpec('avgProfit', 'Avg Profit', 95, TextAlign.right),
      _ColSpec('invoices', 'Invoices', 70, TextAlign.center),
    ];
  }

  String _groupLabel(GroupBy groupBy) {
    switch (groupBy) {
      case GroupBy.product: return 'Product';
      case GroupBy.category: return 'Category';
      case GroupBy.customer: return 'Customer';
      case GroupBy.paymentMethod: return 'Payment';
      case GroupBy.day: return 'Date';
      case GroupBy.week: return 'Week';
      case GroupBy.month: return 'Month';
      case GroupBy.year: return 'Year';
      default: return 'Group';
    }
  }
}

// ─────────────────────────────────────────────
// Column spec
// ─────────────────────────────────────────────
class _ColSpec {
  final String id;
  final String label;
  final double width;
  final TextAlign align;
  _ColSpec(this.id, this.label, this.width, this.align);
}

// ─────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────
class _AnalysisHeader extends StatelessWidget {
  final List<_ColSpec> columns;
  final double tableWidth;

  const _AnalysisHeader({required this.columns, required this.tableWidth});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 44,
      color: isDark ? const Color(0xFF13281E) : const Color(0xFF064E3B),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: Row(
            children: columns.map((c) => SizedBox(
              width: c.width,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  c.label,
                  textAlign: c.align,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            )).toList(),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Grand Total Row
// ─────────────────────────────────────────────
class _GrandTotalRow extends StatelessWidget {
  final ReportSummary summary;
  final List<SalesAnalysisRow> rows;
  final List<_ColSpec> columns;
  final double tableWidth;
  final NumberFormat numFmt;
  final NumberFormat qtyFmt;

  const _GrandTotalRow({
    required this.summary,
    required this.rows,
    required this.columns,
    required this.tableWidth,
    required this.numFmt,
    required this.qtyFmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        color: Color(0xFF047857),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: Row(
            children: columns.map((col) {
              String value = '';
              const bold = TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Colors.white);
              const accent = TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF34D399));

              switch (col.id) {
                case 'no': value = ''; break;
                case 'group': value = 'GRAND TOTAL'; break;
                case 'category': value = '${summary.totalProducts} items'; break;
                case 'qty': value = qtyFmt.format(summary.totalQtySold); break;
                case 'sales': value = '₹${numFmt.format(summary.totalSales)}'; break;
                case 'gst': value = '₹${numFmt.format(summary.totalGst)}'; break;
                case 'discount': value = '₹${numFmt.format(summary.totalDiscount)}'; break;
                case 'purchase': value = '₹${numFmt.format(summary.totalPurchaseCost)}'; break;
                case 'profit': value = '₹${numFmt.format(summary.totalProfit)}'; break;
                case 'avgPrice': value = ''; break;
                case 'finalAmt': value = '₹${numFmt.format(summary.grandTotal)}'; break;
                case 'avgProfit': value = ''; break;
                case 'invoices': value = '${summary.totalInvoices}'; break;
              }

              final isAccent = col.id == 'finalAmt' || col.id == 'profit';

              return SizedBox(
                width: col.width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    value,
                    textAlign: col.align,
                    style: isAccent ? accent : bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
