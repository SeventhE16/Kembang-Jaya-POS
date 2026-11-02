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

  Future<void> transferStock(String sourceId, String targetId, int quantity, {List<dynamic>? allocations}) async {
    try {
      await _firestore.runTransaction((tx) async {
        final sourceRef = _firestore.collection(collectionName).doc(sourceId);
        final targetRef = _firestore.collection(collectionName).doc(targetId);

        final sourceDoc = await tx.get(sourceRef);
        final targetDoc = await tx.get(targetRef);

        if (!sourceDoc.exists || !targetDoc.exists) {
          throw Exception('Product not found');
        }

        final sourceProduct = Product.fromJson(sourceDoc.data()!, sourceDoc.id);
        final targetProduct = Product.fromJson(targetDoc.data()!, targetDoc.id);

        List<StockBatch> sourceBatches = List.from(sourceProduct.stockBatches);
        List<StockBatch> targetBatches = List.from(targetProduct.stockBatches);

        if (allocations != null && allocations.isNotEmpty) {
          // Specific Identification
          for (var allocDynamic in allocations) {
            final alloc = allocDynamic as dynamic; 
            String bId = alloc.batchId;
            int bQty = alloc.quantity;
            double bPrice = alloc.basePrice;

            // Deduct from source and get original date
            DateTime originalDate = DateTime.now();
            int sIndex = sourceBatches.indexWhere((b) => b.id == bId);
            if (sIndex != -1) {
              originalDate = sourceBatches[sIndex].dateAdded;
              sourceBatches[sIndex].quantity -= bQty;
            }

            String newBatchId = '${bId}_mutated';
            
            // Check if target already has this exact mutated batch
            int tIndex = targetBatches.indexWhere((b) => b.id == newBatchId);
            if (tIndex != -1) {
              targetBatches[tIndex].quantity += bQty;
            } else {
              targetBatches.add(StockBatch(
                id: newBatchId,
                quantity: bQty,
                basePrice: bPrice,
                dateAdded: originalDate, // Mempertahankan tanggal asli
                grade: targetProduct.name.contains('Grade') ? targetProduct.name.split('Grade ').last : 'Mutated',
              ));
            }
          }
          // Cleanup empty batches
          sourceBatches.removeWhere((b) => b.quantity <= 0);
        } else {
          // Fallback to FIFO
          int remainingToDeduct = quantity;
          sourceBatches.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
          
          for (int j = 0; j < sourceBatches.length; j++) {
            if (remainingToDeduct <= 0) break;
            if (sourceBatches[j].quantity > 0) {
              int qtyToTake = remainingToDeduct <= sourceBatches[j].quantity ? remainingToDeduct : sourceBatches[j].quantity;
              sourceBatches[j].quantity -= qtyToTake;
              remainingToDeduct -= qtyToTake;
              
              targetBatches.add(StockBatch(
                id: '${sourceBatches[j].id}_mutated_$j',
                quantity: qtyToTake,
                basePrice: sourceBatches[j].basePrice,
                dateAdded: sourceBatches[j].dateAdded, // Mempertahankan tanggal asli
                grade: targetProduct.name.contains('Grade') ? targetProduct.name.split('Grade ').last : 'Mutated',
              ));
            }
          }
          sourceBatches.removeWhere((b) => b.quantity <= 0);
        }

        int newSourceStock = sourceBatches.fold(0, (sum, batch) => sum + batch.quantity);
        int newTargetStock = targetBatches.fold(0, (sum, batch) => sum + batch.quantity);

        tx.update(sourceRef, {
          'stock': newSourceStock,
          'stockBatches': sourceBatches.map((e) => e.toJson()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        tx.update(targetRef, {
          'stock': newTargetStock,
          'stockBatches': targetBatches.map((e) => e.toJson()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
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
