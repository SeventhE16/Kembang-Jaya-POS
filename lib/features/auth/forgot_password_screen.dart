import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_assets.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_dialog.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _codeSent = false;

  Future<void> _handleSendCode() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      showStatusSnackBar(
        context,
        message: 'Email wajib diisi',
        isSuccess: false,
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500)); // Mock network
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _codeSent = true;
    });

    showStatusSnackBar(
      context,
      message: 'Kode unik telah dikirim ke email Anda',
      isSuccess: true,
    );
  }

  Future<void> _handleVerifyCode() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      showStatusSnackBar(
        context,
        message: 'Kode unik wajib diisi',
        isSuccess: false,
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500)); // Mock network
    if (!mounted) return;
    setState(() => _isLoading = false);

    showStatusSnackBar(
      context,
      message: 'Password berhasil direset (Mock)',
      isSuccess: true,
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
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
                const SizedBox(height: 20),
                Image.asset(
                  AppAssets.logo,
                  width: 80,
                  height: 80,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Lupa Password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Masukkan email untuk menerima kode',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
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
                        readOnly: _codeSent,
                      ),
                      
                      if (_codeSent) ...[
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Kode Unik',
                          hint: 'Masukkan 6 digit kode',
                          controller: _codeController,
                          prefix: const Icon(Icons.pin_outlined),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      AppButton(
                        label: _codeSent ? 'Verifikasi & Reset' : 'Kirim Kode',
                        onPressed: _codeSent ? _handleVerifyCode : _handleSendCode,
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
