import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_state_provider.dart' as auth_state;
import 'auth_flow_provider.dart' as auth_flow;
import '../../utils/secure_storage_helper.dart';
import 'package:flutter/foundation.dart';

class UserProfile {
  final String role;
  final String profileId;

  UserProfile({required this.role, required this.profileId});
}

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final authStateValue = ref.watch(auth_state.authStateProvider);
  
  if (authStateValue != auth_state.AuthState.authenticated) {
    return null;
  }

  try {
    final supabase = Supabase.instance.client;
    Map<String, dynamic>? response;

    final userId = supabase.auth.currentUser?.id;

    if (userId != null) {
      response = await supabase
          .from('profiles')
          .select('id, role')
          .eq('user_id', userId)
          .maybeSingle();
    } else {
      // Fallback for PIN-only login where no session exists yet
      final authFlowNotifier = ref.read(auth_flow.authFlowProvider);
      final phone = authFlowNotifier.phoneNumber;
      final savedPhone = phone ?? await SecureStorageHelper.getSavedPhone();
      
      if (savedPhone != null) {
        final formattedPhone = savedPhone.startsWith('+91') ? savedPhone : '+91$savedPhone';
        debugPrint('userProfileProvider: Falling back to phone lookup for $formattedPhone');
        response = await supabase
            .from('profiles')
            .select('id, role')
            .eq('phone', formattedPhone)
            .maybeSingle();
      }
    }

    if (response == null) {
      return null;
    }

    final role = response['role'] as String?;
    final profileId = response['id'] as String?;

    if (role == null || profileId == null) {
      return null;
    }

    return UserProfile(role: role, profileId: profileId);
  } catch (e) {
    debugPrint('userProfileProvider error: $e');
    return null;
  }
});

