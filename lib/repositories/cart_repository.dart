import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/constants.dart';
import '../models/cart_model.dart';

class CartRepository {
  Future<void> addToCart(int productId, int quantity) async {
    try {
      await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/cart'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'productId': productId,
          'quantity': quantity,
        }),
      );
    } catch (_) {}
  }

  Future<List<CartModel>> getCartItems() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.apiBaseUrl}/cart'));
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((e) => CartModel.fromMap(Map<String, dynamic>.from(e))).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> updateQuantity(int id, int quantity) async {
    try {
      await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/cart/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'quantity': quantity}),
      );
    } catch (_) {}
  }

  Future<void> removeFromCart(int id) async {
    try {
      await http.delete(Uri.parse('${AppConstants.apiBaseUrl}/cart/$id'));
    } catch (_) {}
  }

  Future<void> clearCart() async {
    try {
      await http.delete(Uri.parse('${AppConstants.apiBaseUrl}/cart'));
    } catch (_) {}
  }

  Future<int> getCartItemCount() async {
    var items = await getCartItems();
    return items.length;
  }
}
