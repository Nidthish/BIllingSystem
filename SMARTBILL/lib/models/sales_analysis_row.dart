/// Represents one aggregated row in the Sales Analysis report.
/// Each row can represent a product, category, customer, payment method,
/// or a time-period group depending on the active [GroupBy] setting.
class SalesAnalysisRow {
  final String groupLabel;
  final int? productId;
  final String productName;
  final String categoryName;
  final String paymentMethod;
  final String customerName;
  final String city;
  final String gstCategory; // "With GST" or "Without GST"

  // Aggregated metrics
  final double qtySold;
  final double saleAmount;       // subtotal without GST
  final double gstAmount;
  final double discount;
  final double purchaseCost;
  final double profit;
  final double finalAmount;      // saleAmount + gstAmount
  final int invoiceCount;

  const SalesAnalysisRow({
    required this.groupLabel,
    this.productId,
    this.productName = '',
    this.categoryName = '',
    this.paymentMethod = '',
    this.customerName = '',
    this.city = '',
    this.gstCategory = 'With GST',
    required this.qtySold,
    required this.saleAmount,
    required this.gstAmount,
    required this.discount,
    required this.purchaseCost,
    required this.profit,
    required this.finalAmount,
    required this.invoiceCount,
  });

  double get avgSellingPrice => qtySold > 0 ? saleAmount / qtySold : 0;
  double get avgProfit => qtySold > 0 ? profit / qtySold : 0;
  double get profitMargin => saleAmount > 0 ? (profit / saleAmount) * 100 : 0;

  SalesAnalysisRow operator +(SalesAnalysisRow other) {
    return SalesAnalysisRow(
      groupLabel: groupLabel,
      productId: productId,
      productName: productName,
      categoryName: categoryName,
      paymentMethod: paymentMethod,
      customerName: customerName,
      city: city,
      gstCategory: gstCategory,
      qtySold: qtySold + other.qtySold,
      saleAmount: saleAmount + other.saleAmount,
      gstAmount: gstAmount + other.gstAmount,
      discount: discount + other.discount,
      purchaseCost: purchaseCost + other.purchaseCost,
      profit: profit + other.profit,
      finalAmount: finalAmount + other.finalAmount,
      invoiceCount: invoiceCount + other.invoiceCount,
    );
  }
}

/// Summary statistics shown in the KPI cards above the table.
class ReportSummary {
  final int totalInvoices;
  final double totalQtySold;
  final double totalSales;
  final double totalGst;
  final double totalDiscount;
  final double totalProfit;
  final double grandTotal;
  final double totalPurchaseCost;
  final double avgInvoiceValue;
  final String highestSellingProduct;
  final String lowestSellingProduct;
  final int totalProducts;
  final double todaySales;
  final double highestInvoiceAmount;

  // Refactored GST Invoice Breakdown
  final int gstBillsCount;
  final double gstBillsSales;
  final double gstBillsGstCollected;
  final int nonGstBillsCount;
  final double nonGstBillsSales;

  // Refactored GST Product Breakdown
  final int gstProductsCount;
  final double gstProductsQtySold;
  final double gstProductsSalesValue;
  final int nonGstProductsCount;
  final double nonGstProductsQtySold;
  final double nonGstProductsSalesValue;

  const ReportSummary({
    required this.totalInvoices,
    required this.totalQtySold,
    required this.totalSales,
    required this.totalGst,
    required this.totalDiscount,
    required this.totalProfit,
    required this.grandTotal,
    required this.totalPurchaseCost,
    required this.avgInvoiceValue,
    required this.highestSellingProduct,
    required this.lowestSellingProduct,
    required this.totalProducts,
    required this.todaySales,
    required this.highestInvoiceAmount,
    this.gstBillsCount = 0,
    this.gstBillsSales = 0.0,
    this.gstBillsGstCollected = 0.0,
    this.nonGstBillsCount = 0,
    this.nonGstBillsSales = 0.0,
    this.gstProductsCount = 0,
    this.gstProductsQtySold = 0.0,
    this.gstProductsSalesValue = 0.0,
    this.nonGstProductsCount = 0,
    this.nonGstProductsQtySold = 0.0,
    this.nonGstProductsSalesValue = 0.0,
  });

  static const ReportSummary empty = ReportSummary(
    totalInvoices: 0,
    totalQtySold: 0,
    totalSales: 0,
    totalGst: 0,
    totalDiscount: 0,
    totalProfit: 0,
    grandTotal: 0,
    totalPurchaseCost: 0,
    avgInvoiceValue: 0,
    highestSellingProduct: '—',
    lowestSellingProduct: '—',
    totalProducts: 0,
    todaySales: 0,
    highestInvoiceAmount: 0,
    gstBillsCount: 0,
    gstBillsSales: 0.0,
    gstBillsGstCollected: 0.0,
    nonGstBillsCount: 0,
    nonGstBillsSales: 0.0,
    gstProductsCount: 0,
    gstProductsQtySold: 0.0,
    gstProductsSalesValue: 0.0,
    nonGstProductsCount: 0,
    nonGstProductsQtySold: 0.0,
    nonGstProductsSalesValue: 0.0,
  );
}
