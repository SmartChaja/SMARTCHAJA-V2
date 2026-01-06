// lib/features/chargenow_devices/create_rent_order/model/rented_power_bank_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class RentedPowerBank {
  final String id; // Firestore document ID
  final String userId;
  final String userName; // <--- ADDED THIS FIELD
  final String userPhoneNumber; // <--- ADDED THIS FIELD
  final String deviceId;
  final String tradeNo; // The transaction number from the API response
  final DateTime rentStartTime;
  final DateTime? expectedReturnTime; // Based on the plan duration
  final String planId;
  final double planPrice;
  final String planCurrency;
  String status; // e.g., 'rented', 'returned', 'overdue', 'lost'

  RentedPowerBank({
    required this.id,
    required this.userId,
    required this.userName, // <--- Add to constructor
    required this.userPhoneNumber, // <--- Add to constructor
    required this.deviceId,
    required this.tradeNo,
    required this.rentStartTime,
    this.expectedReturnTime,
    required this.planId,
    required this.planPrice,
    required this.planCurrency,
    this.status = 'rented',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName, // <--- Add to map
      'userPhoneNumber': userPhoneNumber, // <--- Add to map
      'deviceId': deviceId,
      'tradeNo': tradeNo,
      'rentStartTime': Timestamp.fromDate(rentStartTime),
      'expectedReturnTime': expectedReturnTime != null ? Timestamp.fromDate(expectedReturnTime!) : null,
      'planId': planId,
      'planPrice': planPrice,
      'planCurrency': planCurrency,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory RentedPowerBank.fromMap(String id, Map<String, dynamic> map) {
    return RentedPowerBank(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '', // <--- Read from map
      userPhoneNumber: map['userPhoneNumber'] ?? '', // <--- Read from map
      deviceId: map['deviceId'] ?? '',
      tradeNo: map['tradeNo'] ?? '',
      rentStartTime: (map['rentStartDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expectedReturnTime: (map['rentEndDate'] as Timestamp?)?.toDate(),
      planId: map['planId'] ?? '',
      planPrice: (map['planPrice'] as num?)?.toDouble() ?? 0.0,
      planCurrency: map['planCurrency'] ?? '',
      status: map['status'] ?? 'rented',
    );
  }

  RentedPowerBank copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhoneNumber,
    String? deviceId,
    String? tradeNo,
    DateTime? rentStartTime,
    DateTime? expectedReturnTime,
    String? planId,
    double? planPrice,
    String? planCurrency,
    String? status,
  }) {
    return RentedPowerBank(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhoneNumber: userPhoneNumber ?? this.userPhoneNumber,
      deviceId: deviceId ?? this.deviceId,
      tradeNo: tradeNo ?? this.tradeNo,
      rentStartTime: rentStartTime ?? this.rentStartTime,
      expectedReturnTime: expectedReturnTime ?? this.expectedReturnTime,
      planId: planId ?? this.planId,
      planPrice: planPrice ?? this.planPrice,
      planCurrency: planCurrency ?? this.planCurrency,
      status: status ?? this.status,
    );
  }
}