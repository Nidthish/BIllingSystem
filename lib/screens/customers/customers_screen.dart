import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../models/customer.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  void _showCustomerDialog(BuildContext parentContext, {Customer? customer}) {
    final nameController = TextEditingController(text: customer?.customerName ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final addressController = TextEditingController(text: customer?.address ?? '');
    final cityController = TextEditingController(text: customer?.city ?? '');
    final gstController = TextEditingController(text: customer?.gstNumber ?? '');
    final formKey = GlobalKey<FormState>();
    String? successMessage;

    showDialog(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(customer == null ? 'Add Customer' : 'Edit Customer'),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (successMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4EA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF00875A)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF00875A), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                successMessage!,
                                style: const TextStyle(color: Color(0xFF00875A), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Customer Name *'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Customer Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: phoneController,
                            decoration: const InputDecoration(labelText: 'Phone Number (10 digits) *'),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Phone number is required';
                              }
                              final digitsOnly = v.trim().replaceAll(RegExp(r'\D'), '');
                              if (digitsOnly.length != 10) {
                                return 'Must be exactly 10 digits';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: gstController,
                            decoration: const InputDecoration(labelText: 'GST Number (Optional)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: cityController,
                      decoration: const InputDecoration(labelText: 'City'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (dialogContext.mounted && Navigator.canPop(dialogContext)) Navigator.pop(dialogContext);
                },
                child: Text(customer == null ? 'Close' : 'Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00875A),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final addedName = nameController.text.trim();
                    final newCustomer = Customer(
                      customerId: customer?.customerId,
                      customerName: addedName,
                      phone: phoneController.text.trim(),
                      address: addressController.text.trim(),
                      city: cityController.text.trim(),
                      gstNumber: gstController.text.trim(),
                    );

                    final provider = parentContext.read<CustomerProvider>();
                    if (customer == null) {
                      await provider.addCustomer(newCustomer);
                      nameController.clear();
                      phoneController.clear();
                      addressController.clear();
                      cityController.clear();
                      gstController.clear();
                      setState(() {
                        successMessage = 'Customer "$addedName" added! Add another or click Close.';
                      });
                      formKey.currentState?.reset();
                    } else {
                      await provider.updateCustomer(newCustomer);
                      if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
                        Navigator.pop(dialogContext);
                      }
                    }
                  }
                },
                child: Text(customer == null ? 'Add Customer' : 'Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete "${customer.customerName}"?'),
        actions: [
          TextButton(
            onPressed: () {
              if (dialogContext.mounted && Navigator.canPop(dialogContext)) Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<CustomerProvider>().deleteCustomer(customer.customerId!);
              if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers Directory'),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text('Add Customer'),
            onPressed: () => _showCustomerDialog(context),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search customers by name, phone, or city...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (val) => context.read<CustomerProvider>().setSearchQuery(val),
            ),
            const SizedBox(height: 24),
            // Customers DataTable
            Expanded(
              child: Consumer<CustomerProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final customers = provider.filteredCustomers;
                  if (customers.isEmpty) {
                    return const Center(child: Text('No customers found.'));
                  }

                  return Card(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Customer Name')),
                                  DataColumn(label: Text('Phone')),
                                  DataColumn(label: Text('Address')),
                                  DataColumn(label: Text('City')),
                                  DataColumn(label: Text('GST Number')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: customers.map((c) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(c.customerName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataCell(Text(c.phone != null && c.phone!.isNotEmpty ? c.phone! : '-')),
                                      DataCell(Text(c.address != null && c.address!.isNotEmpty ? c.address! : '-')),
                                      DataCell(Text(c.city != null && c.city!.isNotEmpty ? c.city! : '-')),
                                      DataCell(Text(c.gstNumber != null && c.gstNumber!.isNotEmpty ? c.gstNumber! : '-')),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blue),
                                              onPressed: () => _showCustomerDialog(context, customer: c),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              onPressed: () => _confirmDelete(context, c),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
