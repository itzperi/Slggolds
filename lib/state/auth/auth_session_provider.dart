import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseSessionProvider = StreamProvider<Session?>(
  (ref) {
    return Supabase.instance.client.auth.onAuthStateChange
        .map((event) => event.session);
  },
);

