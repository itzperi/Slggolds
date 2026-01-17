// lib/services/staff_auth_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class StaffAuthService {
  static final _client = Supabase.instance.client;

  /// Sign in staff using username/password or staff_code/password
  /// Supports direct username/password (e.g., "Staff"/"Staff@007") or staff_code lookup
  /// Resolves staff_code → email, then authenticates via Supabase Auth
  /// 
  /// Throws Exception if:
  /// - staff_code/username not found
  /// - email not set in profile
  /// - password incorrect
  /// - Supabase auth fails
  static Future<void> signInWithStaffCode({
    required String staffCode,
    required String password,
  }) async {
    try {
      print('StaffAuthService: Attempting login for staff_code: ${staffCode.toUpperCase()}');
      
      String? email;
      
      // Special case: Direct username/password login (Staff/Staff@007)
      if (staffCode.toUpperCase() == 'STAFF' && password == 'Staff@007') {
        // Try direct login with username "Staff" → look for staff with specific email pattern
        // Or check if staff_code "STAFF" exists
        email = 'staff@slggolds.com'; // Default staff email pattern
      } else if (staffCode.toUpperCase() == 'ADMIN' && password == 'Admin@007') {
        // Admin login handled separately, but we can check here too
        throw Exception('Use AdminAuthService for admin login');
      }
      
      // If not special case, resolve staff_code → email via database function
      if (email == null) {
        final response = await _client.rpc(
          'get_staff_email_by_code',
          params: {'staff_code_param': staffCode.toUpperCase()},
        ).maybeSingle();

        debugPrint('StaffAuthService: Database function raw response = $response');

        if (response == null) {
          print('StaffAuthService: ERROR - Staff code not found in database');
          throw Exception('Invalid staff credentials');
        }

        email = response['email'] as String?;
      }
      
      debugPrint('StaffAuthService: Resolved email = $email');
      
      if (email == null || email.isEmpty) {
        print('StaffAuthService: ERROR - Email not set in profile');
        throw Exception('Staff account not properly configured');
      }

      print('StaffAuthService: Attempting Supabase auth with email: $email');
      
      // 2. Authenticate using Supabase email + password
      final authResponse = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.session == null) {
        print('StaffAuthService: ERROR - No session created after auth');
        throw Exception('Invalid staff credentials');
      }

      print('StaffAuthService: SUCCESS - Session created, user_id: ${authResponse.user?.id}');
      // Session is now set - AuthGate will handle routing
    } catch (e) {
      print('StaffAuthService: EXCEPTION - ${e.toString()}');
      // Re-throw with user-friendly message
      if (e.toString().contains('Invalid login credentials') ||
          e.toString().contains('Email not confirmed') ||
          e.toString().contains('Invalid staff credentials')) {
        throw Exception('Invalid staff credentials');
      }
      rethrow;
    }
  }
}

