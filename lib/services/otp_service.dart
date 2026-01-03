// lib/services/otp_service.dart

import 'auth_config.dart';

class OtpService {
  // Check if phone number is allowed (whitelist check)
  Future<bool> isPhoneAllowed(String phone) async {
    // TODO: Implement whitelist check from database
    // For now, return true if bypass is enabled
    if (AuthConfig.allowBypassWithoutWhitelist) {
      return true;
    }
    
    // Placeholder for actual whitelist implementation
    return false;
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

