import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/status_dialog.dart';
import '../../data/models/transaction_model.dart';
import '../../data/providers/settings_provider.dart';
import '../../data/providers/auth_provider.dart';

class StrukScreen extends StatefulWidget {
  const StrukScreen({super.key});

  @override
  State<StrukScreen> createState() => _StrukScreenState();
}

class _StrukScreenState extends State<StrukScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final GlobalKey _globalKey = GlobalKey();

  Future<void> _downloadReceipt() async {
    try {
      final image = await _screenshotController.capture();
      if (image == null) return;

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/struk_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await imagePath.writeAsBytes(image);

      if (mounted) {
        showStatusSnackBar(
          context,
          message: 'Struk berhasil diunduh ke ${imagePath.path}',
          type: SnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showStatusSnackBar(
          context,
          message: 'Gagal mengunduh struk',
          type: SnackbarType.error,
        );
      }
    }
  }

  Future<void> _shareReceipt() async {
    try {
      final image = await _screenshotController.capture();
      if (image == null) return;

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/struk_share_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await imagePath.writeAsBytes(image);

      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: 'Terima kasih telah berbelanja di toko kami!',
      );
    } catch (e) {
      if (mounted) {
        showStatusSnackBar(
          context,
          message: 'Gagal membagikan struk',
          type: SnackbarType.error,
        );
      }
    }
  }

  Future<void> _printReceipt(Transaction transaction) async {
    // Placeholder for printing logic
  }

  @override
  Widget build(BuildContext context) {
    final transaction = ModalRoute.of(context)?.settings.arguments as Transaction?;
    if (transaction == null) {
      return const Scaffold(body: Center(child: Text('Data transaksi tidak ditemukan')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Struk Pembayaran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareReceipt,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadReceipt,
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printReceipt(transaction),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spacingLG),
        child: Center(
          child: RepaintBoundary(
            key: _globalKey,
            child: Container(
              width: 320, // Thermal printer width approximation
              padding: const EdgeInsets.all(AppDimensions.spacingMD),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Consumer2<SettingsProvider, AuthProvider>(
                builder: (context, settingsProvider, authProvider, child) {
                  final settings = settingsProvider.settings;
                  // Dynamic properties from settings if available
                  final storeName = (settings as dynamic)?.name ?? 'KEMBANG JAYA';
                  final storeAddress = (settings as dynamic)?.address ?? 'Jl. Raya Industri No. 12, Sidoarjo';
                  final storePhone = (settings as dynamic)?.phone ?? '08123456789';
                  final logoUrl = (settings as dynamic)?.logoUrl;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      if (logoUrl != null && logoUrl.isNotEmpty)
                      AppLogo(logoUrl: logoUrl, height: 60, width: 60)
                      else
                        const Icon(Icons.store, size: 60, color: AppColors.textPrimary),
                      
                      const SizedBox(height: AppDimensions.spacingSM),
                      
                      // Store Name
                      Text(
                        storeName.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      
                      // Store Address
                      Text(
                        '$storeAddress\nTelp: $storePhone',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: AppDimensions.spacingMD),
                      const _DashedDivider(),
                      const SizedBox(height: AppDimensions.spacingMD),
                      
                      // Date & Cashier
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('dd MMM yyyy HH:mm').format(transaction.date), style: const TextStyle(fontSize: 12)),
                          Text('Kasir: ${transaction.cashierName}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      
                      const SizedBox(height: AppDimensions.spacingMD),
                      const _DashedDivider(),
                      const SizedBox(height: AppDimensions.spacingMD),
                      
                      // Items
                      ...transaction.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: AppDimensions.spacingSM),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.name.replaceAll(RegExp(r'\s*Grade.*', caseSensitive: false), ''), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${item.quantity} x ${_currencyFormat.format(item.unitPrice - item.itemDiscount)}', style: const TextStyle(fontSize: 13)),
                                    Text(_currencyFormat.format(item.subtotal), style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                          )),
                          
                      const SizedBox(height: AppDimensions.spacingSM),
                      const _DashedDivider(),
                      const SizedBox(height: AppDimensions.spacingMD),
                      
                      // Subtotals
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sub Total', style: TextStyle(fontSize: 13)),
                          Text(_currencyFormat.format(transaction.subtotal), style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                      
                      if (transaction.extraDiscount > 0 || transaction.discount != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Diskon', style: TextStyle(fontSize: 13)),
                              Text('- ${_currencyFormat.format(transaction.extraDiscount + (transaction.discount?.value ?? 0))}', style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        
                      if (transaction.extraFee > 0 || transaction.fee != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Biaya', style: TextStyle(fontSize: 13)),
                              Text('+ ${_currencyFormat.format(transaction.extraFee + (transaction.fee?.value ?? 0))}', style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        
                      const SizedBox(height: AppDimensions.spacingSM),
                      
                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(_currencyFormat.format(transaction.total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Pay
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Bayar (${transaction.paymentMethod})', style: const TextStyle(fontSize: 13)),
                          Text(_currencyFormat.format(transaction.payAmount), style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                      
                      if (transaction.debtAmount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Sisa Hutang', style: TextStyle(fontSize: 13, color: AppColors.error)),
                              Text(_currencyFormat.format(transaction.debtAmount), style: const TextStyle(fontSize: 13, color: AppColors.error)),
                            ],
                          ),
                        ),
                        
                      const SizedBox(height: AppDimensions.spacingMD),
                      const _DashedDivider(),
                      const SizedBox(height: AppDimensions.spacingMD),
                      
                      // Footer
                      const Text(
                        'Terimakasih telah berbelanja di Depot Kayu\nKembang Jaya',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashWidth = 4.0;
        final dashSpace = 3.0;
        final dashCount = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: const DecoratedBox(
                decoration: BoxDecoration(color: AppColors.textSecondary),
              ),
            );
          }),
        );
      },
    );
  }
}
