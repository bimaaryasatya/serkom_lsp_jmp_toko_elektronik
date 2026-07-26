import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _repository = ProductRepository();

  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<ProductModel> get products =>
      _selectedCategory != null ? _filteredProducts : _products;
  List<String> get categories => _categories;
  String? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.syncProductsToLocal();
      _products = await _repository.getLocalProducts();
      _categories = _getUniqueCategories();
      _applyFilter();
    } catch (e) {
      _products = await _repository.getLocalProducts();
      _categories = _getUniqueCategories();
      _applyFilter();
    }

    _isLoading = false;
    notifyListeners();
  }

  List<String> _getUniqueCategories() {
    return _products.map((p) => p.category).toSet().toList();
  }

  void filterByCategory(String? category) {
    _selectedCategory = category;
    _applyFilter();
    notifyListeners();
  }

  void searchProducts(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    var result = List<ProductModel>.from(_products);

    if (_selectedCategory != null) {
      result = result
          .where((p) => p.category == _selectedCategory)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      result = result
          .where((p) =>
              p.name.toLowerCase().contains(_searchQuery) ||
              p.description.toLowerCase().contains(_searchQuery))
          .toList();
    }

    _filteredProducts = result;
  }

  ProductModel? getProductById(int id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addProduct(ProductModel product) async {
    await _repository.addProduct(product);
    _products.add(product);
    _applyFilter();
    notifyListeners();
  }

  Future<void> updateProduct(ProductModel product) async {
    await _repository.updateProduct(product);
    int index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
    }
    _applyFilter();
    notifyListeners();
  }

  Future<void> deleteProduct(int id) async {
    await _repository.deleteProduct(id);
    _products.removeWhere((p) => p.id == id);
    _applyFilter();
    notifyListeners();
  }
}
