import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../../core/widgets/app_logo.dart';
import '../../data/models/transaction_model.dart';
import '../../core/services/settings_service.dart';
import '../../data/models/user_model.dart';

class StrukGenerator {
  static Widget buildStrukContent({
    required BuildContext context, 
    required Transaction transaction, 
    StoreSettings? settings,
    User? user,
    bool isRestock = false,
  }) {
    final cart = transaction.items;
    final subtotal = transaction.subtotal;
    final discount = transaction.extraDiscount;
    final fee = isRestock ? transaction.extraFee : (transaction.extraFee) + (transaction.fee?.value ?? 0);
    final feeName = transaction.fee?.name ?? 'Biaya';
    final total = transaction.total;
    final isCredit = transaction.paymentMethod == 'Kasbon' && transaction.debtAmount > 0;
    final date = DateFormat('yyyy-MM-dd HH:mm:ss').format(transaction.date);

    return MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Material(
          color: Colors.white,
          child: Container(
            color: Colors.white,
      width: 400,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (settings?.logoUrl != null && settings!.logoUrl!.isNotEmpty)
             AppLogo(logoUrl: settings.logoUrl!, height: 64, fit: BoxFit.contain)
          else
             const Icon(Icons.storefront, color: Colors.black54, size: 48),
          
          const SizedBox(height: 16),
          Text(
            settings?.name ?? 'TOKO',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
          ),
          if (settings?.address != null && settings!.address.isNotEmpty)
            Text(
              settings.address,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          if (settings?.phone != null && settings!.phone.isNotEmpty)
            Text(
              settings.phone,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          
          const SizedBox(height: 16),
          const _DashedDivider(),
          const SizedBox(height: 16),
          
          // Info Transaksi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date, style: const TextStyle(fontSize: 12, color: Colors.black87)),
              Text(transaction.invoiceNumber ?? '-', style: const TextStyle(fontSize: 12, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kasir: ${user?.name ?? transaction.cashierName}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
              if (isRestock)
                Text('Supplier: ${transaction.supplierName ?? "-"}', style: const TextStyle(fontSize: 12, color: Colors.black87))
              else
                Text('Cust: ${transaction.customerName ?? "-"}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
            ],
          ),
          
          const SizedBox(height: 16),
          const _DashedDivider(),
          const SizedBox(height: 16),
          
          // Items
          ...cart.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product.name, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.quantity} x ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(item.unitPrice)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      Text(NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(item.quantity * item.unitPrice), style: const TextStyle(fontSize: 14, color: Colors.black87)),
                    ],
                  ),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 8),
          const _DashedDivider(),
          const SizedBox(height: 16),
          
          // Totals
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: TextStyle(fontSize: 14, color: Colors.black54)),
              Text(NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(subtotal), style: const TextStyle(fontSize: 14, color: Colors.black87)),
            ],
          ),
          if (discount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Diskon', style: TextStyle(fontSize: 14, color: Colors.black54)),
                Text('-${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(discount)}', style: const TextStyle(fontSize: 14, color: Colors.black87)),
              ],
            ),
          ],
          if (fee > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(feeName, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                Text('+${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(fee)}', style: const TextStyle(fontSize: 14, color: Colors.black87)),
              ],
            ),
          ],
          
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              Text('Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(total)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bayar', style: TextStyle(fontSize: 14, color: Colors.black54)),
              Text(NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(transaction.payAmount), style: const TextStyle(fontSize: 14, color: Colors.black87)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isCredit ? 'Sisa Hutang' : 'Kembali', style: const TextStyle(fontSize: 14, color: Colors.black54)),
              Text(NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(isCredit ? transaction.debtAmount : (transaction.payAmount - total)), style: const TextStyle(fontSize: 14, color: Colors.black87)),
            ],
          ),
          
          const SizedBox(height: 32),
          const Text(
            'Terima Kasih',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
        ],
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
              child: DecoratedBox(decoration: BoxDecoration(color: Colors.black26)),
            );
          }),
        );
      },
    );
  }
}
