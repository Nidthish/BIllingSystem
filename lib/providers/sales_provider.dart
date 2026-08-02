import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';

class SalesProvider with ChangeNotifier {
  List<Sale> _sales = [];
  Map<int, List<SaleItem>> _saleItemsMap = {};
  bool _isLoading = false;

  List<Sale> get sales => _sales;
  bool get isLoading => _isLoading;

  Future<void> loadSales() async {
    _isLoading = true;
    notifyListeners();
    _sales = await DatabaseHelper.instance.getSales();
    
    _saleItemsMap.clear();
    for (var sale in _sales) {
      if (sale.saleId != null) {
        _saleItemsMap[sale.saleId!] = await DatabaseHelper.instance.getSaleItems(sale.saleId!);
      }
    }
    
    _isLoading = false;
    notifyListeners();
  }

  List<SaleItem> getItemsForSale(int saleId) {
    return _saleItemsMap[saleId] ?? [];
  }

  Future<int> createSale(Sale sale, List<SaleItem> items) async {
    final saleId = await DatabaseHelper.instance.insertSale(sale, items);
    await loadSales();
    return saleId;
  }

  Future<void> deleteSale(int saleId) async {
    await DatabaseHelper.instance.deleteSale(saleId);
    await loadSales();
  }
}
