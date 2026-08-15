import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/widgets/status_dialog.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/product_provider.dart';
import '../../data/providers/customer_provider.dart';
import '../../data/providers/transaction_provider.dart';
import '../../data/providers/mutation_provider.dart';
import 'package:depot_kayu_app/core/extensions/context_colors.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _navigated = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    // Safety timeout: if sync takes more than 30 seconds, assume something is wrong
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (!_navigated && mounted) {
        _navigated = true;
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.logout();
        Navigator.pushReplacementNamed(context, AppRoutes.login);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showStatusSnackBar(
              context,
              message: 'Sinkronisasi gagal. Silakan login ulang.',
              type: SnackbarType.error,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // If user is no longer authenticated (e.g., forced logout due to missing user doc)
    if (!authProvider.isAuthenticated && !_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.login);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showStatusSnackBar(
              context,
              message: authProvider.userNotFound
                  ? 'Akun tidak ditemukan. Silahkan buat akun baru.'
                  : 'Sesi berakhir. Silakan login ulang.',
              type: SnackbarType.error,
            );
          }
        });
      });
    }

    final pLoading = context.watch<ProductProvider>().isLoading;
    final cLoading = context.watch<CustomerProvider>().isLoading;
    final tLoading = context.watch<TransactionProvider>().isLoading;
    final mLoading = context.watch<MutationProvider>().isLoading;

    final isLoading = pLoading || cLoading || tLoading || mLoading;

    if (!isLoading && !_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.sales);
      });
    }

    String status = 'Menghubungkan ke Server...';
    double progress = 0.2;
    if (!pLoading) {
      status = 'Mengunduh Data Pelanggan...';
      progress = 0.5;
    }
    if (!cLoading && !pLoading) {
      status = 'Mengunduh Transaksi...';
      progress = 0.8;
    }
    if (!isLoading) {
      status = 'Sinkronisasi Selesai';
      progress = 1.0;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_sync, size: 80, color: context.colorPrimary),
              const SizedBox(height: 24),
              Text(
                'Sinkronisasi Data',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: context.colorTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                status,
                style: TextStyle(
                  fontSize: 14,
                  color: context.colorTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: context.colorInputFill,
                  valueColor: AlwaysStoppedAnimation<Color>(context.colorPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}