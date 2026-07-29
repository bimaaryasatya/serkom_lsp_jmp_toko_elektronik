import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/constants.dart';
import '../models/product_model.dart';

class WishlistRepository {
  Future<List<ProductModel>> getWishlist(int userId) async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.apiBaseUrl}/wishlist/$userId'));
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((e) => ProductModel.fromMap(Map<String, dynamic>.from(e))).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> addToWishlist(int userId, int productId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/wishlist'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId, 'productId': productId}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeFromWishlist(int userId, int productId) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.apiBaseUrl}/wishlist/$userId/$productId'),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
