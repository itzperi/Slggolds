import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_state_provider.dart' as auth_state;

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

  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) {
    return null;
  }

  try {
    final response = await Supabase.instance.client
        .from('profiles')
        .select('id, role')
        .eq('user_id', userId)
        .maybeSingle();

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
    return null;
  }
});

