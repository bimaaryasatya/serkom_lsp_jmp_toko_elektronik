import 'dart:convert';

class ProductModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String image;
  final List<String> images;
  final String category;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.image,
    this.images = const [],
    required this.category,
  });

  /// Returns effective list of product images.
  List<String> get imageList {
    if (images.isNotEmpty) {
      return images;
    }
    if (image.trim().isNotEmpty) {
      return [image];
    }
    return [];
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    List<String> imgs = [];
    if (json["images"] != null) {
      if (json["images"] is List) {
        imgs = (json["images"] as List).map((e) => e.toString()).toList();
      } else if (json["images"] is String && (json["images"] as String).isNotEmpty) {
        try {
          final decoded = jsonDecode(json["images"]);
          if (decoded is List) {
            imgs = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {
          imgs = [json["images"].toString()];
        }
      }
    }
    final primaryImg = json["image"]?.toString() ?? (imgs.isNotEmpty ? imgs.first : '');
    return ProductModel(
      id: json["id"],
      name: json["name"],
      description: json["description"],
      price: (json["price"] is num) ? (json["price"] as num).toDouble() : 0.0,
      stock: json["stock"],
      image: primaryImg,
      images: imgs,
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
      "image": image.isEmpty && images.isNotEmpty ? images.first : image,
      "images": jsonEncode(images),
      "category": category,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    List<String> imgs = [];
    if (map["images"] != null && map["images"].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map["images"]);
        if (decoded is List) {
          imgs = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        imgs = [map["images"].toString()];
      }
    }
    if (imgs.isEmpty && map["image"] != null && map["image"].toString().isNotEmpty) {
      imgs = [map["image"].toString()];
    }
    final primaryImg = map["image"]?.toString() ?? (imgs.isNotEmpty ? imgs.first : '');

    return ProductModel(
      id: map["id"],
      name: map["name"],
      description: map["description"],
      price: (map["price"] is num) ? (map["price"] as num).toDouble() : 0.0,
      stock: map["stock"],
      image: primaryImg,
      images: imgs,
      category: map["category"],
    );
  }
}

