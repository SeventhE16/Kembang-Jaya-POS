import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_dialog.dart';
import '../../data/dummy/dummy_data.dart';
import '../../data/models/discount_model.dart';
import 'add_discount_screen.dart';

class DiscountScreen extends StatefulWidget {
  const DiscountScreen({super.key});

  @override
  State<DiscountScreen> createState() => _DiscountScreenState();
}

class _DiscountScreenState extends State<DiscountScreen> {
  final DummyData _data = DummyData();

  Future<void> _navigateToAddDiscount() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddDiscountScreen()),
    );
    if (result == true) {
      setState(() {});
    }
  }

  void _showEditDiscountDialog(Discount discount) {
    final nameController = TextEditingController(text: discount.name);
    final valueController = TextEditingController(text: discount.value.toInt().toString());
    DiscountType selectedType = discount.type;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
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
                      'Edit Diskon',
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
                  label: 'Nama Diskon',
                  hint: 'mis. Diskon Tukang',
                  controller: nameController,
                ),
                const SizedBox(height: 12),

                // Type radio
                const Text('Tipe',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _TypeRadio(
                      label: 'Persen (%)',
                      isSelected: selectedType == DiscountType.percent,
                      onTap: () => setDialogState(
                          () => selectedType = DiscountType.percent),
                    ),
                    const SizedBox(width: 24),
                    _TypeRadio(
                      label: 'Nominal (Rp)',
                      isSelected: selectedType == DiscountType.nominal,
                      onTap: () => setDialogState(
                          () => selectedType = DiscountType.nominal),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                AppTextField(
                  label: 'Nilai',
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
                        message: 'Nama diskon wajib diisi',
                        isSuccess: false,
                      );
                      return;
                    }
                    final value =
                        double.tryParse(valueController.text) ?? 0;
                    if (value <= 0) {
                      Navigator.pop(ctx);
                      showStatusSnackBar(
                        context,
                        message: 'Nilai diskon harus lebih dari 0',
                        isSuccess: false,
                      );
                      return;
                    }

                    final updatedDiscount = Discount(
                      id: discount.id,
                      name: nameController.text.trim(),
                      type: selectedType,
                      value: value,
                    );
                    setState(() {
                      final index = _data.discounts.indexWhere((d) => d.id == discount.id);
                      if (index != -1) {
                        _data.discounts[index] = updatedDiscount;
                      }
                    });
                    Navigator.pop(ctx);
                    showStatusSnackBar(
                      context,
                      message: 'Diskon diperbarui',
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
      ),
    );
  }

  void _deleteDiscount(Discount discount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus ${discount.name}?'),
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
                _data.discounts.removeWhere((d) => d.id == discount.id);
              });
              showStatusSnackBar(
                context,
                message: '${discount.name} dihapus',
                isSuccess: true,
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/discount'),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text(
          'Diskon',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: _data.discounts.isEmpty
                ? AppEmptyState(
                    icon: Icons.local_offer_outlined,
                    title: 'Belum ada diskon',
                    subtitle: 'Tambah diskon untuk pelanggan',
                    actionLabel: 'Tambah Diskon',
                    onAction: _navigateToAddDiscount,
                  )
                : ListView.separated(
                    itemCount: _data.discounts.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final discount = _data.discounts[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.iconLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.local_offer_outlined,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    discount.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    discount.displayValue,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: AppColors.primary, size: 20),
                              onPressed: () => _showEditDiscountDialog(discount),
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.primary, size: 20),
                              onPressed: () => _deleteDiscount(discount),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppButton(
              label: 'Tambah Diskon',
              icon: Icons.add,
              onPressed: _navigateToAddDiscount,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _TypeRadio extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeRadio({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
