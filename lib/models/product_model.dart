class ProductModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String image;
  final String category;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.image,
    required this.category,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json["id"],
      name: json["name"],
      description: json["description"],
      price: json["price"].toDouble(),
      stock: json["stock"],
      image: json["image"],
      category: json["category"],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "description": description,
      "price": price,
      "stock": stock,
      "image": image,
      "category": category,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map["id"],
      name: map["name"],
      description: map["description"],
      price: map["price"],
      stock: map["stock"],
      image: map["image"],
      category: map["category"],
    );
  }
}
