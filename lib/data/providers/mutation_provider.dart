import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/store_context.dart';
import '../models/mutation_model.dart';
import '../../core/services/mutation_service.dart';

class MutationProvider extends ChangeNotifier {
  StreamSubscription? _sub;
  StreamSubscription? _storeSub;
  final MutationService _mutationService = MutationService();
  List<GradeMutation> _mutations = [];
  bool _isLoading = false;

  List<GradeMutation> get mutations => _mutations;
  bool get isLoading => _isLoading;

  MutationProvider() {
    _storeSub = StoreContext().storeIdStream.listen((storeId) {
      _sub?.cancel();
      if (storeId == null) {
        _mutations = [];
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

    _sub = _mutationService.getMutations().listen((mutationsList) {
      _mutations = mutationsList;
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addMutation(GradeMutation mutation) async {
    try {
      await _mutationService.addMutation(mutation);
    } catch (e) {
      rethrow;
    }
  }
  @override
  void dispose() {
    _sub?.cancel();
    _storeSub?.cancel();
    super.dispose();
  }
}