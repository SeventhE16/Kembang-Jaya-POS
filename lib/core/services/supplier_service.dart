import 'package:cloud_firestore/cloud_firestore.dart';
import 'store_context.dart';

class Supplier {
  final String id;
  final String name;
  final String phone;
  final String address;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;

  Supplier({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  factory Supplier.fromJson(Map<String, dynamic> json, String id) {
    return Supplier(
      id: id,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }
}

class SupplierService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'suppliers';

  Stream<List<Supplier>> streamSuppliers() {
    return _firestore
        .collection(collectionName)
        .where('storeId', isEqualTo: StoreContext().storeId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Supplier.fromJson(doc.data(), doc.id)).toList();
    });
  }

  Future<void> addSupplier(Supplier supplier) async {
    try {
      final data = supplier.toJson();
      data['storeId'] = StoreContext().storeId;
      await _firestore.collection(collectionName).add(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateSupplier(Supplier supplier) async {
    try {
      await _firestore.collection(collectionName).doc(supplier.id).update(supplier.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSupplier(String id) async {
    try {
      await _firestore.collection(collectionName).doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }
}
