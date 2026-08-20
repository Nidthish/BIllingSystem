import '../models/sale.dart';
import '../models/sale_item.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/customer.dart';
import '../models/report_filter_model.dart';
import '../models/sales_analysis_row.dart';

/// Pure business-logic service for generating report data.
/// No Flutter/UI dependencies — fully testable.
class ReportService {
  const ReportService();

  // ─────────────────────────────────────────────
  // Invoice Filtering
  // ─────────────────────────────────────────────

  /// Returns invoices matching all active invoice-tab filters.
  List<Sale> filterInvoices({
    required List<Sale> sales,
    String searchQuery = '',
    int? customerId,
    DateTime? startDate,
    DateTime? endDate,
    String paymentMethod = 'All',
    InvoiceGstFilter invoiceGstFilter = InvoiceGstFilter.all,
  }) {
    return sales.where((sale) {
      // GST Invoice Classification Filter
      if (invoiceGstFilter == InvoiceGstFilter.gstBills && !sale.isGstBill) return false;
      if (invoiceGstFilter == InvoiceGstFilter.nonGstBills && sale.isGstBill) return false;

      // Search
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchesInv = sale.invoiceNo.toLowerCase().contains(q);
        final matchesCust = sale.customerName?.toLowerCase().contains(q) ?? false;
        if (!matchesInv && !matchesCust) return false;
      }
      // Customer
      if (customerId != null && sale.customerId != customerId) return false;
      // Payment
      if (paymentMethod != 'All' && sale.paymentMethod != paymentMethod) return false;
      // Date range
      if (startDate != null || endDate != null) {
        final saleDate = DateTime.tryParse(sale.date);
        if (saleDate == null) return false;
        if (startDate != null && saleDate.isBefore(startDate)) return false;
        if (endDate != null && saleDate.isAfter(endDate)) return false;
      }
      return true;
    }).toList();
  }

  // ─────────────────────────────────────────────
  // Sales Analysis Aggregation
  // ─────────────────────────────────────────────

  /// Applies all analysis filters, groups, and sorts to produce [SalesAnalysisRow] list.
  /// Applies all analysis filters, groups, and sorts to produce [SalesAnalysisRow] list
  /// and returns matching sales that actually contributed to the analysis.
  (List<SalesAnalysisRow>, List<Sale>) generateAnalysis({
    required List<Sale> sales,
    required Map<int, List<SaleItem>> saleItemsMap,
    required List<Product> products,
    required List<Category> categories,
    required List<Customer> customers,
    required ReportFilterModel filter,
  }) {
    // Build lookup maps for performance
    final productMap = {for (var p in products) p.productId: p};
    final categoryMap = {for (var c in categories) c.categoryId: c};

    // Step 1: Filter sales by date + payment + customer + GST invoice filter
    final (startDate, endDate) = filter.effectiveDateRange;
    final filteredSales = sales.where((sale) {
      final saleDate = DateTime.tryParse(sale.date);
      if (saleDate == null) return false;
      if (saleDate.isBefore(startDate) || saleDate.isAfter(endDate)) return false;
      if (filter.paymentMethods.isNotEmpty &&
          !filter.paymentMethods.contains(sale.paymentMethod ?? 'Cash')) return false;
      if (filter.customerName.isNotEmpty &&
          !(sale.customerName?.toLowerCase().contains(filter.customerName.toLowerCase()) ?? false)) {
        return false;
      }
      if (filter.invoiceGstFilter == InvoiceGstFilter.gstBills && !sale.isGstBill) return false;
      if (filter.invoiceGstFilter == InvoiceGstFilter.nonGstBills && sale.isGstBill) return false;
      return true;
    }).toList();

    // Step 2: Expand into sale item rows with full context
    final List<_RawRow> rawRows = [];
    final Set<int> matchingSaleIds = {};

    for (final sale in filteredSales) {
      final items = saleItemsMap[sale.saleId] ?? [];
      final hasGst = sale.isGstBill;

      // Product GST Filter check
      if (filter.productGstFilter == ProductGstFilter.withGst && !hasGst) continue;
      if (filter.productGstFilter == ProductGstFilter.withoutGst && hasGst) continue;

      bool hasMatchingItem = false;
      for (final item in items) {
        final product = productMap[item.productId];
        if (product == null) continue;

        // Product filter
        if (filter.productId != null && product.productId != filter.productId) continue;
        if (filter.categoryId != null && product.categoryId != filter.categoryId) continue;

        final category = product.categoryId != null
            ? categoryMap[product.categoryId]
            : null;

        final purchaseCost = product.unit == 'g'
            ? (item.quantity / 1000.0) * product.purchasePrice
            : item.quantity * product.purchasePrice;
        final saleAmount = item.total;
        
        // Product item inherits GST proportion from invoice
        final itemGstShare = sale.subtotal > 0
            ? (saleAmount / sale.subtotal) * sale.gst
            : 0.0;
        final profit = saleAmount - purchaseCost;

        // Customer city filter
        if (filter.city.isNotEmpty) {
          final customer = customers.firstWhere(
            (c) => c.customerId == sale.customerId,
            orElse: () => Customer(customerName: ''),
          );
          if (!(customer.city?.toLowerCase().contains(filter.city.toLowerCase()) ?? false)) {
            continue;
          }
        }

        hasMatchingItem = true;
        rawRows.add(_RawRow(
          sale: sale,
          item: item,
          product: product,
          categoryName: category?.categoryName ?? 'Uncategorized',
          gstCategory: hasGst ? 'With GST' : 'Without GST',
          purchaseCost: purchaseCost,
          saleAmount: saleAmount,
          gstAmount: itemGstShare,
          profit: profit,
          finalAmount: saleAmount + itemGstShare,
          discount: items.isNotEmpty ? (sale.discount / items.length) : 0.0,
        ));
      }

      if (hasMatchingItem && sale.saleId != null) {
        matchingSaleIds.add(sale.saleId!);
      }
    }

    final matchingSales = filteredSales.where((s) => s.saleId != null && matchingSaleIds.contains(s.saleId)).toList();

    // Step 3: Group rows
    final Map<String, List<_RawRow>> grouped = {};
    for (final row in rawRows) {
      final key = _groupKey(row, filter.groupBy);
      grouped.putIfAbsent(key, () => []).add(row);
    }

    // Step 4: Aggregate each group
    final List<SalesAnalysisRow> result = grouped.entries.map((entry) {
      final rows = entry.value;
      final first = rows.first;
      return SalesAnalysisRow(
        groupLabel: entry.key,
        productId: filter.groupBy == GroupBy.product ? first.product.productId : null,
        productName: filter.groupBy == GroupBy.product ? first.product.productName : '',
        categoryName: first.categoryName,
        paymentMethod: filter.groupBy == GroupBy.paymentMethod
            ? (first.sale.paymentMethod ?? 'Cash')
            : '',
        customerName: filter.groupBy == GroupBy.customer
            ? (first.sale.customerName ?? 'Walk-in')
            : '',
        gstCategory: first.gstCategory,
        qtySold: rows.fold(0.0, (s, r) => s + r.item.quantity),
        saleAmount: rows.fold(0.0, (s, r) => s + r.saleAmount),
        gstAmount: rows.fold(0.0, (s, r) => s + r.gstAmount),
        discount: rows.fold(0.0, (s, r) => s + r.discount),
        purchaseCost: rows.fold(0.0, (s, r) => s + r.purchaseCost),
        profit: rows.fold(0.0, (s, r) => s + r.profit),
        finalAmount: rows.fold(0.0, (s, r) => s + r.finalAmount),
        invoiceCount: rows.map((r) => r.sale.saleId).toSet().length,
      );
    }).toList();

    // Step 5: Sort
    _sort(result, filter.primarySortField, filter.primarySortAsc);
    if (filter.secondarySortField != SortField.none) {
      result.sort((a, b) {
        final primary = _compareRows(a, b, filter.primarySortField, filter.primarySortAsc);
        if (primary != 0) return primary;
        return _compareRows(a, b, filter.secondarySortField, filter.secondarySortAsc);
      });
    }

    return (result, matchingSales);
  }

  String _groupKey(_RawRow row, GroupBy groupBy) {
    switch (groupBy) {
      case GroupBy.none:
        return '${row.product.productId} (${row.gstCategory})';
      case GroupBy.product:
        return '${row.product.productName} (${row.gstCategory})';
      case GroupBy.category:
        return row.categoryName;
      case GroupBy.customer:
        return row.sale.customerName ?? 'Walk-in Customer';
      case GroupBy.paymentMethod:
        return row.sale.paymentMethod ?? 'Cash';
      case GroupBy.day:
        final d = DateTime.tryParse(row.sale.date) ?? DateTime.now();
        return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      case GroupBy.week:
        final d = DateTime.tryParse(row.sale.date) ?? DateTime.now();
        final weekStart = d.subtract(Duration(days: d.weekday - 1));
        return 'Wk ${weekStart.day}/${weekStart.month}/${weekStart.year}';
      case GroupBy.month:
        final d = DateTime.tryParse(row.sale.date) ?? DateTime.now();
        return _monthName(d.month) + ' ${d.year}';
      case GroupBy.year:
        final d = DateTime.tryParse(row.sale.date) ?? DateTime.now();
        return '${d.year}';
    }
  }

  String _monthName(int m) {
    const names = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return names[m];
  }

  void _sort(List<SalesAnalysisRow> rows, SortField field, bool asc) {
    if (field == SortField.none) return;
    rows.sort((a, b) => _compareRows(a, b, field, asc));
  }

  int _compareRows(SalesAnalysisRow a, SalesAnalysisRow b, SortField field, bool asc) {
    int cmp;
    switch (field) {
      case SortField.none: cmp = 0; break;
      case SortField.groupLabel: cmp = a.groupLabel.compareTo(b.groupLabel); break;
      case SortField.productName: cmp = a.productName.compareTo(b.productName); break;
      case SortField.categoryName: cmp = a.categoryName.compareTo(b.categoryName); break;
      case SortField.qtySold: cmp = a.qtySold.compareTo(b.qtySold); break;
      case SortField.saleAmount: cmp = a.saleAmount.compareTo(b.saleAmount); break;
      case SortField.gstAmount: cmp = a.gstAmount.compareTo(b.gstAmount); break;
      case SortField.discount: cmp = a.discount.compareTo(b.discount); break;
      case SortField.profit: cmp = a.profit.compareTo(b.profit); break;
      case SortField.finalAmount: cmp = a.finalAmount.compareTo(b.finalAmount); break;
      case SortField.purchaseCost: cmp = a.purchaseCost.compareTo(b.purchaseCost); break;
      case SortField.invoiceCount: cmp = a.invoiceCount.compareTo(b.invoiceCount); break;
    }
    return asc ? cmp : -cmp;
  }

  // ─────────────────────────────────────────────
  // Summary Calculation
  // ─────────────────────────────────────────────

  ReportSummary calculateSummary({
    required List<SalesAnalysisRow> rows,
    required List<Sale> matchingSales,
  }) {
    if (rows.isEmpty) return ReportSummary.empty;

    final totalQty = rows.fold(0.0, (s, r) => s + r.qtySold);
    final totalSales = rows.fold(0.0, (s, r) => s + r.saleAmount);
    final totalGst = rows.fold(0.0, (s, r) => s + r.gstAmount);
    final totalDiscount = rows.fold(0.0, (s, r) => s + r.discount);
    final totalProfit = rows.fold(0.0, (s, r) => s + r.profit);
    final totalPurchase = rows.fold(0.0, (s, r) => s + r.purchaseCost);
    final grandTotal = rows.fold(0.0, (s, r) => s + r.finalAmount);
    final invoiceCount = matchingSales.length;
    final avg = invoiceCount > 0 ? grandTotal / invoiceCount : 0.0;

    // GST Invoice Breakdown
    final gstSalesList = matchingSales.where((s) => s.isGstBill).toList();
    final nonGstSalesList = matchingSales.where((s) => !s.isGstBill).toList();

    final gstBillsCount = gstSalesList.length;
    final gstBillsSales = gstSalesList.fold(0.0, (s, r) => s + r.subtotal);
    final gstBillsGstCollected = gstSalesList.fold(0.0, (s, r) => s + r.gst);

    final nonGstBillsCount = nonGstSalesList.length;
    final nonGstBillsSales = nonGstSalesList.fold(0.0, (s, r) => s + r.subtotal);

    // GST Product Breakdown
    final gstRows = rows.where((r) => r.gstCategory == 'With GST').toList();
    final nonGstRows = rows.where((r) => r.gstCategory == 'Without GST').toList();

    final gstProductsCount = gstRows.map((r) => r.productId ?? r.groupLabel).toSet().length;
    final gstProductsQtySold = gstRows.fold(0.0, (s, r) => s + r.qtySold);
    final gstProductsSalesValue = gstRows.fold(0.0, (s, r) => s + r.saleAmount);

    final nonGstProductsCount = nonGstRows.map((r) => r.productId ?? r.groupLabel).toSet().length;
    final nonGstProductsQtySold = nonGstRows.fold(0.0, (s, r) => s + r.qtySold);
    final nonGstProductsSalesValue = nonGstRows.fold(0.0, (s, r) => s + r.saleAmount);

    final sorted = [...rows]..sort((a, b) => b.saleAmount.compareTo(a.saleAmount));

    final today = DateTime.now();
    final todaySales = matchingSales
        .where((s) {
          final d = DateTime.tryParse(s.date);
          return d != null &&
              d.year == today.year &&
              d.month == today.month &&
              d.day == today.day;
        })
        .fold(0.0, (s, sale) => s + sale.grandTotal);

    final highestInvoice = matchingSales.isEmpty
        ? 0.0
        : matchingSales.map((s) => s.grandTotal).reduce((a, b) => a > b ? a : b);

    return ReportSummary(
      totalInvoices: invoiceCount,
      totalQtySold: totalQty,
      totalSales: totalSales,
      totalGst: totalGst,
      totalDiscount: totalDiscount,
      totalProfit: totalProfit,
      grandTotal: grandTotal,
      totalPurchaseCost: totalPurchase,
      avgInvoiceValue: avg,
      highestSellingProduct: sorted.isNotEmpty ? sorted.first.groupLabel : '—',
      lowestSellingProduct: sorted.isNotEmpty ? sorted.last.groupLabel : '—',
      totalProducts: rows.length,
      todaySales: todaySales,
      highestInvoiceAmount: highestInvoice,
      gstBillsCount: gstBillsCount,
      gstBillsSales: gstBillsSales,
      gstBillsGstCollected: gstBillsGstCollected,
      nonGstBillsCount: nonGstBillsCount,
      nonGstBillsSales: nonGstBillsSales,
      gstProductsCount: gstProductsCount,
      gstProductsQtySold: gstProductsQtySold,
      gstProductsSalesValue: gstProductsSalesValue,
      nonGstProductsCount: nonGstProductsCount,
      nonGstProductsQtySold: nonGstProductsQtySold,
      nonGstProductsSalesValue: nonGstProductsSalesValue,
    );
  }
}

// ─────────────────────────────────────────────
// Internal helper for raw (un-aggregated) row
// ─────────────────────────────────────────────
class _RawRow {
  final Sale sale;
  final SaleItem item;
  final Product product;
  final String categoryName;
  final String gstCategory;
  final double purchaseCost;
  final double saleAmount;
  final double gstAmount;
  final double profit;
  final double finalAmount;
  final double discount;

  _RawRow({
    required this.sale,
    required this.item,
    required this.product,
    required this.categoryName,
    required this.gstCategory,
    required this.purchaseCost,
    required this.saleAmount,
    required this.gstAmount,
    required this.profit,
    required this.finalAmount,
    required this.discount,
  });
}
