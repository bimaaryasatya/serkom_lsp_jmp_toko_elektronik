import '../database/sqlite_helper.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../models/transaction_item_model.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final SqliteHelper _sqliteHelper = SqliteHelper();

  Future<TransactionModel> createTransaction({
    required int userId,
    required double total,
    double shippingFee = 0.0,
    String? address,
    required List<CartModel> cartItems,
    required List<ProductModel> products,
    String paymentMethod = 'Transfer Bank',
    String courier = 'JNE Regular',
  }) async {
    String invoice = 'INV-${DateTime.now().millisecondsSinceEpoch}-$userId';
    const String defaultStatus = 'Menunggu Konfirmasi';
    String dateStr = DateTime.now().toIso8601String();

    List<TransactionItemModel> items = [];
    for (var cartItem in cartItems) {
      var product = products.firstWhere(
        (p) => p.id == cartItem.productId,
        orElse: () => ProductModel(
          id: cartItem.productId,
          name: '',
          description: '',
          price: 0.0,
          stock: 0,
          image: '',
          category: '',
        ),
      );
      items.add(TransactionItemModel(
        transactionId: 0,
        productId: cartItem.productId,
        quantity: cartItem.quantity,
        price: product.price,
        productName: product.name,
        productImage: product.image,
      ));
    }

    final transaction = TransactionModel(
      invoice: invoice,
      userId: userId,
      total: total,
      shippingFee: shippingFee,
      address: address,
      status: defaultStatus,
      date: dateStr,
      paymentMethod: paymentMethod,
      courier: courier,
    );

    int id = await _sqliteHelper.insertTransactionWithItems(transaction, items);

    return TransactionModel(
      id: id == 0 ? null : id,
      invoice: invoice,
      userId: userId,
      total: total,
      shippingFee: shippingFee,
      address: address,
      status: defaultStatus,
      date: dateStr,
      paymentMethod: paymentMethod,
      courier: courier,
    );
  }

  Future<List<TransactionModel>> getTransactionsByUser(int userId) async {
    return _sqliteHelper.getTransactionsByUser(userId);
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    return _sqliteHelper.getAllTransactions();
  }

  Future<List<TransactionItemModel>> getTransactionItems(int transactionId) async {
    return _sqliteHelper.getTransactionItems(transactionId);
  }

  Future<void> updateTransactionStatus(int id, String status) async {
    await _sqliteHelper.updateTransactionStatusLocal(id, status);
  }

  Future<void> updateTrackingNumber(int id, String courier, String trackingNumber) async {
    await _sqliteHelper.updateTrackingNumberLocal(id, courier, trackingNumber);
  }

  Future<double> getTotalRevenue() async {
    return _sqliteHelper.getTotalRevenueLocal();
  }

  Future<Map<String, dynamic>> getSalesReport() async {
    return _sqliteHelper.getSalesReport();
  }
}
