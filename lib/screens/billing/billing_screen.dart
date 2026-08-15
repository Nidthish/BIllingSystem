import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/customer.dart';
import '../../models/product.dart';
import '../../models/sale.dart';
import '../../models/sale_item.dart';
import '../../models/settings.dart';
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

  // Product Search State
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
    final initialPrice = prod.sellingPrice;
    final unitStr = (prod.unit ?? '').toLowerCase();
    final isPcs = unitStr == 'pcs' || unitStr == 'piece' || unitStr == 'pieces' || unitStr == 'pkt' || unitStr == 'nos' || unitStr == 'bottle' || unitStr == 'box';
    final initialQty = isPcs ? 1.0 : 1000.0;

    final existingIndex = _cart.indexWhere((item) => item.productId == prod.productId);

    if (existingIndex >= 0) {
      final existingItem = _cart[existingIndex];
      final newQty = existingItem.quantity + initialQty;
      setState(() {
        _cart[existingIndex] = SaleItem(
          saleId: existingItem.saleId,
          productId: existingItem.productId,
          quantity: newQty,
          price: existingItem.price,
          total: existingItem.price,
        );
      });
    } else {
      setState(() {
        _cart.add(SaleItem(
          saleId: 0,
          productId: prod.productId!,
          quantity: initialQty,
          price: initialPrice,
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

  double get _taxableAmount {
    if (_selectedGstRate <= 0) return _subtotal;
    return _subtotal / (1 + (_selectedGstRate / 100));
  }

  double get _gst => _subtotal - _taxableAmount;
  double get _cgstAmount => _gst / 2;
  double get _sgstAmount => _gst / 2;
  double get _cgstRate => _selectedGstRate / 2;
  double get _sgstRate => _selectedGstRate / 2;
  double get _grandTotal => _subtotal;

  // --- INVOICE PROCESSING ---
  Future<void> _processInvoice() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty! Add products to bill.')),
      );
      return;
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

        if (_saveCustomerForFuture && customerName.isNotEmpty && customerName != 'Walk-in Customer') {
          final newCust = Customer(
            customerName: customerName,
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
        date: dateStr,
        subtotal: _subtotal,
        discount: 0.0,
        gst: _gst,
        grandTotal: _grandTotal,
        paymentMethod: _paymentMethod,
        gstRate: _selectedGstRate,
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sale processed successfully! Opening print window...'),
          backgroundColor: Colors.green,
        ),
      );

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
            title: const Text('Create Invoice / Billing', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                    flex: 3,
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
                                              setState(() => _selectedProduct = matches.first);
                                            } else if (_selectedProduct != null) {
                                              final selCode = _selectedProduct!.codeOrId.toLowerCase();
                                              final selName = _selectedProduct!.productName.toLowerCase();
                                              if (!query.contains(selCode) && !query.contains(selName)) {
                                                setState(() => _selectedProduct = null);
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
                                              width: 480,
                                              constraints: const BoxConstraints(maxHeight: 280),
                                              child: ListView.builder(
                                                padding: EdgeInsets.zero,
                                                shrinkWrap: true,
                                                itemCount: options.length,
                                                itemBuilder: (BuildContext context, int index) {
                                                  final Product option = options.elementAt(index);
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
                                                    trailing: isLow
                                                        ? const Chip(
                                                            label: Text('Low Stock', style: TextStyle(color: Colors.white, fontSize: 9)),
                                                            backgroundColor: Colors.orange,
                                                          )
                                                        : null,
                                                    onTap: () {
                                                      onSelected(option);
                                                      setState(() => _selectedProduct = option);
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
                                children: [
                                  Text('Invoice GST %:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? Colors.white : Colors.black87)),
                                  Row(
                                    children: [
                                      ...[0.0, 5.0, 12.0, 18.0, 28.0].map((rate) {
                                        final isSelected = _selectedGstRate == rate;
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 4),
                                          child: ChoiceChip(
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
                                          ),
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
                                    isDark: isDark,
                                    onChanged: (newPrice, newQty) {
                                      setState(() {
                                        _cart[index] = SaleItem(
                                          saleId: item.saleId,
                                          productId: item.productId,
                                          quantity: newQty,
                                          price: newPrice,
                                          total: newPrice,
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
  final bool isDark;
  final Function(double newPrice, double newQty) onChanged;
  final VoidCallback onDelete;

  const _CartItemTile({
    super.key,
    required this.item,
    required this.productName,
    required this.productUnit,
    required this.isDark,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends State<_CartItemTile> {
  late TextEditingController _priceController;
  late TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: widget.item.price.toStringAsFixed(2));
    _qtyController = TextEditingController(text: widget.item.quantity.toInt().toString());
  }

  @override
  void didUpdateWidget(covariant _CartItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.price != widget.item.price && double.tryParse(_priceController.text) != widget.item.price) {
      _priceController.text = widget.item.price.toStringAsFixed(2);
    }
    if (oldWidget.item.quantity != widget.item.quantity && double.tryParse(_qtyController.text) != widget.item.quantity) {
      _qtyController.text = widget.item.quantity.toInt().toString();
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  void _onPriceOrQtyChanged() {
    double price = double.tryParse(_priceController.text) ?? widget.item.price;
    double qty = double.tryParse(_qtyController.text) ?? widget.item.quantity;

    widget.onChanged(price, qty);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

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

          // Row 2: Inline Inputs for Qty (g) and Price (₹) - INCREASED BOX SIZE & PADDING
          Row(
            children: [
              // Qty (Grams)
              Expanded(
                child: TextField(
                  controller: _qtyController,
                  decoration: const InputDecoration(
                    labelText: 'Qty (g)',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  onChanged: (_) => _onPriceOrQtyChanged(),
                ),
              ),
              const SizedBox(width: 8),

              // Price (₹)
              Expanded(
                child: TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (₹)',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF00875A)),
                  onChanged: (_) => _onPriceOrQtyChanged(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
