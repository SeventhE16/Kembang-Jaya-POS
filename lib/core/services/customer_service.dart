import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/customer_model.dart';
import 'store_context.dart';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'customers';

  Stream<List<Customer>> streamCustomers() {
    return _firestore
        .collection(collectionName)
        .where('storeId', isEqualTo: StoreContext().storeId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Customer.fromJson(doc.data(), doc.id)).toList();
    });
  }

  Future<void> addCustomer(Customer customer) async {
    try {
      final data = customer.toJson();
      data['storeId'] = StoreContext().storeId;
      await _firestore.collection(collectionName).add(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      await _firestore.collection(collectionName).doc(customer.id).update(customer.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _firestore.collection(collectionName).doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }
}
