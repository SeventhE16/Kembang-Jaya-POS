import '../models/product_model.dart';
import '../models/discount_model.dart';
import '../models/transaction_model.dart';
import 'package:flutter/foundation.dart';
import '../models/fee_model.dart';

class DummyData {
  // Singleton pattern for runtime state
  static final DummyData _instance = DummyData._internal();
  factory DummyData() => _instance;
  DummyData._internal();

  // Current User Mock State
  final ValueNotifier<Map<String, String>> currentUser = ValueNotifier({
    'name': 'Andi Pratama',
    'email': 'andi@kembangjaya.id',
  });

  // Categories
  final List<String> categories = [
    'Semua',
    'Kayu Balok',
    'Triplek',
    'Material',
    'Lainnya',
  ];

  // Products
  final List<Product> products = [
    Product(
      id: 'P001',
      name: 'Kayu Meranti 4×6',
      category: 'Kayu Balok',
      unit: 'batang',
      basePrice: 45000,
      sellPrice: 62000,
      stock: 120,
    ),
    Product(
      id: 'P002',
      name: 'Triplek 9mm',
      category: 'Triplek',
      unit: 'lembar',
      basePrice: 95000,
      sellPrice: 128000,
      stock: 40,
    ),
    Product(
      id: 'P003',
      name: 'Paku 5cm',
      category: 'Material',
      unit: 'kg',
      basePrice: 18000,
      sellPrice: 25000,
      stock: 0,
    ),
    Product(
      id: 'P004',
      name: 'Kayu Jati Belanda',
      category: 'Kayu Balok',
      unit: 'batang',
      basePrice: 75000,
      sellPrice: 98000,
      stock: 60,
    ),
    Product(
      id: 'P005',
      name: 'Lem Kayu Fox 600gr',
      category: 'Material',
      unit: 'pcs',
      basePrice: 28000,
      sellPrice: 38000,
      stock: 25,
    ),
    Product(
      id: 'P008',
      name: 'Engsel Pintu Set',
      category: 'Material',
      unit: 'pcs',
      basePrice: 22000,
      sellPrice: 35000,
      stock: 80,
    ),
  ];

  // Discounts
  final List<Discount> discounts = [
    Discount(
      id: 'D001',
      name: 'Diskon Tukang',
      type: DiscountType.percent,
      value: 10,
    ),
    Discount(
      id: 'D002',
      name: 'Diskon Grosir',
      type: DiscountType.percent,
      value: 5,
    ),
    Discount(
      id: 'D003',
      name: 'Potongan Member',
      type: DiscountType.nominal,
      value: 10000,
    ),
  ];

  // Fees
  final List<Fee> fees = [
    Fee(
      id: 'F001',
      name: 'Biaya Antar',
      value: 50000,
    ),
    Fee(
      id: 'F002',
      name: 'Biaya Potong',
      value: 15000,
    ),
  ];

  // Stock entries
  late final List<StockEntry> stockEntries = [
    StockEntry(
      id: 'SE001',
      product: products[0],
      quantity: 100,
      totalCost: 4500000,
      note: 'Restock supplier A',
      date: DateTime(2026, 6, 13),
    ),
    StockEntry(
      id: 'SE002',
      product: products[1],
      quantity: 30,
      totalCost: 2850000,
      date: DateTime(2026, 6, 5),
    ),
    StockEntry(
      id: 'SE003',
      product: products[7],
      quantity: 50,
      totalCost: 1100000,
      date: DateTime(2026, 5, 1),
    ),
  ];

  // Transaction history
  final List<Transaction> transactions = [];

  // Transaction counter
  int _transactionCount = 5;

  String generateTransactionId() {
    _transactionCount++;
    return 'TRX-${_transactionCount.toString().padLeft(5, '0')}';
  }

  // Helper: format number
  static String formatCurrency(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }
}
