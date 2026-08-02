class Sale {
  final int? saleId;
  final String invoiceNo;
  final int? customerId;
  final String? customerName;
  final String date;
  final double subtotal;
  final double discount;
  final double gst;
  final double grandTotal;
  final String? paymentMethod;
  final double gstRate;
  final double cgstRate;
  final double sgstRate;
  final double taxableAmount;
  final double cgstAmount;
  final double sgstAmount;

  Sale({
    this.saleId,
    required this.invoiceNo,
    this.customerId,
    this.customerName,
    required this.date,
    required this.subtotal,
    required this.discount,
    required this.gst,
    required this.grandTotal,
    this.paymentMethod,
    double? gstRate,
    double? cgstRate,
    double? sgstRate,
    double? taxableAmount,
    double? cgstAmount,
    double? sgstAmount,
  })  : gstRate = gstRate ?? (subtotal > 0 && gst > 0 ? ((gst / (subtotal - discount > 0 ? subtotal - discount : subtotal)) * 100).roundToDouble() : 0.0),
        cgstRate = cgstRate ?? ((gstRate ?? (subtotal > 0 && gst > 0 ? ((gst / (subtotal - discount > 0 ? subtotal - discount : subtotal)) * 100).roundToDouble() : 0.0)) / 2),
        sgstRate = sgstRate ?? ((gstRate ?? (subtotal > 0 && gst > 0 ? ((gst / (subtotal - discount > 0 ? subtotal - discount : subtotal)) * 100).roundToDouble() : 0.0)) / 2),
        taxableAmount = taxableAmount ?? (subtotal - discount).clamp(0.0, double.infinity),
        cgstAmount = cgstAmount ?? (gst / 2),
        sgstAmount = sgstAmount ?? (gst / 2);

  bool get isGstBill => gstRate > 0 || gst > 0;

  factory Sale.fromMap(Map<String, dynamic> map) {
    final subtotal = (map['subtotal'] as num?)?.toDouble() ?? 0.0;
    final discount = (map['discount'] as num?)?.toDouble() ?? 0.0;
    final gst = (map['gst'] as num?)?.toDouble() ?? (map['gst_amount'] as num?)?.toDouble() ?? 0.0;
    final taxable = (map['taxable_amount'] as num?)?.toDouble() ?? (subtotal - discount).clamp(0.0, double.infinity);
    
    double rate = (map['gst_rate'] as num?)?.toDouble() ?? 0.0;
    if (rate == 0.0 && gst > 0 && taxable > 0) {
      rate = ((gst / taxable) * 100).roundToDouble();
    }
    final cgstR = (map['cgst_rate'] as num?)?.toDouble() ?? (rate / 2);
    final sgstR = (map['sgst_rate'] as num?)?.toDouble() ?? (rate / 2);
    final cgstA = (map['cgst_amount'] as num?)?.toDouble() ?? (gst / 2);
    final sgstA = (map['sgst_amount'] as num?)?.toDouble() ?? (gst / 2);

    return Sale(
      saleId: map['sale_id'],
      invoiceNo: map['invoice_no'] ?? '',
      customerId: map['customer_id'],
      customerName: map['customer_name'],
      date: map['date'] ?? '',
      subtotal: subtotal,
      discount: discount,
      gst: gst,
      grandTotal: (map['grand_total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['payment_method'],
      gstRate: rate,
      cgstRate: cgstR,
      sgstRate: sgstR,
      taxableAmount: taxable,
      cgstAmount: cgstA,
      sgstAmount: sgstA,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'invoice_no': invoiceNo,
      'customer_id': customerId,
      'customer_name': customerName,
      'date': date,
      'subtotal': subtotal,
      'discount': discount,
      'gst': gst,
      'grand_total': grandTotal,
      'payment_method': paymentMethod,
      'gst_rate': gstRate,
      'cgst_rate': cgstRate,
      'sgst_rate': sgstRate,
      'taxable_amount': taxableAmount,
      'cgst_amount': cgstAmount,
      'sgst_amount': sgstAmount,
    };
    if (saleId != null) {
      map['sale_id'] = saleId;
    }
    return map;
  }
}
