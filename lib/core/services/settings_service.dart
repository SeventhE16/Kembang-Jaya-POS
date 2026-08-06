import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'store_context.dart';

class StoreSettings {
  final String name;
  final String address;
  final String phone;
  final String? logoUrl;
  final int logoSize;
  final DateTime updatedAt;

  StoreSettings({
    required this.name,
    required this.address,
    required this.phone,
    this.logoUrl,
    this.logoSize = 200,
    required this.updatedAt,
  });

  factory StoreSettings.fromJson(Map<String, dynamic> json) {
    return StoreSettings(
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      logoUrl: json['logoUrl'],
      logoSize: json['logoSize'] ?? 200,
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'logoUrl': logoUrl,
      'logoSize': logoSize,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<StoreSettings?> getSettings() async {
    final doc = await _firestore.collection('settings').doc(StoreContext().storeId).get();
    if (doc.exists && doc.data() != null) {
      return StoreSettings.fromJson(doc.data()!);
    }
    return null;
  }

  Stream<StoreSettings?> streamSettings() {
    return _firestore.collection('settings').doc(StoreContext().storeId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return StoreSettings.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  Future<void> saveSettings(StoreSettings settings) async {
    try {
      await _firestore.collection('settings').doc(StoreContext().storeId).set(settings.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<String> uploadLogo(File imageFile) async {
    try {
      final storeId = StoreContext().storeId;
      final ref = _storage.ref().child('settings/${storeId}_logo_${DateTime.now().millisecondsSinceEpoch}.png');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }
}
