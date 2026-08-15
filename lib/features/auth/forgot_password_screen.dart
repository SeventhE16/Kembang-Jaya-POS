import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_assets.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_dialog.dart';
import '../../data/providers/auth_provider.dart';
import 'package:depot_kayu_app/core/extensions/context_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      showStatusSnackBar(
        context,
        message: 'Email wajib diisi',
        type: SnackbarType.error,
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.resetPassword(email);
      
      if (!mounted) return;
      setState(() => _emailSent = true);
      showStatusSnackBar(
        context,
        message: 'Email reset password telah dikirim ke $email',
        type: SnackbarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      showStatusSnackBar(
        context,
        message: 'Gagal mengirim email: $e',
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.colorPrimarySurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colorTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.colorPrimarySurface,
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
                Text(
                  'Lupa Password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: context.colorTextPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSM),
                Text(
                  'Masukkan email untuk menerima link reset',
                  style: TextStyle(
                    fontSize: 16,
                    color: context.colorTextSecondary,
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
                      const SizedBox(height: AppDimensions.spacingXL),
                      AppButton(
                        label: _emailSent ? 'Kirim Ulang Link' : 'Kirim Link Reset',
                        isFullWidth: true,
                        isLoading: _isLoading,
                        onPressed: _handleResetPassword,
                      ),
                      if (_emailSent) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Silakan periksa kotak masuk (atau spam) email Anda untuk mengatur ulang password.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.green, fontSize: 13),
                        )
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}