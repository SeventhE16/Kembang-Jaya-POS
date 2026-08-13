import 'package:flutter/material.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/discount_model.dart';
import '../../data/models/fee_model.dart';
import '../../core/services/store_context.dart';
import 'dart:async';

class CartProvider extends ChangeNotifier {
  Map<String, CartItem> _activeCart = {};
  Customer? _activeCustomer;
  String? _activeNote;
  Discount? _activeDiscount;
  double _activeExtraDiscount = 0;
  Fee? _activeFee;
  double _activeExtraFee = 0;

  Map<String, CartItem> get activeCart => _activeCart;
  Customer? get activeCustomer => _activeCustomer;
  String? get activeNote => _activeNote;
  Discount? get activeDiscount => _activeDiscount;
  double get activeExtraDiscount => _activeExtraDiscount;
  Fee? get activeFee => _activeFee;
  double get activeExtraFee => _activeExtraFee;

  double get subtotal {
    return _activeCart.values.fold(0, (sum, item) => sum + item.subtotal);
  }

  StreamSubscription? _storeSub;

  CartProvider() {
    _storeSub = StoreContext().storeIdStream.listen((storeId) {
      if (storeId == null) {
        clearCart();
      }
    });
  }

  @override
  void dispose() {
    _storeSub?.cancel();
    super.dispose();
  }

  // Helper: total qty dari baris grosir + ecer untuk satu produk
  int _getTotalQtyForProduct(String productId) {
    final ecerQty = _activeCart[productId]?.quantity ?? 0;
    final grosirQty = _activeCart['${productId}_grosir']?.quantity ?? 0;
    return ecerQty + grosirQty;
  }

  // Helper: breakdown qty jadi baris grosir dan ecer
  void _applyWholesaleBreakdown(Product product, int totalQty) {
    if (totalQty <= 0) {
      _activeCart.remove(product.id);
      _activeCart.remove('${product.id}_grosir');
      return;
    }

    // Ambil tier grosir tertinggi
    if (product.wholesalePrices.isEmpty) return;
    final sortedTiers = List<WholesalePrice>.from(product.wholesalePrices)
      ..sort((a, b) => b.minQty.compareTo(a.minQty));
    final tier = sortedTiers.first;

    final wholesaleUnits = (totalQty ~/ tier.minQty) * tier.minQty;
    final remainderUnits = totalQty % tier.minQty;

    if (wholesaleUnits > 0) {
      if (_activeCart.containsKey('${product.id}_grosir')) {
        _activeCart['${product.id}_grosir']!.quantity = wholesaleUnits;
      } else {
        _activeCart['${product.id}_grosir'] = CartItem(product: product, quantity: wholesaleUnits);
      }
    } else {
      _activeCart.remove('${product.id}_grosir');
    }

    if (remainderUnits > 0) {
      if (_activeCart.containsKey(product.id)) {
        _activeCart[product.id]!.quantity = remainderUnits;
      } else {
        _activeCart[product.id] = CartItem(product: product, quantity: remainderUnits);
      }
    } else {
      _activeCart.remove(product.id);
    }
  }

  void addItem(CartItem item) {
    final product = item.product;
    if (product.wholesalePrices.isNotEmpty) {
      final currentTotal = _getTotalQtyForProduct(product.id);
      _applyWholesaleBreakdown(product, currentTotal + item.quantity);
    } else {
      if (_activeCart.containsKey(product.id)) {
        _activeCart[product.id]!.quantity += item.quantity;
      } else {
        _activeCart[product.id] = item;
      }
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int delta) {
    // Cari product dari baris grosir atau ecer
    final baseId = productId.replaceAll('_grosir', '');
    final product = _activeCart[productId]?.product ?? _activeCart[baseId]?.product;
    if (product == null) return;

    if (product.wholesalePrices.isNotEmpty) {
      final currentTotal = _getTotalQtyForProduct(baseId);
      final newTotal = currentTotal + delta;
      _applyWholesaleBreakdown(product, newTotal);
    } else {
      if (_activeCart.containsKey(productId)) {
        final item = _activeCart[productId]!;
        if (item.quantity + delta > 0) {
          item.quantity += delta;
        } else {
          _activeCart.remove(productId);
        }
      }
    }
    notifyListeners();
  }

  void setQuantity(String productId, int qty) {
    final baseId = productId.replaceAll('_grosir', '');
    final product = _activeCart[productId]?.product ?? _activeCart[baseId]?.product;
    
    if (product != null && product.wholesalePrices.isNotEmpty) {
      // Hitung total baru: ganti qty baris yang diedit, pertahankan baris lain
      final otherKey = productId.endsWith('_grosir') ? baseId : '${baseId}_grosir';
      final otherQty = _activeCart[otherKey]?.quantity ?? 0;
      final newTotal = qty + otherQty;
      _applyWholesaleBreakdown(product, newTotal);
    } else if (_activeCart.containsKey(productId)) {
      if (qty > 0) {
        _activeCart[productId]!.quantity = qty;
      } else {
        _activeCart.remove(productId);
      }
    }
    notifyListeners();
  }

  void setItemPrice(String productId, double price) {
    if (_activeCart.containsKey(productId)) {
      _activeCart[productId]!.customPrice = price;
      notifyListeners();
    }
  }

  void setItemDiscount(String productId, double discount) {
    if (_activeCart.containsKey(productId)) {
      _activeCart[productId]!.itemDiscount = discount;
      notifyListeners();
    }
  }

  void setItemNote(String productId, String? note) {
    if (_activeCart.containsKey(productId)) {
      _activeCart[productId]!.note = note;
      notifyListeners();
    }
  }

  CartItem? removeItem(String productId) {
    final item = _activeCart.remove(productId);
    notifyListeners();
    return item;
  }

  void restoreItem(String productId, CartItem item) {
    _activeCart[productId] = item;
    notifyListeners();
  }

  void setCustomer(Customer? customer) {
    _activeCustomer = customer;
    notifyListeners();
  }

  void setNote(String? note) {
    _activeNote = note;
    notifyListeners();
  }

  void setDiscount(Discount? discount) {
    _activeDiscount = discount;
    notifyListeners();
  }

  void setExtraDiscount(double amount) {
    _activeExtraDiscount = amount;
    notifyListeners();
  }

  void setFee(Fee? fee) {
    _activeFee = fee;
    notifyListeners();
  }

  void setExtraFee(double amount) {
    _activeExtraFee = amount;
    notifyListeners();
  }

  void clearCart() {
    _activeCart.clear();
    _activeCustomer = null;
    _activeNote = null;
    _activeDiscount = null;
    _activeExtraDiscount = 0;
    _activeFee = null;
    _activeExtraFee = 0;
    notifyListeners();
  }
}

