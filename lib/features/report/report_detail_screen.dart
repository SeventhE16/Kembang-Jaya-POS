import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_routes.dart';
import '../../core/widgets/status_dialog.dart';
import '../../data/models/transaction_model.dart';
import '../../data/providers/transaction_provider.dart';
import '../../data/providers/product_provider.dart';
import '../../data/providers/audit_provider.dart';
import '../../data/providers/cart_provider.dart';
import 'package:depot_kayu_app/core/extensions/context_colors.dart';
import 'widgets/transaction_list_item.dart';

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
              color: context.colorPrimary,
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
                return TransactionListItem(
                  tx: tx,
                  isPurchase: tx.type == 'purchase',
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