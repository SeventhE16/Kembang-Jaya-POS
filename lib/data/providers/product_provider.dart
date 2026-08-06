import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/store_context.dart';
import '../../data/models/product_model.dart';
import '../../core/services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  StreamSubscription? _sub;
  StreamSubscription? _storeSub;
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  List<String> get categories {
    final Set<String> cats = {'Semua'};
    for (var p in _products) {
      cats.add(p.category);
    }
    return cats.toList();
  }

  ProductProvider() {
    _storeSub = StoreContext().storeIdStream.listen((storeId) {
      _sub?.cancel();
      if (storeId == null) {
        _products = [];
        _isLoading = true;
        notifyListeners();
      } else {
        _sub = _productService.streamProducts().listen((products) {
          _products = products;
          _isLoading = false;
          notifyListeners();
        });
      }
    });
    
    if (StoreContext().storeIdOrNull != null) {
      _sub = _productService.streamProducts().listen((products) {
        _products = products;
        _isLoading = false;
        notifyListeners();
      });
    }
  }

  Future<void> addProduct(Product product) async {
    await _productService.addProduct(product);
  }

  Future<void> updateProduct(Product product) async {
    await _productService.updateProduct(product);
  }

  Future<void> deleteProduct(String id) async {
    await _productService.deleteProduct(id);
  }

  Future<void> reduceStock(String productId, int quantity) async {
    await _productService.reduceStock(productId, quantity);
  }

  Future<void> transferStock(String sourceId, String targetId, int quantity) async {
    await _productService.transferStock(sourceId, targetId, quantity);
  }
  @override
  void dispose() {
    _sub?.cancel();
    _storeSub?.cancel();
    super.dispose();
  }
}