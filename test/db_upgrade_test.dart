import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common/sqflite.dart';

import 'package:aplikasi_toko_elektronik/database/sqlite_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    if (databaseFactoryOrNull == null) {
      databaseFactory = databaseFactoryFfi;
    }
  });

  test('Upgrade dari DB v1 (aplikasi lama) tetap menghasilkan user', () async {
    final dbPath = await databaseFactory.getDatabasesPath();
    final path = p.join(dbPath, 'tiptronic_upgrade_test.db');
    SqliteHelper.setCustomDbPath(path);

    // Hapus DB yang ada
    await databaseFactory.deleteDatabase(path);

    // Simulasikan DB v1 dari aplikasi lama: hanya auth_session + products_cache
    final oldDb = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
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
    await oldDb.insert('auth_session', {
      'id': 1,
      'userId': 1,
      'token': 'old',
      'name': 'Admin',
      'email': 'admin@toko.com',
      'role': 'admin',
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await oldDb.close();

    // Sekarang buka lewat SqliteHelper (harus upgrade ke v2 + seed)
    final helper = SqliteHelper();
    final admin = await helper.getUserByEmail('admin@toko.com');
    print('admin after upgrade=$admin');
    expect(admin, isNotNull);
    expect(admin!.password, 'admin123');

    final user = await helper.getUserByEmail('user@toko.com');
    expect(user, isNotNull);
    expect(user!.password, 'user123');

    final products = await helper.getAllProducts();
    print('products after upgrade=${products.length}');
    expect(products, isNotEmpty);

    final session = await helper.getSession();
    print('session after upgrade=$session');
    expect(session, isNotNull, reason: 'Sesi lama harus tetap ada');
  });
}
