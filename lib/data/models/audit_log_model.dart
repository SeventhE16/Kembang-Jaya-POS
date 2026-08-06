import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLog {
  final String id;
  final String action;
  final String description;
  final String userId;
  final String userName;
  final DateTime timestamp;

  AuditLog({
    required this.id,
    required this.action,
    required this.description,
    required this.userId,
    required this.userName,
    required this.timestamp,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json, String id) {
    return AuditLog(
      id: id,
      action: json['action'] ?? '',
      description: json['description'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'description': description,
      'userId': userId,
      'userName': userName,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
