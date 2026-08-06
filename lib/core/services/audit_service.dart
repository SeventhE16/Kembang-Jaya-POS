import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/audit_log_model.dart';
import 'store_context.dart';

class AuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> logAction(AuditLog log) async {
    try {
      final data = log.toJson();
      data['storeId'] = StoreContext().storeId;
      await _firestore.collection('audit_logs').add(data);
    } catch (e) {
      // Silently fail for audit logs to not block the main process
      print('Failed to save audit log: $e');
    }
  }

  Stream<List<AuditLog>> streamAuditLogs() {
    return _firestore
        .collection('audit_logs')
        .where('storeId', isEqualTo: StoreContext().storeId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AuditLog.fromJson(doc.data(), doc.id))
          .toList();
    });
  }
}
