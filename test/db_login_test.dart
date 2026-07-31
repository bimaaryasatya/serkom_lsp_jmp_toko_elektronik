import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common/sqflite.dart';

import 'package:aplikasi_toko_elektronik/database/sqlite_helper.dart';
import 'package:aplikasi_toko_elektronik/repositories/user_repository.dart';
import 'package:aplikasi_toko_elektronik/repositories/product_repository.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    if (databaseFactoryOrNull == null) {
      databaseFactory = databaseFactoryFfi;
    }
    final dbPath = await databaseFactory.getDatabasesPath();
    final testPath = p.join(dbPath, 'tiptronic_login_test.db');
    await databaseFactory.deleteDatabase(testPath).catchError((_) {});
    SqliteHelper.setCustomDbPath(testPath);
  });

  test('Login admin & user via SqliteHelper (schema penuh)', () async {
    final helper = SqliteHelper();

    final admin = await helper.getUserByEmail('admin@toko.com');
    expect(admin, isNotNull);
    expect(admin!.password, 'admin123');
    expect(admin.role, 'admin');

    final user = await helper.getUserByEmail('user@toko.com');
    expect(user, isNotNull);
    expect(user!.password, 'user123');
    expect(user.role, 'user');

    final products = await helper.getAllProducts();
    expect(products.length, greaterThanOrEqualTo(8));

    final banners = await helper.getBanners();
    expect(banners.length, 3);
  });

  test('Login via UserRepository (jalur yang dipakai AuthProvider)', () async {
    final repo = UserRepository();

    final admin = await repo.login('admin@toko.com', 'admin123');
    expect(admin, isNotNull);
    expect(admin!.role, 'admin');

    final user = await repo.login('user@toko.com', 'user123');
    expect(user, isNotNull);
    expect(user!.role, 'user');

    final wrong = await repo.login('user@toko.com', 'salah');
    expect(wrong, isNull);

    final unknown = await repo.login('x@x.com', '123');
    expect(unknown, isNull);
  });

  test('Produk & kategori via ProductRepository', () async {
    final repo = ProductRepository();
    final products = await repo.getLocalProducts();
    expect(products, isNotEmpty);
    final categories = await repo.getCategories();
    print('categories=$categories');
    expect(categories, isNotEmpty);
  });

  test('Register user baru lalu login', () async {
    final repo = UserRepository();
    final registered = await repo.register('Budi', 'budi@test.com', 'budi123');
    expect(registered, isTrue);

    final dup = await repo.register('Budi', 'budi@test.com', 'budi123');
    expect(dup, isFalse, reason: 'Email duplikat harus ditolak');

    final user = await repo.login('budi@test.com', 'budi123');
    expect(user, isNotNull);
  });
}
