import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import '../../data/providers/cart_provider.dart';
import '../../data/providers/transaction_provider.dart';
import '../../data/models/transaction_model.dart';
import '../../core/constants/app_routes.dart';
import 'package:intl/intl.dart';

class HoldOrderScreen extends StatefulWidget {
  const HoldOrderScreen({super.key});

  @override
  State<HoldOrderScreen> createState() => _HoldOrderScreenState();
}

class _HoldOrderScreenState extends State<HoldOrderScreen> {
  TransactionProvider get _transaction => Provider.of<TransactionProvider>(context, listen: false);
  CartProvider get _cart => Provider.of<CartProvider>(context, listen: false);
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  void _restoreHoldOrder(HoldOrder holdOrder) {
    if (_cart.activeCart.isNotEmpty) {
      // Ask for confirmation to overwrite current cart or save current cart
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Keranjang Aktif'),
          content: const Text(
              'Ada transaksi yang sedang berjalan di keranjang. Apakah Anda ingin menyimpannya ke Hold Order terlebih dahulu sebelum membuka transaksi ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            AppButton(
              label: 'Ya, Simpan & Buka',
              onPressed: () {
                // Save current cart
                _transaction.saveHoldOrder(HoldOrder(
                  id: 'HO-${DateTime.now().millisecondsSinceEpoch}',
                  cart: Map.from(_cart.activeCart),
                  date: DateTime.now(),
                  note: _cart.activeCustomer?.name ?? 'Tanpa Nama',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                ));
                // Load the selected hold order
                _loadAndPop(holdOrder);
              },
            ),
            AppButton(
              label: 'Hapus Keranjang Lama',
              variant: AppButtonVariant.secondary,
              onPressed: () => _loadAndPop(holdOrder),
            ),
          ],
        ),
      );
    } else {
      _loadAndPop(holdOrder, fromDialog: false);
    }
  }

  void _loadAndPop(HoldOrder holdOrder, {bool fromDialog = true}) {
    _cart.clearCart();
    holdOrder.cart.forEach((k, v) => _cart.restoreItem(k, v));
    _transaction.deleteHoldOrder(holdOrder.id);
    
    if (fromDialog) {
      Navigator.pop(context); // Close dialog
    }
    Navigator.pushReplacementNamed(context, '/sales'); // Go to sales screen
  }

  void _deleteHoldOrder(HoldOrder holdOrder) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Hold Order'),
        content: const Text('Apakah Anda yakin ingin menghapus pesanan yang ditangguhkan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          AppButton(
            label: 'Hapus',
            variant: AppButtonVariant.primary,
            onPressed: () {
              _transaction.deleteHoldOrder(holdOrder.id);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.holdOrders),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text('Pesanan Ditahan (Hold)'),
      ),
      body: context.watch<TransactionProvider>().holdOrders.isEmpty
          ? const Center(
              child: Text(
                'Belum ada pesanan yang di-hold',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.spacingMD),
              itemCount: context.watch<TransactionProvider>().holdOrders.length,
              itemBuilder: (context, index) {
                final hold = context.watch<TransactionProvider>().holdOrders[index];
                double total = hold.cart.values.fold(0, (sum, item) => sum + item.subtotal);
                int itemsCount = hold.cart.values.fold(0, (sum, item) => sum + item.quantity);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radius)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      (hold.note?.isNotEmpty ?? false) ? hold.note! : 'Tanpa Nama',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(DateFormat('dd/MM/yyyy HH:mm').format(hold.date)),
                        Text('$itemsCount barang • ${_currencyFormat.format(total)}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          onPressed: () => _deleteHoldOrder(hold),
                        ),
                        const SizedBox(width: AppDimensions.spacingSM),
                        AppButton(
                          label: 'Lanjutkan',
                          onPressed: () => _restoreHoldOrder(hold),
                          isFullWidth: false,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}











