import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_dialog.dart';
import 'package:provider/provider.dart';
import '../../data/providers/product_provider.dart';
import '../../data/models/product_model.dart';

class WholesalePriceEntry {
  final TextEditingController qtyController;
  final TextEditingController priceController;

  WholesalePriceEntry({
    required this.qtyController,
    required this.priceController,
  });

  void dispose() {
    qtyController.dispose();
    priceController.dispose();
  }
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _basePriceController = TextEditingController(text: '0');
  final _sellPriceController = TextEditingController(text: '0');
  final _stockController = TextEditingController(text: '0');
  final _unitController = TextEditingController(text: 'pcs');
  bool _trackStock = true;
  
  final List<WholesalePriceEntry> _wholesaleEntries = [];

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _basePriceController.dispose();
    _sellPriceController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    for (var entry in _wholesaleEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  void _addWholesaleEntry() {
    setState(() {
      _wholesaleEntries.add(WholesalePriceEntry(
        qtyController: TextEditingController(text: ''),
        priceController: TextEditingController(text: ''),
      ));
    });
  }

  void _removeWholesaleEntry(int index) {
    setState(() {
      _wholesaleEntries[index].dispose();
      _wholesaleEntries.removeAt(index);
    });
  }

  void _handleAdd() async {
    if (_nameController.text.trim().isEmpty) {
      showStatusSnackBar(
        context,
        message: 'Nama barang wajib diisi',
        type: SnackbarType.error,
      );
      return;
    }

    final wholesalePrices = _wholesaleEntries
        .map((e) => WholesalePrice(
              minQty: int.tryParse(e.qtyController.text) ?? 0,
              price: double.tryParse(e.priceController.text) ?? 0,
            ))
        .where((e) => e.minQty > 0 && e.price > 0)
        .toList();

    final newProduct = Product(
      id: 'P${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      category: _categoryController.text.trim().isEmpty
          ? 'Material'
          : _categoryController.text.trim(),
      unit: _unitController.text.trim(),
      basePrice: double.tryParse(_basePriceController.text) ?? 0,
      sellPrice: double.tryParse(_sellPriceController.text) ?? 0,
      stock: int.tryParse(_stockController.text) ?? 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      trackStock: _trackStock,
      wholesalePrices: wholesalePrices,
    );

    await Provider.of<ProductProvider>(context, listen: false).addProduct(newProduct);
    
    if (mounted) {
      showStatusSnackBar(
        context,
        message: 'Produk ditambahkan',
        type: SnackbarType.success,
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.primary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tambah Produk',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label: 'Nama Barang',
                      hint: 'Nama barang / jasa',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Kategori',
                      hint: 'mis. Kayu Balko, Material, Jasa',
                      controller: _categoryController,
                    ),
                    const SizedBox(height: 16),
                    
                    // Track stock checkbox
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _trackStock,
                              onChanged: (v) {
                                setState(() {
                                  _trackStock = v ?? true;
                                });
                              },
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Lacak Stok (Barang) — nonaktifkan untuk Jasa',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Price row
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Harga Dasar (Modal)',
                            controller: _basePriceController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            label: 'Harga Jual',
                            controller: _sellPriceController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Stock & unit row
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Stok',
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            label: 'Satuan',
                            controller: _unitController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Wholesale prices section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Harga Grosir (Opsional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addWholesaleEntry,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tambah'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_wholesaleEntries.isEmpty)
                      const Text(
                        'Belum ada harga grosir yang ditambahkan.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ...List.generate(_wholesaleEntries.length, (index) {
                      final entry = _wholesaleEntries[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              flex: 2,
                              child: AppTextField(
                                label: 'Min Qty',
                                controller: entry.qtyController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: AppTextField(
                                label: 'Harga Grosir',
                                controller: entry.priceController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _removeWholesaleEntry(index),
                              icon: const Icon(Icons.delete_outline),
                              color: AppColors.error,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            // Bottom buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(color: AppColors.divider),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    label: 'Tambah',
                    onPressed: _handleAdd,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Batal',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
