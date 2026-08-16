import 'dart:io';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_routes.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/status_dialog.dart';
import 'package:provider/provider.dart';
import '../../data/providers/cart_provider.dart';
import '../../data/providers/settings_provider.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/product_model.dart';
import '../../core/services/printer_service.dart';
import '../../core/services/settings_service.dart';
import '../../data/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:depot_kayu_app/core/extensions/context_colors.dart';

class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({super.key});

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  CartProvider get _cart => Provider.of<CartProvider>(context, listen: false);
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final ScreenshotController _screenshotController = ScreenshotController();

  void _finishTransaction() {
    _cart.clearCart();
    Navigator.popUntil(context, ModalRoute.withName(AppRoutes.sales));
  }

  Widget _buildStrukContent(Transaction? transaction) {
    final cart = transaction?.items ?? [];
    final subtotal = transaction?.subtotal ?? 0;
    final discount = transaction?.extraDiscount ?? 0;
    final fee = (transaction?.extraFee ?? 0) + (transaction?.fee?.value ?? 0);
    final feeName = transaction?.fee?.name ?? 'Biaya';
    final total = transaction?.total ?? 0;
    // mock data for piutang if present
    final isCredit = transaction?.paymentMethod == 'Kasbon' && (transaction?.debtAmount ?? 0) > 0;
    final date = DateFormat('yyyy-MM-dd HH:mm:ss').format(transaction?.date ?? DateTime.now());
    
    final settings = Provider.of<SettingsProvider>(context, listen: false).settings;
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    return Container(
      color: Colors.white,
      width: 400, // Fixed width for consistent screenshot
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo
          if (settings?.logoUrl != null && settings!.logoUrl!.isNotEmpty)
             AppLogo(logoUrl: settings.logoUrl!, height: 64, fit: BoxFit.contain)
          else
             const Icon(Icons.storefront, color: Colors.black54, size: 48),
          const SizedBox(height: 16),
          Text(
            settings?.name.toUpperCase() ?? 'KEMBANG JAYA',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black, letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          Text(
            '${settings?.address ?? ''}\nWhatsApp (WA) ${settings?.phone ?? ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          const _DashedDivider(),
          const SizedBox(height: 8),
          // Info Row 1
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date.split(' ')[0], style: const TextStyle(fontSize: 13, color: Colors.black)),
                  Text(date.split(' ')[1], style: const TextStyle(fontSize: 13, color: Colors.black)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (transaction?.customerName != null)
                    Text('Pelanggan : ${transaction!.customerName}', style: const TextStyle(fontSize: 13, color: Colors.black)),
                  Text('Kasir : ${transaction?.cashierName ?? user?.displayName ?? 'Staff'}', style: const TextStyle(fontSize: 13, color: Colors.black)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _DashedDivider(),
          const SizedBox(height: 8),
          // Items
          ...cart.expand((item) {
            final name = item.product.name.replaceAll(RegExp(r'\s*Grade.*', caseSensitive: false), '');
            final widgets = <Widget>[];

            if (item.customPrice == null && item.product.wholesalePrices.isNotEmpty) {
              final sortedTiers = List<WholesalePrice>.from(item.product.wholesalePrices)
                ..sort((a, b) => b.minQty.compareTo(a.minQty));
              final tier = sortedTiers.first;

              if (item.quantity >= tier.minQty) {
                final wholesaleQty = (item.quantity ~/ tier.minQty) * tier.minQty;
                final remainderQty = item.quantity % tier.minQty;

                widgets.add(Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)));
                widgets.add(Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$wholesaleQty x ${_currencyFormat.format(tier.price - item.itemDiscount)} (grosir)', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    Text(_currencyFormat.format(wholesaleQty * (tier.price - item.itemDiscount)), style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  ],
                ));
                if (remainderQty > 0) {
                  widgets.add(Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$remainderQty x ${_currencyFormat.format(item.product.sellPrice - item.itemDiscount)} (ecer)', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                      Text(_currencyFormat.format(remainderQty * (item.product.sellPrice - item.itemDiscount)), style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    ],
                  ));
                }
                widgets.add(const SizedBox(height: 8));
                return widgets;
              }
            }

            // Default: item biasa
            widgets.add(Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.quantity} x ${_currencyFormat.format(item.unitPrice)}', style: const TextStyle(fontSize: 13, color: Colors.black)),
                      Text(_currencyFormat.format(item.subtotal), style: const TextStyle(fontSize: 13, color: Colors.black)),
                    ],
                  ),
                ],
              ),
            ));
            return widgets;
          }),
          const SizedBox(height: 4),
          const _DashedDivider(),
          const SizedBox(height: 8),
          // Subtotal & Totals
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sub Total', style: TextStyle(fontSize: 13, color: Colors.black)),
              Text(_currencyFormat.format(subtotal), style: const TextStyle(fontSize: 13, color: Colors.black)),
            ],
          ),
          if (discount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Diskon: ', style: const TextStyle(fontSize: 13, color: Colors.black)),
                Text(_currencyFormat.format(discount), style: const TextStyle(fontSize: 13, color: Colors.black)),
              ],
            ),
          if (fee > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(feeName, style: const TextStyle(fontSize: 13, color: Colors.black)),
                Text(_currencyFormat.format(fee), style: const TextStyle(fontSize: 13, color: Colors.black)),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
              Text(_currencyFormat.format(total), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
          if (!isCredit) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bayar (${transaction?.paymentMethod ?? 'Cash'})', style: const TextStyle(fontSize: 13, color: Colors.black)),
                Text(_currencyFormat.format(transaction?.payAmount ?? 0), style: const TextStyle(fontSize: 13, color: Colors.black)),
              ],
            ),
          ],
          if (discount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Anda Hemat', style: TextStyle(fontSize: 13, color: Colors.black)),
                Text(_currencyFormat.format(discount), style: const TextStyle(fontSize: 13, color: Colors.black)),
              ],
            ),
          const SizedBox(height: 8),
          const _DashedDivider(),
          const SizedBox(height: 8),
          // Credit Info
          if (isCredit) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tipe: kredit', style: TextStyle(fontSize: 13, color: Colors.black)),
                Text('Jatuh Tempo: -', style: const TextStyle(fontSize: 13, color: Colors.black)),
              ],
            ),
            const SizedBox(height: 4),
            const Text('STATUS: BELUM LUNAS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
            Text('SISA KREDIT: ${_currencyFormat.format(transaction?.debtAmount ?? 0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 8),
            const _DashedDivider(),
            const SizedBox(height: 8),
            const Text('Riwayat Pembayaran :', style: TextStyle(fontSize: 13, color: Colors.black)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('dd-MM-yyyy').format(transaction?.date ?? DateTime.now()), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
                Text(transaction?.cashierName ?? user?.displayName ?? 'Staff', style: const TextStyle(fontSize: 13, color: Colors.black)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(transaction?.paymentMethod ?? 'Cash', style: const TextStyle(fontSize: 13, color: Colors.black)),
                Text(_currencyFormat.format(transaction?.payAmount ?? 0), style: const TextStyle(fontSize: 13, color: Colors.black)),
              ],
            ),
            const SizedBox(height: 8),
            const _DashedDivider(),
            const SizedBox(height: 16),
          ],
          
          const Text('Terimakasih telah berbelanja di Depot Kayu\nKembang Jaya', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.black)),
        ],
      ),
    );
  }

  void _showPreviewStruk(Transaction? transaction) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Preview Struk'),
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: _buildStrukContent(transaction)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          AppButton(
            label: 'Cetak',
            onPressed: () async {
              Navigator.pop(ctx);
              
              if (transaction == null) {
                showStatusSnackBar(context, message: 'Data transaksi tidak tersedia', type: SnackbarType.error);
                return;
              }
              
              final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
              final storeSettings = settingsProvider.settings ?? StoreSettings(
                name: 'Nama Toko (Belum Diatur)',
                address: '-',
                phone: '-',
                updatedAt: DateTime.now(),
              );

              if (!PrinterService().isConnected) {
                showStatusSnackBar(context, message: 'Printer belum terhubung. Silakan atur di Pengaturan.', type: SnackbarType.error);
                return;
              }

              final currentCtx = context;
              try {
                showStatusSnackBar(currentCtx, message: 'Sedang mencetak struk...', type: SnackbarType.success);
                await PrinterService().printTransaction(transaction, storeSettings);
              } catch (e) {
                if (!currentCtx.mounted) return;
                showStatusSnackBar(currentCtx, message: 'Gagal mencetak: $e', type: SnackbarType.error);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _shareWhatsApp(Transaction? transaction) async {
    try {
      final image = await _screenshotController.captureFromWidget(_buildStrukContent(transaction));
      final directory = await getTemporaryDirectory();
      final imagePath = File('${directory.path}/struk_share.png');
      await imagePath.writeAsBytes(image);

      final total = _currencyFormat.format(transaction?.total ?? 0);
      final date = DateFormat('dd/MM/yyyy, HH:mm').format(transaction?.date ?? DateTime.now());
      final text = 'Terimakasih telah belanja sebesar $total, pada $date di Depot Kayu Kembang Jaya';

      await SharePlus.instance.share(
        ShareParams(files: [XFile(imagePath.path)], text: text),
      );
    } catch (e) {
      if (mounted) {
        showStatusSnackBar(context, message: 'Gagal membagikan struk', type: SnackbarType.error);
        debugPrint('Share error: $e');
      }
    }
  }

  Future<void> _downloadStruk(Transaction? transaction) async {
    try {
      final image = await _screenshotController.captureFromWidget(_buildStrukContent(transaction));
      final result = await ImageGallerySaverPlus.saveImage(
        image, 
        name: 'struk_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      if (mounted) {
        if (result['isSuccess'] == true) {
          showStatusSnackBar(context, message: 'Struk berhasil disimpan ke Galeri', type: SnackbarType.success);
        } else {
          showStatusSnackBar(context, message: 'Gagal menyimpan struk: ${result['errorMessage']}', type: SnackbarType.error);
        }
      }
    } catch (e) {
      if (mounted) {
        showStatusSnackBar(context, message: 'Gagal menyimpan struk', type: SnackbarType.error);
        debugPrint('Download error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaction = ModalRoute.of(context)?.settings.arguments as Transaction?;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingLG),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: context.colorSuccess.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: context.colorSuccess,
                  size: 80,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLG),
              Text(
                'Pembayaran Berhasil!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.colorTextPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingSM),
              Text(
                'Transaksi telah disimpan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: context.colorTextSecondary,
                ),
              ),
              const Spacer(),
              AppButton(
                label: 'Cetak Struk (Bluetooth)',
                isFullWidth: true,
                onPressed: () => _showPreviewStruk(transaction),
              ),
              const SizedBox(height: AppDimensions.spacingMD),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'WhatsApp',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => _shareWhatsApp(transaction),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingMD),
                  Expanded(
                    child: AppButton(
                      label: 'Simpan',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => _downloadStruk(transaction),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingMD),
              TextButton(
                onPressed: _finishTransaction,
                child: const Text('Tutup Transaksi', style: TextStyle(fontSize: 16)),
              ),
            ],
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
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(decoration: BoxDecoration(color: Colors.black45)),
            );
          }),
        );
      },
    );
  }
}