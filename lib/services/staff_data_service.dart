// lib/services/staff_data_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // For debugPrint, debugPrintStack

class StaffDataService {
  static final _supabase = Supabase.instance.client;

  /// Get staff profile ID from staffId (which is profile UUID)
  static Future<String?> getStaffProfileId(String staffId) async {
    try {
      // staffId is already the profile UUID
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', staffId)
          .maybeSingle();
      return response?['id'] as String?;
    } catch (e, stackTrace) {
      debugPrint('StaffDataService.getStaffProfileId FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get assigned customers for staff
  /// Returns list in same format as StaffMockData.assignedCustomers
  static Future<List<Map<String, dynamic>>> getAssignedCustomers(String staffProfileId) async {
    try {
      debugPrint('StaffDataService.getAssignedCustomers: START - staffProfileId=$staffProfileId');
      
      // Get staff assignments
      final assignments = await _supabase
          .from('staff_assignments')
          .select('customer_id')
          .eq('staff_id', staffProfileId)
          .eq('is_active', true);

      debugPrint('StaffDataService.getAssignedCustomers: Found ${assignments.length} assignments');

      if (assignments.isEmpty) {
        debugPrint('StaffDataService.getAssignedCustomers: No active assignments found');
        return [];
      }

      final customerIds = (assignments as List)
          .map((a) => a['customer_id'] as String)
          .toList();

      debugPrint('StaffDataService.getAssignedCustomers: Extracted ${customerIds.length} customer IDs: $customerIds');

      if (customerIds.isEmpty) {
        debugPrint('StaffDataService.getAssignedCustomers: No customer IDs extracted');
        return [];
      }

      // Get customers with their profiles and schemes
      // Use or() to filter by multiple IDs
      var query = _supabase
          .from('customers')
          .select('id, profile_id, address');
      
      // Build OR query for multiple customer IDs
      if (customerIds.length == 1) {
        query = query.eq('id', customerIds[0]);
      } else {
        // Chain OR conditions
        final orConditions = customerIds
            .map((id) => 'id.eq.$id')
            .join(',');
        query = query.or(orConditions);
      }
      
      final customersResponse = await query;

      debugPrint('StaffDataService.getAssignedCustomers: Found ${customersResponse.length} customers from DB');

      if (customersResponse.isEmpty) {
        debugPrint('StaffDataService.getAssignedCustomers: No customers found in DB');
        return [];
      }

      final customers = customersResponse as List;
      final List<Map<String, dynamic>> result = [];

      for (var customer in customers) {
        final customerId = customer['id'] as String;
        final profileId = customer['profile_id'] as String;
        debugPrint('StaffDataService.getAssignedCustomers: Processing customer $customerId (profile_id: $profileId)');

        // Get profile (RLS policy allows staff to read assigned customer profiles)
        final profile = await _supabase
            .from('profiles')
            .select('id, name, phone')
            .eq('id', profileId)
            .maybeSingle();
        
        if (profile == null) {
          debugPrint('StaffDataService.getAssignedCustomers: Customer $customerId SKIPPED - no profile found');
          continue;
        }
        
        debugPrint('StaffDataService.getAssignedCustomers: Customer $customerId - profile found: ${profile['name']}');

        // Get latest user scheme (any status) - customer must have scheme for payment flow integrity
        final userSchemes = await _supabase
            .from('user_schemes')
            .select('id, scheme_id, status, payment_frequency, min_amount, max_amount, total_amount_paid, payments_made, payments_missed, accumulated_grams')
            .eq('customer_id', customerId)
            .order('enrollment_date', ascending: false)
            .limit(1)
            .maybeSingle();

        // Customer must still have a scheme for payment flow integrity
        if (userSchemes == null) {
          debugPrint('StaffDataService.getAssignedCustomers: Customer $customerId SKIPPED - no user_schemes found');
          continue;
        }
        debugPrint('StaffDataService.getAssignedCustomers: Customer $customerId - user_scheme found: ${userSchemes['id']}');

        // Get scheme details
        final schemeId = userSchemes['scheme_id'] as String;
        final scheme = await _supabase
            .from('schemes')
            .select('name, asset_type')
            .eq('id', schemeId)
            .maybeSingle();

        if (scheme == null) {
          debugPrint('StaffDataService.getAssignedCustomers: Customer $customerId SKIPPED - no scheme found for scheme_id: $schemeId');
          continue;
        }
        debugPrint('StaffDataService.getAssignedCustomers: Customer $customerId - scheme found: ${scheme['name']}');
        
        // Check if paid today
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final todayPayments = await _supabase
            .from('payments')
            .select('amount, payment_method')
            .eq('customer_id', customerId)
            .eq('staff_id', staffProfileId)
            .eq('payment_date', today)
            .eq('status', 'completed');

        final paidToday = todayPayments.isNotEmpty;
        double paidTodayAmount = 0.0;
        String paidTodayMethod = 'cash';
        if (paidToday && todayPayments.isNotEmpty) {
          for (var p in todayPayments) {
            paidTodayAmount += (p['amount'] as num?)?.toDouble() ?? 0.0;
          }
          paidTodayMethod = todayPayments[0]['payment_method'] as String? ?? 'cash';
        }

        // Calculate due amount (average of min and max)
        final minAmount = (userSchemes['min_amount'] as num?)?.toDouble() ?? 0.0;
        final maxAmount = (userSchemes['max_amount'] as num?)?.toDouble() ?? 0.0;
        final dueAmount = (minAmount + maxAmount) / 2;

        // Map payment frequency
        final frequency = _mapPaymentFrequency(userSchemes['payment_frequency'] as String);

        result.add({
          'id': customerId,
          'customer_id': customerId, // For compatibility
          'name': profile['name'] as String? ?? 'Unknown',
          'phone': profile['phone'] as String? ?? '',
          'address': customer['address'] as String? ?? '',
          'scheme': scheme['name'] as String? ?? 'Unknown Scheme',
          'schemeNumber': _extractSchemeNumber(scheme['name'] as String? ?? ''),
          'frequency': frequency,
          'minAmount': minAmount,
          'maxAmount': maxAmount,
          'dueAmount': dueAmount,
          'totalPayments': userSchemes['payments_made'] as int? ?? 0,
          'missedPayments': userSchemes['payments_missed'] as int? ?? 0,
          'paidToday': paidToday,
          'user_scheme_id': userSchemes['id'] as String, // For payment insertion
        });
        debugPrint('StaffDataService.getAssignedCustomers: ✅ Customer $customerId ADDED to result list');
      }

      debugPrint('StaffDataService.getAssignedCustomers: FINAL RESULT - ${result.length} customers added');
      return result;
    } catch (e, stackTrace) {
      debugPrint('StaffDataService.getAssignedCustomers FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get today's statistics
  static Future<Map<String, dynamic>> getTodayStats(String staffProfileId) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Get today's payments
      final payments = await _supabase
          .from('payments')
          .select('amount, payment_method, customer_id')
          .eq('staff_id', staffProfileId)
          .eq('payment_date', today)
          .eq('status', 'completed');

      double totalAmount = 0.0;
      double cashAmount = 0.0;
      double upiAmount = 0.0;
      final Set<String> customersCollected = {};

      for (var payment in payments) {
        final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
        totalAmount += amount;
        final method = payment['payment_method'] as String? ?? 'cash';
        if (method == 'cash') {
          cashAmount += amount;
        } else {
          upiAmount += amount;
        }
        customersCollected.add(payment['customer_id'] as String);
      }

      // STEP 1: Get assigned customers (business relationship)
      final assignments = await _supabase
          .from('staff_assignments')
          .select('customer_id')
          .eq('staff_id', staffProfileId)
          .eq('is_active', true);

      final assignedCustomerIds = (assignments as List)
          .map((a) => a['customer_id'] as String)
          .toSet();

      // STEP 2: Get customers with ACTIVE schemes only (for pending calculation)
      final customersWithActiveSchemes = await _supabase
          .from('user_schemes')
          .select('customer_id')
          .eq('status', 'active');

      // STEP 3: Intersect assigned customers with active schemes
      final activeSchemeCustomerIds = (customersWithActiveSchemes as List)
          .map((c) => c['customer_id'] as String)
          .where((id) => assignedCustomerIds.contains(id))
          .toSet();

      // STEP 4: Pending = active scheme customers − customers paid today
      final collectedCount = customersCollected.length;
      var pendingCount =
          activeSchemeCustomerIds.length - collectedCount;

      // STEP 5: Defensive clamp (never show negative pending)
      if (pendingCount < 0) {
        pendingCount = 0;
      }

      // Get total customers for completion percent (use active scheme customers)
      final totalCustomers = activeSchemeCustomerIds.length;
      
      // Get assigned customers for missed payments count (need full list)
      final assignedCustomers = await getAssignedCustomers(staffProfileId);

      // Count missed payments
      int missedPaymentsCount = 0;
      for (var customer in assignedCustomers) {
        if ((customer['missedPayments'] as int) > 0) {
          missedPaymentsCount++;
        }
      }

      return {
        'totalAmount': totalAmount,
        'customersCollected': collectedCount,
        'totalCustomers': totalCustomers,
        'completionPercent': totalCustomers > 0 
            ? (collectedCount / totalCustomers) * 100 
            : 0.0,
        'pendingCount': pendingCount,
        'missedPaymentsCount': missedPaymentsCount,
        'cashAmount': cashAmount,
        'upiAmount': upiAmount,
      };
    } catch (e, stackTrace) {
      debugPrint('StaffDataService.getTodayStats FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get today's collections
  static Future<List<Map<String, dynamic>>> getTodayCollections(String staffProfileId) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final payments = await _supabase
          .from('payments')
          .select('''
            customer_id,
            amount,
            payment_method,
            payment_time,
            customers!inner(
              profiles!inner(name)
            )
          ''')
          .eq('staff_id', staffProfileId)
          .eq('payment_date', today)
          .eq('status', 'completed')
          .order('payment_time', ascending: false);

      final List<Map<String, dynamic>> result = [];

      for (var payment in payments) {
        final customer = payment['customers'] as Map<String, dynamic>;
        final profile = customer['profiles'] as Map<String, dynamic>;
        
        // Get latest scheme (any status) for display purposes
        final userScheme = await _supabase
            .from('user_schemes')
            .select('schemes!inner(name)')
            .eq('customer_id', payment['customer_id'] as String)
            .order('enrollment_date', ascending: false)
            .limit(1)
            .maybeSingle();

        final schemeName = userScheme?['schemes']?['name'] as String? ?? 'Unknown Scheme';
        final paymentTime = payment['payment_time'] as String? ?? '';

        result.add({
          'customerId': payment['customer_id'] as String,
          'customerName': profile['name'] as String? ?? 'Unknown',
          'scheme': schemeName,
          'amount': (payment['amount'] as num?)?.toDouble() ?? 0.0,
          'method': payment['payment_method'] as String? ?? 'cash',
          'time': _formatTime(paymentTime),
        });
      }

      return result;
    } catch (e, stackTrace) {
      debugPrint('StaffDataService.getTodayCollections FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get payment history for a customer
  static Future<List<Map<String, dynamic>>> getPaymentHistory(String customerId) async {
    try {
      final payments = await _supabase
          .from('payments')
          .select('payment_date, amount, status, payment_method')
          .eq('customer_id', customerId)
          .order('payment_date', ascending: false)
          .limit(50);

      final List<Map<String, dynamic>> result = [];

      for (var payment in payments) {
        final paymentStatus = payment['status'] as String? ?? '';
        result.add({
          'date': payment['payment_date'] as String? ?? '',
          'amount': (payment['amount'] as num?)?.toDouble() ?? 0.0,
          'status': paymentStatus == 'completed' ? 'paid' : 'missed',
          'method': payment['payment_method'] as String? ?? 'cash',
        });
      }

      return result;
    } catch (e, stackTrace) {
      debugPrint('StaffDataService.getPaymentHistory FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get priority customers (with missed payments)
  static Future<List<Map<String, dynamic>>> getPriorityCustomers(String staffProfileId) async {
    try {
      final customers = await getAssignedCustomers(staffProfileId);
      final priority = customers
          .where((c) => (c['missedPayments'] as int) > 0)
          .toList();

      priority.sort((a, b) =>
          (b['missedPayments'] as int).compareTo(a['missedPayments'] as int));

      return priority;
    } catch (e, stackTrace) {
      debugPrint('StaffDataService.getPriorityCustomers FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get scheme breakdown (Gold vs Silver)
  static Future<Map<String, double>> getSchemeBreakdown(String staffProfileId) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final payments = await _supabase
          .from('payments')
          .select('''
            amount,
            user_schemes!inner(
              schemes!inner(asset_type)
            )
          ''')
          .eq('staff_id', staffProfileId)
          .eq('payment_date', today)
          .eq('status', 'completed');

      double goldTotal = 0.0;
      double silverTotal = 0.0;

      for (var payment in payments) {
        final userScheme = payment['user_schemes'] as Map<String, dynamic>;
        final scheme = userScheme['schemes'] as Map<String, dynamic>;
        final assetType = scheme['asset_type'] as String? ?? '';
        final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;

        if (assetType.toLowerCase() == 'gold') {
          goldTotal += amount;
        } else if (assetType.toLowerCase() == 'silver') {
          silverTotal += amount;
        }
      }

      return {'Gold': goldTotal, 'Silver': silverTotal};
    } catch (e, stackTrace) {
      debugPrint('StaffDataService.getSchemeBreakdown FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get due today customers (no missed payments, not paid today)
  static Future<List<Map<String, dynamic>>> getDueToday(String staffProfileId) async {
    try {
      final customers = await getAssignedCustomers(staffProfileId);
      return customers
          .where((c) => 
              (c['paidToday'] as bool) == false && 
              (c['missedPayments'] as int) == 0)
          .toList();
    } catch (e, stackTrace) {
      debugPrint('StaffDataService.getDueToday FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get pending customers (not paid today)
  static Future<List<Map<String, dynamic>>> getPending(String staffProfileId) async {
    try {
      final customers = await getAssignedCustomers(staffProfileId);
      return customers
          .where((c) => (c['paidToday'] as bool) == false)
          .toList();
    } catch (e, stackTrace) {
      debugPrint('StaffDataService.getPending FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get daily target from staff_metadata
  static Future<Map<String, dynamic>> getDailyTarget(String staffProfileId) async {
    try {
      // STEP 2: Add diagnostics before query
      final session = _supabase.auth.currentSession;
      final user = _supabase.auth.currentUser;
      
      debugPrint('SESSION BEFORE staff_metadata QUERY (getDailyTarget) = $session');
      debugPrint('USER BEFORE staff_metadata QUERY (getDailyTarget) = $user');
      debugPrint('SUPABASE CLIENT HASH (getDailyTarget) = ${_supabase.hashCode}');
      
      // STEP 3: Enforce hard auth guard
      if (session == null) {
        throw Exception('Auth session not ready — blocking staff_metadata access');
      }
      
      final metadata = await _supabase
          .from('staff_metadata')
          .select('daily_target_amount, daily_target_customers')
          .eq('profile_id', staffProfileId)
          .maybeSingle();

      return {
        'amount': (metadata?['daily_target_amount'] as num?)?.toDouble() ?? 0.0,
        'customers': metadata?['daily_target_customers'] as int? ?? 0,
      };
    } catch (e, stackTrace) {
      debugPrint('StaffDataService.getDailyTarget FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Calculate total due for customer (including missed payments)
  static double calculateTotalDue(Map<String, dynamic> customer) {
    final missedCount = customer['missedPayments'] as int;
    final dueAmount = customer['dueAmount'] as double;
    final minAmount = customer['minAmount'] as double;

    return (missedCount * minAmount) + dueAmount;
  }

  // Helper methods

  static String _mapPaymentFrequency(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return frequency;
    }
  }

  static int _extractSchemeNumber(String schemeName) {
    final match = RegExp(r'(\d+)').firstMatch(schemeName);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '1') ?? 1;
    }
    return 1;
  }

  static String _formatTime(String timeStr) {
    if (timeStr.isEmpty) return '';
    try {
      // timeStr is in HH:mm:ss format
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = parts[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '$displayHour:$minute $period';
      }
    } catch (e) {
      // Fallback
    }
    return timeStr;
  }

  /// Get staff profile information (profile + metadata)
  /// Returns null if profile does not exist (not an error)
  static Future<Map<String, dynamic>?> getStaffProfile(String profileId) async {
    try {
      // Fetch profile
      final profile = await _supabase
          .from('profiles')
          .select('id, name, phone, email, role, active, created_at')
          .eq('id', profileId)
          .maybeSingle();

      // Returning null means profile does not exist (not an error)
      if (profile == null) return null;

      // Fetch staff metadata
      final metadata = await _supabase
          .from('staff_metadata')
          .select('staff_code, staff_type, daily_target_amount, daily_target_customers, join_date')
          .eq('profile_id', profileId)
          .maybeSingle();

      // Combine data
      return {
        'id': profile['id'],
        'name': profile['name'] as String? ?? 'Unknown',
        'phone': profile['phone'] as String? ?? '',
        'email': profile['email'] as String? ?? '',
        'role': profile['role'] as String? ?? 'staff',
        'active': profile['active'] as bool? ?? true,
        'created_at': profile['created_at'] as String? ?? '',
        'staff_code': metadata?['staff_code'] as String? ?? '',
        'staff_type': metadata?['staff_type'] as String? ?? 'collection',
        'daily_target_amount': (metadata?['daily_target_amount'] as num?)?.toDouble() ?? 0.0,
        'daily_target_customers': metadata?['daily_target_customers'] as int? ?? 0,
        'join_date': metadata?['join_date'] as String? ?? '',
      };
    } catch (e, stackTrace) {
      debugPrint('StaffDataService.getStaffProfile FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow; // ✅ Fail loud
    }
  }

  /// Get staff metadata only
  static Future<Map<String, dynamic>?> getStaffMetadata(String profileId) async {
    try {
      final metadata = await _supabase
          .from('staff_metadata')
          .select('*')
          .eq('profile_id', profileId)
          .maybeSingle();

      return metadata as Map<String, dynamic>?;
    } catch (e, stackTrace) {
      debugPrint('StaffDataService.getStaffMetadata FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow; // ✅ Fail loud
    }
  }
}

