class TransactionItemModel {
  final int? id;
  final int transactionId;
  final int productId;
  final int quantity;
  final double price;

  TransactionItemModel({
    this.id,
    required this.transactionId,
    required this.productId,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "transactionId": transactionId,
      "productId": productId,
      "quantity": quantity,
      "price": price,
    };
  }

  factory TransactionItemModel.fromMap(Map<String, dynamic> map) {
    return TransactionItemModel(
      id: map["id"],
      transactionId: map["transactionId"],
      productId: map["productId"],
      quantity: map["quantity"],
      price: map["price"],
    );
  }
}
