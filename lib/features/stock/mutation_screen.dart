import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/status_dialog.dart';
import '../../data/models/product_model.dart';
import '../../data/models/mutation_model.dart';
import '../../data/providers/product_provider.dart';
import '../../data/providers/mutation_provider.dart';
import '../../data/providers/auth_provider.dart';

class MutationScreen extends StatefulWidget {
  const MutationScreen({super.key});

  @override
  State<MutationScreen> createState() => _MutationScreenState();
}

class _MutationScreenState extends State<MutationScreen> {
  Product? _sourceProduct;
  Product? _targetProduct;
  final TextEditingController _qtyController = TextEditingController();
  bool _isLoading = false;

  void _submit() async {
    if (_sourceProduct == null || _targetProduct == null) {
      showStatusSnackBar(context, message: 'Pilih produk asal dan tujuan', type: SnackbarType.warning);
      return;
    }
    if (_sourceProduct!.id == _targetProduct!.id) {
      showStatusSnackBar(context, message: 'Produk asal dan tujuan tidak boleh sama', type: SnackbarType.warning);
      return;
    }

    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (qty < 1) {
      showStatusSnackBar(context, message: 'Jumlah minimal 1', type: SnackbarType.warning);
      return;
    }
    if (qty > _sourceProduct!.stock) {
      showStatusSnackBar(context, message: 'Jumlah melebihi stok produk asal (${_sourceProduct!.stock})', type: SnackbarType.warning);
      return;
    }

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Mutasi'),
        content: Text('Anda yakin ingin memindahkan stok sebanyak $qty dari ${_sourceProduct!.name} ke ${_targetProduct!.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Pindahkan', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    final currentCtx = context;

    try {
      final provProduct = Provider.of<ProductProvider>(context, listen: false);
      final provMutation = Provider.of<MutationProvider>(context, listen: false);
      final provAuth = Provider.of<AuthProvider>(context, listen: false);

      // Transfer stock via Provider which will call Service
      await provProduct.transferStock(
        _sourceProduct!.id,
        _targetProduct!.id,
        qty,
      );

      // Save mutation record
      final mutation = GradeMutation(
        id: '',
        sourceProductId: _sourceProduct!.id,
        sourceProductName: _sourceProduct!.name,
        targetProductId: _targetProduct!.id,
        targetProductName: _targetProduct!.name,
        quantity: qty,
        date: DateTime.now(),
        createdBy: provAuth.user?.displayName ?? 'Kasir',
      );

      await provMutation.addMutation(mutation);

      if (!currentCtx.mounted) return;

      ScaffoldMessenger.of(currentCtx).showSnackBar(
        const SnackBar(content: Text('Mutasi berhasil disimpan')),
      );

      _qtyController.clear();
      setState(() {
        _sourceProduct = null;
        _targetProduct = null;
      });
    } catch (e) {
      if (!currentCtx.mounted) return;
      ScaffoldMessenger.of(currentCtx).showSnackBar(
        SnackBar(content: Text('Gagal melakukan mutasi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/mutation'),
      appBar: AppBar(
        title: const Text(
          'Mutasi Grade Barang',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Form Mutasi Grade',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pindahkan stok barang dari satu grade/kualitas ke grade lainnya. Stok asal akan berkurang, stok tujuan akan bertambah secara otomatis.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  // Dropdown Source
                  const Text('Produk Asal', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildProductDropdown(
                    value: _sourceProduct,
                    onChanged: (p) => setState(() => _sourceProduct = p),
                  ),
                  if (_sourceProduct != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Sisa Stok: ${_sourceProduct!.stock}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(height: 20),

                  // Dropdown Target
                  const Text('Produk Tujuan', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildProductDropdown(
                    value: _targetProduct,
                    onChanged: (p) => setState(() => _targetProduct = p),
                  ),
                  const SizedBox(height: 20),

                  // Quantity
                  const Text('Jumlah Mutasi', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit
                  AppButton(
                    label: 'Simpan Mutasi',
                    onPressed: _submit,
                    icon: Icons.swap_horiz,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProductDropdown({required Product? value, required ValueChanged<Product?> onChanged}) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        // Filter out "Jasa"
        final products = provider.products.where((p) => p.category != 'Jasa').toList();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: const Text('Pilih Produk'),
              value: value?.id,
              items: products.map((p) {
                return DropdownMenuItem<String>(
                  value: p.id,
                  child: Text(p.name),
                );
              }).toList(),
              onChanged: (id) {
                if (id != null) {
                  onChanged(products.firstWhere((p) => p.id == id));
                }
              },
            ),
          ),
        );
      },
    );
  }
}
