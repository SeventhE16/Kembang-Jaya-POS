import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/status_dialog.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/providers/transaction_provider.dart';
import '../../../data/providers/product_provider.dart';
import '../../../data/providers/audit_provider.dart';
import '../../../data/providers/cart_provider.dart';
import 'package:depot_kayu_app/core/extensions/context_colors.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction tx;
  final bool isPurchase;
  
  const TransactionListItem({super.key, required this.tx, this.isPurchase = false});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    
    double costBasis = 0;
    for (var item in tx.items) {
      costBasis += item.cogs ?? (item.product.basePrice * item.quantity);
    }
    final keuntungan = tx.subtotal - costBasis;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingMD),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Date & Time
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  DateFormat('HH:mm:ss').format(tx.date),
                  style: TextStyle(fontSize: 10, color: context.colorTextSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd').format(tx.date),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('MMM\nyyyy').format(tx.date),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: context.colorTextSecondary),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: AppDimensions.spacingMD),
          
          // Right side: Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tx.type == 'purchase' ? 'Pengeluaran' : 'Pendapatan', style: TextStyle(fontSize: 12, color: context.colorTextSecondary)),
                    Text(currencyFormat.format(tx.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                if (tx.type != 'purchase') ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Keuntungan', style: TextStyle(fontSize: 12, color: context.colorTextSecondary)),
                      Text(currencyFormat.format(keuntungan), style: TextStyle(fontWeight: FontWeight.bold, color: context.colorSuccess)),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text('No : ${tx.id}', style: TextStyle(fontSize: 12, color: context.colorTextSecondary)),
                if (tx.paymentMethod == 'Kasbon' && tx.debtAmount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: context.colorError.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text('Kasbon - Belum Lunas', style: TextStyle(fontSize: 10, color: context.colorError, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          
          // Far right: Actions
          Column(
            children: [
              // Edit Button
              if (tx.type != 'purchase')
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: context.colorPrimary),
                  tooltip: 'Edit Transaksi',
                  onPressed: () {
                    final cartProv = Provider.of<CartProvider>(context, listen: false);
                    cartProv.loadTransaction(tx);
                    // Kembali ke Sales screen dengan keranjang yang sudah terisi
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.sales,
                      (route) => false,
                    );
                    showStatusSnackBar(context,
                        message: 'Mode Edit: ubah item lalu lanjut ke Pembayaran',
                        type: SnackbarType.success);
                  },
                ),
              // Delete Button
              IconButton(
                icon: Icon(Icons.close, color: context.colorError),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Hapus Transaksi?'),
                      content: const Text('Transaksi yang dihapus tidak dapat dikembalikan.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () {
                            try {
                              Provider.of<TransactionProvider>(context, listen: false).deleteTransaction(tx.id);
                              
                              // Kembalikan stok barang
                              final productProvider = Provider.of<ProductProvider>(context, listen: false);
                              for (var item in tx.items) {
                                if (item.product.category != 'Jasa') {
                                  productProvider.reduceStock(item.product.id, -item.quantity);
                                }
                              }
                              Navigator.pop(ctx);
                              
                              // Log Activity
                              final invoice = tx.invoiceNumber ?? tx.id;
                              Provider.of<AuditProvider>(context, listen: false).logAction('Hapus Transaksi', 'Menghapus transaksi nota: $invoice senilai Rp${tx.total}');
                              
                              showStatusSnackBar(context, message: 'Transaksi dihapus & stok dikembalikan', type: SnackbarType.success);
                            } catch (e) {
                              Navigator.pop(ctx);
                              showStatusSnackBar(context, message: 'Gagal menghapus', type: SnackbarType.error);
                            }
                          },
                          child: Text('Hapus', style: TextStyle(color: context.colorError)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.receipt_long, color: context.colorPrimary),
                tooltip: 'Lihat Struk',
                onPressed: () {
                  Navigator.pushNamed(context, '/struk', arguments: tx);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
