import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../utils/app_folder_storage.dart';
import 'widgets/sales_trend_chart.dart';
import 'widgets/top_products_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _trendStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _trendEndDate = DateTime.now();

  DateTime _barStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _barEndDate = DateTime.now();

  // RepaintBoundary keys for chart capture
  final GlobalKey _trendChartKey = GlobalKey();
  final GlobalKey _barChartKey = GlobalKey();

  Future<void> _selectTrendDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _trendStartDate, end: _trendEndDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _trendStartDate = picked.start;
        _trendEndDate = picked.end;
      });
    }
  }

  Future<void> _selectBarDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _barStartDate, end: _barEndDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _barStartDate = picked.start;
        _barEndDate = picked.end;
      });
    }
  }

  /// Captures a widget by its RepaintBoundary key and saves it as a PNG image.
  Future<void> _saveChartAsPng(GlobalKey key, String chartName) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not capture chart. Please try again.'), backgroundColor: Colors.red),
          );
        }
        return;
      }
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = Uint8List.view(byteData.buffer);
      final savedFile = await AppFolderStorage.saveGraphPng(pngBytes, chartName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Graph saved: ${savedFile.path}'),
            backgroundColor: const Color(0xFF00875A),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving graph: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showLowStockDialog(BuildContext context, List<Product> lowStockProducts) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text('Low Quantity Products Alert', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('The following products are at or below their minimum stock threshold:'),
              const SizedBox(height: 12),
              if (lowStockProducts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('All products are sufficiently stocked!')),
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowHeight: 40,
                        dataRowMinHeight: 44,
                        columns: const [
                          DataColumn(label: Text('Code / ID')),
                          DataColumn(label: Text('Product Name')),
                          DataColumn(label: Text('Current Stock')),
                          DataColumn(label: Text('Min Stock')),
                        ],
                        rows: lowStockProducts.map((p) {
                          return DataRow(
                            cells: [
                              DataCell(Text(p.barcode ?? '#${p.productId ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(Text(p.productName, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text('${p.stock} ${p.unit ?? 'pcs'}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                              DataCell(Text('${p.minimumStock}')),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (dialogCtx.mounted && Navigator.canPop(dialogCtx)) Navigator.pop(dialogCtx);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/sk_logo.png',
              height: 32,
              width: 32,
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, stack) => const Icon(Icons.dashboard, color: Color(0xFF00875A), size: 28),
            ),
            const SizedBox(width: 10),
            const Text('Dashboard & Sales Analytics'),
          ],
        ),
      ),
      body: Consumer3<DashboardProvider, SalesProvider, ProductProvider>(
        builder: (context, dashboard, sales, products, child) {
          if (sales.isLoading || products.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final todaySales = dashboard.getTodaySales(sales);
          final weekSales = dashboard.getThisWeekSales(sales);
          final monthSales = dashboard.getMonthlySales(sales);
          final lowStockProducts = dashboard.getLowStockProducts(products);
          final lowStockCount = lowStockProducts.length;

          // Filter sales for Trend Line Chart
          final trendSales = sales.sales.where((s) {
            final d = DateTime.tryParse(s.date);
            if (d == null) return false;
            return d.isAfter(_trendStartDate.subtract(const Duration(seconds: 1))) &&
                d.isBefore(_trendEndDate.add(const Duration(days: 1)));
          }).toList();

          // Filter sales for Product Performance Bar Chart
          final barSales = sales.sales.where((s) {
            final d = DateTime.tryParse(s.date);
            if (d == null) return false;
            return d.isAfter(_barStartDate.subtract(const Duration(seconds: 1))) &&
                d.isBefore(_barEndDate.add(const Duration(days: 1)));
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 4 CLEAN TOP KPI CARDS ──────────────────────────────────
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildKpiCard(
                      context,
                      'Today Sales',
                      '₹${todaySales.toStringAsFixed(2)}',
                      'Revenue today',
                      Icons.today,
                      const Color(0xFF00875A),
                    ),
                    _buildKpiCard(
                      context,
                      'This Week Sales',
                      '₹${weekSales.toStringAsFixed(2)}',
                      'Revenue this week',
                      Icons.date_range,
                      const Color(0xFF0F766E),
                    ),
                    _buildKpiCard(
                      context,
                      'This Month Sales',
                      '₹${monthSales.toStringAsFixed(2)}',
                      'Revenue this month',
                      Icons.calendar_month,
                      const Color(0xFF059669),
                    ),
                    InkWell(
                      onTap: () => _showLowStockDialog(context, lowStockProducts),
                      borderRadius: BorderRadius.circular(12),
                      child: _buildKpiCard(
                        context,
                        'Low Quantity Indicator',
                        '$lowStockCount Products',
                        'Click to view alert items',
                        Icons.warning_amber_rounded,
                        Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── CHART 1: TOTAL SALES TREND (LINE CHART) ──────────────────
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Sales Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.date_range, size: 18),
                                  label: Text('${dateFmt.format(_trendStartDate)} – ${dateFmt.format(_trendEndDate)}'),
                                  onPressed: () => _selectTrendDateRange(context),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.save_alt, size: 16),
                                  label: const Text('Save Graph'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00875A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onPressed: () => _saveChartAsPng(_trendChartKey, 'Sales_Trend_Chart'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        RepaintBoundary(
                          key: _trendChartKey,
                          child: SizedBox(
                            height: 320,
                            width: double.infinity,
                            child: SalesTrendChart(sales: trendSales),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── CHART 2: PRODUCT SALES PERFORMANCE (BAR CHART) ───────────
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Product Sales Performance',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.date_range, size: 18),
                              label: Text('${dateFmt.format(_barStartDate)} – ${dateFmt.format(_barEndDate)}'),
                              onPressed: () => _selectBarDateRange(context),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.save_alt, size: 16),
                              label: const Text('Save Graph'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: () => _saveChartAsPng(_barChartKey, 'Product_Sales_Bar_Chart'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        RepaintBoundary(
                          key: _barChartKey,
                          child: SizedBox(
                            height: 390,
                            width: double.infinity,
                            child: TopProductsChart(
                              sales: barSales,
                              salesProvider: sales,
                              productProvider: products,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiCard(BuildContext context, String title, String value, String? subtext, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E2D) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;
    final titleColor = isDark ? Colors.white60 : Colors.grey.shade600;
    final valueColor = isDark ? Colors.white : const Color(0xFF212121);

    return Container(
      width: 240,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: titleColor)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valueColor),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtext != null && subtext.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtext,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: isDark ? const Color(0xFF34D399) : const Color(0xFF00875A)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
