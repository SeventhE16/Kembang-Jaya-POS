import '../../core/widgets/status_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_routes.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_customer_picker.dart';
import 'package:provider/provider.dart';
import '../../data/providers/cart_provider.dart';
import '../../data/providers/transaction_provider.dart';
import '../../data/models/transaction_model.dart';

import 'package:intl/intl.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  CartProvider get _cart => Provider.of<CartProvider>(context, listen: false);
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isWholesaleRow(String key) => key.endsWith('_grosir');

  double get _subtotal {
    return _cart.activeCart.values.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  double get _totalModal {
    return _cart.activeCart.values.fold(0.0, (sum, item) => sum + (item.product.basePrice * item.quantity));
  }

  double get _totalDiskon {
    return _cart.activeCart.values.fold(0.0, (sum, item) => sum + (item.itemDiscount * item.quantity));
  }

  double get _totalKeuntungan {
    return _subtotal - _totalModal;
  }

  double get _margin {
    if (_totalModal == 0) return 0;
    return (_totalKeuntungan / _totalModal) * 100;
  }

  void _holdOrder() {
    if (_cart.activeCart.isEmpty) return;

    final hold = HoldOrder(
      id: 'HO-${DateTime.now().millisecondsSinceEpoch}',
      cart: Map.from(_cart.activeCart),
      date: DateTime.now(),
      note: _cart.activeCustomer?.name ?? 'Tanpa Nama',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    Provider.of<TransactionProvider>(context, listen: false).saveHoldOrder(hold);
    
    // Instead of using setState and direct setters (which don't exist), use CartProvider's clear method
    _cart.clearCart();

    showStatusSnackBar(
      context,
      message: 'Transaksi berhasil di-hold',
      type: SnackbarType.success,
    );
    Navigator.pop(context);
  }

  void _showProfitInfo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Profit',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            _buildInfoRow('Total Modal', _totalModal),
            _buildInfoRow('Total Diskon Barang', _totalDiskon),
            const Divider(height: 24),
            _buildInfoRow('Total Keuntungan', _totalKeuntungan, isBold: true, color: AppColors.primary),
            _buildInfoRowString('Margin Penjualan', '${_margin.toStringAsFixed(1)}%', isBold: true, color: AppColors.primary),
            const SizedBox(height: AppDimensions.spacingLG),
            AppButton(
              label: 'Tutup',
              isFullWidth: true,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, double amount, {bool isBold = false, Color? color}) {
    return _buildInfoRowString(label, _currencyFormat.format(amount), isBold: isBold, color: color);
  }

  Widget _buildInfoRowString(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _updateQuantity(String id, int delta) {
    final item = _cart.activeCart[id];
    if (item == null) return;

    if (delta > 0 && item.product.trackStock && item.quantity + delta > item.product.stock) {
      showStatusSnackBar(
        context,
        message: 'Stok tidak cukup',
        type: SnackbarType.error,
      );
      return;
    }

    final oldQty = item.quantity;
    _cart.updateQuantity(id, delta);
    
    if (!_cart.activeCart.containsKey(id) && oldQty + delta <= 0) {
      showStatusSnackBar(
        context,
        message: '${item.product.name} dihapus',
        type: SnackbarType.success,
        onUndo: () {
          _cart.setQuantity(id, oldQty);
          setState(() {});
        },
      );
    }
    
    setState(() {});

    if (_cart.activeCart.isEmpty) {
      Navigator.pop(context);
    }
  }

  void _editQuantityDialog(String id) {
    final item = _cart.activeCart[id];
    if (item == null) return;
    
    final controller = TextEditingController(text: item.quantity.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Kuantitas'),
        content: AppTextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          hint: 'Masukkan kuantitas',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          AppButton(
            label: 'Simpan',
            onPressed: () {
              final newQty = int.tryParse(controller.text) ?? 0;
              final oldQty = item.quantity;
              if (newQty <= 0) {
                _cart.setQuantity(id, 0); // remove item
                showStatusSnackBar(
                  context,
                  message: '${item.product.name} dihapus',
                  type: SnackbarType.success,
                  onUndo: () {
                    _cart.setQuantity(id, oldQty);
                    setState(() {});
                  },
                );
                setState(() {});
              } else {
                if (item.product.trackStock && newQty > item.product.stock) {
                  showStatusSnackBar(context, message: 'Stok tidak cukup', type: SnackbarType.error);
                  return;
                }
                _cart.setQuantity(id, newQty);
                setState(() {});
              }
              Navigator.pop(ctx);
              if (_cart.activeCart.isEmpty) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _editItemDialog(String id, String field) {
    final item = _cart.activeCart[id];
    if (item == null) return;

    final controller = TextEditingController();
    String title = '';
    TextInputType keyboard = TextInputType.text;

    if (field == 'harga') {
      title = 'Ubah Harga (Markup)';
      controller.text = item.unitPrice.toStringAsFixed(0);
      keyboard = TextInputType.number;
    } else if (field == 'diskon') {
      title = 'Diskon Per Barang';
      controller.text = item.itemDiscount.toStringAsFixed(0);
      keyboard = TextInputType.number;
    } else if (field == 'catatan') {
      title = 'Catatan Barang';
      controller.text = item.note ?? '';
      keyboard = TextInputType.text;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: AppTextField(
          controller: controller,
          keyboardType: keyboard,
          inputFormatters: keyboard == TextInputType.number ? [FilteringTextInputFormatter.digitsOnly] : null,
          hint: 'Masukkan $title',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          AppButton(
            label: 'Simpan',
            onPressed: () {
              setState(() {
                if (field == 'harga') {
                  item.customPrice = double.tryParse(controller.text);
                } else if (field == 'diskon') {
                  item.itemDiscount = double.tryParse(controller.text) ?? 0;
                } else if (field == 'catatan') {
                  item.note = controller.text.trim().isEmpty ? null : controller.text.trim();
                }
              });
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Keranjang', style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.pause, color: AppColors.primary),
            tooltip: 'Hold Order',
            onPressed: _holdOrder,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppDimensions.spacingMD),
                itemCount: _cart.activeCart.length,
                itemBuilder: (context, index) {
                  final key = _cart.activeCart.keys.elementAt(index);
                  final item = _cart.activeCart[key]!;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radius)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.spacingMD),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.product.name,
                                            style: Theme.of(context).textTheme.titleSmall,
                                          ),
                                        ),
                                        if (_isWholesaleRow(key))
                                          Container(
                                            margin: const EdgeInsets.only(left: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.success.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Grosir',
                                              style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _currencyFormat.format(item.unitPrice),
                                      style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  final removedItem = _cart.activeCart.remove(key);
                                  if (removedItem != null) {
                                    final oldQty = removedItem.quantity;
                                    showStatusSnackBar(
                                      context,
                                      message: '${removedItem.product.name} dihapus',
                                      type: SnackbarType.success,
                                      onUndo: () {
                                        setState(() {
                                          removedItem.quantity = oldQty;
                                          _cart.activeCart[key] = removedItem;
                                        });
                                      },
                                    );
                                  }
                                  setState(() {});
                                  if (_cart.activeCart.isEmpty) {
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                            ],
                          ),
                          if (item.itemDiscount > 0 || item.note != null) ...[
                            const SizedBox(height: AppDimensions.spacingSM),
                            if (item.itemDiscount > 0)
                              Text(
                                'Diskon: -${_currencyFormat.format(item.itemDiscount)}',
                                style: const TextStyle(fontSize: 13, color: AppColors.warning),
                              ),
                            if (item.note != null)
                              Text(
                                'Catatan: ${item.note}',
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                              ),
                          ],
                          const SizedBox(height: AppDimensions.spacingMD),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Action Chips
                              Row(
                                children: [
                                  _buildActionChip('Harga', () => _editItemDialog(key, 'harga')),
                                  const SizedBox(width: AppDimensions.spacingSM),
                                  _buildActionChip('Diskon', () => _editItemDialog(key, 'diskon')),
                                  const SizedBox(width: AppDimensions.spacingSM),
                                  _buildActionChip('Catatan', () => _editItemDialog(key, 'catatan')),
                                ],
                              ),
                              // Qty controls
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.inputFill,
                                  borderRadius: BorderRadius.circular(AppDimensions.radius),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 20),
                                      onPressed: () => _updateQuantity(key, -1),
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      constraints: const BoxConstraints(),
                                    ),
                                    InkWell(
                                      onTap: () => _editQuantityDialog(key),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        child: Text(
                                          '${item.quantity}',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 20),
                                      onPressed: () => _updateQuantity(key, 1),
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Bottom Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: _showProfitInfo,
                        borderRadius: BorderRadius.circular(AppDimensions.radius),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary),
                            borderRadius: BorderRadius.circular(AppDimensions.radius),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Keuntungan',
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          // Customer picker
                          _showCustomerPicker();
                        },
                        borderRadius: BorderRadius.circular(AppDimensions.radius),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary),
                            borderRadius: BorderRadius.circular(AppDimensions.radius),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline, color: AppColors.primary, size: 20),
                              const SizedBox(width: AppDimensions.spacingSM),
                              Text(
                                _cart.activeCustomer?.name ?? 'Tambah Pelanggan',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingMD),
                  AppButton(
                    label: 'Bayar (${_currencyFormat.format(_subtotal)})',
                    isFullWidth: true,
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.payment).then((_) {
                        if (mounted) setState(() {});
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.chipInactive,
          borderRadius: BorderRadius.circular(AppDimensions.radius),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }





  void _showCustomerPicker() async {
    final customer = await AppCustomerPicker.show(context, selectedCustomer: _cart.activeCustomer);
    if (customer != null) {
      setState(() {
        _cart.setCustomer(customer);
      });
    }
  }
}



