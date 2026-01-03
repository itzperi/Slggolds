// lib/services/auth_flow_notifier.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthFlowState {
  unauthenticated,
  staffLogin,
  otpVerifiedNeedsPin,
  authenticated,
}

class AuthFlowNotifier extends ChangeNotifier {
  AuthFlowState _state = AuthFlowState.unauthenticated;
  String? _phoneNumber;
  bool _isFirstTime = false;
  bool _isResetPin = false;

  AuthFlowState get state => _state;
  String? get phoneNumber => _phoneNumber;
  bool get isFirstTime => _isFirstTime;
  bool get isResetPin => _isResetPin;

  // One-time session bootstrap - checks Supabase session on app start
  // This is NOT UI code - it's backend glue that updates state
  void initializeSession() {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      
      if (session == null) {
        setUnauthenticated();
      } else {
        setAuthenticated();
      }
      
      print('AuthFlowNotifier: Session initialized - state: $_state');
    } catch (e) {
      print('AuthFlowNotifier: Error initializing session: $e');
      setUnauthenticated();
    }
  }

  // OTP verified - user needs to set up PIN
  void setOtpVerified({
    required String phoneNumber,
    bool isFirstTime = false,
    bool isResetPin = false,
  }) {
    // Idempotent: Don't notify if already in this state
    if (_state == AuthFlowState.otpVerifiedNeedsPin) {
      print('AuthFlowNotifier: Already in otpVerifiedNeedsPin state, skipping duplicate call');
      return;
    }
    
    final oldState = _state;
    _state = AuthFlowState.otpVerifiedNeedsPin;
    _phoneNumber = phoneNumber;
    _isFirstTime = isFirstTime;
    _isResetPin = isResetPin;
    notifyListeners();
    print('AuthFlowNotifier: State transition: $oldState -> otpVerifiedNeedsPin for $phoneNumber');
  }

  // PIN setup completed - user is fully authenticated
  void setAuthenticated() {
    // Idempotent: Don't notify if already in this state
    if (_state == AuthFlowState.authenticated) {
      print('AuthFlowNotifier: Already in authenticated state, skipping duplicate call');
      return;
    }
    
    final oldState = _state;
    _state = AuthFlowState.authenticated;
    _phoneNumber = null;
    _isFirstTime = false;
    _isResetPin = false;
    notifyListeners();
    print('AuthFlowNotifier: State transition: $oldState -> authenticated');
  }

  // Navigate to staff login screen
  void goToStaffLogin() {
    debugPrint('✅ goToStaffLogin: Instance hashCode = ${hashCode}');
    debugPrint('✅ goToStaffLogin: Listeners = ${hasListeners ? "YES" : "NO"}');
    
    // Idempotent: If already in staffLogin state, just return (no error)
    if (_state == AuthFlowState.staffLogin) {
      debugPrint('✅ goToStaffLogin: Already in staffLogin state, skipping');
      return;
    }
    
    // Enforce invariant: can only transition from unauthenticated
    if (_state != AuthFlowState.unauthenticated) {
      debugPrint('❌ ILLEGAL goToStaffLogin call from state $_state');
      debugPrint('❌ Current state: $_state, expected: ${AuthFlowState.unauthenticated}');
      debugPrint('❌ Attempting to force reset to unauthenticated first...');
      // Force reset to unauthenticated, then transition to staffLogin
      forceLogout();
      // Now transition to staffLogin
      _state = AuthFlowState.staffLogin;
      notifyListeners();
      debugPrint('✅ goToStaffLogin: Force reset completed, now in staffLogin state');
      return;
    }
    
    final oldState = _state;
    _state = AuthFlowState.staffLogin;
    debugPrint('✅ goToStaffLogin (user initiated): $oldState -> staffLogin');
    debugPrint('✅ goToStaffLogin: State updated to $_state');
    debugPrint('✅ goToStaffLogin: Calling notifyListeners()');
    notifyListeners();
    debugPrint('✅ goToStaffLogin: notifyListeners() completed');
    debugPrint('✅ goToStaffLogin: State after notify: $_state');
  }

  // Force logout - ALWAYS resets state (no idempotent check)
  // Use this for all logout paths to enforce state reset invariant
  void forceLogout() {
    debugPrint('🔥 FORCE LOGOUT from $_state');
    debugPrint('🔥 FORCE LOGOUT: Instance hashCode = ${hashCode}');
    debugPrint('🔥 FORCE LOGOUT: Listeners = ${hasListeners ? "YES" : "NO"}');
    
    final oldState = _state;
    _state = AuthFlowState.unauthenticated;
    _phoneNumber = null;
    _isFirstTime = false;
    _isResetPin = false;
    
    debugPrint('🔥 FORCE LOGOUT: State reset to unauthenticated');
    notifyListeners();
    debugPrint('🔥 FORCE LOGOUT: notifyListeners() completed');
    debugPrint('🔥 FORCE LOGOUT: Transition: $oldState -> $_state');
  }

  // Logout - reset to unauthenticated (idempotent - for initialization only)
  void setUnauthenticated() {
    // Idempotent: Don't notify if already in this state
    if (_state == AuthFlowState.unauthenticated) {
      print('AuthFlowNotifier: Already in unauthenticated state, skipping duplicate call');
      return;
    }
    
    final oldState = _state;
    _state = AuthFlowState.unauthenticated;
    _phoneNumber = null;
    _isFirstTime = false;
    _isResetPin = false;
    notifyListeners();
    print('AuthFlowNotifier: State transition: $oldState -> unauthenticated');
  }
}

