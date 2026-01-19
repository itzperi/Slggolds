// lib/services/admin_auth_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AdminAuthService {
  static final _client = Supabase.instance.client;

  /// Sign in admin using username and password
  /// Supports direct username/password (e.g., "Admin"/"Admin@007")
  /// 
  /// Throws Exception if:
  /// - username not found or incorrect
  /// - password incorrect
  /// - user is not an admin
  /// - Supabase auth fails
  static Future<void> signInWithUsername({
    required String username,
    required String password,
  }) async {
    try {
      debugPrint('AdminAuthService: Attempting admin login');
      
      String email;
      
      // Special case: Default admin credentials (Admin/Admin@007)
      if (username.toUpperCase() == 'ADMIN' && password == 'Admin@007') {
        email = 'admin@slggolds.com'; // Default admin email
      } else {
        // For other admins, try direct email login
        email = username.contains('@') ? username : '${username.toLowerCase()}@slggolds.com';
      }
      
      debugPrint('AdminAuthService: Attempting Supabase auth for admin user');
      
      // Authenticate using Supabase email + password
      final authResponse = await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (authResponse.session == null) {
        debugPrint('AdminAuthService: ERROR - No session created after auth');
        throw Exception('Invalid admin credentials');
      }

      // Verify user has admin role
      final profileResponse = await _client
          .from('profiles')
          .select('role')
          .eq('user_id', authResponse.user!.id)
          .maybeSingle();

      if (profileResponse == null || profileResponse['role'] != 'admin') {
      debugPrint('AdminAuthService: ERROR - User is not an admin');
        await _client.auth.signOut();
        throw Exception('Access denied: Admin privileges required');
      }

      debugPrint('AdminAuthService: SUCCESS - Admin session created');
      // Session is now set - AuthGate will handle routing
    } catch (e) {
      debugPrint('AdminAuthService: EXCEPTION - ${e.toString()}');
      // Re-throw with user-friendly message
      if (e.toString().contains('Invalid login credentials') ||
          e.toString().contains('Email not confirmed') ||
          e.toString().contains('Invalid admin credentials') ||
          e.toString().contains('Access denied')) {
        throw Exception('Invalid admin credentials');
      }
      rethrow;
    }
  }
}

