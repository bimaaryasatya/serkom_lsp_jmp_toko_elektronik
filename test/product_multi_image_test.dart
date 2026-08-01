import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_toko_elektronik/models/product_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('ProductModel Multi-Image Tests', () {
    test('ProductModel imageList fallback to primary image when images list is empty', () {
      final product = ProductModel(
        id: 1,
        name: 'Test Laptop',
        description: 'Desc',
        price: 1000,
        stock: 5,
        image: 'https://example.com/img1.jpg',
        images: [],
        category: 'laptops',
      );

      expect(product.imageList.length, equals(1));
      expect(product.imageList.first, equals('https://example.com/img1.jpg'));
    });

    test('ProductModel imageList returns multiple images when provided', () {
      final product = ProductModel(
        id: 2,
        name: 'Test Phone',
        description: 'Desc',
        price: 2000,
        stock: 10,
        image: 'https://example.com/img1.jpg',
        images: [
          'https://example.com/img1.jpg',
          'https://example.com/img2.jpg',
          'https://example.com/img3.jpg',
        ],
        category: 'smartphones',
      );

      expect(product.imageList.length, equals(3));
      expect(product.imageList[1], equals('https://example.com/img2.jpg'));
    });

    test('ProductModel map conversion retains images JSON string', () {
      final product = ProductModel(
        id: 3,
        name: 'Test Tablet',
        description: 'Desc',
        price: 3000,
        stock: 8,
        image: 'https://example.com/thumb.jpg',
        images: ['https://example.com/thumb.jpg', 'https://example.com/detail.jpg'],
        category: 'tablets',
      );

      final map = product.toMap();
      expect(map['images'], contains('https://example.com/detail.jpg'));

      final restored = ProductModel.fromMap(map);
      expect(restored.images.length, equals(2));
      expect(restored.imageList.length, equals(2));
      expect(restored.imageList[1], equals('https://example.com/detail.jpg'));
    });
  });
}
