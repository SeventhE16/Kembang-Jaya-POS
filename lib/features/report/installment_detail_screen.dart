import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/models/transaction_model.dart';

class InstallmentDetailScreen extends StatelessWidget {
  const InstallmentDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final title = args['title'] as String;
    final installments = args['installments'] as List<InstallmentPayment>;
    final isOutgoing = args['isOutgoing'] as bool;
    
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: installments.isEmpty
          ? const Center(child: Text('Tidak ada detail cicilan'))
          : ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.spacingMD),
              itemCount: installments.length,
              itemBuilder: (context, index) {
                final installment = installments[index];
                
                return Container(
                  margin: const EdgeInsets.only(bottom: AppDimensions.spacingMD),
                  padding: const EdgeInsets.all(AppDimensions.spacingMD),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radius),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm').format(installment.date),
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          Text(
                            installment.cashierName,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Nominal Angsuran', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                Text(
                                  currencyFormat.format(installment.amount),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isOutgoing ? AppColors.error : AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (installment.note != null && installment.note!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Text('Catatan: ${installment.note}', style: const TextStyle(fontSize: 13)),
                      ],
                      if (installment.transactionId != null) ...[
                        const SizedBox(height: 4),
                        Text('No. Transaksi: ${installment.transactionId}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}
