import '../database/database_helper.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../models/transaction_item_model.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<TransactionModel> createTransaction({
    required int userId,
    required double total,
    double shippingFee = 0.0,
    String? address,
    required List<CartModel> cartItems,
    required List<ProductModel> products,
  }) async {
    String invoice = 'INV-${DateTime.now().millisecondsSinceEpoch}-$userId';
    const String defaultStatus = 'Menunggu Konfirmasi';

    var transaction = TransactionModel(
      invoice: invoice,
      userId: userId,
      total: total,
      shippingFee: shippingFee,
      address: address,
      status: defaultStatus,
      date: DateTime.now().toIso8601String(),
    );

    int transactionId = await _db.insertTransaction(transaction);

    for (var cartItem in cartItems) {
      var product = products.firstWhere((p) => p.id == cartItem.productId);
      await _db.insertTransactionItem(TransactionItemModel(
        transactionId: transactionId,
        productId: cartItem.productId,
        quantity: cartItem.quantity,
        price: product.price,
      ));
    }

    await _db.clearCart();

    return TransactionModel(
      id: transactionId,
      invoice: invoice,
      userId: userId,
      total: total,
      shippingFee: shippingFee,
      address: address,
      status: defaultStatus,
      date: DateTime.now().toIso8601String(),
    );
  }

  Future<List<TransactionModel>> getTransactionsByUser(int userId) async {
    return await _db.getTransactionsByUser(userId);
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    return await _db.getAllTransactions();
  }

  Future<List<TransactionItemModel>> getTransactionItems(int transactionId) async {
    return await _db.getTransactionItems(transactionId);
  }

  Future<void> updateTransactionStatus(int id, String status) async {
    await _db.updateTransactionStatus(id, status);
  }
}
