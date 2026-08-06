import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_routes.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/status_dialog.dart';
import 'package:provider/provider.dart';
import '../../data/providers/product_provider.dart';
import '../../data/providers/restock_cart_provider.dart';
import '../../data/models/product_model.dart';
import '../../data/models/transaction_model.dart';

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  List<Product> _getFilteredProducts(List<Product> allProducts) {
    return allProducts.where((p) {
      final matchesCategory =
          _selectedCategory == 'Semua' || p.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _addToCart(Product product, RestockCartProvider cartProvider) {
    setState(() {
      cartProvider.addItem(CartItem(product: product, quantity: 1));
    });
  }

  void _showCheckout(RestockCartProvider cartProvider) {
    if (cartProvider.activeCart.isEmpty) {
      showStatusSnackBar(
        context,
        message: 'Keranjang masih kosong',
        type: SnackbarType.error,
      );
      return;
    }

    Navigator.pushNamed(context, AppRoutes.restockCart).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<RestockCartProvider>(context);
    final products = productProvider.products;
    final totalCartItems = cartProvider.activeCart.values.fold(0, (sum, item) => sum + item.quantity);
    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.stock),
      appBar: AppBar(
        title: Text(
          'Catat Pembelian',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
          children: [
            // Divider line
            const Divider(height: 1),

            // Search bar + action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(AppDimensions.spacingMD, 12, AppDimensions.spacingMD, 0),
              child: Row(
                children: [
                  // Search field
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: const InputDecoration(
                        hintText: 'Cari Nama atau kode barang',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingSM),
                  // Add product button
                  IconButton(
                    icon: const Icon(Icons.add, size: AppDimensions.iconSizeLG),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.product);
                    },
                  ),
                ],
              ),
            ),

            // Category chips
            SizedBox(
              height: 64,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMD, vertical: AppDimensions.spacingSM),
                itemCount: productProvider.categories.length + 1,
                itemBuilder: (context, index) {
                  final category = index == 0 ? 'Semua' : productProvider.categories[index - 1];
                  final isSelected = category == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppDimensions.spacingSM),
                    child: ChoiceChip(
                      label: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                    ),
                  );
                },
              ),
            ),

            // Product list
            Expanded(
              child: _getFilteredProducts(products).isEmpty
                  ? const AppEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Produk tidak ditemukan',
                      subtitle: 'Coba ubah kata kunci atau filter kategori',
                    )
                  : ListView.builder(
                      itemCount: _getFilteredProducts(products).length,
                      itemBuilder: (context, index) {
                        final product = _getFilteredProducts(products)[index];
                        final cartQty = cartProvider.activeCart[product.id]?.quantity ?? 0;
                        return ProductCard(
                          product: product,
                          cartQuantity: cartQty,
                          allowZeroStock: true,
                          onAdd: () => _addToCart(product, cartProvider),
                        );
                      },
                    ),
            ),

            // Bottom cart bar
            Container(
              padding: const EdgeInsets.fromLTRB(AppDimensions.spacingMD, AppDimensions.spacingSM, AppDimensions.spacingMD, AppDimensions.spacingMD),
              child: Row(
                children: [
                  // Cart bar
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showCheckout(cartProvider),
                      child: Container(
                        height: 56, // Accessible tap target
                        decoration: BoxDecoration(
                          color: totalCartItems > 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: AppDimensions.spacingLG),
                            Text(
                              '$totalCartItems',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              ' Barang',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'LANJUT',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spacingXS),
                            const Icon(Icons.chevron_right, color: Colors.white, size: AppDimensions.iconSize),
                            const SizedBox(width: AppDimensions.spacingMD),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

