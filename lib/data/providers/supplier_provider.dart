import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/store_context.dart';
import '../../core/services/supplier_service.dart';

class SupplierProvider extends ChangeNotifier {
  StreamSubscription? _sub;
  StreamSubscription? _storeSub;
  final SupplierService _supplierService = SupplierService();
  List<Supplier> _suppliers = [];
  bool _isLoading = true;

  List<Supplier> get suppliers => _suppliers;
  bool get isLoading => _isLoading;

  SupplierProvider() {
    _storeSub = StoreContext().storeIdStream.listen((storeId) {
      _sub?.cancel();
      if (storeId == null) {
        _suppliers = [];
        _isLoading = true;
        notifyListeners();
      } else {
        _sub = _supplierService.streamSuppliers().listen((suppliers) {
          _suppliers = suppliers;
          _isLoading = false;
          notifyListeners();
        }, onError: (error) {
          _isLoading = false;
          notifyListeners();
        });
      }
    });
    
    if (StoreContext().storeIdOrNull != null) {
      _sub = _supplierService.streamSuppliers().listen((suppliers) {
        _suppliers = suppliers;
        _isLoading = false;
        notifyListeners();
      }, onError: (error) {
        _isLoading = false;
        notifyListeners();
      });
    }
  }

  Future<void> addSupplier(Supplier supplier) async {
    await _supplierService.addSupplier(supplier);
  }

  Future<void> updateSupplier(Supplier supplier) async {
    await _supplierService.updateSupplier(supplier);
  }

  Future<void> deleteSupplier(String id) async {
    await _supplierService.deleteSupplier(id);
  }
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}