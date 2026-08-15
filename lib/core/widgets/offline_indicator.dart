import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';
import '../widgets/app_button.dart';
import 'package:depot_kayu_app/core/extensions/context_colors.dart';

class OfflineIndicator extends StatefulWidget {
  final Widget child;

  const OfflineIndicator({super.key, required this.child});

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  bool _isOffline = false;
  bool _needsSync = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen(_handleConnectivityChange);
    _checkInitial();
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final isOffline = results.isEmpty || results.contains(ConnectivityResult.none);
    
    if (isOffline) {
      FirebaseFirestore.instance.disableNetwork();
      if (mounted) {
        setState(() {
          _isOffline = true;
        });
      }
    } else {
      // Come back online
      if (_isOffline) {
        if (mounted) {
          setState(() {
            _isOffline = false;
            _needsSync = true;
          });
        }
      } else {
        // Initial online
        FirebaseFirestore.instance.enableNetwork();
      }
    }
  }

  Future<void> _checkInitial() async {
    final results = await Connectivity().checkConnectivity();
    _handleConnectivityChange(results);
  }

  Future<void> _performSync() async {
    setState(() => _isSyncing = true);
    try {
      await FirebaseFirestore.instance.enableNetwork();
      await FirebaseFirestore.instance.waitForPendingWrites();
      
      if (mounted) {
        setState(() {
          _needsSync = false;
          _isSyncing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sinkronisasi data berhasil.'),
            backgroundColor: context.colorSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal sinkronisasi, coba lagi.'),
            backgroundColor: context.colorError,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            if (_isOffline)
              Container(
                width: double.infinity,
                color: context.colorError,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                  bottom: 4,
                ),
                child: const Text(
                  'Anda sedang offline. Semua transaksi disimpan di lokal.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Expanded(child: widget.child),
          ],
        ),

        // Blocking overlay when needs sync
        if (_needsSync && !_isOffline)
          Container(
            color: Colors.black.withOpacity(0.85),
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_upload_outlined, size: 64, color: context.colorPrimary),
                      const SizedBox(height: 16),
                      const Text(
                        'Koneksi Terhubung',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Anda memiliki data transaksi lokal yang belum diunggah ke server. Harap upload data sekarang untuk melanjutkan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.colorTextSecondary),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          label: _isSyncing ? 'Mengunggah...' : 'Upload Data Sekarang',
                          onPressed: _isSyncing ? null : _performSync,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}