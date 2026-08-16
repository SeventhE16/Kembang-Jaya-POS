import 'dart:io';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/status_dialog.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/product_model.dart';
import '../../data/providers/settings_provider.dart';
import '../../core/services/printer_service.dart';
import 'package:depot_kayu_app/core/extensions/context_colors.dart';

class StrukScreen extends StatefulWidget {
  const StrukScreen({super.key});

  @override
  State<StrukScreen> createState() => _StrukScreenState();
}

class _StrukScreenState extends State<StrukScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Konten struk diekstrak ke method terpisah agar bisa dipakai
  // untuk tampilan layar DAN captureFromWidget (pola sama seperti confirmation_screen)
  Widget _buildStrukContent(Transaction transaction) {
    final settings = Provider.of<SettingsProvider>(context, listen: false).settings;
    final storeName = (settings as dynamic)?.name ?? 'KEMBANG JAYA';
    final storeAddress = (settings as dynamic)?.address ?? '';
    final storePhone = (settings as dynamic)?.phone ?? '';
    final logoUrl = (settings as dynamic)?.logoUrl;

    return Container(
      width: 320,
      padding: const EdgeInsets.all(AppDimensions.spacingMD),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo
          if (logoUrl != null && logoUrl.isNotEmpty)
            AppLogo(logoUrl: logoUrl, height: 60, width: 60)
          else
            Icon(Icons.store, size: 60, color: context.colorTextPrimary),

          const SizedBox(height: AppDimensions.spacingSM),

          // Nama toko
          Text(
            storeName.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Alamat & telepon
          if (storeAddress.isNotEmpty || storePhone.isNotEmpty)
            Text(
              [
                if (storeAddress.isNotEmpty) storeAddress,
                if (storePhone.isNotEmpty) 'Telp: $storePhone',
              ].join('\n'),
              style: TextStyle(fontSize: 12, color: context.colorTextSecondary),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: AppDimensions.spacingMD),
          const _DashedDivider(),
          const SizedBox(height: AppDimensions.spacingMD),

          // Tanggal & kasir
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMM yyyy HH:mm').format(transaction.date),
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                'Kasir: ${transaction.cashierName}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingMD),
          const _DashedDivider(),
          const SizedBox(height: AppDimensions.spacingMD),

          // Item barang
          ...transaction.items.expand((item) {
            final name = item.product.name
                .replaceAll(RegExp(r'\s*Grade.*', caseSensitive: false), '');
            final widgets = <Widget>[];

            // Tampilan grosir+ecer jika berlaku
            if (item.customPrice == null &&
                item.product.wholesalePrices.isNotEmpty) {
              final sortedTiers =
                  List<WholesalePrice>.from(item.product.wholesalePrices)
                    ..sort((a, b) => b.minQty.compareTo(a.minQty));
              final tier = sortedTiers.first;

              if (item.quantity >= tier.minQty) {
                final wholesaleQty =
                    (item.quantity ~/ tier.minQty) * tier.minQty;
                final remainderQty = item.quantity % tier.minQty;

                widgets.add(Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ));
                widgets.add(Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$wholesaleQty x ${_currencyFormat.format(tier.price - item.itemDiscount)} (grosir)',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        _currencyFormat.format(
                            wholesaleQty * (tier.price - item.itemDiscount)),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ));
                if (remainderQty > 0) {
                  widgets.add(Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppDimensions.spacingSM),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$remainderQty x ${_currencyFormat.format(item.product.sellPrice - item.itemDiscount)} (ecer)',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          _currencyFormat.format(remainderQty *
                              (item.product.sellPrice - item.itemDiscount)),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ));
                } else {
                  widgets.add(const SizedBox(height: AppDimensions.spacingSM));
                }
                return widgets;
              }
            }

            // Default: item biasa (1 baris)
            widgets.add(Padding(
              padding:
                  const EdgeInsets.only(bottom: AppDimensions.spacingSM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item.quantity} x ${_currencyFormat.format(item.unitPrice - item.itemDiscount)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        _currencyFormat.format(item.subtotal),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ));
            return widgets;
          }),

          const SizedBox(height: AppDimensions.spacingSM),
          const _DashedDivider(),
          const SizedBox(height: AppDimensions.spacingMD),

          // Sub Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sub Total', style: TextStyle(fontSize: 13)),
              Text(_currencyFormat.format(transaction.subtotal),
                  style: const TextStyle(fontSize: 13)),
            ],
          ),

          if (transaction.extraDiscount > 0 || transaction.discount != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Diskon', style: TextStyle(fontSize: 13)),
                  Text(
                    '- ${_currencyFormat.format(transaction.extraDiscount + (transaction.discount?.value ?? 0))}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),

          if (transaction.extraFee > 0 || transaction.fee != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    transaction.fee?.name ?? 'Biaya',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    '+ ${_currencyFormat.format(transaction.extraFee + (transaction.fee?.value ?? 0))}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppDimensions.spacingSM),

          // TOTAL
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                _currencyFormat.format(transaction.total),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Bayar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Bayar (${transaction.paymentMethod})',
                  style: const TextStyle(fontSize: 13)),
              Text(_currencyFormat.format(transaction.payAmount),
                  style: const TextStyle(fontSize: 13)),
            ],
          ),

          if (transaction.debtAmount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sisa Hutang',
                      style:
                          TextStyle(fontSize: 13, color: context.colorError)),
                  Text(
                    _currencyFormat.format(transaction.debtAmount),
                    style: TextStyle(
                        fontSize: 13, color: context.colorError),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppDimensions.spacingMD),
          const _DashedDivider(),
          const SizedBox(height: AppDimensions.spacingMD),

          // Footer
          Text(
            'Terimakasih telah berbelanja di Depot Kayu\nKembang Jaya',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 12, color: context.colorTextSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadReceipt(Transaction transaction) async {
    try {
      final image = await _screenshotController.captureFromWidget(
        _buildStrukContent(transaction),
        context: context,
        pixelRatio: 2.0,
      );
      final result = await ImageGallerySaverPlus.saveImage(
        image,
        name: 'struk_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (mounted) {
        if (result['isSuccess'] == true) {
          showStatusSnackBar(context,
              message: 'Struk berhasil disimpan ke Galeri',
              type: SnackbarType.success);
        } else {
          showStatusSnackBar(context,
              message: 'Gagal menyimpan struk ke galeri',
              type: SnackbarType.error);
        }
      }
    } catch (e) {
      debugPrint('Download error: $e');
      if (mounted) {
        showStatusSnackBar(context,
            message: 'Gagal menyimpan struk', type: SnackbarType.error);
      }
    }
  }

  Future<void> _shareReceipt(Transaction transaction) async {
    try {
      final image = await _screenshotController.captureFromWidget(
        _buildStrukContent(transaction),
        context: context,
        pixelRatio: 2.0,
      );
      final directory = await getTemporaryDirectory();
      final imagePath = File(
          '${directory.path}/struk_share_${DateTime.now().millisecondsSinceEpoch}.png');
      await imagePath.writeAsBytes(image);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(imagePath.path)],
          text: 'Terima kasih telah berbelanja di toko kami!',
        ),
      );
    } catch (e) {
      debugPrint('Share error: $e');
      if (mounted) {
        showStatusSnackBar(context,
            message: 'Gagal membagikan struk', type: SnackbarType.error);
      }
    }
  }

  Future<void> _printReceipt(Transaction transaction) async {
    if (!PrinterService().isConnected) {
      if (mounted) {
        showStatusSnackBar(context,
            message: 'Printer belum terhubung. Silakan atur di Pengaturan.',
            type: SnackbarType.error);
      }
      return;
    }
    final settings =
        Provider.of<SettingsProvider>(context, listen: false).settings;
    try {
      if (mounted) {
        showStatusSnackBar(context,
            message: 'Sedang mencetak struk...', type: SnackbarType.success);
      }
      await PrinterService().printTransaction(transaction, settings);
    } catch (e) {
      debugPrint('Print error: $e');
      if (mounted) {
        showStatusSnackBar(context,
            message: 'Gagal mencetak struk', type: SnackbarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaction =
        ModalRoute.of(context)?.settings.arguments as Transaction?;
    if (transaction == null) {
      return const Scaffold(
          body: Center(child: Text('Data transaksi tidak ditemukan')));
    }

    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: AppBar(
        title: const Text('Struk Pembayaran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareReceipt(transaction),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadReceipt(transaction),
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
          child: Screenshot(
            controller: _screenshotController,
            child: _buildStrukContent(transaction),
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
        const dashWidth = 4.0;
        const dashSpace = 3.0;
        final dashCount =
            (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration:
                    BoxDecoration(color: context.colorTextSecondary),
              ),
            );
          }),
        );
      },
    );
  }
}