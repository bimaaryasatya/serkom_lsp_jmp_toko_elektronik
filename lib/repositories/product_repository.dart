import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/sqlite_helper.dart';
import '../models/product_model.dart';

class ProductRepository {
  final SqliteHelper _sqliteHelper = SqliteHelper();

  Future<List<ProductModel>> fetchProductsFromApi() async {
    await syncProductsToLocal();
    return getLocalProducts();
  }

  Future<List<ProductModel>> searchProductsFromApi(String query) async {
    return _sqliteHelper.searchProducts(query);
  }

  Future<void> syncProductsToLocal() async {
    await _sqliteHelper.seedProductsIfEmpty();
    await _sqliteHelper.cleanNonElectronics();

    final categoriesToFetch = [
      'laptops',
      'smartphones',
      'tablets',
      'mobile-accessories',
    ];

    for (var cat in categoriesToFetch) {
      try {
        final response = await http
            .get(Uri.parse('https://dummyjson.com/products/category/$cat'))
            .timeout(const Duration(seconds: 6));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data is Map<String, dynamic> && data['products'] is List) {
            final List productsJson = data['products'];
            for (var item in productsJson) {
              if (item is Map<String, dynamic>) {
                double price = (item['price'] is num) ? (item['price'] as num).toDouble() : 0.0;
                // Convert USD price to IDR if price is under 10000
                if (price < 10000) {
                  price = (price * 15000).roundToDouble();
                }
                List<String> imgList = [];
                if (item['images'] is List) {
                  imgList = (item['images'] as List).map((e) => e.toString()).toList();
                }
                final thumb = item['thumbnail']?.toString() ?? (imgList.isNotEmpty ? imgList.first : '');
                if (thumb.isNotEmpty && !imgList.contains(thumb)) {
                  imgList.insert(0, thumb);
                }

                final product = ProductModel(
                  id: item['id'] as int,
                  name: item['title']?.toString() ?? '',
                  description: item['description']?.toString() ?? '',
                  price: price,
                  stock: (item['stock'] is int) ? item['stock'] as int : 10,
                  image: thumb,
                  images: imgList,
                  category: item['category']?.toString() ?? cat,
                );
                await _sqliteHelper.insertProduct(product);
              }
            }
          }
        }
      } catch (_) {
        // Fallback silently if offline or request fails
      }
    }
  }

  Future<List<ProductModel>> getLocalProducts() async {
    return _sqliteHelper.getAllProducts();
  }

  Future<ProductModel?> getProductById(int id) async {
    return _sqliteHelper.getProductByIdLocal(id);
  }

  Future<List<ProductModel>> getProductsByCategory(String category) async {
    return _sqliteHelper.getProductsByCategory(category);
  }

  Future<List<String>> getCategories() async {
    final categories = await _sqliteHelper.getCategories();
    if (categories.isNotEmpty) return categories;
    return ['laptops', 'smartphones', 'audio', 'tv'];
  }

  Future<int> getProductCount() async {
    return _sqliteHelper.getProductCountLocal();
  }

  Future<void> addProduct(ProductModel product) async {
    await _sqliteHelper.insertProduct(product);
  }

  Future<void> updateProduct(ProductModel product) async {
    await _sqliteHelper.updateProductLocal(product);
  }

  Future<void> deleteProduct(int id) async {
    await _sqliteHelper.deleteProductLocal(id);
  }
}
