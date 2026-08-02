import 'dart:convert';

/// All date presets available in the filter panel.
enum DatePreset {
  today,
  yesterday,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  thisYear,
  financialYear,
  custom,
}

extension DatePresetLabel on DatePreset {
  String get label {
    switch (this) {
      case DatePreset.today: return 'Today';
      case DatePreset.yesterday: return 'Yesterday';
      case DatePreset.thisWeek: return 'This Week';
      case DatePreset.lastWeek: return 'Last Week';
      case DatePreset.thisMonth: return 'This Month';
      case DatePreset.lastMonth: return 'Last Month';
      case DatePreset.thisYear: return 'This Year';
      case DatePreset.financialYear: return 'Financial Year';
      case DatePreset.custom: return 'Custom Range';
    }
  }
}

/// How the analysis rows should be grouped.
enum GroupBy {
  none,
  product,
  category,
  customer,
  paymentMethod,
  day,
  week,
  month,
  year,
}

extension GroupByLabel on GroupBy {
  String get label {
    switch (this) {
      case GroupBy.none: return 'None (All Items)';
      case GroupBy.product: return 'Product';
      case GroupBy.category: return 'Category';
      case GroupBy.customer: return 'Customer';
      case GroupBy.paymentMethod: return 'Payment Method';
      case GroupBy.day: return 'Day';
      case GroupBy.week: return 'Week';
      case GroupBy.month: return 'Month';
      case GroupBy.year: return 'Year';
    }
  }
}

/// Which column to sort by in the analysis table.
enum SortField {
  none,
  groupLabel,
  productName,
  categoryName,
  qtySold,
  saleAmount,
  gstAmount,
  discount,
  profit,
  finalAmount,
  purchaseCost,
  invoiceCount,
}

extension SortFieldLabel on SortField {
  String get label {
    switch (this) {
      case SortField.none: return 'None';
      case SortField.groupLabel: return 'Group / Name';
      case SortField.productName: return 'Product Name';
      case SortField.categoryName: return 'Category';
      case SortField.qtySold: return 'Quantity Sold';
      case SortField.saleAmount: return 'Sales Amount';
      case SortField.gstAmount: return 'GST Amount';
      case SortField.discount: return 'Discount';
      case SortField.profit: return 'Profit';
      case SortField.finalAmount: return 'Final Amount';
      case SortField.purchaseCost: return 'Purchase Cost';
      case SortField.invoiceCount: return 'Invoice Count';
    }
  }
}

/// Which columns are visible in the analysis table.
class AnalysisOptions {
  final bool showQtySold;
  final bool showSaleAmount;
  final bool showGst;
  final bool showDiscount;
  final bool showProfit;
  final bool showPurchaseCost;
  final bool showFinalAmount;
  final bool showAvgSellingPrice;
  final bool showAvgProfit;

  const AnalysisOptions({
    this.showQtySold = true,
    this.showSaleAmount = true,
    this.showGst = true,
    this.showDiscount = false,
    this.showProfit = true,
    this.showPurchaseCost = false,
    this.showFinalAmount = true,
    this.showAvgSellingPrice = false,
    this.showAvgProfit = false,
  });

  AnalysisOptions copyWith({
    bool? showQtySold,
    bool? showSaleAmount,
    bool? showGst,
    bool? showDiscount,
    bool? showProfit,
    bool? showPurchaseCost,
    bool? showFinalAmount,
    bool? showAvgSellingPrice,
    bool? showAvgProfit,
  }) {
    return AnalysisOptions(
      showQtySold: showQtySold ?? this.showQtySold,
      showSaleAmount: showSaleAmount ?? this.showSaleAmount,
      showGst: showGst ?? this.showGst,
      showDiscount: showDiscount ?? this.showDiscount,
      showProfit: showProfit ?? this.showProfit,
      showPurchaseCost: showPurchaseCost ?? this.showPurchaseCost,
      showFinalAmount: showFinalAmount ?? this.showFinalAmount,
      showAvgSellingPrice: showAvgSellingPrice ?? this.showAvgSellingPrice,
      showAvgProfit: showAvgProfit ?? this.showAvgProfit,
    );
  }

  Map<String, dynamic> toJson() => {
    'showQtySold': showQtySold,
    'showSaleAmount': showSaleAmount,
    'showGst': showGst,
    'showDiscount': showDiscount,
    'showProfit': showProfit,
    'showPurchaseCost': showPurchaseCost,
    'showFinalAmount': showFinalAmount,
    'showAvgSellingPrice': showAvgSellingPrice,
    'showAvgProfit': showAvgProfit,
  };

  factory AnalysisOptions.fromJson(Map<String, dynamic> j) => AnalysisOptions(
    showQtySold: j['showQtySold'] ?? true,
    showSaleAmount: j['showSaleAmount'] ?? true,
    showGst: j['showGst'] ?? true,
    showDiscount: j['showDiscount'] ?? false,
    showProfit: j['showProfit'] ?? true,
    showPurchaseCost: j['showPurchaseCost'] ?? false,
    showFinalAmount: j['showFinalAmount'] ?? true,
    showAvgSellingPrice: j['showAvgSellingPrice'] ?? false,
    showAvgProfit: j['showAvgProfit'] ?? false,
  );
}

enum InvoiceGstFilter {
  all,
  gstBills,
  nonGstBills,
}

extension InvoiceGstFilterLabel on InvoiceGstFilter {
  String get label {
    switch (this) {
      case InvoiceGstFilter.all: return 'All Invoices';
      case InvoiceGstFilter.gstBills: return 'GST Bills';
      case InvoiceGstFilter.nonGstBills: return 'Non-GST Bills';
    }
  }
}

enum ProductGstFilter {
  all,
  withGst,
  withoutGst,
}

extension ProductGstFilterLabel on ProductGstFilter {
  String get label {
    switch (this) {
      case ProductGstFilter.all: return 'All Products';
      case ProductGstFilter.withGst: return 'Products Sold With GST';
      case ProductGstFilter.withoutGst: return 'Products Sold Without GST';
    }
  }
}

/// The complete filter state for the Sales Analysis tab.
/// Immutable; use [copyWith] to create modified copies.
class ReportFilterModel {
  final DatePreset datePreset;
  final DateTime? startDate;
  final DateTime? endDate;

  // GST Classification Filters
  final InvoiceGstFilter invoiceGstFilter;
  final ProductGstFilter productGstFilter;

  // Product filters
  final int? categoryId;
  final String categoryName;
  final int? productId;
  final String productName;

  // Customer filters
  final String customerName;
  final String city;

  // Payment filters (multi-select)
  final Set<String> paymentMethods;

  // Analysis options
  final AnalysisOptions analysisOptions;

  // Grouping
  final GroupBy groupBy;

  // Sorting
  final SortField primarySortField;
  final bool primarySortAsc;
  final SortField secondarySortField;
  final bool secondarySortAsc;

  const ReportFilterModel({
    this.datePreset = DatePreset.thisMonth,
    this.startDate,
    this.endDate,
    this.invoiceGstFilter = InvoiceGstFilter.all,
    this.productGstFilter = ProductGstFilter.all,
    this.categoryId,
    this.categoryName = '',
    this.productId,
    this.productName = '',
    this.customerName = '',
    this.city = '',
    this.paymentMethods = const {},
    this.analysisOptions = const AnalysisOptions(),
    this.groupBy = GroupBy.product,
    this.primarySortField = SortField.saleAmount,
    this.primarySortAsc = false,
    this.secondarySortField = SortField.none,
    this.secondarySortAsc = true,
  });

  /// Returns the effective date range based on [datePreset].
  (DateTime start, DateTime end) get effectiveDateRange {
    final now = DateTime.now();
    switch (datePreset) {
      case DatePreset.today:
        final s = DateTime(now.year, now.month, now.day);
        return (s, s.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)));
      case DatePreset.yesterday:
        final s = DateTime(now.year, now.month, now.day - 1);
        return (s, s.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)));
      case DatePreset.thisWeek:
        final s = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(s.year, s.month, s.day);
        return (start, now);
      case DatePreset.lastWeek:
        final s = now.subtract(Duration(days: now.weekday + 6));
        final start = DateTime(s.year, s.month, s.day);
        final end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        return (start, end);
      case DatePreset.thisMonth:
        final s = DateTime(now.year, now.month, 1);
        return (s, now);
      case DatePreset.lastMonth:
        final s = DateTime(now.year, now.month - 1, 1);
        final e = DateTime(now.year, now.month, 1).subtract(const Duration(seconds: 1));
        return (s, e);
      case DatePreset.thisYear:
        return (DateTime(now.year, 1, 1), now);
      case DatePreset.financialYear:
        // April 1 to March 31
        final fyStart = now.month >= 4
            ? DateTime(now.year, 4, 1)
            : DateTime(now.year - 1, 4, 1);
        final fyEnd = DateTime(fyStart.year + 1, 3, 31, 23, 59, 59);
        return (fyStart, fyEnd);
      case DatePreset.custom:
        return (
          startDate ?? DateTime(now.year, now.month, 1),
          endDate ?? now,
        );
    }
  }

  bool get hasActiveFilters =>
      (datePreset != DatePreset.thisMonth && datePreset != DatePreset.thisYear) ||
      invoiceGstFilter != InvoiceGstFilter.all ||
      productGstFilter != ProductGstFilter.all ||
      categoryId != null ||
      productId != null ||
      customerName.isNotEmpty ||
      city.isNotEmpty ||
      paymentMethods.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportFilterModel &&
          runtimeType == other.runtimeType &&
          datePreset == other.datePreset &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          invoiceGstFilter == other.invoiceGstFilter &&
          productGstFilter == other.productGstFilter &&
          categoryId == other.categoryId &&
          categoryName == other.categoryName &&
          productId == other.productId &&
          productName == other.productName &&
          customerName == other.customerName &&
          city == other.city &&
          paymentMethods.length == other.paymentMethods.length &&
          paymentMethods.containsAll(other.paymentMethods) &&
          groupBy == other.groupBy &&
          primarySortField == other.primarySortField &&
          primarySortAsc == other.primarySortAsc &&
          secondarySortField == other.secondarySortField &&
          secondarySortAsc == other.secondarySortAsc;

  @override
  int get hashCode => Object.hash(
        datePreset,
        startDate,
        endDate,
        invoiceGstFilter,
        productGstFilter,
        categoryId,
        categoryName,
        productId,
        productName,
        customerName,
        city,
        Object.hashAll(paymentMethods),
        groupBy,
        primarySortField,
        primarySortAsc,
        secondarySortField,
        secondarySortAsc,
      );

  ReportFilterModel copyWith({
    DatePreset? datePreset,
    DateTime? startDate,
    DateTime? endDate,
    InvoiceGstFilter? invoiceGstFilter,
    ProductGstFilter? productGstFilter,
    int? categoryId,
    String? categoryName,
    int? productId,
    String? productName,
    String? customerName,
    String? city,
    Set<String>? paymentMethods,
    AnalysisOptions? analysisOptions,
    GroupBy? groupBy,
    SortField? primarySortField,
    bool? primarySortAsc,
    SortField? secondarySortField,
    bool? secondarySortAsc,
    bool clearCategoryId = false,
    bool clearProductId = false,
  }) {
    return ReportFilterModel(
      datePreset: datePreset ?? this.datePreset,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      invoiceGstFilter: invoiceGstFilter ?? this.invoiceGstFilter,
      productGstFilter: productGstFilter ?? this.productGstFilter,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      categoryName: clearCategoryId ? '' : (categoryName ?? this.categoryName),
      productId: clearProductId ? null : (productId ?? this.productId),
      productName: clearProductId ? '' : (productName ?? this.productName),
      customerName: customerName ?? this.customerName,
      city: city ?? this.city,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      analysisOptions: analysisOptions ?? this.analysisOptions,
      groupBy: groupBy ?? this.groupBy,
      primarySortField: primarySortField ?? this.primarySortField,
      primarySortAsc: primarySortAsc ?? this.primarySortAsc,
      secondarySortField: secondarySortField ?? this.secondarySortField,
      secondarySortAsc: secondarySortAsc ?? this.secondarySortAsc,
    );
  }

  static const ReportFilterModel defaultFilter = ReportFilterModel(
    datePreset: DatePreset.thisYear,
  );

  Map<String, dynamic> toJson() => {
    'datePreset': datePreset.index,
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'categoryId': categoryId,
    'categoryName': categoryName,
    'productId': productId,
    'productName': productName,
    'customerName': customerName,
    'city': city,
    'paymentMethods': paymentMethods.toList(),
    'analysisOptions': analysisOptions.toJson(),
    'groupBy': groupBy.index,
    'primarySortField': primarySortField.index,
    'primarySortAsc': primarySortAsc,
    'secondarySortField': secondarySortField.index,
    'secondarySortAsc': secondarySortAsc,
  };

  factory ReportFilterModel.fromJson(Map<String, dynamic> j) => ReportFilterModel(
    datePreset: DatePreset.values[j['datePreset'] ?? 4],
    startDate: j['startDate'] != null ? DateTime.tryParse(j['startDate']) : null,
    endDate: j['endDate'] != null ? DateTime.tryParse(j['endDate']) : null,
    categoryId: j['categoryId'],
    categoryName: j['categoryName'] ?? '',
    productId: j['productId'],
    productName: j['productName'] ?? '',
    customerName: j['customerName'] ?? '',
    city: j['city'] ?? '',
    paymentMethods: Set<String>.from(j['paymentMethods'] ?? []),
    analysisOptions: j['analysisOptions'] != null
        ? AnalysisOptions.fromJson(j['analysisOptions'])
        : const AnalysisOptions(),
    groupBy: GroupBy.values[j['groupBy'] ?? 1],
    primarySortField: SortField.values[j['primarySortField'] ?? 3],
    primarySortAsc: j['primarySortAsc'] ?? false,
    secondarySortField: SortField.values[j['secondarySortField'] ?? 0],
    secondarySortAsc: j['secondarySortAsc'] ?? true,
  );

  String toJsonString() => jsonEncode(toJson());

  factory ReportFilterModel.fromJsonString(String s) =>
      ReportFilterModel.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

/// A named, saved report template.
class ReportTemplate {
  final String name;
  final ReportFilterModel filter;
  final DateTime savedAt;

  const ReportTemplate({
    required this.name,
    required this.filter,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'filter': filter.toJson(),
    'savedAt': savedAt.toIso8601String(),
  };

  factory ReportTemplate.fromJson(Map<String, dynamic> j) => ReportTemplate(
    name: j['name'],
    filter: ReportFilterModel.fromJson(j['filter']),
    savedAt: DateTime.parse(j['savedAt']),
  );
}
