import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/product_model.dart';
import 'store_context.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'products';

  Stream<List<Product>> streamProducts() {
    return _firestore
        .collection(collectionName)
        .where('storeId', isEqualTo: StoreContext().storeId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromJson(doc.data(), doc.id)).toList();
    });
  }

  Future<Product> getProduct(String id) async {
    final doc = await _firestore.collection(collectionName).doc(id).get();
    if (doc.exists && doc.data() != null) {
      return Product.fromJson(doc.data()!, doc.id);
    }
    throw Exception('Product not found');
  }

  Future<void> addProduct(Product product) async {
    try {
      final data = product.toJson();
      data['storeId'] = StoreContext().storeId;
      await _firestore.collection(collectionName).add(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _firestore.collection(collectionName).doc(product.id).update(product.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reduceStock(String productId, int quantity) async {
    try {
      await _firestore.collection(collectionName).doc(productId).update({
        'stock': FieldValue.increment(-quantity),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> transferStock(String sourceId, String targetId, int quantity) async {
    try {
      final batch = _firestore.batch();
      final sourceRef = _firestore.collection(collectionName).doc(sourceId);
      final targetRef = _firestore.collection(collectionName).doc(targetId);

      batch.update(sourceRef, {'stock': FieldValue.increment(-quantity)});
      batch.update(targetRef, {'stock': FieldValue.increment(quantity)});

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _firestore.collection(collectionName).doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }
}
