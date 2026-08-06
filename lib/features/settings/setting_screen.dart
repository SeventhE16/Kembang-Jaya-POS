import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:provider/provider.dart';
import '../../data/providers/auth_provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_dialog.dart';
import '../../core/services/printer_service.dart';
import '../../core/services/settings_service.dart';
import '../../data/providers/settings_provider.dart';

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

  List<BluetoothDevice> _devices = [];
  bool _isLoadingPrinters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final settings = Provider.of<SettingsProvider>(context, listen: false).settings;
      if (auth.user != null) {
        _nameController.text = auth.user!.displayName ?? '';
        _emailController.text = auth.user!.email ?? '';
      }
      if (settings != null) {
        _storeNameController.text = settings.name;
        _storeAddressController.text = settings.address;
        _storePhoneController.text = settings.phone;
        _logoSizeController.text = settings.logoSize.toString();
      }
    });
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    setState(() { _isLoadingPrinters = true; });
    final devices = await PrinterService().getPairedDevices();
    setState(() {
      _devices = devices;
      _isLoadingPrinters = false;
    });
  }

  // --- Struk State ---
  File? _logoFile;
  final _logoUrlController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _storePhoneController = TextEditingController();
  final _logoSizeController = TextEditingController(text: '200');
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
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _storePhoneController.dispose();
    _logoSizeController.dispose();
    _adminFeeController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _logoFile = File(pickedFile.path);
      });
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final newPassController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ganti Password'),
        content: AppTextField(
          label: 'Password Baru',
          controller: newPassController,
          obscureText: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          AppButton(
            label: 'Simpan',
            onPressed: () async {
              try {
                // We'd ideally call AuthService or AuthProvider to update password
                await auth.FirebaseAuth.instance.currentUser?.updatePassword(newPassController.text);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  showStatusSnackBar(context, message: 'Password berhasil diubah', type: SnackbarType.success);
                }
              } catch (e) {
                if (ctx.mounted) {
                  showStatusSnackBar(context, message: 'Gagal mengubah password: \$e', type: SnackbarType.error);
                }
              }
            }
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.setting),
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
                  if (context.watch<AuthProvider>().userModel?.role == UserRole.admin) ...[
                    const SizedBox(height: 12),
                    _buildStaffManagementSection(),
                  ],
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
          onPressed: () async {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final currentUser = authProvider.firebaseUser;
            if (currentUser == null) return;
            
            final newEmail = _emailController.text.trim();
            final newName = _nameController.text.trim();
            
            try {
              final user = auth.FirebaseAuth.instance.currentUser;
              if (user != null) {
                // Update display name
                if (newName.isNotEmpty && user.displayName != newName) {
                  await user.updateDisplayName(newName);
                }
                // Update email (requires verification)
                if (newEmail.isNotEmpty && user.email != newEmail) {
                  await user.verifyBeforeUpdateEmail(newEmail);
                }
                // Refresh AuthProvider so drawer updates
                await authProvider.refreshUser();
              }
              if (mounted) {
                showStatusSnackBar(
                  context,
                  message: 'Profil berhasil disimpan',
                  type: SnackbarType.success,
                );
              }
            } catch (e) {
              if (mounted) {
                showStatusSnackBar(
                  context,
                  message: 'Gagal menyimpan profil: $e',
                  type: SnackbarType.error,
                );
              }
            }
          },
        ),
        const SizedBox(height: 8),
        AppButton(
          label: 'Ganti Password',
          variant: AppButtonVariant.secondary,
          icon: Icons.lock_reset,
          onPressed: () => _showChangePasswordDialog(context),
        ),
        const SizedBox(height: 8),
        AppButton(
          label: 'Log Out',
          variant: AppButtonVariant.secondary,
          icon: Icons.logout_rounded,
          onPressed: () async {
            await Provider.of<AuthProvider>(context, listen: false).logout();
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
            }
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
            'Perangkat Bluetooth Terpasang (Paired).',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (_isLoadingPrinters) const Center(child: CircularProgressIndicator()),
        ..._devices.map((device) {
          final isConnected = PrinterService().selectedDevice?.address == device.address;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(AppDimensions.spacingMD),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(AppDimensions.radius),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name ?? 'Unknown Device',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        device.address ?? '-',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isConnected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppDimensions.radius),
                    ),
                    child: const Text('Terhubung', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
                  ),
                const SizedBox(width: AppDimensions.spacingSM),
                IconButton(
                  onPressed: () async {
                    if (isConnected) {
                      await PrinterService().disconnect();
                    } else {
                      await PrinterService().connect(device);
                    }
                    setState((){});
                  },
                  icon: Icon(
                    isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                    color: isConnected ? AppColors.success : AppColors.primary,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 4),
        AppButton(
          label: 'Segarkan Bluetooth',
          variant: AppButtonVariant.secondary,
          icon: Icons.refresh,
          onPressed: () {
            _loadPrinters();
            showStatusSnackBar(
              context,
              message: 'Memuat perangkat Bluetooth...',
              type: SnackbarType.success,
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: _logoFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_logoFile!, fit: BoxFit.cover),
                    )
                  : (_logoUrlController.text.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AppLogo(logoUrl: _logoUrlController.text, height: 80, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.image, color: AppColors.textSecondary, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppButton(
                label: 'Pilih Logo Struk',
                variant: AppButtonVariant.secondary,
                onPressed: _pickLogo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Nama Toko',
          controller: _storeNameController,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Alamat Toko',
          controller: _storeAddressController,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'WhatsApp / Telepon Toko',
          controller: _storePhoneController,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Ukuran Logo Struk (Pixel) - Default: 200',
          controller: _logoSizeController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          hint: 'Contoh: 200',
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Simpan Info Toko & Logo',
          onPressed: () async {
            final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
            String? logoUrl = settingsProvider.settings?.logoUrl;
            
            if (_logoFile != null) {
              showStatusSnackBar(context, message: 'Mengunggah logo...', type: SnackbarType.success);
              try {
                logoUrl = await settingsProvider.uploadLogo(_logoFile!);
              } catch (e) {
                if (mounted) showStatusSnackBar(context, message: 'Gagal mengunggah logo: $e', type: SnackbarType.error);
                return;
              }
            }
            
            int logoSize = int.tryParse(_logoSizeController.text.trim()) ?? 200;
            // Batasan ukuran aman untuk printer thermal 58mm (max 380px)
            if (logoSize < 100) logoSize = 100;
            if (logoSize > 380) logoSize = 380;
            _logoSizeController.text = logoSize.toString();

            final newSettings = StoreSettings(
              name: _storeNameController.text.trim(),
              address: _storeAddressController.text.trim(),
              phone: _storePhoneController.text.trim(),
              logoUrl: logoUrl,
              logoSize: logoSize,
              updatedAt: DateTime.now(),
            );
            
            try {
              await settingsProvider.saveSettings(newSettings);
              if (mounted) showStatusSnackBar(context, message: 'Info struk berhasil disimpan', type: SnackbarType.success);
            } catch (e) {
              if (mounted) showStatusSnackBar(context, message: 'Gagal menyimpan pengaturan: $e', type: SnackbarType.error);
            }
          },
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

  Widget _buildStaffManagementSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Hanya Admin yang bisa melihat menu ini
        if (authProvider.userModel?.role != UserRole.admin) {
          return const SizedBox.shrink();
        }

        return _sectionContainer(
          icon: Icons.people_alt,
          title: 'Manajemen Staf',
          children: [
            const Text(
              'Tambahkan akun staf baru. Staf akan memiliki akses terbatas ke sistem.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Tambah Akun Staf',
              icon: Icons.person_add_outlined,
              onPressed: () => _showAddStaffDialog(context),
            ),
          ],
        );
      },
    );
  }

  void _showAddStaffDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tambah Akun Staf'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      label: 'Nama Staf',
                      controller: nameCtrl,
                      hint: 'Masukkan nama',
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Email',
                      controller: emailCtrl,
                      hint: 'email@contoh.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Password',
                      controller: passCtrl,
                      hint: 'Minimal 6 karakter',
                      obscureText: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty || nameCtrl.text.isEmpty) {
                            showStatusSnackBar(context, message: 'Semua field harus diisi', type: SnackbarType.error);
                            return;
                          }
                          setState(() => isSaving = true);
                          try {
                            await context.read<AuthProvider>().registerStaff(
                                  emailCtrl.text.trim(),
                                  passCtrl.text.trim(),
                                  nameCtrl.text.trim(),
                                );
                            if (!mounted) return;
                            Navigator.pop(context);
                            showStatusSnackBar(context, message: 'Akun staf berhasil dibuat!', type: SnackbarType.success);
                          } catch (e) {
                            setState(() => isSaving = false);
                            showStatusSnackBar(context, message: 'Gagal membuat akun staf', type: SnackbarType.error);
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}





