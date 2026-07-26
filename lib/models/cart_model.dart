class CartModel {
  final int? id;
  final int productId;
  final int quantity;

  CartModel({this.id, required this.productId, required this.quantity});

  Map<String, dynamic> toMap() {
    return {"id": id, "productId": productId, "quantity": quantity};
  }

  factory CartModel.fromMap(Map<String, dynamic> map) {
    return CartModel(
      id: map["id"],
      productId: map["productId"],
      quantity: map["quantity"],
    );
  }
}
