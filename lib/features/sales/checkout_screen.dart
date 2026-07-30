import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/status_dialog.dart';
import '../../data/dummy/dummy_data.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/discount_model.dart';
import '../../data/models/fee_model.dart';

class CheckoutSheet extends StatefulWidget {
  final Map<String, CartItem> cart;
  final void Function(Transaction transaction) onComplete;

  const CheckoutSheet({
    super.key,
    required this.cart,
    required this.onComplete,
  });

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  final DummyData _data = DummyData();
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _extraDiscountController = TextEditingController(text: '0');
  final TextEditingController _extraFeeController = TextEditingController(text: '0');
  Discount? _selectedDiscount;
  Fee? _selectedFee;

  double get _subtotal =>
      widget.cart.values.fold(0.0, (sum, item) => sum + item.subtotal);

  double get _discountAmount {
    double amount = 0;
    if (_selectedDiscount != null) {
      amount += _selectedDiscount!.calculateDiscount(_subtotal);
    }
    final extra = double.tryParse(_extraDiscountController.text) ?? 0;
    amount += extra;
    return amount;
  }

  double get _feeAmount {
    double amount = 0;
    if (_selectedFee != null) {
      amount += _selectedFee!.value;
    }
    final extra = double.tryParse(_extraFeeController.text) ?? 0;
    amount += extra;
    return amount;
  }

  double get _total => (_subtotal - _discountAmount + _feeAmount).clamp(0, double.infinity);

  double get _estimatedProfit {
    double costTotal = widget.cart.values
        .fold(0.0, (sum, item) => sum + (item.product.basePrice * item.quantity));
    return _total - costTotal;
  }

  void _removeItem(String productId) {
    setState(() {
      widget.cart.remove(productId);
    });
    if (widget.cart.isEmpty) {
      Navigator.pop(context);
    }
  }

  void _updateQuantity(String productId, int delta) {
    final item = widget.cart[productId]!;
    if (delta > 0 && item.product.trackStock && item.quantity + delta > item.product.stock) {
      showStatusSnackBar(
        context,
        message: 'Stok ${item.product.name} habis/tidak cukup',
        isSuccess: false,
      );
      return;
    }
    setState(() {
      item.quantity += delta;
      if (item.quantity <= 0) {
        widget.cart.remove(productId);
      }
    });
    if (widget.cart.isEmpty) {
      Navigator.pop(context);
    }
  }

  void _showDiscountPicker() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pilih Diskon',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._data.discounts.map((discount) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () {
                        setState(() => _selectedDiscount = discount);
                        Navigator.pop(ctx);
                      },
                      title: Text(
                        discount.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: Text(
                        discount.displayValue,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Diskon Nominal Dadakan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _extraDiscountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(100, 48),
                    ),
                    child: const Text('Terapkan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeePicker() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pilih Biaya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_data.fees.isEmpty)
                const Center(child: Text('Belum ada data biaya.'))
              else
                ..._data.fees.map((fee) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () {
                      setState(() => _selectedFee = fee);
                      Navigator.pop(ctx);
                    },
                    title: Text(fee.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: Text(
                      'Rp ${DummyData.formatCurrency(fee.value.toInt())}',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Biaya Nominal Dadakan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _extraFeeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(minimumSize: const Size(100, 48)),
                    child: const Text('Terapkan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePayment() {
    // Validate stock first
    for (final item in widget.cart.values) {
      if (item.product.trackStock && item.quantity > item.product.stock) {
        showStatusSnackBar(
          context,
          message: 'Stok ${item.product.name} tidak cukup (Sisa: ${item.product.stock})',
          isSuccess: false,
        );
        return; // Abort checkout
      }
    }

    // Deduct stock for physical products
    for (final item in widget.cart.values) {
      if (item.product.trackStock) {
        item.product.stock = (item.product.stock - item.quantity).clamp(0, item.product.stock);
      }
    }

    final transaction = Transaction(
      id: _data.generateTransactionId(),
      customerName: _customerController.text.trim().isEmpty
          ? null
          : _customerController.text.trim(),
      cashierName: 'Andi Pratama',
      items: widget.cart.values.toList(),
      discount: _selectedDiscount,
      extraDiscount: double.tryParse(_extraDiscountController.text) ?? 0,
      fee: _selectedFee,
      extraFee: double.tryParse(_extraFeeController.text) ?? 0,
      subtotal: _subtotal,
      total: _total,
      date: DateTime.now(),
    );
    _data.transactions.add(transaction);
    widget.onComplete(transaction);
  }

  @override
  void dispose() {
    _customerController.dispose();
    _extraDiscountController.dispose();
    _extraFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Checkout',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer name
                      const Text(
                        'Nama Pelanggan (opsional)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _customerController,
                        decoration: InputDecoration(
                          hintText: 'mis. Pak Budi',
                          filled: true,
                          fillColor: AppColors.inputFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),

                      // Cart items
                      ...widget.cart.values.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Rp ${DummyData.formatCurrency(item.product.sellPrice.toInt())}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Qty controls
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.divider),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _qtyButton(Icons.remove, () =>
                                          _updateQuantity(item.product.id, -1)),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      _qtyButton(Icons.add, () =>
                                          _updateQuantity(item.product.id, 1)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _removeItem(item.product.id),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                          )),

                      const SizedBox(height: 8),

                      // Discount section
                      GestureDetector(
                        onTap: _showDiscountPicker,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary,
                              style: BorderStyle.solid,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.percent,
                                  color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _selectedDiscount != null
                                    ? '${_selectedDiscount!.name} (${_selectedDiscount!.displayValue})'
                                    : 'Tambah Diskon',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.chevron_right,
                                  color: AppColors.primary, size: 20),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Fee section
                      GestureDetector(
                        onTap: _showFeePicker,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.shade600,
                              style: BorderStyle.solid,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.payments_outlined, color: Colors.blue.shade600, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _selectedFee != null
                                    ? '${_selectedFee!.name} (Rp ${DummyData.formatCurrency(_selectedFee!.value.toInt())})'
                                    : 'Biaya',
                                style: TextStyle(
                                  color: Colors.blue.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.chevron_right, color: Colors.blue.shade600, size: 20),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Totals
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal',
                              style: TextStyle(color: AppColors.textSecondary)),
                          Text(
                              'Rp ${DummyData.formatCurrency(_subtotal.toInt())}'),
                        ],
                      ),
                      if (_discountAmount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Diskon',
                                style: TextStyle(color: AppColors.textSecondary)),
                            Text(
                              '-Rp ${DummyData.formatCurrency(_discountAmount.toInt())}',
                              style: const TextStyle(color: AppColors.success),
                            ),
                          ],
                        ),
                      ],
                      if (_feeAmount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Biaya', style: TextStyle(color: AppColors.textSecondary)),
                            Text(
                              '+Rp ${DummyData.formatCurrency(_feeAmount.toInt())}',
                              style: TextStyle(color: Colors.blue.shade600),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      const Divider(),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Rp ${DummyData.formatCurrency(_total.toInt())}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Estimasi Profit',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Rp ${DummyData.formatCurrency(_estimatedProfit.toInt())}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Pay button
                      AppButton(
                        label: 'Selesaikan & Bayar',
                        onPressed: _handlePayment,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}
