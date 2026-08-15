import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_dialog.dart';
import 'package:provider/provider.dart';
import '../../data/providers/product_provider.dart';
import '../../data/models/product_model.dart';
import 'package:depot_kayu_app/core/extensions/context_colors.dart';

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
  final _codeController = TextEditingController();
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
    _codeController.dispose();
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

    final int initialStock = int.tryParse(_stockController.text) ?? 0;
    final double initialBasePrice = double.tryParse(_basePriceController.text) ?? 0;

    final newProduct = Product(
      id: 'P${DateTime.now().millisecondsSinceEpoch}',
      code: _codeController.text.trim().isEmpty ? '-' : _codeController.text.trim(),
      name: _nameController.text.trim(),
      category: _categoryController.text.trim().isEmpty
          ? 'Material'
          : _categoryController.text.trim(),
      unit: _unitController.text.trim(),
      basePrice: initialBasePrice,
      sellPrice: double.tryParse(_sellPriceController.text) ?? 0,
      stock: initialStock,
      stockBatches: initialStock > 0 
          ? [StockBatch(id: DateTime.now().millisecondsSinceEpoch.toString(), quantity: initialStock, basePrice: initialBasePrice, dateAdded: DateTime.now())] 
          : [],
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
      backgroundColor: context.colorBackground,
      appBar: AppBar(
        backgroundColor: context.colorBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: context.colorPrimary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tambah Produk',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: context.colorTextPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Divider(height: 1, color: context.colorDivider),
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
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Kode Barang (Opsional)',
                      hint: 'mis. A1, KY-001',
                      controller: _codeController,
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
                        color: context.colorInputFill,
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
                              activeColor: context.colorPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Lacak Stok (Barang) — nonaktifkan untuk Jasa',
                              style: TextStyle(
                                fontSize: 13,
                                color: context.colorTextPrimary,
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
                        Text(
                          'Harga Grosir (Opsional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.colorTextPrimary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addWholesaleEntry,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tambah'),
                          style: TextButton.styleFrom(
                            foregroundColor: context.colorPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_wholesaleEntries.isEmpty)
                      Text(
                        'Belum ada harga grosir yang ditambahkan.',
                        style: TextStyle(color: context.colorTextSecondary, fontSize: 14),
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
                              color: context.colorError,
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
              decoration: BoxDecoration(
                color: context.colorBackground,
                border: Border(
                  top: BorderSide(color: context.colorDivider),
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