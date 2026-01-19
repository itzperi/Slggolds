import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_session_provider.dart';

/// Provider for the current user's profile and customer record
final customerProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final session = ref.watch(supabaseSessionProvider).value;
  if (session == null) return null;
  
  final supabase = Supabase.instance.client;
  
  // Fetch profile and related customer data
  final response = await supabase
      .from('profiles')
      .select('*, customers(*)')
      .eq('user_id', session.user.id)
      .maybeSingle();
      
  return response;
});

/// FutureProvider to fetch all schemes metadata (for identifying asset types)
final metadataSchemesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase.from('schemes').select('id, name, asset_type, scheme_code');
  
  // Create a map for quick lookup: scheme_id -> scheme_data
  final map = <String, dynamic>{};
  for (final item in response) {
    map[item['id']] = item;
  }
  return map;
});

/// StreamProvider for customer dashboard metrics (Realtime)
final customerDashboardProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, customerId) {
  final supabase = Supabase.instance.client;
  
  // 1. Get Scheme Metadata (to know if Gold or Silver)
  final schemesMetadataAsync = ref.watch(metadataSchemesProvider);
  final schemesMap = schemesMetadataAsync.value ?? {};

  // 2. Get Real-time Market Rates
  final marketRatesAsync = ref.watch(marketRatesProvider);
  final marketRates = marketRatesAsync.value ?? {'gold': 0.0, 'silver': 0.0};

  // 3. Listen to 'user_schemes' changes
  return supabase
      .from('user_schemes')
      .stream(primaryKey: ['id'])
      .eq('customer_id', customerId)
      .map((data) {
        double totalGrams = 0;
        double totalInvested = 0;
        double goldGrams = 0;
        double silverGrams = 0;
        int activeSchemesCount = 0;
        int totalPaymentsMade = 0;
        int totalExpectedPayments = 0;
        DateTime? earliestNextDue;

        for (final us in data) {
          if (us['status'] != 'active') continue;
          
          activeSchemesCount++;
          final grams = (us['accumulated_grams'] as num).toDouble();
          final invested = (us['total_amount_paid'] as num).toDouble();
          final paidCount = (us['payments_made'] as num).toInt();
          
          totalInvested += invested;
          totalPaymentsMade += paidCount;

          // Determine asset type from metadata
          final schemeId = us['scheme_id'];
          final schemeData = schemesMap[schemeId];
          final assetType = schemeData?['asset_type'] ?? 'gold';
          final durationMonths = (schemeData?['duration_months'] as num?)?.toInt() ?? 12;
          final frequency = us['payment_frequency'] ?? 'monthly';

          // Calculate expected payments for this scheme
          int expectedForScheme = 0;
          int daysBetween = 30;
          if (frequency == 'daily') {
            expectedForScheme = durationMonths * 30;
            daysBetween = 1;
          } else if (frequency == 'weekly') {
            expectedForScheme = durationMonths * 4;
            daysBetween = 7;
          } else {
            expectedForScheme = durationMonths;
            daysBetween = 30;
          }
          totalExpectedPayments += expectedForScheme;

          // Calculate next due date for this scheme
          final enrollmentDateStr = us['enrollment_date'];
          if (enrollmentDateStr != null) {
            final enrollmentDate = DateTime.parse(enrollmentDateStr);
            final nextDueDate = enrollmentDate.add(Duration(days: paidCount * daysBetween));
            if (earliestNextDue == null || nextDueDate.isBefore(earliestNextDue!)) {
              earliestNextDue = nextDueDate;
            }
          }

          if (assetType == 'silver') {
            silverGrams += grams;
          } else {
            goldGrams += grams;
          }
        }

        totalGrams = goldGrams + silverGrams;

        // Calculate Market Value
        final goldValue = goldGrams * (marketRates['gold'] as num).toDouble();
        final silverValue = silverGrams * (marketRates['silver'] as num).toDouble();
        final totalMarketValue = goldValue + silverValue;

        return {
          'total_grams': totalGrams,
          'total_invested': totalInvested,
          'market_value': totalMarketValue,
          'schemes_count': activeSchemesCount,
          'gold_grams': goldGrams,
          'silver_grams': silverGrams,
          'total_payments_made': totalPaymentsMade,
          'total_expected_payments': totalExpectedPayments,
          'progress': totalExpectedPayments > 0 ? totalPaymentsMade / totalExpectedPayments : 0.0,
          'next_due': earliestNextDue?.toIso8601String(),
        };
      });
});

/// StreamProvider for active schemes
final customerSchemesProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, customerId) {
  return Supabase.instance.client
      .from('user_schemes')
      .stream(primaryKey: ['id'])
      .eq('customer_id', customerId)
      .order('created_at')
      .map((data) => List<Map<String, dynamic>>.from(data));
});

/// StreamProvider for recent payments
final customerPaymentsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, customerId) {
  return Supabase.instance.client
      .from('payments')
      .stream(primaryKey: ['id'])
      .eq('customer_id', customerId)
      .order('created_at', ascending: false)
      .limit(10)
      .map((data) => List<Map<String, dynamic>>.from(data));
});

/// StreamProvider for market rates
final marketRatesProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return Supabase.instance.client
      .from('market_rates')
      .stream(primaryKey: ['id'])
      .order('rate_date', ascending: false)
      .limit(5)
      .map((data) {
        if (data.isEmpty) return {'gold': 0.0, 'gold_change': 0.0, 'silver': 0.0, 'silver_change': 0.0};
        
        // Find latest gold and silver rates
        var goldPrice = 0.0;
        var silverPrice = 0.0;
        
        // Sort by date inside the stream result if not guaranteed
        data.sort((a, b) => (b['rate_date'] as String).compareTo(a['rate_date'] as String));

        for (var r in data) {
          if (r['asset_type'] == 'gold' && goldPrice == 0) goldPrice = (r['price_per_gram'] as num).toDouble();
          if (r['asset_type'] == 'silver' && silverPrice == 0) silverPrice = (r['price_per_gram'] as num).toDouble();
        }
        
        return {
          'gold': goldPrice,
          'gold_change': 0.0, 
          'silver': silverPrice,
          'silver_change': 0.0,
        };
      });
});

