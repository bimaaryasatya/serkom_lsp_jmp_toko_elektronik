import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

/// Inisialisasi database factory untuk platform native (io).
/// - Windows/Linux/macOS: SQLite via FFI (sqflite_common_ffi)
/// - Android/iOS: plugin sqflite native
void initDatabaseFactory() {
  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  } else {
    databaseFactory = databaseFactorySqflitePlugin;
  }
}
