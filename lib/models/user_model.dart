import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, admin }

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String? matricule;
  final String? faculty;
  final String? promotion;
  final String? phoneNumber;
  final String? address;
  final String? profileImageUrl;
  final UserRole role;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isActive;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.matricule,
    this.faculty,
    this.promotion,
    this.phoneNumber,
    this.address,
    this.profileImageUrl,
    required this.role,
    required this.createdAt,
    required this.lastLogin,
    required this.isActive,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      matricule: map['matricule'],
      faculty: map['faculty'],
      promotion: map['promotion'],
      phoneNumber: map['phoneNumber'],
      address: map['address'],
      profileImageUrl: map['profileImageUrl'],
      role: map['role'] == 'admin' ? UserRole.admin : UserRole.student,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastLogin: (map['lastLogin'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'matricule': matricule,
      'faculty': faculty,
      'promotion': promotion,
      'phoneNumber': phoneNumber,
      'address': address,
      'profileImageUrl': profileImageUrl,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'isActive': isActive,
    };
  }

  UserModel copyWith({
    String? fullName,
    String? email,
    String? matricule,
    String? faculty,
    String? promotion,
    String? phoneNumber,
    String? address,
    String? profileImageUrl,
    UserRole? role,
    DateTime? lastLogin,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      matricule: matricule ?? this.matricule,
      faculty: faculty ?? this.faculty,
      promotion: promotion ?? this.promotion,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
    );
  }
}
