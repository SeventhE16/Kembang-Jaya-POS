import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
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
      // Decode image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Format gambar tidak didukung');

      // Resize to max 380x380 for standard receipt logos
      final resized = img.copyResize(
        image,
        width: 380,
        height: image.height > image.width ? 380 : null,
      );

      final pngBytes = img.encodePng(resized);
      
      // Upload to Firebase Storage
      final ref = _storage.ref().child('store_logos/${StoreContext().storeId}_${DateTime.now().millisecondsSinceEpoch}.png');
      
      final uploadTask = await ref.putData(
        pngBytes,
        SettableMetadata(contentType: 'image/png'),
      );
      
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }
}
