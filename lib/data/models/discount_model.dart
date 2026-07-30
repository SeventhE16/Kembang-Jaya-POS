enum DiscountType { percent, nominal }

class Discount {
  final String id;
  final String name;
  final DiscountType type;
  final double value;

  Discount({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
  });

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
