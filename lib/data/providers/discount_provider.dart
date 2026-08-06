import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/store_context.dart';
import '../../data/models/discount_model.dart';
import '../../core/services/discount_service.dart';

class DiscountProvider extends ChangeNotifier {
  StreamSubscription? _sub;
  StreamSubscription? _storeSub;
  final DiscountService _service = DiscountService();
  List<Discount> _discounts = [];
  bool _isLoading = false;

  List<Discount> get discounts => _discounts;
  bool get isLoading => _isLoading;

  DiscountProvider() {
    _storeSub = StoreContext().storeIdStream.listen((storeId) {
      _sub?.cancel();
      if (storeId == null) {
        _discounts = [];
        _isLoading = true;
        notifyListeners();
      } else {
        _init();
      }
    });
    
    if (StoreContext().storeIdOrNull != null) {
      _init();
    }
  }

  void _init() {
    _isLoading = true;
    notifyListeners();
    
    _sub = _service.streamDiscounts().listen((data) {
      _discounts = data;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading discounts: $e');
    });
  }

  Future<void> addDiscount(Discount discount) async {
    await _service.addDiscount(discount);
  }

  Future<void> updateDiscount(Discount discount) async {
    await _service.updateDiscount(discount);
  }

  Future<void> deleteDiscount(String id) async {
    await _service.deleteDiscount(id);
  }
  @override
  void dispose() {
    _sub?.cancel();
    _storeSub?.cancel();
    super.dispose();
  }
}