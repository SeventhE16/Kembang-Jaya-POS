import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_routes.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_dialog.dart';
import 'package:provider/provider.dart';
import '../../data/providers/auth_provider.dart';
import 'package:depot_kayu_app/core/extensions/context_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-login is now handled safely in the build method 
    // by observing AuthProvider's isLoadingUser and userModel
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showStatusSnackBar(
        context,
        message: 'Email dan password wajib diisi',
        type: SnackbarType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.login(email, password);
      
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.sync);
    } catch (e) {
      if (!mounted) return;
      showStatusSnackBar(
        context,
        message: 'Gagal login: ${e.toString().replaceAll('Exception: ', '')}',
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
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Auto navigation when user data finishes loading and is valid
    if (!auth.isLoadingUser && auth.isAuthenticated && auth.userModel != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.sync);
      });
      return Scaffold(body: Center(child: CircularProgressIndicator(color: context.colorPrimary)));
    }

    if (auth.isLoadingUser) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [context.colorPrimarySurface, Colors.white],
              stops: [0.0, 0.5],
            ),
          ),
          child: Center(
            child: CircularProgressIndicator(color: context.colorPrimary),
          ),
        ),
      );
    }

    return Scaffold(
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
                const SizedBox(height: 48),

                // Logo
                Image.asset(
                  AppAssets.logo,
                  width: 80,
                  height: 80,
                ),
                const SizedBox(height: AppDimensions.spacingLG),

                // Store name
                Text(
                  'Depot Kayu\nKembang Jaya',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: context.colorTextPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSM),

                // Subtitle
                Text(
                  'Kelola stok dan transaksi toko',
                  style: TextStyle(
                    fontSize: 15,
                    color: context.colorPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXL),

                // Login Card
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
                        hint: 'Masukkan password Anda',
                        controller: _passwordController,
                        obscureText: true,
                        prefix: const Icon(Icons.lock_outline),
                      ),
                      const SizedBox(height: AppDimensions.spacingMD),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.forgotPassword);
                          },
                          child: Text(
                            'Lupa Password?',
                            style: TextStyle(
                              color: context.colorPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingLG),
                      AppButton(
                        label: 'Masuk',
                        onPressed: _handleLogin,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: AppDimensions.spacingMD),

                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Belum punya akun?',
                            style: TextStyle(color: context.colorTextSecondary),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.register);
                            },
                            child: Text(
                              'Buat Akun',
                              style: TextStyle(
                                color: context.colorPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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