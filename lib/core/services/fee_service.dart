import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/fee_model.dart';
import 'store_context.dart';

class FeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Fee>> streamFees() {
    return _firestore
        .collection('fees')
        .where('storeId', isEqualTo: StoreContext().storeId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Fee.fromJson(doc.data(), doc.id)).toList();
    });
  }

  Future<void> addFee(Fee fee) async {
    final data = fee.toJson();
    data.remove('id'); 
    data['storeId'] = StoreContext().storeId;
    if (fee.id.isNotEmpty && !fee.id.startsWith('F')) {
      await _firestore.collection('fees').doc(fee.id).set(data);
    } else {
      await _firestore.collection('fees').add(data);
    }
  }

  Future<void> updateFee(Fee fee) async {
    final data = fee.toJson();
    data.remove('id');
    await _firestore.collection('fees').doc(fee.id).update(data);
  }

  Future<void> deleteFee(String id) async {
    await _firestore.collection('fees').doc(id).delete();
  }
}
