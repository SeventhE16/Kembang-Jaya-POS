import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Shows a top snackbar for success or error feedback
void showStatusSnackBar(
  BuildContext context, {
  required String message,
  required bool isSuccess,
}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: isSuccess ? AppColors.success : AppColors.errorBackground,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height - 150,
        left: 16,
        right: 16,
      ),
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 12),

            // Dashed line
            _dashedLine(),
            const SizedBox(height: 8),

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
            const SizedBox(height: 8),
            _dashedLine(),
            const SizedBox(height: 8),

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
            const SizedBox(height: 8),

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
            const SizedBox(height: 8),
            _dashedLine(),
            const SizedBox(height: 12),

            const Text(
              'Terima kasih atas kunjungan Anda! Barang\nyang sudah dibeli tidak dapat\ndikembalikan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),

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
            child: const DecoratedBox(
              decoration: BoxDecoration(color: AppColors.textSecondary),
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
