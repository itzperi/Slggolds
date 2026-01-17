// lib/main.dart

// ⚠️ LEGACY AUTH FLOW — DO NOT MODIFY
// See /docs/architecture_current.md


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/login_screen.dart';
import 'screens/customer/dashboard_screen.dart';
import 'screens/auth/pin_setup_screen.dart';
import 'screens/staff/staff_dashboard.dart';
import 'screens/staff/staff_login_screen.dart';
import 'services/auth_flow_notifier.dart';
import 'services/role_routing_service.dart';
import 'services/offline_sync_service.dart';
import 'state/auth/auth_state_provider.dart' as auth_state;
import 'state/navigation/app_router_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  // Initialize error tracking (Sentry)
  // Note: Sentry DSN should be set in environment variables for production
  // For now, error tracking is disabled until DSN is configured
  final sentryDsn = dotenv.env['SENTRY_DSN'];
  
  if (sentryDsn != null && sentryDsn.isNotEmpty) {
    try {
      // Initialize Sentry only if DSN is provided
      // await SentryFlutter.init(
      //   (options) {
      //     options.dsn = sentryDsn;
      //     options.environment = kDebugMode ? 'development' : 'production';
      //     options.tracesSampleRate = 0.2; // Capture 20% of transactions
      //   },
      //   appRunner: () => _runApp(),
      // );
      // For now, we'll use the regular runApp but prepare for Sentry integration
      debugPrint('Sentry DSN found but Sentry initialization commented out. Enable when ready.');
    } catch (e) {
      debugPrint('Failed to initialize Sentry: $e');
    }
  }

  // Initialize Flutter error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log error to console in debug mode
    FlutterError.presentError(details);
    
    // In production, send to error tracking service
    if (sentryDsn != null && sentryDsn.isNotEmpty) {
      // TODO: Uncomment when Sentry is initialized
      // Sentry.captureException(
      //   details.exception,
      //   stackTrace: details.stack,
      // );
    }
    
    if (kDebugMode) {
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack: ${details.stack}');
    }
  };

  // Handle errors from async operations outside Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform Error: $error');
    debugPrint('Stack: $stack');
    
    // Send to error tracking service
    if (sentryDsn != null && sentryDsn.isNotEmpty) {
      // TODO: Uncomment when Sentry is initialized
      // Sentry.captureException(error, stackTrace: stack);
    }
    
    return true; // Prevent app crash
  };

  await _runApp();
}

Future<void> _runApp() async {

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseUrl.isEmpty) {
    throw Exception(
      'SUPABASE_URL is not set in .env file. '
      'Please copy .env.example to .env and add your Supabase credentials.',
    );
  }

  if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
    throw Exception(
      'SUPABASE_ANON_KEY is not set in .env file. '
      'Please copy .env.example to .env and add your Supabase credentials.',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Start offline sync service (GAP-048) - listens for connectivity and syncs queued payments
  OfflineSyncService.instance.start();

  // One-time session bootstrap - NO LONGER reads Supabase (now a no-op)
  final authFlowNotifier = AuthFlowNotifier();
  authFlowNotifier.initializeSession();

  // Create ProviderContainer to watch Riverpod auth state
  // This allows us to react to Riverpod auth state changes and update Provider
  final container = ProviderContainer();
  
  // Wire Provider to react to Riverpod auth state (ONE-WAY: Riverpod → Provider)
  // This replaces the old dual-authority pattern where Provider also read Supabase
  container.listen(
    auth_state.authStateProvider,
    (previous, next) {
      // Translate Riverpod AuthState to Provider UI state
      if (next == auth_state.AuthState.authenticated) {
        debugPrint('RIVERPOD → PROVIDER: Setting authenticated state');
        authFlowNotifier.setAuthenticated();
      } else if (next == auth_state.AuthState.unauthenticated) {
        debugPrint('RIVERPOD → PROVIDER: Setting unauthenticated state');
        // Use forceLogout() instead of setUnauthenticated() to ensure state reset
        // This guarantees state is reset even if already unauthenticated
        authFlowNotifier.forceLogout();
      }
    },
    fireImmediately: true, // Fire on first value to sync initial state
  );

  // Auth state listener - NO LONGER updates Provider state
  // Riverpod (supabaseSessionProvider) is now the only reader of Supabase auth
  // This listener only enforces business rules (mobile app access check)
  // Auth state is derived from Supabase session via Riverpod providers
  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    final event = data.event;
    
    if (event == AuthChangeEvent.signedIn) {
      try {
        // Check mobile app access (only runs after session is attached)
        debugPrint('AUTH LISTENER: Checking mobile app access...');
        final hasAccess = await RoleRoutingService.checkMobileAppAccess();
        debugPrint('AUTH LISTENER: Access check result = $hasAccess');
        
        if (!hasAccess) {
          // Access denied - logout (business rule enforcement)
          debugPrint('AUTH LISTENER: Access denied, signing out');
          await Supabase.instance.client.auth.signOut();
        } else {
          // Access granted - auth state will be derived by Riverpod from session
          debugPrint('AUTH LISTENER: Access granted (auth state derived by Riverpod)');
          // TODO (Sprint 2): Provider will react to Riverpod auth state in later steps
        }
      } catch (e, stackTrace) {
        // Access denied or error - logout (business rule enforcement)
        debugPrint('AUTH LISTENER: Exception caught: $e');
        debugPrint('AUTH LISTENER: Stack trace: $stackTrace');
        await Supabase.instance.client.auth.signOut();
      }
    } else if (event == AuthChangeEvent.signedOut) {
      // Supabase session ended - auth state will be derived by Riverpod from session
      debugPrint('AUTH LISTENER: signedOut event detected (auth state derived by Riverpod)');
      // TODO (Sprint 2): Provider will react to Riverpod auth state in later steps
    }
  });

  // Set custom error widget builder
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kDebugMode) {
      // In debug mode, show detailed error
      return ErrorWidget(details.exception);
    } else {
      // In production, show user-friendly error screen
      return Scaffold(
        backgroundColor: const Color(0xFF1A0F3E),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 24),
                Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Please restart the app. If the problem persists, contact support.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
  };

  runApp(
    ProviderScope(
      parent: container, // Use the container that watches auth state
      child: provider.ChangeNotifierProvider.value(
        value: authFlowNotifier,
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthFlowNotifier is created in main() and passed via ChangeNotifierProvider.value
    // This ensures initializeSession() runs before UI builds
    return MaterialApp(
      title: 'SLG Thangangal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF37),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: provider.Consumer<AuthFlowNotifier>(
        builder: (context, authFlow, child) {
          return Consumer(
            builder: (_, ref, __) {
              return ref.watch(appRouterProvider(context));
            },
          );
        },
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Widget? _roleBasedScreen;
  bool _isCheckingRole = false;
  AuthFlowState? _lastState;

  @override
  void initState() {
    super.initState();
    debugPrint('🔵 AuthGate.initState: Called');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRoleIfNeeded();
    });
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('🔵 AuthGate.didChangeDependencies: Called');
    // Trigger routing check when dependencies change (e.g., Provider updates)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRoleIfNeeded();
    });
  }

  Future<void> _checkRoleIfNeeded() async {
    final authFlow = provider.Provider.of<AuthFlowNotifier>(context, listen: false);
    
    // Reset state when unauthenticated (logout)
    if (authFlow.state == AuthFlowState.unauthenticated) {
      if (_lastState != AuthFlowState.unauthenticated) {
        // Logout detected - reset all routing state
        setState(() {
          _lastState = authFlow.state;
          _roleBasedScreen = null;
          _isCheckingRole = false;
        });
      }
      return;
    }
    
    // IDEMPOTENT ROUTING: If authenticated but no screen set, always route
    // This removes dependency on transition detection and handles all cases:
    // - Cold start auto-login
    // - Manual login after logout
    // - State changes that might be missed by transition detection
    if (authFlow.state == AuthFlowState.authenticated) {
      if (_roleBasedScreen == null && !_isCheckingRole) {
        debugPrint('AuthGate: Triggering routing (authenticated but no screen)');
        _lastState = authFlow.state;
        await _checkRoleAndRoute();
      } else {
        debugPrint('AuthGate: Skipping routing - screen=${_roleBasedScreen != null}, checking=${_isCheckingRole}');
        _lastState = authFlow.state;
      }
    } else {
      _lastState = authFlow.state;
    }
  }

  Future<void> _checkRoleAndRoute() async {
    debugPrint('AuthGate._checkRoleAndRoute: START');
    if (!mounted) {
      debugPrint('AuthGate._checkRoleAndRoute: NOT MOUNTED, returning');
      return;
    }
    
    debugPrint('AuthGate._checkRoleAndRoute: Setting _isCheckingRole = true');
    setState(() => _isCheckingRole = true);
    
    try {
      // ← MOVE Provider.of INSIDE try block
      final authFlow = provider.Provider.of<AuthFlowNotifier>(context, listen: false);
      debugPrint('AuthGate._checkRoleAndRoute: Got authFlow from Provider');
      
      // Access check is done in auth state listener (after SIGNED_IN event)
      // Here we just fetch role and route
      final userId = Supabase.instance.client.auth.currentUser?.id;
      debugPrint('AuthGate._checkRoleAndRoute: Got userId = $userId');
      
      if (userId == null) {
        debugPrint('AuthGate._checkRoleAndRoute: No userId, signing out');
        await Supabase.instance.client.auth.signOut();
        authFlow.forceLogout();
        if (mounted) {
          setState(() {
            _roleBasedScreen = const LoginScreen(key: ValueKey('login_screen'));
            _isCheckingRole = false;
          });
        }
        return;
      }

      debugPrint('AuthGate._checkRoleAndRoute: Fetching profile for userId = $userId');
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('id, role')
          .eq('user_id', userId)
          .maybeSingle();

      debugPrint('AuthGate._checkRoleAndRoute: Profile response = $profileResponse');

      if (profileResponse == null) {
        debugPrint('AuthGate._checkRoleAndRoute: No profile found, signing out');
        await Supabase.instance.client.auth.signOut();
        authFlow.forceLogout();
        if (mounted) {
          setState(() {
            _roleBasedScreen = const LoginScreen(key: ValueKey('login_screen'));
            _isCheckingRole = false;
          });
        }
        return;
      }

      final role = profileResponse['role'] as String?;
      final profileId = profileResponse['id'] as String?;

      debugPrint('AuthGate._checkRoleAndRoute: role = $role, profileId = $profileId');

      if (role == null || profileId == null) {
        debugPrint('AuthGate._checkRoleAndRoute: Role or profileId null, signing out');
        await Supabase.instance.client.auth.signOut();
        authFlow.forceLogout();
        if (mounted) {
          setState(() {
            _roleBasedScreen = const LoginScreen(key: ValueKey('login_screen'));
            _isCheckingRole = false;
          });
        }
        return;
      }

      Widget targetScreen;
      switch (role) {
        case 'customer':
          debugPrint('AuthGate._checkRoleAndRoute: Routing to customer dashboard');
          targetScreen = const DashboardScreen(key: ValueKey('customer_dashboard'));
          break;
        case 'staff':
          debugPrint('AuthGate._checkRoleAndRoute: Routing to staff dashboard');
          targetScreen = StaffDashboard(key: const ValueKey('staff_dashboard'), staffId: profileId);
          break;
        default:
          debugPrint('AuthGate._checkRoleAndRoute: Unknown role, signing out');
          await Supabase.instance.client.auth.signOut();
          authFlow.forceLogout();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This account does not have mobile app access.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
              ),
            );
            setState(() {
              _roleBasedScreen = const LoginScreen(key: ValueKey('login_screen'));
              _isCheckingRole = false;
            });
          }
          return;
      }

      if (mounted) {
        setState(() {
          _roleBasedScreen = targetScreen;
          _isCheckingRole = false;
        });
        debugPrint('AuthGate._checkRoleAndRoute: ROUTED TO ${_roleBasedScreen.runtimeType}');
      }
    } catch (e, stackTrace) {
      debugPrint('AuthGate._checkRoleAndRoute: ERROR caught - $e');
      debugPrint('AuthGate._checkRoleAndRoute: Stack trace - $stackTrace');
      
      // Access denied or error - logout
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (signOutError) {
        debugPrint('AuthGate._checkRoleAndRoute: Sign out also failed - $signOutError');
      }
      
      final authFlow = provider.Provider.of<AuthFlowNotifier>(context, listen: false);
      authFlow.forceLogout();
      
      if (mounted) {
        final message = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.isNotEmpty ? message : 'Authentication error occurred.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        setState(() {
          _roleBasedScreen = const LoginScreen(key: ValueKey('login_screen'));
          _isCheckingRole = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authFlow = provider.Provider.of<AuthFlowNotifier>(context); // ← Use this instead
    debugPrint('🟢 AuthGate.build() via Provider.of - state = ${authFlow.state}');
    debugPrint('🟢 AuthGate.build() - Instance hashCode = ${authFlow.hashCode}');
    
    switch (authFlow.state) {
      case AuthFlowState.unauthenticated:
        debugPrint('🟢 Returning LoginScreen');
        return const LoginScreen(key: ValueKey('login_screen'));
      
      case AuthFlowState.staffLogin:
        debugPrint('🟢 Returning StaffLoginScreen');
        return const StaffLoginScreen(key: ValueKey('staff_login_screen'));
      
      case AuthFlowState.otpVerifiedNeedsPin:
        debugPrint('🟢 Returning PinSetupScreen');
        return PinSetupScreen(
          key: const ValueKey('pin_setup_screen'),
          phoneNumber: authFlow.phoneNumber ?? '',
          isFirstTime: authFlow.isFirstTime,
          isReset: authFlow.isResetPin,
        );
      
      case AuthFlowState.authenticated:
        debugPrint('🟢 Authenticated state - checking role screen');
        
        // CRITICAL: Trigger role check if needed
        if (_roleBasedScreen == null && !_isCheckingRole) {
          debugPrint('🟢 No role screen yet, scheduling role check');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            debugPrint('🟢 PostFrameCallback: Calling _checkRoleIfNeeded()');
            _checkRoleIfNeeded();
          });
        }
        
        // If we have a cached screen, return it
        if (_roleBasedScreen != null) {
          debugPrint('🟢 Returning cached role screen: ${_roleBasedScreen.runtimeType}');
          return _roleBasedScreen!;
        }
        
        // Show loading while checking role
        debugPrint('🟢 Showing loading (checking: $_isCheckingRole, screen: ${_roleBasedScreen != null})');
        return const Scaffold(
          backgroundColor: Color(0xFF140A33),
          body: Center(
            child: CircularProgressIndicator(
              color: Color(0xFFD4AF37),
            ),
          ),
        );
    }
  }
}
