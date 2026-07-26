import 'package:flutter/material.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../repositories/cart_repository.dart';

class CartProvider extends ChangeNotifier {
  final CartRepository _repository = CartRepository();

  List<CartModel> _cartItems = [];
  List<ProductModel> _products = [];
  bool _isLoading = false;

  List<CartModel> get cartItems => _cartItems;
  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  int get itemCount => _cartItems.length;

  double get totalPrice {
    double total = 0;
    for (var cart in _cartItems) {
      try {
        var product = _products.firstWhere((p) => p.id == cart.productId);
        total += product.price * cart.quantity;
      } catch (_) {}
    }
    return total;
  }

  Future<void> loadCart(List<ProductModel> allProducts) async {
    _isLoading = true;
    notifyListeners();

    _cartItems = await _repository.getCartItems();
    _products = allProducts;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addToCart(int productId, int quantity) async {
    await _repository.addToCart(productId, quantity);
    await loadCart(_products);
  }

  Future<void> updateQuantity(int id, int quantity) async {
    if (quantity <= 0) {
      await _repository.removeFromCart(id);
    } else {
      await _repository.updateQuantity(id, quantity);
    }
    await loadCart(_products);
  }

  Future<void> removeFromCart(int id) async {
    await _repository.removeFromCart(id);
    await loadCart(_products);
  }

  Future<void> clearCart() async {
    await _repository.clearCart();
    _cartItems.clear();
    notifyListeners();
  }

  ProductModel? getProductById(int productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  int getProductQuantity(int productId) {
    try {
      return _cartItems.firstWhere((c) => c.productId == productId).quantity;
    } catch (_) {
      return 0;
    }
  }
}
