import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_dialog.dart';
import '../../data/dummy/dummy_data.dart';
import '../../data/models/product_model.dart';

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
  
  final DummyData _data = DummyData();

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _basePriceController.dispose();
    _sellPriceController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _handleAdd() {
    if (_nameController.text.trim().isEmpty) {
      showStatusSnackBar(
        context,
        message: 'Nama barang wajib diisi',
        isSuccess: false,
      );
      return;
    }

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
      trackStock: _trackStock,
    );

    _data.products.add(newProduct);
    
    showStatusSnackBar(
      context,
      message: 'Produk ditambahkan',
      isSuccess: true,
    );
    Navigator.pop(context, true);
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
                    isPrimary: false,
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
