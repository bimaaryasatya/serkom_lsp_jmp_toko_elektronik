import 'package:flutter/foundation.dart' show debugPrint, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart' show getApplicationSupportDirectory;
import 'package:sqflite_common/sqflite.dart';
import '../models/banner_model.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';
import '../models/transaction_item_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';

class SqliteHelper {
  static SqliteHelper? _instance;
  static Database? _database;
  static Future<Database?>? _initFuture;
  static String? _customDbPath;

  SqliteHelper._internal();

  factory SqliteHelper() {
    _instance ??= SqliteHelper._internal();
    return _instance!;
  }

  /// Mengatur path DB khusus (bermanfaat untuk unit testing agar mencegah database lock).
  static void setCustomDbPath(String? path) {
    _customDbPath = path;
    if (_database != null && _database!.isOpen) {
      _database!.close().catchError((_) {});
    }
    _database = null;
    _initFuture = null;
  }

  Future<Database?> get database {
    if (_database != null && _database!.isOpen) return Future.value(_database);
    final current = _initFuture;
    if (current != null) return current;
    final future = _initSqlite();
    _initFuture = future;
    return future;
  }

  /// Menyimpan error terakhir saat database gagal dibuka (untuk ditampilkan ke user).
  static String? lastOpenError;

  Future<Database?> _initSqlite() async {
    // Factory SQLite (FFI desktop / WASM web / sqflite mobile) sudah diset global di main.dart
    // melalui initDatabaseFactory().
    try {
      final path = await _resolveDbPath();
      final db = await _openDatabaseWithSchema(path);

      // Pastikan akun demo & produk sample selalu ada (idempotent), untuk
      // memulihkan DB lama yang belum memiliki data seed.
      await _ensureSeeded(db);

      _database = db;
      _initFuture = null;
      lastOpenError = null;
      return db;
    } catch (e) {
      lastOpenError = e.toString();
      debugPrint('SQLiteHelper: gagal membuka database ($e). Mencoba pulihkan...');

      // Pulihkan otomatis bila DB korup/rusak: hapus file lalu buka ulang sekali.
      try {
        final path = await _resolveDbPath();
        await databaseFactory.deleteDatabase(path).catchError((_) {});
      } catch (_) {}

      try {
        final path = await _resolveDbPath();
        final db = await _openDatabaseWithSchema(path);
        await _ensureSeeded(db);

        _database = db;
        _initFuture = null;
        lastOpenError = null;
        return db;
      } catch (e2) {
        lastOpenError = e2.toString();
        debugPrint('SQLiteHelper: pemulihan gagal ($e2)');
        _initFuture = null;
        return null;
      }
    }
  }

  Future<String> _resolveDbPath() async {
    if (_customDbPath != null && _customDbPath!.isNotEmpty) {
      return _customDbPath!;
    }
    if (kIsWeb) {
      // Web: Simpan di IndexedDB browser dengan nama file tiptronic_local.db
      return 'tiptronic_local.db';
    }

    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      // Mobile (Android / iOS): gunakan folder database standar native sqflite plugin
      final dbFolder = await databaseFactory.getDatabasesPath();
      return join(dbFolder, 'tiptronic_local.db');
    }

    try {
      // Desktop (Windows/Linux/macOS): gunakan folder data aplikasi yang aman & terpisah
      final dir = await getApplicationSupportDirectory();
      return join(dir.path, 'tiptronic_local.db');
    } catch (_) {
      // Fallback
      final base = await databaseFactory.getDatabasesPath();
      return join(base, 'tiptronic_local.db');
    }
  }

  Future<Database> _openDatabaseWithSchema(String path) async {
    return databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          await _createAllTables(db);
          await _seedProductsIfEmpty(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await _createAllTables(db);
          await _seedProductsIfEmpty(db);
        },
      ),
    );
  }

  // ==================== SCHEMA & SEED ====================

  Future<void> _createAllTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS auth_session (
        id INTEGER PRIMARY KEY,
        userId INTEGER NOT NULL,
        token TEXT NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        role TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS products_cache (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        stock INTEGER NOT NULL,
        image TEXT,
        category TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        stock INTEGER NOT NULL,
        image TEXT,
        category TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'user'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS wishlist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        productId INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        userName TEXT NOT NULL,
        productId INTEGER NOT NULL,
        transactionId INTEGER,
        rating INTEGER NOT NULL DEFAULT 5,
        comment TEXT,
        date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS banners (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        subtitle TEXT,
        image TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice TEXT NOT NULL,
        userId INTEGER NOT NULL,
        total REAL NOT NULL DEFAULT 0,
        shippingFee REAL NOT NULL DEFAULT 0,
        address TEXT,
        status TEXT NOT NULL DEFAULT 'Menunggu Konfirmasi',
        date TEXT NOT NULL,
        paymentMethod TEXT DEFAULT 'Transfer Bank',
        courier TEXT DEFAULT 'JNE Regular',
        trackingNumber TEXT DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transactionId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        price REAL NOT NULL DEFAULT 0
      )
    ''');

    await _seedUsers(db);
    await _seedBannersIfEmpty(db);
  }

  Future<void> _seedUsers(Database db) async {
    await db.insert('users', {
      'id': 1,
      'name': 'Admin Toko',
      'email': 'admin@toko.com',
      'password': 'admin123',
      'role': 'admin',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('users', {
      'id': 2,
      'name': 'User Demo',
      'email': 'user@toko.com',
      'password': 'user123',
      'role': 'user',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _seedBannersIfEmpty(Database db) async {
    final bannerCount = await _countRows(db, 'banners');
    if (bannerCount == 0) {
      await db.insert('banners', {
        'title': 'Promo Mega Akhir Tahun',
        'subtitle': 'Diskon hingga 50% untuk produk elektronik pilihan',
        'image': 'https://cdn.dummyjson.com/product-images/laptops/apple-macbook-pro-14-inch-space-grey/thumbnail.webp',
      });
      await db.insert('banners', {
        'title': 'Gratis Ongkir',
        'subtitle': 'Untuk semua pesanan di atas Rp1.000.000',
        'image': 'https://cdn.dummyjson.com/product-images/smartphones/iphone-13-pro/thumbnail.webp',
      });
      await db.insert('banners', {
        'title': 'Produk Baru Telah Tiba',
        'subtitle': 'Smartphone, laptop & tablet generasi terbaru',
        'image': 'https://cdn.dummyjson.com/product-images/tablets/ipad-mini-2021-starlight/thumbnail.webp',
      });
    } else {
      await db.execute('''
        UPDATE banners 
        SET image = 'https://cdn.dummyjson.com/product-images/laptops/apple-macbook-pro-14-inch-space-grey/thumbnail.webp'
        WHERE image LIKE '%products/images%'
      ''');
    }
  }

  Future<void> cleanNonElectronics({Database? targetDb}) async {
    final db = targetDb ?? await database;
    if (db == null) return;
    const allowed = "('laptops', 'smartphones', 'tablets', 'mobile-accessories', 'audio', 'accessories', 'tv', 'electronics')";
    await db.execute("DELETE FROM products WHERE LOWER(category) NOT IN $allowed");
  }

  Future<void> _ensureSeeded(Database db) async {
    await _seedUsers(db);
    await _seedBannersIfEmpty(db);
    await _seedProductsIfEmpty(db);
    await cleanNonElectronics(targetDb: db);
  }

  Future<int> _countRows(Database db, String table) async {
    final res = await db.rawQuery('SELECT COUNT(*) as c FROM $table');
    if (res.isEmpty) return 0;
    return res.first['c'] as int? ?? 0;
  }

  Future<void> seedProductsIfEmpty() async {
    final db = await database;
    if (db == null) return;
    await _seedProductsIfEmpty(db);
    await cleanNonElectronics(targetDb: db);
  }

  Future<void> _seedProductsIfEmpty(Database db) async {
    final count = await _countRows(db, 'products');
    if (count == 0) {
      for (var product in _defaultProducts()) {
        await db.insert('products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } else {
      for (var product in _defaultProducts()) {
        await db.rawUpdate(
          "UPDATE products SET image = ? WHERE id = ? OR image LIKE '%products/images%'",
          [product.image, product.id],
        );
      }
    }
  }

  List<ProductModel> _defaultProducts() {
    return [
      ProductModel(
        id: 1,
        name: 'MacBook Pro 14" M3',
        description: 'Laptop profesional dengan chip M3 Pro, layar Liquid Retina XDR 14 inci, dan baterai hingga 18 jam pemakaian.',
        price: 24999000,
        stock: 10,
        image: 'https://cdn.dummyjson.com/product-images/laptops/apple-macbook-pro-14-inch-space-grey/thumbnail.webp',
        category: 'laptops',
      ),
      ProductModel(
        id: 2,
        name: 'iPhone 13 Pro Flagship',
        description: 'Smartphone flagship dengan kamera Pro, chip A15 Bionic, dan rangka stainless steel premium.',
        price: 18999000,
        stock: 15,
        image: 'https://cdn.dummyjson.com/product-images/smartphones/iphone-13-pro/thumbnail.webp',
        category: 'smartphones',
      ),
      ProductModel(
        id: 3,
        name: 'Samsung Galaxy S10',
        description: 'Ponsel flagship Samsung dengan layar Dynamic AMOLED, kamera ultra-wide, dan sensor sidik jari di layar.',
        price: 12500000,
        stock: 12,
        image: 'https://cdn.dummyjson.com/product-images/smartphones/samsung-galaxy-s10/thumbnail.webp',
        category: 'smartphones',
      ),
      ProductModel(
        id: 4,
        name: 'Apple AirPods Pro Wireless',
        description: 'True wireless earbuds dengan Active Noise Cancellation dan Spatial Audio imersif.',
        price: 4999000,
        stock: 20,
        image: 'https://cdn.dummyjson.com/product-images/mobile-accessories/apple-airpods/thumbnail.webp',
        category: 'audio',
      ),
      ProductModel(
        id: 5,
        name: 'Amazon Echo Plus Speaker',
        description: 'Speaker pintar bluetooth dengan kualitas suara surround bass powerful dan integrasi pintar.',
        price: 1999000,
        stock: 25,
        image: 'https://cdn.dummyjson.com/product-images/mobile-accessories/amazon-echo-plus/thumbnail.webp',
        category: 'audio',
      ),
      ProductModel(
        id: 6,
        name: 'iPad Mini 2021 Starlight',
        description: 'Tablet lipat portabel dengan chip A15 Bionic, layar Liquid Retina 8.3 inci, dan dukungan Apple Pencil.',
        price: 12999000,
        stock: 8,
        image: 'https://cdn.dummyjson.com/product-images/tablets/ipad-mini-2021-starlight/thumbnail.webp',
        category: 'tablets',
      ),
      ProductModel(
        id: 7,
        name: 'Apple Watch Series 4 Gold',
        description: 'Smartwatch premium dengan pemantau detak jantung, layar Retina selalu aktif, dan desain emas yang elegan.',
        price: 5499000,
        stock: 30,
        image: 'https://cdn.dummyjson.com/product-images/mobile-accessories/apple-watch-series-4-gold/thumbnail.webp',
        category: 'accessories',
      ),
      ProductModel(
        id: 8,
        name: 'Samsung Galaxy Tab S8 Plus',
        description: 'Tablet Android performa tinggi dengan S-Pen bawaan, layar Super AMOLED 12.4 inci 120Hz.',
        price: 14999000,
        stock: 9,
        image: 'https://cdn.dummyjson.com/product-images/tablets/samsung-galaxy-tab-s8-plus-grey/thumbnail.webp',
        category: 'tablets',
      ),
      ProductModel(
        id: 9,
        name: 'Asus Zenbook Pro Dual Screen',
        description: 'Laptop inovatif layar ganda ScreenPad Plus 4K untuk produktivitas & kreasi konten tanpa batas.',
        price: 22999000,
        stock: 6,
        image: 'https://cdn.dummyjson.com/product-images/laptops/asus-zenbook-pro-dual-screen-laptop/thumbnail.webp',
        category: 'laptops',
      ),
      ProductModel(
        id: 10,
        name: 'Apple AirPods Max Silver',
        description: 'Headphone over-ear nirkabel mewah dengan audio resolusi tinggi & pembatalan bising aktif kelas atas.',
        price: 8499000,
        stock: 14,
        image: 'https://cdn.dummyjson.com/product-images/mobile-accessories/apple-airpods-max-silver/thumbnail.webp',
        category: 'audio',
      ),
    ];
  }

  // ==================== AUTH SESSION METHODS ====================

  Future<void> saveSession({
    required int userId,
    required String token,
    required String name,
    required String email,
    required String role,
  }) async {
    final db = await database;
    if (db == null) return;

    await db.insert(
      'auth_session',
      {
        'id': 1, // Single active session record
        'userId': userId,
        'token': token,
        'name': name,
        'email': email,
        'role': role,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getSession() async {
    final db = await database;
    if (db == null) return null;

    List<Map<String, dynamic>> results = await db.query('auth_session', where: 'id = ?', whereArgs: [1]);
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<UserModel?> getCachedUser() async {
    final session = await getSession();
    if (session != null) {
      return UserModel(
        id: session['userId'] as int,
        name: session['name'] as String,
        email: session['email'] as String,
        password: '',
        role: session['role'] as String,
      );
    }
    return null;
  }

  Future<void> clearSession() async {
    final db = await database;
    if (db == null) return;

    await db.delete('auth_session', where: 'id = ?', whereArgs: [1]);
  }

  // ==================== USERS METHODS ====================

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    if (db == null) return null;

    final results = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [email.toLowerCase()],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    if (db == null) return null;

    final results = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  Future<bool> registerUser(String name, String email, String password, {String role = 'user'}) async {
    final db = await database;
    if (db == null) return false;

    final existing = await getUserByEmail(email);
    if (existing != null) return false;

    try {
      await db.insert('users', {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateUserProfile(int id, String name, String email) async {
    final db = await database;
    if (db == null) return false;

    try {
      await db.update('users', {'name': name, 'email': email}, where: 'id = ?', whereArgs: [id]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> changeUserPassword(int id, String oldPassword, String newPassword) async {
    final db = await database;
    if (db == null) return false;

    final user = await getUserById(id);
    if (user == null || user.password != oldPassword) return false;

    try {
      await db.update('users', {'password': newPassword}, where: 'id = ?', whereArgs: [id]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<int> getUserCount() async {
    final db = await database;
    if (db == null) return 0;
    return _countRows(db, 'users');
  }

  // ==================== PRODUCTS METHODS ====================

  Future<List<ProductModel>> getAllProducts() async {
    final db = await database;
    if (db == null) return [];

    final maps = await db.query('products', orderBy: 'id DESC');
    return maps.map((m) => ProductModel.fromMap(m)).toList();
  }

  Future<ProductModel?> getProductByIdLocal(int id) async {
    final db = await database;
    if (db == null) return null;

    final maps = await db.query('products', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return ProductModel.fromMap(maps.first);
  }

  Future<List<ProductModel>> getProductsByCategory(String category) async {
    final db = await database;
    if (db == null) return [];

    final maps = await db.query(
      'products',
      where: 'LOWER(category) = ?',
      whereArgs: [category.toLowerCase()],
      orderBy: 'id DESC',
    );
    return maps.map((m) => ProductModel.fromMap(m)).toList();
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    final db = await database;
    if (db == null) return [];

    final maps = await db.query(
      'products',
      where: 'LOWER(name) LIKE ? OR LOWER(description) LIKE ?',
      whereArgs: ['%${query.toLowerCase()}%', '%${query.toLowerCase()}%'],
      orderBy: 'id DESC',
    );
    return maps.map((m) => ProductModel.fromMap(m)).toList();
  }

  Future<List<String>> getCategories() async {
    final db = await database;
    if (db == null) return [];

    final res = await db.rawQuery('SELECT DISTINCT category FROM products ORDER BY category ASC');
    return res
        .map((r) => r['category']?.toString() ?? '')
        .where((c) => c.isNotEmpty)
        .toList();
  }

  Future<void> insertProduct(ProductModel product) async {
    final db = await database;
    if (db == null) return;

    await db.insert('products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProductLocal(ProductModel product) async {
    final db = await database;
    if (db == null) return;

    await db.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
  }

  Future<void> deleteProductLocal(int id) async {
    final db = await database;
    if (db == null) return;

    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getProductCountLocal() async {
    final db = await database;
    if (db == null) return 0;
    return _countRows(db, 'products');
  }

  // ==================== CART METHODS ====================

  Future<List<CartModel>> getCartItems() async {
    final db = await database;
    if (db == null) return [];

    final maps = await db.query('cart', orderBy: 'id DESC');
    return maps.map((m) => CartModel.fromMap(m)).toList();
  }

  Future<void> addToCart(int productId, int quantity) async {
    final db = await database;
    if (db == null) return;

    final existing = await db.query('cart', where: 'productId = ?', whereArgs: [productId], limit: 1);
    if (existing.isNotEmpty) {
      int newQty = (existing.first['quantity'] as int? ?? 0) + quantity;
      await db.update('cart', {'quantity': newQty}, where: 'productId = ?', whereArgs: [productId]);
    } else {
      await db.insert('cart', {'productId': productId, 'quantity': quantity});
    }
  }

  Future<void> updateCartQuantity(int id, int quantity) async {
    final db = await database;
    if (db == null) return;

    await db.update('cart', {'quantity': quantity}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> removeCartItem(int id) async {
    final db = await database;
    if (db == null) return;

    await db.delete('cart', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearCart() async {
    final db = await database;
    if (db == null) return;

    await db.delete('cart');
  }

  // ==================== WISHLIST METHODS ====================

  Future<List<ProductModel>> getWishlist(int userId) async {
    final db = await database;
    if (db == null) return [];

    final maps = await db.rawQuery('''
      SELECT p.* FROM wishlist w
      INNER JOIN products p ON p.id = w.productId
      WHERE w.userId = ?
      ORDER BY w.id DESC
    ''', [userId]);
    return maps.map((m) => ProductModel.fromMap(m)).toList();
  }

  Future<bool> addToWishlist(int userId, int productId) async {
    final db = await database;
    if (db == null) return false;

    try {
      await db.insert('wishlist', {'userId': userId, 'productId': productId});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeFromWishlist(int userId, int productId) async {
    final db = await database;
    if (db == null) return false;

    try {
      await db.delete('wishlist', where: 'userId = ? AND productId = ?', whereArgs: [userId, productId]);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ==================== REVIEWS METHODS ====================

  Future<List<ReviewModel>> getReviewsForProduct(int productId) async {
    final db = await database;
    if (db == null) return [];

    final maps = await db.query('reviews', where: 'productId = ?', whereArgs: [productId], orderBy: 'id DESC');
    return maps.map((m) => ReviewModel.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> getProductReviewSummary(int productId) async {
    final reviews = await getReviewsForProduct(productId);
    double avg = 0;
    if (reviews.isNotEmpty) {
      avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
    }
    return {
      'reviews': reviews,
      'avgRating': avg,
      'count': reviews.length,
    };
  }

  Future<Set<String>> getUserReviewedPairs(int userId) async {
    final db = await database;
    if (db == null) return {};

    final maps = await db.query('reviews', where: 'userId = ?', whereArgs: [userId]);
    return maps
        .map((m) => '${m['transactionId']}_${m['productId']}')
        .toSet();
  }

  Future<bool> addReview(ReviewModel review) async {
    final db = await database;
    if (db == null) return false;

    try {
      await db.insert('reviews', {
        'userId': review.userId,
        'userName': review.userName,
        'productId': review.productId,
        'transactionId': review.transactionId,
        'rating': review.rating,
        'comment': review.comment,
        'date': review.date,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // ==================== BANNERS METHODS ====================

  Future<List<BannerModel>> getBanners() async {
    final db = await database;
    if (db == null) return [];

    final maps = await db.query('banners', orderBy: 'id ASC');
    return maps.map((m) => BannerModel.fromMap(m)).toList();
  }

  // ==================== TRANSACTIONS METHODS ====================

  Future<int> insertTransactionWithItems(
    TransactionModel transaction,
    List<TransactionItemModel> items,
  ) async {
    final db = await database;
    if (db == null) return 0;

    int transactionId = 0;
    try {
      await db.transaction((txn) async {
        transactionId = await txn.insert('transactions', {
          'invoice': transaction.invoice,
          'userId': transaction.userId,
          'total': transaction.total,
          'shippingFee': transaction.shippingFee,
          'address': transaction.address,
          'status': transaction.status,
          'date': transaction.date,
          'paymentMethod': transaction.paymentMethod,
          'courier': transaction.courier,
          'trackingNumber': transaction.trackingNumber,
        });

        for (var item in items) {
          await txn.insert('transaction_items', {
            'transactionId': transactionId,
            'productId': item.productId,
            'quantity': item.quantity,
            'price': item.price,
          });
        }

        await txn.delete('cart');
      });
    } catch (_) {}
    return transactionId;
  }

  Future<List<TransactionModel>> getTransactionsByUser(int userId) async {
    final db = await database;
    if (db == null) return [];

    final maps = await db.query('transactions', where: 'userId = ?', whereArgs: [userId], orderBy: 'id DESC');
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    if (db == null) return [];

    final maps = await db.query('transactions', orderBy: 'id DESC');
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<List<TransactionItemModel>> getTransactionItems(int transactionId) async {
    final db = await database;
    if (db == null) return [];

    final maps = await db.rawQuery('''
      SELECT ti.*, p.name AS productName, p.image AS productImage
      FROM transaction_items ti
      LEFT JOIN products p ON p.id = ti.productId
      WHERE ti.transactionId = ?
    ''', [transactionId]);
    return maps.map((m) => TransactionItemModel.fromMap(m)).toList();
  }

  Future<void> updateTransactionStatusLocal(int id, String status) async {
    final db = await database;
    if (db == null) return;

    try {
      await db.transaction((txn) async {
        final prev = await txn.query(
          'transactions',
          columns: ['status'],
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );
        String oldStatus = prev.isNotEmpty ? (prev.first['status']?.toString() ?? '') : '';

        await txn.update('transactions', {'status': status}, where: 'id = ?', whereArgs: [id]);

        // Kurangi stok produk secara atomic saat transaksi dinyatakan selesai
        if ((status == 'Selesai' || status == 'completed') &&
            oldStatus != 'Selesai' && oldStatus != 'completed') {
          final items = await txn.query(
            'transaction_items',
            columns: ['productId', 'quantity'],
            where: 'transactionId = ?',
            whereArgs: [id],
          );
          for (var item in items) {
            int productId = item['productId'] as int;
            int qty = item['quantity'] as int;
            await txn.rawUpdate('UPDATE products SET stock = MAX(0, stock - ?) WHERE id = ?', [qty, productId]);
          }
        }
      });
    } catch (_) {}
  }

  Future<void> updateTrackingNumberLocal(int id, String courier, String trackingNumber) async {
    final db = await database;
    if (db == null) return;

    try {
      await db.update(
        'transactions',
        {'courier': courier, 'trackingNumber': trackingNumber, 'status': 'Dikirim'},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (_) {}
  }

  Future<double> getTotalRevenueLocal() async {
    final db = await database;
    if (db == null) return 0;

    final res = await db.rawQuery(
      "SELECT COALESCE(SUM(total), 0) AS total FROM transactions WHERE status IN ('Selesai', 'completed')",
    );
    if (res.isEmpty) return 0;
    return (res.first['total'] as num? ?? 0).toDouble();
  }

  Future<Map<String, dynamic>> getSalesReport() async {
    final transactions = await getAllTransactions();

    final orders = <Map<String, dynamic>>[];
    for (var t in transactions) {
      final user = await getUserById(t.userId);
      orders.add({
        'invoice': t.invoice,
        'userName': user?.name ?? 'User #${t.userId}',
        'userId': t.userId,
        'date': t.date,
        'paymentMethod': t.paymentMethod,
        'total': t.total,
        'status': t.status,
      });
    }

    final totalOrders = transactions.length;
    final completed = transactions
        .where((t) => t.status == 'Selesai' || t.status == 'completed')
        .length;
    final totalRevenue = transactions
        .where((t) => t.status == 'Selesai' || t.status == 'completed')
        .fold<double>(0, (sum, t) => sum + t.total);

    return {
      'summary': {
        'totalOrders': totalOrders,
        'completedOrders': completed,
        'totalRevenue': totalRevenue,
      },
      'orders': orders,
    };
  }
}
