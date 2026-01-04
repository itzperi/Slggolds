import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_session_provider.dart';

enum AuthState {
  unauthenticated,
  authenticated,
}

final authStateProvider = Provider<AuthState>((ref) {
  final sessionAsync = ref.watch(supabaseSessionProvider);

  return sessionAsync.when(
    data: (session) =>
        session == null ? AuthState.unauthenticated : AuthState.authenticated,
    loading: () => AuthState.unauthenticated,
    error: (_, __) => AuthState.unauthenticated,
  );
});

