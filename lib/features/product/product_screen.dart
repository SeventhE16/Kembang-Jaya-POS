import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/status_dialog.dart';
import 'package:provider/provider.dart';
import '../../data/providers/product_provider.dart';
import '../../data/models/product_model.dart';
import '../../core/constants/app_routes.dart';
import 'add_product_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  String _sortOption = 'Nama (A-Z)';

  List<Product> _getFilteredProducts(List<Product> allProducts) {
    var list = allProducts.where((p) {
      final matchesCategory =
          _selectedCategory == 'Semua' || p.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    if (_sortOption == 'Nama (A-Z)') {
      list.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortOption == 'Nama (Z-A)') {
      list.sort((a, b) => b.name.compareTo(a.name));
    } else if (_sortOption == 'Harga Terendah') {
      list.sort((a, b) => a.sellPrice.compareTo(b.sellPrice));
    } else if (_sortOption == 'Harga Tertinggi') {
      list.sort((a, b) => b.sellPrice.compareTo(a.sellPrice));
    } else if (_sortOption == 'Kategori') {
      list.sort((a, b) => a.category.compareTo(b.category));
    }
    return list;
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Urutkan Berdasarkan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              for (String option in ['Nama (A-Z)', 'Nama (Z-A)', 'Harga Terendah', 'Harga Tertinggi', 'Kategori'])
                ListTile(
                  title: Text(option),
                  trailing: _sortOption == option ? const Icon(Icons.check, color: AppColors.primary) : null,
                  onTap: () {
                    setState(() {
                      _sortOption = option;
                    });
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        );
      },
    );
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
    List<WholesalePrice> wholesalePrices = List.from(product.wholesalePrices);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radius)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.spacingLG),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Produk',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingMD),

                AppTextField(
                  label: 'Nama Barang',
                  hint: 'Nama barang / jasa',
                  controller: nameController,
                ),
                const SizedBox(height: AppDimensions.spacingMD),

                AppTextField(
                  label: 'Kategori',
                  hint: 'mis. Kayu Balko, Material, Jasa',
                  controller: categoryController,
                ),
                const SizedBox(height: AppDimensions.spacingMD),

                // Track stock checkbox
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingMD),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(AppDimensions.radius),
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
                            borderRadius: BorderRadius.circular(AppDimensions.radius),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingSM),
                      Expanded(
                        child: Text(
                          'Lacak Stok (Barang) — nonaktifkan untuk Jasa',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingMD),

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
                    const SizedBox(width: AppDimensions.spacingMD),
                    Expanded(
                      child: AppTextField(
                        label: 'Harga Jual',
                        controller: sellPriceController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingMD),

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
                    const SizedBox(width: AppDimensions.spacingMD),
                    Expanded(
                      child: AppTextField(
                        label: 'Satuan',
                        controller: unitController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingMD),

                // Harga Grosir
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingMD),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(AppDimensions.radius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Harga Grosir (Opsional)', style: TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: AppColors.primary),
                            onPressed: () {
                              setDialogState(() {
                                wholesalePrices.add(WholesalePrice(minQty: 10, price: 0));
                              });
                            },
                          ),
                        ],
                      ),
                      ...wholesalePrices.asMap().entries.map((e) {
                        int idx = e.key;
                        WholesalePrice wp = e.value;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  label: 'Min Qty',
                                  controller: TextEditingController(text: wp.minQty.toString()),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) {
                                    wholesalePrices[idx] = WholesalePrice(minQty: int.tryParse(v) ?? 1, price: wp.price);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AppTextField(
                                  label: 'Harga',
                                  controller: TextEditingController(text: wp.price.toStringAsFixed(0)),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) {
                                    wholesalePrices[idx] = WholesalePrice(minQty: wp.minQty, price: double.tryParse(v) ?? 0);
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setDialogState(() {
                                    wholesalePrices.removeAt(idx);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLG),

                // Buttons
                AppButton(
                  label: 'Simpan',
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      Navigator.pop(ctx);
                      showStatusSnackBar(
                        context,
                        message: 'Nama barang wajib diisi',
                        type: SnackbarType.error,
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
                      wholesalePrices: wholesalePrices,
                    );
                    
                    await Provider.of<ProductProvider>(context, listen: false).updateProduct(updatedProduct);
                    
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    showStatusSnackBar(
                      context,
                      message: 'Produk diperbarui',
                      type: SnackbarType.success,
                    );
                  },
                ),
                const SizedBox(height: AppDimensions.spacingSM),
                AppButton(
                  label: 'Batal',
                  variant: AppButtonVariant.secondary,
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
            onPressed: () async {
                Navigator.pop(ctx);
                final productProvider = Provider.of<ProductProvider>(context, listen: false);
                await productProvider.deleteProduct(product.id);
              showStatusSnackBar(
                context,
                message: '${product.name} dihapus',
                type: SnackbarType.success,
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
    final productProvider = Provider.of<ProductProvider>(context);
    final products = productProvider.products;
    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.management),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          'Barang',
          style: Theme.of(context).textTheme.titleLarge,
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
                GestureDetector(
                  onTap: _showFilterDialog,
                  child: Icon(Icons.filter_list, color: AppColors.textSecondary, size: 24),
                ),
                const SizedBox(width: AppDimensions.spacingSM),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Cari Nama atau kode barang',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radius),
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
              itemCount: productProvider.categories.length,
              itemBuilder: (context, index) {
                final category = productProvider.categories[index];
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radius)),
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
            child: _getFilteredProducts(products).isEmpty
                ? AppEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Tidak ada barang',
                    subtitle: 'Belum ada barang yang sesuai filter',
                    action: AppButton(
                      label: 'Tambah Produk',
                      onPressed: _navigateToAddProduct,
                    ),
                  )
                : ListView.builder(
                    itemCount: _getFilteredProducts(products).length,
                    itemBuilder: (context, index) {
                      final product = _getFilteredProducts(products)[index];
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
            padding: const EdgeInsets.all(AppDimensions.spacingMD),
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













