import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:smart_chaja/authentication/register/model/auth_result.dart';
import 'package:smart_chaja/authentication/register/model/user_model.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool _isVerificationHandled = false;

  // Send OTP
  Future<AuthResult> sendOTP({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onVerificationFailed,
    TextEditingController? pinController,
    required Function() onAutoVerificationCompleted,
  }) async {
    _isVerificationHandled = false;

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (_isVerificationHandled) return;
          _isVerificationHandled = true;

          try {
            // Auto-fill the SMS code if pinController is provided
            if (pinController != null && credential.smsCode != null) {
              pinController.text = credential.smsCode!;
            }

            await _auth.signInWithCredential(credential);
            onAutoVerificationCompleted();
          } catch (e) {
            onVerificationFailed('Auto sign-in failed: ${e.toString()}');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onVerificationFailed(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _isVerificationHandled = false;
        },
        timeout: const Duration(seconds: 60),
      );
      return AuthResult.success(message: 'OTP sent successfully');
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  // Verify OTP and Sign In
  Future<AuthResult> verifyOTPAndSignIn({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        return AuthResult.success(message: 'Login successful');
      } else {
        return AuthResult.failure('Login failed');
      }
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  // Check if user profile exists
  Future<bool> userProfileExists(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Create user profile
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

      String? profilePictureUrl;
      if (profilePicture != null) {
        profilePictureUrl =
            await _uploadProfilePicture(currentUser!.uid, profilePicture);
      }

      UserModel user = UserModel(
        uid: currentUser!.uid,
        phoneNumber: currentUser!.phoneNumber ?? '',
        fullName: fullName,
        gender: gender,
        dateOfBirth: dateOfBirth,
        nationalId: nationalId,
        profilePictureUrl: profilePictureUrl,
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        balance: 0.0,
      );

      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .set(user.toMap());

      return AuthResult.success(
          user: user, message: 'Profile created successfully');
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  // Get user profile
  Future<AuthResult> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();

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

  // Update user profile
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
      if (dateOfBirth != null)
        updates['dateOfBirth'] = Timestamp.fromDate(dateOfBirth);
      if (nationalId != null) updates['nationalId'] = nationalId;
      if (role != null) updates['role'] = role;
      if (balance != null) updates['balance'] = balance;

      if (removeProfilePicture) {
        updates['profilePictureUrl'] = null;
        await _deleteProfilePicture(uid);
      } else if (profilePicture != null) {
        await _deleteProfilePicture(uid);
        String profilePictureUrl =
            await _uploadProfilePicture(uid, profilePicture);
        updates['profilePictureUrl'] = profilePictureUrl;
      }

      await _firestore.collection('users').doc(uid).update(updates);

      AuthResult result = await getUserProfile(uid);
      if (result.success) {
        return AuthResult.success(
            user: result.user, message: 'Profile updated successfully');
      } else {
        return AuthResult.failure('Failed to retrieve updated profile');
      }
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  // Delete user account
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

  // Sign out
  Future<AuthResult> signOut() async {
    try {
      await _auth.signOut();
      return AuthResult.success(message: 'Signed out successfully');
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  // Reauthenticate for sensitive operations
  Future<AuthResult> reauthenticate({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onVerificationFailed,
    TextEditingController? pinController,
    required Function() onAutoVerificationCompleted,
  }) async {
    return await sendOTP(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onVerificationFailed: onVerificationFailed,
      pinController: pinController,
      onAutoVerificationCompleted: onAutoVerificationCompleted,
    );
  }

  // Update phone number
  Future<AuthResult> updatePhoneNumber({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      if (currentUser == null) {
        return AuthResult.failure('No authenticated user found');
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await currentUser!.updatePhoneNumber(credential);

      await _firestore.collection('users').doc(currentUser!.uid).update({
        'phoneNumber': currentUser!.phoneNumber,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return AuthResult.success(message: 'Phone number updated successfully');
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  // Upload profile picture
  Future<String> _uploadProfilePicture(String uid, File file) async {
    debugPrint('📤 Uploading profile picture for $uid');
    try {
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      if (currentUser!.uid != uid) {
        throw Exception('User ID mismatch');
      }

      String extension = path.extension(file.path).toLowerCase();
      if (!['.jpg', '.jpeg', '.png'].contains(extension)) {
        debugPrint('❌ Unsupported file format: $extension');
        throw Exception('Unsupported file format: $extension');
      }

      Reference ref =
          _storage.ref().child('profile_pictures').child('$uid$extension');

      final metadata = SettableMetadata(
        contentType: 'image/${extension.replaceAll('.', '')}',
        customMetadata: {'userId': uid},
      );

      UploadTask uploadTask = ref.putFile(file, metadata);
      TaskSnapshot snapshot = await uploadTask;
      String url = await snapshot.ref.getDownloadURL();
      debugPrint('✅ Upload successful: $url');
      return url;
    } catch (e) {
      debugPrint('❌ Upload failed: $e');
      rethrow;
    }
  }

  // Delete profile picture
  Future<void> _deleteProfilePicture(String uid) async {
    debugPrint('🗑️ Deleting profile picture for $uid');
    try {
      for (String ext in ['.jpg', '.jpeg', '.png']) {
        Reference ref =
            _storage.ref().child('profile_pictures').child('$uid$ext');
        await ref
            .delete()
            .catchError((e) => debugPrint('ℹ️ No file with $ext to delete'));
      }
      debugPrint('✅ Deletion attempted for all extensions');
    } catch (e) {
      debugPrint('ℹ️ No profile picture to delete or error: $e');
    }
  }
}
