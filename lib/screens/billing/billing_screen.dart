import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/product.dart';
import '../../models/customer.dart';
import '../../models/sale.dart';
import '../../models/sale_item.dart';
import '../../models/settings.dart';
import 'package:pdf/pdf.dart';
import '../../utils/invoice_generator.dart';
import '../../widgets/print_options_dialog.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  bool _isWalkIn = false;
  bool _saveCustomerForFuture = false;
  bool _isProcessing = false;

  Customer? _selectedCustomer;
  final TextEditingController _walkInNameController = TextEditingController();
  final TextEditingController _walkInPhoneController = TextEditingController();
  final TextEditingController _walkInAddressController = TextEditingController();

  Product? _selectedProduct;
  final TextEditingController _productSearchController = TextEditingController();
  final FocusNode _productSearchFocusNode = FocusNode();
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final TextEditingController _gstRateController = TextEditingController(text: '5.0');
  
  final List<SaleItem> _cart = [];
  String _paymentMethod = 'Cash';
  double _selectedGstRate = 5.0; // Manual invoice GST rate

  @override
  void initState() {
    super.initState();
    // Preload PDF fonts & images early so printing opens instantly
    InvoiceGenerator.preloadAssets();
  }

  @override
  void dispose() {
    _walkInNameController.dispose();
    _walkInPhoneController.dispose();
    _walkInAddressController.dispose();
    _productSearchController.dispose();
    _productSearchFocusNode.dispose();
    _qtyController.dispose();
    _gstRateController.dispose();
    super.dispose();
  }

  void _addToCart() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a product first')));
      return;
    }
    
    double qty = double.tryParse(_qtyController.text) ?? 1;
    if (qty <= 0) qty = 1;

    // Stock & Product Limit Validation
    int currentCartQty = 0;
    final existingIndex = _cart.indexWhere((item) => item.productId == _selectedProduct!.productId);
    if (existingIndex >= 0) {
      currentCartQty = _cart[existingIndex].quantity.toInt();
    } else if (_cart.length >= 40) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('One invoice can contain only 40 products.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedProduct!.stock < (currentCartQty + qty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot add! Available stock for ${_selectedProduct!.productName} is ${_selectedProduct!.stock}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    double price = _selectedProduct!.sellingPrice;
    double total = price * qty;

    setState(() {
      if (existingIndex >= 0) {
        final existing = _cart[existingIndex];
        final newQty = existing.quantity + qty;
        _cart[existingIndex] = SaleItem(
          saleId: 0,
          productId: existing.productId,
          quantity: newQty,
          price: existing.price,
          total: existing.price * newQty,
        );
      } else {
        _cart.add(SaleItem(
          saleId: 0,
          productId: _selectedProduct!.productId!,
          quantity: qty,
          price: price,
          total: total,
        ));
      }
      _selectedProduct = null;
      _productSearchController.clear();
      _qtyController.text = '1';
    });
  }

  void _updateQuantity(int index, double newQty) {
    if (newQty <= 0) {
      _removeFromCart(index);
      return;
    }

    final item = _cart[index];
    final products = context.read<ProductProvider>().products;
    final productList = products.where((p) => p.productId == item.productId);
    
    if (productList.isNotEmpty) {
      final product = productList.first;
      if (product.stock < newQty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stock limit reached! Max available: ${product.stock}')),
        );
        return;
      }
    }

    setState(() {
      _cart[index] = SaleItem(
        saleId: item.saleId,
        productId: item.productId,
        quantity: newQty,
        price: item.price,
        total: item.price * newQty,
      );
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  double get _subtotal => _cart.fold(0.0, (sum, item) => sum + item.total);
  double get _discount => 0.0;
  double get _taxableAmount => (_subtotal - _discount).clamp(0.0, double.infinity);
  double get _cgstRate => _selectedGstRate / 2;
  double get _sgstRate => _selectedGstRate / 2;
  double get _cgstAmount => _taxableAmount * (_cgstRate / 100);
  double get _sgstAmount => _taxableAmount * (_sgstRate / 100);
  double get _gst => _cgstAmount + _sgstAmount;
  double get _grandTotal => _taxableAmount + _gst;

  Future<void> _processInvoice() async {
    if (_isProcessing) return;

    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart is empty! Add products first.')));
      return;
    }

    if (_cart.length > 40) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('One invoice can contain only 40 products.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String customerName = '';
    String customerPhone = '';
    String customerAddress = '';
    int? customerId;

    if (_isWalkIn) {
      customerName = _walkInNameController.text.trim();
      customerPhone = _walkInPhoneController.text.trim();
      customerAddress = _walkInAddressController.text.trim();

      if (customerPhone.isNotEmpty) {
        final phoneDigits = customerPhone.replaceAll(RegExp(r'\D'), '');
        if (phoneDigits.length != 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone number must be exactly 10 digits!'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (_saveCustomerForFuture) {
        final phoneDigits = customerPhone.replaceAll(RegExp(r'\D'), '');
        if (phoneDigits.length != 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A valid 10-digit phone number is required to save customer for future sales!'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final newCust = Customer(
          customerName: customerName.isEmpty ? 'Walk-in Customer' : customerName,
          phone: customerPhone,
          address: customerAddress,
        );
        customerId = await context.read<CustomerProvider>().addCustomer(newCust);
      }

      if (customerName.isEmpty) {
        customerName = 'Walk-in Customer';
      }
    } else {
      if (_selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an existing customer or switch to Walk-in')));
        return;
      }
      customerId = _selectedCustomer!.customerId;
      customerName = _selectedCustomer!.customerName;
      customerPhone = _selectedCustomer!.phone ?? '';
      customerAddress = _selectedCustomer!.address ?? '';
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final settingsProvider = context.read<SettingsProvider>();
      var rawSettings = settingsProvider.settings;
      if (rawSettings == null) {
        await settingsProvider.loadSettings();
        rawSettings = settingsProvider.settings;
      }
      final Settings activeSettings = rawSettings ?? Settings(
        shopName: 'MS TRADERS',
        address: '138, Mullai Street, Sanjeevi Nagar,\nTiruchirappalli - 620002, Tamil Nadu, India.',
        phone: '7708906866',
        gstNumber: '33ABCDE1234F1Z5',
        invoicePrefix: 'INV',
      );

      String prefix = activeSettings.invoicePrefix;
      String invoiceNo = '$prefix-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

      Sale sale = Sale(
        invoiceNo: invoiceNo,
        customerId: customerId,
        customerName: customerName,
        date: DateTime.now().toIso8601String(),
        subtotal: _subtotal,
        discount: _discount,
        gst: _gst,
        grandTotal: _grandTotal,
        paymentMethod: _paymentMethod,
        gstRate: _selectedGstRate,
        cgstRate: _cgstRate,
        sgstRate: _sgstRate,
        taxableAmount: _taxableAmount,
        cgstAmount: _cgstAmount,
        sgstAmount: _sgstAmount,
      );

      // Save sale to DB & decrease stock
      final messenger = ScaffoldMessenger.of(context);
      final salesProvider = context.read<SalesProvider>();
      final productProvider = context.read<ProductProvider>();

      final cartCopy = List<SaleItem>.from(_cart);

      await salesProvider.createSale(sale, _cart);
      await productProvider.loadProducts(); // Refresh live stock in state

      // Save invoice PDF quietly to Invoices/ folder (A4 default)
      await InvoiceGenerator.generateAndSaveInvoice(
        sale: sale,
        items: cartCopy,
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        customerGst: _selectedCustomer?.gstNumber,
        settings: activeSettings,
        allProducts: productProvider.products,
      );

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text('Invoice $invoiceNo created & saved to Invoices folder!')),
      );

      // Clear form & reset processing state immediately so UI resets instantly
      setState(() {
        _cart.clear();
        _selectedCustomer = null;
        _walkInNameController.clear();
        _walkInPhoneController.clear();
        _walkInAddressController.clear();
        _saveCustomerForFuture = false;
        _isProcessing = false;
      });

      // Show Print Options Dialog (A4 / A5 radio selection)
      if (mounted) {
        PrintOptionsDialog.showInvoiceDialog(
          parentContext: context,
          sale: sale,
          items: cartCopy,
          customerName: customerName,
          customerPhone: customerPhone,
          customerAddress: customerAddress,
          customerGst: _selectedCustomer?.gstNumber,
          settings: activeSettings,
          allProducts: productProvider.products,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showPrintOptionsDialog({
    required BuildContext parentContext,
    required Sale sale,
    required List<SaleItem> items,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    String? customerGst,
    required Settings settings,
    required List<Product> allProducts,
  }) {
    String selectedPaperFormat = 'A4'; // 'A4' default radio selection

    showDialog(
      context: parentContext,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF00875A), size: 28),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Invoice Saved Successfully!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invoice #${sale.invoiceNo} has been saved to your "Invoices" folder.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Paper Format for Printing:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2D27) : const Color(0xFFF4F9F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00875A).withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          value: 'A4',
                          groupValue: selectedPaperFormat,
                          activeColor: const Color(0xFF00875A),
                          title: const Text('A4 Paper Format (Default - Standard Sheet)', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text('Full A4 sheet (210 x 297 mm)'),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedPaperFormat = val);
                          },
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        RadioListTile<String>(
                          value: 'A5',
                          groupValue: selectedPaperFormat,
                          activeColor: const Color(0xFF00875A),
                          title: const Text('A5 Paper Format (Compact Sheet)', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text('Half A4 sheet (148 x 210 mm)'),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedPaperFormat = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text('Close (No Hard Copy)'),
                  onPressed: () {
                    if (dialogCtx.mounted && Navigator.canPop(dialogCtx)) {
                      Navigator.pop(dialogCtx);
                    }
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.print),
                  label: const Text('Print Invoice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00875A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () async {
                    if (dialogCtx.mounted && Navigator.canPop(dialogCtx)) {
                      Navigator.pop(dialogCtx);
                    }

                    final format = selectedPaperFormat == 'A5' ? PdfPageFormat.a5 : PdfPageFormat.a4;
                    final pdfBytes = await InvoiceGenerator.buildInvoicePdfBytes(
                      sale: sale,
                      items: items,
                      customerName: customerName,
                      customerPhone: customerPhone,
                      customerAddress: customerAddress,
                      customerGst: customerGst,
                      settings: settings,
                      allProducts: allProducts,
                      pageFormat: format,
                    );

                    bool printed = false;
                    try {
                      printed = await InvoiceGenerator.directPrintInvoiceBytes(
                        pdfBytes: pdfBytes,
                        invoiceNo: sale.invoiceNo,
                      );
                    } catch (e) {
                      debugPrint('Print error: $e');
                    }

                    if (parentContext.mounted) {
                      if (printed) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            content: Text('Invoice sent directly to printer!'),
                            backgroundColor: Color(0xFF00875A),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            content: Text('Invoice saved in "Invoices" folder! Connect a paper printer to print hard copies.'),
                            backgroundColor: Color(0xFF00875A),
                            duration: Duration(seconds: 4),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<CustomerProvider>().customers;
    final products = context.watch<ProductProvider>().products;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Invoice / Billing'),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Section: Customer Selection & Product Search
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- CUSTOMER SECTION ---
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Customer Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ChoiceChip(
                                  label: Text(
                                    'Existing Customer',
                                    style: TextStyle(
                                      color: !_isWalkIn ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  selected: !_isWalkIn,
                                  selectedColor: const Color(0xFF00875A),
                                  onSelected: (val) => setState(() => _isWalkIn = !val),
                                ),
                                const SizedBox(width: 12),
                                ChoiceChip(
                                  label: Text(
                                    'Walk-in Customer',
                                    style: TextStyle(
                                      color: _isWalkIn ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  selected: _isWalkIn,
                                  selectedColor: const Color(0xFF00875A),
                                  onSelected: (val) => setState(() => _isWalkIn = val),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (!_isWalkIn) ...[
                              DropdownButtonFormField<Customer>(
                                initialValue: _selectedCustomer,
                                dropdownColor: isDark ? const Color(0xFF1C382B) : Colors.white,
                                decoration: const InputDecoration(
                                  labelText: 'Select Registered Customer',
                                  prefixIcon: Icon(Icons.person),
                                ),
                                items: customers.map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    '${c.customerName} (${c.phone ?? "No Phone"})',
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
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
                                        prefixIcon: Icon(Icons.person_outline),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _walkInPhoneController,
                                      decoration: const InputDecoration(
                                        labelText: 'Phone Number (10 digits)',
                                        prefixIcon: Icon(Icons.phone),
                                      ),
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(10),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _walkInAddressController,
                                decoration: const InputDecoration(
                                  labelText: 'Address',
                                  prefixIcon: Icon(Icons.location_on_outlined),
                                ),
                              ),
                              const SizedBox(height: 8),
                              CheckboxListTile(
                                value: _saveCustomerForFuture,
                                title: const Text('Save customer to database for future sales'),
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (val) => setState(() => _saveCustomerForFuture = val ?? false),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- PRODUCT SELECTION AUTOCOMPLETE ---
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Add Products to Bill', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: RawAutocomplete<Product>(
                                    textEditingController: _productSearchController,
                                    focusNode: _productSearchFocusNode,
                                    optionsBuilder: (TextEditingValue textEditingValue) {
                                      if (textEditingValue.text.isEmpty) {
                                        return products;
                                      }
                                      return products.where((Product option) {
                                        return option.productName
                                            .toLowerCase()
                                            .contains(textEditingValue.text.toLowerCase());
                                      });
                                    },
                                    displayStringForOption: (Product option) => option.productName,
                                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                      return TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        decoration: const InputDecoration(
                                          labelText: 'Search Product Name...',
                                          prefixIcon: Icon(Icons.search),
                                          suffixIcon: Icon(Icons.arrow_drop_down),
                                        ),
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
                                            width: 400,
                                            constraints: const BoxConstraints(maxHeight: 250),
                                            child: ListView.builder(
                                              padding: EdgeInsets.zero,
                                              shrinkWrap: true,
                                              itemCount: options.length,
                                              itemBuilder: (BuildContext context, int index) {
                                                final Product option = options.elementAt(index);
                                                final isLow = option.stock <= option.minimumStock;
                                                return ListTile(
                                                  title: Text(option.productName, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                                  subtitle: Text('Stock: ${option.stock} ${option.unit ?? "pcs"} | Price: ₹${option.sellingPrice}', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600)),
                                                  trailing: isLow
                                                      ? const Chip(label: Text('Low Stock', style: TextStyle(color: Colors.white, fontSize: 10)), backgroundColor: Colors.orange)
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
                                      setState(() => _selectedProduct = selection);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 90,
                                  child: TextField(
                                    controller: _qtyController,
                                    decoration: const InputDecoration(labelText: 'Qty'),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add_shopping_cart),
                                  label: const Text('Add'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  ),
                                  onPressed: _addToCart,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Right Section: Current Cart & Totals
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
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFF00875A),
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current Bill Items',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Chip(
                          label: Text(
                            '${_cart.length} Items',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF00875A),
                            ),
                          ),
                          backgroundColor: isDark ? const Color(0xFF064E3B) : Colors.white,
                        ),
                      ],
                    ),
                  ),

                  // Cart List View
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
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _cart.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
                            itemBuilder: (context, index) {
                              final item = _cart[index];
                              final productList = products.where((p) => p.productId == item.productId);
                              final productName = productList.isNotEmpty ? productList.first.productName : 'Product #${item.productId}';

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            productName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            '₹${item.price} each',
                                            style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Quantity Controls (+, -, Direct text)
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.remove_circle_outline, size: 20, color: isDark ? Colors.white70 : Colors.black54),
                                          onPressed: () => _updateQuantity(index, item.quantity - 1),
                                        ),
                                        Text(
                                          '${item.quantity}',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black87),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.add_circle_outline, size: 20, color: isDark ? Colors.white70 : Colors.black54),
                                          onPressed: () => _updateQuantity(index, item.quantity + 1),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 80,
                                      child: Text(
                                        '₹${item.total.toStringAsFixed(2)}',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () => _removeFromCart(index),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // Bottom Summary & Process Invoice Button
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0B1912) : Colors.grey.shade50,
                      border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300)),
                    ),
                    child: Column(
                      children: [
                        // Manual GST Rate Input & Quick Chips
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Invoice GST % (Manual):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                                SizedBox(
                                  width: 100,
                                  child: TextFormField(
                                    controller: _gstRateController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      suffixText: '%',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onChanged: (val) {
                                      final parsed = double.tryParse(val) ?? 0.0;
                                      setState(() => _selectedGstRate = parsed.clamp(0.0, 100.0));
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [0.0, 5.0, 12.0, 18.0, 28.0].map((rate) {
                                  final isSelected = _selectedGstRate == rate;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text('${rate.toStringAsFixed(0)}%'),
                                      selected: isSelected,
                                      selectedColor: const Color(0xFF00875A),
                                      backgroundColor: isDark ? const Color(0xFF1C382B) : Colors.grey.shade200,
                                      labelStyle: TextStyle(
                                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                        fontSize: 11,
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
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Payment Method:', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                            DropdownButton<String>(
                              value: _paymentMethod,
                              dropdownColor: isDark ? const Color(0xFF1C382B) : Colors.white,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                              items: ['Cash', 'UPI', 'Card'].map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(m, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                              )).toList(),
                              onChanged: (val) => setState(() => _paymentMethod = val ?? 'Cash'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Subtotal', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                            Text('₹${_subtotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Taxable Amount', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                            Text('₹${_taxableAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                          ],
                        ),
                        if (_selectedGstRate > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('CGST (${_cgstRate.toStringAsFixed(1)}%)', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade700)),
                              Text('₹${_cgstAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey.shade700)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('SGST (${_sgstRate.toStringAsFixed(1)}%)', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade700)),
                              Text('₹${_sgstAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey.shade700)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total GST (${_selectedGstRate.toStringAsFixed(0)}%)', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                              Text('₹${_gst.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF34D399) : const Color(0xFF00875A))),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('GST (0%)', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade700)),
                              Text('₹0.00', style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.grey.shade700)),
                            ],
                          ),
                        ],
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: isDark ? Colors.white12 : Colors.grey.shade300),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Grand Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                            Text(
                              '₹${_grandTotal.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: isDark ? const Color(0xFF34D399) : const Color(0xFF00875A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            icon: _isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Icon(Icons.print),
                            label: Text(
                              _isProcessing ? 'PROCESSING INVOICE...' : 'GENERATE & PRINT INVOICE',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00875A),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade400,
                              disabledForegroundColor: Colors.white70,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _isProcessing ? null : _processInvoice,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
