import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_text_field.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/providers/fee_provider.dart';
import '../../data/models/fee_model.dart';
import '../../core/widgets/status_dialog.dart';
import 'add_fee_screen.dart';
import 'package:depot_kayu_app/core/extensions/context_colors.dart';

class FeeScreen extends StatefulWidget {
  const FeeScreen({super.key});

  @override
  State<FeeScreen> createState() => _FeeScreenState();
}

class _FeeScreenState extends State<FeeScreen> {
  Future<void> _navigateToAddFee() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddFeeScreen()),
    );
    if (result == true) {
      setState(() {});
    }
  }

  void _showEditFeeDialog(Fee fee) {
    final nameController = TextEditingController(text: fee.name);
    final valueController = TextEditingController(text: fee.value.toInt().toString());

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radius)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spacingLG),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Biaya',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingMD),
              AppTextField(
                label: 'Nama Biaya',
                hint: 'mis. Biaya Antar',
                controller: nameController,
              ),
              const SizedBox(height: AppDimensions.spacingMD),
              AppTextField(
                label: 'Nilai (Rp)',
                controller: valueController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppDimensions.spacingLG),
              AppButton(
                label: 'Simpan',
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    Navigator.pop(ctx);
                    showStatusSnackBar(
                      context,
                      message: 'Nama biaya wajib diisi',
                      type: SnackbarType.error,
                    );
                    return;
                  }
                  final value = double.tryParse(valueController.text) ?? 0;
                  if (value < 0) {
                    Navigator.pop(ctx);
                    showStatusSnackBar(
                      context,
                      message: 'Nilai biaya tidak boleh negatif',
                      type: SnackbarType.error,
                    );
                    return;
                  }

                  final updatedFee = Fee(
                    id: fee.id,
                    name: nameController.text.trim(),
                    value: value,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                  );
                  
                  await Provider.of<FeeProvider>(context, listen: false).updateFee(updatedFee);
                  
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  showStatusSnackBar(
                    context,
                    message: 'Biaya diperbarui',
                    type: SnackbarType.success,
                  );
                },
              ),
              const SizedBox(height: AppDimensions.spacingSM),
              AppButton(
                label: 'Batal',
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteFee(Fee fee) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus ${fee.name}?'),
        content: const Text('Data yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<FeeProvider>(context, listen: false).deleteFee(fee.id);
              
              if (!mounted) return;
              showStatusSnackBar(
                context,
                message: '${fee.name} dihapus',
                type: SnackbarType.success,
              );
            },
            child: Text('Hapus', style: TextStyle(color: context.colorError)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Daftar Biaya',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SafeArea(
        child: Consumer<FeeProvider>(
          builder: (context, provider, child) {
            final fees = provider.fees;
            return Column(
              children: [
                const Divider(height: 1),
                if (provider.isLoading)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else
                  Expanded(
                    child: fees.isEmpty
                        ? AppEmptyState(
                            icon: Icons.payments_outlined,
                            title: 'Belum ada biaya',
                            subtitle: 'Tambah opsi biaya (mis. ongkir, potong)',
                            action: AppButton(
                              label: 'Tambah Biaya',
                              onPressed: _navigateToAddFee,
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppDimensions.spacingMD),
                            itemCount: fees.length,
                            separatorBuilder: (context, index) => const SizedBox(height: AppDimensions.spacingMD),
                            itemBuilder: (context, index) {
                              final fee = fees[index];
                              return Container(
                                padding: const EdgeInsets.all(AppDimensions.spacingMD),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(AppDimensions.radius),
                                  border: Border.all(
                                    color: context.colorDivider,
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(AppDimensions.spacingMD),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.payments_outlined, color: Colors.blue.shade600),
                                    ),
                                    const SizedBox(width: AppDimensions.spacingMD),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fee.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(fee.value)}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: context.colorTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.edit_outlined, color: context.colorPrimary),
                                      onPressed: () => _showEditFeeDialog(fee),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline, color: context.colorError),
                                      onPressed: () => _deleteFee(fee),
                                    ),
                                  ],
                                ),
                              );
                            },
                    ),
            ),
          ],
        );
       },
      ),
      ),
      floatingActionButton: Provider.of<FeeProvider>(context).fees.isNotEmpty
          ? FloatingActionButton(
              onPressed: _navigateToAddFee,
              backgroundColor: context.colorPrimary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}





