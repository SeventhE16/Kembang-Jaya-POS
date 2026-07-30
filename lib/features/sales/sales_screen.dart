import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/status_dialog.dart';
import '../../data/dummy/dummy_data.dart';
import '../../data/models/product_model.dart';
import '../../data/models/transaction_model.dart';
import 'checkout_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final DummyData _data = DummyData();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, CartItem> _cart = {};
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

  int get _totalCartItems =>
      _cart.values.fold(0, (sum, item) => sum + item.quantity);

  void _addToCart(Product product) {
    setState(() {
      final currentQty = _cart[product.id]?.quantity ?? 0;
      if (product.trackStock && currentQty >= product.stock) {
        showStatusSnackBar(
          context,
          message: 'Stok ${product.name} habis/tidak cukup',
          isSuccess: false,
        );
        return;
      }
      if (_cart.containsKey(product.id)) {
        _cart[product.id]!.quantity++;
      } else {
        _cart[product.id] = CartItem(product: product);
      }
    });
  }

  void _showCheckout() {
    if (_cart.isEmpty) {
      showStatusSnackBar(
        context,
        message: 'Keranjang masih kosong',
        isSuccess: false,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CheckoutSheet(
        cart: _cart,
        onComplete: (transaction) {
          setState(() {
            _cart.clear();
          });
          Navigator.pop(ctx);
          showStatusSnackBar(
            context,
            message: 'Transaksi berhasil disimpan',
            isSuccess: true,
          );
          // Show receipt
          showReceiptDialog(
            context,
            transactionNo: transaction.id,
            cashier: transaction.cashierName,
            items: transaction.items
                .map((e) => {
                      'name': e.product.name,
                      'qty': e.quantity,
                      'price': e.product.sellPrice,
                      'subtotal': e.subtotal,
                    })
                .toList(),
            total: transaction.total,
            onPrint: () {
              showStatusSnackBar(
                context,
                message: 'Struk dikirim ke printer (demo)',
                isSuccess: true,
              );
            },
          );
        },
      ),
    ).then((_) {
      // Sync UI when checkout sheet is closed (items might have been removed)
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
    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.sales),
      appBar: AppBar(
        title: const Text(
          'Penjualan',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
        child: Column(
        children: [
          // Divider line
          const Divider(height: 1),

          // Search bar + action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                // Search field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
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
                const SizedBox(width: 8),
                // Add product button
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.primary, size: 26),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.product);
                  },
                ),
                // Discount button
                IconButton(
                  icon: const Icon(Icons.percent, color: AppColors.primary, size: 22),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.discount);
                  },
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
                    onSelected: (_) =>
                        setState(() => _selectedCategory = category),
                    backgroundColor: AppColors.chipInactive,
                    selectedColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: AppColors.textHint),
                        const SizedBox(height: 16),
                        const Text(
                          'Produk tidak ditemukan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Coba ubah kata kunci atau filter kategori',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      final cartQty = _cart[product.id]?.quantity ?? 0;
                      return ProductCard(
                        product: product,
                        cartQuantity: cartQty,
                        onAdd: () => _addToCart(product),
                      );
                    },
                  ),
          ),

          // Bottom cart bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                // Cart bar
                Expanded(
                  child: GestureDetector(
                    onTap: _showCheckout,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: _totalCartItems > 0 ? AppColors.primary : AppColors.stockEmpty,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 20),
                          Text(
                            '$_totalCartItems',
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
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, color: Colors.white, size: 24),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Customer button
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.person_add_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
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
