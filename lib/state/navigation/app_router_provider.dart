import 'package:flutter/material.dart';
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
import '../auth/auth_flow_provider.dart';

/// Router provider that handles both Riverpod auth state and Provider UI flow states
/// 
/// Priority order:
/// 1. UI flow states (staffLogin, otpVerifiedNeedsPin) from AuthFlowNotifier
/// 2. Auth states (unauthenticated, authenticated) from Riverpod
/// 
final appRouterProvider = Provider<Widget>((ref) {
  // First, check UI flow states from AuthFlowNotifier (Riverpod-managed)
  final authFlow = ref.watch(authFlowProvider);
  
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
      // Fall through to Riverpod auth state logic
      break;

    case AuthFlowState.authenticated: {
      // NEW: If AuthFlow explicitly says authenticated (e.g. via PIN), 
      // we proceed to profile fetching even if Supabase session is slow to sync
      final profileAsync = ref.watch(userProfileProvider);
      
      return profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Scaffold(
              backgroundColor: Color(0xFF140A33),
              body: Center(child: Text('Profile not found', style: TextStyle(color: Colors.white))),
            );
          }
          
          switch (profile.role) {
            case 'customer':
              return const DashboardScreen();
            case 'staff':
              return StaffDashboard(staffId: profile.profileId);
            default:
              return const Scaffold(
                backgroundColor: Color(0xFF140A33),
                body: Center(child: Text('Unknown role', style: TextStyle(color: Colors.white))),
              );
          }
        },
        loading: () => const Scaffold(
          backgroundColor: Color(0xFF140A33),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
          ),
        ),
        error: (err, stack) => Scaffold(
          backgroundColor: Color(0xFF140A33),
          body: Center(
            child: Text('Error: $err', style: const TextStyle(color: Colors.white)),
          ),
        ),
      );
    }
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
            return const Scaffold(
              backgroundColor: Color(0xFF140A33),
              body: Center(child: Text('Profile not found', style: TextStyle(color: Colors.white))),
            );
          }
          
          switch (profile.role) {
            case 'customer':
              return const DashboardScreen();
            case 'staff':
              return StaffDashboard(staffId: profile.profileId);
            default:
              return const Scaffold(
                backgroundColor: Color(0xFF140A33),
                body: Center(child: Text('Unknown role', style: TextStyle(color: Colors.white))),
              );
          }
        },
        loading: () => const Scaffold(
          backgroundColor: Color(0xFF140A33),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
          ),
        ),
        error: (err, stack) => Scaffold(
          backgroundColor: Color(0xFF140A33),
          body: Center(
            child: Text('Error: $err', style: const TextStyle(color: Colors.white)),
          ),
        ),
      );
  }
});
