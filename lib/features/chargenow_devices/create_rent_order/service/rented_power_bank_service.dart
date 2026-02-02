// File: lib/features/chargenow_devices/create_rent_order/service/rented_power_bank_service.dart

import 'dart:developer';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/model/plan.dart';

final rentedPowerBankServiceProvider = Provider<RentedPowerBankService>((ref) {
  return RentedPowerBankService();
});

class RentedPowerBankService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Save a rented power bank record to Firestore
  /// This method ensures the authenticated user matches before saving
  Future<void> saveRentedPowerBank({
    required String deviceId,
    required String tradeNo,
    required Plan selectedPlan,
  }) async {
    try {
      // CRITICAL: Get current authenticated user
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        log('ERROR: No authenticated user found. Cannot save rent record.');
        throw Exception('User not authenticated. Cannot save rent record.');
      }

      final String userId = currentUser.uid;
      log('Saving rent record for authenticated user: $userId');

      // Fetch user profile from Firestore to get phone and name (more reliable than Firebase Auth)
      String userPhone = currentUser.phoneNumber ?? '';
      String userName = currentUser.displayName ?? 'User';

      try {
        // Add timeout to Firestore fetch to prevent hanging
        final userDocFuture = _firestore.collection('users').doc(userId).get();
        final userDoc = await userDocFuture.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            log('⚠️ Firestore user fetch timed out, using Firebase Auth data');
            throw TimeoutException('User profile fetch timeout');
          },
        );

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          // Get phone number from Firestore (more reliable for phone auth users)
          userPhone = userData['phoneNumber'] ?? userPhone;
          // Get full name from Firestore
          userName = userData['fullName'] ?? userData['firstName'] ?? userName;
          log('✅ Fetched user info from Firestore: phone=$userPhone, name=$userName');
        }
      } on TimeoutException {
        log('⚠️ Firestore fetch timeout, using Firebase Auth data as fallback');
      } catch (e) {
        log('⚠️ Could not fetch user profile from Firestore: $e');
        log('Using Firebase Auth data as fallback');
      }

      // Calculate rental period
      final DateTime rentStartDate = DateTime.now();
      final DateTime rentEndDate =
          rentStartDate.add(Duration(days: selectedPlan.durationDays));

      // Calculate reminder time based on plan duration
      final int reminderMinutes = selectedPlan.reminderMinutes;
      final DateTime reminderDateTime =
          rentEndDate.subtract(Duration(minutes: reminderMinutes));

      // Prepare the document data
      final Map<String, dynamic> rentData = {
        'userId': userId, // CRITICAL: Use Firebase Auth UID
        'deviceId': deviceId,
        'tradeNo': tradeNo,
        'planId': selectedPlan.id,
        'planName': selectedPlan.name,
        'planPrice': selectedPlan.price,
        'planCurrency': selectedPlan.currency,
        'planDurationDays': selectedPlan.durationDays,
        'rentStartDate': Timestamp.fromDate(rentStartDate),
        'rentEndDate': Timestamp.fromDate(rentEndDate),
        'rentalEndTime': Timestamp.fromDate(rentEndDate), // For Cloud Function
        'reminderTime':
            Timestamp.fromDate(reminderDateTime), // Dynamic reminder time
        'reminderMinutes': reminderMinutes, // Minutes before end to remind
        'status': 'rented',
        'reminderSMSSent': false, // For reminder SMS tracking
        'lastPenaltyAt': Timestamp.fromDate(rentEndDate),
        'userPhoneNumber': userPhone, // For SMS (from Firestore, more reliable)
        'userName': userName, // For SMS (from Firestore, more reliable)
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      log('Attempting to write to Firestore: rented_power_banks/$tradeNo');
      log('Data: $rentData');

      // Save to Firestore with tradeNo as document ID
      // Add timeout to prevent hanging on slow networks
      await _firestore
          .collection('rented_power_banks')
          .doc(tradeNo)
          .set(rentData, SetOptions(merge: false))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Firestore write operation timed out');
            },
          );

      log('✅ Successfully saved rent record to Firestore for user: $userId, tradeNo: $tradeNo');
    } on FirebaseException catch (e) {
      log('❌ Firebase error saving rent record: ${e.code} - ${e.message}');

      if (e.code == 'permission-denied') {
        throw Exception(
            'Permission denied: User not authenticated. Cannot save rent record.');
      } else if (e.code == 'unauthenticated') {
        throw Exception('User not authenticated. Cannot save rent record.');
      } else {
        throw Exception('Failed to save rent record: ${e.message}');
      }
    } catch (e) {
      log('❌ Unexpected error saving rent record: ${e.toString()}');
      throw Exception('Failed to save rent record: ${e.toString()}');
    }
  }

  /// Get all rented power banks for a specific user
  Future<List<Map<String, dynamic>>> getRentedPowerBanks(String userId) async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null || currentUser.uid != userId) {
        log('ERROR: User not authenticated or UID mismatch');
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('rented_power_banks')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } on FirebaseException catch (e) {
      log('Firebase error getting rent records: ${e.code} - ${e.message}');
      throw Exception('Failed to get rent records: ${e.message}');
    } catch (e) {
      log('Error getting rent records: ${e.toString()}');
      throw Exception('Failed to get rent records: ${e.toString()}');
    }
  }

  /// Get a specific rented power bank by tradeNo
  Future<Map<String, dynamic>?> getRentedPowerBankByTradeNo(
      String tradeNo) async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        log('ERROR: User not authenticated');
        throw Exception('User not authenticated');
      }

      final docSnapshot =
          await _firestore.collection('rented_power_banks').doc(tradeNo).get();

      if (!docSnapshot.exists) {
        return null;
      }

      final data = docSnapshot.data()!;

      // Verify the document belongs to the current user
      if (data['userId'] != currentUser.uid) {
        log('ERROR: Rent record does not belong to current user');
        throw Exception('Access denied');
      }

      data['id'] = docSnapshot.id;
      return data;
    } on FirebaseException catch (e) {
      log('Firebase error getting rent record: ${e.code} - ${e.message}');
      throw Exception('Failed to get rent record: ${e.message}');
    } catch (e) {
      log('Error getting rent record: ${e.toString()}');
      throw Exception('Failed to get rent record: ${e.toString()}');
    }
  }

  /// Update rent status (e.g., from 'active' to 'completed')
  Future<void> updateRentStatus(String tradeNo, String newStatus) async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        log('ERROR: User not authenticated');
        throw Exception('User not authenticated');
      }

      // First verify the document belongs to the current user
      final docSnapshot =
          await _firestore.collection('rented_power_banks').doc(tradeNo).get();

      if (!docSnapshot.exists) {
        throw Exception('Rent record not found');
      }

      final data = docSnapshot.data()!;
      if (data['userId'] != currentUser.uid) {
        log('ERROR: Cannot update rent record - not owned by current user');
        throw Exception('Access denied');
      }

      // Update the status
      await _firestore.collection('rented_power_banks').doc(tradeNo).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      log('✅ Successfully updated rent status to: $newStatus for tradeNo: $tradeNo');
    } on FirebaseException catch (e) {
      log('Firebase error updating rent status: ${e.code} - ${e.message}');

      if (e.code == 'permission-denied') {
        throw Exception('Permission denied: Cannot update rent record');
      } else {
        throw Exception('Failed to update rent status: ${e.message}');
      }
    } catch (e) {
      log('Error updating rent status: ${e.toString()}');
      throw Exception('Failed to update rent status: ${e.toString()}');
    }
  }

  /// Get active rentals for a user
  Future<List<Map<String, dynamic>>> getActiveRentals(String userId) async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null || currentUser.uid != userId) {
        log('ERROR: User not authenticated or UID mismatch');
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('rented_power_banks')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } on FirebaseException catch (e) {
      log('Firebase error getting active rentals: ${e.code} - ${e.message}');
      throw Exception('Failed to get active rentals: ${e.message}');
    } catch (e) {
      log('Error getting active rentals: ${e.toString()}');
      throw Exception('Failed to get active rentals: ${e.toString()}');
    }
  }
}
