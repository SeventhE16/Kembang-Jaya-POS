import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_model.dart';
import 'discount_model.dart';
import 'fee_model.dart';

class CartItem {
  final Product product;
  int quantity;
  double? customPrice;
  double itemDiscount;
  String? note;
  double? cogs; // Exact Cost of Goods Sold from FIFO calculation

  CartItem({
    required this.product,
    this.quantity = 1,
    this.customPrice,
    this.itemDiscount = 0,
    this.note,
    this.cogs,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product'] ?? {}, json['product']['id'] ?? ''),
      quantity: json['quantity'] ?? 1,
      customPrice: json['customPrice'] != null ? (json['customPrice'] as num).toDouble() : null,
      itemDiscount: (json['itemDiscount'] ?? 0).toDouble(),
      note: json['note'],
      cogs: json['cogs'] != null ? (json['cogs'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson()..['id'] = product.id,
      'quantity': quantity,
      'customPrice': customPrice,
      'itemDiscount': itemDiscount,
      'note': note,
      'cogs': cogs,
    };
  }

  double get unitPrice {
    if (customPrice != null) return customPrice!;
    
    // Sort wholesale prices by minQty descending
    if (product.wholesalePrices.isNotEmpty) {
      final sortedTiers = List<WholesalePrice>.from(product.wholesalePrices)
        ..sort((a, b) => b.minQty.compareTo(a.minQty));
      
      for (var tier in sortedTiers) {
        if (quantity >= tier.minQty) {
          return tier.price;
        }
      }
    }
    return product.sellPrice;
  }
  double get subtotal {
    if (customPrice != null) return (customPrice! - itemDiscount) * quantity;

    if (product.wholesalePrices.isNotEmpty) {
      final sortedTiers = List<WholesalePrice>.from(product.wholesalePrices)
        ..sort((a, b) => b.minQty.compareTo(a.minQty));
      final tier = sortedTiers.first;

      if (quantity >= tier.minQty) {
        final wholesaleUnits = (quantity ~/ tier.minQty) * tier.minQty;
        final remainderUnits = quantity % tier.minQty;
        double total = wholesaleUnits * (tier.price - itemDiscount);
        if (remainderUnits > 0) {
          total += remainderUnits * (product.sellPrice - itemDiscount);
        }
        return total;
      }
    }

    return (product.sellPrice - itemDiscount) * quantity;
  }
}

class HoldOrder {
  final String id;
  final Map<String, CartItem> cart;
  final DateTime date;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;

  HoldOrder({
    required this.id,
    required this.cart,
    required this.date,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  factory HoldOrder.fromJson(Map<String, dynamic> json, String id) {
    final Map<String, dynamic> cartData = json['cart'] ?? {};
    final cart = cartData.map((key, value) => MapEntry(key, CartItem.fromJson(value)));
    
    return HoldOrder(
      id: id,
      cart: cart,
      date: (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: json['note'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cart': cart.map((key, value) => MapEntry(key, value.toJson())),
      'date': Timestamp.fromDate(date),
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }
}

class InstallmentPayment {
  final String id;
  final String? transactionId;
  final double amount;
  final DateTime date;
  final String cashierName;
  final String? note;

  InstallmentPayment({
    required this.id,
    this.transactionId,
    required this.amount,
    required this.date,
    required this.cashierName,
    this.note,
  });

  factory InstallmentPayment.fromJson(Map<String, dynamic> json, String docId) {
    return InstallmentPayment(
      id: docId,
      transactionId: json['transactionId'],
      amount: (json['amount'] ?? 0).toDouble(),
      date: (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cashierName: json['cashierName'] ?? '',
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'cashierName': cashierName,
      'note': note,
    };
  }
}

class Transaction {
  final String id;
  final String? invoiceNumber;
  final String type; // 'sale' or 'purchase'
  final String? customerName;
  final String? supplierName;
  final String cashierName;
  final List<CartItem> items;
  final Discount? discount;
  final double extraDiscount;
  final Fee? fee;
  final double extraFee;
  final double subtotal;
  final double total;
  final String paymentMethod; // Tunai, Transfer, Kasbon
  double payAmount;
  double debtAmount;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final List<InstallmentPayment> installments;
  final String? strukUrl;

  Transaction({
    required this.id,
    this.invoiceNumber,
    this.type = 'sale',
    this.customerName,
    this.supplierName,
    required this.cashierName,
    required this.items,
    this.discount,
    this.extraDiscount = 0,
    this.fee,
    this.extraFee = 0,
    required this.subtotal,
    required this.total,
    required this.paymentMethod,
    required this.payAmount,
    this.debtAmount = 0,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.installments = const [],
    this.strukUrl,
  });

  factory Transaction.fromJson(Map<String, dynamic> json, String id) {
    return Transaction(
      id: id,
      invoiceNumber: json['invoiceNumber'],
      type: json['type'] ?? 'sale',
      customerName: json['customerName'],
      supplierName: json['supplierName'],
      cashierName: json['cashierName'] ?? '',
      items: (json['items'] as List<dynamic>?)?.map((e) => CartItem.fromJson(e)).toList() ?? [],
      discount: json['discount'] != null ? Discount.fromJson(json['discount'], json['discount']['id'] ?? '') : null,
      extraDiscount: (json['extraDiscount'] ?? 0).toDouble(),
      fee: json['fee'] != null ? Fee.fromJson(json['fee'], json['fee']['id'] ?? '') : null,
      extraFee: (json['extraFee'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? 'Tunai',
      payAmount: (json['payAmount'] ?? 0).toDouble(),
      debtAmount: (json['debtAmount'] ?? 0).toDouble(),
      date: (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      installments: [], // Di-fetch terpisah dari sub-collection
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoiceNumber': invoiceNumber,
      'type': type,
      'customerName': customerName,
      'supplierName': supplierName,
      'cashierName': cashierName,
      'items': items.map((e) => e.toJson()).toList(),
      'strukUrl': strukUrl,
      'installments': installments.map((e) => e.toJson()).toList(),
      'discount': discount != null ? (discount!.toJson()..['id'] = discount!.id) : null,
      'extraDiscount': extraDiscount,
      'fee': fee != null ? (fee!.toJson()..['id'] = fee!.id) : null,
      'extraFee': extraFee,
      'subtotal': subtotal,
      'total': total,
      'paymentMethod': paymentMethod,
      'payAmount': payAmount,
      'debtAmount': debtAmount,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  Transaction copyWith({
    String? id,
    String? invoiceNumber,
    String? type,
    String? customerName,
    String? supplierName,
    String? cashierName,
    List<CartItem>? items,
    Discount? discount,
    double? extraDiscount,
    Fee? fee,
    double? extraFee,
    double? subtotal,
    double? total,
    String? paymentMethod,
    double? payAmount,
    double? debtAmount,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    List<InstallmentPayment>? installments,
    String? strukUrl,
  }) {
    return Transaction(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      type: type ?? this.type,
      customerName: customerName ?? this.customerName,
      supplierName: supplierName ?? this.supplierName,
      cashierName: cashierName ?? this.cashierName,
      items: items ?? this.items,
      discount: discount ?? this.discount,
      extraDiscount: extraDiscount ?? this.extraDiscount,
      fee: fee ?? this.fee,
      extraFee: extraFee ?? this.extraFee,
      subtotal: subtotal ?? this.subtotal,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      payAmount: payAmount ?? this.payAmount,
      debtAmount: debtAmount ?? this.debtAmount,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      installments: installments ?? this.installments,
      strukUrl: strukUrl ?? this.strukUrl,
    );
  }

  int get totalQty => items.fold(0, (sum, item) => sum + item.quantity);
}

class StockEntry {
  final String id;
  final Product product;
  final int quantity;
  final double totalCost;
  final String? note;
  final String? supplierName;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;

  StockEntry({
    required this.id,
    required this.product,
    required this.quantity,
    required this.totalCost,
    this.note,
    this.supplierName,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  factory StockEntry.fromJson(Map<String, dynamic> json, String id) {
    return StockEntry(
      id: id,
      product: Product.fromJson(json['product'] ?? {}, json['product']['id'] ?? ''),
      quantity: json['quantity'] ?? 0,
      totalCost: (json['totalCost'] ?? 0).toDouble(),
      note: json['note'],
      supplierName: json['supplierName'],
      date: (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson()..['id'] = product.id,
      'quantity': quantity,
      'totalCost': totalCost,
      'note': note,
      'supplierName': supplierName,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  double get costPerUnit => quantity > 0 ? totalCost / quantity : 0;
}

class StockOpnameItem {
  final String productId;
  final String productName;
  final int oldStock;
  final int newStock;

  StockOpnameItem({
    required this.productId,
    required this.productName,
    required this.oldStock,
    required this.newStock,
  });

  factory StockOpnameItem.fromJson(Map<String, dynamic> json) {
    return StockOpnameItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      oldStock: json['oldStock'] ?? 0,
      newStock: json['newStock'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'oldStock': oldStock,
      'newStock': newStock,
    };
  }
}
class StockOpnameEntry {
  final String id;
  final DateTime date;
  final String cashierName;
  final int totalItemsChanged;
  final List<StockOpnameItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;

  StockOpnameEntry({
    required this.id, 
    required this.date, 
    required this.cashierName, 
    required this.totalItemsChanged,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  factory StockOpnameEntry.fromJson(Map<String, dynamic> json, String id) {
    return StockOpnameEntry(
      id: id,
      date: (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cashierName: json['cashierName'] ?? '',
      totalItemsChanged: json['totalItemsChanged'] ?? 0,
      items: (json['items'] as List<dynamic>?)?.map((e) => StockOpnameItem.fromJson(e)).toList() ?? [],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': Timestamp.fromDate(date),
      'cashierName': cashierName,
      'totalItemsChanged': totalItemsChanged,
      'items': items.map((e) => e.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }
}
