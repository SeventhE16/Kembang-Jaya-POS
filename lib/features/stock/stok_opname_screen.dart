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

class StokOpnameScreen extends StatefulWidget {
  const StokOpnameScreen({super.key});

  @override
  State<StokOpnameScreen> createState() => _StokOpnameScreenState();
}

class _StokOpnameScreenState extends State<StokOpnameScreen> {
  final Map<String, int> _physicalStocks = {};
  
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

  void _saveOpname(List<Product> products, String cashierName) {
    int changed = 0;
    for (var p in products) {
      if (_physicalStocks.containsKey(p.id)) {
        final newStock = _physicalStocks[p.id]!;
        if (newStock != p.stock) {
          changed++;
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
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Catat jumlah fisik barang di gudang. Jika ada selisih, sesuaikan angka di kolom Fisik.',
                          style: TextStyle(color: AppColors.primary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: trackableProducts.length,
                    itemBuilder: (context, index) {
                      final p = trackableProducts[index];
                      final sysStock = p.stock;
                      final physStock = _physicalStocks[p.id] ?? 0;
                      final diff = physStock - sysStock;
                      
                      Color diffColor = Colors.grey;
                      if (diff > 0) diffColor = AppColors.success;
                      if (diff < 0) diffColor = AppColors.error;

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
                                color: AppColors.error,
                                onPressed: () {
                                  setState(() {
                                    if (physStock > 0) _physicalStocks[p.id] = physStock - 1;
                                  });
                                },
                              ),
                              Text('$physStock', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                color: AppColors.success,
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





