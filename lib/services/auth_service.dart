// lib/services/auth_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Send OTP to phone number
  Future<void> sendOTP(String phone) async {
    try {
      final formattedPhone =
          phone.startsWith('+91') ? phone : '+91$phone';

      await _supabase.auth.signInWithOtp(
        phone: formattedPhone,
      );
    } catch (e) {
      throw Exception('Failed to send OTP: ${e.toString()}');
    }
  }

  // Verify OTP
  Future<AuthResponse> verifyOTP(String phone, String otp) async {
    try {
      final formattedPhone =
          phone.startsWith('+91') ? phone : '+91$phone';

      final response = await _supabase.auth.verifyOTP(
        phone: formattedPhone,
        token: otp,
        type: OtpType.sms,
      );

      if (response.session == null) {
        throw Exception('Invalid OTP');
      }

      return response;
    } catch (e) {
      throw Exception('Verification failed: ${e.toString()}');
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Auth state stream
  Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange;
  }
}
