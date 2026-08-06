import 'dart:async';

class StoreContext {
  static final StoreContext _instance = StoreContext._internal();
  
  factory StoreContext() {
    return _instance;
  }
  
  StoreContext._internal();
  
  String? _storeId;
  
  final StreamController<String?> _storeIdController = StreamController<String?>.broadcast();
  Stream<String?> get storeIdStream => _storeIdController.stream;
  
  String get storeId {
    if (_storeId == null) {
      throw Exception('StoreContext.storeId accessed before initialization or after logout');
    }
    return _storeId!;
  }
  
  String? get storeIdOrNull => _storeId;
  
  void setStoreId(String? id) {
    if (_storeId != id) {
      _storeId = id;
      _storeIdController.add(id);
    }
  }
}
