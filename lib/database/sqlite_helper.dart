import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' show join;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';

class SqliteHelper {
  static SqliteHelper? _instance;
  static Database? _database;

  SqliteHelper._internal();

  factory SqliteHelper() {
    _instance ??= SqliteHelper._internal();
    return _instance!;
  }

  Future<Database?> get database async {
    if (_database != null) return _database;
    _database = await _initSqlite();
    return _database;
  }

  Future<Database?> _initSqlite() async {
    if (kIsWeb) {
      // Browser Sandbox/Web Chrome tidak mendukung FFI C binaries, return null untuk fallback ke REST API / SharedPreferences secara otomatis
      return null;
    }

    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
    } catch (_) {}

    try {
      String dbPath = await databaseFactory.getDatabasesPath();
      String path = join(dbPath, 'tiptronic_local.db');

      return await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            // Table for User Token / Session Storage
            await db.execute('''
              CREATE TABLE auth_session (
                id INTEGER PRIMARY KEY,
                userId INTEGER NOT NULL,
                token TEXT NOT NULL,
                name TEXT NOT NULL,
                email TEXT NOT NULL,
                role TEXT NOT NULL,
                updatedAt TEXT NOT NULL
              )
            ''');

            // Table for Offline Product Caching
            await db.execute('''
              CREATE TABLE products_cache (
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
          },
        ),
      );
    } catch (e) {
      return null;
    }
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

  // ==================== PRODUCT CACHE METHODS ====================

  Future<void> cacheProducts(List<ProductModel> products) async {
    if (products.isEmpty) return;
    final db = await database;
    if (db == null) return;

    Batch batch = db.batch();

    String now = DateTime.now().toIso8601String();
    for (var product in products) {
      batch.insert(
        'products_cache',
        {
          'id': product.id,
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'stock': product.stock,
          'image': product.image,
          'category': product.category,
          'updatedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<ProductModel>> getCachedProducts() async {
    final db = await database;
    if (db == null) return [];

    List<Map<String, dynamic>> maps = await db.query('products_cache', orderBy: 'id DESC');
    return maps.map((map) => ProductModel.fromMap(map)).toList();
  }

  Future<List<ProductModel>> getCachedProductsByCategory(String category) async {
    final db = await database;
    if (db == null) return [];

    List<Map<String, dynamic>> maps = await db.query(
      'products_cache',
      where: 'LOWER(category) = ?',
      whereArgs: [category.toLowerCase()],
      orderBy: 'id DESC',
    );
    return maps.map((map) => ProductModel.fromMap(map)).toList();
  }

  Future<List<ProductModel>> searchCachedProducts(String query) async {
    final db = await database;
    if (db == null) return [];

    List<Map<String, dynamic>> maps = await db.query(
      'products_cache',
      where: 'LOWER(name) LIKE ? OR LOWER(description) LIKE ?',
      whereArgs: ['%${query.toLowerCase()}%', '%${query.toLowerCase()}%'],
      orderBy: 'id DESC',
    );
    return maps.map((map) => ProductModel.fromMap(map)).toList();
  }
}
