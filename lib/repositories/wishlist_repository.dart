import '../database/sqlite_helper.dart';
import '../models/product_model.dart';

class WishlistRepository {
  final SqliteHelper _sqliteHelper = SqliteHelper();

  Future<List<ProductModel>> getWishlist(int userId) async {
    return _sqliteHelper.getWishlist(userId);
  }

  Future<bool> addToWishlist(int userId, int productId) async {
    return _sqliteHelper.addToWishlist(userId, productId);
  }

  Future<bool> removeFromWishlist(int userId, int productId) async {
    return _sqliteHelper.removeFromWishlist(userId, productId);
  }
}
