import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../../data/models/transaction_model.dart';
import '../../data/providers/transaction_provider.dart';
import '../../data/providers/settings_provider.dart';
import '../../data/providers/auth_provider.dart';
import 'store_context.dart';
import '../utils/struk_generator.dart';

class StrukMigrationService {
  static bool _hasRun = false;

  static Future<void> runMigration(BuildContext context) async {
    if (_hasRun) return;
    _hasRun = true;

    final storeId = StoreContext().storeIdOrNull;
    if (storeId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('storeId', isEqualTo: storeId)
          .where('strukUrl', isNull: true)
          .get();

      if (snapshot.docs.isEmpty) {
        return; // Nothing to migrate
      }

      final controller = ScreenshotController();
      final txProv = Provider.of<TransactionProvider>(context, listen: false);
      final settings = Provider.of<SettingsProvider>(context, listen: false).settings;
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;

      for (var doc in snapshot.docs) {
        final tx = Transaction.fromJson(doc.data(), doc.id);
        
        try {
          final isRestock = tx.type == 'purchase';
          final widget = StrukGenerator.buildStrukContent(
            context: context, 
            transaction: tx, 
            settings: settings,
            user: user,
            isRestock: isRestock
          );
          final bytes = await controller.captureFromWidget(widget);

          final ref = FirebaseStorage.instance.ref('struk/${tx.id}.png');
          await ref.putData(bytes);
          final url = await ref.getDownloadURL();

          final updatedTx = tx.copyWith(strukUrl: url);
          await txProv.updateTransaction(updatedTx);
          debugPrint('Migrated struk for TX: ${tx.id}');
        } catch (e) {
          debugPrint('Failed to migrate struk for TX ${tx.id}: $e');
        }
      }
      
      debugPrint('Migration struk selesai!');
    } catch (e) {
      debugPrint('Migration query error: $e');
    }
  }
}
