import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/store_context.dart';
import '../../data/models/customer_model.dart';
import '../../core/services/customer_service.dart';

class CustomerProvider extends ChangeNotifier {
  StreamSubscription? _sub;
  StreamSubscription? _storeSub;
  final CustomerService _customerService = CustomerService();
  List<Customer> _customers = [];
  bool _isLoading = true;

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;

  CustomerProvider() {
    _storeSub = StoreContext().storeIdStream.listen((storeId) {
      _sub?.cancel();
      if (storeId == null) {
        _customers = [];
        _isLoading = true;
        notifyListeners();
      } else {
        _sub = _customerService.streamCustomers().listen((customers) {
          _customers = customers;
          _isLoading = false;
          notifyListeners();
        }, onError: (error) {
          _isLoading = false;
          notifyListeners();
        });
      }
    });
    
    if (StoreContext().storeIdOrNull != null) {
      _sub = _customerService.streamCustomers().listen((customers) {
        _customers = customers;
        _isLoading = false;
        notifyListeners();
      }, onError: (error) {
        _isLoading = false;
        notifyListeners();
      });
    }
  }

  Future<void> addCustomer(Customer customer) async {
    await _customerService.addCustomer(customer);
  }

  Future<void> updateCustomer(Customer customer) async {
    await _customerService.updateCustomer(customer);
  }

  Future<void> deleteCustomer(String id) async {
    await _customerService.deleteCustomer(id);
  }
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}