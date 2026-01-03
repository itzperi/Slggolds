// lib/services/payment_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class PaymentService {
  static final _supabase = Supabase.instance.client;

  /// Get current market rate for asset type
  static Future<double> getCurrentMarketRate(String assetType) async {
    try {
      final response = await _supabase
          .from('market_rates')
          .select('price_per_gram')
          .eq('asset_type', assetType)
          .order('rate_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        throw Exception('Market rate not found for $assetType');
      }

      return (response['price_per_gram'] as num).toDouble();
    } catch (e) {
      rethrow;
    }
  }

  /// Get user_scheme_id for a customer
  static Future<String?> getUserSchemeId(String customerId) async {
    try {
      // 1️⃣ Prefer ACTIVE scheme
      var response = await _supabase
          .from('user_schemes')
          .select('id')
          .eq('customer_id', customerId)
          .eq('status', 'active')
          .order('enrollment_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return response['id'] as String?;
      }

      // 2️⃣ Fallback to PAUSED scheme
      response = await _supabase
          .from('user_schemes')
          .select('id')
          .eq('customer_id', customerId)
          .eq('status', 'paused')
          .order('enrollment_date', ascending: false)
          .limit(1)
          .maybeSingle();

      return response?['id'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Get customer UUID from customer data
  /// First tries customer_id if present (UUID), otherwise looks up by phone
  static Future<String?> getCustomerIdFromData(Map<String, dynamic> customerData) async {
    try {
      // Check if customer_id is already a UUID
      final customerId = customerData['customer_id'] as String?;
      if (customerId != null && customerId.length == 36) {
        // Looks like a UUID, verify it exists
        final response = await _supabase
            .from('customers')
            .select('id')
            .eq('id', customerId)
            .maybeSingle();
        if (response != null) {
          return response['id'] as String;
        }
      }

      // Try to find customer by phone
      final phone = customerData['phone'] as String?;
      if (phone != null) {
        // Format phone if needed
        String formattedPhone = phone;
        if (!phone.startsWith('+')) {
          formattedPhone = phone.startsWith('91') ? '+$phone' : '+91$phone';
        }

        final profileResponse = await _supabase
            .from('profiles')
            .select('id')
            .eq('phone', formattedPhone)
            .maybeSingle();

        if (profileResponse != null) {
          final profileId = profileResponse['id'] as String;
          
          // Get customer record
          final customerResponse = await _supabase
              .from('customers')
              .select('id')
              .eq('profile_id', profileId)
              .maybeSingle();

          return customerResponse?['id'] as String?;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Insert payment into database
  static Future<void> insertPayment({
    required String userSchemeId,
    required String customerId,
    required String staffId,
    required double amount,
    required String paymentMethod,
    required double metalRatePerGram,
    required String deviceId,
    required DateTime clientTimestamp,
  }) async {
    try {
      print('PaymentService.insertPayment: DEBUG START');
      print('  - userSchemeId: $userSchemeId');
      print('  - customerId: $customerId');
      print('  - staffId: $staffId');
      print('  - amount: $amount');
      print('  - paymentMethod: $paymentMethod');
      print('  - metalRatePerGram: $metalRatePerGram');
      
      // Check current auth user
      final currentUserId = _supabase.auth.currentUser?.id;
      print('  - current auth.uid(): $currentUserId');
      
      // Check current user's profile
      try {
        final profileResponse = await _supabase
            .from('profiles')
            .select('id, role, user_id')
            .eq('user_id', currentUserId ?? '')
            .maybeSingle();
        print('  - current user profile: $profileResponse');
        if (profileResponse != null) {
          print('  - profile.id: ${profileResponse['id']}');
          print('  - profile.role: ${profileResponse['role']}');
          print('  - staffId matches profile.id: ${staffId == profileResponse['id']}');
        }
      } catch (e) {
        print('  - ERROR checking profile: $e');
      }
      
      // Check staff assignment
      try {
        final assignmentResponse = await _supabase
            .from('staff_assignments')
            .select('staff_id, customer_id, is_active')
            .eq('staff_id', staffId)
            .eq('customer_id', customerId)
            .maybeSingle();
        print('  - staff_assignment: $assignmentResponse');
      } catch (e) {
        print('  - ERROR checking assignment: $e');
      }
      
      final gstAmount = amount * 0.03;
      final netAmount = amount * 0.97;
      final metalGramsAdded = netAmount / metalRatePerGram;

      final paymentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final paymentTime = DateFormat('HH:mm:ss').format(DateTime.now());

      // DEBUG: Log exact values being inserted
      debugPrint('PaymentService.insertPayment: DEBUG VALUES:');
      debugPrint('  - staffId being inserted: $staffId');
      debugPrint('  - customerIdParam: $customerId');
      debugPrint('  - auth.uid(): ${_supabase.auth.currentUser?.id}');
      
      print('PaymentService.insertPayment: Attempting insert...');
      await _supabase.from('payments').insert({
        'user_scheme_id': userSchemeId,
        'customer_id': customerId,
        'staff_id': staffId,
        'amount': amount,
        'gst_amount': gstAmount,
        'net_amount': netAmount,
        'payment_method': paymentMethod,
        'payment_date': paymentDate,
        'payment_time': paymentTime,
        'status': 'completed',
        'metal_rate_per_gram': metalRatePerGram,
        'metal_grams_added': metalGramsAdded,
        'is_reversal': false,
        'device_id': deviceId,
        'client_timestamp': clientTimestamp.toIso8601String(),
      });
      print('PaymentService.insertPayment: ✅ SUCCESS');
    } catch (e) {
      print('PaymentService.insertPayment: ❌ ERROR - $e');
      rethrow;
    }
  }

  /// Get device ID (simple implementation)
  static String getDeviceId() {
    return Platform.isAndroid
        ? 'android_${DateTime.now().millisecondsSinceEpoch}'
        : 'ios_${DateTime.now().millisecondsSinceEpoch}';
  }
}

