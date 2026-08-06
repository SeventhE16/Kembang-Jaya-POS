import 'package:cloud_firestore/cloud_firestore.dart';

enum DiscountType { percent, nominal }

class Discount {
  final String id;
  final String name;
  final DiscountType type;
  final double value;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;

  Discount({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  factory Discount.fromJson(Map<String, dynamic> json, String id) {
    return Discount(
      id: id,
      name: json['name'] ?? '',
      type: DiscountType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DiscountType.nominal,
      ),
      value: (json['value'] ?? 0).toDouble(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.name,
      'value': value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  String get displayValue {
    if (type == DiscountType.percent) {
      return '${value.toInt()}%';
    }
    return 'Rp ${_formatNumber(value.toInt())}';
  }

  double calculateDiscount(double subtotal) {
    if (type == DiscountType.percent) {
      return subtotal * (value / 100);
    }
    return value;
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }
}
