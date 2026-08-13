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

  bool _hasMixedPricing(CartItem item) {
    if (item.customPrice != null) return false;
    if (item.product.wholesalePrices.isEmpty) return false;
    final sortedTiers = List<WholesalePrice>.from(item.product.wholesalePrices)
      ..sort((a, b) => b.minQty.compareTo(a.minQty));
    final tier = sortedTiers.first;
    return item.quantity >= tier.minQty && item.quantity % tier.minQty != 0;
  }

  WholesalePrice? _getApplicableTier(CartItem item) {
    if (item.product.wholesalePrices.isEmpty) return null;
    final sortedTiers = List<WholesalePrice>.from(item.product.wholesalePrices)
      ..sort((a, b) => b.minQty.compareTo(a.minQty));
    for (var tier in sortedTiers) {
      if (item.quantity >= tier.minQty) return tier;
    }
    return null;
  }

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

    // Dialog khusus Ubah Harga — modern bottom sheet dengan live profit
    if (field == 'harga') {
      _showEditHargaSheet(id, item);
      return;
    }

    final controller = TextEditingController();
    String title = '';
    TextInputType keyboard = TextInputType.text;

    if (field == 'diskon') {
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
                if (field == 'diskon') {
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

  void _showEditHargaSheet(String id, CartItem item) {
    final controller = TextEditingController(text: item.unitPrice.toStringAsFixed(0));
    final basePrice = item.product.basePrice;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final currentPrice = double.tryParse(controller.text) ?? item.unitPrice;
          final profit = currentPrice - basePrice;
          final profitPositive = profit >= 0;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title + product name
                  Text(
                    'Ubah Harga',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.product.name.replaceAll(RegExp(r'\s*Grade.*', caseSensitive: false), ''),
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  // Input harga
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    autofocus: true,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radius),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radius),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 12),
                  // Live profit card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: profitPositive
                          ? AppColors.success.withValues(alpha: 0.08)
                          : AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppDimensions.radius),
                      border: Border.all(
                        color: profitPositive
                            ? AppColors.success.withValues(alpha: 0.3)
                            : AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              profitPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                              size: 18,
                              color: profitPositive ? AppColors.success : AppColors.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Keuntungan per barang',
                              style: TextStyle(
                                fontSize: 13,
                                color: profitPositive ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${profitPositive ? '+' : ''}${_currencyFormat.format(profit)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: profitPositive ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Hint harga modal
                  Text(
                    'Harga modal: ${_currencyFormat.format(basePrice)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  // Tombol aksi
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.textSecondary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radius)),
                          ),
                          child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              item.customPrice = double.tryParse(controller.text);
                            });
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radius)),
                            elevation: 0,
                          ),
                          child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Tampilan harga: jika mixed grosir+ecer, tampilkan info breakdown
                                    if (_hasMixedPricing(item)) ...[  
                                      Builder(builder: (context) {
                                        final tier = _getApplicableTier(item)!;
                                        final wholesaleQty = (item.quantity ~/ tier.minQty) * tier.minQty;
                                        final remainderQty = item.quantity % tier.minQty;
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${_currencyFormat.format(tier.price)} × $wholesaleQty (grosir)',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            ),
                                            Text(
                                              '${_currencyFormat.format(item.product.sellPrice)} × $remainderQty (ecer)',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        );
                                      }),
                                    ] else ...[  
                                      Text(
                                        _currencyFormat.format(item.unitPrice),
                                        style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w500),
                                      ),
                                    ],
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
                          const SizedBox(height: 6),
                          // Total per item
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Total: ${_currencyFormat.format(item.subtotal)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
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



