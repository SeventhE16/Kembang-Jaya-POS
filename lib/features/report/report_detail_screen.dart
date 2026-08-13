import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/status_dialog.dart';
import '../../data/models/transaction_model.dart';
import '../../data/providers/transaction_provider.dart';
import '../../data/providers/product_provider.dart';
import '../../data/providers/audit_provider.dart';

class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final transactions = (args?['transactions'] as List<dynamic>?)?.cast<Transaction>() ?? [];
    final title = args?['title'] as String? ?? 'Detail Transaksi';
    final periodLabel = args?['periodLabel'] as String? ?? '';

    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    bool isPurchase = transactions.isNotEmpty && transactions.every((t) => t.type == 'purchase');

    double totalPendapatan = 0;
    double totalKeuntungan = 0;

    for (var tx in transactions) {
      totalPendapatan += tx.total;
      
      double costBasis = 0;
      for (var item in tx.items) {
        costBasis += item.product.basePrice * item.quantity;
      }
      totalKeuntungan += (tx.total - costBasis);
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
            if (periodLabel.isNotEmpty)
              Text(
                '$periodLabel ($title)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Summary bar
          Container(
            margin: const EdgeInsets.all(AppDimensions.spacingMD),
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingMD, horizontal: AppDimensions.spacingSM),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppDimensions.radius),
            ),
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSummaryItem('Jml Transaksi', '${transactions.length}'),
                  const VerticalDivider(color: Colors.white54, thickness: 1),
                  _buildSummaryItem(isPurchase ? 'Total Pengeluaran' : 'Pendapatan', currencyFormat.format(totalPendapatan)),
                  if (!isPurchase) ...[
                    const VerticalDivider(color: Colors.white54, thickness: 1),
                    _buildSummaryItem('Keuntungan', currencyFormat.format(totalKeuntungan)),
                  ],
                ],
              ),
            ),
          ),
          
          // Transaction List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMD, vertical: AppDimensions.spacingSM),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                
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
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd').format(tx.date),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              DateFormat('MMM\nyyyy').format(tx.date),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
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
                                Text(tx.type == 'purchase' ? 'Pengeluaran' : 'Pendapatan', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                Text(currencyFormat.format(tx.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            if (tx.type != 'purchase') ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Keuntungan', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  Text(currencyFormat.format(keuntungan), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: Text('No : ${tx.id}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 16, color: AppColors.textSecondary),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: tx.id));
                                    showStatusSnackBar(
                                      context,
                                      message: 'Nomor transaksi disalin',
                                      type: SnackbarType.success,
                                    );
                                  },
                                ),
                              ],
                            ),
                            if (tx.paymentMethod == 'Kasbon' && tx.debtAmount > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                  child: const Text('Kasbon - Belum Lunas', style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.bold)),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Far right: Actions
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.error),
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
                                              // Menggunakan negatif quantity agar stock bertambah kembali
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
                                      child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward, color: AppColors.primary),
                            onPressed: () {
                              Navigator.pushNamed(context, '/struk', arguments: tx);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}
