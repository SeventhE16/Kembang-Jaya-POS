import 'package:flutter/material.dart';
import '../../data/providers/audit_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_routes.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_customer_picker.dart';
import '../../core/widgets/status_dialog.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/discount_model.dart';
import '../../data/models/fee_model.dart';
import 'package:provider/provider.dart';
import '../../data/providers/cart_provider.dart';
import '../../data/providers/transaction_provider.dart';
import '../../data/providers/discount_provider.dart';
import '../../data/providers/fee_provider.dart';
import 'package:intl/intl.dart';
import 'package:depot_kayu_app/core/extensions/context_colors.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  CartProvider get _cart => Provider.of<CartProvider>(context, listen: false);
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String _payAmountStr = '';
  String _paymentMethod = 'Tunai';
  final List<String> _methods = ['Tunai', 'QRIS', 'Transfer'];
  bool _isPiutang = false;
  DateTime? _dueDate;

  /// Apakah saat ini sedang dalam mode edit transaksi
  bool get _isEditMode => _cart.editingTransactionId != null;

  /// Total uang yang sudah dibayar customer (DP awal + semua cicilan) untuk transaksi kasbon
  double get _totalAlreadyPaid {
    final oldTx = _cart.editingTransactionOriginal;
    if (oldTx == null) return 0;
    // payAmount di transaksi kasbon sudah termasuk DP + cicilan yang telah dibayar
    return oldTx.payAmount;
  }

  double get _subtotal {
    return _cart.activeCart.values.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  double get _discountAmount {
    double amt = _cart.activeExtraDiscount;
    if (_cart.activeDiscount != null) {
      if (_cart.activeDiscount!.type == DiscountType.nominal) {
        amt += _cart.activeDiscount!.value;
      } else {
        amt += _subtotal * (_cart.activeDiscount!.value / 100);
      }
    }
    return amt;
  }

  double get _feeAmount {
    double amt = _cart.activeExtraFee;
    if (_cart.activeFee != null) {
      amt += _cart.activeFee!.value;
    }
    return amt;
  }

  double get _totalToPay {
    return _subtotal - _discountAmount + _feeAmount;
  }

  double get _payAmount {
    if (_payAmountStr.isEmpty) return 0;
    return double.tryParse(_payAmountStr) ?? 0;
  }

  double get _change {
    return _payAmount - _totalToPay;
  }

  void _onNumpadTap(String value) {
    setState(() {
      if (value == 'C') {
        _payAmountStr = '';
      } else if (value == 'DEL') {
        if (_payAmountStr.isNotEmpty) {
          _payAmountStr = _payAmountStr.substring(0, _payAmountStr.length - 1);
        }
      } else {
        if (_payAmountStr == '0' && value != '000') {
          _payAmountStr = value;
        } else {
          _payAmountStr += value;
        }
      }
    });
  }

  void _addShortcut(double amount) {
    setState(() {
      if (_payAmountStr.isEmpty) {
        _payAmountStr = amount.toInt().toString();
      } else {
        final current = double.tryParse(_payAmountStr) ?? 0;
        _payAmountStr = (current + amount).toInt().toString();
      }
    });
  }

  void _showCustomerPicker() async {
    final customer = await AppCustomerPicker.show(context, selectedCustomer: _cart.activeCustomer);
    if (customer != null) {
      setState(() {
        _cart.setCustomer(customer);
      });
    }
  }

  void _showNotePicker() {
    final controller = TextEditingController(text: _cart.activeNote);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keterangan Transaksi'),
        content: AppTextField(
          controller: controller,
          hint: 'Keterangan (opsional)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: context.colorTextSecondary)),
          ),
          AppButton(
            label: 'Simpan',
            onPressed: () {
              setState(() {
                _cart.setNote(controller.text.trim().isEmpty ? null : controller.text.trim());
              });
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _showDiscountPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pilih Diskon', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Tanpa Diskon'),
              onTap: () {
                setState(() {
                  _cart.setDiscount(null);
                  _cart.setExtraDiscount(0);
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Diskon Manual (Nominal)'),
              trailing: const Icon(Icons.edit, size: 16),
              onTap: () {
                Navigator.pop(ctx);
                _showCustomDiscountDialog();
              },
            ),
            ...Provider.of<DiscountProvider>(context, listen: false).discounts.map((d) => ListTile(
              title: Text(d.name),
              subtitle: Text(d.type == DiscountType.nominal 
                ? 'Rp ${d.value.toInt()}' 
                : '${d.value.toInt()}%'),
              onTap: () {
                setState(() {
                  _cart.setDiscount(d);
                  _cart.setExtraDiscount(0);
                });
                Navigator.pop(ctx);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showCustomDiscountDialog() {
    final TextEditingController ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Diskon Manual'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Nominal Diskon (Rp)',
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              setState(() {
                _cart.setDiscount(null);
                _cart.setExtraDiscount(val);
              });
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showFeePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pilih Biaya Tambahan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Tanpa Biaya Tambahan'),
              onTap: () {
                setState(() {
                  _cart.setFee(null);
                  _cart.setExtraFee(0);
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Biaya Manual (Nominal)'),
              trailing: const Icon(Icons.edit, size: 16),
              onTap: () {
                Navigator.pop(ctx);
                _showCustomFeeDialog();
              },
            ),
            ...Provider.of<FeeProvider>(context, listen: false).fees.map((f) => ListTile(
              title: Text(f.name),
              subtitle: Text('Rp ${_currencyFormat.format(f.value).replaceAll('Rp', '').trim()}'),
              onTap: () {
                setState(() {
                  _cart.setFee(f);
                  _cart.setExtraFee(0);
                });
                Navigator.pop(ctx);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showCustomFeeDialog() {
    final TextEditingController nameCtrl = TextEditingController(text: 'Biaya Tambahan');
    final TextEditingController amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Biaya Manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Biaya',
                hintText: 'mis. Ongkir, Biaya Angkut',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nominal Biaya (Rp)',
                prefixText: 'Rp ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              final name = nameCtrl.text.trim().isEmpty ? 'Biaya Tambahan' : nameCtrl.text.trim();
              if (val <= 0) {
                Navigator.pop(ctx);
                return;
              }
              // Buat Fee baru dan simpan ke Firestore (menu Biaya)
              final newFee = Fee(
                id: 'F${DateTime.now().millisecondsSinceEpoch}',
                name: name,
                value: val,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              await Provider.of<FeeProvider>(context, listen: false).addFee(newFee);
              setState(() {
                _cart.setFee(newFee);
                _cart.setExtraFee(0);
              });
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  bool _isLoading = false;

  Future<void> _processPayment() async {
    if (_isPiutang && _cart.activeCustomer == null) {
      showStatusSnackBar(context, message: 'Piutang/Kasbon wajib memilih Pelanggan', type: SnackbarType.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentCtx = context;
      final transactionProv = Provider.of<TransactionProvider>(context, listen: false);
      final auditProv = Provider.of<AuditProvider>(context, listen: false);

      if (_isEditMode) {
        // ===== MODE EDIT =====
        final oldTx = _cart.editingTransactionOriginal!;
        final editingId = _cart.editingTransactionId!;

        final debt = _isPiutang ? (_totalToPay - _payAmount).clamp(0.0, double.infinity) : 0.0;
        final newTx = Transaction(
          id: editingId,
          invoiceNumber: oldTx.invoiceNumber, // Pertahankan nomor nota asli
          type: oldTx.type,
          items: _cart.activeCart.values.toList(),
          customerName: _cart.activeCustomer?.name ?? oldTx.customerName,
          cashierName: oldTx.cashierName,
          subtotal: _subtotal,
          discount: _cart.activeDiscount,
          extraDiscount: _cart.activeExtraDiscount,
          fee: _cart.activeFee,
          extraFee: _cart.activeExtraFee,
          total: _totalToPay,
          createdAt: oldTx.createdAt,
          updatedAt: DateTime.now(),
          paymentMethod: _isPiutang ? 'Kasbon' : _paymentMethod,
          payAmount: _payAmount,
          debtAmount: debt,
          date: oldTx.date, // Pertahankan tanggal asli
        );

        final finalTx = await transactionProv.updateTransactionWithReconciliation(
          oldTx: oldTx,
          newTx: newTx,
          totalAlreadyPaid: _totalAlreadyPaid,
        );

        await auditProv.logAction('Edit Transaksi', 'Edit nota ${oldTx.invoiceNumber ?? oldTx.id}: total baru Rp${finalTx.total}');

        if (!currentCtx.mounted) return;
        Navigator.pushReplacementNamed(currentCtx, AppRoutes.confirmation, arguments: finalTx);
      } else {
        // ===== TRANSAKSI BARU =====
        final debt = _isPiutang ? (_totalToPay - _payAmount) : 0.0;

        final transaction = Transaction(
          id: 'TRX-${DateTime.now().millisecondsSinceEpoch}',
          items: _cart.activeCart.values.toList(),
          customerName: _cart.activeCustomer?.name,
          cashierName: 'Admin',
          subtotal: _subtotal,
          discount: _cart.activeDiscount,
          extraDiscount: _cart.activeExtraDiscount,
          fee: _cart.activeFee,
          extraFee: _cart.activeExtraFee,
          total: _totalToPay,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          paymentMethod: _isPiutang ? 'Kasbon' : _paymentMethod,
          payAmount: _payAmount,
          debtAmount: debt < 0 ? 0 : debt,
          date: DateTime.now(),
        );

        await transactionProv.addTransaction(transaction);
        await auditProv.logAction('Transaksi Baru', 'Kasir Admin menerima pembayaran Rp${transaction.total} via ${transaction.paymentMethod}');

        if (!currentCtx.mounted) return;
        Navigator.pushReplacementNamed(currentCtx, AppRoutes.confirmation, arguments: transaction);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showStatusSnackBar(context, message: 'Gagal memproses pembayaran: $e', type: SnackbarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Di mode edit, jika uang yang sudah masuk sebelumnya (totalAlreadyPaid) 
    // sudah menutupi total tagihan baru, maka bisa langsung dibayar.
    final bool canPay = (_isPiutang || _payAmount >= _totalToPay || (_isEditMode && _totalAlreadyPaid >= _totalToPay)) && !_isLoading;
    final bool isEdit = _isEditMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Transaksi - Pembayaran' : 'Nominal Pembayaran',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Banner Mode Edit
            if (isEdit)
              Container(
                width: double.infinity,
                color: context.colorPrimary.withValues(alpha: 0.12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 16, color: context.colorPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mode Edit — Nota: ${_cart.editingTransactionOriginal?.invoiceNumber ?? _cart.editingTransactionId}'
                        + (_totalAlreadyPaid > 0
                            ? '  |  Sudah dibayar: ${_currencyFormat.format(_totalAlreadyPaid)}'
                            : ''),
                        style: TextStyle(fontSize: 12, color: context.colorPrimary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.spacingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Customer & Note Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _showCustomerPicker,
                            borderRadius: BorderRadius.circular(AppDimensions.radius),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: context.colorDivider),
                                borderRadius: BorderRadius.circular(AppDimensions.radius),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.person_outline, color: context.colorTextSecondary, size: 20),
                                  const SizedBox(width: AppDimensions.spacingSM),
                                  Expanded(
                                    child: Text(
                                      _cart.activeCustomer?.name ?? 'Tambah Pelanggan',
                                      style: TextStyle(color: context.colorTextPrimary, fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingMD),
                        Expanded(
                          child: InkWell(
                            onTap: _showNotePicker,
                            borderRadius: BorderRadius.circular(AppDimensions.radius),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: context.colorDivider),
                                borderRadius: BorderRadius.circular(AppDimensions.radius),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.edit_note, color: context.colorTextSecondary, size: 20),
                                  const SizedBox(width: AppDimensions.spacingSM),
                                  Expanded(
                                    child: Text(
                                      _cart.activeNote ?? 'Keterangan',
                                      style: TextStyle(color: context.colorTextPrimary, fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 32, thickness: 1, color: context.colorDivider),
                    
                    // Clean Total and Change info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Tagihan', style: TextStyle(fontSize: 16, color: context.colorTextPrimary)),
                        Text(
                          _currencyFormat.format(_totalToPay),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colorPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_discountAmount > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Diskon', style: TextStyle(fontSize: 14, color: context.colorTextSecondary)),
                          Text(
                            '- ${_currencyFormat.format(_discountAmount)}',
                            style: const TextStyle(fontSize: 14, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_feeAmount > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Biaya Tambahan', style: TextStyle(fontSize: 14, color: context.colorTextSecondary)),
                          Text(
                            '+ ${_currencyFormat.format(_feeAmount)}',
                            style: const TextStyle(fontSize: 14, color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                    Divider(height: 24, thickness: 1, color: context.colorDivider),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Kembalian', style: TextStyle(fontSize: 16, color: context.colorTextPrimary)),
                        Text(
                          _change >= 0 ? _currencyFormat.format(_change) : 'Rp 0',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colorTextPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingLG),

                    // Payment Actions & Piutang Checkbox
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isPiutang = !_isPiutang;
                              });
                            },
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _isPiutang,
                                    activeColor: context.colorPrimary,
                                    onChanged: (val) {
                                      setState(() {
                                        _isPiutang = val ?? false;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Piutang', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: OutlinedButton(
                            onPressed: _showDiscountPicker,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              minimumSize: const Size(0, 32),
                              side: BorderSide(color: context.colorPrimary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('+ Diskon', style: TextStyle(fontSize: 12, color: context.colorPrimary)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: OutlinedButton(
                            onPressed: _showFeePicker,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              minimumSize: const Size(0, 32),
                              side: BorderSide(color: context.colorPrimary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('+ Biaya', style: TextStyle(fontSize: 12, color: context.colorPrimary)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingMD),
                    const Text('Metode Pembayaran (DP / Lunas)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppDimensions.spacingMD),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _methods.map((method) {
                          final isSelected = method == _paymentMethod;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                method,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : context.colorTextPrimary,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) setState(() => _paymentMethod = method);
                              },
                              backgroundColor: context.colorChipInactive,
                              selectedColor: context.colorPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radius)),
                              side: BorderSide.none,
                              showCheckmark: false,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (_isPiutang) ...[
                      const SizedBox(height: AppDimensions.spacingMD),
                      Row(
                        children: [
                          const Icon(Icons.event, size: 20, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Text('Jatuh Tempo:', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final selected = await showDatePicker(
                                  context: context,
                                  initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                                );
                                if (selected != null) {
                                  setState(() => _dueDate = selected);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.orange),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _dueDate != null ? DateFormat('dd MMM yyyy').format(_dueDate!) : 'Pilih Tanggal (Opsional)',
                                  style: TextStyle(color: _dueDate != null ? context.colorTextPrimary : context.colorTextSecondary),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: AppDimensions.spacingLG),
                    // Uang Dibayar Display
                    const Text('Uang Pelanggan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppDimensions.spacingMD),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: context.colorInputFill,
                        borderRadius: BorderRadius.circular(AppDimensions.radius),
                      ),
                      alignment: Alignment.centerRight,
                      child: Text(
                        _payAmountStr.isEmpty ? 'Rp 0' : _currencyFormat.format(_payAmount),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: context.colorTextPrimary),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingMD),
                    // Custom Numpad Layout
                    Column(
                      children: [
                        Row(
                          children: [
                            _buildNumpadButton('1'), const SizedBox(width: AppDimensions.spacingSM),
                            _buildNumpadButton('2'), const SizedBox(width: AppDimensions.spacingSM),
                            _buildNumpadButton('3'), const SizedBox(width: AppDimensions.spacingSM),
                            _buildNumpadButton('C', color: context.colorError),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacingSM),
                        Row(
                          children: [
                            _buildNumpadButton('4'), const SizedBox(width: AppDimensions.spacingSM),
                            _buildNumpadButton('5'), const SizedBox(width: AppDimensions.spacingSM),
                            _buildNumpadButton('6'), const SizedBox(width: AppDimensions.spacingSM),
                            _buildNumpadButton('DEL', icon: Icons.backspace_outlined),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacingSM),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      _buildNumpadButton('7'), const SizedBox(width: AppDimensions.spacingSM),
                                      _buildNumpadButton('8'), const SizedBox(width: AppDimensions.spacingSM),
                                      _buildNumpadButton('9'),
                                    ],
                                  ),
                                  const SizedBox(height: AppDimensions.spacingSM),
                                  Row(
                                    children: [
                                      _buildNumpadButton('0'), const SizedBox(width: AppDimensions.spacingSM),
                                      _buildNumpadButton('000'), const SizedBox(width: AppDimensions.spacingSM),
                                      _buildNumpadButton('AUTO', icon: Icons.payments_outlined, color: context.colorPrimary),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spacingSM),
                            Expanded(
                              flex: 1,
                              child: _buildNumpadButton('PAS', color: Colors.white, bgColor: context.colorPrimary, height: 116),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          
            // Bottom Pay Button
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingMD),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: AppButton(
                label: 'BAYAR',
                isFullWidth: true,
                onPressed: canPay ? _processPayment : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAutoOptions() {
    final options = [10000, 20000, 50000, 100000, 200000, 500000, 1000000];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tambah Nominal Cepat',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingLG),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: options.map((amount) => InkWell(
                onTap: () {
                  _addShortcut(amount.toDouble());
                  Navigator.pop(ctx);
                },
                borderRadius: BorderRadius.circular(AppDimensions.radius),
                child: Container(
                  width: (MediaQuery.of(context).size.width - 48) / 3,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: context.colorChipInactive,
                    borderRadius: BorderRadius.circular(AppDimensions.radius),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '+${_currencyFormat.format(amount).replaceAll('Rp', '').trim()}',
                    style: TextStyle(fontWeight: FontWeight.w600, color: context.colorTextPrimary),
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpadButton(String value, {Color? color, Color? bgColor, IconData? icon, double height = 54}) {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (value == 'AUTO') {
            _showAutoOptions();
          } else if (value == 'PAS') {
            setState(() { _payAmountStr = _totalToPay.toInt().toString(); });
          } else {
            _onNumpadTap(value);
          }
        },
        borderRadius: BorderRadius.circular(AppDimensions.radius),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: bgColor ?? Colors.transparent,
            border: Border.all(color: bgColor ?? context.colorDivider),
            borderRadius: BorderRadius.circular(AppDimensions.radius),
          ),
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, color: color ?? context.colorTextPrimary, size: 28)
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: color ?? context.colorTextPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}