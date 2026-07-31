import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/customer.dart';
import '../models/report_filter_model.dart';
import '../models/sales_analysis_row.dart';
import '../services/report_service.dart';

/// State management for the Sales Analysis tab.
class SalesAnalysisProvider with ChangeNotifier {
  // ── Raw data ──────────────────────────────────
  List<Sale> _allSales = [];
  Map<int, List<SaleItem>> _saleItemsMap = {};
  List<Product> _allProducts = [];
  List<Category> _allCategories = [];
  List<Customer> _allCustomers = [];

  // ── Filter state ──────────────────────────────
  ReportFilterModel _filter = ReportFilterModel.defaultFilter;
  ReportFilterModel _pendingFilter = ReportFilterModel.defaultFilter;

  // ── Results ───────────────────────────────────
  List<SalesAnalysisRow> _analysisRows = [];
  ReportSummary _summary = ReportSummary.empty;
  List<Sale> _filteredSales = [];

  // ── Pagination ────────────────────────────────
  int _currentPage = 0;
  static const int _pageSize = 100;

  // ── Templates ─────────────────────────────────
  List<ReportTemplate> _savedTemplates = [];

  // ── Loading ───────────────────────────────────
  bool _isLoading = false;
  bool _isApplying = false;

  // ── Panel ─────────────────────────────────────
  bool _filterPanelExpanded = true;

  final ReportService _service = const ReportService();

  // ── Getters ───────────────────────────────────
  bool get isLoading => _isLoading;
  bool get isApplying => _isApplying;
  bool get filterPanelExpanded => _filterPanelExpanded;
  ReportFilterModel get filter => _filter;
  ReportFilterModel get pendingFilter => _pendingFilter;
  List<SalesAnalysisRow> get analysisRows => _analysisRows;
  ReportSummary get summary => _summary;
  List<Sale> get filteredSales => _filteredSales;
  List<ReportTemplate> get savedTemplates => _savedTemplates;
  List<Product> get allProducts => _allProducts;
  List<Category> get allCategories => _allCategories;
  List<Customer> get allCustomers => _allCustomers;

  List<SalesAnalysisRow> get pagedRows {
    final start = _currentPage * _pageSize;
    if (start >= _analysisRows.length) return [];
    return _analysisRows.sublist(start, (start + _pageSize).clamp(0, _analysisRows.length));
  }

  int get totalPages => (_analysisRows.length / _pageSize).ceil().clamp(1, 99999);
  int get currentPage => _currentPage;

  // ── Init ──────────────────────────────────────

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allSales = await DatabaseHelper.instance.getSales();
      _allProducts = await DatabaseHelper.instance.getProducts();
      _allCategories = await DatabaseHelper.instance.getCategories();
      _allCustomers = await DatabaseHelper.instance.getCustomers();
      _saleItemsMap.clear();
      for (final sale in _allSales) {
        if (sale.saleId != null) {
          _saleItemsMap[sale.saleId!] =
              await DatabaseHelper.instance.getSaleItems(sale.saleId!);
        }
      }
      await _loadTemplates();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    await applyFilters();
  }

  // ── Pending Filter Updates (before Apply is clicked) ──────────────

  void updatePendingFilter(ReportFilterModel filter) {
    _pendingFilter = filter;
    notifyListeners();
  }

  // ── Apply / Clear ─────────────────────────────

  Future<void> applyFilters() async {
    _filter = _pendingFilter;
    _isApplying = true;
    notifyListeners();

    await Future.delayed(Duration.zero); // allow UI to update

    _filteredSales = _service.filterInvoices(
      sales: _allSales,
      startDate: _filter.effectiveDateRange.$1,
      endDate: _filter.effectiveDateRange.$2,
      paymentMethod: _filter.paymentMethods.isEmpty
          ? 'All'
          : (_filter.paymentMethods.length == 1 ? _filter.paymentMethods.first : 'All'),
      searchQuery: _filter.customerName, // search customer by name text
    );

    // For multi-payment filter, re-filter here
    if (_filter.paymentMethods.length > 1) {
      _filteredSales = _filteredSales
          .where((s) => _filter.paymentMethods.contains(s.paymentMethod ?? 'Cash'))
          .toList();
    }

    final (rows, matchingSales) = _service.generateAnalysis(
      sales: _filteredSales,
      saleItemsMap: _saleItemsMap,
      products: _allProducts,
      categories: _allCategories,
      customers: _allCustomers,
      filter: _filter,
    );
    _analysisRows = rows;

    _summary = _service.calculateSummary(
      rows: _analysisRows,
      matchingSales: matchingSales,
    );

    _currentPage = 0;
    _isApplying = false;
    notifyListeners();
  }

  void clearFilters() {
    _pendingFilter = ReportFilterModel.defaultFilter;
    _filter = ReportFilterModel.defaultFilter;
    notifyListeners();
    applyFilters();
  }

  Future<void> refresh() async {
    await loadData();
  }

  // ── Panel ─────────────────────────────────────

  void toggleFilterPanel() {
    _filterPanelExpanded = !_filterPanelExpanded;
    notifyListeners();
  }

  // ── Pagination ────────────────────────────────

  void goToPage(int page) {
    _currentPage = page.clamp(0, totalPages - 1);
    notifyListeners();
  }

  void nextPage() => goToPage(_currentPage + 1);
  void prevPage() => goToPage(_currentPage - 1);

  // ── Templates ─────────────────────────────────

  Future<void> saveTemplate(String name) async {
    final template = ReportTemplate(
      name: name,
      filter: _filter,
      savedAt: DateTime.now(),
    );
    _savedTemplates.removeWhere((t) => t.name == name);
    _savedTemplates.insert(0, template);
    await _persistTemplates();
    notifyListeners();
  }

  void loadTemplate(ReportTemplate template) {
    _pendingFilter = template.filter;
    notifyListeners();
    applyFilters();
  }

  Future<void> deleteTemplate(String name) async {
    _savedTemplates.removeWhere((t) => t.name == name);
    await _persistTemplates();
    notifyListeners();
  }

  Future<File> _getTemplateFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/smartbill_report_templates.json');
  }

  Future<void> _persistTemplates() async {
    try {
      final file = await _getTemplateFile();
      final data = jsonEncode(_savedTemplates.map((t) => t.toJson()).toList());
      await file.writeAsString(data);
    } catch (_) {}
  }

  Future<void> _loadTemplates() async {
    try {
      final file = await _getTemplateFile();
      if (await file.exists()) {
        final data = await file.readAsString();
        final list = jsonDecode(data) as List;
        _savedTemplates = list.map((e) => ReportTemplate.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
  }
}
