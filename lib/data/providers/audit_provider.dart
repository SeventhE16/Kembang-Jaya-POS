import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/store_context.dart';
import '../../core/services/audit_service.dart';
import '../models/audit_log_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class AuditProvider extends ChangeNotifier {
  StreamSubscription? _sub;
  StreamSubscription? _storeSub;
  final AuditService _auditService = AuditService();
  List<AuditLog> _logs = [];
  bool _isLoading = true;

  List<AuditLog> get logs => _logs;
  bool get isLoading => _isLoading;

  AuditProvider() {
    _storeSub = StoreContext().storeIdStream.listen((storeId) {
      _sub?.cancel();
      if (storeId == null) {
        _logs = [];
        _isLoading = true;
        notifyListeners();
      } else {
        _sub = _auditService.streamAuditLogs().listen((logsData) {
          _logs = logsData;
          _isLoading = false;
          notifyListeners();
        });
      }
    });
    
    if (StoreContext().storeIdOrNull != null) {
      _sub = _auditService.streamAuditLogs().listen((logsData) {
        _logs = logsData;
        _isLoading = false;
        notifyListeners();
      });
    }
  }

  Future<void> logAction(String action, String description) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final log = AuditLog(
      id: '',
      action: action,
      description: description,
      userId: user.uid,
      userName: user.displayName ?? 'Unknown',
      timestamp: DateTime.now(),
    );

    await _auditService.logAction(log);
  }
  @override
  void dispose() {
    _sub?.cancel();
    _storeSub?.cancel();
    super.dispose();
  }
}