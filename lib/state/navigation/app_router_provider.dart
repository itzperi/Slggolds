import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import '../auth/auth_state_provider.dart' as auth_state;
import '../auth/user_profile_provider.dart';
import '../../screens/login_screen.dart';
import '../../screens/customer/dashboard_screen.dart';
import '../../screens/staff/staff_dashboard.dart';
import '../../screens/staff/staff_login_screen.dart';
import '../../screens/auth/pin_setup_screen.dart';
import '../../services/auth_flow_notifier.dart';

/// Router provider that handles both Riverpod auth state and Provider UI flow states
/// 
/// Priority order:
/// 1. UI flow states (staffLogin, otpVerifiedNeedsPin) from AuthFlowNotifier
/// 2. Auth states (unauthenticated, authenticated) from Riverpod
/// 
/// NOTE: This provider uses Provider.family to access BuildContext, which allows
/// it to read AuthFlowNotifier from the Provider tree. The Provider Consumer
/// wrapper in main.dart ensures rebuilds when AuthFlowNotifier changes.
final appRouterProvider = Provider.family<Widget, BuildContext>((ref, context) {
  // First, check UI flow states from AuthFlowNotifier (Provider)
  // Using listen: false because the Provider Consumer wrapper handles rebuilds
  final authFlow = provider.Provider.of<AuthFlowNotifier>(context, listen: false);
  
  // Handle UI flow states (these take priority)
  switch (authFlow.state) {
    case AuthFlowState.staffLogin:
      return const StaffLoginScreen();
    
    case AuthFlowState.otpVerifiedNeedsPin:
      return PinSetupScreen(
        phoneNumber: authFlow.phoneNumber ?? '',
        isFirstTime: authFlow.isFirstTime,
        isReset: authFlow.isResetPin,
      );
    
    case AuthFlowState.unauthenticated:
    case AuthFlowState.authenticated:
      // Fall through to Riverpod auth state logic
      break;
  }
  
  // Fall back to Riverpod auth state
  final authStateValue = ref.watch(auth_state.authStateProvider);
  
  switch (authStateValue) {
    case auth_state.AuthState.unauthenticated:
      return const LoginScreen();
    
    case auth_state.AuthState.authenticated:
      final profileAsync = ref.watch(userProfileProvider);
      
      return profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const SizedBox.shrink();
          }
          
          switch (profile.role) {
            case 'customer':
              return const DashboardScreen();
            case 'staff':
              return StaffDashboard(staffId: profile.profileId);
            default:
              return const SizedBox.shrink();
          }
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      );
  }
});
