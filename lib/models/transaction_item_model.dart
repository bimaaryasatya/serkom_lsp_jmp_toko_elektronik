class TransactionItemModel {
  final int? id;
  final int transactionId;
  final int productId;
  final int quantity;
  final double price;
  final String productName;
  final String productImage;

  TransactionItemModel({
    this.id,
    required this.transactionId,
    required this.productId,
    required this.quantity,
    required this.price,
    this.productName = 'Produk Elektronik',
    this.productImage = '',
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "transactionId": transactionId,
      "productId": productId,
      "quantity": quantity,
      "price": price,
      "productName": productName,
      "productImage": productImage,
    };
  }

  factory TransactionItemModel.fromMap(Map<String, dynamic> map) {
    return TransactionItemModel(
      id: map["id"],
      transactionId: map["transactionId"],
      productId: map["productId"],
      quantity: map["quantity"],
      price: map["price"] != null ? (map["price"] as num).toDouble() : 0.0,
      productName: map["productName"] ?? 'Produk Elektronik',
      productImage: map["productImage"] ?? '',
    );
  }
}
