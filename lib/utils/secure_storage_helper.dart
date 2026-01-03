import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class SecureStorageHelper {
  static const _storage = FlutterSecureStorage();

  // Keys
  static const String _pinHashKey = 'user_pin_hash';
  static const String _phoneKey = 'user_phone';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastAuthKey = 'last_auth_timestamp';
  
  // Staff keys
  static const String _staffPinHashKey = 'staff_pin_hash';
  static const String _staffIdKey = 'staff_id';
  static const String _staffLastAuthKey = 'staff_last_auth_timestamp';

  // Hash PIN with SHA-256
  static String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // Save PIN (hashed)
  static Future<void> savePin(String pin) async {
    final hashedPin = hashPin(pin);
    await _storage.write(key: _pinHashKey, value: hashedPin);
    await updateLastAuth();
  }

  // Verify PIN
  static Future<bool> verifyPin(String pin) async {
    final storedHash = await _storage.read(key: _pinHashKey);
    if (storedHash == null) return false;
    final inputHash = hashPin(pin);
    return storedHash == inputHash;
  }

  // Check if PIN is set
  static Future<bool> isPinSet() async {
    final pin = await _storage.read(key: _pinHashKey);
    return pin != null && pin.isNotEmpty;
  }

  // Delete PIN
  static Future<void> deletePin() async {
    await _storage.delete(key: _pinHashKey);
  }

  // Save phone number
  static Future<void> savePhone(String phone) async {
    await _storage.write(key: _phoneKey, value: phone);
  }

  // Get saved phone
  static Future<String?> getSavedPhone() async {
    return await _storage.read(key: _phoneKey);
  }

  // Biometric preference
  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  static Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  // Last authentication timestamp
  static Future<void> updateLastAuth() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await _storage.write(key: _lastAuthKey, value: timestamp);
  }

  static Future<bool> needsReauth() async {
    final lastAuth = await _storage.read(key: _lastAuthKey);
    if (lastAuth == null) return true;

    final lastAuthTime = DateTime.fromMillisecondsSinceEpoch(int.parse(lastAuth));
    final daysSinceAuth = DateTime.now().difference(lastAuthTime).inDays;

    return daysSinceAuth >= 30; // Re-auth every 30 days
  }

  // Staff PIN methods
  static Future<void> saveStaffPin(String pin) async {
    final hashedPin = hashPin(pin);
    await _storage.write(key: _staffPinHashKey, value: hashedPin);
    await updateStaffLastAuth();
  }

  static Future<bool> verifyStaffPin(String pin) async {
    final storedHash = await _storage.read(key: _staffPinHashKey);
    if (storedHash == null) return false;
    final inputHash = hashPin(pin);
    return storedHash == inputHash;
  }

  static Future<bool> isStaffPinSet() async {
    final pin = await _storage.read(key: _staffPinHashKey);
    return pin != null && pin.isNotEmpty;
  }

  static Future<void> deleteStaffPin() async {
    await _storage.delete(key: _staffPinHashKey);
  }

  static Future<void> saveStaffId(String staffId) async {
    await _storage.write(key: _staffIdKey, value: staffId);
  }

  static Future<String?> getSavedStaffId() async {
    return await _storage.read(key: _staffIdKey);
  }

  static Future<void> updateStaffLastAuth() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await _storage.write(key: _staffLastAuthKey, value: timestamp);
  }

  static Future<bool> staffNeedsReauth() async {
    final lastAuth = await _storage.read(key: _staffLastAuthKey);
    if (lastAuth == null) return true;

    final lastAuthTime = DateTime.fromMillisecondsSinceEpoch(int.parse(lastAuth));
    final daysSinceAuth = DateTime.now().difference(lastAuthTime).inDays;

    return daysSinceAuth >= 30; // Re-auth every 30 days
  }

  // Clear all data (on logout)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}




