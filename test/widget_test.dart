import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:aplikasi_toko_elektronik/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    if (databaseFactoryOrNull == null) {
      databaseFactory = databaseFactoryFfi;
    }
  });

  testWidgets('App initializes correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
