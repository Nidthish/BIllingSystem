import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../models/product.dart';
import 'sales_provider.dart';
import 'product_provider.dart';

enum DateFilter {
  allTime,
  today,
  yesterday,
  thisWeek,
  thisMonth,
  thisYear,
  custom,
}

class DashboardProvider with ChangeNotifier {
  DateFilter _selectedFilter = DateFilter.allTime; // Default to All Time so historical mock data renders immediately!
  DateTimeRange? _customRange;

  int? _selectedCategoryId;
  String? _selectedPaymentMethod;
  int? _selectedCustomerId;

  DateFilter get selectedFilter => _selectedFilter;
  DateTimeRange? get customRange => _customRange;
  int? get selectedCategoryId => _selectedCategoryId;
  String? get selectedPaymentMethod => _selectedPaymentMethod;
  int? get selectedCustomerId => _selectedCustomerId;

  void setFilter(DateFilter filter, {DateTimeRange? customRange}) {
    _selectedFilter = filter;
    _customRange = customRange;
    notifyListeners();
  }

  void setCategoryFilter(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setPaymentMethodFilter(String? paymentMethod) {
    _selectedPaymentMethod = paymentMethod == 'All' ? null : paymentMethod;
    notifyListeners();
  }

  void setCustomerFilter(int? customerId) {
    _selectedCustomerId = customerId;
    notifyListeners();
  }

  void resetFilters() {
    _selectedFilter = DateFilter.allTime;
    _customRange = null;
    _selectedCategoryId = null;
    _selectedPaymentMethod = null;
    _selectedCustomerId = null;
    notifyListeners();
  }

  List<Sale> getFilteredSales(SalesProvider salesProvider, {ProductProvider? productProvider}) {
    final allSales = salesProvider.sales;
    final now = DateTime.now();

    return allSales.where((sale) {
      final saleDate = DateTime.tryParse(sale.date);
      if (saleDate == null) return false;

      // 1. Date Filter
      bool matchesDate = false;
      switch (_selectedFilter) {
        case DateFilter.allTime:
          matchesDate = true;
          break;
        case DateFilter.today:
          matchesDate = saleDate.year == now.year &&
              saleDate.month == now.month &&
              saleDate.day == now.day;
          break;
        case DateFilter.yesterday:
          final y = now.subtract(const Duration(days: 1));
          matchesDate = saleDate.year == y.year &&
              saleDate.month == y.month &&
              saleDate.day == y.day;
          break;
        case DateFilter.thisWeek:
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          matchesDate = saleDate.isAfter(start.subtract(const Duration(seconds: 1)));
          break;
        case DateFilter.thisMonth:
          matchesDate = saleDate.year == now.year && saleDate.month == now.month;
          break;
        case DateFilter.thisYear:
          matchesDate = saleDate.year == now.year;
          break;
        case DateFilter.custom:
          if (_customRange == null) {
            matchesDate = true;
          } else {
            matchesDate = saleDate.isAfter(_customRange!.start.subtract(const Duration(seconds: 1))) &&
                saleDate.isBefore(_customRange!.end.add(const Duration(days: 1)));
          }
          break;
      }
      if (!matchesDate) return false;

      // 2. Payment Method Filter
      if (_selectedPaymentMethod != null && _selectedPaymentMethod!.isNotEmpty) {
        if (sale.paymentMethod != _selectedPaymentMethod) return false;
      }

      // 3. Customer Filter
      if (_selectedCustomerId != null) {
        if (sale.customerId != _selectedCustomerId) return false;
      }

      // 4. Category Filter
      if (_selectedCategoryId != null && productProvider != null) {
        final items = salesProvider.getItemsForSale(sale.saleId ?? 0);
        bool hasCategoryItem = items.any((item) {
          final pList = productProvider.products.where((p) => p.productId == item.productId);
          return pList.isNotEmpty && pList.first.categoryId == _selectedCategoryId;
        });
        if (!hasCategoryItem) return false;
      }

      return true;
    }).toList();
  }

  double getTotalRevenue(SalesProvider salesProvider, {ProductProvider? productProvider}) {
    final filtered = getFilteredSales(salesProvider, productProvider: productProvider);
    return filtered.fold(0.0, (sum, s) => sum + s.grandTotal);
  }

  double getTodaySales(SalesProvider salesProvider) {
    final now = DateTime.now();
    return salesProvider.sales.where((s) {
      final d = DateTime.tryParse(s.date);
      return d != null && d.year == now.year && d.month == now.month && d.day == now.day;
    }).fold(0.0, (sum, s) => sum + s.grandTotal);
  }

  double getThisWeekSales(SalesProvider salesProvider) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return salesProvider.sales.where((s) {
      final d = DateTime.tryParse(s.date);
      return d != null && d.isAfter(start.subtract(const Duration(seconds: 1)));
    }).fold(0.0, (sum, s) => sum + s.grandTotal);
  }

  double getMonthlySales(SalesProvider salesProvider) {
    final now = DateTime.now();
    return salesProvider.sales.where((s) {
      final d = DateTime.tryParse(s.date);
      return d != null && d.year == now.year && d.month == now.month;
    }).fold(0.0, (sum, s) => sum + s.grandTotal);
  }

  List<Product> getLowStockProducts(ProductProvider productProvider) {
    return productProvider.products.where((p) => p.stock <= p.minimumStock).toList();
  }

  int getTotalBills(SalesProvider salesProvider, {ProductProvider? productProvider}) {
    return getFilteredSales(salesProvider, productProvider: productProvider).length;
  }

  double getTotalProfit(SalesProvider salesProvider, ProductProvider productProvider) {
    final filteredSales = getFilteredSales(salesProvider, productProvider: productProvider);
    double totalProfit = 0.0;

    for (var sale in filteredSales) {
      final items = salesProvider.getItemsForSale(sale.saleId ?? 0);
      for (var item in items) {
        final productList = productProvider.products.where((p) => p.productId == item.productId);
        if (productList.isNotEmpty) {
          final product = productList.first;
          if (_selectedCategoryId == null || product.categoryId == _selectedCategoryId) {
            final itemProfit = (item.price - product.purchasePrice) * item.quantity;
            totalProfit += itemProfit;
          }
        }
      }
    }
    return totalProfit;
  }

  int getLowStockCount(ProductProvider productProvider) {
    return productProvider.products.where((p) {
      final matchesCategory = _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
      return matchesCategory && p.stock <= p.minimumStock;
    }).length;
  }

  String getBestSellingProduct(SalesProvider salesProvider, ProductProvider productProvider) {
    final filteredSales = getFilteredSales(salesProvider, productProvider: productProvider);
    final Map<int, double> productQtyMap = {};

    for (var sale in filteredSales) {
      final items = salesProvider.getItemsForSale(sale.saleId ?? 0);
      for (var item in items) {
        productQtyMap[item.productId] = (productQtyMap[item.productId] ?? 0) + item.quantity;
      }
    }

    if (productQtyMap.isEmpty) return 'N/A';

    int? topProductId;
    double maxQty = -1;

    productQtyMap.forEach((pId, qty) {
      if (qty > maxQty) {
        maxQty = qty;
        topProductId = pId;
      }
    });

    if (topProductId != null) {
      final matches = productProvider.products.where((p) => p.productId == topProductId);
      if (matches.isNotEmpty) return matches.first.productName;
    }
    return 'N/A';
  }

  // ─────────────────────────────────────────────
  // Refactored GST Dashboard Summary Metrics
  // ─────────────────────────────────────────────

  Map<String, dynamic> getGstBillsMetrics(SalesProvider salesProvider, {ProductProvider? productProvider}) {
    final filtered = getFilteredSales(salesProvider, productProvider: productProvider);
    final gstSales = filtered.where((s) => s.isGstBill).toList();
    final salesAmount = gstSales.fold(0.0, (sum, s) => sum + s.subtotal);
    final gstCollected = gstSales.fold(0.0, (sum, s) => sum + s.gst);

    return {
      'count': gstSales.length,
      'sales': salesAmount,
      'gstCollected': gstCollected,
    };
  }

  Map<String, dynamic> getNonGstBillsMetrics(SalesProvider salesProvider, {ProductProvider? productProvider}) {
    final filtered = getFilteredSales(salesProvider, productProvider: productProvider);
    final nonGstSales = filtered.where((s) => !s.isGstBill).toList();
    final salesAmount = nonGstSales.fold(0.0, (sum, s) => sum + s.subtotal);

    return {
      'count': nonGstSales.length,
      'sales': salesAmount,
    };
  }

  Map<String, dynamic> getGstProductsMetrics(SalesProvider salesProvider, ProductProvider productProvider) {
    final filteredSales = getFilteredSales(salesProvider, productProvider: productProvider);
    final gstSales = filteredSales.where((s) => s.isGstBill).toList();
    final Set<int> uniqueProducts = {};
    double totalQty = 0.0;
    double totalValue = 0.0;

    for (final sale in gstSales) {
      final items = salesProvider.getItemsForSale(sale.saleId ?? 0);
      for (final item in items) {
        uniqueProducts.add(item.productId);
        totalQty += item.quantity;
        totalValue += item.total;
      }
    }

    return {
      'count': uniqueProducts.length,
      'qtySold': totalQty,
      'salesValue': totalValue,
    };
  }

  Map<String, dynamic> getNonGstProductsMetrics(SalesProvider salesProvider, ProductProvider productProvider) {
    final filteredSales = getFilteredSales(salesProvider, productProvider: productProvider);
    final nonGstSales = filteredSales.where((s) => !s.isGstBill).toList();
    final Set<int> uniqueProducts = {};
    double totalQty = 0.0;
    double totalValue = 0.0;

    for (final sale in nonGstSales) {
      final items = salesProvider.getItemsForSale(sale.saleId ?? 0);
      for (final item in items) {
        uniqueProducts.add(item.productId);
        totalQty += item.quantity;
        totalValue += item.total;
      }
    }

    return {
      'count': uniqueProducts.length,
      'qtySold': totalQty,
      'salesValue': totalValue,
    };
  }
}
