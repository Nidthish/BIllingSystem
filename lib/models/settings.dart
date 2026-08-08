class Settings {
  final String shopName;
  final String address;
  final String phone;
  final String gstNumber;
  final String invoicePrefix;
  final String accountNumber;
  final String ifsc;
  final String branch;
  final String bankName;
  final String accountType;

  Settings({
    required this.shopName,
    required this.address,
    required this.phone,
    required this.gstNumber,
    required this.invoicePrefix,
    this.accountNumber = '05390200000618',
    this.ifsc = 'BARB0TIRUCH',
    this.branch = 'TRICHY MAIN',
    this.bankName = 'BANK OF BARODA',
    this.accountType = 'CURRENT ACCOUNT',
  });

  factory Settings.fromMap(Map<String, dynamic> map) {
    return Settings(
      shopName: map['shop_name'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      gstNumber: map['gst_number'] ?? '',
      invoicePrefix: map['invoice_prefix'] ?? '',
      accountNumber: (map['account_number'] != null && map['account_number'].toString().isNotEmpty)
          ? map['account_number']
          : '05390200000618',
      ifsc: (map['ifsc'] != null && map['ifsc'].toString().isNotEmpty)
          ? map['ifsc']
          : 'BARB0TIRUCH',
      branch: (map['branch'] != null && map['branch'].toString().isNotEmpty)
          ? map['branch']
          : 'TRICHY MAIN',
      bankName: (map['bank_name'] != null && map['bank_name'].toString().isNotEmpty)
          ? map['bank_name']
          : 'BANK OF BARODA',
      accountType: (map['account_type'] != null && map['account_type'].toString().isNotEmpty)
          ? map['account_type']
          : 'CURRENT ACCOUNT',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shop_name': shopName,
      'address': address,
      'phone': phone,
      'gst_number': gstNumber,
      'invoice_prefix': invoicePrefix,
      'account_number': accountNumber,
      'ifsc': ifsc,
      'branch': branch,
      'bank_name': bankName,
      'account_type': accountType,
    };
  }
}

