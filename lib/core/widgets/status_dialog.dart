import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

import '../constants/app_dimensions.dart';
import 'package:depot_kayu_app/core/extensions/context_colors.dart';

enum SnackbarType { success, error, warning }

/// Shows a top snackbar for success, error, or warning feedback
void showStatusSnackBar(
  BuildContext context, {
  required String message,
  required SnackbarType type,
  VoidCallback? onUndo,
}) {
  final theme = Theme.of(context);
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  
  // Clean up error messages: remove "Exception: " and "[firebase_auth/...]" codes
  String cleanMsg = message.replaceAll('Exception: ', '');
  cleanMsg = cleanMsg.replaceAll(RegExp(r'\[.*?\]\s*'), '').trim();
  
  Color backgroundColor;
  IconData iconData;
  
  switch (type) {
    case SnackbarType.success:
      backgroundColor = context.colorSuccess;
      iconData = Icons.check_circle;
      break;
    case SnackbarType.error:
      backgroundColor = theme.colorScheme.error;
      iconData = Icons.error;
      break;
    case SnackbarType.warning:
      backgroundColor = context.colorWarning;
      iconData = Icons.warning;
      break;
  }
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            iconData,
            color: Colors.white,
            size: AppDimensions.iconSize,
          ),
          const SizedBox(width: AppDimensions.spacingSM),
          Expanded(
            child: Text(
              cleanMsg,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(
        bottom: AppDimensions.spacingMD,
        left: AppDimensions.spacingMD,
        right: AppDimensions.spacingMD,
      ),
      duration: const Duration(seconds: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusSM)),
      action: onUndo != null
          ? SnackBarAction(
              label: 'UNDO',
              textColor: Colors.white,
              onPressed: onUndo,
            )
          : null,
    ),
  );
}

/// Shows a receipt-style dialog for sales success
void showReceiptDialog(
  BuildContext context, {
  required String transactionNo,
  required String cashier,
  required List<Map<String, dynamic>> items,
  required double total,
  VoidCallback? onPrint,
}) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: const Icon(Icons.close, size: 22),
              ),
            ),

            // Store info
            const Text(
              'Depot Kayu Kembang Jaya Jl. Raya\nIndustri No. 12, Sidoarjo',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: AppDimensions.spacingMD),

            // Dashed line
            _dashedLine(),
            const SizedBox(height: AppDimensions.spacingSM),

            // Transaction info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('No', style: TextStyle(fontSize: 12)),
                Text(transactionNo, style: const TextStyle(fontSize: 12)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kasir', style: TextStyle(fontSize: 12)),
                Text(cashier, style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingSM),
            _dashedLine(),
            const SizedBox(height: AppDimensions.spacingSM),

            // Items
            ...items.map((item) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item['qty']} x Rp ${_formatNum((item['price'] as num).toInt())}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Rp ${_formatNum((item['subtotal'] as num).toInt())}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            )),

            const SizedBox(height: 4),
            _dashedLine(),
            const SizedBox(height: AppDimensions.spacingSM),

            // Totals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Qty', style: TextStyle(fontSize: 12)),
                Text(
                  items.fold<int>(0, (sum, item) => sum + (item['qty'] as int)).toString(),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: TextStyle(fontSize: 12)),
                Text('Rp ${_formatNum(total.toInt())}', style: const TextStyle(fontSize: 12)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                Text(
                  'Rp ${_formatNum(total.toInt())}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingSM),
            _dashedLine(),
            const SizedBox(height: AppDimensions.spacingMD),

            Text(
              'Terima kasih atas kunjungan Anda! Barang\nyang sudah dibeli tidak dapat\ndikembalikan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: context.colorTextSecondary, height: 1.4),
            ),
            const SizedBox(height: AppDimensions.spacingMD),

            // Print button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onPrint?.call();
                },
                child: const Text('Cetak Struk'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _dashedLine() {
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
            child: DecoratedBox(
              decoration: BoxDecoration(color: context.colorTextSecondary),
            ),
          );
        }),
      );
    },
  );
}

String _formatNum(int number) {
  return number.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]}.',
  );
}