import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, staff }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String storeId;
  final List<String> allowedFeatures;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    required this.storeId,
    this.allowedFeatures = const [],
  });

  factory User.fromJson(Map<String, dynamic> json, String id) {
    return User(
      id: id,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.staff,
      ),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      storeId: json['storeId'] ?? id, // Default to id if missing (for legacy data)
      allowedFeatures: (json['allowedFeatures'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'storeId': storeId,
      'allowedFeatures': allowedFeatures,
    };
  }

  bool hasAccess(String feature) {
    if (role == UserRole.admin) return true;
    return allowedFeatures.contains(feature);
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? storeId,
    List<String>? allowedFeatures,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      storeId: storeId ?? this.storeId,
      allowedFeatures: allowedFeatures ?? this.allowedFeatures,
    );
  }
}
