// lib/services/auth_config.dart

class AuthConfig {
  static const bool whitelistOtpEnabled = true;

  // TEMP: allow local demo without whitelist
  static const bool allowBypassWithoutWhitelist = true;

  static const String fixedOtp = '123456';
}

