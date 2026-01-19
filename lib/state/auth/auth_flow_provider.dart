import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_flow_notifier.dart';

/// Provider that exposes the legacy AuthFlowNotifier to the Riverpod tree.
/// This allows Riverpod-based navigation and state management to react
/// to UI flow state changes (like staff login, PIN set up).
final authFlowProvider = ChangeNotifierProvider<AuthFlowNotifier>((ref) {
  return AuthFlowNotifier();
});
