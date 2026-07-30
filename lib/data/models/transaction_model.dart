import 'product_model.dart';
import 'discount_model.dart';
import 'fee_model.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.sellPrice * quantity;
}

class Transaction {
  final String id;
  final String? customerName;
  final String cashierName;
  final List<CartItem> items;
  final Discount? discount;
  final double extraDiscount;
  final Fee? fee;
  final double extraFee;
  final double subtotal;
  final double total;
  final DateTime date;

  Transaction({
    required this.id,
    this.customerName,
    required this.cashierName,
    required this.items,
    this.discount,
    this.extraDiscount = 0,
    this.fee,
    this.extraFee = 0,
    required this.subtotal,
    required this.total,
    required this.date,
  });

  int get totalQty => items.fold(0, (sum, item) => sum + item.quantity);
}

class StockEntry {
  final String id;
  final Product product;
  final int quantity;
  final double totalCost;
  final String? note;
  final DateTime date;

  StockEntry({
    required this.id,
    required this.product,
    required this.quantity,
    required this.totalCost,
    this.note,
    required this.date,
  });

  double get costPerUnit => quantity > 0 ? totalCost / quantity : 0;
}
