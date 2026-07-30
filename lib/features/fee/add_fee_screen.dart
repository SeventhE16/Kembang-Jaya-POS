import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_dialog.dart';
import '../../data/dummy/dummy_data.dart';
import '../../data/models/fee_model.dart';

class AddFeeScreen extends StatefulWidget {
  const AddFeeScreen({super.key});

  @override
  State<AddFeeScreen> createState() => _AddFeeScreenState();
}

class _AddFeeScreenState extends State<AddFeeScreen> {
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();

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
        message: 'Nama biaya wajib diisi',
        isSuccess: false,
      );
      return;
    }

    final value = double.tryParse(_valueController.text) ?? 0;
    if (value < 0) {
      showStatusSnackBar(
        context,
        message: 'Nilai biaya tidak boleh negatif',
        isSuccess: false,
      );
      return;
    }

    final newFee = Fee(
      id: 'F${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      value: value,
    );

    DummyData().fees.add(newFee);

    showStatusSnackBar(
      context,
      message: 'Biaya ditambahkan',
      isSuccess: true,
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Biaya'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Biaya',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            AppTextField(
              label: 'Nama Biaya',
              hint: 'mis. Biaya Antar, Biaya Potong',
              controller: _nameController,
            ),
            const SizedBox(height: 16),
            
            AppTextField(
              label: 'Nilai (Rp)',
              controller: _valueController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            
            AppButton(
              label: 'Tambah Biaya',
              onPressed: _onTambah,
            ),
          ],
        ),
      ),
    );
  }
}
