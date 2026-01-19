import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final staffDashboardProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, staffId) {
  // Listen to payments table for this staff member to trigger updates
  final paymentStream = Supabase.instance.client
      .from('payments')
      .stream(primaryKey: ['id'])
      .eq('staff_id', staffId)
      .map((_) => DateTime.now()); // heartbeat

  // Combine with RPC call
  return paymentStream.asyncMap((_) async {
    final response = await Supabase.instance.client.rpc(
      'get_staff_dashboard',
      params: {'staff_id_param': staffId},
    );
    return Map<String, dynamic>.from(response);
  });
});

final assignedCustomersProvider = FutureProvider.family<List<Map<String, dynamic>>, ({String staffId, String filter})>((ref, arg) async {
  final supabase = Supabase.instance.client;
  final response = await supabase.rpc(
    'get_assigned_customers',
    params: {
      'staff_id_param': arg.staffId,
      'filter_type': arg.filter,
    },
  );
  return List<Map<String, dynamic>>.from(response);
});
