import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  static const String appName = 'Tiptronic';

  static String get apiBaseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      // Android emulator menggunakan alamat 10.0.2.2 untuk menembak localhost PC
      return 'http://10.0.2.2:5000/api';
    }
    // Web Chrome atau Windows Desktop langsung menggunakan localhost
    return 'http://localhost:5000/api';
  }

  static const String dummyJsonBaseUrl = 'https://dummyjson.com';
  static const String productsEndpoint = '/products';
  static const String productsSearchEndpoint = '/products/search';
  static const int productsLimit = 30;
}
