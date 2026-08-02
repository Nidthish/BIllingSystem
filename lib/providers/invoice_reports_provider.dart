import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/report_filter_model.dart';
import '../services/report_service.dart';

/// State management for the Invoice Reports tab.
class InvoiceReportsProvider with ChangeNotifier {
  // ── Raw data ──────────────────────────────────
  List<Sale> _allSales = [];
  Map<int, List<SaleItem>> _saleItemsMap = {};
  List<Product> _allProducts = [];
  List<Customer> _allCustomers = [];

  // ── Filter state ──────────────────────────────
  String _searchQuery = '';
  int? _customerFilterId;
  String _paymentMethodFilter = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  InvoiceGstFilter _invoiceGstFilter = InvoiceGstFilter.all;

  // ── Pagination ────────────────────────────────
  int _currentPage = 0;
  static const int _pageSize = 50;

  // ── Selection ─────────────────────────────────
  final Set<int> _selectedSaleIds = {};

  // ── Loading ───────────────────────────────────
  bool _isLoading = false;

  // ── Service ───────────────────────────────────
  final ReportService _service = const ReportService();

  // ── Getters ───────────────────────────────────
  bool get isLoading => _isLoading;
  List<Sale> get allSales => _allSales;
  List<Customer> get allCustomers => _allCustomers;
  List<Product> get allProducts => _allProducts;
  String get searchQuery => _searchQuery;
  int? get customerFilterId => _customerFilterId;
  String get paymentMethodFilter => _paymentMethodFilter;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  InvoiceGstFilter get invoiceGstFilter => _invoiceGstFilter;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  Set<int> get selectedSaleIds => _selectedSaleIds;

  List<Sale> get filteredSales => _service.filterInvoices(
    sales: _allSales,
    searchQuery: _searchQuery,
    customerId: _customerFilterId,
    startDate: _startDate,
    endDate: _endDate,
    paymentMethod: _paymentMethodFilter,
    invoiceGstFilter: _invoiceGstFilter,
  );

  List<Sale> get pagedSales {
    final all = filteredSales;
    final start = _currentPage * _pageSize;
    if (start >= all.length) return [];
    return all.sublist(start, (start + _pageSize).clamp(0, all.length));
  }

  int get totalPages => (filteredSales.length / _pageSize).ceil().clamp(1, 99999);

  // ── Invoice summary for KPI cards ─────────────
  double get totalSales => filteredSales.fold(0.0, (s, sale) => s + sale.grandTotal);
  double get totalGst => filteredSales.fold(0.0, (s, sale) => s + sale.gst);
  double get totalDiscount => filteredSales.fold(0.0, (s, sale) => s + sale.discount);
  double get avgInvoiceValue =>
      filteredSales.isEmpty ? 0.0 : totalSales / filteredSales.length;
  double get highestInvoiceAmount =>
      filteredSales.isEmpty ? 0.0 : filteredSales.map((s) => s.grandTotal).reduce((a, b) => a > b ? a : b);
  double get todaySales {
    final now = DateTime.now();
    return filteredSales.where((s) {
      final d = DateTime.tryParse(s.date);
      return d != null && d.year == now.year && d.month == now.month && d.day == now.day;
    }).fold(0.0, (s, sale) => s + sale.grandTotal);
  }

  List<SaleItem> getItemsForSale(int saleId) => _saleItemsMap[saleId] ?? [];

  // ── Data Loading ──────────────────────────────

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allSales = await DatabaseHelper.instance.getSales();
      _allCustomers = await DatabaseHelper.instance.getCustomers();
      _allProducts = await DatabaseHelper.instance.getProducts();

      _saleItemsMap.clear();
      for (final sale in _allSales) {
        if (sale.saleId != null) {
          _saleItemsMap[sale.saleId!] =
              await DatabaseHelper.instance.getSaleItems(sale.saleId!);
        }
      }
    } finally {
      _isLoading = false;
      _currentPage = 0;
      notifyListeners();
    }
  }

  // ── Filter Actions ────────────────────────────

  void setSearchQuery(String q) {
    _searchQuery = q;
    _currentPage = 0;
    notifyListeners();
  }

  void setCustomerFilter(int? customerId) {
    _customerFilterId = customerId;
    _currentPage = 0;
    notifyListeners();
  }

  void setPaymentMethodFilter(String method) {
    _paymentMethodFilter = method;
    _currentPage = 0;
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _currentPage = 0;
    notifyListeners();
  }

  void setInvoiceGstFilter(InvoiceGstFilter filter) {
    _invoiceGstFilter = filter;
    _currentPage = 0;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _customerFilterId = null;
    _paymentMethodFilter = 'All';
    _startDate = null;
    _endDate = null;
    _invoiceGstFilter = InvoiceGstFilter.all;
    _currentPage = 0;
    notifyListeners();
  }

  // ── Pagination ────────────────────────────────

  void goToPage(int page) {
    _currentPage = page.clamp(0, totalPages - 1);
    notifyListeners();
  }

  void nextPage() => goToPage(_currentPage + 1);
  void prevPage() => goToPage(_currentPage - 1);

  // ── Row Selection ─────────────────────────────

  void toggleSelection(int saleId) {
    if (_selectedSaleIds.contains(saleId)) {
      _selectedSaleIds.remove(saleId);
    } else {
      _selectedSaleIds.add(saleId);
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedSaleIds.addAll(filteredSales.map((s) => s.saleId!).whereType<int>());
    notifyListeners();
  }

  void clearSelection() {
    _selectedSaleIds.clear();
    notifyListeners();
  }

  bool get hasSelection => _selectedSaleIds.isNotEmpty;

  List<Sale> get selectedSales =>
      _allSales.where((s) => s.saleId != null && _selectedSaleIds.contains(s.saleId)).toList();

  // ── Delete ────────────────────────────────────

  Future<void> deleteSale(int saleId) async {
    await DatabaseHelper.instance.deleteSale(saleId);
    await loadData();
  }
}
