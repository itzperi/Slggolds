// lib/services/role_routing_service.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_flow_notifier.dart';

class RoleRoutingService {
  static final _supabase = Supabase.instance.client;

  /// Fetch user profile and validate role
  /// Returns role if valid, null if invalid/missing
  static Future<String?> fetchAndValidateRole() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select('role, active')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      if (response['active'] != true) return null;

      final role = response['role'] as String?;
      if (role == null) return null;

      // Validate role is one of the allowed values
      if (!['customer', 'staff', 'admin'].contains(role)) {
        return null;
      }

      return role;
    } catch (e) {
      return null;
    }
  }

  /// Fetch staff_type for staff users
  /// Returns 'collection' or 'office', null if not staff or missing
  static Future<String?> fetchStaffType(String profileId) async {
    try {
      final session = _supabase.auth.currentSession;
      // STEP 3: Enforce hard auth guard
      if (session == null) {
        throw Exception('Auth session not ready — blocking staff_metadata access');
      }
      
      final response = await _supabase
          .from('staff_metadata')
          .select('staff_type')
          .eq('profile_id', profileId)
          .maybeSingle();

      return response?['staff_type'] as String?;
    } catch (e) {
      debugPrint('STAFF_METADATA ERROR = $e');
      rethrow; // Fail loud instead of returning null
    }
  }

  /// Check if user has mobile app access using database RPC function (GAP-033)
  /// Returns true if allowed, throws exception with message if denied
  /// This enforces database-level access control for admin/office staff
  static Future<bool> checkMobileAppAccess() async {
    try {
      // Ensure session is ready
      final session = _supabase.auth.currentSession;
      if (session == null) {
        await Future.delayed(const Duration(milliseconds: 500));
        final retrySession = _supabase.auth.currentSession;
        if (retrySession == null) {
          throw Exception('Auth session not ready — blocking access check');
        }
      }

      // Call database RPC function check_mobile_app_access()
      // This function enforces: admin/office staff denied, collection staff/customers allowed
      final response = await _supabase.rpc('check_mobile_app_access');
      
      // RPC returns boolean true if allowed, throws exception if denied
      if (response == true) {
        return true;
      }
      
      // Should not reach here, but defensive check
      throw Exception('This account does not have mobile app access.');
    } catch (e, stackTrace) {
      debugPrint('CHECK MOBILE ACCESS EXCEPTION: $e');
      debugPrint('STACK TRACE: $stackTrace');
      
      // Re-throw with user-friendly message
      final errorMessage = e.toString().contains('mobile app access')
          ? e.toString().replaceFirst('Exception: ', '')
          : 'This account does not have mobile app access. Please use the web dashboard.';
      throw Exception(errorMessage);
    }
  }

  /// Get profile ID for current user
  static Future<String?> getCurrentProfileId() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      return response?['id'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Navigate to role-appropriate screen with mobile app access enforcement
  /// Returns true if navigation successful, false if logout required
  static Future<bool> navigateByRole(BuildContext context, AuthFlowNotifier authFlow) async {
    throw UnimplementedError(
      'navigateByRole is forbidden. Auth routing must be declarative via AuthGate.'
    );
  }
}

