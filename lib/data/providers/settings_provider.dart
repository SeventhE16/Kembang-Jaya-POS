import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/store_context.dart';

class SettingsProvider extends ChangeNotifier {
  StreamSubscription? _sub;
  final SettingsService _settingsService = SettingsService();
  StoreSettings? _settings;
  bool _isLoading = true;

  StoreSettings? get settings => _settings;
  bool get isLoading => _isLoading;

  StreamSubscription? _storeSub;

  SettingsProvider() {
    _storeSub = StoreContext().storeIdStream.listen((storeId) {
      _sub?.cancel();
      if (storeId == null) {
        _settings = null;
        _isLoading = true;
        notifyListeners();
      } else {
        _sub = _settingsService.streamSettings().listen((settings) {
          _settings = settings;
          _isLoading = false;
          notifyListeners();
        });
      }
    });

    if (StoreContext().storeIdOrNull != null) {
      _sub = _settingsService.streamSettings().listen((settings) {
        _settings = settings;
        _isLoading = false;
        notifyListeners();
      });
    }
  }

  Future<void> saveSettings(StoreSettings settings) async {
    await _settingsService.saveSettings(settings);
  }

  Future<String> uploadLogo(File imageFile) async {
    return await _settingsService.uploadLogo(imageFile);
  }
  @override
  void dispose() {
    _sub?.cancel();
    _storeSub?.cancel();
    super.dispose();
  }
}