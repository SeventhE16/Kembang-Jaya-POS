import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_dialog.dart';
import 'package:provider/provider.dart';
import '../../data/providers/fee_provider.dart';
import '../../data/models/fee_model.dart';
import 'package:depot_kayu_app/core/extensions/context_colors.dart';

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

  Future<void> _onTambah() async {
    if (_nameController.text.trim().isEmpty) {
      showStatusSnackBar(
        context,
        message: 'Nama biaya wajib diisi',
        type: SnackbarType.error,
      );
      return;
    }

    final value = double.tryParse(_valueController.text) ?? 0;
    if (value < 0) {
      showStatusSnackBar(
        context,
        message: 'Nilai biaya tidak boleh negatif',
        type: SnackbarType.error,
      );
      return;
    }

    final newFee = Fee(
      id: 'F${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      value: value,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await Provider.of<FeeProvider>(context, listen: false).addFee(newFee);

    if (!mounted) return;
    showStatusSnackBar(
      context,
      message: 'Biaya ditambahkan',
      type: SnackbarType.success,
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
        padding: const EdgeInsets.all(AppDimensions.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Biaya',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.colorTextPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            
            AppTextField(
              label: 'Nama Biaya',
              hint: 'mis. Biaya Antar, Biaya Potong',
              controller: _nameController,
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            
            AppTextField(
              label: 'Nilai (Rp)',
              controller: _valueController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppDimensions.spacingXL),
            
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


