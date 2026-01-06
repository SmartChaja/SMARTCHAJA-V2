
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/authentication/register/model/user_model.dart';
import 'dart:io';
import 'package:smart_chaja/authentication/register/repositories/auth_repository.dart';

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel(ref.read(authRepositoryProvider));
});

class AuthState {
  final bool isLoading;
  final String? error;
  final UserModel? user;
  final bool isAuthenticated;
  final String? verificationId;
  final String? phoneNumber;

  AuthState({
    this.isLoading = false,
    this.error,
    this.user,
    this.isAuthenticated = false,
    this.verificationId,
    this.phoneNumber,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    UserModel? user,
    bool? isAuthenticated,
    String? verificationId,
    String? phoneNumber,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      verificationId: verificationId ?? this.verificationId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthViewModel(this._authRepository) : super(AuthState()) {
    _init();
  }

  void _init() {
    _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        _loadUserProfile(user.uid);
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          user: null,
          phoneNumber: null,
          verificationId: null,
        );
      }
    });
  }

  Future<void> _loadUserProfile(String uid) async {
    state = state.copyWith(isLoading: true);

    final result = await _authRepository.getUserProfile(uid);
    if (result.success && result.user != null) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: result.user,
        error: null,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: null,
        error: null,
      );
    }
  }

  Future<void> refreshUserProfile() async {
    final currentUser = _authRepository.currentUser;
    if (currentUser != null) {
      await _loadUserProfile(currentUser.uid);
    } else {
      state = state.copyWith(isAuthenticated: false, user: null);
    }
  }

  Future<bool> sendOTP(
    String phoneNumber, {
    TextEditingController? pinController,
    Function()? onAutoVerificationCompleted,
  }) async {
    state = state.copyWith(isLoading: true, error: null, phoneNumber: phoneNumber);
    bool codeSent = false;
    String? errorMessage;

    try {
      final result = await _authRepository.sendOTP(
        phoneNumber: state.phoneNumber!,
        pinController: pinController,
        onCodeSent: (verificationId) {
          debugPrint('✅ onCodeSent triggered with verificationId: $verificationId');
          state = state.copyWith(
            isLoading: false,
            verificationId: verificationId,
            error: null,
          );
          codeSent = true;
        },
        onVerificationFailed: (error) {
          debugPrint('❌ onVerificationFailed: $error');
          if (error.contains('unusual activity') || error.contains('blocked')) {
            errorMessage = 'Device temporarily blocked. Please try again later.';
          } else if (error.contains('invalid phone') || error.contains('17010')) {
            errorMessage = 'Invalid phone number format. Please check and try again.';
          } else if (error.contains('quota exceeded')) {
            errorMessage = 'SMS quota exceeded. Please try again later.';
          } else if (error.contains('network')) {
            errorMessage = 'Network error. Please check your connection.';
          } else {
            errorMessage = 'SMS verification failed: $error';
          }
          state = state.copyWith(
            isLoading: false,
            error: errorMessage,
          );
          codeSent = false;
        },
        onAutoVerificationCompleted: () {
          debugPrint('✅ Auto verification completed');
          state = state.copyWith(isLoading: false, error: null);
          if (onAutoVerificationCompleted != null) {
            onAutoVerificationCompleted();
          }
        },
      );

      debugPrint('🔍 sendOTP result: success=${result.success}, codeSent=$codeSent');
      if (!result.success && !codeSent) {
        String finalError = result.message ?? 'Unknown error occurred';
        if (finalError.contains('unusual activity') || finalError.contains('blocked')) {
          finalError = 'Device temporarily blocked. Please try again later.';
        }
        state = state.copyWith(
          isLoading: false,
          error: finalError,
        );
        return false;
      }

      return codeSent;
    } catch (e) {
      debugPrint('❌ Unexpected error in sendOTP: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Unexpected error: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> verifyOTP(String smsCode) async {
    if (state.verificationId == null) {
      state = state.copyWith(error: 'No verification ID found. Please request OTP again.');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authRepository.verifyOTPAndSignIn(
        verificationId: state.verificationId!,
        smsCode: smsCode,
      );

      if (result.success) {
        final currentUser = _authRepository.currentUser;
        if (currentUser != null) {
          final profileExists = await _authRepository.userProfileExists(currentUser.uid);

          if (profileExists) {
            await _loadUserProfile(currentUser.uid);
          } else {
            state = state.copyWith(
              isLoading: false,
              isAuthenticated: true,
              user: null,
              error: null,
            );
          }
          return profileExists;
        }
      }

      String errorMessage = result.message ?? 'Verification failed';
      if (errorMessage.contains('invalid') || errorMessage.contains('expired')) {
        errorMessage = 'Invalid or expired OTP code. Please try again.';
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Verification error: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> createUserProfile({
    required String fullName,
    required String gender,
    required DateTime dateOfBirth,
    required String nationalId,
    File? profilePicture,
    String role = 'member',
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authRepository.createUserProfile(
        fullName: fullName,
        gender: gender,
        dateOfBirth: dateOfBirth,
        nationalId: nationalId,
        profilePicture: profilePicture,
        role: role,
      );

      if (result.success) {
        state = state.copyWith(
          isLoading: false,
          user: result.user,
          error: null,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.message ?? 'Failed to create profile',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Profile creation error: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> updateUserProfile({
    String? fullName,
    String? gender,
    DateTime? dateOfBirth,
    String? nationalId,
    File? profilePicture,
    bool removeProfilePicture = false,
    String? role,
  }) async {
    if (state.user == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authRepository.updateUserProfile(
        uid: state.user!.uid,
        fullName: fullName,
        gender: gender,
        dateOfBirth: dateOfBirth,
        nationalId: nationalId,
        profilePicture: profilePicture,
        removeProfilePicture: removeProfilePicture,
        role: role,
      );

      if (result.success) {
        state = state.copyWith(
          isLoading: false,
          user: result.user,
          error: null,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.message ?? 'Failed to update profile',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Profile update error: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authRepository.deleteUserAccount();

      if (result.success) {
        state = AuthState();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.message ?? 'Failed to delete account',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Account deletion error: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authRepository.signOut();
      state = AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sign out error: ${e.toString()}',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<bool> retryAfterDelay(String phoneNumber, {int delayMinutes = 60}) async {
    await Future.delayed(Duration(minutes: delayMinutes));
    return await sendOTP(phoneNumber);
  }
}

