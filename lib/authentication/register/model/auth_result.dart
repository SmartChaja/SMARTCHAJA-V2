// lib/models/auth_result.dart
import 'package:smart_chaja/authentication/register/model/user_model.dart';

class AuthResult {
  final bool success;
  final String? message;
  final UserModel? user;

  AuthResult({
    required this.success,
    this.message,
    this.user,
  });

  factory AuthResult.success({UserModel? user, String? message}) {
    return AuthResult(success: true, user: user, message: message);
  }

  factory AuthResult.failure(String message) {
    return AuthResult(success: false, message: message);
  }
}