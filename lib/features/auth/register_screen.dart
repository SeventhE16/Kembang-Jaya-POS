import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_assets.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_dialog.dart';
import 'package:provider/provider.dart';
import '../../data/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      showStatusSnackBar(
        context,
        message: 'Semua kolom wajib diisi',
        type: SnackbarType.error,
      );
      return;
    }

    if (password != confirmPassword) {
      showStatusSnackBar(
        context,
        message: 'Password dan Konfirmasi Password tidak sama',
        type: SnackbarType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().register(email, password);
      
      if (!mounted) return;
      setState(() => _isLoading = false);

      showStatusSnackBar(
        context,
        message: 'Akun berhasil dibuat. Silakan login.',
        type: SnackbarType.success,
      );
      Navigator.pop(context);
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      String message = 'Terjadi kesalahan saat pendaftaran';
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email sudah digunakan oleh akun lain';
          break;
        case 'invalid-email':
          message = 'Format email tidak valid';
          break;
        case 'weak-password':
          message = 'Password terlalu lemah (minimal 6 karakter)';
          break;
        case 'operation-not-allowed':
          message = 'Pendaftaran email/password tidak diizinkan';
          break;
        case 'network-request-failed':
          message = 'Masalah koneksi internet';
          break;
        default:
          message = e.message ?? message;
      }
      
      showStatusSnackBar(
        context,
        message: message,
        type: SnackbarType.error,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showStatusSnackBar(
        context,
        message: 'Terjadi kesalahan tidak terduga',
        type: SnackbarType.error,
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primarySurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primarySurface,
              Colors.white,
            ],
            stops: [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: AppDimensions.spacingLG),
                Image.asset(
                  AppAssets.logo,
                  width: 80,
                  height: 80,
                ),
                const SizedBox(height: AppDimensions.spacingLG),
                const Text(
                  'Buat Akun Baru',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSM),
                const Text(
                  'Silakan daftar untuk melanjutkan',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXL),

                // Form
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingLG),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppDimensions.radius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Email',
                        hint: 'Masukkan email Anda',
                        controller: _emailController,
                        prefix: const Icon(Icons.email_outlined),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: AppDimensions.spacingMD),
                      AppTextField(
                        label: 'Password',
                        hint: 'Buat password baru',
                        controller: _passwordController,
                        obscureText: true,
                        prefix: const Icon(Icons.lock_outline),
                      ),
                      const SizedBox(height: AppDimensions.spacingMD),
                      AppTextField(
                        label: 'Konfirmasi Password',
                        hint: 'Ketik ulang password',
                        controller: _confirmPasswordController,
                        obscureText: true,
                        prefix: const Icon(Icons.lock_outline),
                      ),
                      const SizedBox(height: AppDimensions.spacingXL),
                      AppButton(
                        label: 'Daftar',
                        onPressed: _handleRegister,
                        isLoading: _isLoading,
                        isFullWidth: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



