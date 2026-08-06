import 'package:cloud_firestore/cloud_firestore.dart';

class GradeMutation {
  final String id;
  final String sourceProductId;
  final String sourceProductName;
  final String targetProductId;
  final String targetProductName;
  final int quantity;
  final DateTime date;
  final String? createdBy;

  GradeMutation({
    required this.id,
    required this.sourceProductId,
    required this.sourceProductName,
    required this.targetProductId,
    required this.targetProductName,
    required this.quantity,
    required this.date,
    this.createdBy,
  });

  factory GradeMutation.fromJson(Map<String, dynamic> json, String id) {
    return GradeMutation(
      id: id,
      sourceProductId: json['sourceProductId'] ?? '',
      sourceProductName: json['sourceProductName'] ?? '',
      targetProductId: json['targetProductId'] ?? '',
      targetProductName: json['targetProductName'] ?? '',
      quantity: json['quantity'] ?? 0,
      date: (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: json['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sourceProductId': sourceProductId,
      'sourceProductName': sourceProductName,
      'targetProductId': targetProductId,
      'targetProductName': targetProductName,
      'quantity': quantity,
      'date': Timestamp.fromDate(date),
      'createdBy': createdBy,
    };
  }
}
