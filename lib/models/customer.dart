class Customer {
  final int? customerId;
  final String customerName;
  final String? phone;
  final String? address;
  final String? city;
  final String? gstNumber;
  final String? createdAt;

  Customer({
    this.customerId,
    required this.customerName,
    this.phone,
    this.address,
    this.city,
    this.gstNumber,
    this.createdAt,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      customerId: map['customer_id'],
      customerName: map['customer_name'] ?? '',
      phone: map['phone'],
      address: map['address'],
      city: map['city'],
      gstNumber: map['gst_number'],
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'customer_name': customerName,
      'phone': phone,
      'address': address,
      'city': city,
      'gst_number': gstNumber,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
    if (customerId != null) {
      map['customer_id'] = customerId;
    }
    return map;
  }
}
