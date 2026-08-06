import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_dialog.dart';
import '../../data/models/transaction_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/supplier_provider.dart';
import '../../data/providers/transaction_provider.dart';
import '../../core/widgets/app_supplier_picker.dart';

class HutangScreen extends StatefulWidget {
  const HutangScreen({super.key});

  @override
  State<HutangScreen> createState() => _HutangScreenState();
}

class _HutangScreenState extends State<HutangScreen> {
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  void _sendWhatsApp(String phone, dynamic tx) async {
    final sisa = currencyFormat.format(tx.debtAmount);
    final tgl = DateFormat('dd MMM yyyy, HH:mm').format(tx.date);
    final message = "Halo, ini adalah rincian tagihan Kembang Jaya ke Supplier sebesar $sisa dengan transaksi pembelian pada Tanggal $tgl. Terima kasih!";
    
    // Normalize phone (replace leading 0 with 62)
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    }

    final url = Uri.parse("https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka WhatsApp')));
    }
  }

  void _payCicilan(dynamic tx) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bayar Cicilan Hutang'),
        content: AppTextField(
          controller: controller,
          label: 'Nominal Pembayaran',
          hint: 'Contoh: 500000',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          AppButton(
            label: 'Bayar',
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final cashier = authProvider.user?.displayName ?? 'Kasir';
                
                double actualAmount = amount;
                if (amount >= tx.debtAmount) {
                  actualAmount = tx.debtAmount;
                }

                final newInstallment = InstallmentPayment(
                  id: '', // Di-generate di server
                  amount: actualAmount,
                  date: DateTime.now(),
                  cashierName: cashier,
                );

                Navigator.pop(ctx);
                
                try {
                  Provider.of<TransactionProvider>(context, listen: false).addInstallment(tx.id, newInstallment);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran hutang berhasil dicatat!')));
                  }
                } catch (e) {
                  if (mounted) {
                    showStatusSnackBar(context, message: 'Gagal mencatat: $e', type: SnackbarType.error);
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    final hutangList = transactionProvider.purchaseTransactions.where((t) => t.debtAmount > 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hutang Supplier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.store_mall_directory_outlined),
            onPressed: () => AppSupplierPicker.show(context).then((_) => setState(() {})),
            tooltip: 'Supplier',
          ),
        ],
      ),
      body: hutangList.isEmpty
          ? const Center(
              child: AppEmptyState(
                icon: Icons.check_circle_outline,
                title: 'Tidak Ada Hutang',
                subtitle: 'Semua transaksi pembelian sudah lunas.',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.spacingMD),
              itemCount: hutangList.length,
              itemBuilder: (context, index) {
                final tx = hutangList[index];
                // Find the supplier phone
                final suppliers = Provider.of<SupplierProvider>(context, listen: false).suppliers;
                final supplier = suppliers.where((c) => c.name == tx.supplierName).firstOrNull;

                return Card(
                  margin: const EdgeInsets.only(bottom: AppDimensions.spacingMD),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radius)),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacingMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.supplierName ?? 'Tanpa Nama',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                if (supplier != null && supplier.phone.isNotEmpty)
                                  Text(
                                    'HP: ${supplier.phone}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Belum Lunas',
                                style: const TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacingSM),
                        Text(
                          'Sisa Hutang: ${currencyFormat.format(tx.debtAmount)}',
                          style: const TextStyle(fontSize: 16, color: AppColors.error, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total Pembelian: ${currencyFormat.format(tx.total)}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        const SizedBox(height: 4),
                        Text(
                          'Tgl: ${DateFormat('dd MMM yyyy HH:mm').format(tx.date)} • ID: ${tx.invoiceNumber ?? tx.id}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        ExpansionTile(
                          title: const Text(
                            'Riwayat Pembayaran',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          tilePadding: EdgeInsets.zero,
                          children: [
                            StreamBuilder<List<InstallmentPayment>>(
                              stream: transactionProvider.streamInstallments(tx.id),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  );
                                }
                                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Belum ada riwayat pembayaran', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  );
                                }
                                return Column(
                                  children: snapshot.data!.map((inst) {
                                    return ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(Icons.history, size: 20),
                                      title: Text(currencyFormat.format(inst.amount)),
                                      subtitle: Text('${DateFormat('dd MMM yyyy HH:mm').format(inst.date)} • Oleh: ${inst.cashierName}'),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacingMD),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.phone, size: 16),
                                label: const Text('Hubungi'),
                                onPressed: () {
                                  if (supplier != null) {
                                    _sendWhatsApp(supplier.phone, tx);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nomor telepon supplier tidak ditemukan')));
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spacingSM),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.payment, size: 16),
                                label: const Text('Bayar Hutang'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => _payCicilan(tx),
                              ),
                            ),
                          ],
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
