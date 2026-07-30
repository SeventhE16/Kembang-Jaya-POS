import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_dialog.dart';
import '../../data/dummy/dummy_data.dart';
import '../../data/models/fee_model.dart';
import 'add_fee_screen.dart';

class FeeScreen extends StatefulWidget {
  const FeeScreen({super.key});

  @override
  State<FeeScreen> createState() => _FeeScreenState();
}

class _FeeScreenState extends State<FeeScreen> {
  final DummyData _data = DummyData();

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Biaya',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Nama Biaya',
                hint: 'mis. Biaya Antar',
                controller: nameController,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Nilai (Rp)',
                controller: valueController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Simpan',
                onPressed: () {
                  if (nameController.text.trim().isEmpty) {
                    Navigator.pop(ctx);
                    showStatusSnackBar(
                      context,
                      message: 'Nama biaya wajib diisi',
                      isSuccess: false,
                    );
                    return;
                  }
                  final value = double.tryParse(valueController.text) ?? 0;
                  if (value < 0) {
                    Navigator.pop(ctx);
                    showStatusSnackBar(
                      context,
                      message: 'Nilai biaya tidak boleh negatif',
                      isSuccess: false,
                    );
                    return;
                  }

                  final updatedFee = Fee(
                    id: fee.id,
                    name: nameController.text.trim(),
                    value: value,
                  );
                  setState(() {
                    final index = _data.fees.indexWhere((f) => f.id == fee.id);
                    if (index != -1) {
                      _data.fees[index] = updatedFee;
                    }
                  });
                  Navigator.pop(ctx);
                  showStatusSnackBar(
                    context,
                    message: 'Biaya diperbarui',
                    isSuccess: true,
                  );
                },
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Batal',
                isPrimary: false,
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
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _data.fees.removeWhere((f) => f.id == fee.id);
              });
              showStatusSnackBar(
                context,
                message: '${fee.name} dihapus',
                isSuccess: true,
              );
            },
            child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Biaya',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Divider(height: 1),
            Expanded(
              child: _data.fees.isEmpty
                  ? AppEmptyState(
                      icon: Icons.payments_outlined,
                      title: 'Belum ada biaya',
                      subtitle: 'Tambah opsi biaya (mis. ongkir, potong)',
                      actionLabel: 'Tambah Biaya',
                      onAction: _navigateToAddFee,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _data.fees.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final fee = _data.fees[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.divider,
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.payments_outlined, color: Colors.blue.shade600),
                              ),
                              const SizedBox(width: 16),
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
                                      'Rp ${DummyData.formatCurrency(fee.value.toInt())}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                onPressed: () => _showEditFeeDialog(fee),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                onPressed: () => _deleteFee(fee),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _data.fees.isNotEmpty
          ? FloatingActionButton(
              onPressed: _navigateToAddFee,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
