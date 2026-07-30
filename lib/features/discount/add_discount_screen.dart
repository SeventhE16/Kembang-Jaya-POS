import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_dialog.dart';
import '../../data/dummy/dummy_data.dart';
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

  void _onTambah() {
    if (_nameController.text.trim().isEmpty) {
      showStatusSnackBar(
        context,
        message: 'Nama diskon wajib diisi',
        isSuccess: false,
      );
      return;
    }

    final value = double.tryParse(_valueController.text) ?? 0;
    if (value <= 0) {
      showStatusSnackBar(
        context,
        message: 'Nilai diskon harus lebih dari 0',
        isSuccess: false,
      );
      return;
    }

    final newDiscount = Discount(
      id: 'D${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      type: _selectedType,
      value: value,
    );

    DummyData().discounts.add(newDiscount);

    showStatusSnackBar(
      context,
      message: 'Diskon ditambahkan',
      isSuccess: true,
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
        title: const Text(
          'Tambah Diskon',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label: 'Nama Diskon',
                      hint: 'mis. Diskon Tukang',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 16),
                    
                    const Text('Tipe',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _TypeRadio(
                          label: 'Persen (%)',
                          isSelected: _selectedType == DiscountType.percent,
                          onTap: () => setState(() => _selectedType = DiscountType.percent),
                        ),
                        const SizedBox(width: 24),
                        _TypeRadio(
                          label: 'Nominal (Rp)',
                          isSelected: _selectedType == DiscountType.nominal,
                          onTap: () => setState(() => _selectedType = DiscountType.nominal),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
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
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    label: 'Tambah',
                    onPressed: _onTambah,
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'Batal',
                    isPrimary: false,
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
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
