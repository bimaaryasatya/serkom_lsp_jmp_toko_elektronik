import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/constants.dart';
import '../database/database_helper.dart';
import '../models/product_model.dart';

class ProductRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<List<ProductModel>> fetchProductsFromApi() async {
    final response = await http.get(
      Uri.parse('${AppConstants.dummyJsonBaseUrl}${AppConstants.productsEndpoint}?limit=${AppConstants.productsLimit}'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> productsJson = data['products'];
      return productsJson.map((json) => ProductModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products from API');
    }
  }

  Future<List<ProductModel>> searchProductsFromApi(String query) async {
    final response = await http.get(
      Uri.parse('${AppConstants.dummyJsonBaseUrl}${AppConstants.productsSearchEndpoint}?q=$query'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> productsJson = data['products'];
      return productsJson.map((json) => ProductModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search products');
    }
  }

  Future<void> syncProductsToLocal() async {
    try {
      int count = await _db.getProductCount();
      if (count > 0) return; // Jika MySQL sudah ada data produk dari impor schema.sql, lewati
      final products = await fetchProductsFromApi();
      for (var product in products) {
        await _db.insertProduct(product);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ProductModel>> getLocalProducts() async {
    return await _db.getProducts();
  }

  Future<ProductModel?> getProductById(int id) async {
    return await _db.getProductById(id);
  }

  Future<List<ProductModel>> getProductsByCategory(String category) async {
    final products = await _db.getProducts();
    return products.where((p) => p.category == category).toList();
  }

  Future<List<String>> getCategories() async {
    final response = await http.get(
      Uri.parse('${AppConstants.dummyJsonBaseUrl}${AppConstants.productsEndpoint}/categories'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => e['slug'] as String).toList();
    }
    return [];
  }

  Future<void> addProduct(ProductModel product) async {
    await _db.insertProduct(product);
  }

  Future<void> updateProduct(ProductModel product) async {
    await _db.updateProduct(product);
  }

  Future<void> deleteProduct(int id) async {
    await _db.deleteProduct(id);
  }
}
