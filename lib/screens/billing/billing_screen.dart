import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../database/database_helper.dart';
import '../../models/customer.dart';
import '../../models/product.dart';
import '../../models/sale.dart';
import '../../models/sale_item.dart';
import '../../models/settings.dart';
import '../../providers/product_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/invoice_reports_provider.dart';
import '../../providers/sales_analysis_provider.dart';
import '../../utils/invoice_generator.dart';
import '../../widgets/print_options_dialog.dart';

class BillingScreen extends StatefulWidget {
  final VoidCallback? onSaleCompleted;

  const BillingScreen({super.key, this.onSaleCompleted});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Customer Selection State
  Customer? _selectedCustomer;
  bool _isWalkIn = true;
  final TextEditingController _walkInNameController = TextEditingController();
  final TextEditingController _walkInPhoneController = TextEditingController();
  final TextEditingController _walkInAddressController = TextEditingController();
  final TextEditingController _walkInGstController = TextEditingController();
  bool _saveCustomerForFuture = false;

  // Product Search & Pre-Cart State
  Product? _selectedProduct;
  final TextEditingController _productSearchController = TextEditingController();
  final FocusNode _productSearchFocusNode = FocusNode();

  // Cart & Calculation State
  final List<SaleItem> _cart = [];
  double _selectedGstRate = 5.0;
  final TextEditingController _gstRateController = TextEditingController(text: '5.0');
  String _paymentMethod = 'Cash';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _gstRateController.text = '5.0';
  }

  @override
  void dispose() {
    _walkInNameController.dispose();
    _walkInPhoneController.dispose();
    _walkInAddressController.dispose();
    _walkInGstController.dispose();
    _productSearchController.dispose();
    _productSearchFocusNode.dispose();
    _gstRateController.dispose();
    super.dispose();
  }

  // --- CART MANAGEMENT ---
  void _addToCart([List<Product>? currentProducts]) async {
    if (_selectedProduct == null) {
      final query = _productSearchController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final allProducts = currentProducts ?? await _dbHelper.getProducts();
        final matches = allProducts.where((p) {
          final nameLower = p.productName.toLowerCase();
          final codeLower = p.codeOrId.toLowerCase();
          final barcodeLower = (p.barcode ?? '').toLowerCase();
          final idStr = p.productId != null ? p.productId.toString() : '';
          return codeLower == query ||
              barcodeLower == query ||
              idStr == query ||
              '#$idStr' == query ||
              nameLower == query ||
              nameLower.contains(query) ||
              codeLower.contains(query) ||
              barcodeLower.contains(query);
        }).toList();

        if (matches.isNotEmpty) {
          _selectedProduct = matches.firstWhere(
            (p) =>
                p.codeOrId.toLowerCase() == query ||
                (p.barcode ?? '').toLowerCase() == query ||
                p.productId.toString() == query,
            orElse: () => matches.first,
          );
        }
      }
    }

    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or search a valid product first')),
      );
      return;
    }

    final prod = _selectedProduct!;

    // 1. OUT OF STOCK PREVENTION (stock <= 0)
    if (prod.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.block, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No stock available! "${prod.productName}" has 0 stock remaining. Cannot add to bill.',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
      _productSearchController.clear();
      setState(() {
        _selectedProduct = null;
      });
      return;
    }

    final initialQty = prod.unit == 'g' ? 1000.0 : 1.0;
    final initialPrice = prod.unit == 'g'
        ? (initialQty / 1000.0) * prod.sellingPrice
        : initialQty * prod.sellingPrice;

    final existingIndex = _cart.indexWhere((item) => item.productId == prod.productId);
    final existingQty = existingIndex >= 0 ? _cart[existingIndex].quantity : 0.0;
    final targetQty = existingQty + initialQty;

    // 2. CHECK TARGET QTY VS AVAILABLE STOCK
    if (targetQty > prod.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot add to bill: Requested quantity (${targetQty.toInt()}) exceeds available stock (${prod.stock} ${prod.unit ?? "pcs"}).',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    // 3. MINIMUM STOCK HIT ALERT
    if (prod.stock <= prod.minimumStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Low Stock Alert: "${prod.productName}" has hit minimum stock level! Remaining stock: ${prod.stock}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    if (existingIndex >= 0) {
      final existingItem = _cart[existingIndex];
      final newQty = existingItem.quantity + initialQty;
      final newTotal = prod.unit == 'g'
          ? (newQty / 1000.0) * existingItem.price
          : newQty * existingItem.price;
      setState(() {
        _cart[existingIndex] = SaleItem(
          saleId: existingItem.saleId,
          productId: existingItem.productId,
          quantity: newQty,
          price: existingItem.price,
          total: newTotal,
        );
      });
    } else {
      setState(() {
        _cart.add(SaleItem(
          saleId: 0,
          productId: prod.productId!,
          quantity: initialQty,
          price: prod.sellingPrice,
          total: initialPrice,
        ));
      });
    }

    _productSearchController.clear();
    setState(() {
      _selectedProduct = null;
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  // --- CALCULATIONS ---
  double get _subtotal {
    double sum = 0.0;
    for (var item in _cart) {
      sum += item.total;
    }
    return sum;
  }

  double get _taxableAmount => _subtotal;
  double get _gst => _selectedGstRate > 0 ? (_taxableAmount * (_selectedGstRate / 100.0)) : 0.0;
  double get _cgstAmount => _gst / 2;
  double get _sgstAmount => _gst / 2;
  double get _cgstRate => _selectedGstRate / 2;
  double get _sgstRate => _selectedGstRate / 2;
  double get _grandTotal => _subtotal + _gst;

  // --- INVOICE PROCESSING ---
  Future<void> _processInvoice() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty! Add products to bill.')),
      );
      return;
    }

    // STRICT STOCK VALIDATION BEFORE BILLING
    final latestProducts = await _dbHelper.getProducts();
    for (var item in _cart) {
      final prodList = latestProducts.where((p) => p.productId == item.productId);
      if (prodList.isNotEmpty) {
        final prod = prodList.first;
        if (prod.stock <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot generate bill: "${prod.productName}" has NO stock remaining (0).'),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }
        if (item.quantity > prod.stock) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot generate bill: "${prod.productName}" quantity (${item.quantity.toInt()} ${prod.unit ?? "pcs"}) exceeds available stock (${prod.stock} ${prod.unit ?? "pcs"}).'),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }
      }
    }

    setState(() => _isProcessing = true);

    try {
      int? customerId;
      String customerName = 'Walk-in Customer';
      String customerPhone = 'N/A';
      String customerAddress = 'N/A';
      String? customerGst;

      if (!_isWalkIn && _selectedCustomer != null) {
        customerId = _selectedCustomer!.customerId;
        customerName = _selectedCustomer!.customerName;
        customerPhone = _selectedCustomer!.phone ?? 'N/A';
        customerAddress = _selectedCustomer!.address ?? 'N/A';
        customerGst = _selectedCustomer!.gstNumber;
      } else if (_isWalkIn) {
        if (_walkInNameController.text.trim().isNotEmpty) {
          customerName = _walkInNameController.text.trim();
        }
        if (_walkInPhoneController.text.trim().isNotEmpty) {
          customerPhone = _walkInPhoneController.text.trim();
        }
        if (_walkInAddressController.text.trim().isNotEmpty) {
          customerAddress = _walkInAddressController.text.trim();
        }
        if (_walkInGstController.text.trim().isNotEmpty) {
          customerGst = _walkInGstController.text.trim();
        }

        // Issue 2 Fix: Save Walking Customer data permanently to Database
        final bool hasCustomInfo = customerName != 'Walk-in Customer' ||
            (customerPhone != 'N/A' && customerPhone.isNotEmpty) ||
            (customerAddress != 'N/A' && customerAddress.isNotEmpty) ||
            (customerGst != null && customerGst.isNotEmpty);

        if (_saveCustomerForFuture || hasCustomInfo) {
          final newCust = Customer(
            customerName: customerName.isNotEmpty ? customerName : 'Walk-in Customer',
            phone: customerPhone != 'N/A' ? customerPhone : null,
            address: customerAddress != 'N/A' ? customerAddress : null,
            gstNumber: customerGst,
          );
          customerId = await _dbHelper.insertCustomer(newCust);
        }
      }

      final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final invNo = await _dbHelper.getNextInvoiceNumber();

      final sale = Sale(
        invoiceNo: invNo,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        customerGst: customerGst,
        date: dateStr,
        subtotal: _subtotal,
        discount: 0.0,
        gst: _gst,
        grandTotal: _grandTotal,
        paymentMethod: _paymentMethod,
        gstRate: _selectedGstRate,
        taxableAmount: _taxableAmount,
        cgstAmount: _cgstAmount,
        sgstAmount: _sgstAmount,
      );

      final saleId = await _dbHelper.insertSale(sale, _cart);
      final saleItems = await _dbHelper.getSaleItems(saleId);
      final allProducts = await _dbHelper.getProducts();
      final settings = await _dbHelper.getSettings() ?? Settings(
        shopName: 'MS TRADERS',
        address: 'No.144A, Mariyam Fathima Building, E.B.Road, Trichy',
        phone: '7708906866',
        gstNumber: '33CXGPS6190A1ZI',
        fssaiNumber: '22421591000206',
        invoicePrefix: 'INV',
      );

      if (!mounted) return;

      await InvoiceGenerator.generateAndSaveInvoice(
        sale: sale,
        items: saleItems,
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        customerGst: customerGst,
        settings: settings,
        allProducts: allProducts,
      );

      if (mounted) {
        PrintOptionsDialog.showInvoiceDialog(
          parentContext: context,
          sale: sale,
          items: saleItems,
          customerName: customerName,
          customerPhone: customerPhone,
          customerAddress: customerAddress,
          customerGst: customerGst,
          settings: settings,
          allProducts: allProducts,
        );
      }

      // Reset state
      setState(() {
        _cart.clear();
        _walkInNameController.clear();
        _walkInPhoneController.clear();
        _walkInAddressController.clear();
        _walkInGstController.clear();
        _selectedCustomer = null;
        _isWalkIn = true;
        _saveCustomerForFuture = false;
      });

      if (mounted) {
        try {
          context.read<ProductProvider>().loadProducts();
          context.read<SalesProvider>().loadSales();
          context.read<CustomerProvider>().loadCustomers();
          context.read<InvoiceReportsProvider>().loadData();
          context.read<SalesAnalysisProvider>().loadData();
        } catch (_) {}
      }

      widget.onSaleCompleted?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing invoice: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder(
      future: Future.wait([
        _dbHelper.getCustomers(),
        _dbHelper.getProducts(),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        final customers = (snapshot.data?[0] as List<Customer>?) ?? [];
        final products = (snapshot.data?[1] as List<Product>?) ?? [];

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Image.asset(
                  'assets/images/sk_logo.png',
                  height: 32,
                  width: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) => const Icon(Icons.receipt_long, color: Color(0xFF00875A), size: 28),
                ),
                const SizedBox(width: 10),
                const Text('Create Invoice / Billing', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            elevation: 0,
          ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Customer Details, Product Search & Calculation Details Card
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- CUSTOMER SECTION ---
                      Card(
                        elevation: 1,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Customer Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [
                                      ChoiceChip(
                                        visualDensity: VisualDensity.compact,
                                        label: Text(
                                          'Existing',
                                          style: TextStyle(
                                            color: !_isWalkIn ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        selected: !_isWalkIn,
                                        selectedColor: const Color(0xFF00875A),
                                        onSelected: (val) => setState(() => _isWalkIn = !val),
                                      ),
                                      const SizedBox(width: 8),
                                      ChoiceChip(
                                        visualDensity: VisualDensity.compact,
                                        label: Text(
                                          'Walk-in',
                                          style: TextStyle(
                                            color: _isWalkIn ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        selected: _isWalkIn,
                                        selectedColor: const Color(0xFF00875A),
                                        onSelected: (val) => setState(() => _isWalkIn = val),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (!_isWalkIn) ...[
                                DropdownButtonFormField<Customer>(
                                  initialValue: customers.contains(_selectedCustomer) ? _selectedCustomer : null,
                                  dropdownColor: isDark ? const Color(0xFF1C382B) : Colors.white,
                                  decoration: const InputDecoration(
                                    labelText: 'Select Registered Customer',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    prefixIcon: Icon(Icons.person, size: 18),
                                  ),
                                  items: customers.map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      '${c.customerName} (${c.phone ?? "No Phone"})',
                                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                                    ),
                                  )).toList(),
                                  onChanged: (val) => setState(() => _selectedCustomer = val),
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _walkInNameController,
                                        decoration: const InputDecoration(
                                          labelText: 'Customer Name',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          prefixIcon: Icon(Icons.person_outline, size: 18),
                                        ),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _walkInPhoneController,
                                        decoration: const InputDecoration(
                                          labelText: 'Phone Number (10 digits)',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          prefixIcon: Icon(Icons.phone, size: 18),
                                        ),
                                        style: const TextStyle(fontSize: 13),
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(10),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _walkInAddressController,
                                        decoration: const InputDecoration(
                                          labelText: 'Address',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                                        ),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _walkInGstController,
                                        decoration: const InputDecoration(
                                          labelText: 'GST Number (Optional)',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          prefixIcon: Icon(Icons.receipt_long, size: 18),
                                        ),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                CheckboxListTile(
                                  value: _saveCustomerForFuture,
                                  title: const Text('Save customer to database for future sales', style: TextStyle(fontSize: 11)),
                                  controlAffinity: ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  dense: true,
                                  onChanged: (val) => setState(() => _saveCustomerForFuture = val ?? false),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // --- PRODUCT SELECTION AUTOCOMPLETE ---
                      Card(
                        elevation: 1,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Add Products to Bill', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: RawAutocomplete<Product>(
                                      textEditingController: _productSearchController,
                                      focusNode: _productSearchFocusNode,
                                      optionsBuilder: (TextEditingValue textEditingValue) {
                                        final query = textEditingValue.text.trim().toLowerCase();
                                        if (query.isEmpty) {
                                          return products;
                                        }
                                        return products.where((Product option) {
                                          final nameMatch = option.productName.toLowerCase().contains(query);
                                          final codeOrIdMatch = option.codeOrId.toLowerCase().contains(query);
                                          final barcodeMatch = (option.barcode ?? '').toLowerCase().contains(query);
                                          final idStr = option.productId != null ? option.productId.toString() : '';
                                          final idMatch = idStr == query || '#$idStr' == query;
                                          return nameMatch || codeOrIdMatch || barcodeMatch || idMatch;
                                        });
                                      },
                                      displayStringForOption: (Product option) {
                                        final code = option.codeOrId;
                                        return code.isNotEmpty ? '${option.productName} ($code)' : option.productName;
                                      },
                                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                        return TextField(
                                          controller: controller,
                                          focusNode: focusNode,
                                          decoration: const InputDecoration(
                                            labelText: 'Search Product Name or Code (e.g. SK002)...',
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            prefixIcon: Icon(Icons.search, size: 18),
                                            suffixIcon: Icon(Icons.arrow_drop_down, size: 18),
                                          ),
                                          style: const TextStyle(fontSize: 13),
                                          onChanged: (val) {
                                            final query = val.trim().toLowerCase();
                                            if (query.isEmpty) {
                                              if (_selectedProduct != null) {
                                                setState(() => _selectedProduct = null);
                                              }
                                              return;
                                            }
                                            final matches = products.where((p) =>
                                                p.codeOrId.toLowerCase() == query ||
                                                (p.barcode ?? '').toLowerCase() == query ||
                                                p.productName.toLowerCase() == query).toList();
                                            if (matches.isNotEmpty) {
                                              setState(() {
                                                _selectedProduct = matches.first;
                                              });
                                            } else if (_selectedProduct != null) {
                                              final selCode = _selectedProduct!.codeOrId.toLowerCase();
                                              final selName = _selectedProduct!.productName.toLowerCase();
                                              if (!query.contains(selCode) && !query.contains(selName)) {
                                                setState(() {
                                                  _selectedProduct = null;
                                                });
                                              }
                                            }
                                          },
                                          onSubmitted: (value) {
                                            final query = value.trim().toLowerCase();
                                            if (query.isNotEmpty) {
                                              final matches = products.where((p) {
                                                final nameLower = p.productName.toLowerCase();
                                                final codeLower = p.codeOrId.toLowerCase();
                                                final barcodeLower = (p.barcode ?? '').toLowerCase();
                                                final idStr = p.productId != null ? p.productId.toString() : '';
                                                return codeLower == query ||
                                                    barcodeLower == query ||
                                                    idStr == query ||
                                                    '#$idStr' == query ||
                                                    nameLower == query ||
                                                    nameLower.contains(query) ||
                                                    codeLower.contains(query) ||
                                                    barcodeLower.contains(query);
                                              }).toList();

                                              if (matches.isNotEmpty) {
                                                final exactMatch = matches.firstWhere(
                                                  (p) =>
                                                      p.codeOrId.toLowerCase() == query ||
                                                      (p.barcode ?? '').toLowerCase() == query ||
                                                      p.productId.toString() == query,
                                                  orElse: () => matches.first,
                                                );
                                                setState(() {
                                                  _selectedProduct = exactMatch;
                                                  controller.text = exactMatch.codeOrId.isNotEmpty
                                                      ? '${exactMatch.productName} (${exactMatch.codeOrId})'
                                                      : exactMatch.productName;
                                                });
                                                onFieldSubmitted();
                                                _addToCart(products);
                                              }
                                            }
                                          },
                                        );
                                      },
                                      optionsViewBuilder: (context, onSelected, options) {
                                        return Align(
                                          alignment: Alignment.topLeft,
                                          child: Material(
                                            elevation: 4,
                                            color: isDark ? const Color(0xFF1C382B) : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              constraints: BoxConstraints(
                                                maxWidth: MediaQuery.of(context).size.width * 0.55,
                                                maxHeight: 280,
                                              ),
                                              child: ListView.builder(
                                                padding: EdgeInsets.zero,
                                                shrinkWrap: true,
                                                itemCount: options.length,
                                                itemBuilder: (BuildContext context, int index) {
                                                  final Product option = options.elementAt(index);
                                                  final isOut = option.stock <= 0;
                                                  final isLow = option.stock <= option.minimumStock;
                                                  final codeStr = (option.barcode != null && option.barcode!.isNotEmpty)
                                                      ? option.barcode!
                                                      : '#${option.productId ?? "-"}';
                                                  return ListTile(
                                                    title: Text(
                                                      option.productName,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: isDark ? Colors.white : Colors.black87,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    subtitle: Text(
                                                      'Code: $codeStr | Stock: ${option.stock} ${option.unit ?? "pcs"} | Price: ₹${option.sellingPrice}',
                                                      style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 11),
                                                    ),
                                                    trailing: isOut
                                                        ? const Chip(
                                                            label: Text('NO STOCK (0)', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                                            backgroundColor: Colors.red,
                                                            visualDensity: VisualDensity.compact,
                                                          )
                                                        : (isLow
                                                            ? Chip(
                                                                label: Text('LOW STOCK (${option.stock})', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                                                backgroundColor: Colors.orange,
                                                                visualDensity: VisualDensity.compact,
                                                              )
                                                            : null),
                                                    onTap: () {
                                                      onSelected(option);
                                                      setState(() {
                                                        _selectedProduct = option;
                                                      });
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      onSelected: (Product selection) {
                                        setState(() {
                                          _selectedProduct = selection;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                                    label: const Text('Add to Cart', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00875A),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                    onPressed: () => _addToCart(products),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // --- CALCULATION & PAYMENT DETAILS CARD (PLACED UNDER PRODUCT SELECT!) ---
                      Card(
                        elevation: 1,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Calculation & Payment Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [
                                      Text('Payment: ', style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w600)),
                                      DropdownButton<String>(
                                        value: _paymentMethod,
                                        isDense: true,
                                        underline: const SizedBox(),
                                        dropdownColor: isDark ? const Color(0xFF1C382B) : Colors.white,
                                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                                        items: ['Cash', 'UPI', 'Card'].map((m) => DropdownMenuItem(
                                          value: m,
                                          child: Text(m, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 12)),
                                        )).toList(),
                                        onChanged: (val) => setState(() => _paymentMethod = val ?? 'Cash'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text('Invoice GST %:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? Colors.white : Colors.black87)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Wrap(
                                        alignment: WrapAlignment.end,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: [
                                          ...[0.0, 5.0, 12.0, 18.0, 28.0].map((rate) {
                                            final isSelected = _selectedGstRate == rate;
                                            return ChoiceChip(
                                              visualDensity: VisualDensity.compact,
                                              label: Text('${rate.toStringAsFixed(0)}%'),
                                              selected: isSelected,
                                              selectedColor: const Color(0xFF00875A),
                                              backgroundColor: isDark ? const Color(0xFF1C382B) : Colors.grey.shade200,
                                              labelStyle: TextStyle(
                                                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              onSelected: (_) {
                                                setState(() {
                                                  _selectedGstRate = rate;
                                                  _gstRateController.text = rate.toStringAsFixed(rate == rate.roundToDouble() ? 0 : 1);
                                                });
                                              },
                                            );
                                          }),
                                          SizedBox(
                                            width: 55,
                                            child: TextField(
                                              controller: _gstRateController,
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                suffixText: '%',
                                                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                              ),
                                              style: const TextStyle(fontSize: 11),
                                              onChanged: (val) {
                                                final parsed = double.tryParse(val) ?? 0.0;
                                                setState(() {
                                                  _selectedGstRate = parsed.clamp(0.0, 100.0);
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Subtotal', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
                                  Text('₹${_subtotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87)),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Taxable Amount', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
                                  Text('₹${_taxableAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                                ],
                              ),
                              if (_selectedGstRate > 0) ...[
                                const SizedBox(height: 3),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('CGST (${_cgstRate.toStringAsFixed(1)}%)', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade700)),
                                    Text('₹${_cgstAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.grey.shade700)),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('SGST (${_sgstRate.toStringAsFixed(1)}%)', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade700)),
                                    Text('₹${_sgstAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.grey.shade700)),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total GST (${_selectedGstRate.toStringAsFixed(0)}%)', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
                                    Text('₹${_gst.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF34D399) : const Color(0xFF00875A))),
                                  ],
                                ),
                              ] else ...[
                                const SizedBox(height: 3),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('GST (0%)', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade700)),
                                    Text('₹0.00', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade700)),
                                  ],
                                ),
                              ],
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(
                                    '₹${_grandTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF00875A)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: ElevatedButton.icon(
                                  icon: _isProcessing
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Icon(Icons.print, size: 18),
                                  label: Text(
                                    _isProcessing ? 'PROCESSING INVOICE...' : 'GENERATE & PRINT INVOICE',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00875A),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.grey.shade400,
                                    disabledForegroundColor: Colors.white70,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: _isProcessing ? null : _processInvoice,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Right Column: Current Cart Items Panel (FULL vertical height!)
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(left: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: const Color(0xFF00875A),
                        width: double.infinity,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Current Bill Items',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Chip(
                              label: Text(
                                '${_cart.length} Items',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: isDark ? Colors.white : const Color(0xFF00875A),
                                ),
                              ),
                              backgroundColor: isDark ? const Color(0xFF064E3B) : Colors.white,
                            ),
                          ],
                        ),
                      ),

                      // Cart List View (Takes full vertical height!)
                      Expanded(
                        child: _cart.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shopping_bag_outlined, size: 48, color: isDark ? Colors.white54 : Colors.grey),
                                    const SizedBox(height: 8),
                                    Text('Cart is empty', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: _cart.length,
                                itemBuilder: (context, index) {
                                  final item = _cart[index];
                                  final productList = products.where((p) => p.productId == item.productId);
                                  final prodObj = productList.isNotEmpty ? productList.first : null;
                                  final productName = prodObj != null ? prodObj.productName : 'Product #${item.productId}';
                                  final productUnit = prodObj?.unit ?? 'g';

                                  return _CartItemTile(
                                    key: ValueKey('cart_item_${item.productId}_$index'),
                                    item: item,
                                    productName: productName,
                                    productUnit: productUnit,
                                    sellingPrice: prodObj?.sellingPrice ?? 0.0,
                                    maxStock: prodObj?.stock,
                                    isDark: isDark,
                                    onChanged: (newRate, newQty, newTotal) {
                                      setState(() {
                                        _cart[index] = SaleItem(
                                          saleId: item.saleId,
                                          productId: item.productId,
                                          quantity: newQty,
                                          price: newRate,
                                          total: newTotal,
                                        );
                                      });
                                    },
                                    onDelete: () => _removeFromCart(index),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── INLINE EDITABLE CART ITEM TILE WIDGET (REDUCED FONT SIZE) ──
class _CartItemTile extends StatefulWidget {
  final SaleItem item;
  final String productName;
  final String productUnit;
  final double sellingPrice;
  final int? maxStock;
  final bool isDark;
  final Function(double newRate, double newQty, double newTotal) onChanged;
  final VoidCallback onDelete;

  const _CartItemTile({
    super.key,
    required this.item,
    required this.productName,
    required this.productUnit,
    required this.sellingPrice,
    this.maxStock,
    required this.isDark,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends State<_CartItemTile> {
  late TextEditingController _qtyController;
  late TextEditingController _rateController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(
      text: widget.item.quantity % 1 == 0
          ? widget.item.quantity.toInt().toString()
          : widget.item.quantity.toString(),
    );
    _rateController = TextEditingController(
      text: widget.item.price % 1 == 0
          ? widget.item.price.toInt().toString()
          : widget.item.price.toStringAsFixed(2),
    );
  }

  @override
  void didUpdateWidget(covariant _CartItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.quantity != widget.item.quantity &&
        double.tryParse(_qtyController.text) != widget.item.quantity) {
      _qtyController.text = widget.item.quantity % 1 == 0
          ? widget.item.quantity.toInt().toString()
          : widget.item.quantity.toString();
    }
    if (oldWidget.item.price != widget.item.price &&
        double.tryParse(_rateController.text) != widget.item.price) {
      _rateController.text = widget.item.price % 1 == 0
          ? widget.item.price.toInt().toString()
          : widget.item.price.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _onPriceOrQtyChanged() {
    final qtyText = _qtyController.text.trim();
    final rateText = _rateController.text.trim();

    double qty = double.tryParse(qtyText) ?? 0.0;
    double rate = double.tryParse(rateText) ?? 0.0;

    if (widget.maxStock != null && qty > widget.maxStock!) {
      qty = widget.maxStock!.toDouble();
      _qtyController.text = qty % 1 == 0 ? qty.toInt().toString() : qty.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quantity for "${widget.productName}" capped at max available stock (${widget.maxStock} ${widget.productUnit}).'),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    final double calculatedTotal = widget.productUnit == 'g'
        ? (qty / 1000.0) * rate
        : qty * rate;

    setState(() {}); // Updates formula text immediately in the state!
    widget.onChanged(rate, qty, calculatedTotal);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final qtyText = _qtyController.text.trim();
    final rateText = _rateController.text.trim();
    final double qty = double.tryParse(qtyText) ?? 0.0;
    final double rate = double.tryParse(rateText) ?? 0.0;
    final double calculatedTotal = widget.productUnit == 'g'
        ? (qty / 1000.0) * rate
        : qty * rate;

    final String unitLabel = widget.productUnit == 'g'
        ? 'kg'
        : (widget.productUnit.isEmpty ? 'pc' : widget.productUnit);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C382B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Product Name & Delete Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.productName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Remove Item',
                onPressed: widget.onDelete,
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Row 2: Qty (modifiable) X Price per unit (modifiable) = Calculated Total
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Qty TextField
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _qtyController,
                  decoration: InputDecoration(
                    labelText: 'Qty (${widget.productUnit})',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  onChanged: (_) => _onPriceOrQtyChanged(),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  'X',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
              // Price per unit / kg TextField
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _rateController,
                  decoration: InputDecoration(
                    labelText: 'Price / $unitLabel (₹)',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00875A)),
                  onChanged: (_) => _onPriceOrQtyChanged(),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  '=',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
              // Calculated Total display
              Expanded(
                child: Text(
                  '₹${calculatedTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00875A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
