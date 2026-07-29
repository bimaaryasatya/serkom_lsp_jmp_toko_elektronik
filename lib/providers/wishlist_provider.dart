import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../repositories/wishlist_repository.dart';

class WishlistProvider extends ChangeNotifier {
  final WishlistRepository _repository = WishlistRepository();

  List<ProductModel> _wishlistItems = [];
  bool _isLoading = false;

  List<ProductModel> get wishlistItems => _wishlistItems;
  bool get isLoading => _isLoading;
  int get itemCount => _wishlistItems.length;

  bool isProductWishlisted(int productId) {
    return _wishlistItems.any((p) => p.id == productId);
  }

  Future<void> loadWishlist(int userId) async {
    _isLoading = true;
    notifyListeners();

    _wishlistItems = await _repository.getWishlist(userId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleWishlist(int userId, ProductModel product) async {
    final exists = isProductWishlisted(product.id);
    if (exists) {
      _wishlistItems.removeWhere((p) => p.id == product.id);
      notifyListeners();
      await _repository.removeFromWishlist(userId, product.id);
    } else {
      _wishlistItems.add(product);
      notifyListeners();
      await _repository.addToWishlist(userId, product.id);
    }
  }
}
