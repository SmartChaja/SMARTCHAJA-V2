import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id; // Firestore document ID
  final String userId;
  final double amount;
  final String currency;
  final String provider;
  final String status; // pending, confirmed, failed
  final String? transactionId; // Mobile checkout
  final String? referenceId; // Bank checkout
  final String? externalId; // Mobile checkout
  final DateTime createdAt;
  final DateTime? updatedAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.provider,
    required this.status,
    this.transactionId,
    this.referenceId,
    this.externalId,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'provider': provider,
      'status': status,
      'transactionId': transactionId,
      'referenceId': referenceId,
      'externalId': externalId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return TransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? '',
      provider: map['provider'] ?? '',
      status: map['status'] ?? 'pending',
      transactionId: map['transactionId'],
      referenceId: map['referenceId'],
      externalId: map['externalId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}


