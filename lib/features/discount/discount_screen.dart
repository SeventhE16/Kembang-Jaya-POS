import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_text_field.dart';
import 'package:provider/provider.dart';
import '../../data/providers/discount_provider.dart';
import '../../data/models/discount_model.dart';
import '../../core/widgets/status_dialog.dart';
import 'add_discount_screen.dart';
import 'package:depot_kayu_app/core/extensions/context_colors.dart';

class DiscountScreen extends StatefulWidget {
  const DiscountScreen({super.key});

  @override
  State<DiscountScreen> createState() => _DiscountScreenState();
}

class _DiscountScreenState extends State<DiscountScreen> {
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
                      'Edit Diskon',
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
                  label: 'Nama Diskon',
                  hint: 'mis. Diskon Tukang',
                  controller: nameController,
                ),
                const SizedBox(height: AppDimensions.spacingMD),

                // Type radio
                const Text('Tipe',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: AppDimensions.spacingSM),
                Row(
                  children: [
                    _TypeRadio(
                      label: 'Persen (%)',
                      isSelected: selectedType == DiscountType.percent,
                      onTap: () => setDialogState(
                          () => selectedType = DiscountType.percent),
                    ),
                    const SizedBox(width: AppDimensions.spacingLG),
                    _TypeRadio(
                      label: 'Nominal (Rp)',
                      isSelected: selectedType == DiscountType.nominal,
                      onTap: () => setDialogState(
                          () => selectedType = DiscountType.nominal),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingMD),

                AppTextField(
                  label: 'Nilai',
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
                        message: 'Nama diskon wajib diisi',
                        type: SnackbarType.error,
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
                        type: SnackbarType.error,
                      );
                      return;
                    }

                    final updatedDiscount = Discount(
                      id: discount.id,
                      name: nameController.text.trim(),
                      type: selectedType,
                      value: value,
                      createdAt: discount.createdAt,
                      updatedAt: DateTime.now(),
                    );
                    
                    await Provider.of<DiscountProvider>(context, listen: false)
                        .updateDiscount(updatedDiscount);
                        
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    showStatusSnackBar(
                      context,
                      message: 'Diskon diperbarui',
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
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<DiscountProvider>(context, listen: false)
                  .deleteDiscount(discount.id);
                  
              if (!mounted) return;
              showStatusSnackBar(
                context,
                message: '${discount.name} dihapus',
                type: SnackbarType.success,
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
        title: Text(
          'Diskon',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Consumer<DiscountProvider>(
          builder: (context, provider, child) {
            final discounts = provider.discounts;
            return Column(
              children: [
                const Divider(height: 1),
                if (provider.isLoading)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else
                  Expanded(
                    child: discounts.isEmpty
                        ? AppEmptyState(
                            icon: Icons.local_offer_outlined,
                            title: 'Belum ada diskon',
                            subtitle: 'Tambah diskon untuk pelanggan',
                            action: AppButton(
                              label: 'Tambah Diskon',
                              onPressed: _navigateToAddDiscount,
                            ),
                          )
                        : ListView.separated(
                            itemCount: discounts.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final discount = discounts[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: context.colorIconLight,
                                borderRadius: BorderRadius.circular(AppDimensions.radius),
                              ),
                              child: Icon(
                                Icons.local_offer_outlined,
                                color: context.colorPrimary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spacingMD),
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
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: context.colorTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit_outlined,
                                  color: context.colorPrimary, size: 20),
                              onPressed: () => _showEditDiscountDialog(discount),
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  color: context.colorPrimary, size: 20),
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
            padding: const EdgeInsets.all(AppDimensions.spacingMD),
            child: AppButton(
              label: 'Tambah Diskon',
              icon: Icons.add,
              onPressed: _navigateToAddDiscount,
            ),
          ),
        ],
      );
      },
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
                color: isSelected ? context.colorPrimary : context.colorTextSecondary,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colorPrimary,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}




