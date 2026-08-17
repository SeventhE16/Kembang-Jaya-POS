import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/store_context.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  StreamSubscription? _sub;
  final AuthService _authService = AuthService();
  firebase_auth.User? _firebaseUser;
  User? _userModel;
  bool _userNotFound = false;
  bool _isLoadingUser = true;

  firebase_auth.User? get firebaseUser => _firebaseUser;
  firebase_auth.User? get user => _firebaseUser;
  User? get userModel => _userModel;
  bool get isAuthenticated => _firebaseUser != null;
  bool get userNotFound => _userNotFound;
  bool get isLoadingUser => _isLoadingUser;

  AuthProvider() {
    _firebaseUser = _authService.currentUser;
    if (_firebaseUser != null) {
      _fetchUserModel();
    } else {
      _isLoadingUser = false;
    }
    _sub = _authService.authStateChanges.listen((firebase_auth.User? user) {
      _firebaseUser = user;
      if (user != null) {
        _fetchUserModel();
      } else {
        _userModel = null;
        _isLoadingUser = false;
        StoreContext().setStoreId(null);
        notifyListeners();
      }
    });
  }

  Future<void> _fetchUserModel() async {
    _isLoadingUser = true;
    notifyListeners();

    if (_firebaseUser != null) {
      final prefs = await SharedPreferences.getInstance();
      final lastLoginStr = prefs.getString('last_login_time');
      if (lastLoginStr != null) {
        final lastLogin = DateTime.parse(lastLoginStr);
        if (DateTime.now().difference(lastLogin).inHours >= 24) {
          debugPrint('Session expired (24h). Forcing logout.');
          await prefs.remove('last_login_time');
          await _authService.logout();
          return;
        }
      } else {
        // Set it for existing sessions so they expire in 24 hours from first open after update
        await prefs.setString('last_login_time', DateTime.now().toIso8601String());
      }

      _userModel = await _authService.getUserModel(_firebaseUser!.uid);
      _isLoadingUser = false;
      if (_userModel != null) {
        StoreContext().setStoreId(_userModel!.storeId);
      } else {
        // User document doesn't exist in Firestore — force logout
        debugPrint('User document not found in Firestore for uid: ${_firebaseUser!.uid}. Forcing logout.');
        _userNotFound = true;
        await _authService.logout();
        notifyListeners();
        return; // authStateChanges listener will handle the rest
      }
      notifyListeners();
    } else {
      _isLoadingUser = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _userNotFound = false;
    final cred = await _authService.login(email, password);
    
    // After successful Firebase Auth, verify user document exists in Firestore
    final userDoc = await _authService.getUserModel(cred.user!.uid);
    if (userDoc == null) {
      // User document was deleted from Firestore — sign out immediately
      _userNotFound = true;
      await _authService.logout();
      throw Exception('Akun belum dibuat atau telah dihapus. Hubungi administrator.');
    }
    
    // Save last login time
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_login_time', DateTime.now().toIso8601String());
  }

  Future<void> register(String email, String password, {String name = ''}) async {
    final cred = await _authService.register(email, password);
    if (cred.user != null) {
      final newUser = User(
        id: cred.user!.uid,
        name: name.isNotEmpty ? name : email.split('@')[0],
        email: email,
        role: UserRole.admin,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        storeId: cred.user!.uid, // Admin is their own store
        allowedFeatures: ['management', 'sales', 'holdOrders', 'piutang', 'report', 'stock', 'stokOpname', 'mutation'],
      );
      await _authService.saveUserModel(newUser);
      // Immediately logout so the user can manually login, avoiding state conflicts
      await _authService.logout();
    }
  }

  Future<void> registerStaff(String email, String password, String name) async {
    if (_userModel == null) throw Exception('Admin must be logged in to register staff');
    await _authService.registerStaff(email, password, name, _userModel!.storeId);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_login_time');
    await _authService.logout();
  }
  
  Future<void> resetPassword(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  Future<void> refreshUser() async {
    await firebase_auth.FirebaseAuth.instance.currentUser?.reload();
    _firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    await _fetchUserModel();
  }
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}