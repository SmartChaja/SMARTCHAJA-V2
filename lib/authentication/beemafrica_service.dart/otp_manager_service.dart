// ============================================
// FILE: otp_manager_service.dart
// ============================================
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_chaja/authentication/beemafrica_service.dart/beem_africa_service.dart';
import 'package:smart_chaja/features/core/config/env_config.dart'; // Ensure this path is correct

class OTPManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Instantiate the new BeemAfricaService, injecting the credentials from your config.
  final BeemAfricaService _beemService = BeemAfricaService(
    apiKey: EnvConfig.beemApiKey,
    secretKey: EnvConfig.beemSecretKey,
    senderId: EnvConfig.beemSenderId,
  );

  String generateOTP() {
    return (Random.secure().nextInt(900000) + 100000).toString();
  }

  Future<void> storeOTP({ required String phoneNumber, required String otpCode }) async {
    try {
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));
      final otpData = {
        'code': otpCode, 'phoneNumber': phoneNumber,
        'createdAt': FieldValue.serverTimestamp(), 'expiresAt': Timestamp.fromDate(expiresAt),
        'verified': false, 'attempts': 0,
      };

      await _firestore.collection('otp_codes').doc(phoneNumber).set(otpData);
      debugPrint('✅ OTP stored in Firestore for $phoneNumber');
    } catch (e) {
      debugPrint('❌ Error storing OTP: $e');
      rethrow;
    }
  }

  /// Renamed to reflect its dual responsibility: storing and sending.
  Future<void> sendAndStoreOTP(String phoneNumber) async {
    try {
      final otpCode = generateOTP();
      debugPrint('🔐 Generated OTP: $otpCode for $phoneNumber');
      await storeOTP(phoneNumber: phoneNumber, otpCode: otpCode);

      debugPrint('📤 Attempting to send SMS via Beem Africa...');
      final message = 'Your Smart Chaja verification code is: $otpCode. Valid for 10 minutes.';
      
      final responseData = await _beemService.sendSMS(phoneNumber: phoneNumber, message: message);
      debugPrint('✅ OTP SMS submitted successfully. Response: $responseData');
    } catch (e) {
      debugPrint('❌ A critical error occurred in sendAndStoreOTP: $e');
      try {
        await _firestore.collection('otp_codes').doc(phoneNumber).delete();
        debugPrint('🧹 Cleaned up Firestore document for failed OTP attempt.');
      } catch (cleanupError) {
        debugPrint('⚠️ Error during Firestore cleanup: $cleanupError');
      }
      rethrow;
    }
  }

  Future<bool> verifyOTP({ required String phoneNumber, required String otpCode }) async {
    try {
      final docRef = _firestore.collection('otp_codes').doc(phoneNumber);
      final doc = await docRef.get();

      if (!doc.exists) throw Exception('No OTP found. Please request a new one.');
      
      final data = doc.data()!;
      if (data['verified'] as bool) throw Exception('This OTP has already been used.');
      if (DateTime.now().isAfter((data['expiresAt'] as Timestamp).toDate())) {
        await docRef.delete();
        throw Exception('OTP has expired. Please request a new one.');
      }
      if ((data['attempts'] as int? ?? 0) >= 5) {
        await docRef.delete();
        throw Exception('Too many failed attempts. Please request a new OTP.');
      }

      if (data['code'] as String == otpCode) {
        await docRef.update({'verified': true, 'verifiedAt': FieldValue.serverTimestamp()});
        debugPrint('✅ OTP verified successfully for $phoneNumber');
        return true;
      } else {
        await docRef.update({'attempts': FieldValue.increment(1)});
        final remaining = 4 - (data['attempts'] as int? ?? 0);
        throw Exception('Invalid OTP code. $remaining attempts remaining.');
      }
    } catch (e) {
      debugPrint('❌ Error during OTP verification: $e');
      rethrow;
    }
  }

  Future<void> deleteOTP(String phoneNumber) async {
    try {
      await _firestore.collection('otp_codes').doc(phoneNumber).delete();
      debugPrint('🗑️ Deleted OTP document for $phoneNumber.');
    } catch (e) {
      debugPrint('❌ Error deleting OTP document: $e');
    }
  }
}