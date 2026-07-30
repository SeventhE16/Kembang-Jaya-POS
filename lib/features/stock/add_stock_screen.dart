import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_dialog.dart';
import '../../core/widgets/product_card.dart';
import '../../data/dummy/dummy_data.dart';
import '../../data/models/product_model.dart';
import '../../data/models/transaction_model.dart';

class RestockCartItem {
  final Product product;
  int quantity;
  double costPerUnit;
  String? note;

  RestockCartItem({
    required this.product,
    required this.quantity,
    required this.costPerUnit,
    this.note,
  });

  double get totalCost => quantity * costPerUnit;
}

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  final DummyData _data = DummyData();
  final Map<String, RestockCartItem> _cart = {};
  
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  List<Product> get _filteredProducts {
    return _data.products.where((p) {
      if (!p.trackStock) return false;
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'Semua' || p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  double get _totalCartCost => _cart.values.fold(0, (sum, item) => sum + item.totalCost);

  void _showAddItemSheet(Product product) {
    final qtyController = TextEditingController(text: '1');
    final costController = TextEditingController(text: product.basePrice.toInt().toString());
    final noteController = TextEditingController();

    // Pre-fill if already in cart
    if (_cart.containsKey(product.id)) {
      final existing = _cart[product.id]!;
      qtyController.text = existing.quantity.toString();
      costController.text = existing.costPerUnit.toInt().toString();
      noteController.text = existing.note ?? '';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Restock ${product.name}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Kuantitas',
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Modal / Unit',
                      controller: costController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              AppTextField(
                label: 'Catatan (opsional)',
                controller: noteController,
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  if (_cart.containsKey(product.id)) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _cart.remove(product.id);
                          });
                          Navigator.pop(ctx);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        child: const Text('Hapus'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: 'Simpan',
                      onPressed: () {
                        final qty = int.tryParse(qtyController.text) ?? 0;
                        if (qty <= 0) {
                          showStatusSnackBar(context, message: 'Kuantitas harus lebih dari 0', isSuccess: false);
                          return;
                        }
                        final cost = double.tryParse(costController.text) ?? 0;
                        
                        setState(() {
                          _cart[product.id] = RestockCartItem(
                            product: product,
                            quantity: qty,
                            costPerUnit: cost,
                            note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                          );
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _finishPurchase() {
    if (_cart.isEmpty) return;

    // Process all items
    for (var item in _cart.values) {
      final entry = StockEntry(
        id: 'SE${DateTime.now().millisecondsSinceEpoch}',
        product: item.product,
        quantity: item.quantity,
        totalCost: item.totalCost,
        note: item.note,
        date: DateTime.now(),
      );
      _data.stockEntries.add(entry);
      item.product.stock += item.quantity;
    }

    _showReceiptDialog();
  }

  void _showReceiptDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 64),
              const SizedBox(height: 16),
              const Text('Restock Berhasil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Stok barang telah ditambahkan.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _cart.clear();
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Tutup'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        showStatusSnackBar(context, message: 'Mencetak struk restock...', isSuccess: true);
                      },
                      child: const Text('Cetak Struk'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      appBar: AppBar(
        title: const Text('Catat Pembelian'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                          color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
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

            // Product List
            Expanded(
              child: _filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textHint),
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
                          onAdd: () => _showAddItemSheet(product),
                        );
                      },
                    ),
            ),
            
            // Bottom Bar
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Total Pembelian', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          'Rp ${DummyData.formatCurrency(_totalCartCost.toInt())}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _cart.isEmpty ? null : _finishPurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cart.isEmpty ? AppColors.stockEmpty : AppColors.primary,
                      ),
                      child: const Text('Selesaikan'),
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
