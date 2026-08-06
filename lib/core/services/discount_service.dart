import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/discount_model.dart';
import 'store_context.dart';

class DiscountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Discount>> streamDiscounts() {
    return _firestore
        .collection('discounts')
        .where('storeId', isEqualTo: StoreContext().storeId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Discount.fromJson(doc.data(), doc.id)).toList();
    });
  }

  Future<void> addDiscount(Discount discount) async {
    final data = discount.toJson();
    data.remove('id'); 
    data['storeId'] = StoreContext().storeId;
    if (discount.id.isNotEmpty && !discount.id.startsWith('D')) {
      await _firestore.collection('discounts').doc(discount.id).set(data);
    } else {
      await _firestore.collection('discounts').add(data);
    }
  }

  Future<void> updateDiscount(Discount discount) async {
    final data = discount.toJson();
    data.remove('id');
    await _firestore.collection('discounts').doc(discount.id).update(data);
  }

  Future<void> deleteDiscount(String id) async {
    await _firestore.collection('discounts').doc(id).delete();
  }
}
