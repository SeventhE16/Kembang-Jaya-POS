import '../../core/widgets/app_customer_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/status_dialog.dart';
import '../../data/models/transaction_model.dart';
import 'package:provider/provider.dart';
import '../../data/providers/transaction_provider.dart';
import '../../data/providers/customer_provider.dart';
import '../../data/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:depot_kayu_app/core/extensions/context_colors.dart';

class PiutangScreen extends StatefulWidget {
  const PiutangScreen({super.key});

  @override
  State<PiutangScreen> createState() => _PiutangScreenState();
}

class _PiutangScreenState extends State<PiutangScreen> {
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  void _sendWhatsApp(String phone, dynamic tx) async {
    final sisa = currencyFormat.format(tx.debtAmount);
    final tgl = DateFormat('dd MMM yyyy, HH:mm').format(tx.date);
    final message = "Halo, ini adalah rincian tagihan dari Kembang Jaya sebesar $sisa dengan transaksi yang dilakukan pada Tanggal $tgl di Depot Kayu Kembang Jaya. Terima kasih!";
    
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
        title: const Text('Bayar Cicilan'),
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
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran berhasil dicatat!')));
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
    final piutangList = transactionProvider.salesTransactions.where((t) => t.debtAmount > 0).toList();

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.piutang),
      appBar: AppBar(
        title: const Text('Piutang & Kasbon'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () => AppCustomerPicker.show(context).then((_) => setState(() {})),
            tooltip: 'Pelanggan',
          ),
        ],
      ),
      body: piutangList.isEmpty
          ? const Center(
              child: AppEmptyState(
                icon: Icons.check_circle_outline,
                title: 'Tidak Ada Piutang',
                subtitle: 'Semua transaksi pelanggan sudah lunas.',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.spacingMD),
              itemCount: piutangList.length,
              itemBuilder: (context, index) {
                final tx = piutangList[index];
                // Find the customer phone
                final customers = Provider.of<CustomerProvider>(context, listen: false).customers;
                final customer = customers.where((c) => c.name == tx.customerName).firstOrNull;

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
                                  tx.customerName ?? 'Tanpa Nama',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                if (customer != null && customer.phone.isNotEmpty)
                                  Text(
                                    'HP: ${customer.phone}',
                                    style: TextStyle(fontSize: 12, color: context.colorTextSecondary),
                                  ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: context.colorError.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Belum Lunas',
                                style: TextStyle(fontSize: 11, color: context.colorError, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacingSM),
                        Text(
                          'Sisa Hutang: ${currencyFormat.format(tx.debtAmount)}',
                          style: TextStyle(fontSize: 16, color: context.colorError, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total Transaksi: ${currencyFormat.format(tx.total)}',
                          style: TextStyle(fontSize: 13, color: context.colorTextSecondary),
                        ),
                        const SizedBox(height: 4),
                        const SizedBox(height: 4),
                        Text(
                          'Tgl: ${DateFormat('dd MMM yyyy HH:mm').format(tx.date)} • ID: ${tx.invoiceNumber ?? tx.id}',
                          style: TextStyle(fontSize: 12, color: context.colorTextSecondary),
                        ),
                        const SizedBox(height: 12),
                        ExpansionTile(
                          title: const Text(
                            'Riwayat Cicilan',
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
                                  return Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Belum ada riwayat cicilan', style: TextStyle(color: context.colorTextSecondary, fontSize: 12)),
                                  );
                                }
                                return Column(
                                  children: snapshot.data!.map((inst) {
                                    return ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(Icons.history, size: 20),
                                      title: Text(currencyFormat.format(inst.amount)),
                                      subtitle: Text('${DateFormat('dd MMM yyyy HH:mm').format(inst.date)} • Kasir: ${inst.cashierName}'),
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
                                  // Find customer phone
                                  final customers = Provider.of<CustomerProvider>(context, listen: false).customers;
                                  final cust = customers.where((c) => c.name == tx.customerName).firstOrNull;
                                  if (cust != null) {
                                    _sendWhatsApp(cust.phone, tx);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nomor telepon pelanggan tidak ditemukan')));
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spacingSM),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.payment, size: 16),
                                label: const Text('Bayar Cicilan'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.colorSuccess,
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

