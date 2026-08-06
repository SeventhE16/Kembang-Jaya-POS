import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/store_context.dart';
import '../../data/models/fee_model.dart';
import '../../core/services/fee_service.dart';

class FeeProvider extends ChangeNotifier {
  StreamSubscription? _sub;
  StreamSubscription? _storeSub;
  final FeeService _service = FeeService();
  List<Fee> _fees = [];
  bool _isLoading = false;

  List<Fee> get fees => _fees;
  bool get isLoading => _isLoading;

  FeeProvider() {
    _storeSub = StoreContext().storeIdStream.listen((storeId) {
      _sub?.cancel();
      if (storeId == null) {
        _fees = [];
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
    
    _sub = _service.streamFees().listen((data) {
      _fees = data;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading fees: $e');
    });
  }

  Future<void> addFee(Fee fee) async {
    await _service.addFee(fee);
  }

  Future<void> updateFee(Fee fee) async {
    await _service.updateFee(fee);
  }

  Future<void> deleteFee(String id) async {
    await _service.deleteFee(id);
  }
  @override
  void dispose() {
    _sub?.cancel();
    _storeSub?.cancel();
    super.dispose();
  }
}