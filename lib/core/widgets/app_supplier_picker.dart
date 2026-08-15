import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/supplier_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../../data/providers/supplier_provider.dart';
import '../widgets/status_dialog.dart';
import 'package:depot_kayu_app/core/extensions/context_colors.dart';

class AppSupplierPicker extends StatefulWidget {
  final Supplier? initialSupplier;
  const AppSupplierPicker({super.key, this.initialSupplier});

  static Future<Supplier?> show(BuildContext context, {Supplier? initialSupplier}) {
    return showModalBottomSheet<Supplier>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AppSupplierPicker(initialSupplier: initialSupplier),
    );
  }

  @override
  State<AppSupplierPicker> createState() => _AppSupplierPickerState();
}

class _AppSupplierPickerState extends State<AppSupplierPicker> {
  String _searchQuery = '';
  
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupplierProvider>();
    final suppliers = provider.suppliers.where((c) {
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             c.phone.contains(_searchQuery);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLG)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header & Search
          Padding(
            padding: const EdgeInsets.fromLTRB(AppDimensions.spacingMD, 0, AppDimensions.spacingMD, AppDimensions.spacingMD),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Pilih Supplier',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    AppButton(
                      label: 'Tambah Baru',
                      icon: Icons.add,
                      variant: AppButtonVariant.primary,
                      isFullWidth: false,
                      onPressed: () => _addNewSupplier(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingMD),
                AppTextField(
                  hint: 'Cari nama atau nomor telepon...',
                  prefix: const Icon(Icons.search),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // List
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : suppliers.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty ? 'Belum ada supplier' : 'Supplier tidak ditemukan',
                          style: TextStyle(color: context.colorTextSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom + AppDimensions.spacingLG,
                        ),
                        itemCount: suppliers.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final supplier = suppliers[i];
                          final isSelected = widget.initialSupplier?.id == supplier.id;
                          
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.spacingMD,
                              vertical: 4,
                            ),
                            selected: isSelected,
                            selectedTileColor: context.colorPrimary.withValues(alpha: 0.05),
                            leading: CircleAvatar(
                              backgroundColor: isSelected ? context.colorPrimary : Colors.grey.shade200,
                              child: Text(
                                supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : context.colorTextPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              supplier.name,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              supplier.phone.isNotEmpty ? supplier.phone : 'Tidak ada no telepon',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: context.colorPrimary)
                                : IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    color: context.colorTextSecondary,
                                    onPressed: () => _editSupplier(context, supplier),
                                  ),
                            onTap: () => Navigator.pop(context, supplier),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
  
  void _addNewSupplier(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Supplier'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: nameController,
                label: 'Nama Supplier',
                hint: 'Masukkan nama supplier',
              ),
              const SizedBox(height: AppDimensions.spacingMD),
              AppTextField(
                controller: phoneController,
                label: 'No. Telepon',
                hint: '0812...',
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: context.colorTextSecondary)),
          ),
          AppButton(
            label: 'Simpan',
            isFullWidth: false,
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                showStatusSnackBar(ctx, message: 'Nama supplier harus diisi', type: SnackbarType.warning);
                return;
              }
              
              final newSupplier = Supplier(
                id: '',
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                address: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              
              try {
                Navigator.pop(ctx); // Close dialog
                await context.read<SupplierProvider>().addSupplier(newSupplier);
                if (mounted) {
                  showStatusSnackBar(context, message: 'Supplier berhasil ditambahkan', type: SnackbarType.success);
                }
              } catch (e) {
                if (mounted) {
                  showStatusSnackBar(context, message: 'Gagal menambahkan supplier', type: SnackbarType.error);
                }
              }
            },
          ),
        ],
      ),
    );
  }
  
  void _editSupplier(BuildContext context, Supplier supplier) {
    final nameController = TextEditingController(text: supplier.name);
    final phoneController = TextEditingController(text: supplier.phone);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Supplier'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: nameController,
                label: 'Nama Supplier',
                hint: 'Masukkan nama supplier',
              ),
              const SizedBox(height: AppDimensions.spacingMD),
              AppTextField(
                controller: phoneController,
                label: 'No. Telepon',
                hint: '0812...',
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: context.colorTextSecondary)),
          ),
          AppButton(
            label: 'Simpan',
            isFullWidth: false,
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                showStatusSnackBar(ctx, message: 'Nama supplier harus diisi', type: SnackbarType.warning);
                return;
              }
              
              final updatedSupplier = Supplier(
                id: supplier.id,
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                address: supplier.address,
                createdAt: supplier.createdAt,
                updatedAt: DateTime.now(),
                createdBy: supplier.createdBy,
                updatedBy: supplier.updatedBy,
              );
              
              try {
                Navigator.pop(ctx); // Close dialog
                await context.read<SupplierProvider>().updateSupplier(updatedSupplier);
                if (mounted) {
                  showStatusSnackBar(context, message: 'Supplier berhasil diperbarui', type: SnackbarType.success);
                }
              } catch (e) {
                if (mounted) {
                  showStatusSnackBar(context, message: 'Gagal memperbarui supplier', type: SnackbarType.error);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}