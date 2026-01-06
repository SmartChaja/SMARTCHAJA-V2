
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_chaja/features/chargenow_devices/payment/azam/model/transaction_model.dart';
import 'package:smart_chaja/features/chargenow_devices/payment/azam/service/azampay.dart';
import 'package:smart_chaja/features/core/config/env_config.dart';
import 'package:uuid/uuid.dart';

class PaymentService {
  final AzamPay azamPay;
  final Uuid uuid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  PaymentService()
      : azamPay = AzamPay(
          appName: EnvConfig.appName,
          clientId: EnvConfig.clientId,
          clientSecret: EnvConfig.clientSecret,
          xApiKey: EnvConfig.xApiKey,
          sandbox: EnvConfig.useSandbox,
        ),
        uuid = const Uuid();

  Future<Map<String, dynamic>> performMobileCheckout({
    required String merchantMobileNumber,
    required String amount,
    required String currency,
    required String provider,
    Map<String, dynamic>? additionalProperties,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('No authenticated user found');
      return {
        'success': false,
        'message': 'No authenticated user found',
        'transactionId': '',
        'externalId': '',
        'transactionDocId': '',
      };
    }

    debugPrint('Authenticated user: ${user.uid}');
    String externalId = uuid.v4();
    String transactionDocId = uuid.v4();
    double parsedAmount = double.tryParse(amount) ?? 0.0;

    try {
      final response = await azamPay.mobileCheckout(
        merchantMobileNumber: merchantMobileNumber,
        amount: amount,
        currency: currency,
        provider: provider,
        externalId: externalId,
        callbackUrl: EnvConfig.callbackUrl,
        additionalProperties: {
          ...?additionalProperties,
          'userId': user.uid,
          'transactionDocId': transactionDocId,
        },
      );

      debugPrint('Raw response body: ${response?.body}');
      if (response == null) {
        debugPrint('Mobile checkout response is null');
        return {
          'success': false,
          'message': 'Payment request failed: No response from server',
          'transactionId': '',
          'externalId': externalId,
          'transactionDocId': '',
        };
      }

      var responseData = json.decode(response.body);
      debugPrint('Full API Response: $responseData');

      if (!(responseData['success'] ?? false)) {
        debugPrint('API response indicates failure: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Payment request failed',
          'transactionId': '',
          'externalId': externalId,
          'transactionDocId': '',
        };
      }

      // Extract transactionId from response
      String transactionId = responseData['transactionId']?.toString() ??
          responseData['data']?['transactionId']?.toString() ??
          externalId; // Fallback to externalId if transactionId is missing

      // Save transaction with transactionId
      final transactionData = TransactionModel(
        id: transactionDocId,
        userId: user.uid,
        amount: parsedAmount,
        currency: currency,
        provider: provider,
        status: 'pending',
        externalId: externalId,
        transactionId: transactionId,
        createdAt: DateTime.now(),
      ).toMap();
      transactionData['createdAt'] = Timestamp.fromDate(transactionData['createdAt'] as DateTime);
      debugPrint('Creating transaction: $transactionData');
      try {
        await _firestore.collection('transactions').doc(transactionDocId).set(transactionData);
        debugPrint('Transaction created: $transactionDocId');
      } catch (e) {
        debugPrint('Error creating transaction: $e');
        return {
          'success': false,
          'message': 'Failed to create transaction: $e',
          'transactionId': transactionId,
          'externalId': externalId,
          'transactionDocId': transactionDocId,
        };
      }

      return {
        'success': true,
        'message': 'Payment initiated successfully',
        'transactionId': transactionId,
        'externalId': externalId,
        'transactionDocId': transactionDocId,
      };
    } catch (e) {
      debugPrint('Error in performMobileCheckout: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'transactionId': '',
        'externalId': externalId,
        'transactionDocId': '',
      };
    }
  }

  Future<Map<String, dynamic>> performBankCheckout({
    required String merchantAccountNumber,
    required String merchantMobileNumber,
    String? merchantName,
    required String amount,
    required String currency,
    required String provider,
    required String otp,
    Map<String, dynamic>? additionalProperties,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('No authenticated user found');
      return {
        'success': false,
        'message': 'No authenticated user found',
        'referenceId': '',
        'transactionDocId': '',
      };
    }

    debugPrint('Authenticated user: ${user.uid}');
    String referenceId = uuid.v4();
    String transactionDocId = uuid.v4();
    double parsedAmount = double.tryParse(amount) ?? 0.0;

    try {
      final response = await azamPay.bankCheckout(
        merchantAccountNumber: merchantAccountNumber,
        merchantMobileNumber: merchantMobileNumber,
        merchantName: merchantName,
        amount: amount,
        currency: currency,
        provider: provider,
        otp: otp,
        referenceId: referenceId,
        callbackUrl: EnvConfig.callbackUrl,
        additionalProperties: {
          ...?additionalProperties,
          'userId': user.uid,
          'transactionDocId': transactionDocId,
        },
      );

      debugPrint('Raw response body: ${response?.body}');
      if (response == null) {
        debugPrint('Bank checkout response is null');
        return {
          'success': false,
          'message': 'Bank payment request failed: No response from server',
          'referenceId': referenceId,
          'transactionDocId': '',
        };
      }

      var responseData = json.decode(response.body);
      debugPrint('Full API Response: $responseData');

      if (!(responseData['success'] ?? false)) {
        debugPrint('API response indicates failure: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Bank payment request failed',
          'referenceId': referenceId,
          'transactionDocId': '',
        };
      }

      // Extract referenceId from response or use generated one
      String finalReferenceId = responseData['data']?['referenceId']?.toString() ?? referenceId;

      // Save transaction with referenceId
      final transactionData = TransactionModel(
        id: transactionDocId,
        userId: user.uid,
        amount: parsedAmount,
        currency: currency,
        provider: provider,
        status: 'pending',
        referenceId: finalReferenceId,
        createdAt: DateTime.now(),
      ).toMap();
      transactionData['createdAt'] = Timestamp.fromDate(transactionData['createdAt'] as DateTime);
      debugPrint('Creating transaction: $transactionData');
      try {
        await _firestore.collection('transactions').doc(transactionDocId).set(transactionData);
        debugPrint('Transaction created: $transactionDocId');
      } catch (e) {
        debugPrint('Error creating transaction: $e');
        return {
          'success': false,
          'message': 'Failed to create transaction: $e',
          'referenceId': finalReferenceId,
          'transactionDocId': transactionDocId,
        };
      }

      return {
        'success': true,
        'message': 'Bank payment initiated successfully',
        'referenceId': finalReferenceId,
        'transactionDocId': transactionDocId,
      };
    } catch (e) {
      debugPrint('Error in performBankCheckout: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'referenceId': referenceId,
        'transactionDocId': '',
      };
    }
  }
}