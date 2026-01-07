// lib/services/role_routing_service.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/customer/dashboard_screen.dart';
import '../screens/staff/staff_dashboard.dart';
import '../screens/login_screen.dart';
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
      // STEP 2: Add diagnostics before query
      final session = _supabase.auth.currentSession;
      final user = _supabase.auth.currentUser;
      
      debugPrint('SESSION BEFORE staff_metadata QUERY = $session');
      debugPrint('USER BEFORE staff_metadata QUERY = $user');
      debugPrint('SUPABASE CLIENT HASH = ${_supabase.hashCode}');
      
      // STEP 3: Enforce hard auth guard
      if (session == null) {
        throw Exception('Auth session not ready — blocking staff_metadata access');
      }
      
      final response = await _supabase
          .from('staff_metadata')
          .select('staff_type')
          .eq('profile_id', profileId)
          .maybeSingle();

      // DEBUG: Verify staff_metadata response
      debugPrint('STAFF_METADATA RESPONSE = ${response?.toString()}');

      return response?['staff_type'] as String?;
    } catch (e) {
      debugPrint('STAFF_METADATA ERROR = $e');
      rethrow; // Fail loud instead of returning null
    }
  }

  /// Check if user has mobile app access
  /// Returns true if allowed, false if denied
  /// Throws exception with message if denied
  static Future<bool> checkMobileAppAccess() async {
    try {
      // STEP 3: Enforce hard auth guard - ensure session is ready
      final session = _supabase.auth.currentSession;
      if (session == null) {
        // Wait briefly for session to propagate (max 2 seconds)
        await Future.delayed(const Duration(milliseconds: 500));
        final retrySession = _supabase.auth.currentSession;
        if (retrySession == null) {
          throw Exception('Auth session not ready — blocking access check');
        }
      }
      
      final userId = _supabase.auth.currentUser?.id;
      // DEBUG: Verify UID is not null (temporary)
      debugPrint('CHECK MOBILE ACCESS UID = $userId');
      if (userId == null) {
        throw Exception('This account does not have mobile app access.');
      }

      // Fetch role and profile
      debugPrint('BEFORE PROFILE QUERY');
      final profileResponse = await _supabase
          .from('profiles')
          .select('id, role, active')
          .eq('user_id', userId)
          .maybeSingle();
      debugPrint('AFTER PROFILE QUERY');

      // DEBUG: Verify profile response data
      debugPrint('PROFILE RESPONSE = ${profileResponse?.toString()}');

      if (profileResponse == null || profileResponse['active'] != true) {
        throw Exception('This account does not have mobile app access.');
      }

      final role = profileResponse['role'] as String?;
      final profileId = profileResponse['id'] as String?;

      if (role == null || profileId == null) {
        throw Exception('This account does not have mobile app access.');
      }

      // Admin users cannot access mobile app
      if (role == 'admin') {
        throw Exception('This account does not have mobile app access.');
      }

      // Customers can always access
      if (role == 'customer') {
        return true;
      }

      // Staff must have staff_type='collection'
      if (role == 'staff') {
        final staffType = await fetchStaffType(profileId);
        // DEBUG: Verify staff_type
        debugPrint('STAFF TYPE = $staffType');
        if (staffType != 'collection') {
          throw Exception('This account does not have mobile app access.');
        }
        return true;
      }

      // Unknown role
      throw Exception('This account does not have mobile app access.');
    } catch (e, stackTrace) {
      // DEBUG: Log the full exception
      debugPrint('CHECK MOBILE ACCESS EXCEPTION: $e');
      debugPrint('STACK TRACE: $stackTrace');
      rethrow;
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

