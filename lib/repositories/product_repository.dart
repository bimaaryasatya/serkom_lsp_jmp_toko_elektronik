import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/constants.dart';
import '../database/sqlite_helper.dart';
import '../models/product_model.dart';

class ProductRepository {
  final SqliteHelper _sqliteHelper = SqliteHelper();

  Future<List<ProductModel>> fetchProductsFromApi() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.dummyJsonBaseUrl}${AppConstants.productsEndpoint}?limit=${AppConstants.productsLimit}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> productsJson = data['products'];
        final products = productsJson.map((json) => ProductModel.fromJson(json)).toList();
        await _sqliteHelper.cacheProducts(products);
        return products;
      } else {
        throw Exception('Gagal memuat produk dari API eksternal');
      }
    } catch (e) {
      return getLocalProducts();
    }
  }

  Future<List<ProductModel>> searchProductsFromApi(String query) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/products?search=${Uri.encodeComponent(query)}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        final products = list.map((e) => ProductModel.fromMap(Map<String, dynamic>.from(e))).toList();
        if (products.isNotEmpty) {
          await _sqliteHelper.cacheProducts(products);
        }
        return products;
      }
      return await _sqliteHelper.searchCachedProducts(query);
    } catch (_) {
      // Fallback ke pencarian SQLite lokal saat offline
      return await _sqliteHelper.searchCachedProducts(query);
    }
  }

  Future<void> syncProductsToLocal() async {
    try {
      final countRes = await http.get(Uri.parse('${AppConstants.apiBaseUrl}/products/count'));
      if (countRes.statusCode == 200) {
        final data = json.decode(countRes.body);
        if ((data['count'] ?? 0) > 0) return; // Jika sudah ada data produk di MySQL, skip
      }

      final products = await fetchProductsFromApi();
      for (var product in products) {
        await addProduct(product);
      }
    } catch (e) {
      // Abaikan error sync agar tidak crash
    }
  }

  Future<List<ProductModel>> getLocalProducts() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.apiBaseUrl}/products'));
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        final products = list.map((e) {
          final map = Map<String, dynamic>.from(e);
          if (map['price'] != null) map['price'] = (map['price'] as num).toDouble();
          if (map['stock'] != null) map['stock'] = (map['stock'] as num).toInt();
          return ProductModel.fromMap(map);
        }).toList();

        // Simpan ke cache SQLite lokal
        if (products.isNotEmpty) {
          await _sqliteHelper.cacheProducts(products);
        }
        return products;
      }

      // Jika response bukan 200, ambil dari cache SQLite
      return await _sqliteHelper.getCachedProducts();
    } catch (e) {
      // Jika terjadi kesalahan koneksi/offline, ambil dari cache SQLite
      return await _sqliteHelper.getCachedProducts();
    }
  }

  Future<ProductModel?> getProductById(int id) async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.apiBaseUrl}/products/$id'));
      if (response.statusCode == 200) {
        final map = Map<String, dynamic>.from(json.decode(response.body));
        if (map['price'] != null) map['price'] = (map['price'] as num).toDouble();
        if (map['stock'] != null) map['stock'] = (map['stock'] as num).toInt();
        final product = ProductModel.fromMap(map);
        await _sqliteHelper.cacheProducts([product]);
        return product;
      }
    } catch (_) {}

    // Fallback ke cache SQLite
    final cached = await _sqliteHelper.getCachedProducts();
    try {
      return cached.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/products?category=${Uri.encodeComponent(category)}'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        final products = list.map((e) {
          final map = Map<String, dynamic>.from(e);
          if (map['price'] != null) map['price'] = (map['price'] as num).toDouble();
          if (map['stock'] != null) map['stock'] = (map['stock'] as num).toInt();
          return ProductModel.fromMap(map);
        }).toList();

        if (products.isNotEmpty) {
          await _sqliteHelper.cacheProducts(products);
        }
        return products;
      }
      return await _sqliteHelper.getCachedProductsByCategory(category);
    } catch (_) {
      return await _sqliteHelper.getCachedProductsByCategory(category);
    }
  }


  Future<List<String>> getCategories() async {
    try {
      final products = await getLocalProducts();
      final categories = products.map((p) => p.category).toSet().toList();
      if (categories.isNotEmpty) return categories;

      final response = await http.get(
        Uri.parse('${AppConstants.dummyJsonBaseUrl}${AppConstants.productsEndpoint}/categories'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => e['slug'] as String).toList();
      }
      return [];
    } catch (_) {
      return ['laptops', 'smartphones', 'audio', 'tv'];
    }
  }

  Future<void> addProduct(ProductModel product) async {
    await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/products'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(product.toMap()),
    );
  }

  Future<void> updateProduct(ProductModel product) async {
    await http.put(
      Uri.parse('${AppConstants.apiBaseUrl}/products/${product.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(product.toMap()),
    );
  }

  Future<void> deleteProduct(int id) async {
    await http.delete(
      Uri.parse('${AppConstants.apiBaseUrl}/products/$id'),
    );
  }
}
