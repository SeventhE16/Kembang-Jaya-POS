class Product {
  final String id;
  final String name;
  final String category;
  final String unit;
  final double basePrice;
  final double sellPrice;
  int stock;
  final bool trackStock;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.basePrice,
    required this.sellPrice,
    required this.stock,
    this.trackStock = true,
  });

  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? unit,
    double? basePrice,
    double? sellPrice,
    int? stock,
    bool? trackStock,
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
    );
  }
}
