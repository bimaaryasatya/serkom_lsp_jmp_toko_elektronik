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

  double? _minPrice;
  double? _maxPrice;
  String _sort = 'latest';

  List<ProductModel> get products => _filteredProducts;
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
      _applyFilterInternal();
    } catch (e) {
      _products = await _repository.getLocalProducts();
      _categories = _getUniqueCategories();
      _applyFilterInternal();
    }

    _isLoading = false;
    notifyListeners();
  }

  List<String> _getUniqueCategories() {
    return _products.map((p) => p.category).toSet().toList();
  }

  void filterByCategory(String? category) {
    _selectedCategory = category;
    _applyFilterInternal();
    notifyListeners();
  }

  void searchProducts(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilterInternal();
    notifyListeners();
  }

  void applyFilter({double? minPrice, double? maxPrice, String? sort}) {
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    if (sort != null) _sort = sort;
    _applyFilterInternal();
    notifyListeners();
  }

  void _applyFilterInternal() {
    var result = List<ProductModel>.from(_products);

    if (_selectedCategory != null) {
      result = result.where((p) => p.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      result = result.where((p) =>
          p.name.toLowerCase().contains(_searchQuery) ||
          p.description.toLowerCase().contains(_searchQuery)).toList();
    }

    if (_minPrice != null) {
      result = result.where((p) => p.price >= _minPrice!).toList();
    }

    if (_maxPrice != null) {
      result = result.where((p) => p.price <= _maxPrice!).toList();
    }

    if (_sort == 'price_asc') {
      result.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sort == 'price_desc') {
      result.sort((a, b) => b.price.compareTo(a.price));
    } else {
      result.sort((a, b) => b.id.compareTo(a.id));
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
    _applyFilterInternal();
    notifyListeners();
  }

  Future<void> updateProduct(ProductModel product) async {
    await _repository.updateProduct(product);
    int index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
    }
    _applyFilterInternal();
    notifyListeners();
  }

  Future<void> deleteProduct(int id) async {
    await _repository.deleteProduct(id);
    _products.removeWhere((p) => p.id == id);
    _applyFilterInternal();
    notifyListeners();
  }
}
