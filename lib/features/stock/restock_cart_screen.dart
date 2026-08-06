import '../../core/widgets/status_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_routes.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_supplier_picker.dart';
import 'package:provider/provider.dart';
import '../../data/providers/restock_cart_provider.dart';

import 'package:intl/intl.dart';

class RestockCartScreen extends StatefulWidget {
  const RestockCartScreen({super.key});

  @override
  State<RestockCartScreen> createState() => _RestockCartScreenState();
}

class _RestockCartScreenState extends State<RestockCartScreen> {
  RestockCartProvider get _cart => Provider.of<RestockCartProvider>(context, listen: false);
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  double get _subtotal {
    return _cart.activeCart.values.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  void _updateQuantity(String id, int delta) {
    final item = _cart.activeCart[id];
    if (item == null) return;

    setState(() {
      item.quantity += delta;
      if (item.quantity <= 0) {
        final removedItem = _cart.activeCart.remove(id);
        if (removedItem != null) {
          final oldQty = item.quantity - delta; // restore to old qty
          showStatusSnackBar(
            context,
            message: '${removedItem.product.name} dihapus',
            type: SnackbarType.success,
            onUndo: () {
              setState(() {
                removedItem.quantity = oldQty > 0 ? oldQty : 1;
                _cart.activeCart[id] = removedItem;
              });
            },
          );
        }
      }
    });

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
              if (newQty <= 0) {
                final removedItem = _cart.activeCart.remove(id);
                if (removedItem != null) {
                  final oldQty = item.quantity;
                  showStatusSnackBar(
                    context,
                    message: '${removedItem.product.name} dihapus',
                    type: SnackbarType.success,
                    onUndo: () {
                      setState(() {
                        removedItem.quantity = oldQty;
                        _cart.activeCart[id] = removedItem;
                      });
                    },
                  );
                }
                setState(() {});
              } else {
                setState(() {
                  item.quantity = newQty;
                });
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
      title = 'Ubah Modal/Unit';
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
        title: Text('Keranjang Restock', style: Theme.of(context).textTheme.titleLarge),
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
                                    Text(
                                      item.product.name,
                                      style: Theme.of(context).textTheme.titleSmall,
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
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () {
                          // Supplier picker
                          _showSupplierPicker();
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
                              const Icon(Icons.business, color: AppColors.primary, size: 20),
                              const SizedBox(width: AppDimensions.spacingSM),
                              Text(
                                _cart.activeSupplier?.name ?? 'Pilih Supplier',
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
                    label: 'Lanjut (${_currencyFormat.format(_subtotal)})',
                    isFullWidth: true,
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.restockPayment).then((_) {
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

  void _showSupplierPicker() async {
    final supplier = await AppSupplierPicker.show(context, initialSupplier: _cart.activeSupplier);
    if (supplier != null) {
      setState(() {
        _cart.setSupplier(supplier);
      });
    }
  }
}
