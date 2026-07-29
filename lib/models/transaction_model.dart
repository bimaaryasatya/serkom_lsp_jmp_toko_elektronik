class TransactionModel {
  final int? id;
  final String invoice;
  final int userId;
  final double total;
  final double shippingFee;
  final String? address;
  final String status;
  final String date;
  final String paymentMethod;
  final String courier;
  final String trackingNumber;

  TransactionModel({
    this.id,
    required this.invoice,
    required this.userId,
    required this.total,
    this.shippingFee = 0.0,
    this.address,
    required this.status,
    required this.date,
    this.paymentMethod = 'Transfer Bank',
    this.courier = 'JNE Regular',
    this.trackingNumber = '',
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "invoice": invoice,
      "userId": userId,
      "total": total,
      "shippingFee": shippingFee,
      "address": address,
      "status": status,
      "date": date,
      "paymentMethod": paymentMethod,
      "courier": courier,
      "trackingNumber": trackingNumber,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map["id"],
      invoice: map["invoice"],
      userId: map["userId"],
      total: map["total"] != null ? (map["total"] as num).toDouble() : 0.0,
      shippingFee: map["shippingFee"] != null ? (map["shippingFee"] as num).toDouble() : 0.0,
      address: map["address"],
      status: map["status"] ?? 'Menunggu Konfirmasi',
      date: map["date"] ?? '',
      paymentMethod: map["paymentMethod"] ?? 'Transfer Bank',
      courier: map["courier"] ?? 'JNE Regular',
      trackingNumber: map["trackingNumber"] ?? '',
    );
  }
}
