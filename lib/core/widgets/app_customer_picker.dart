import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/customer_provider.dart';
import '../../data/models/customer_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'app_button.dart';
import 'app_text_field.dart';
import 'package:depot_kayu_app/core/extensions/context_colors.dart';

class AppCustomerPicker extends StatefulWidget {
  final Customer? selectedCustomer;

  const AppCustomerPicker({super.key, this.selectedCustomer});

  static Future<Customer?> show(BuildContext context, {Customer? selectedCustomer}) {
    return showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radius)),
      ),
      builder: (ctx) => AppCustomerPicker(selectedCustomer: selectedCustomer),
    );
  }

  @override
  State<AppCustomerPicker> createState() => _AppCustomerPickerState();
}

class _AppCustomerPickerState extends State<AppCustomerPicker> {
  String _searchQuery = '';
  
  void _addNewCustomer() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Pelanggan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            AppTextField(
              controller: nameController,
              label: 'Nama Pelanggan',
              hint: 'Masukkan nama',
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
            onPressed: () async {
              if (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) return;
              final newCust = Customer(
                id: 'C${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              
              final prov = Provider.of<CustomerProvider>(context, listen: false);
              await prov.addCustomer(newCust);
              
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              Navigator.pop(ctx, newCust);
            },
          ),
        ],
      ),
    );
  }

  void _editCustomer(Customer cust) {
    final nameController = TextEditingController(text: cust.name);
    final phoneController = TextEditingController(text: cust.phone);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Pelanggan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: nameController,
              label: 'Nama Pelanggan',
              hint: 'Masukkan nama',
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: context.colorTextSecondary)),
          ),
          AppButton(
            label: 'Simpan',
            onPressed: () async {
              if (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) return;
              
              cust.name = nameController.text.trim();
              cust.phone = phoneController.text.trim();
              
              final prov = Provider.of<CustomerProvider>(context, listen: false);
              await prov.updateCustomer(cust);
              
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final customers = customerProvider.customers;
    
    final filtered = customers.where((c) {
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
             c.phone.contains(_searchQuery);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingMD),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pilih Pelanggan', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMD),
              child: AppTextField(
                hint: 'Cari nama atau telepon...',
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingSM),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: context.colorPrimary,
                child: Icon(Icons.add, color: Colors.white),
              ),
              title: Text('Tambah Pelanggan Baru', style: TextStyle(color: context.colorPrimary, fontWeight: FontWeight.bold)),
              onTap: _addNewCustomer,
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final cust = filtered[i];
                  final isSelected = widget.selectedCustomer?.id == cust.id;
                  
                  return ListTile(
                    leading: isSelected ? Icon(Icons.check_circle, color: context.colorPrimary) : CircleAvatar(backgroundColor: Colors.black12, child: Icon(Icons.person, color: Colors.white)),
                    title: Text(cust.name, style: Theme.of(context).textTheme.bodyLarge),
                    subtitle: Text(cust.phone, style: Theme.of(context).textTheme.bodySmall),
                    trailing: IconButton(
                      icon: Icon(Icons.edit, color: context.colorTextSecondary, size: 20),
                      onPressed: () => _editCustomer(cust),
                    ),
                    onTap: () => Navigator.pop(context, cust),
                  );
                },
              ),
            ),
          ],
        );
      }
    );
  }
}