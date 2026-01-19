// lib/services/otp_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_config.dart';

class OtpService {
  final _supabase = Supabase.instance.client;

  /// Check if phone number is allowed (whitelist check)
  /// Returns true if:
  /// 1. Bypass is enabled (for demo/testing), OR
  /// 2. A profile exists with this phone number in the database
  Future<bool> isPhoneAllowed(String phone) async {
    // Allow bypass if configured (for demo/testing)
    if (AuthConfig.allowBypassWithoutWhitelist) {
      return true;
    }

    try {
      // Format phone number (ensure it starts with +91 if it's an Indian number)
      final formattedPhone = phone.startsWith('+91') ? phone : '+91$phone';

      // Check if a profile exists with this phone number
      final response = await _supabase
          .from('profiles')
          .select('id, active')
          .eq('phone', formattedPhone)
          .maybeSingle();

      // Phone is allowed if profile exists and is active
      if (response != null) {
        final isActive = response['active'] as bool? ?? true;
        return isActive;
      }

      // Phone not found in whitelist (profiles table)
      return false;
    } catch (e) {
      // On error, deny access for security
      debugPrint('OTP: Whitelist check failed');
      return false;
    }
  }

  // Send OTP to phone number
  Future<void> sendOtp(String phone) async {
    if (!AuthConfig.whitelistOtpEnabled) return;

    if (AuthConfig.allowBypassWithoutWhitelist) {
      return; // allow demo mode
    }

    final allowed = await isPhoneAllowed(phone);
    if (!allowed) {
      throw Exception('Onboarding in progress');
    }
  }
}

