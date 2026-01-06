
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String phoneNumber;
  final String fullName;
  final String gender;
  final DateTime dateOfBirth;
  final String nationalId;
  final String? profilePictureUrl;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double balance;
  final double debt;           
  final int totalPenalties;    

  UserModel({
    required this.uid,
    required this.phoneNumber,
    required this.fullName,
    required this.gender,
    required this.dateOfBirth,
    required this.nationalId,
    this.profilePictureUrl,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.balance = 0.0,
    this.debt = 0.0,           
    this.totalPenalties = 0,    
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      fullName: map['fullName'] ?? '',
      gender: map['gender'] ?? '',
      dateOfBirth: (map['dateOfBirth'] is Timestamp
          ? (map['dateOfBirth'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['dateOfBirth'] ?? 0)),
      nationalId: map['nationalId'] ?? '',
      profilePictureUrl: map['profilePictureUrl'],
      role: map['role'] ?? 'member',
      createdAt: (map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0)),
      updatedAt: (map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0)),
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      debt: (map['debt'] as num?)?.toDouble() ?? 0.0,           
      totalPenalties: (map['totalPenalties'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      'gender': gender,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'nationalId': nationalId,
      'profilePictureUrl': profilePictureUrl,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'balance': balance,
      'debt': debt,           
      'totalPenalties': totalPenalties,
    };
  }

  UserModel copyWith({
    String? uid,
    String? phoneNumber,
    String? fullName,
    String? gender,
    DateTime? dateOfBirth,
    String? nationalId,
    String? profilePictureUrl,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? balance,
    double? debt,           
    int? totalPenalties,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nationalId: nationalId ?? this.nationalId,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      balance: balance ?? this.balance,
      debt: debt ?? this.debt,           
      totalPenalties: totalPenalties ?? this.totalPenalties,
    );
  }
}
