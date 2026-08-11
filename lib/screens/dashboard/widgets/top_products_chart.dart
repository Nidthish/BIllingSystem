import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/sale.dart';
import '../../../providers/sales_provider.dart';
import '../../../providers/product_provider.dart';

enum _BarMode { revenue, quantity }

class TopProductsChart extends StatefulWidget {
  final List<Sale> sales;
  final SalesProvider salesProvider;
  final ProductProvider productProvider;

  const TopProductsChart({
    super.key,
    required this.sales,
    required this.salesProvider,
    required this.productProvider,
  });

  @override
  State<TopProductsChart> createState() => _TopProductsChartState();
}

class _TopProductsChartState extends State<TopProductsChart>
    with SingleTickerProviderStateMixin {
  _BarMode _mode = _BarMode.revenue;
  int? _hoveredIndex;
  late AnimationController _animCtrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _anim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void didUpdateWidget(covariant TopProductsChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-animate when data or mode changes
    if (oldWidget.sales != widget.sales) {
      _animCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ── Aggregate data ──────────────────────────────────────────────
    final Map<int, double> revenueMap = {};
    final Map<int, double> qtyMap = {};

    for (final p in widget.productProvider.products) {
      if (p.productId != null) {
        revenueMap[p.productId!] = 0.0;
        qtyMap[p.productId!] = 0.0;
      }
    }

    for (final sale in widget.sales) {
      if (sale.saleId == null) continue;
      for (final item in widget.salesProvider.getItemsForSale(sale.saleId!)) {
        revenueMap[item.productId] = (revenueMap[item.productId] ?? 0) + item.total;
        qtyMap[item.productId] = (qtyMap[item.productId] ?? 0) + item.quantity;
      }
    }

    final useMap = _mode == _BarMode.revenue ? revenueMap : qtyMap;
    final sorted = useMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = sorted.take(12).toList();

    // ── Colours ─────────────────────────────────────────────────────
    final revenueGradient = [const Color(0xFF7C3AED), const Color(0xFF6D28D9)];
    final qtyGradient = [const Color(0xFF059669), const Color(0xFF047857)];
    final barColors = _mode == _BarMode.revenue ? revenueGradient : qtyGradient;
    final accentColor = barColors.first;

    // Y-axis label formatter
    String yLabel(double v) {
      if (_mode == _BarMode.revenue) {
        if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}k';
        return '₹${v.toInt()}';
      } else {
        if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
        return '${v.toInt()}';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Segmented Toggle ─────────────────────────────────────────
        Row(
          children: [
            // Mode toggle
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2D) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ModeTab(
                    label: 'Most Revenue',
                    icon: Icons.attach_money_rounded,
                    selected: _mode == _BarMode.revenue,
                    color: const Color(0xFF7C3AED),
                    onTap: () {
                      if (_mode != _BarMode.revenue) {
                        setState(() => _mode = _BarMode.revenue);
                        _animCtrl.forward(from: 0);
                      }
                    },
                  ),
                  _ModeTab(
                    label: 'Most Qty Sold',
                    icon: Icons.inventory_2_rounded,
                    selected: _mode == _BarMode.quantity,
                    color: const Color(0xFF059669),
                    onTap: () {
                      if (_mode != _BarMode.quantity) {
                        setState(() => _mode = _BarMode.quantity);
                        _animCtrl.forward(from: 0);
                      }
                    },
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Count chip
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Top ${topEntries.length} Products',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Bar Chart ────────────────────────────────────────────────
        Expanded(
          child: topEntries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bar_chart_outlined,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('No sales data for selected period',
                          style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : AnimatedBuilder(
                  animation: _anim,
                  builder: (_, child) {
                    return BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: topEntries.isEmpty
                            ? 10
                            : (topEntries.first.value * 1.2),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchCallback: (event, response) {
                            final idx = response?.spot?.touchedBarGroupIndex;
                            if (mounted) setState(() => _hoveredIndex = idx);
                          },
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => isDark
                                ? const Color(0xFF312E81)
                                : const Color(0xFF4338CA),
                            tooltipPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            tooltipMargin: 8,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final i = group.x;
                              if (i < 0 || i >= topEntries.length) return null;
                              final pId = topEntries[i].key;
                              final rev = revenueMap[pId] ?? 0;
                              final qty = qtyMap[pId] ?? 0;
                              final product =
                                  widget.productProvider.products
                                      .where((p) => p.productId == pId)
                                      .firstOrNull;
                              final name =
                                  product?.productName ?? 'Product #$pId';
                              return BarTooltipItem(
                                '$name\n',
                                const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                                children: [
                                  TextSpan(
                                    text:
                                        '₹${rev.toStringAsFixed(2)}  |  ${qty.toInt()} units',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 52,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= topEntries.length || value != idx.toDouble()) {
                                  return const SizedBox.shrink();
                                }
                                final pId = topEntries[idx].key;
                                final product = widget.productProvider.products
                                    .where((p) => p.productId == pId)
                                    .firstOrNull;
                                String name =
                                    product?.productName ?? '#$pId';
                                if (name.length > 8) {
                                  name = '${name.substring(0, 6)}..';
                                }
                                final isHovered = _hoveredIndex == idx;
                                return SideTitleWidget(
                                  meta: meta,
                                  space: 4,
                                  child: Transform.rotate(
                                    angle: -0.4,
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: isHovered
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isHovered
                                            ? accentColor
                                            : (isDark
                                                ? Colors.white60
                                                : Colors.grey.shade600),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 52,
                              getTitlesWidget: (value, meta) {
                                if (value == meta.min || value == meta.max) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  yLabel(value),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey.shade500,
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: isDark ? Colors.white10 : Colors.grey.shade200,
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: topEntries.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final val = entry.value.value * _anim.value;
                          final isHovered = _hoveredIndex == idx;
                          return BarChartGroupData(
                            x: idx,
                            barRods: [
                              BarChartRodData(
                                toY: val,
                                gradient: LinearGradient(
                                  colors: isHovered
                                      ? [
                                          barColors[0].withValues(alpha: 1),
                                          barColors[1].withValues(alpha: 0.8),
                                        ]
                                      : [
                                          barColors[0].withValues(alpha: 0.85),
                                          barColors[1].withValues(alpha: 0.6),
                                        ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                width: isHovered ? 26 : 22,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  topRight: Radius.circular(6),
                                ),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: topEntries.first.value * 1.2,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.03)
                                      : Colors.grey.withValues(alpha: 0.06),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      duration: Duration.zero,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Compact tab pill for mode selector ──────────────────────────────
class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: selected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
