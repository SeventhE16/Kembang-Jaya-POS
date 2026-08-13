import 'package:cloud_firestore/cloud_firestore.dart';

class WholesalePrice {
  final int minQty;
  final double price;

  WholesalePrice({required this.minQty, required this.price});

  factory WholesalePrice.fromJson(Map<String, dynamic> json) {
    return WholesalePrice(
      minQty: json['minQty'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minQty': minQty,
      'price': price,
    };
  }
}

class StockBatch {
  final String id;
  int quantity;
  double basePrice;
  final DateTime dateAdded;

  StockBatch({
    required this.id,
    required this.quantity,
    required this.basePrice,
    required this.dateAdded,
  });

  factory StockBatch.fromJson(Map<String, dynamic> json) {
    return StockBatch(
      id: json['id'] ?? '',
      quantity: json['quantity'] ?? 0,
      basePrice: (json['basePrice'] ?? 0).toDouble(),
      dateAdded: (json['dateAdded'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quantity': quantity,
      'basePrice': basePrice,
      'dateAdded': Timestamp.fromDate(dateAdded),
    };
  }
}

class Product {
  final String id;
  final String name;
  final String category;
  final String unit;
  double basePrice;
  double sellPrice;
  int stock;
  final bool trackStock;
  final List<WholesalePrice> wholesalePrices;
  List<StockBatch> stockBatches;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.basePrice,
    required this.sellPrice,
    required this.stock,
    this.trackStock = true,
    this.wholesalePrices = const [],
    this.stockBatches = const [],
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  factory Product.fromJson(Map<String, dynamic> json, String id) {
    return Product(
      id: id,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      unit: json['unit'] ?? '',
      basePrice: (json['basePrice'] ?? 0).toDouble(),
      sellPrice: (json['sellPrice'] ?? 0).toDouble(),
      stock: json['stock'] ?? 0,
      trackStock: json['trackStock'] ?? true,
      wholesalePrices: (json['wholesalePrices'] as List<dynamic>?)
              ?.map((e) => WholesalePrice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      stockBatches: (json['stockBatches'] as List<dynamic>?)
              ?.map((e) => StockBatch.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'unit': unit,
      'basePrice': basePrice,
      'sellPrice': sellPrice,
      'stock': stock,
      'trackStock': trackStock,
      'wholesalePrices': wholesalePrices.map((e) => e.toJson()).toList(),
      'stockBatches': stockBatches.map((e) => e.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? unit,
    double? basePrice,
    double? sellPrice,
    int? stock,
    bool? trackStock,
    List<WholesalePrice>? wholesalePrices,
    List<StockBatch>? stockBatches,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      basePrice: basePrice ?? this.basePrice,
      sellPrice: sellPrice ?? this.sellPrice,
      stock: stock ?? this.stock,
      trackStock: trackStock ?? this.trackStock,
      wholesalePrices: wholesalePrices ?? this.wholesalePrices,
      stockBatches: stockBatches ?? this.stockBatches,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
