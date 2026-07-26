import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mysql1/mysql1.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/cart_model.dart';
import '../models/transaction_model.dart';
import '../models/transaction_item_model.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static MySqlConnection? _connection;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  Future<MySqlConnection> get database async {
    try {
      if (_connection == null) {
        _connection = await _initDatabase();
      } else {
        // Cek koneksi apakah masih aktif
        await _connection!.query('SELECT 1');
      }
    } catch (_) {
      _connection = await _initDatabase();
    }
    return _connection!;
  }

  Future<MySqlConnection> _initDatabase() async {
    if (kIsWeb) {
      throw Exception(
        'Koneksi langsung MySQL (port 3306) tidak didukung oleh browser Chrome demi keamanan sandbox.\n'
        'Silakan jalankan aplikasi sebagai Windows Desktop menggunakan perintah: flutter run -d windows'
      );
    }
    // Alamat host MySQL: Windows Desktop menggunakan 'localhost' atau '127.0.0.1'
    // Jika di Android Emulator, menggunakan '10.0.2.2'
    String host = Platform.isAndroid ? '10.0.2.2' : 'localhost';

    // Konfigurasi MySQL Laragon
    // Ubah mysqlPassword jika MySQL di Laragon kamu memiliki password (misal: 'root' atau 'admin')
    const String mysqlUser = 'root';
    const String mysqlPassword = ''; // Jika memakai password, isi di sini (misal: 'root')
    const String mysqlDb = 'toko_elektronik_db';
    const int mysqlPort = 3306;

    final settings = ConnectionSettings(
      host: host,
      port: mysqlPort,
      user: mysqlUser,
      password: mysqlPassword.isEmpty ? null : mysqlPassword,
      db: mysqlDb,
    );

    return await MySqlConnection.connect(settings);
  }

  Map<String, dynamic> _rowToMap(ResultRow row) {
    final map = <String, dynamic>{};
    row.fields.forEach((key, value) {
      if (value is Blob) {
        map[key] = value.toString();
      } else {
        map[key] = value;
      }
    });
    // Konversi aman untuk tipe data numerik
    if (map['id'] != null) map['id'] = int.tryParse(map['id'].toString()) ?? map['id'];
    if (map['price'] != null) map['price'] = double.tryParse(map['price'].toString()) ?? 0.0;
    if (map['total'] != null) map['total'] = double.tryParse(map['total'].toString()) ?? 0.0;
    if (map['shippingFee'] != null) map['shippingFee'] = double.tryParse(map['shippingFee'].toString()) ?? 0.0;
    if (map['stock'] != null) map['stock'] = int.tryParse(map['stock'].toString()) ?? 0;
    if (map['quantity'] != null) map['quantity'] = int.tryParse(map['quantity'].toString()) ?? 0;
    if (map['userId'] != null) map['userId'] = int.tryParse(map['userId'].toString()) ?? 0;
    if (map['productId'] != null) map['productId'] = int.tryParse(map['productId'].toString()) ?? 0;
    if (map['transactionId'] != null) map['transactionId'] = int.tryParse(map['transactionId'].toString()) ?? 0;
    return map;
  }

  Future<int> insertUser(UserModel user) async {
    MySqlConnection db = await database;
    var result = await db.query(
      'INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)',
      [user.name, user.email, user.password, user.role],
    );
    return result.insertId ?? 0;
  }

  Future<UserModel?> getUserByEmail(String email) async {
    MySqlConnection db = await database;
    var result = await db.query('SELECT * FROM users WHERE email = ?', [email]);
    if (result.isNotEmpty) {
      return UserModel.fromMap(_rowToMap(result.first));
    }
    return null;
  }

  Future<UserModel?> getUserById(int id) async {
    MySqlConnection db = await database;
    var result = await db.query('SELECT * FROM users WHERE id = ?', [id]);
    if (result.isNotEmpty) {
      return UserModel.fromMap(_rowToMap(result.first));
    }
    return null;
  }

  Future<int> insertProduct(ProductModel product) async {
    MySqlConnection db = await database;
    var result = await db.query(
      'INSERT INTO products (name, description, price, stock, image, category) VALUES (?, ?, ?, ?, ?, ?)',
      [product.name, product.description, product.price, product.stock, product.image, product.category],
    );
    return result.insertId ?? 0;
  }

  Future<List<ProductModel>> getProducts() async {
    MySqlConnection db = await database;
    var result = await db.query('SELECT * FROM products ORDER BY id DESC');
    return result.map((e) => ProductModel.fromMap(_rowToMap(e))).toList();
  }

  Future<ProductModel?> getProductById(int id) async {
    MySqlConnection db = await database;
    var result = await db.query('SELECT * FROM products WHERE id = ?', [id]);
    if (result.isNotEmpty) {
      return ProductModel.fromMap(_rowToMap(result.first));
    }
    return null;
  }

  Future<int> updateProduct(ProductModel product) async {
    MySqlConnection db = await database;
    var result = await db.query(
      'UPDATE products SET name = ?, description = ?, price = ?, stock = ?, image = ?, category = ? WHERE id = ?',
      [product.name, product.description, product.price, product.stock, product.image, product.category, product.id],
    );
    return result.affectedRows ?? 0;
  }

  Future<int> deleteProduct(int id) async {
    MySqlConnection db = await database;
    var result = await db.query('DELETE FROM products WHERE id = ?', [id]);
    return result.affectedRows ?? 0;
  }

  Future<int> insertCart(CartModel cart) async {
    MySqlConnection db = await database;
    var existing = await db.query('SELECT id, quantity FROM cart WHERE productId = ?', [cart.productId]);
    if (existing.isNotEmpty) {
      int newQty = int.parse(existing.first['quantity'].toString()) + cart.quantity;
      var updateRes = await db.query('UPDATE cart SET quantity = ? WHERE productId = ?', [newQty, cart.productId]);
      return updateRes.affectedRows ?? 0;
    }
    var insertRes = await db.query('INSERT INTO cart (productId, quantity) VALUES (?, ?)', [cart.productId, cart.quantity]);
    return insertRes.insertId ?? 0;
  }

  Future<List<CartModel>> getCartItems() async {
    MySqlConnection db = await database;
    var result = await db.query('SELECT * FROM cart ORDER BY id DESC');
    return result.map((e) => CartModel.fromMap(_rowToMap(e))).toList();
  }

  Future<int> updateCartQuantity(int id, int quantity) async {
    MySqlConnection db = await database;
    var result = await db.query('UPDATE cart SET quantity = ? WHERE id = ?', [quantity, id]);
    return result.affectedRows ?? 0;
  }

  Future<int> deleteCartItem(int id) async {
    MySqlConnection db = await database;
    var result = await db.query('DELETE FROM cart WHERE id = ?', [id]);
    return result.affectedRows ?? 0;
  }

  Future<void> clearCart() async {
    MySqlConnection db = await database;
    await db.query('DELETE FROM cart');
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    MySqlConnection db = await database;
    var result = await db.query(
      'INSERT INTO transactions (invoice, userId, total, shippingFee, address, status, date) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        transaction.invoice,
        transaction.userId,
        transaction.total,
        transaction.shippingFee,
        transaction.address,
        transaction.status,
        transaction.date
      ],
    );
    return result.insertId ?? 0;
  }

  Future<List<TransactionModel>> getTransactionsByUser(int userId) async {
    MySqlConnection db = await database;
    var result = await db.query('SELECT * FROM transactions WHERE userId = ? ORDER BY id DESC', [userId]);
    return result.map((e) => TransactionModel.fromMap(_rowToMap(e))).toList();
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    MySqlConnection db = await database;
    var result = await db.query('SELECT * FROM transactions ORDER BY id DESC');
    return result.map((e) => TransactionModel.fromMap(_rowToMap(e))).toList();
  }

  Future<int> updateTransactionStatus(int id, String status) async {
    MySqlConnection db = await database;
    
    // Cek status sebelumnya
    var prev = await db.query('SELECT status FROM transactions WHERE id = ?', [id]);
    String oldStatus = prev.isNotEmpty ? prev.first[0].toString() : '';

    var result = await db.query('UPDATE transactions SET status = ? WHERE id = ?', [status, id]);

    // Jika status dikonfirmasi menjadi 'Selesai' (dan sebelumnya belum selesai), kurangi stok produk di database MySQL
    if ((status == 'Selesai' || status == 'completed') && oldStatus != 'Selesai' && oldStatus != 'completed') {
      var items = await db.query('SELECT productId, quantity FROM transaction_items WHERE transactionId = ?', [id]);
      for (var row in items) {
        int productId = row[0];
        int qty = row[1];
        await db.query('UPDATE products SET stock = GREATEST(0, stock - ?) WHERE id = ?', [qty, productId]);
      }
    }

    return result.affectedRows ?? 0;
  }

  Future<int> insertTransactionItem(TransactionItemModel item) async {
    MySqlConnection db = await database;
    var result = await db.query(
      'INSERT INTO transaction_items (transactionId, productId, quantity, price) VALUES (?, ?, ?, ?)',
      [item.transactionId, item.productId, item.quantity, item.price],
    );
    return result.insertId ?? 0;
  }

  Future<List<TransactionItemModel>> getTransactionItems(int transactionId) async {
    MySqlConnection db = await database;
    var result = await db.query('SELECT * FROM transaction_items WHERE transactionId = ?', [transactionId]);
    return result.map((e) => TransactionItemModel.fromMap(_rowToMap(e))).toList();
  }

  Future<int> getProductCount() async {
    MySqlConnection db = await database;
    var result = await db.query('SELECT COUNT(*) as count FROM products');
    if (result.isNotEmpty) {
      return int.tryParse(result.first['count'].toString()) ?? 0;
    }
    return 0;
  }

  Future<int> getUserCount() async {
    MySqlConnection db = await database;
    var result = await db.query('SELECT COUNT(*) as count FROM users');
    if (result.isNotEmpty) {
      return int.tryParse(result.first['count'].toString()) ?? 0;
    }
    return 0;
  }

  Future<double> getTotalRevenue() async {
    MySqlConnection db = await database;
    var result = await db.query('SELECT COALESCE(SUM(total), 0) as total FROM transactions WHERE status = "completed"');
    if (result.isNotEmpty) {
      return double.tryParse(result.first['total'].toString()) ?? 0.0;
    }
    return 0.0;
  }
}
