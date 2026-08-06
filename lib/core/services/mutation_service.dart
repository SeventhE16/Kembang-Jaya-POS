import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/mutation_model.dart';
import 'store_context.dart';

class MutationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'grade_mutations';

  Stream<List<GradeMutation>> getMutations() {
    return _firestore
        .collection(collectionName)
        .where('storeId', isEqualTo: StoreContext().storeId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return GradeMutation.fromJson(doc.data(), doc.id);
      }).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<void> addMutation(GradeMutation mutation) async {
    try {
      final data = mutation.toJson();
      data['storeId'] = StoreContext().storeId;
      await _firestore.collection(collectionName).add(data);
    } catch (e) {
      rethrow;
    }
  }
}
