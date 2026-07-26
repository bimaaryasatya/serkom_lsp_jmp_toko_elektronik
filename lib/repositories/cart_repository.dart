import '../database/database_helper.dart';
import '../models/cart_model.dart';

class CartRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<void> addToCart(int productId, int quantity) async {
    await _db.insertCart(CartModel(productId: productId, quantity: quantity));
  }

  Future<List<CartModel>> getCartItems() async {
    return await _db.getCartItems();
  }

  Future<void> updateQuantity(int id, int quantity) async {
    await _db.updateCartQuantity(id, quantity);
  }

  Future<void> removeFromCart(int id) async {
    await _db.deleteCartItem(id);
  }

  Future<void> clearCart() async {
    await _db.clearCart();
  }

  Future<int> getCartItemCount() async {
    var items = await _db.getCartItems();
    return items.length;
  }
}
