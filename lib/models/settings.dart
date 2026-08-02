class Settings {
  final String shopName;
  final String address;
  final String phone;
  final String gstNumber;
  final String invoicePrefix;

  Settings({
    required this.shopName,
    required this.address,
    required this.phone,
    required this.gstNumber,
    required this.invoicePrefix,
  });

  factory Settings.fromMap(Map<String, dynamic> map) {
    return Settings(
      shopName: map['shop_name'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      gstNumber: map['gst_number'] ?? '',
      invoicePrefix: map['invoice_prefix'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shop_name': shopName,
      'address': address,
      'phone': phone,
      'gst_number': gstNumber,
      'invoice_prefix': invoicePrefix,
    };
  }
}
