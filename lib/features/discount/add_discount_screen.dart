import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_dialog.dart';
import 'package:provider/provider.dart';
import '../../data/providers/discount_provider.dart';
import '../../data/models/discount_model.dart';

class AddDiscountScreen extends StatefulWidget {
  const AddDiscountScreen({super.key});

  @override
  State<AddDiscountScreen> createState() => _AddDiscountScreenState();
}

class _AddDiscountScreenState extends State<AddDiscountScreen> {
  final _nameController = TextEditingController();
  final _valueController = TextEditingController(text: '10');
  DiscountType _selectedType = DiscountType.percent;

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _onTambah() async {
    if (_nameController.text.trim().isEmpty) {
      showStatusSnackBar(
        context,
        message: 'Nama diskon wajib diisi',
        type: SnackbarType.error,
      );
      return;
    }

    final value = double.tryParse(_valueController.text) ?? 0;
    if (value <= 0) {
      showStatusSnackBar(
        context,
        message: 'Nilai diskon harus lebih dari 0',
        type: SnackbarType.error,
      );
      return;
    }
    
    if (_selectedType == DiscountType.percent && value > 100) {
      showStatusSnackBar(
        context,
        message: 'Diskon maksimal 100%',
        type: SnackbarType.error,
      );
      return;
    }

    final newDiscount = Discount(
      id: 'D${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      type: _selectedType,
      value: value,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await Provider.of<DiscountProvider>(context, listen: false).addDiscount(newDiscount);

    if (!mounted) return;
    showStatusSnackBar(
      context,
      message: 'Diskon ditambahkan',
      type: SnackbarType.success,
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.primary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tambah Diskon',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.spacingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label: 'Nama Diskon',
                      hint: 'mis. Diskon Tukang',
                      controller: _nameController,
                    ),
                    const SizedBox(height: AppDimensions.spacingMD),
                    
                    const Text('Tipe',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: AppDimensions.spacingSM),
                    Row(
                      children: [
                        _TypeRadio(
                          label: 'Persen (%)',
                          isSelected: _selectedType == DiscountType.percent,
                          onTap: () => setState(() => _selectedType = DiscountType.percent),
                        ),
                        const SizedBox(width: AppDimensions.spacingLG),
                        _TypeRadio(
                          label: 'Nominal (Rp)',
                          isSelected: _selectedType == DiscountType.nominal,
                          onTap: () => setState(() => _selectedType = DiscountType.nominal),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingMD),
                    
                    AppTextField(
                      label: 'Nilai',
                      hint: '10',
                      controller: _valueController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingMD),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    label: 'Tambah',
                    onPressed: _onTambah,
                  ),
                  const SizedBox(height: AppDimensions.spacingSM),
                  AppButton(
                    label: 'Batal',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
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
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}






