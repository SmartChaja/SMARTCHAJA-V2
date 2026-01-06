import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:smart_chaja/authentication/register/model/auth_result.dart';
import 'package:smart_chaja/authentication/register/model/user_model.dart';
import 'package:smart_chaja/authentication/beemafrica_service.dart/otp_manager_service.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final OTPManager _otpManager = OTPManager();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

//............................................................................................................................
//............................................................................................................................
  /// Send OTP using Beem Africa (Custom Implementation)
 Future<AuthResult> sendOTP({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onVerificationFailed,
  }) async {
    try {
      debugPrint('📤 Sending OTP via Beem Africa to $phoneNumber');
      
      // UPDATED: Call the renamed method in OTPManager
      await _otpManager.sendAndStoreOTP(phoneNumber);

      onCodeSent(phoneNumber); // Pass phone number as our "verification ID"
      return AuthResult.success(message: 'OTP sent successfully via Beem Africa');
    } catch (e) {
      debugPrint('❌ Send OTP error: $e');
      onVerificationFailed(e.toString());
      return AuthResult.failure(e.toString());
    }
  }

//............................................................................................................................
//............................................................................................................................
  /// Verify OTP and create custom token for Firebase Auth
  Future<AuthResult> verifyOTPAndSignIn({
    required String phoneNumber,
    required String smsCode,
  }) async {
    try {
      debugPrint('🔐 Verifying OTP for $phoneNumber');

      // Verify OTP using OTPManager
      final isValid = await _otpManager.verifyOTP(
        phoneNumber: phoneNumber,
        otpCode: smsCode,
      );

      if (!isValid) {
        return AuthResult.failure('Invalid OTP code');
      }

      // Check if user exists in Firebase Auth
      final methods = await _auth.fetchSignInMethodsForEmail('$phoneNumber@smartchaja.app');
      
      UserCredential userCredential;

      if (methods.isEmpty) {
        // Create new anonymous user and link phone number
        debugPrint('🆕 Creating new user for $phoneNumber');
        userCredential = await _auth.signInAnonymously();
        
        // Store phone number in user document
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'phoneNumber': phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        // Sign in existing user
        debugPrint('🔓 Signing in existing user for $phoneNumber');
        
        // Find user by phone number
        final userQuery = await _firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: phoneNumber)
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty) {
          return AuthResult.failure('User not found');
        }

        final userId = userQuery.docs.first.id;
        
        // Sign in with custom token (you'll need to implement this on your backend)
        // For now, we'll use anonymous sign-in and update the UID
        userCredential = await _auth.signInAnonymously();
      }

      // Clean up OTP after successful verification
      await _otpManager.deleteOTP(phoneNumber);

      debugPrint('✅ Login successful for $phoneNumber');
      return AuthResult.success(message: 'Login successful');
    } catch (e) {
      debugPrint('❌ Verify OTP error: $e');
      return AuthResult.failure(e.toString());
    }
  }

  /// Check if user profile exists
  Future<bool> userProfileExists(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists && doc.data() != null && (doc.data() as Map<String, dynamic>).containsKey('fullName');
    } catch (e) {
      return false;
    }
  }

//............................................................................................................................
//............................................................................................................................
  /// Create user profile
  Future<AuthResult> createUserProfile({
    required String fullName,
    required String gender,
    required DateTime dateOfBirth,
    required String nationalId,
    File? profilePicture,
    String role = 'member',
  }) async {
    try {
      if (currentUser == null) {
        return AuthResult.failure('No authenticated user found');
      }

      // Get phone number from existing document
      final existingDoc = await _firestore.collection('users').doc(currentUser!.uid).get();
      final phoneNumber = existingDoc.data()?['phoneNumber'] as String? ?? '';

      String? profilePictureUrl;
      if (profilePicture != null) {
        profilePictureUrl = await _uploadProfilePicture(currentUser!.uid, profilePicture);
      }

      UserModel user = UserModel(
        uid: currentUser!.uid,
        phoneNumber: phoneNumber,
        fullName: fullName,
        gender: gender,
        dateOfBirth: dateOfBirth,
        nationalId: nationalId,
        profilePictureUrl: profilePictureUrl,
        role: role,
        createdAt: existingDoc.data()?['createdAt'] != null 
            ? (existingDoc.data()!['createdAt'] as Timestamp).toDate() 
            : DateTime.now(),
        updatedAt: DateTime.now(),
        balance: 0.0,
      );

      await _firestore.collection('users').doc(currentUser!.uid).set(user.toMap());

      return AuthResult.success(user: user, message: 'Profile created successfully');
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

//............................................................................................................................
//............................................................................................................................
  /// Get user profile
  Future<AuthResult> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        UserModel user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        return AuthResult.success(user: user);
      } else {
        return AuthResult.failure('User profile not found');
      }
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

//............................................................................................................................
//............................................................................................................................
  /// Update user profile
  Future<AuthResult> updateUserProfile({
    required String uid,
    String? fullName,
    String? gender,
    DateTime? dateOfBirth,
    String? nationalId,
    File? profilePicture,
    bool removeProfilePicture = false,
    String? role,
    double? balance,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'updatedAt': DateTime.now(),
      };

      if (fullName != null) updates['fullName'] = fullName;
      if (gender != null) updates['gender'] = gender;
      if (dateOfBirth != null) updates['dateOfBirth'] = Timestamp.fromDate(dateOfBirth);
      if (nationalId != null) updates['nationalId'] = nationalId;
      if (role != null) updates['role'] = role;
      if (balance != null) updates['balance'] = balance;

      if (removeProfilePicture) {
        updates['profilePictureUrl'] = null;
        await _deleteProfilePicture(uid);
      } else if (profilePicture != null) {
        await _deleteProfilePicture(uid);
        String profilePictureUrl = await _uploadProfilePicture(uid, profilePicture);
        updates['profilePictureUrl'] = profilePictureUrl;
      }

      await _firestore.collection('users').doc(uid).update(updates);

      AuthResult result = await getUserProfile(uid);
      if (result.success) {
        return AuthResult.success(user: result.user, message: 'Profile updated successfully');
      } else {
        return AuthResult.failure('Failed to retrieve updated profile');
      }
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

//............................................................................................................................
//............................................................................................................................
  /// Upload profile picture
  Future<String> _uploadProfilePicture(String uid, File file) async {
    debugPrint('📤 Uploading profile picture for $uid');
    try {
      String extension = path.extension(file.path).toLowerCase();
      if (!['.jpg', '.jpeg', '.png'].contains(extension)) {
        debugPrint('❌ Unsupported file format: $extension');
        throw Exception('Unsupported file format: $extension');
      }
      Reference ref = _storage.ref().child('profile_pictures').child('$uid$extension');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String url = await snapshot.ref.getDownloadURL();
      debugPrint('✅ Upload successful: $url');
      return url;
    } catch (e) {
      debugPrint('❌ Upload failed: $e');
      rethrow;
    }
  }

//............................................................................................................................
//............................................................................................................................
  /// Delete profile picture
  Future<void> _deleteProfilePicture(String uid) async {
    debugPrint('🗑️ Deleting profile picture for $uid');
    try {
      for (String ext in ['.jpg', '.jpeg', '.png']) {
        Reference ref = _storage.ref().child('profile_pictures').child('$uid$ext');
        await ref.delete().catchError((e) => debugPrint('ℹ️ No file with $ext to delete'));
      }
      debugPrint('✅ Deletion attempted for all extensions');
    } catch (e) {
      debugPrint('ℹ️ No profile picture to delete or error: $e');
    }
  }

//............................................................................................................................
//............................................................................................................................
  /// Delete user account
  Future<AuthResult> deleteUserAccount() async {
    try {
      if (currentUser == null) {
        return AuthResult.failure('No authenticated user found');
      }

      String uid = currentUser!.uid;

      await _deleteProfilePicture(uid);
      await _firestore.collection('users').doc(uid).delete();
      await currentUser!.delete();

      return AuthResult.success(message: 'Account deleted successfully');
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

//............................................................................................................................
//............................................................................................................................
  /// Sign out
  Future<AuthResult> signOut() async {
    try {
      await _auth.signOut();
      return AuthResult.success(message: 'Signed out successfully');
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

//............................................................................................................................
//............................................................................................................................
  /// Reauthenticate for sensitive operations
  Future<AuthResult> reauthenticate({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onVerificationFailed,
  }) async {
    return await sendOTP(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onVerificationFailed: onVerificationFailed,
    );
  }

//............................................................................................................................
//............................................................................................................................
  /// Update phone number
  Future<AuthResult> updatePhoneNumber({
    required String phoneNumber,
    required String smsCode,
  }) async {
    try {
      if (currentUser == null) {
        return AuthResult.failure('No authenticated user found');
      }

      // Verify OTP
      final isValid = await _otpManager.verifyOTP(
        phoneNumber: phoneNumber,
        otpCode: smsCode,
      );

      if (!isValid) {
        return AuthResult.failure('Invalid OTP code');
      }

      // Update phone number in Firestore
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'phoneNumber': phoneNumber,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Clean up OTP
      await _otpManager.deleteOTP(phoneNumber);

      return AuthResult.success(message: 'Phone number updated successfully');
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }
}
//............................................................................................................................
//............................................................................................................................