import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../../data/models/transaction_model.dart';
import '../../data/models/product_model.dart';
import 'store_context.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Transaction>> streamTransactions({DateTime? startDate, DateTime? endDate}) {
    var query = _firestore
        .collection('transactions')
        .where('storeId', isEqualTo: StoreContext().storeId);

    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => Transaction.fromJson(doc.data(), doc.id)).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      final counterRef = _firestore.collection('metadata').doc('invoice_counter');
      final newTxRef = _firestore.collection('transactions').doc(); // Auto ID
      Exception? caughtError;
      try {
        await _firestore.runTransaction((tx) async {
          try {
            // --- 1. ALL READS ---
            final snapshot = await tx.get(counterRef);
            int currentCount = 0;
            if (snapshot.exists) {
              final data = snapshot.data() as Map<String, dynamic>?;
              currentCount = data?['count'] ?? 0;
            }
            
            // Collect all product reads
            final Map<String, DocumentSnapshot> productDocs = {};
            for (var item in transaction.items) {
              if (item.product.category != 'Jasa') {
                if (!productDocs.containsKey(item.product.id)) {
                  final productRef = _firestore.collection('products').doc(item.product.id);
                  productDocs[item.product.id] = await tx.get(productRef);
                }
              }
            }

            // --- 2. ALL LOGIC ---
            final newCount = currentCount + 1;
            final now = DateTime.now();
            final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
            final seqStr = newCount.toString().padLeft(4, '0');
            final invoiceNum = transaction.type == 'purchase' 
                ? 'PO-$dateStr-$seqStr' 
                : 'INV-$dateStr-$seqStr';

            final List<CartItem> updatedItems = [];
            final Map<String, Map<String, dynamic>> productUpdates = {}; // product_id -> update_data

            for (int i = 0; i < transaction.items.length; i++) {
              CartItem item = transaction.items[i];
              CartItem finalItem = item;
              
              if (item.product.category != 'Jasa') {
                final productDoc = productDocs[item.product.id]!;
                if (productDoc.exists) {
                  final product = Product.fromJson(productDoc.data() as Map<String, dynamic>, productDoc.id);
                  
                  // In case there are multiple identical items, use the latest modified state from updates map if it exists
                  List<StockBatch> currentBatches;
                  if (productUpdates.containsKey(product.id)) {
                    currentBatches = (productUpdates[product.id]!['stockBatches'] as List).map((e) => StockBatch.fromJson(e)).toList();
                  } else {
                    currentBatches = List.from(product.stockBatches);
                  }
                  
                  if (transaction.type == 'purchase') {
                    currentBatches.add(StockBatch(
                      id: '${DateTime.now().microsecondsSinceEpoch}_$i',
                      quantity: item.quantity,
                      basePrice: item.customPrice ?? item.product.basePrice,
                      dateAdded: DateTime.now(),
                      grade: item.note ?? (item.product.name.contains('Grade') ? item.product.name.split('Grade ').last : null),
                    ));
                  } else {
                    if (item.batchAllocations != null && item.batchAllocations!.isNotEmpty) {
                      for (var alloc in item.batchAllocations!) {
                        int batchIndex = currentBatches.indexWhere((b) => b.id == alloc.batchId);
                        if (batchIndex != -1) {
                          currentBatches[batchIndex].quantity -= alloc.quantity;
                        }
                      }
                      currentBatches.removeWhere((b) => b.quantity <= 0);
                    } else {
                      int remainingToDeduct = item.quantity;
                      currentBatches.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
                      for (int j = 0; j < currentBatches.length; j++) {
                        if (remainingToDeduct <= 0) break;
                        if (currentBatches[j].quantity > 0) {
                          int qtyToTake = remainingToDeduct <= currentBatches[j].quantity ? remainingToDeduct : currentBatches[j].quantity;
                          currentBatches[j].quantity -= qtyToTake;
                          remainingToDeduct -= qtyToTake;
                        }
                      }
                      currentBatches.removeWhere((b) => b.quantity <= 0);
                    }
                    finalItem = item;
                  }

                  int newTotalStock = currentBatches.fold(0, (sum, batch) => sum + batch.quantity);
                  
                  productUpdates[product.id] = {
                    'stockBatches': currentBatches.map((e) => e.toJson()).toList(),
                    'stock': newTotalStock,
                    'updatedAt': FieldValue.serverTimestamp(),
                  };
                }
              }
              updatedItems.add(finalItem);
            }
            
            final finalTx = transaction.copyWith(
              id: newTxRef.id,
              invoiceNumber: invoiceNum,
              items: updatedItems,
            );
            
            final data = finalTx.toJson();
            data['storeId'] = StoreContext().storeId;

            // --- 3. ALL WRITES ---
            tx.set(counterRef, {'count': newCount});
            
            productUpdates.forEach((productId, updateData) {
              final productRef = _firestore.collection('products').doc(productId);
              tx.update(productRef, updateData);
            });
            
            tx.set(newTxRef, data);
          } catch (innerError, stack) {
            caughtError = Exception("Inner Dart Error: $innerError\n$stack");
            throw innerError;
          }
        });
      } catch (e) {
        if (caughtError != null) throw caughtError!;
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update transaksi dengan rekonsiliasi stok (revert stok lama, potong stok baru).
  /// Juga menghitung ulang sisa hutang berdasarkan total uang yang sudah dibayar.
  Future<Transaction> updateTransactionWithReconciliation({
    required Transaction oldTx,
    required Transaction newTx,
    required double totalAlreadyPaid, // DP awal + total semua cicilan
  }) async {
    try {
      final txRef = _firestore.collection('transactions').doc(oldTx.id);

      // Hitung debtAmount baru berdasarkan uang yang sudah masuk
      double newDebt = 0;
      double finalPayAmount = totalAlreadyPaid;
      String finalPaymentMethod = newTx.paymentMethod;

      if (oldTx.paymentMethod == 'Kasbon') {
        // Transaksi asal adalah kasbon - periksa apakah lunas setelah edit
        if (newTx.total <= totalAlreadyPaid) {
          // Lunas (atau lebih bayar)
          newDebt = 0;
          finalPayAmount = newTx.total; // Anggap bayar lunas
          finalPaymentMethod = 'Kasbon'; // Pertahankan metode
        } else {
          // Masih kasbon, sesuaikan hutang
          newDebt = newTx.total - totalAlreadyPaid;
          finalPayAmount = totalAlreadyPaid;
          finalPaymentMethod = 'Kasbon';
        }
      } else {
        // Transaksi tunai/transfer - tidak ada hutang
        newDebt = 0;
        finalPayAmount = newTx.payAmount;
      }

      // Firestore transaction untuk atomicity
      late Transaction finalTx;
      await _firestore.runTransaction((ftx) async {
        // --- 1. ALL READS ---
        final Set<String> allProductIds = {};
        for (var item in oldTx.items) {
          if (item.product.category != 'Jasa') allProductIds.add(item.product.id);
        }
        for (var item in newTx.items) {
          if (item.product.category != 'Jasa') allProductIds.add(item.product.id);
        }

        final Map<String, DocumentSnapshot> productDocs = {};
        for (var pid in allProductIds) {
          final doc = await ftx.get(_firestore.collection('products').doc(pid));
          if (doc.exists) productDocs[pid] = doc;
        }

        // --- 2. ALL LOGIC ---
        final Map<String, Map<String, dynamic>> productUpdates = {};
        
        // Helper untuk mendapatkan list StockBatch terakhir
        List<StockBatch> getCurrentBatches(String pid) {
          if (productUpdates.containsKey(pid)) {
            return (productUpdates[pid]!['stockBatches'] as List).map((e) => StockBatch.fromJson(e)).toList();
          } else {
            final productDoc = productDocs[pid];
            if (productDoc == null || !productDoc.exists) return [];
            final product = Product.fromJson(productDoc.data() as Map<String, dynamic>, productDoc.id);
            return List.from(product.stockBatches);
          }
        }

        // Helper untuk menyimpan update StockBatch
        void saveBatchesUpdate(String pid, List<StockBatch> batches) {
          int newTotalStock = batches.fold(0, (sum, batch) => sum + batch.quantity);
          productUpdates[pid] = {
            'stockBatches': batches.map((e) => e.toJson()).toList(),
            'stock': newTotalStock,
            'updatedAt': FieldValue.serverTimestamp(),
          };
        }

        // 1. REVERT stok dari transaksi lama
        for (var oldItem in oldTx.items) {
          if (oldItem.product.category == 'Jasa' || !productDocs.containsKey(oldItem.product.id)) continue;
          
          List<StockBatch> batches = getCurrentBatches(oldItem.product.id);

          if (oldItem.batchAllocations != null && oldItem.batchAllocations!.isNotEmpty) {
            for (var alloc in oldItem.batchAllocations!) {
              int idx = batches.indexWhere((b) => b.id == alloc.batchId);
              if (idx != -1) {
                batches[idx].quantity += alloc.quantity;
              } else {
                batches.add(StockBatch(
                  id: alloc.batchId,
                  quantity: alloc.quantity,
                  basePrice: alloc.basePrice,
                  dateAdded: oldTx.date,
                ));
              }
            }
          } else {
            // Legacy revert
            batches.add(StockBatch(
              id: 'revert_${oldTx.id}_${oldItem.product.id}',
              quantity: oldItem.quantity,
              basePrice: oldItem.product.basePrice,
              dateAdded: oldTx.date,
            ));
          }

          saveBatchesUpdate(oldItem.product.id, batches);
        }

        // 2. POTONG stok dari transaksi baru (Specific Identification)
        final List<CartItem> updatedItems = [];
        for (var newItem in newTx.items) {
          if (newItem.product.category == 'Jasa' || !productDocs.containsKey(newItem.product.id)) {
            updatedItems.add(newItem);
            continue;
          }

          CartItem finalItem = newItem;
          List<StockBatch> batches = getCurrentBatches(newItem.product.id);
          
          if (newItem.batchAllocations != null && newItem.batchAllocations!.isNotEmpty) {
            for (var alloc in newItem.batchAllocations!) {
              int idx = batches.indexWhere((b) => b.id == alloc.batchId);
              if (idx != -1) {
                batches[idx].quantity -= alloc.quantity;
              }
            }
          } else {
            // Fallback to legacy FIFO
            int remaining = newItem.quantity;
            batches.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
            for (int j = 0; j < batches.length; j++) {
              if (remaining <= 0) break;
              if (batches[j].quantity > 0) {
                int take = remaining <= batches[j].quantity ? remaining : batches[j].quantity;
                batches[j].quantity -= take;
                remaining -= take;
              }
            }
          }
          
          batches.removeWhere((b) => b.quantity <= 0);
          saveBatchesUpdate(newItem.product.id, batches);

          finalItem = newItem;
          updatedItems.add(finalItem);
        }

        // 3. Siapkan objek transaksi baru
        finalTx = newTx.copyWith(
          items: updatedItems,
          payAmount: finalPayAmount,
          debtAmount: newDebt,
          paymentMethod: finalPaymentMethod,
          updatedAt: DateTime.now(),
        );

        final data = finalTx.toJson();
        data['storeId'] = StoreContext().storeId;

        // --- 3. ALL WRITES ---
        productUpdates.forEach((productId, updateData) {
          ftx.update(_firestore.collection('products').doc(productId), updateData);
        });
        
        ftx.set(txRef, data);
      });

      return finalTx;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await _firestore.collection('transactions').doc(transaction.id).update(transaction.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _firestore.collection('transactions').doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  // --- Cicilan Piutang ---
  Future<void> addInstallment(String txId, InstallmentPayment installment) async {
    try {
      final txRef = _firestore.collection('transactions').doc(txId);
      final instRef = _firestore.collection('installments').doc();
      
      final instWithIds = InstallmentPayment(
        id: instRef.id,
        transactionId: txId,
        amount: installment.amount,
        date: installment.date,
        cashierName: installment.cashierName,
        note: installment.note,
      );

      final batch = _firestore.batch();
      
      // 1. Tambahkan dokumen ke sub-collection
      final instData = instWithIds.toJson();
      instData['storeId'] = StoreContext().storeId;
      batch.set(instRef, instData);
      
      // 2. Potong hutang dan tambah uang masuk di dokumen utama
      batch.update(txRef, {
        'debtAmount': FieldValue.increment(-installment.amount),
        'payAmount': FieldValue.increment(installment.amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<InstallmentPayment>> streamInstallments(String txId) {
    return _firestore
        .collection('installments')
        .where('transactionId', isEqualTo: txId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => InstallmentPayment.fromJson(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Stream<List<InstallmentPayment>> streamAllInstallments() {
    return _firestore
        .collection('installments')
        .where('storeId', isEqualTo: StoreContext().storeId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => InstallmentPayment.fromJson(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Stream<List<HoldOrder>> streamHoldOrders() {
    return _firestore
        .collection('hold_orders')
        .where('storeId', isEqualTo: StoreContext().storeId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => HoldOrder.fromJson(doc.data(), doc.id)).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<void> saveHoldOrder(HoldOrder order) async {
    try {
      final data = order.toJson();
      data['storeId'] = StoreContext().storeId;
      if (order.id.isEmpty) {
        await _firestore.collection('hold_orders').add(data);
      } else {
        await _firestore.collection('hold_orders').doc(order.id).set(data);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteHoldOrder(String id) async {
    try {
      await _firestore.collection('hold_orders').doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addStockEntry(StockEntry entry) async {
    try {
      final data = entry.toJson();
      data['storeId'] = StoreContext().storeId;
      await _firestore.collection('stock_entries').add(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addStockOpname(StockOpnameEntry entry) async {
    try {
      final data = entry.toJson();
      data['storeId'] = StoreContext().storeId;
      await _firestore.collection('stock_opnames').add(data);
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<StockEntry>> streamStockEntries() {
    return _firestore
        .collection('stock_entries')
        .where('storeId', isEqualTo: StoreContext().storeId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => StockEntry.fromJson(doc.data(), doc.id)).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Stream<List<StockOpnameEntry>> streamStockOpnames() {
    return _firestore
        .collection('stock_opnames')
        .where('storeId', isEqualTo: StoreContext().storeId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => StockOpnameEntry.fromJson(doc.data(), doc.id)).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }
}
