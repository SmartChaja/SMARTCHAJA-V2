

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:smart_chaja/authentication/register/model/auth_result.dart';
import 'package:smart_chaja/authentication/register/service/firebase_auth_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthRepository {
  final FirebaseAuthService _authService = FirebaseAuthService();

  Stream<User?> get authStateChanges => _authService.authStateChanges;
  User? get currentUser => _authService.currentUser;

  Future<AuthResult> sendOTP({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onVerificationFailed,
    TextEditingController? pinController, // Add pin controller parameter
    required Function() onAutoVerificationCompleted, // Add auto verification callback
  }) {
    return _authService.sendOTP(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onVerificationFailed: onVerificationFailed,
      pinController: pinController, // Pass pin controller
      onAutoVerificationCompleted: onAutoVerificationCompleted, // Pass callback
    );
  }

  Future<AuthResult> verifyOTPAndSignIn({
    required String verificationId,
    required String smsCode,
  }) {
    return _authService.verifyOTPAndSignIn(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  Future<bool> userProfileExists(String uid) {
    return _authService.userProfileExists(uid);
  }

  Future<AuthResult> createUserProfile({
    required String fullName,
    required String gender,
    required DateTime dateOfBirth,
    required String nationalId,
    File? profilePicture,
    String role = 'member',
  }) {
    return _authService.createUserProfile(
      fullName: fullName,
      gender: gender,
      dateOfBirth: dateOfBirth,
      nationalId: nationalId,
      profilePicture: profilePicture,
      role: role,
    );
  }

  Future<AuthResult> getUserProfile(String uid) {
    return _authService.getUserProfile(uid);
  }

  Future<AuthResult> updateUserProfile({
    required String uid,
    String? fullName,
    String? gender,
    DateTime? dateOfBirth,
    String? nationalId,
    File? profilePicture,
    bool removeProfilePicture = false,
    String? role,
  }) {
    return _authService.updateUserProfile(
      uid: uid,
      fullName: fullName,
      gender: gender,
      dateOfBirth: dateOfBirth,
      nationalId: nationalId,
      profilePicture: profilePicture,
      removeProfilePicture: removeProfilePicture,
      role: role,
    );
  }

  Future<AuthResult> deleteUserAccount() {
    return _authService.deleteUserAccount();
  }

  Future<AuthResult> signOut() {
    return _authService.signOut();
  }

  Future<AuthResult> reauthenticate({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onVerificationFailed,
    TextEditingController? pinController, // Add pin controller parameter
    required Function() onAutoVerificationCompleted, // Add auto verification callback
  }) {
    return _authService.reauthenticate(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onVerificationFailed: onVerificationFailed,
      pinController: pinController, // Pass pin controller
      onAutoVerificationCompleted: onAutoVerificationCompleted, // Pass callback
    );
  }

  Future<AuthResult> updatePhoneNumber({
    required String verificationId,
    required String smsCode,
  }) {
    return _authService.updatePhoneNumber(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }
}

