import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/transaction_model.dart';

class StockOpnameDetailScreen extends StatelessWidget {
  const StockOpnameDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entry = ModalRoute.of(context)!.settings.arguments as StockOpnameEntry;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Stok Opname', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tanggal', style: TextStyle(color: AppColors.textSecondary)),
                    Text(DateFormat('dd MMMM yyyy, HH:mm', 'id').format(entry.date), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Kasir', style: TextStyle(color: AppColors.textSecondary)),
                    Text(entry.cashierName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Barang', style: TextStyle(color: AppColors.textSecondary)),
                    Text('${entry.totalItemsChanged} Barang Berubah', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: entry.items.isEmpty
                ? const Center(child: Text('Tidak ada rincian barang', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: entry.items.length,
                    itemBuilder: (context, index) {
                      final item = entry.items[index];
                      final diff = item.newStock - item.oldStock;
                      final isIncrease = diff > 0;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Stok Sistem', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    Text('${item.oldStock}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Fisik/Baru', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    Text('${item.newStock}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isIncrease ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isIncrease ? '+$diff' : '$diff',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isIncrease ? AppColors.success : AppColors.error,
                                      fontSize: 13,
                                    ),
                                  ),
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
}
