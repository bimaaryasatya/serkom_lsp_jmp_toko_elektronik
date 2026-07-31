import 'package:sqflite_common/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Inisialisasi database factory untuk platform Web (Chrome).
/// Menggunakan SQLite WebAssembly (Main Thread / IndexedDB) tanpa Web Worker
/// untuk menghindari error RPC 'unsupported result null' di browser.
void initDatabaseFactory() {
  databaseFactory = databaseFactoryFfiWebNoWebWorker;
}

