import '../database/sqlite_helper.dart';
import '../models/cart_model.dart';

class CartRepository {
  final SqliteHelper _sqliteHelper = SqliteHelper();

  Future<void> addToCart(int productId, int quantity) async {
    await _sqliteHelper.addToCart(productId, quantity);
  }

  Future<List<CartModel>> getCartItems() async {
    return _sqliteHelper.getCartItems();
  }

  Future<void> updateQuantity(int id, int quantity) async {
    await _sqliteHelper.updateCartQuantity(id, quantity);
  }

  Future<void> removeFromCart(int id) async {
    await _sqliteHelper.removeCartItem(id);
  }

  Future<void> clearCart() async {
    await _sqliteHelper.clearCart();
  }

  Future<int> getCartItemCount() async {
    var items = await getCartItems();
    return items.length;
  }
}
