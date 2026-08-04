import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/sale.dart';
import 'package:intl/intl.dart';

class SalesTrendChart extends StatelessWidget {
  final List<Sale> sales;

  const SalesTrendChart({super.key, required this.sales});

  @override
  Widget build(BuildContext context) {
    // Group sales by day
    Map<String, Map<String, dynamic>> dailySales = {};
    for (var sale in sales) {
      DateTime date = DateTime.parse(sale.date);
      String dateStr = DateFormat('yyyy-MM-dd').format(date);
      if (!dailySales.containsKey(dateStr)) {
        dailySales[dateStr] = {'revenue': 0.0, 'count': 0};
      }
      dailySales[dateStr]!['revenue'] = (dailySales[dateStr]!['revenue'] as double) + sale.grandTotal;
      dailySales[dateStr]!['count'] = (dailySales[dateStr]!['count'] as int) + 1;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    var sortedKeys = dailySales.keys.toList()..sort();
    
    if (sortedKeys.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
        ),
        child: const Center(child: Text('No data available for Sales Trend')),
      );
    }

    List<FlSpot> spots = [];
    double maxX = sortedKeys.length.toDouble() - 1;
    if (maxX < 1) maxX = 1;
    double maxY = 0;

    for (int i = 0; i < sortedKeys.length; i++) {
      double y = dailySales[sortedKeys[i]]!['revenue'];
      if (y > maxY) maxY = y;
      spots.add(FlSpot(i.toDouble(), y));
    }
    if (maxY == 0) maxY = 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sales Trend (Hover for Details)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Chip(
                label: Text('${sortedKeys.length} Days Active', style: const TextStyle(fontSize: 11)),
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => Theme.of(context).primaryColor,
                    tooltipPadding: const EdgeInsets.all(10),
                    tooltipMargin: 8,
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        int index = spot.x.toInt();
                        if (index >= 0 && index < sortedKeys.length) {
                          String dateKey = sortedKeys[index];
                          DateTime date = DateTime.parse(dateKey);
                          String formattedDate = DateFormat('dd MMM yyyy').format(date);
                          double revenue = dailySales[dateKey]!['revenue'];
                          int count = dailySales[dateKey]!['count'];

                          return LineTooltipItem(
                            '$formattedDate\nRevenue: ₹${revenue.toStringAsFixed(2)}\nBills Issued: $count',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          );
                        }
                        return null;
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                ),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < sortedKeys.length) {
                          DateTime date = DateTime.parse(sortedKeys[index]);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(DateFormat('dd MMM').format(date), style: const TextStyle(fontSize: 10)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('0', style: TextStyle(fontSize: 10));
                        return Text('${(value / 1000).toStringAsFixed(1)}k', style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: maxX,
                minY: 0,
                maxY: maxY * 1.25,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF00875A),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF00875A).withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
