import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/status_dialog.dart';
import '../../data/dummy/dummy_data.dart';
import '../../data/models/product_model.dart';
import 'add_product_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final DummyData _data = DummyData();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  List<Product> get _filteredProducts {
    return _data.products.where((p) {
      final matchesCategory =
          _selectedCategory == 'Semua' || p.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> _navigateToAddProduct() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
    if (result == true) {
      setState(() {});
    }
  }

  void _showEditProductDialog(Product product) {
    final nameController = TextEditingController(text: product.name);
    final categoryController = TextEditingController(text: product.category);
    final basePriceController = TextEditingController(text: product.basePrice.toInt().toString());
    final sellPriceController = TextEditingController(text: product.sellPrice.toInt().toString());
    final stockController = TextEditingController(text: product.stock.toString());
    final unitController = TextEditingController(text: product.unit);
    bool trackStock = product.trackStock;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Produk',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                AppTextField(
                  label: 'Nama Barang',
                  hint: 'Nama barang / jasa',
                  controller: nameController,
                ),
                const SizedBox(height: 12),

                AppTextField(
                  label: 'Kategori',
                  hint: 'mis. Kayu Balko, Material, Jasa',
                  controller: categoryController,
                ),
                const SizedBox(height: 12),

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
                          value: trackStock,
                          onChanged: (v) =>
                              setDialogState(() => trackStock = v ?? true),
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Lacak Stok (Barang) — nonaktifkan untuk Jasa',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Price row
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Harga Dasar (Modal)',
                        controller: basePriceController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Harga Jual',
                        controller: sellPriceController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stock & unit row
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Stok',
                        controller: stockController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Satuan',
                        controller: unitController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Buttons
                AppButton(
                  label: 'Simpan',
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) {
                      Navigator.pop(ctx);
                      showStatusSnackBar(
                        context,
                        message: 'Nama barang wajib diisi',
                        isSuccess: false,
                      );
                      return;
                    }

                    final updatedProduct = product.copyWith(
                      name: nameController.text.trim(),
                      category: categoryController.text.trim().isEmpty
                          ? 'Material'
                          : categoryController.text.trim(),
                      unit: unitController.text.trim(),
                      basePrice:
                          double.tryParse(basePriceController.text) ?? 0,
                      sellPrice:
                          double.tryParse(sellPriceController.text) ?? 0,
                      stock: int.tryParse(stockController.text) ?? 0,
                      trackStock: trackStock,
                    );
                    setState(() {
                      final index = _data.products.indexWhere((p) => p.id == product.id);
                      if (index != -1) {
                        _data.products[index] = updatedProduct;
                      }
                    });
                    Navigator.pop(ctx);
                    showStatusSnackBar(
                      context,
                      message: 'Produk diperbarui',
                      isSuccess: true,
                    );
                  },
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Batal',
                  isPrimary: false,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus ${product.name}?'),
        content: const Text('Data yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _data.products.removeWhere((p) => p.id == product.id);
              });
              showStatusSnackBar(
                context,
                message: '${product.name} dihapus',
                isSuccess: true,
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/management'),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text(
          'Barang',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
        children: [
          const Divider(height: 1),
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Icon(Icons.filter_list, color: AppColors.textSecondary, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Cari Nama atau kode barang',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.inputFill,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Category chips
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _data.categories.length,
              itemBuilder: (context, index) {
                final category = _data.categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = category),
                    backgroundColor: AppColors.chipInactive,
                    selectedColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide.none,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                );
              },
            ),
          ),

          // Product list
          Expanded(
            child: _filteredProducts.isEmpty
                ? AppEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Tidak ada barang',
                    subtitle: 'Belum ada barang yang sesuai filter',
                    actionLabel: 'Tambah Barang',
                    onAction: _navigateToAddProduct,
                  )
                : ListView.builder(
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return ProductCard(
                        product: product,
                        showEditDelete: true,
                        onEdit: () => _showEditProductDialog(product),
                        onDelete: () => _deleteProduct(product),
                      );
                    },
                  ),
          ),

          // Add button
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppButton(
              label: 'Tambah Barang',
              icon: Icons.add,
              onPressed: _navigateToAddProduct,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
