import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/sales_analysis_row.dart';
import 'package:intl/intl.dart';

/// ERP-style KPI summary cards row.
/// Supports both Invoice and Sales Analysis summaries.
class ReportSummaryCards extends StatelessWidget {
  final List<SummaryCardData> cards;

  const ReportSummaryCards({super.key, required this.cards});

  /// Builds cards for the Sales Analysis summary.
  static ReportSummaryCards forAnalysis(ReportSummary summary) {
    final fmt = NumberFormat('#,##0.00', 'en_IN');
    final qtyFmt = NumberFormat('#,##0.##', 'en_IN');
    return ReportSummaryCards(cards: [
      SummaryCardData(
        label: 'GST Bills (>0%)',
        value: '${summary.gstBillsCount} Bills',
        subtext: 'Sales: ₹${fmt.format(summary.gstBillsSales)}',
        icon: Icons.receipt_long_outlined,
        gradient: const LinearGradient(colors: [Color(0xFF064E3B), Color(0xFF047857)]),
        valueColor: Colors.white,
      ),
      SummaryCardData(
        label: 'Non-GST Bills (0%)',
        value: '${summary.nonGstBillsCount} Bills',
        subtext: 'Sales: ₹${fmt.format(summary.nonGstBillsSales)}',
        icon: Icons.receipt_outlined,
        gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF14B8A6)]),
        valueColor: Colors.white,
      ),
      SummaryCardData(
        label: 'Prods Sold With GST',
        value: '${summary.gstProductsCount} Unique',
        subtext: 'Qty: ${qtyFmt.format(summary.gstProductsQtySold)}',
        icon: Icons.check_circle_outline,
        gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]),
        valueColor: Colors.white,
      ),
      SummaryCardData(
        label: 'Prods Sold W/O GST',
        value: '${summary.nonGstProductsCount} Unique',
        subtext: 'Qty: ${qtyFmt.format(summary.nonGstProductsQtySold)}',
        icon: Icons.remove_circle_outline,
        gradient: const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFF59E0B)]),
        valueColor: Colors.white,
      ),
      SummaryCardData(
        label: 'Total GST Collected',
        value: '₹${fmt.format(summary.totalGst)}',
        icon: Icons.account_balance_outlined,
        gradient: const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF38BDF8)]),
        valueColor: Colors.white,
      ),
      SummaryCardData(
        label: 'Grand Total',
        value: '₹${fmt.format(summary.grandTotal)}',
        icon: Icons.monetization_on_outlined,
        gradient: const LinearGradient(colors: [Color(0xFF022C22), Color(0xFF065F46)]),
        valueColor: const Color(0xFF34D399),
        highlight: true,
      ),
    ]);
  }

  /// Builds cards for the Invoice Reports summary.
  static ReportSummaryCards forInvoices({
    required int totalInvoices,
    required double totalSales,
    required double totalGst,
    required double avgInvoiceValue,
    required double todaySales,
    required double highestInvoiceAmount,
  }) {
    final fmt = NumberFormat('#,##0.00', 'en_IN');
    return ReportSummaryCards(cards: [
      SummaryCardData(
        label: 'Total Invoices',
        value: totalInvoices.toString(),
        icon: Icons.receipt_long_outlined,
        gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]),
        valueColor: Colors.white,
      ),
      SummaryCardData(
        label: 'Total Sales',
        value: '₹${fmt.format(totalSales)}',
        icon: Icons.trending_up,
        gradient: const LinearGradient(colors: [Color(0xFF064E3B), Color(0xFF047857)]),
        valueColor: Colors.white,
      ),
      SummaryCardData(
        label: 'Total GST',
        value: '₹${fmt.format(totalGst)}',
        icon: Icons.account_balance_outlined,
        gradient: const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF38BDF8)]),
        valueColor: Colors.white,
      ),
      SummaryCardData(
        label: 'Avg Invoice',
        value: '₹${fmt.format(avgInvoiceValue)}',
        icon: Icons.bar_chart_outlined,
        gradient: const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFF59E0B)]),
        valueColor: Colors.white,
      ),
      SummaryCardData(
        label: "Today's Sales",
        value: '₹${fmt.format(todaySales)}',
        icon: Icons.today_outlined,
        gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF14B8A6)]),
        valueColor: Colors.white,
      ),
      SummaryCardData(
        label: 'Highest Invoice',
        value: '₹${fmt.format(highestInvoiceAmount)}',
        icon: Icons.emoji_events_outlined,
        gradient: const LinearGradient(colors: [Color(0xFF022C22), Color(0xFF065F46)]),
        valueColor: const Color(0xFF34D399),
        highlight: true,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (cards.length == 6 && constraints.maxWidth < 1350) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 76,
                child: Row(
                  children: [
                    Expanded(child: _SummaryCard(data: cards[0])),
                    Expanded(child: _SummaryCard(data: cards[1])),
                    Expanded(child: _SummaryCard(data: cards[2])),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 76,
                child: Row(
                  children: [
                    Expanded(child: _SummaryCard(data: cards[3])),
                    Expanded(child: _SummaryCard(data: cards[4])),
                    Expanded(child: _SummaryCard(data: cards[5])),
                  ],
                ),
              ),
            ],
          );
        }

        return SizedBox(
          height: 90,
          child: Row(
            children: cards.map((card) => Expanded(
              child: _SummaryCard(data: card),
            )).toList(),
          ),
        );
      },
    );
  }
}

class SummaryCardData {
  final String label;
  final String value;
  final String? subtext;
  final IconData icon;
  final LinearGradient gradient;
  final Color valueColor;
  final bool highlight;

  const SummaryCardData({
    required this.label,
    required this.value,
    this.subtext,
    required this.icon,
    required this.gradient,
    required this.valueColor,
    this.highlight = false,
  });
}

class _SummaryCard extends StatefulWidget {
  final SummaryCardData data;
  const _SummaryCard({required this.data});

  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        transform: _hovered
            ? Matrix4.translationValues(0.0, -3.0, 0.0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          gradient: widget.data.gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: widget.data.gradient.colors.first.withValues(alpha: _hovered ? 0.45 : 0.25),
              blurRadius: _hovered ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.data.icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.data.label,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.data.value,
                      style: GoogleFonts.outfit(
                        fontSize: widget.data.highlight ? 16 : 14.5,
                        fontWeight: FontWeight.w800,
                        color: widget.data.valueColor,
                      ),
                    ),
                  ),
                  if (widget.data.subtext != null && widget.data.subtext!.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      widget.data.subtext!,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
