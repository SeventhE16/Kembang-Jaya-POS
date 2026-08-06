import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../../data/models/transaction_model.dart';
import 'store_context.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Transaction>> streamTransactions() {
    return _firestore
        .collection('transactions')
        .where('storeId', isEqualTo: StoreContext().storeId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => Transaction.fromJson(doc.data(), doc.id)).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      final counterRef = _firestore.collection('metadata').doc('invoice_counter');
      final newTxRef = _firestore.collection('transactions').doc(); // Auto ID

      await _firestore.runTransaction((tx) async {
        final snapshot = await tx.get(counterRef);
        int currentCount = 0;
        if (snapshot.exists) {
          currentCount = snapshot.data()?['count'] ?? 0;
        }
        final newCount = currentCount + 1;
        
        final now = DateTime.now();
        final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
        final seqStr = newCount.toString().padLeft(4, '0');
        final invoiceNum = transaction.type == 'purchase' 
            ? 'PO-$dateStr-$seqStr' 
            : 'INV-$dateStr-$seqStr';

        tx.set(counterRef, {'count': newCount});
        
        // Batch stock reduction or addition
        for (var item in transaction.items) {
          if (item.product.category != 'Jasa') {
            final productRef = _firestore.collection('products').doc(item.product.id);
            final int stockDelta = transaction.type == 'purchase' ? item.quantity : -item.quantity;
            tx.update(productRef, {'stock': FieldValue.increment(stockDelta)});
          }
        }
        
        final finalTx = transaction.copyWith(
          id: newTxRef.id,
          invoiceNumber: invoiceNum,
        );
        
        final data = finalTx.toJson();
        data['storeId'] = StoreContext().storeId;
        tx.set(newTxRef, data);
      });
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

  // --- Cicilan Piutang (Sub-Collection) ---
  Future<void> addInstallment(String txId, InstallmentPayment installment) async {
    try {
      final txRef = _firestore.collection('transactions').doc(txId);
      final instRef = txRef.collection('installments').doc();
      
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
        .collection('transactions')
        .doc(txId)
        .collection('installments')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InstallmentPayment.fromJson(doc.data(), doc.id))
            .toList());
  }

  Stream<List<InstallmentPayment>> streamAllInstallments() {
    return _firestore
        .collectionGroup('installments')
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
