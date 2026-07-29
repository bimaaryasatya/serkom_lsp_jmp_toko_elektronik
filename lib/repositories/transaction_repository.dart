import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/constants.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../models/transaction_item_model.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
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

    List<Map<String, dynamic>> itemsPayload = [];
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
      itemsPayload.add({
        'productId': cartItem.productId,
        'quantity': cartItem.quantity,
        'price': product.price,
      });
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'invoice': invoice,
          'userId': userId,
          'total': total,
          'shippingFee': shippingFee,
          'address': address ?? '',
          'status': defaultStatus,
          'date': dateStr,
          'paymentMethod': paymentMethod,
          'courier': courier,
          'items': itemsPayload,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        int transactionId = data['id'] ?? 0;
        return TransactionModel(
          id: transactionId,
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
    } catch (_) {}

    return TransactionModel(
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
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/transactions/user/$userId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((e) => TransactionModel.fromMap(Map<String, dynamic>.from(e))).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/transactions'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((e) => TransactionModel.fromMap(Map<String, dynamic>.from(e))).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<TransactionItemModel>> getTransactionItems(int transactionId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/transactions/$transactionId/items'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((e) => TransactionItemModel.fromMap(Map<String, dynamic>.from(e))).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> updateTransactionStatus(int id, String status) async {
    try {
      await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/transactions/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );
    } catch (_) {}
  }

  Future<void> updateTrackingNumber(int id, String courier, String trackingNumber) async {
    try {
      await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/transactions/$id/tracking'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'courier': courier, 'trackingNumber': trackingNumber}),
      );
    } catch (_) {}
  }
}
