import 'package:flutter/material.dart';
import '../../data/models/transaction_model.dart';
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

  // --- Edit Mode State ---
  /// ID transaksi yang sedang diedit. Null jika membuat transaksi baru.
  String? editingTransactionId;
  /// Snapshot transaksi asli sebelum diedit (untuk rekonsiliasi stok & kasbon).
  Transaction? editingTransactionOriginal;

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

  /// Muat data dari transaksi yang sudah ada ke dalam keranjang untuk diedit.
  void loadTransaction(Transaction tx) {
    clearCart();
    editingTransactionId = tx.id;
    editingTransactionOriginal = tx;

    // Muat semua item ke keranjang
    for (var item in tx.items) {
      _activeCart[item.product.id] = CartItem(
        product: item.product,
        quantity: item.quantity,
        customPrice: item.customPrice,
        itemDiscount: item.itemDiscount,
        note: item.note,
        cogs: item.cogs,
      );
    }

    // Muat diskon, biaya, dan catatan
    _activeDiscount = tx.discount;
    _activeExtraDiscount = tx.extraDiscount;
    _activeFee = tx.fee;
    _activeExtraFee = tx.extraFee;

    notifyListeners();
  }

  void addItem(CartItem item) {
    if (_activeCart.containsKey(item.product.id)) {
      _activeCart[item.product.id]!.quantity += item.quantity;
    } else {
      _activeCart[item.product.id] = item;
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int delta) {
    if (_activeCart.containsKey(productId)) {
      final item = _activeCart[productId]!;
      if (item.quantity + delta > 0) {
        item.quantity += delta;
      } else {
        _activeCart.remove(productId);
      }
      notifyListeners();
    }
  }

  void setQuantity(String productId, int qty) {
    if (_activeCart.containsKey(productId)) {
      if (qty > 0) {
        _activeCart[productId]!.quantity = qty;
      } else {
        _activeCart.remove(productId);
      }
      notifyListeners();
    }
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
    // Reset edit mode
    editingTransactionId = null;
    editingTransactionOriginal = null;
    notifyListeners();
  }
}
