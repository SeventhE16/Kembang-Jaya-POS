import 'package:flutter/material.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_empty_state.dart';
import 'package:provider/provider.dart';
import '../../data/providers/product_provider.dart';
import '../../data/providers/transaction_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/models/product_model.dart';
import '../../data/models/transaction_model.dart';
import 'package:depot_kayu_app/core/extensions/context_colors.dart';

class StokOpnameScreen extends StatefulWidget {
  const StokOpnameScreen({super.key});

  @override
  State<StokOpnameScreen> createState() => _StokOpnameScreenState();
}

class _StokOpnameScreenState extends State<StokOpnameScreen> {
  final Map<String, int> _physicalStocks = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final products = Provider.of<ProductProvider>(context, listen: false).products;
      for (var p in products) {
        if (p.trackStock) {
          _physicalStocks[p.id] = p.stock;
        }
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _saveOpname(List<Product> products, String cashierName) {
    int changed = 0;
    List<StockOpnameItem> changedItems = [];
    
    for (var p in products) {
      if (_physicalStocks.containsKey(p.id)) {
        final newStock = _physicalStocks[p.id]!;
        if (newStock != p.stock) {
          changed++;
          
          changedItems.add(StockOpnameItem(
            productId: p.id,
            productName: p.name,
            oldStock: p.stock,
            newStock: newStock,
          ));
          
          p.stock = newStock;
          Provider.of<ProductProvider>(context, listen: false).updateProduct(p);
        }
      }
    }

    if (changed > 0) {
      Provider.of<TransactionProvider>(context, listen: false).addStockOpname(StockOpnameEntry(
        id: 'OP_${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        cashierName: cashierName,
        totalItemsChanged: changed,
        items: changedItems,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok Opname berhasil disimpan! Sistem telah diperbarui.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = Provider.of<ProductProvider>(context).products;
    final cashierName = Provider.of<AuthProvider>(context).user?.displayName ?? 'Kasir';
    final trackableProducts = products.where((p) => p.trackStock).toList();
    final filteredProducts = trackableProducts.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.stokOpname),
      appBar: AppBar(
        title: const Text('Stok Opname'),
      ),
      body: trackableProducts.isEmpty
          ? const AppEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Tidak Ada Barang',
              subtitle: 'Belum ada barang fisik yang dilacak stoknya.',
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: context.colorPrimary.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: context.colorPrimary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Catat jumlah fisik barang di gudang. Jika ada selisih, sesuaikan angka di kolom Fisik.',
                          style: TextStyle(color: context.colorPrimary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari nama barang...',
                      prefixIcon: Icon(Icons.search, color: context.colorPrimary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radius)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final p = filteredProducts[index];
                      final sysStock = p.stock;
                      final physStock = _physicalStocks[p.id] ?? 0;
                      final diff = physStock - sysStock;
                      
                      Color diffColor = Colors.grey;
                      if (diff > 0) diffColor = context.colorSuccess;
                      if (diff < 0) diffColor = context.colorError;

                      return ListTile(
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Row(
                          children: [
                            Text('Sistem: $sysStock ${p.unit}'),
                            const SizedBox(width: 16),
                            if (diff != 0)
                              Text('Selisih: ${diff > 0 ? '+' : ''}$diff', style: TextStyle(color: diffColor, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                color: context.colorError,
                                onPressed: () {
                                  setState(() {
                                    if (physStock > 0) _physicalStocks[p.id] = physStock - 1;
                                  });
                                },
                              ),
                              Text('$physStock', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                color: context.colorSuccess,
                                onPressed: () {
                                  setState(() {
                                    _physicalStocks[p.id] = physStock + 1;
                                  });
                                },
                              ),
                            ],
                          ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: trackableProducts.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(AppDimensions.spacingMD),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
              ),
              child: AppButton(
                label: 'Simpan Opname',
                onPressed: () => _saveOpname(products, cashierName),
              ),
            ),
    );
  }
}



