import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_dialog.dart';
import '../../data/dummy/dummy_data.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  // --- Profil State ---
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController(text: 'admin');
  final _phoneController = TextEditingController(text: '0812-3456-7890');
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = DummyData().currentUser.value['name'] ?? '';
    _emailController.text = DummyData().currentUser.value['email'] ?? '';
  }

  // --- Printer State ---
  final List<Map<String, dynamic>> _printers = [
    {
      'name': 'Thermal Printer 58mm',
      'address': 'BT:00:11:22:33:44',
      'date': '14/6/2026',
      'connected': true,
    },
    {
      'name': 'Epson TM-T82',
      'address': 'USB-001',
      'date': '10/6/2026',
      'connected': false,
    },
  ];

  // --- Struk State ---
  final _logoUrlController = TextEditingController();
  final _adminFeeController = TextEditingController(text: '0');
  final _taxController = TextEditingController(text: '0');

  bool _alamatPelanggan = false;
  bool _kodeStruk = true;
  bool _noUrut = false;
  bool _satuanQty = true;
  bool _noStruk = true;
  bool _totalKuantitas = true;
  bool _kolomTtd = false;
  bool _tipeHarga = false;
  bool _labelKasir = true;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _logoUrlController.dispose();
    _adminFeeController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/setting'),
      appBar: AppBar(
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfilSection(),
                  const SizedBox(height: 12),
                  _buildPrinterSection(),
                  const SizedBox(height: 12),
                  _buildStrukSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PROFIL SECTION ====================
  Widget _buildProfilSection() {
    return _sectionContainer(
      icon: Icons.person_outline,
      title: 'Profil',
      children: [
        AppTextField(
          label: 'Nama Staff',
          controller: _nameController,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Username',
          controller: _usernameController,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Telepon',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        AppButton(
          label: 'Simpan Profil',
          onPressed: () {
            DummyData().currentUser.value = {
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
            };
            showStatusSnackBar(
              context,
              message: 'Profil berhasil disimpan',
              isSuccess: true,
            );
          },
        ),
        const SizedBox(height: 8),
        AppButton(
          label: 'Log Out',
          isPrimary: false,
          icon: Icons.logout_rounded,
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.login,
              (route) => false,
            );
          },
        ),
      ],
    );
  }

  // ==================== PRINTER SECTION ====================
  Widget _buildPrinterSection() {
    return _sectionContainer(
      icon: Icons.print_outlined,
      title: 'Printer',
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Riwayat printer yang pernah terkoneksi.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ..._printers.asMap().entries.map((entry) {
          final printer = entry.value;
          final isConnected = printer['connected'] as bool;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        printer['name'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${printer['address']} · ${printer['date']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isConnected ? 'Terhubung' : 'Terputus',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isConnected
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _printers.removeAt(entry.key);
                    });
                    showStatusSnackBar(
                      context,
                      message: '${printer['name']} dihapus',
                      isSuccess: true,
                    );
                  },
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 4),
        AppButton(
          label: 'Hubungkan Printer',
          isPrimary: false,
          icon: Icons.add,
          onPressed: () {
            showStatusSnackBar(
              context,
              message: 'Mencari printer... (demo)',
              isSuccess: true,
            );
          },
        ),
      ],
    );
  }

  // ==================== STRUK SECTION ====================
  Widget _buildStrukSection() {
    return _sectionContainer(
      icon: Icons.receipt_long_outlined,
      title: 'Struk',
      children: [
        AppTextField(
          label: 'Logo Struk (URL)',
          hint: 'https://...',
          controller: _logoUrlController,
        ),
        const SizedBox(height: 16),

        // Switch tiles in a rounded container
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _switchTile('Alamat pelanggan', _alamatPelanggan, (v) =>
                  setState(() => _alamatPelanggan = v)),
              const Divider(height: 1),
              _switchTile('Kode struk', _kodeStruk, (v) =>
                  setState(() => _kodeStruk = v)),
              const Divider(height: 1),
              _switchTile('No urut', _noUrut, (v) =>
                  setState(() => _noUrut = v)),
              const Divider(height: 1),
              _switchTile('Satuan di sebelah qty', _satuanQty, (v) =>
                  setState(() => _satuanQty = v)),
              const Divider(height: 1),
              _switchTile('No struk', _noStruk, (v) =>
                  setState(() => _noStruk = v)),
              const Divider(height: 1),
              _switchTile('Total kuantitas', _totalKuantitas, (v) =>
                  setState(() => _totalKuantitas = v)),
              const Divider(height: 1),
              _switchTile('Kolom tanda tangan hutang/piutang', _kolomTtd, (v) =>
                  setState(() => _kolomTtd = v)),
              const Divider(height: 1),
              _switchTile('Tipe harga', _tipeHarga, (v) =>
                  setState(() => _tipeHarga = v)),
              const Divider(height: 1),
              _switchTile('Label kasir', _labelKasir, (v) =>
                  setState(() => _labelKasir = v)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Admin fee & tax row
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Biaya Admin Toko',
                controller: _adminFeeController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                label: 'Persentase Pajak (%)',
                controller: _taxController,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== HELPERS ====================

  /// Collapsible section container matching Figma design
  Widget _sectionContainer({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Theme(
        data: ThemeData(
          brightness: Brightness.light,
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          leading: Icon(icon, color: AppColors.primary, size: 24),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary, // Force dark text
            ),
          ),
          iconColor: AppColors.textPrimary,
          collapsedIconColor: AppColors.textPrimary,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: children,
        ),
      ),
    );
  }

  /// SwitchListTile with consistent styling
  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      dense: true,
    );
  }
}
