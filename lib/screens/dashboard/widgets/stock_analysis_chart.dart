import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../providers/product_provider.dart';

class StockAnalysisChart extends StatefulWidget {
  final ProductProvider productProvider;

  const StockAnalysisChart({super.key, required this.productProvider});

  @override
  State<StockAnalysisChart> createState() => _StockAnalysisChartState();
}

class _StockAnalysisChartState extends State<StockAnalysisChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    int inStock = 0;
    int lowStock = 0;
    int outOfStock = 0;

    final filteredProducts = widget.productProvider.filteredProducts;

    for (var product in filteredProducts) {
      if (product.stock == 0) {
        outOfStock++;
      } else if (product.stock <= product.minimumStock) {
        lowStock++;
      } else {
        inStock++;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = inStock + lowStock + outOfStock;

    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
        ),
        child: const Center(child: Text('No stock data available')),
      );
    }

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
              const Text('Stock Status (Hover Slices)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Chip(
                label: Text('$total Products', style: const TextStyle(fontSize: 11)),
                backgroundColor: Colors.blue.withOpacity(0.1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: [
                  _buildSection(0, inStock, total, Colors.green, 'In Stock'),
                  _buildSection(1, lowStock, total, Colors.orange, 'Low Stock'),
                  _buildSection(2, outOfStock, total, Colors.red, 'Out of Stock'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegend(Colors.green, 'In Stock ($inStock)'),
              _buildLegend(Colors.orange, 'Low Stock ($lowStock)'),
              _buildLegend(Colors.red, 'Out of Stock ($outOfStock)'),
            ],
          )
        ],
      ),
    );
  }

  PieChartSectionData _buildSection(int index, int count, int total, Color color, String title) {
    final isTouched = index == _touchedIndex;
    final fontSize = isTouched ? 16.0 : 12.0;
    final radius = isTouched ? 60.0 : 50.0;
    final percentage = total > 0 ? ((count / total) * 100).toStringAsFixed(1) : '0';

    return PieChartSectionData(
      color: color,
      value: count.toDouble(),
      title: '$count ($percentage%)',
      radius: radius,
      titleStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
