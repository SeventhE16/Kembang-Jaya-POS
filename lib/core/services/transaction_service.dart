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
        final List<CartItem> updatedItems = [];
        for (int i = 0; i < transaction.items.length; i++) {
          CartItem item = transaction.items[i];
          CartItem finalItem = item;
          if (item.product.category != 'Jasa') {
            final productRef = _firestore.collection('products').doc(item.product.id);
            final productDoc = await tx.get(productRef);
            
            if (productDoc.exists) {
              final product = Product.fromJson(productDoc.data()!, productDoc.id);
              List<StockBatch> currentBatches = List.from(product.stockBatches);
              
              if (transaction.type == 'purchase') {
                // Add new batch
                currentBatches.add(StockBatch(
                  id: '${DateTime.now().microsecondsSinceEpoch}_$i',
                  quantity: item.quantity,
                  basePrice: item.product.basePrice,
                  dateAdded: DateTime.now(),
                ));
              } else {
                // Sale - FIFO logic
                int remainingToDeduct = item.quantity;
                double totalCogs = 0;
                
                // Sort by oldest dateAdded first just in case
                currentBatches.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
                
                for (int j = 0; j < currentBatches.length; j++) {
                  if (remainingToDeduct <= 0) break;
                  
                  if (currentBatches[j].quantity > 0) {
                    int qtyToTake = remainingToDeduct <= currentBatches[j].quantity ? remainingToDeduct : currentBatches[j].quantity;
                    totalCogs += qtyToTake * currentBatches[j].basePrice;
                    currentBatches[j].quantity -= qtyToTake;
                    remainingToDeduct -= qtyToTake;
                  }
                }
                
                // Fallback for negative stock (sold more than tracked in batches)
                if (remainingToDeduct > 0) {
                  totalCogs += remainingToDeduct * product.basePrice;
                }
                
                // Clean up empty batches
                currentBatches.removeWhere((b) => b.quantity <= 0);
                
                // Update item's cogs
                finalItem = CartItem(
                  product: item.product,
                  quantity: item.quantity,
                  customPrice: item.customPrice,
                  itemDiscount: item.itemDiscount,
                  note: item.note,
                  cogs: totalCogs,
                );
              }
              
              final int stockDelta = transaction.type == 'purchase' ? item.quantity : -item.quantity;
              tx.update(productRef, {
                'stock': FieldValue.increment(stockDelta),
                'stockBatches': currentBatches.map((e) => e.toJson()).toList(),
              });
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
        tx.set(newTxRef, data);
      });
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
        // 1. REVERT stok dari transaksi lama
        for (var oldItem in oldTx.items) {
          if (oldItem.product.category == 'Jasa') continue;
          final productRef = _firestore.collection('products').doc(oldItem.product.id);
          final productDoc = await ftx.get(productRef);
          if (!productDoc.exists) continue;

          final product = Product.fromJson(productDoc.data()!, productDoc.id);
          List<StockBatch> batches = List.from(product.stockBatches);

          // Kembalikan stok dengan menambahkan batch baru dari transaksi lama
          batches.add(StockBatch(
            id: 'revert_${oldTx.id}_${oldItem.product.id}',
            quantity: oldItem.quantity,
            basePrice: oldItem.cogs != null && oldItem.quantity > 0
                ? (oldItem.cogs! / oldItem.quantity)
                : oldItem.product.basePrice,
            dateAdded: oldTx.date,
          ));

          ftx.update(productRef, {
            'stock': FieldValue.increment(oldItem.quantity),
            'stockBatches': batches.map((e) => e.toJson()).toList(),
          });
        }

        // 2. POTONG stok dari transaksi baru (FIFO)
        final List<CartItem> updatedItems = [];
        for (var newItem in newTx.items) {
          if (newItem.product.category == 'Jasa') {
            updatedItems.add(newItem);
            continue;
          }
          final productRef = _firestore.collection('products').doc(newItem.product.id);
          final productDoc = await ftx.get(productRef);

          CartItem finalItem = newItem;
          if (productDoc.exists) {
            final product = Product.fromJson(productDoc.data()!, productDoc.id);
            List<StockBatch> batches = List.from(product.stockBatches);
            batches.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));

            int remaining = newItem.quantity;
            double totalCogs = 0;
            for (int j = 0; j < batches.length; j++) {
              if (remaining <= 0) break;
              if (batches[j].quantity > 0) {
                int take = remaining <= batches[j].quantity ? remaining : batches[j].quantity;
                totalCogs += take * batches[j].basePrice;
                batches[j].quantity -= take;
                remaining -= take;
              }
            }
            if (remaining > 0) {
              totalCogs += remaining * product.basePrice;
            }
            batches.removeWhere((b) => b.quantity <= 0);

            ftx.update(productRef, {
              'stock': FieldValue.increment(-newItem.quantity),
              'stockBatches': batches.map((e) => e.toJson()).toList(),
            });

            finalItem = CartItem(
              product: newItem.product,
              quantity: newItem.quantity,
              customPrice: newItem.customPrice,
              itemDiscount: newItem.itemDiscount,
              note: newItem.note,
              cogs: totalCogs,
            );
          }
          updatedItems.add(finalItem);
        }

        // 3. Tulis ulang dokumen transaksi
        finalTx = newTx.copyWith(
          items: updatedItems,
          payAmount: finalPayAmount,
          debtAmount: newDebt,
          paymentMethod: finalPaymentMethod,
          updatedAt: DateTime.now(),
        );

        final data = finalTx.toJson();
        data['storeId'] = StoreContext().storeId;
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
