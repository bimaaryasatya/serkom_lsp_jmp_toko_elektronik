class TransactionModel {
  final int? id;
  final String invoice;
  final int userId;
  final double total;
  final double shippingFee;
  final String? address;
  final String status;
  final String date;

  TransactionModel({
    this.id,
    required this.invoice,
    required this.userId,
    required this.total,
    this.shippingFee = 0.0,
    this.address,
    required this.status,
    required this.date,
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
      date: map["date"],
    );
  }
}
