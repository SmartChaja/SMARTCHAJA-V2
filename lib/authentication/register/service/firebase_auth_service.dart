import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:smart_chaja/authentication/register/model/auth_result.dart';
import 'package:smart_chaja/authentication/register/model/user_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Store phone number for verification flow
  String? _pendingPhoneNumber;

  // Send OTP via Beem Africa (Cloud Function)
  // Works on both iOS and Android without APNs configuration
  Future<AuthResult> sendOTP({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onVerificationFailed,
    TextEditingController? pinController,
    required Function() onAutoVerificationCompleted,
  }) async {
    try {
      debugPrint('📱 Sending OTP via Beem Africa to: $phoneNumber');

      // Store phone number for later verification
      _pendingPhoneNumber = phoneNumber;

      // Call Cloud Function to send OTP via Beem Africa
      final callable = _functions.httpsCallable('sendOTP');
      final result = await callable.call<Map<String, dynamic>>({
        'phoneNumber': phoneNumber,
      });

      final data = result.data;

      if (data['success'] == true) {
        debugPrint('✅ OTP sent successfully via Beem Africa');
        // Use phone number as "verificationId" for our custom flow
        final formattedPhone = data['phoneNumber'] as String? ?? phoneNumber;
        _pendingPhoneNumber = formattedPhone;
        onCodeSent(formattedPhone);
        return AuthResult.success(message: 'OTP sent successfully');
      } else {
        final errorMsg = data['message'] ?? 'Failed to send OTP';
        onVerificationFailed(errorMsg);
        return AuthResult.failure(errorMsg);
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Cloud Function error: ${e.code} - ${e.message}');
      String errorMessage = e.message ?? 'Failed to send OTP';

      // Handle specific error codes
      if (e.code == 'resource-exhausted') {
        errorMessage = e.message ?? 'Please wait before requesting another OTP';
      } else if (e.code == 'failed-precondition') {
        errorMessage = e.message ?? 'SMS service not available';
      }

      onVerificationFailed(errorMessage);
      return AuthResult.failure(errorMessage);
    } catch (e) {
      debugPrint('❌ Error sending OTP: $e');
      onVerificationFailed('Failed to send OTP: ${e.toString()}');
      return AuthResult.failure(e.toString());
    }
  }

  // Verify OTP and Sign In via Cloud Function + Custom Token
  // This bypasses Firebase Phone Auth and APNs requirement on iOS
  Future<AuthResult> verifyOTPAndSignIn({
    required String verificationId, // This is the phone number in our flow
    required String smsCode,
  }) async {
    try {
      debugPrint('🔐 Verifying OTP via Cloud Function...');

      // Use stored phone number or the verificationId (which is phone number)
      final phoneNumber = _pendingPhoneNumber ?? verificationId;

      // Call Cloud Function to verify OTP and get custom token
      final callable = _functions.httpsCallable('verifyOTPAndGetToken');
      final result = await callable.call<Map<String, dynamic>>({
        'phoneNumber': phoneNumber,
        'otpCode': smsCode,
      });

      final data = result.data;

      if (data['success'] == true && data['token'] != null) {
        debugPrint('✅ OTP verified, signing in with custom token...');

        // Sign in with the custom token
        final customToken = data['token'] as String;
        await _auth.signInWithCustomToken(customToken);

        debugPrint('✅ Successfully signed in!');
        _pendingPhoneNumber = null;
        return AuthResult.success(message: 'Login successful');
      } else {
        return AuthResult.failure('Verification failed');
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Verification error: ${e.code} - ${e.message}');
      String errorMessage = e.message ?? 'Verification failed';

      // Handle specific error codes
      switch (e.code) {
        case 'not-found':
          errorMessage = 'No OTP found. Please request a new one.';
          break;
        case 'deadline-exceeded':
          errorMessage = 'OTP has expired. Please request a new one.';
          break;
        case 'permission-denied':
          errorMessage = e.message ?? 'Invalid OTP code.';
          break;
        case 'resource-exhausted':
          errorMessage = 'Too many failed attempts. Please request a new OTP.';
          break;
        case 'failed-precondition':
          errorMessage = 'This OTP has already been used.';
          break;
      }

      return AuthResult.failure(errorMessage);
    } catch (e) {
      debugPrint('❌ Error verifying OTP: $e');
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

  // Send deletion feedback email using Firebase Cloud Functions
  Future<void> _sendDeletionFeedbackEmail({
    required String userEmail,
    required String phoneNumber,
    required String feedback,
    required String userId,
  }) async {
    try {
      // Firebase Cloud Function Gen 2 URL
      final functionUrl =
          'https://senddeletionfeedback-45f4gu65ha-uc.a.run.app';

      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'userEmail': userEmail,
          'phoneNumber': phoneNumber,
          'feedback': feedback,
          'timestamp': DateTime.now().toIso8601String(),
          'recipientEmail': 'ryoba2014@gmail.com',
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Deletion feedback email sent successfully');
      } else {
        debugPrint('⚠️ Failed to send feedback email: ${response.body}');
      }
    } catch (e) {
      debugPrint('⚠️ Error sending feedback email: $e');
      // Don't throw error - deletion should succeed even if email fails
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
  // With Beem Africa OTP, we verify the new phone then update Firestore
  Future<AuthResult> updatePhoneNumber({
    required String verificationId, // This is the new phone number
    required String smsCode,
  }) async {
    try {
      if (currentUser == null) {
        return AuthResult.failure('No authenticated user found');
      }

      // Verify OTP for the new phone number
      final callable = _functions.httpsCallable('verifyOTPAndGetToken');
      final result = await callable.call<Map<String, dynamic>>({
        'phoneNumber': verificationId, // The new phone number
        'otpCode': smsCode,
      });

      final data = result.data;

      if (data['success'] != true) {
        return AuthResult.failure('Phone verification failed');
      }

      // Update phone number in Firestore user document
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'phoneNumber': verificationId,
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

  // Delete user account - removes from Firebase Auth and Firestore
  Future<AuthResult> deleteAccount({
    String? feedback,
  }) async {
    try {
      final uid = currentUser?.uid;
      final userEmail = currentUser?.email;
      final phoneNumber = currentUser?.phoneNumber;

      if (uid == null) {
        return AuthResult.failure('No authenticated user found');
      }

      // Step 1: Save feedback to Firestore before deletion
      if (feedback != null && feedback.isNotEmpty) {
        await _firestore.collection('deleted_user_feedback').doc(uid).set({
          'userId': uid,
          'userEmail': userEmail,
          'phoneNumber': phoneNumber,
          'feedback': feedback,
          'deletedAt': DateTime.now(),
        });

        // Step 2: Send email notification with feedback
        await _sendDeletionFeedbackEmail(
          userEmail: userEmail ?? 'Unknown',
          phoneNumber: phoneNumber ?? 'Unknown',
          feedback: feedback,
          userId: uid,
        );
      }

      // Step 3: Delete user's profile picture from Firebase Storage
      await _deleteProfilePicture(uid);

      // Step 4: Delete user document from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Step 5: Delete user from Firebase Authentication
      await currentUser?.delete();

      return AuthResult.success(message: 'Account deleted successfully');
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }
}
