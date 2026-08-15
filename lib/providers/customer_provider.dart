import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';

class CustomerProvider with ChangeNotifier {
  List<Customer> _customers = [];
  String _searchQuery = '';
  bool _isLoading = false;

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  List<Customer> get filteredCustomers {
    if (_searchQuery.trim().isEmpty) return _customers;
    final q = _searchQuery.trim().toLowerCase();
    return _customers.where((c) =>
      c.customerName.toLowerCase().contains(q) ||
      (c.phone != null && c.phone!.contains(q)) ||
      (c.city != null && c.city!.toLowerCase().contains(q)) ||
      (c.gstNumber != null && c.gstNumber!.toLowerCase().contains(q)) ||
      (c.address != null && c.address!.toLowerCase().contains(q)) ||
      (c.customerId != null && c.customerId.toString() == q)
    ).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();
    _customers = await DatabaseHelper.instance.getCustomers();
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addCustomer(Customer customer) async {
    final id = await DatabaseHelper.instance.insertCustomer(customer);
    await loadCustomers();
    return id;
  }

  Future<void> updateCustomer(Customer customer) async {
    await DatabaseHelper.instance.updateCustomer(customer);
    await loadCustomers();
  }

  Future<void> deleteCustomer(int customerId) async {
    await DatabaseHelper.instance.deleteCustomer(customerId);
    await loadCustomers();
  }
}
