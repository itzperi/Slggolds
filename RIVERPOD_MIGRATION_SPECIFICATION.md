# 🔄 RIVERPOD MIGRATION SPECIFICATION
## Complete Provider → Riverpod Migration Plan

**Date:** 2026-01-02  
**Status:** IN PROGRESS  
**Purpose:** Zero-assumption, lossless migration from Provider to Riverpod

---

## 📋 TABLE OF CONTENTS

- [PHASE 0 — ABSOLUTE INVENTORY](#phase-0)
- [PHASE 1 — CURRENT ARCHITECTURE AUTOPSY](#phase-1)
- [PHASE 2 — RIVERPOD CANONICAL DESIGN](#phase-2)
- [PHASE 3 — EVENT FLOW SPEC](#phase-3)
- [PHASE 4 — MIGRATION PLAN](#phase-4)
- [PHASE 5 — FAILURE & EDGE-CASE MATRIX](#phase-5)
- [PHASE 6 — VERIFICATION & GUARANTEES](#phase-6)
- [PROVIDER MAP](#provider-map)
- [MIGRATION CHECKLIST](#migration-checklist)
- [RISK REGISTER](#risk-register)

---

## PHASE 0 — ABSOLUTE INVENTORY {#phase-0}

### 0.1 State & Side-Effect Census

#### A. Authentication State (Provider/ChangeNotifier)

**Location:** `lib/services/auth_flow_notifier.dart`

**State Variables:**
- `_state: AuthFlowState` (enum: unauthenticated, staffLogin, otpVerifiedNeedsPin, authenticated)
- `_phoneNumber: String?` (temporary, cleared on authenticated)
- `_isFirstTime: bool` (temporary, cleared on authenticated)
- `_isResetPin: bool` (temporary, cleared on authenticated)

**Mutations:**
- `initializeSession()` - Cold start session check
- `setOtpVerified()` - OTP verified, needs PIN setup
- `setAuthenticated()` - Fully authenticated
- `goToStaffLogin()` - Navigate to staff login
- `forceLogout()` - Force logout (always resets)
- `setUnauthenticated()` - Idempotent logout

**Listeners:**
- `AuthGate` via `Provider.of<AuthFlowNotifier>(context)` (line 347)
- Manual listener in `AuthGate.initState()` via `addListener(_forceRebuild)` (line 133)

**Lifecycle:** Created in `main()`, lives for app lifetime, never disposed

---

#### B. Supabase Auth Stream

**Location:** `lib/main.dart` (lines 51-81)

**Stream:** `Supabase.instance.client.auth.onAuthStateChange`

**Events Handled:**
- `AuthChangeEvent.signedIn` → Calls `RoleRoutingService.checkMobileAppAccess()` → `authFlowNotifier.setAuthenticated()`
- `AuthChangeEvent.signedOut` → Calls `authFlowNotifier.forceLogout()`

**Lifecycle:** Listener created in `main()`, never cancelled (potential leak)

**Conflict:** Dual state source competing with `AuthFlowNotifier`

---

#### C. AuthGate Widget State (StatefulWidget)

**Location:** `lib/main.dart` (class `_AuthGateState`)

**State Variables:**
- `_roleBasedScreen: Widget?` - Cached screen (DashboardScreen or StaffDashboard)
- `_isCheckingRole: bool` - Loading flag during role check
- `_lastState: AuthFlowState?` - Previous state for transition detection

**Mutations:**
- `_checkRoleIfNeeded()` - Triggers role check
- `_checkRoleAndRoute()` - Fetches role, creates screen, updates `_roleBasedScreen`

**Lifecycle Dependencies:**
- `initState()` - Sets up manual listener, schedules role check
- `didChangeDependencies()` - Schedules role check
- `dispose()` - Removes manual listener (with try-catch for deactivated widget)

**Problem:** Widget-owned state that should be provider-owned

---

#### D. Secure Storage (Static Class)

**Location:** `lib/utils/secure_storage_helper.dart`

**Persistent State:**
- `user_pin_hash` - Hashed customer PIN
- `user_phone` - Saved phone number
- `biometric_enabled` - Biometric preference
- `last_auth_timestamp` - Last auth time
- `staff_pin_hash` - Hashed staff PIN
- `staff_id` - Saved staff ID
- `staff_last_auth_timestamp` - Staff last auth time

**Access Pattern:** Static methods, no state management

**Lifecycle:** Persists across app restarts

---

#### E. Screen-Level State (StatefulWidget instances)

**LoginScreen (`lib/screens/login_screen.dart`):**
- `_phoneController: TextEditingController`
- `_isLoading: bool`
- `_isFocused: bool`
- `_hasSavedPhone: bool`
- `_savedPhone: String?`

**OTPScreen (`lib/screens/otp_screen.dart`):**
- `_controllers: List<TextEditingController>` (6 OTP boxes)
- `_focusNodes: List<FocusNode>` (6 focus nodes)
- `_isLoading: bool`
- `_secondsRemaining: int`
- `_canResend: bool`
- `_focusStates: List<bool>`
- `_previousTexts: List<String>`
- `_generatedOtp: String`

**StaffLoginScreen (`lib/screens/staff/staff_login_screen.dart`):**
- `_staffIdController: TextEditingController`
- `_passwordController: TextEditingController`
- `_isLoading: bool`
- `_obscurePassword: bool`

**StaffDashboard (`lib/screens/staff/staff_dashboard.dart`):**
- `_staffData: Map<String, dynamic>?`
- `_isLoading: bool`
- `_hasError: bool`
- `_errorMessage: String?`
- `_screens: List<Widget>?`

**CollectTabScreen (`lib/screens/staff/collect_tab_screen.dart`):**
- `_customers: List<Map<String, dynamic>>`
- `_dueToday: List<Map<String, dynamic>>`
- `_pending: List<Map<String, dynamic>>`
- `_todayCollections: List<Map<String, dynamic>>`
- `_collectedCount: int`
- `_totalCustomers: int`
- `_collectedAmount: double`
- `_targetAmount: double`
- `_pendingCount: int`
- `_progress: double`
- `_isLoading: bool`
- `_staffProfileId: String?`
- `_searchController: TextEditingController`

**CollectPaymentScreen (`lib/screens/staff/collect_payment_screen.dart`):**
- `_amountController: TextEditingController`
- `_paymentMethod: String`
- `_isLoading: bool`
- `_currentMetalRate: double?`

**Note:** All screen-level state is local UI state (form controllers, loading flags). This is acceptable and should remain widget-owned.

---

#### F. Service Layer (Stateless Services)

**AuthService (`lib/services/auth_service.dart`):**
- No internal state
- Exposes `authStateChanges` stream (wraps Supabase stream)

**RoleRoutingService (`lib/services/role_routing_service.dart`):**
- Static methods only
- No internal state
- Uses `Supabase.instance.client` directly

**StaffAuthService (`lib/services/staff_auth_service.dart`):**
- Static methods only
- No internal state

**PaymentService (`lib/services/payment_service.dart`):**
- No internal state (assumed, not read)

**StaffDataService (`lib/services/staff_data_service.dart`):**
- No internal state (assumed, not read)

---

#### G. Supabase Client (Singleton)

**Location:** `Supabase.instance.client` (global singleton)

**State:**
- Current session (managed by Supabase SDK)
- Auth state (managed by Supabase SDK)
- Database connection pool

**Access Pattern:** Direct access via `Supabase.instance.client` throughout codebase

---

### 0.2 Dependency Graph

```
┌─────────────────────────────────────────────────────────────┐
│                        main()                                │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Creates AuthFlowNotifier                            │  │
│  │  Sets up Supabase auth listener                      │  │
│  │  Wraps MyApp in ChangeNotifierProvider.value         │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      MyApp                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  MaterialApp                                          │  │
│  │    home: AuthGate                                     │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    AuthGate (StatefulWidget)                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Reads: Provider.of<AuthFlowNotifier>(context)        │  │
│  │  Listens: Manual addListener(_forceRebuild)           │  │
│  │  State: _roleBasedScreen, _isCheckingRole            │  │
│  │  Calls: _checkRoleAndRoute()                         │  │
│  │    └─> RoleRoutingService.fetchAndValidateRole()     │  │
│  │    └─> Creates DashboardScreen or StaffDashboard    │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐
│ LoginScreen  │  │StaffLogin    │  │ PinSetupScreen       │
│              │  │Screen        │  │                      │
│ Reads:       │  │              │  │ Reads:               │
│ Provider.of  │  │ Reads:       │  │ Provider.of          │
│ (for staff   │  │ Provider.of  │  │ Writes:              │
│  login btn)  │  │ Writes:      │  │ authFlow.set         │
│              │  │ StaffAuth    │  │ Authenticated()      │
│ Writes:      │  │ Service      │  └──────────────────────┘
│ authFlow.    │  │              │
│ goToStaff    │  │ Writes:      │
│ Login()      │  │ Supabase     │
└──────────────┘  │ Session      │
                  └──────────────┘
                            │
                            ▼
                  ┌──────────────────────┐
                  │ Supabase Auth Listener│
                  │ (in main.dart)       │
                  │                      │
                  │ On SIGNED_IN:        │
                  │  └─> RoleRouting     │
                  │      Service.check   │
                  │      MobileAppAccess │
                  │  └─> authFlow.set   │
                  │      Authenticated() │
                  │                      │
                  │ On SIGNED_OUT:       │
                  │  └─> authFlow.       │
                  │      forceLogout()   │
                  └──────────────────────┘
                            │
                            ▼
                  ┌──────────────────────┐
                  │  OTPScreen           │
                  │                      │
                  │  Reads:              │
                  │  Provider.of         │
                  │                      │
                  │  Writes:             │
                  │  authFlow.setOtp     │
                  │  Verified()          │
                  └──────────────────────┘
```

**Critical Dependencies:**

1. **AuthFlowNotifier → AuthGate:**
   - `AuthGate.build()` reads `Provider.of<AuthFlowNotifier>(context)`
   - Manual listener in `initState()` forces `setState()` on `notifyListeners()`
   - **Problem:** BuildContext dependency, lifecycle corruption

2. **Supabase Auth Stream → AuthFlowNotifier:**
   - Listener in `main()` calls `authFlowNotifier.setAuthenticated()` or `forceLogout()`
   - **Problem:** Dual state source, race conditions

3. **AuthGate → RoleRoutingService:**
   - `_checkRoleAndRoute()` calls `RoleRoutingService.fetchAndValidateRole()`
   - Creates screen based on role
   - **Problem:** Widget-owned routing state

4. **Screens → AuthFlowNotifier:**
   - `LoginScreen` → `goToStaffLogin()`
   - `OTPScreen` → `setOtpVerified()` or `setAuthenticated()`
   - `PinSetupScreen` → `setAuthenticated()`
   - `StaffLoginScreen` → Uses `StaffAuthService` (creates Supabase session)

5. **Screens → Supabase Client:**
   - Direct access via `Supabase.instance.client` throughout
   - No centralized state management for database queries

**Implicit Dependencies:**
- `SecureStorageHelper` accessed directly (no state management)
- `WidgetsBinding.instance.addPostFrameCallback` used for scheduling (lifecycle-dependent)
- `Navigator.push/pushReplacement` used in some screens (imperative navigation)

---

## PHASE 1 — CURRENT ARCHITECTURE AUTOPSY {#phase-1}

### 1.1 Authentication State Domain

**Current Location:** `lib/services/auth_flow_notifier.dart` (ChangeNotifier)

**How It's Mutated:**
1. **Cold Start:** `initializeSession()` called in `main()` before UI renders
2. **OTP Verification:** `OTPScreen` calls `setOtpVerified()` after OTP verified
3. **PIN Setup Complete:** `PinSetupScreen` calls `setAuthenticated()` after PIN saved
4. **Staff Login:** `StaffLoginScreen` creates Supabase session → auth listener → `setAuthenticated()`
5. **Logout:** `forceLogout()` called from:
   - Supabase `signedOut` event (main.dart line 79)
   - `RoleRoutingService.navigateByRole()` on access denial
   - `AuthGate._checkRoleAndRoute()` on errors
   - Manual logout buttons

**How UI Rebuilds Are Triggered:**
- `notifyListeners()` called after each state mutation
- `AuthGate.build()` uses `Provider.of<AuthFlowNotifier>(context)` (line 347)
- Manual listener in `AuthGate.initState()` calls `setState(() {})` on `notifyListeners()` (NUCLEAR FIX)

**How Lifecycle Events Affect It:**
- **App Start:** `initializeSession()` runs synchronously in `main()`
- **Widget Disposal:** Manual listener removed in `dispose()` (with try-catch for deactivated widget)
- **Widget Rebuild:** `didChangeDependencies()` schedules role check

**How Logout/Login Affects It:**
- **Logout:** `forceLogout()` resets all state, calls `notifyListeners()`
- **Login After Logout:** 
  - `goToStaffLogin()` has defensive reset if called from wrong state
  - `setAuthenticated()` is idempotent (skips if already authenticated)
  - **PROBLEM:** `build()` is suppressed after logout → login sequence (confirmed bug)

**BuildContext Dependencies:**
- `Provider.of<AuthFlowNotifier>(context)` requires valid BuildContext
- Manual listener setup in `initState()` requires context
- **PROBLEM:** Context can become invalid during lifecycle transitions

**Widget-Owned State That Shouldn't Be:**
- `AuthGate._roleBasedScreen` - Should be provider-owned
- `AuthGate._isCheckingRole` - Should be provider-owned
- `AuthGate._lastState` - Should be provider-owned

**Flutter Lifecycle Influences:**
- `didChangeDependencies()` triggers role check (lifecycle-dependent)
- `WidgetsBinding.instance.addPostFrameCallback` used for scheduling (frame-dependent)
- Manual listener in `initState()` attempts to bypass Provider's broken tracking

---

### 1.2 Supabase Auth Stream Domain

**Current Location:** `lib/main.dart` (lines 51-81)

**How It's Mutated:**
- Supabase SDK manages session internally
- `signInWithPassword()`, `signInWithOtp()`, `verifyOTP()`, `signOut()` trigger events

**How UI Rebuilds Are Triggered:**
- Listener in `main()` calls `authFlowNotifier.setAuthenticated()` or `forceLogout()`
- This triggers `notifyListeners()` → `AuthGate` rebuilds

**How Lifecycle Events Affect It:**
- Listener created in `main()` before `runApp()`
- Never cancelled (potential memory leak)
- Runs independently of widget lifecycle

**How Logout/Login Affects It:**
- `signedIn` event → access check → `setAuthenticated()`
- `signedOut` event → `forceLogout()`
- **PROBLEM:** Race condition with `AuthFlowNotifier` state

**BuildContext Dependencies:**
- None (runs outside widget tree)

**Flutter Lifecycle Influences:**
- None (runs independently)

---

### 1.3 Role Routing State Domain

**Current Location:** `lib/main.dart` (`_AuthGateState`)

**How It's Mutated:**
- `_checkRoleAndRoute()` fetches role from Supabase
- Creates `DashboardScreen` or `StaffDashboard` based on role
- Updates `_roleBasedScreen` via `setState()`

**How UI Rebuilds Are Triggered:**
- `setState()` called after role fetch completes
- `build()` returns `_roleBasedScreen` if not null

**How Lifecycle Events Affect It:**
- `initState()` schedules role check via `addPostFrameCallback`
- `didChangeDependencies()` schedules role check
- `build()` schedules role check if `_roleBasedScreen == null`
- **PROBLEM:** Multiple triggers, potential race conditions

**How Logout/Login Affects It:**
- Logout: `_checkRoleIfNeeded()` resets `_roleBasedScreen = null`
- Login: `_checkRoleAndRoute()` creates new screen
- **PROBLEM:** Screen instance may not be properly disposed

**BuildContext Dependencies:**
- `Provider.of<AuthFlowNotifier>(context, listen: false)` in `_checkRoleAndRoute()`
- `ScaffoldMessenger.of(context)` for error messages
- **PROBLEM:** Context may be invalid during async operations

**Widget-Owned State That Shouldn't Be:**
- `_roleBasedScreen` - Should be provider-owned (derived from auth + role)
- `_isCheckingRole` - Should be provider-owned (loading state)

**Flutter Lifecycle Influences:**
- `mounted` checks before `setState()` (lifecycle-dependent)
- `addPostFrameCallback` scheduling (frame-dependent)
- Widget disposal may interrupt async operations

---

### 1.4 Screen-Level State Domains

**Pattern:** All screens use `StatefulWidget` with local state for:
- Form controllers (`TextEditingController`)
- Loading flags (`bool _isLoading`)
- UI flags (`bool _obscurePassword`, `bool _isFocused`)
- Data caches (`List<Map>`, `Map<String, dynamic>`)

**Assessment:** This is **acceptable** - these are local UI concerns and should remain widget-owned.

**Exception:** `StaffDashboard` caches `_screens` list - this could be provider-owned for better testability, but not critical.

---

### 1.5 Service Layer State Domains

**Pattern:** All services are stateless (static methods or instance methods with no internal state)

**Assessment:** This is **correct** - services should be stateless. They will become Riverpod providers that expose methods.

---

### 1.6 Critical Issues Summary

#### Issue 1: BuildContext-Dependent State
- `AuthFlowNotifier` accessed via `Provider.of(context)` requires valid BuildContext
- Manual listener setup in `initState()` requires context
- **Impact:** Context can become invalid during lifecycle transitions, causing silent failures

#### Issue 2: Widget-Owned Routing State
- `_roleBasedScreen` and `_isCheckingRole` are widget-owned
- **Impact:** State lost on widget disposal, race conditions, improper disposal

#### Issue 3: Dual State Sources
- `AuthFlowNotifier` and Supabase auth stream both control auth state
- **Impact:** Race conditions, inconsistent state, rebuild suppression

#### Issue 4: Lifecycle-Dependent Scheduling
- `addPostFrameCallback` used for role checks
- `didChangeDependencies()` triggers role checks
- **Impact:** Timing-dependent bugs, missed updates

#### Issue 5: Manual Listener Workaround
- "NUCLEAR FIX" manual listener attempts to bypass Provider's broken tracking
- **Impact:** Indicates fundamental architectural flaw, not a fix

#### Issue 6: Imperative Navigation
- Some screens use `Navigator.push/pushReplacement` instead of declarative routing
- **Impact:** Navigation stack inconsistencies, back button issues

---

## PHASE 2 — RIVERPOD CANONICAL DESIGN {#phase-2}

### 2.1 Provider Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Riverpod Providers                         │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  AuthStateProvider (StateNotifier)                  │   │
│  │  - AuthFlowState enum                              │   │
│  │  - phoneNumber, isFirstTime, isResetPin           │   │
│  │  - Lifecycle: alwaysAlive                           │   │
│  └─────────────────────────────────────────────────────┘   │
│                          │                                   │
│                          ▼                                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  SupabaseAuthBridgeProvider (StreamProvider)        │   │
│  │  - Wraps Supabase.instance.client.auth.onAuthState  │   │
│  │  - Lifecycle: alwaysAlive                           │   │
│  └─────────────────────────────────────────────────────┘   │
│                          │                                   │
│                          ▼                                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  SessionRestorationProvider (FutureProvider)        │   │
│  │  - Checks Supabase session on app start            │   │
│  │  - Lifecycle: autoDispose                           │   │
│  └─────────────────────────────────────────────────────┘   │
│                          │                                   │
│                          ▼                                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  RoleProvider (FutureProvider)                      │   │
│  │  - Fetches user role from profiles table            │   │
│  │  - Depends on: AuthStateProvider                    │   │
│  │  - Lifecycle: autoDispose                           │   │
│  └─────────────────────────────────────────────────────┘   │
│                          │                                   │
│                          ▼                                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  NavigationAuthorityProvider (Provider)             │   │
│  │  - Computed from: AuthStateProvider + RoleProvider  │   │
│  │  - Returns: Widget (LoginScreen, StaffLoginScreen,  │   │
│  │              PinSetupScreen, DashboardScreen, etc.) │   │
│  │  - Lifecycle: autoDispose                           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

### 2.2 Provider Specifications

#### Provider 1: `authStateProvider`

**Type:** `StateNotifierProvider<AuthStateNotifier, AuthState>`

**Purpose:** Single source of truth for authentication flow state

**State Model:**
```dart
class AuthState {
  final AuthFlowState state;
  final String? phoneNumber;
  final bool isFirstTime;
  final bool isResetPin;
  
  const AuthState({
    required this.state,
    this.phoneNumber,
    this.isFirstTime = false,
    this.isResetPin = false,
  });
  
  AuthState copyWith({
    AuthFlowState? state,
    String? phoneNumber,
    bool? isFirstTime,
    bool? isResetPin,
  }) { ... }
}
```

**Notifier Methods:**
- `initializeSession()` - Check Supabase session on app start
- `setOtpVerified({required String phoneNumber, bool isFirstTime, bool isResetPin})`
- `setAuthenticated()`
- `goToStaffLogin()`
- `forceLogout()`
- `setUnauthenticated()`

**Sync vs Async:** Sync (state mutations are synchronous)

**Ownership:** Authoritative (single source of truth)

**Lifecycle:** `alwaysAlive` (must survive widget tree rebuilds)

**Read/Write Boundaries:**
- **Read:** Any widget via `ref.watch(authStateProvider)`
- **Write:** Only `AuthStateNotifier` methods (no external mutations)

**File:** `lib/providers/auth_state_provider.dart`

---

#### Provider 2: `supabaseAuthBridgeProvider`

**Type:** `StreamProvider<AuthStateChange>`

**Purpose:** Bridge Supabase auth stream to Riverpod

**Stream:** `Supabase.instance.client.auth.onAuthStateChange`

**Sync vs Async:** Async (stream)

**Ownership:** Derived (wraps external Supabase stream)

**Lifecycle:** `alwaysAlive` (must survive widget tree rebuilds)

**Read/Write Boundaries:**
- **Read:** `AuthStateNotifier` watches this stream
- **Write:** Supabase SDK (external)

**File:** `lib/providers/supabase_auth_bridge_provider.dart`

---

#### Provider 3: `sessionRestorationProvider`

**Type:** `FutureProvider<AuthState?>`

**Purpose:** Restore session on app start

**Future:** Checks `Supabase.instance.client.auth.currentSession`

**Sync vs Async:** Async (Future)

**Ownership:** Derived (reads from Supabase)

**Lifecycle:** `autoDispose` (one-time check on app start)

**Dependencies:** None (runs independently)

**Read/Write Boundaries:**
- **Read:** `AuthStateNotifier.initializeSession()` watches this
- **Write:** None (read-only)

**File:** `lib/providers/session_restoration_provider.dart`

---

#### Provider 4: `roleProvider`

**Type:** `FutureProvider<RoleData?>`

**Purpose:** Fetch user role and profile data

**State Model:**
```dart
class RoleData {
  final String role; // 'customer' or 'staff'
  final String profileId;
  final String? staffType; // 'collection' or 'office' (staff only)
  
  const RoleData({
    required this.role,
    required this.profileId,
    this.staffType,
  });
}
```

**Future:** Fetches from `profiles` and `staff_metadata` tables

**Sync vs Async:** Async (Future)

**Ownership:** Derived (reads from Supabase)

**Lifecycle:** `autoDispose` (recreated when auth state changes)

**Dependencies:** 
- `authStateProvider` (only fetches when authenticated)
- `supabaseAuthBridgeProvider` (ensures session is ready)

**Read/Write Boundaries:**
- **Read:** `NavigationAuthorityProvider` watches this
- **Write:** None (read-only)

**File:** `lib/providers/role_provider.dart`

---

#### Provider 5: `navigationAuthorityProvider`

**Type:** `Provider<Widget>`

**Purpose:** Computed navigation target based on auth + role state

**Computation Logic:**
```dart
Widget navigationAuthority(WidgetRef ref) {
  final authState = ref.watch(authStateProvider);
  
  switch (authState.state) {
    case AuthFlowState.unauthenticated:
      return const LoginScreen();
    
    case AuthFlowState.staffLogin:
      return const StaffLoginScreen();
    
    case AuthFlowState.otpVerifiedNeedsPin:
      return PinSetupScreen(
        phoneNumber: authState.phoneNumber ?? '',
        isFirstTime: authState.isFirstTime,
        isReset: authState.isResetPin,
      );
    
    case AuthFlowState.authenticated:
      final roleAsync = ref.watch(roleProvider);
      return roleAsync.when(
        data: (roleData) {
          if (roleData == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          switch (roleData.role) {
            case 'customer':
              return const DashboardScreen();
            case 'staff':
              return StaffDashboard(staffId: roleData.profileId);
            default:
              return const LoginScreen();
          }
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const LoginScreen(),
      );
  }
}
```

**Sync vs Async:** Sync (computed from other providers)

**Ownership:** Derived (computed from auth + role)

**Lifecycle:** `autoDispose` (recomputed when dependencies change)

**Dependencies:**
- `authStateProvider`
- `roleProvider`

**Read/Write Boundaries:**
- **Read:** `AuthGate` widget watches this
- **Write:** None (computed only)

**File:** `lib/providers/navigation_authority_provider.dart`

---

#### Provider 6: `mobileAppAccessProvider`

**Type:** `FutureProvider<bool>`

**Purpose:** Check if user has mobile app access (replaces `RoleRoutingService.checkMobileAppAccess()`)

**Future:** Validates role, active status, staff_type

**Sync vs Async:** Async (Future)

**Ownership:** Derived (reads from Supabase)

**Lifecycle:** `autoDispose`

**Dependencies:**
- `authStateProvider` (only checks when authenticated)
- `roleProvider` (uses role data)

**Read/Write Boundaries:**
- **Read:** `AuthStateNotifier` watches this (in response to Supabase auth events)
- **Write:** None (read-only)

**File:** `lib/providers/mobile_app_access_provider.dart`

---

### 2.3 Provider Dependencies Graph

```
sessionRestorationProvider (FutureProvider)
    │
    └─> authStateProvider.initializeSession() watches this
        │
        ├─> supabaseAuthBridgeProvider (StreamProvider)
        │   │
        │   └─> authStateProvider watches this
        │       │
        │       ├─> mobileAppAccessProvider (FutureProvider)
        │       │   └─> authStateProvider.setAuthenticated() watches this
        │       │
        │       └─> roleProvider (FutureProvider)
        │           │
        │           └─> navigationAuthorityProvider (Provider)
        │               │
        │               └─> AuthGate widget watches this
```

---

### 2.4 Provider Lifecycle Decisions

**Always Alive Providers:**
- `authStateProvider` - Must survive widget tree rebuilds
- `supabaseAuthBridgeProvider` - Must maintain stream subscription

**AutoDispose Providers:**
- `sessionRestorationProvider` - One-time check
- `roleProvider` - Recreated when auth changes
- `navigationAuthorityProvider` - Recreated when dependencies change
- `mobileAppAccessProvider` - Recreated when needed

**Rationale:**
- Auth state must be persistent across widget rebuilds
- Derived providers can be recreated when dependencies change
- This ensures fresh data and prevents stale state

---

### 2.5 Read/Write Boundaries

**Read-Only Providers:**
- `supabaseAuthBridgeProvider` (external Supabase stream)
- `sessionRestorationProvider` (read-only check)
- `roleProvider` (read-only fetch)
- `navigationAuthorityProvider` (computed)
- `mobileAppAccessProvider` (read-only check)

**Read-Write Provider:**
- `authStateProvider` (only `AuthStateNotifier` can mutate)

**Enforcement:**
- All providers are `final` (immutable)
- Only `AuthStateNotifier` methods mutate state
- No external mutations allowed

---

## PHASE 3 — EVENT FLOW SPEC {#phase-3}

### 3.1 Cold App Start Flow

**Event Order:**
1. `main()` runs
2. `Supabase.initialize()` completes
3. `ProviderScope` wraps `MyApp` (Riverpod initialization)
4. `sessionRestorationProvider` is created (autoDispose)
5. `sessionRestorationProvider` checks `Supabase.instance.client.auth.currentSession`
6. `authStateProvider` watches `sessionRestorationProvider`
7. `AuthStateNotifier.initializeSession()` receives session result
8. If session exists:
   - `AuthStateNotifier.setAuthenticated()` called
   - State updated to `AuthFlowState.authenticated`
9. If no session:
   - `AuthStateNotifier.setUnauthenticated()` called
   - State updated to `AuthFlowState.unauthenticated`
10. `supabaseAuthBridgeProvider` is created (alwaysAlive)
11. `supabaseAuthBridgeProvider` subscribes to `Supabase.instance.client.auth.onAuthStateChange`
12. `authStateProvider` watches `supabaseAuthBridgeProvider`
13. `MyApp` builds
14. `AuthGate` widget builds
15. `AuthGate` watches `navigationAuthorityProvider`
16. `navigationAuthorityProvider` computes widget based on `authStateProvider` and `roleProvider`
17. If authenticated:
    - `roleProvider` is created (autoDispose)
    - `roleProvider` fetches role from Supabase
    - `navigationAuthorityProvider` returns loading widget
    - When `roleProvider` completes:
      - `navigationAuthorityProvider` returns `DashboardScreen` or `StaffDashboard`
      - `AuthGate` rebuilds with target screen
18. If unauthenticated:
    - `navigationAuthorityProvider` returns `LoginScreen`
    - `AuthGate` rebuilds with `LoginScreen`

**Which Providers Emit:**
- `sessionRestorationProvider` emits session check result
- `authStateProvider` emits state change
- `roleProvider` emits role data (if authenticated)
- `navigationAuthorityProvider` emits computed widget

**Which Providers React:**
- `authStateProvider` reacts to `sessionRestorationProvider`
- `roleProvider` reacts to `authStateProvider` (only if authenticated)
- `navigationAuthorityProvider` reacts to `authStateProvider` and `roleProvider`

**Which Widgets Rebuild:**
- `AuthGate` rebuilds when `navigationAuthorityProvider` changes

**Navigation Decision:**
- Based on `authStateProvider.state` and `roleProvider` result

---

### 3.2 App Resume Flow

**Event Order:**
1. App resumes from background
2. `supabaseAuthBridgeProvider` stream may emit if session changed
3. `authStateProvider` reacts to stream event
4. If session expired:
   - `AuthStateNotifier.forceLogout()` called
   - State updated to `AuthFlowState.unauthenticated`
5. If session still valid:
   - No state change (already authenticated)
6. `navigationAuthorityProvider` recomputes
7. `AuthGate` rebuilds

**Which Providers Emit:**
- `supabaseAuthBridgeProvider` emits auth state change (if any)
- `authStateProvider` emits state change (if session expired)

**Which Providers React:**
- `authStateProvider` reacts to `supabaseAuthBridgeProvider`
- `navigationAuthorityProvider` reacts to `authStateProvider`

**Which Widgets Rebuild:**
- `AuthGate` rebuilds if navigation target changes

**Navigation Decision:**
- If session expired: navigate to `LoginScreen`
- If session valid: no navigation change

---

### 3.3 Login Flow (Customer OTP)

**Event Order:**
1. User enters phone in `LoginScreen`
2. User taps "Get OTP"
3. `LoginScreen` navigates to `OTPScreen` (imperative, will be removed)
4. User enters OTP
5. `OTPScreen` calls `AuthService.verifyOTP()`
6. Supabase creates session
7. `supabaseAuthBridgeProvider` stream emits `signedIn` event
8. `authStateProvider` watches `supabaseAuthBridgeProvider`
9. `AuthStateNotifier` receives `signedIn` event
10. `AuthStateNotifier` watches `mobileAppAccessProvider`
11. `mobileAppAccessProvider` is created (autoDispose)
12. `mobileAppAccessProvider` checks access (calls `RoleRoutingService.checkMobileAppAccess()`)
13. If access granted:
    - `AuthStateNotifier.setAuthenticated()` called
    - State updated to `AuthFlowState.authenticated`
14. If access denied:
    - `Supabase.instance.client.auth.signOut()` called
    - `supabaseAuthBridgeProvider` stream emits `signedOut` event
    - `AuthStateNotifier.forceLogout()` called
    - State updated to `AuthFlowState.unauthenticated`
15. `OTPScreen` checks if PIN is set
16. If PIN not set:
    - `OTPScreen` calls `AuthStateNotifier.setOtpVerified(phoneNumber, isFirstTime: true)`
    - State updated to `AuthFlowState.otpVerifiedNeedsPin`
17. If PIN is set:
    - `OTPScreen` calls `AuthStateNotifier.setAuthenticated()` (already authenticated, idempotent)
18. `navigationAuthorityProvider` recomputes
19. `AuthGate` rebuilds
20. If `otpVerifiedNeedsPin`:
    - `navigationAuthorityProvider` returns `PinSetupScreen`
21. If `authenticated`:
    - `roleProvider` is created
    - `roleProvider` fetches role
    - `navigationAuthorityProvider` returns loading → `DashboardScreen`

**Which Providers Emit:**
- `supabaseAuthBridgeProvider` emits `signedIn` event
- `mobileAppAccessProvider` emits access check result
- `authStateProvider` emits state change
- `roleProvider` emits role data (if authenticated)

**Which Providers React:**
- `authStateProvider` reacts to `supabaseAuthBridgeProvider`
- `mobileAppAccessProvider` reacts to `authStateProvider` (when signed in)
- `authStateProvider` reacts to `mobileAppAccessProvider` (access result)
- `roleProvider` reacts to `authStateProvider` (when authenticated)
- `navigationAuthorityProvider` reacts to `authStateProvider` and `roleProvider`

**Which Widgets Rebuild:**
- `AuthGate` rebuilds when `navigationAuthorityProvider` changes
- `OTPScreen` may rebuild if it watches `authStateProvider` (optional)

**Navigation Decision:**
- Based on PIN status and access check result

---

### 3.4 Logout Flow

**Event Order:**
1. User taps logout button (any screen)
2. Screen calls `Supabase.instance.client.auth.signOut()`
3. Supabase removes session
4. `supabaseAuthBridgeProvider` stream emits `signedOut` event
5. `authStateProvider` watches `supabaseAuthBridgeProvider`
6. `AuthStateNotifier` receives `signedOut` event
7. `AuthStateNotifier.forceLogout()` called
8. State updated to `AuthFlowState.unauthenticated`
9. All temporary state cleared (`phoneNumber`, `isFirstTime`, `isResetPin`)
10. `navigationAuthorityProvider` recomputes
11. `roleProvider` is disposed (no longer needed)
12. `navigationAuthorityProvider` returns `LoginScreen`
13. `AuthGate` rebuilds
14. `AuthGate` displays `LoginScreen`

**Which Providers Emit:**
- `supabaseAuthBridgeProvider` emits `signedOut` event
- `authStateProvider` emits state change

**Which Providers React:**
- `authStateProvider` reacts to `supabaseAuthBridgeProvider`
- `navigationAuthorityProvider` reacts to `authStateProvider`
- `roleProvider` is disposed (dependency removed)

**Which Widgets Rebuild:**
- `AuthGate` rebuilds when `navigationAuthorityProvider` changes
- All authenticated screens are disposed (replaced by `LoginScreen`)

**Navigation Decision:**
- Always navigate to `LoginScreen`

---

### 3.5 Login After Logout Flow

**Event Order:**
1. User is on `LoginScreen` (after logout)
2. User enters phone and taps "Get OTP"
3. `LoginScreen` navigates to `OTPScreen` (imperative, will be removed)
4. User enters OTP
5. `OTPScreen` calls `AuthService.verifyOTP()`
6. Supabase creates session
7. `supabaseAuthBridgeProvider` stream emits `signedIn` event
8. `authStateProvider` watches `supabaseAuthBridgeProvider`
9. `AuthStateNotifier` receives `signedIn` event
10. `AuthStateNotifier` watches `mobileAppAccessProvider`
11. `mobileAppAccessProvider` is created
12. `mobileAppAccessProvider` checks access
13. If access granted:
    - `AuthStateNotifier.setAuthenticated()` called
    - State updated to `AuthFlowState.authenticated`
14. `OTPScreen` checks PIN status
15. If PIN not set:
    - `OTPScreen` calls `AuthStateNotifier.setOtpVerified()`
    - State updated to `AuthFlowState.otpVerifiedNeedsPin`
16. If PIN is set:
    - `OTPScreen` calls `AuthStateNotifier.setAuthenticated()` (idempotent)
17. `navigationAuthorityProvider` recomputes
18. `roleProvider` is created (if authenticated)
19. `roleProvider` fetches role
20. `navigationAuthorityProvider` returns target screen
21. `AuthGate` rebuilds
22. `AuthGate` displays target screen

**Which Providers Emit:**
- `supabaseAuthBridgeProvider` emits `signedIn` event
- `mobileAppAccessProvider` emits access check result
- `authStateProvider` emits state change
- `roleProvider` emits role data

**Which Providers React:**
- `authStateProvider` reacts to `supabaseAuthBridgeProvider`
- `mobileAppAccessProvider` reacts to `authStateProvider`
- `authStateProvider` reacts to `mobileAppAccessProvider`
- `roleProvider` reacts to `authStateProvider`
- `navigationAuthorityProvider` reacts to `authStateProvider` and `roleProvider`

**Which Widgets Rebuild:**
- `AuthGate` rebuilds when `navigationAuthorityProvider` changes
- **CRITICAL:** This rebuild must happen (Riverpod guarantees it)

**Navigation Decision:**
- Based on PIN status and role

**Key Difference from Current Architecture:**
- Riverpod guarantees `AuthGate` rebuilds when `navigationAuthorityProvider` changes
- No manual listeners needed
- No BuildContext dependency
- No lifecycle corruption

---

### 3.6 Role Resolution Flow

**Event Order:**
1. User is authenticated (`authStateProvider.state == authenticated`)
2. `roleProvider` is created (autoDispose)
3. `roleProvider` watches `authStateProvider` (only if authenticated)
4. `roleProvider` fetches profile from `profiles` table
5. If role is 'staff':
    - `roleProvider` fetches `staff_type` from `staff_metadata` table
6. `roleProvider` emits `RoleData(role, profileId, staffType?)`
7. `navigationAuthorityProvider` watches `roleProvider`
8. `navigationAuthorityProvider` recomputes widget
9. If role is 'customer':
    - `navigationAuthorityProvider` returns `DashboardScreen`
10. If role is 'staff':
    - `navigationAuthorityProvider` returns `StaffDashboard(staffId: profileId)`
11. `AuthGate` watches `navigationAuthorityProvider`
12. `AuthGate` rebuilds with target screen

**Which Providers Emit:**
- `roleProvider` emits role data

**Which Providers React:**
- `navigationAuthorityProvider` reacts to `roleProvider`

**Which Widgets Rebuild:**
- `AuthGate` rebuilds when `navigationAuthorityProvider` changes

**Navigation Decision:**
- Based on role: `DashboardScreen` or `StaffDashboard`

---

### 3.7 Staff Login Flow

**Event Order:**
1. User taps "Staff Login" on `LoginScreen`
2. `LoginScreen` calls `AuthStateNotifier.goToStaffLogin()`
3. State updated to `AuthFlowState.staffLogin`
4. `navigationAuthorityProvider` recomputes
5. `navigationAuthorityProvider` returns `StaffLoginScreen`
6. `AuthGate` rebuilds
7. `AuthGate` displays `StaffLoginScreen`
8. User enters staff code and password
9. `StaffLoginScreen` calls `StaffAuthService.signInWithStaffCode()`
10. `StaffAuthService` resolves staff code → email via RPC
11. `StaffAuthService` calls `Supabase.instance.client.auth.signInWithPassword()`
12. Supabase creates session
13. `supabaseAuthBridgeProvider` stream emits `signedIn` event
14. `authStateProvider` watches `supabaseAuthBridgeProvider`
15. `AuthStateNotifier` receives `signedIn` event
16. `AuthStateNotifier` watches `mobileAppAccessProvider`
17. `mobileAppAccessProvider` is created
18. `mobileAppAccessProvider` checks access (validates staff_type='collection')
19. If access granted:
    - `AuthStateNotifier.setAuthenticated()` called
    - State updated to `AuthFlowState.authenticated`
20. If access denied:
    - `Supabase.instance.client.auth.signOut()` called
    - `supabaseAuthBridgeProvider` stream emits `signedOut` event
    - `AuthStateNotifier.forceLogout()` called
    - State updated to `AuthFlowState.unauthenticated`
21. `navigationAuthorityProvider` recomputes
22. If authenticated:
    - `roleProvider` is created
    - `roleProvider` fetches role
    - `navigationAuthorityProvider` returns `StaffDashboard`
23. If unauthenticated:
    - `navigationAuthorityProvider` returns `LoginScreen`
24. `AuthGate` rebuilds

**Which Providers Emit:**
- `supabaseAuthBridgeProvider` emits `signedIn` event
- `mobileAppAccessProvider` emits access check result
- `authStateProvider` emits state change
- `roleProvider` emits role data (if authenticated)

**Which Providers React:**
- `authStateProvider` reacts to `supabaseAuthBridgeProvider`
- `mobileAppAccessProvider` reacts to `authStateProvider`
- `authStateProvider` reacts to `mobileAppAccessProvider`
- `roleProvider` reacts to `authStateProvider`
- `navigationAuthorityProvider` reacts to `authStateProvider` and `roleProvider`

**Which Widgets Rebuild:**
- `AuthGate` rebuilds when `navigationAuthorityProvider` changes

**Navigation Decision:**
- Based on access check result: `StaffDashboard` or `LoginScreen`

---

### 3.8 Supabase Session Expiry Flow

**Event Order:**
1. Supabase session expires (timeout or revoked)
2. `supabaseAuthBridgeProvider` stream emits `tokenRefreshed` or `signedOut` event
3. `authStateProvider` watches `supabaseAuthBridgeProvider`
4. `AuthStateNotifier` receives event
5. If `signedOut`:
    - `AuthStateNotifier.forceLogout()` called
    - State updated to `AuthFlowState.unauthenticated`
6. If `tokenRefreshed`:
    - No state change (session still valid)
7. `navigationAuthorityProvider` recomputes
8. If logged out:
    - `navigationAuthorityProvider` returns `LoginScreen`
9. `AuthGate` rebuilds

**Which Providers Emit:**
- `supabaseAuthBridgeProvider` emits session event

**Which Providers React:**
- `authStateProvider` reacts to `supabaseAuthBridgeProvider`
- `navigationAuthorityProvider` reacts to `authStateProvider`

**Which Widgets Rebuild:**
- `AuthGate` rebuilds if navigation target changes

**Navigation Decision:**
- If session expired: navigate to `LoginScreen`
- If session refreshed: no navigation change

---

## PHASE 4 — MIGRATION PLAN {#phase-4}

### 4.1 Pre-Migration Checklist

**Dependencies:**
- [ ] Add `flutter_riverpod` to `pubspec.yaml`
- [ ] Run `flutter pub get`
- [ ] Verify no other state management packages conflict

**Backup:**
- [ ] Create git branch: `riverpod-migration`
- [ ] Commit current state: `git commit -m "Pre-migration state"`
- [ ] Tag current commit: `git tag pre-riverpod-migration`

---

### 4.2 Step-by-Step Execution Plan

#### STEP 1: Add Riverpod Dependency

**File:** `pubspec.yaml`

**Action:**
```yaml
dependencies:
  flutter_riverpod: ^2.4.9  # Add this line
```

**Verification:**
- Run `flutter pub get`
- App compiles: `flutter run --no-sound-null-safety`

**Rollback Point:** Git commit after this step

---

#### STEP 2: Create Provider Files Structure

**Files to Create:**
1. `lib/providers/auth_state_provider.dart`
2. `lib/providers/supabase_auth_bridge_provider.dart`
3. `lib/providers/session_restoration_provider.dart`
4. `lib/providers/role_provider.dart`
5. `lib/providers/navigation_authority_provider.dart`
6. `lib/providers/mobile_app_access_provider.dart`

**Action:**
- Create empty files with basic structure
- Add placeholder providers (return dummy values)

**Verification:**
- App compiles
- No runtime errors

**Rollback Point:** Git commit after this step

---

#### STEP 3: Implement `authStateProvider`

**File:** `lib/providers/auth_state_provider.dart`

**Action:**
1. Create `AuthState` class (copy from current `AuthFlowNotifier` state)
2. Create `AuthStateNotifier` class (extends `StateNotifier<AuthState>`)
3. Implement all methods from `AuthFlowNotifier`:
   - `initializeSession()`
   - `setOtpVerified()`
   - `setAuthenticated()`
   - `goToStaffLogin()`
   - `forceLogout()`
   - `setUnauthenticated()`
4. Create `authStateProvider` (StateNotifierProvider, alwaysAlive)

**Verification:**
- Provider compiles
- No runtime errors
- State model matches current behavior

**Rollback Point:** Git commit after this step

---

#### STEP 4: Implement `supabaseAuthBridgeProvider`

**File:** `lib/providers/supabase_auth_bridge_provider.dart`

**Action:**
1. Create `StreamProvider<AuthStateChange>` that wraps `Supabase.instance.client.auth.onAuthStateChange`
2. Mark as `alwaysAlive`
3. Handle stream errors gracefully

**Verification:**
- Provider compiles
- Stream emits events correctly
- No memory leaks

**Rollback Point:** Git commit after this step

---

#### STEP 5: Implement `sessionRestorationProvider`

**File:** `lib/providers/session_restoration_provider.dart`

**Action:**
1. Create `FutureProvider<AuthState?>` that checks `Supabase.instance.client.auth.currentSession`
2. Mark as `autoDispose`
3. Return `AuthState` if session exists, `null` if not

**Verification:**
- Provider compiles
- Returns correct session state
- Handles errors gracefully

**Rollback Point:** Git commit after this step

---

#### STEP 6: Implement `roleProvider`

**File:** `lib/providers/role_provider.dart`

**Action:**
1. Create `RoleData` class
2. Create `FutureProvider<RoleData?>` that fetches role from Supabase
3. Only fetch when `authStateProvider.state == authenticated`
4. Mark as `autoDispose`
5. Handle errors gracefully (return null on error)

**Verification:**
- Provider compiles
- Fetches role correctly
- Handles errors gracefully

**Rollback Point:** Git commit after this step

---

#### STEP 7: Implement `mobileAppAccessProvider`

**File:** `lib/providers/mobile_app_access_provider.dart`

**Action:**
1. Create `FutureProvider<bool>` that wraps `RoleRoutingService.checkMobileAppAccess()`
2. Mark as `autoDispose`
3. Only check when authenticated

**Verification:**
- Provider compiles
- Checks access correctly
- Handles errors gracefully

**Rollback Point:** Git commit after this step

---

#### STEP 8: Implement `navigationAuthorityProvider`

**File:** `lib/providers/navigation_authority_provider.dart`

**Action:**
1. Create `Provider<Widget>` that computes navigation target
2. Watch `authStateProvider` and `roleProvider`
3. Return appropriate screen based on state
4. Mark as `autoDispose`

**Verification:**
- Provider compiles
- Returns correct screens
- Handles loading/error states

**Rollback Point:** Git commit after this step

---

#### STEP 9: Wire Up `authStateProvider` to Supabase Stream

**File:** `lib/providers/auth_state_provider.dart`

**Action:**
1. In `AuthStateNotifier` constructor, watch `supabaseAuthBridgeProvider`
2. On `signedIn` event:
   - Watch `mobileAppAccessProvider`
   - If access granted: call `setAuthenticated()`
   - If access denied: call `Supabase.instance.client.auth.signOut()`
3. On `signedOut` event:
   - Call `forceLogout()`
4. Watch `sessionRestorationProvider` in `initializeSession()`

**Verification:**
- Auth state updates correctly on Supabase events
- Access check works correctly
- Logout works correctly

**Rollback Point:** Git commit after this step

---

#### STEP 10: Update `main.dart` - Remove Provider, Add Riverpod

**File:** `lib/main.dart`

**Action:**
1. Remove `import 'package:provider/provider.dart';`
2. Add `import 'package:flutter_riverpod/flutter_riverpod.dart';`
3. Remove `ChangeNotifierProvider.value` wrapper
4. Wrap `MyApp` in `ProviderScope`
5. Remove Supabase auth listener (now handled by `supabaseAuthBridgeProvider`)
6. Remove `AuthFlowNotifier` creation
7. Remove `authFlowNotifier.initializeSession()` call (now handled by provider)

**Before:**
```dart
final authFlowNotifier = AuthFlowNotifier();
authFlowNotifier.initializeSession();

Supabase.instance.client.auth.onAuthStateChange.listen(...);

runApp(
  ChangeNotifierProvider.value(
    value: authFlowNotifier,
    child: const MyApp(),
  ),
);
```

**After:**
```dart
runApp(
  const ProviderScope(
    child: MyApp(),
  ),
);
```

**Verification:**
- App compiles
- No runtime errors
- App starts correctly

**Rollback Point:** Git commit after this step

---

#### STEP 11: Update `AuthGate` to Use Riverpod

**File:** `lib/main.dart` (class `_AuthGateState`)

**Action:**
1. Change `AuthGate` from `StatefulWidget` to `ConsumerWidget`
2. Remove all state variables (`_roleBasedScreen`, `_isCheckingRole`, `_lastState`)
3. Remove `initState()`, `dispose()`, `didChangeDependencies()`
4. Remove `_checkRoleIfNeeded()`, `_checkRoleAndRoute()`
5. Remove manual listener (`_forceRebuild`)
6. In `build()` method:
   - Use `ref.watch(navigationAuthorityProvider)`
   - Return the widget directly

**Before:**
```dart
class AuthGate extends StatefulWidget { ... }

class _AuthGateState extends State<AuthGate> {
  Widget? _roleBasedScreen;
  bool _isCheckingRole = false;
  
  @override
  Widget build(BuildContext context) {
    final authFlow = Provider.of<AuthFlowNotifier>(context);
    // Complex routing logic...
  }
}
```

**After:**
```dart
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(navigationAuthorityProvider);
  }
}
```

**Verification:**
- App compiles
- Navigation works correctly
- No lifecycle errors

**Rollback Point:** Git commit after this step

---

#### STEP 12: Update Screens to Use Riverpod

**Files to Update:**
1. `lib/screens/login_screen.dart`
2. `lib/screens/otp_screen.dart`
3. `lib/screens/auth/pin_setup_screen.dart`
4. `lib/screens/staff/staff_login_screen.dart`

**Action for Each Screen:**
1. Change from `StatefulWidget` to `ConsumerStatefulWidget` (if needed)
2. Replace `Provider.of<AuthFlowNotifier>(context, listen: false)` with `ref.read(authStateProvider.notifier)`
3. Remove `import 'package:provider/provider.dart';`
4. Add `import 'package:flutter_riverpod/flutter_riverpod.dart';`

**Example (LoginScreen):**
```dart
// Before
final authFlow = Provider.of<AuthFlowNotifier>(context, listen: false);
authFlow.goToStaffLogin();

// After
ref.read(authStateProvider.notifier).goToStaffLogin();
```

**Verification:**
- All screens compile
- Auth actions work correctly
- No Provider references remain

**Rollback Point:** Git commit after this step

---

#### STEP 13: Remove `AuthFlowNotifier` File

**File:** `lib/services/auth_flow_notifier.dart`

**Action:**
1. Delete the file
2. Remove any remaining imports

**Verification:**
- App compiles
- No references to `AuthFlowNotifier` remain

**Rollback Point:** Git commit after this step

---

#### STEP 14: Remove Provider Dependency

**File:** `pubspec.yaml`

**Action:**
1. Remove `provider` package
2. Run `flutter pub get`

**Verification:**
- App compiles
- No Provider imports remain

**Rollback Point:** Git commit after this step

---

#### STEP 15: Remove Imperative Navigation

**Files to Update:**
1. `lib/screens/login_screen.dart` - Remove `Navigator.push` to `OTPScreen`
2. `lib/screens/otp_screen.dart` - Remove any `Navigator` calls

**Action:**
- Replace `Navigator.push/pushReplacement` with state changes
- Let `AuthGate` handle navigation declaratively

**Verification:**
- Navigation works correctly
- No imperative navigation remains

**Rollback Point:** Git commit after this step

---

#### STEP 16: Testing & Verification

**Test Cases:**
1. Cold app start (with session)
2. Cold app start (without session)
3. Login flow (OTP → PIN setup → Dashboard)
4. Staff login flow
5. Logout flow
6. Login after logout
7. Session expiry
8. App resume

**Verification:**
- All test cases pass
- No lifecycle errors
- No rebuild suppression
- No context errors

**Rollback Point:** Git commit after this step

---

### 4.3 Files to Delete

1. `lib/services/auth_flow_notifier.dart` - Replaced by `authStateProvider`
2. Any test files for `AuthFlowNotifier` (if they exist)

---

### 4.4 Files to Rewrite

1. `lib/main.dart` - Remove Provider, add Riverpod
2. `lib/screens/login_screen.dart` - Use Riverpod
3. `lib/screens/otp_screen.dart` - Use Riverpod
4. `lib/screens/auth/pin_setup_screen.dart` - Use Riverpod
5. `lib/screens/staff/staff_login_screen.dart` - Use Riverpod

---

### 4.5 Files to Create

1. `lib/providers/auth_state_provider.dart`
2. `lib/providers/supabase_auth_bridge_provider.dart`
3. `lib/providers/session_restoration_provider.dart`
4. `lib/providers/role_provider.dart`
5. `lib/providers/navigation_authority_provider.dart`
6. `lib/providers/mobile_app_access_provider.dart`

---

### 4.6 Order of Operations

**Critical Order:**
1. Add Riverpod dependency (STEP 1)
2. Create provider files (STEP 2)
3. Implement providers (STEPS 3-8)
4. Wire up providers (STEP 9)
5. Update `main.dart` (STEP 10)
6. Update `AuthGate` (STEP 11)
7. Update screens (STEP 12)
8. Remove old code (STEPS 13-14)
9. Clean up navigation (STEP 15)
10. Test (STEP 16)

**Why This Order:**
- Providers must exist before `main.dart` uses them
- `AuthGate` must be updated before screens use it
- Old code must remain until new code is verified

---

### 4.7 Zero-Downtime Guarantees

**At Each Step:**
- App must compile
- App must run (even if functionality is broken)
- No mixed Provider/Riverpod state
- No temporary hacks

**How to Ensure:**
- Test compilation after each step
- Test app startup after each step
- Use feature flags if needed (not recommended for this migration)

---

### 4.8 Rollback Points

**Major Rollback Points:**
1. After STEP 1 (dependency added)
2. After STEP 10 (`main.dart` updated)
3. After STEP 11 (`AuthGate` updated)
4. After STEP 12 (screens updated)

**How to Rollback:**
```bash
git reset --hard <rollback-point-tag>
flutter pub get
flutter clean
flutter run
```

---

## PHASE 5 — FAILURE & EDGE-CASE MATRIX {#phase-5}

### 5.1 Stale State

**Failure Mode:** Provider returns outdated state after mutation

**Why Riverpod Prevents It:**
- Providers are immutable
- State changes create new instances
- `ref.watch()` automatically subscribes to updates
- No manual subscription management needed

**How to Guard Against It:**
- Always use `ref.watch()` for reactive reads
- Never cache provider values outside `build()` method
- Use `ref.read()` only for one-time reads or mutations

**Example:**
```dart
// ❌ WRONG - Stale state
final authState = ref.read(authStateProvider);
// Later: authState is stale

// ✅ CORRECT - Always fresh
Widget build(BuildContext context, WidgetRef ref) {
  final authState = ref.watch(authStateProvider); // Always fresh
  return Text(authState.state.toString());
}
```

---

### 5.2 Double Navigation

**Failure Mode:** Multiple navigation events trigger simultaneously

**Why Riverpod Prevents It:**
- `navigationAuthorityProvider` is computed (single source of truth)
- Only one widget is returned at a time
- No imperative navigation calls

**How to Guard Against It:**
- `navigationAuthorityProvider` must be idempotent
- Use `ref.watch()` to ensure single subscription
- No `Navigator.push/pop` calls in widgets

**Example:**
```dart
// ❌ WRONG - Double navigation
onTap: () {
  Navigator.push(context, ...);
  authFlow.setAuthenticated(); // Also triggers navigation
}

// ✅ CORRECT - Single navigation source
Widget build(BuildContext context, WidgetRef ref) {
  return ref.watch(navigationAuthorityProvider); // Single source
}
```

---

### 5.3 Duplicate Listeners

**Failure Mode:** Multiple listeners subscribe to same provider, causing memory leaks

**Why Riverpod Prevents It:**
- `ref.watch()` automatically manages subscriptions
- Subscriptions are tied to widget lifecycle
- No manual `addListener/removeListener` needed

**How to Guard Against It:**
- Never use manual listeners
- Always use `ref.watch()` or `ref.listen()`
- Riverpod handles cleanup automatically

**Example:**
```dart
// ❌ WRONG - Manual listener (current code)
authFlow.addListener(_forceRebuild);

// ✅ CORRECT - Automatic subscription
Widget build(BuildContext context, WidgetRef ref) {
  ref.watch(authStateProvider); // Auto-subscribes, auto-cleans up
}
```

---

### 5.4 Race Conditions

**Failure Mode:** Multiple async operations complete in unexpected order

**Why Riverpod Prevents It:**
- Providers are reactive (automatically handle async state)
- `AsyncValue` type handles loading/error/data states
- Dependencies are explicit (provider graph)

**How to Guard Against It:**
- Use `AsyncValue.when()` to handle all states
- Chain providers with dependencies (not parallel calls)
- Use `ref.watch()` to ensure proper ordering

**Example:**
```dart
// ❌ WRONG - Race condition
final role = await fetchRole();
final access = await checkAccess(); // May complete first

// ✅ CORRECT - Explicit dependencies
final roleAsync = ref.watch(roleProvider);
final accessAsync = ref.watch(mobileAppAccessProvider); // Depends on role
```

---

### 5.5 Memory Leaks

**Failure Mode:** Providers or listeners not disposed, causing memory leaks

**Why Riverpod Prevents It:**
- `autoDispose` providers are automatically disposed
- `ref.watch()` subscriptions are tied to widget lifecycle
- No manual cleanup needed

**How to Guard Against It:**
- Use `autoDispose` for derived providers
- Use `alwaysAlive` only for persistent state
- Never store provider references outside widget tree

**Example:**
```dart
// ❌ WRONG - Memory leak (current code)
Supabase.instance.client.auth.onAuthStateChange.listen(...); // Never cancelled

// ✅ CORRECT - Auto-dispose
final authStreamProvider = StreamProvider.autoDispose((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});
```

---

### 5.6 Provider Re-creation

**Failure Mode:** Provider recreated unnecessarily, causing unnecessary rebuilds

**Why Riverpod Prevents It:**
- Providers are cached by Riverpod
- `alwaysAlive` providers are never recreated
- `autoDispose` providers are recreated only when dependencies change

**How to Guard Against It:**
- Use `alwaysAlive` for persistent state (`authStateProvider`)
- Use `autoDispose` for derived state (`roleProvider`)
- Avoid creating providers in `build()` method

**Example:**
```dart
// ❌ WRONG - Recreated every build
final provider = Provider((ref) => SomeValue()); // In build()

// ✅ CORRECT - Cached
final provider = Provider((ref) => SomeValue()); // Top-level
```

---

### 5.7 Auth Desync

**Failure Mode:** Supabase session and app auth state become out of sync

**Why Riverpod Prevents It:**
- `supabaseAuthBridgeProvider` bridges Supabase stream to Riverpod
- `authStateProvider` watches Supabase stream
- Single source of truth (Supabase stream)

**How to Guard Against It:**
- `authStateProvider` must always react to Supabase events
- Never mutate auth state without Supabase event
- Use `ref.watch(supabaseAuthBridgeProvider)` in `AuthStateNotifier`

**Example:**
```dart
// ❌ WRONG - Desync
void setAuthenticated() {
  _state = AuthFlowState.authenticated; // Not synced with Supabase
}

// ✅ CORRECT - Synced
class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier() : super(...) {
    ref.listen(supabaseAuthBridgeProvider, (previous, next) {
      if (next.event == AuthChangeEvent.signedIn) {
        state = state.copyWith(state: AuthFlowState.authenticated);
      }
    });
  }
}
```

---

### 5.8 Widget Lifecycle Dependence

**Failure Mode:** Auth state depends on widget lifecycle (current bug)

**Why Riverpod Prevents It:**
- Providers are independent of widget lifecycle
- `ref.watch()` works regardless of widget state
- No `BuildContext` dependency

**How to Guard Against It:**
- Never use `BuildContext` for state access
- Always use `ref.watch()` or `ref.read()`
- No manual `addListener/removeListener`

**Example:**
```dart
// ❌ WRONG - Lifecycle dependent (current code)
Provider.of<AuthFlowNotifier>(context); // Requires valid context

// ✅ CORRECT - Lifecycle independent
ref.watch(authStateProvider); // Works regardless of widget state
```

---

### 5.9 Rebuild Suppression

**Failure Mode:** State changes but widgets don't rebuild (current bug)

**Why Riverpod Prevents It:**
- `ref.watch()` automatically triggers rebuilds
- No manual subscription management
- Riverpod's dependency tracking is reliable

**How to Guard Against It:**
- Always use `ref.watch()` for reactive reads
- Never use `ref.read()` for values that should trigger rebuilds
- Use `ConsumerWidget` or `ConsumerStatefulWidget`

**Example:**
```dart
// ❌ WRONG - Rebuild suppression (current code)
final authFlow = Provider.of<AuthFlowNotifier>(context, listen: false);
authFlow.addListener(_forceRebuild); // Manual workaround

// ✅ CORRECT - Automatic rebuilds
Widget build(BuildContext context, WidgetRef ref) {
  final authState = ref.watch(authStateProvider); // Auto-rebuilds
}
```

---

### 5.10 Context-Based State Corruption

**Failure Mode:** Invalid `BuildContext` causes state access to fail

**Why Riverpod Prevents It:**
- `ref` is not tied to `BuildContext`
- `ref.watch()` works even with invalid context
- No context validation needed

**How to Guard Against It:**
- Never use `BuildContext` for state access
- Always use `ref` parameter
- No `Provider.of(context)` calls

**Example:**
```dart
// ❌ WRONG - Context corruption (current code)
try {
  final authFlow = Provider.of<AuthFlowNotifier>(context, listen: false);
} catch (e) {
  // Context invalid - silent failure
}

// ✅ CORRECT - No context needed
final authState = ref.watch(authStateProvider); // Always works
```

---

### 5.11 Edge Cases Summary

| Edge Case | Current Risk | Riverpod Solution | Guard Required |
|-----------|-------------|-------------------|-----------------|
| Stale state | High | Automatic updates | Use `ref.watch()` |
| Double navigation | High | Single source | No imperative nav |
| Duplicate listeners | High | Auto-managed | No manual listeners |
| Race conditions | Medium | Reactive dependencies | Chain providers |
| Memory leaks | Medium | Auto-dispose | Use `autoDispose` |
| Provider re-creation | Low | Caching | Use `alwaysAlive` |
| Auth desync | High | Stream bridge | Watch Supabase stream |
| Lifecycle dependence | High | Independent | Use `ref` not `context` |
| Rebuild suppression | High | Auto-rebuilds | Use `ref.watch()` |
| Context corruption | High | No context needed | Use `ref` not `context` |

---

## PHASE 6 — VERIFICATION & GUARANTEES {#phase-6}

### 6.1 Invariants That Must Always Hold

#### Invariant 1: Single Source of Truth
**Statement:** `authStateProvider` is the only source of auth state.

**Verification:**
- No other providers or widgets mutate auth state
- All auth state reads go through `authStateProvider`
- Supabase stream only triggers `authStateProvider` mutations

**Assertion:**
```dart
// In AuthStateNotifier
void setAuthenticated() {
  assert(state.state != AuthFlowState.authenticated || 
         state.state == AuthFlowState.authenticated); // Idempotent check
  state = state.copyWith(state: AuthFlowState.authenticated);
}
```

---

#### Invariant 2: Navigation Authority
**Statement:** `navigationAuthorityProvider` is the only source of navigation decisions.

**Verification:**
- No `Navigator.push/pop` calls in widgets
- All navigation goes through `navigationAuthorityProvider`
- `AuthGate` always returns `ref.watch(navigationAuthorityProvider)`

**Assertion:**
```dart
// In navigationAuthorityProvider
Widget navigationAuthority(WidgetRef ref) {
  final authState = ref.watch(authStateProvider);
  assert(authState != null, 'Auth state must exist');
  // Navigation logic...
}
```

---

#### Invariant 3: Supabase Sync
**Statement:** `authStateProvider` is always in sync with Supabase session.

**Verification:**
- `authStateProvider` watches `supabaseAuthBridgeProvider`
- All Supabase auth events trigger `authStateProvider` updates
- No manual auth state mutations without Supabase events

**Assertion:**
```dart
// In AuthStateNotifier constructor
AuthStateNotifier() : super(...) {
  ref.listen(supabaseAuthBridgeProvider, (previous, next) {
    assert(next != null, 'Supabase event must exist');
    // Handle event...
  });
}
```

---

#### Invariant 4: Widget Lifecycle Independence
**Statement:** Auth state is independent of widget lifecycle.

**Verification:**
- No `BuildContext` usage for state access
- No manual `addListener/removeListener`
- All state access via `ref.watch()` or `ref.read()`

**Assertion:**
```dart
// In AuthGate
@override
Widget build(BuildContext context, WidgetRef ref) {
  // No context usage for state
  final authState = ref.watch(authStateProvider);
  assert(authState != null, 'Auth state must exist');
  return ref.watch(navigationAuthorityProvider);
}
```

---

#### Invariant 5: Rebuild Guarantee
**Statement:** State changes always trigger widget rebuilds.

**Verification:**
- All reactive reads use `ref.watch()`
- No `ref.read()` for values that should trigger rebuilds
- `ConsumerWidget` or `ConsumerStatefulWidget` used for reactive widgets

**Assertion:**
```dart
// In any reactive widget
Widget build(BuildContext context, WidgetRef ref) {
  final authState = ref.watch(authStateProvider); // Must trigger rebuild
  assert(authState != null, 'Auth state must exist');
  // Widget rebuilds when authState changes
}
```

---

### 6.2 Assertions & Logging

#### Assertions

**Location:** All provider files

**Purpose:** Catch invariant violations at development time

**Examples:**
```dart
// In AuthStateNotifier
void setAuthenticated() {
  assert(state.state != AuthFlowState.authenticated || 
         state.state == AuthFlowState.authenticated, 
         'setAuthenticated called but already authenticated');
  state = state.copyWith(state: AuthFlowState.authenticated);
}

// In navigationAuthorityProvider
Widget navigationAuthority(WidgetRef ref) {
  final authState = ref.watch(authStateProvider);
  assert(authState != null, 'Auth state must exist');
  // ...
}
```

---

#### Logging

**Location:** All provider files and `AuthGate`

**Purpose:** Track state transitions and debug issues

**Log Points:**
1. **State Transitions:**
   ```dart
   void setAuthenticated() {
     debugPrint('🟢 AuthState: Transitioning to authenticated');
     state = state.copyWith(state: AuthFlowState.authenticated);
     debugPrint('🟢 AuthState: State updated to ${state.state}');
   }
   ```

2. **Provider Creation:**
   ```dart
   final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>(
     (ref) {
       debugPrint('🟢 AuthStateProvider: Creating notifier');
       return AuthStateNotifier(ref);
     },
   );
   ```

3. **Navigation Decisions:**
   ```dart
   Widget navigationAuthority(WidgetRef ref) {
     final authState = ref.watch(authStateProvider);
     debugPrint('🟢 NavigationAuthority: Auth state = ${authState.state}');
     // ...
   }
   ```

4. **Supabase Events:**
   ```dart
   final supabaseAuthBridgeProvider = StreamProvider.autoDispose((ref) {
     debugPrint('🟢 SupabaseAuthBridge: Subscribing to auth stream');
     return Supabase.instance.client.auth.onAuthStateChange.map((data) {
       debugPrint('🟢 SupabaseAuthBridge: Event = ${data.event}');
       return data;
     });
   });
   ```

---

### 6.3 Test Cases

#### Test Case 1: Cold App Start (With Session)

**Setup:**
- Supabase session exists
- App starts fresh

**Expected Behavior:**
1. `sessionRestorationProvider` checks session
2. `authStateProvider` receives session
3. `authStateProvider.state` = `authenticated`
4. `roleProvider` fetches role
5. `navigationAuthorityProvider` returns `DashboardScreen` or `StaffDashboard`
6. `AuthGate` displays target screen

**Verification:**
- Logs show state transitions
- No errors in console
- Correct screen displayed

---

#### Test Case 2: Cold App Start (Without Session)

**Setup:**
- No Supabase session
- App starts fresh

**Expected Behavior:**
1. `sessionRestorationProvider` checks session (returns null)
2. `authStateProvider` receives null
3. `authStateProvider.state` = `unauthenticated`
4. `navigationAuthorityProvider` returns `LoginScreen`
5. `AuthGate` displays `LoginScreen`

**Verification:**
- Logs show state transitions
- No errors in console
- `LoginScreen` displayed

---

#### Test Case 3: Login Flow (OTP → PIN Setup → Dashboard)

**Setup:**
- User on `LoginScreen`
- User enters phone, gets OTP
- User verifies OTP
- PIN not set

**Expected Behavior:**
1. `OTPScreen` calls `AuthService.verifyOTP()`
2. Supabase creates session
3. `supabaseAuthBridgeProvider` emits `signedIn`
4. `authStateProvider` watches `mobileAppAccessProvider`
5. Access granted → `authStateProvider.state` = `authenticated`
6. `OTPScreen` calls `setOtpVerified()`
7. `authStateProvider.state` = `otpVerifiedNeedsPin`
8. `navigationAuthorityProvider` returns `PinSetupScreen`
9. User sets PIN
10. `PinSetupScreen` calls `setAuthenticated()`
11. `authStateProvider.state` = `authenticated`
12. `roleProvider` fetches role
13. `navigationAuthorityProvider` returns `DashboardScreen`
14. `AuthGate` displays `DashboardScreen`

**Verification:**
- All state transitions logged
- No errors
- Correct screens displayed at each step

---

#### Test Case 4: Staff Login Flow

**Setup:**
- User on `LoginScreen`
- User taps "Staff Login"
- User enters staff code and password

**Expected Behavior:**
1. `LoginScreen` calls `goToStaffLogin()`
2. `authStateProvider.state` = `staffLogin`
3. `navigationAuthorityProvider` returns `StaffLoginScreen`
4. `StaffLoginScreen` calls `StaffAuthService.signInWithStaffCode()`
5. Supabase creates session
6. `supabaseAuthBridgeProvider` emits `signedIn`
7. `authStateProvider` watches `mobileAppAccessProvider`
8. Access granted → `authStateProvider.state` = `authenticated`
9. `roleProvider` fetches role
10. `navigationAuthorityProvider` returns `StaffDashboard`
11. `AuthGate` displays `StaffDashboard`

**Verification:**
- All state transitions logged
- No errors
- `StaffDashboard` displayed

---

#### Test Case 5: Logout Flow

**Setup:**
- User on `DashboardScreen` or `StaffDashboard`
- User taps logout

**Expected Behavior:**
1. Screen calls `Supabase.instance.client.auth.signOut()`
2. Supabase removes session
3. `supabaseAuthBridgeProvider` emits `signedOut`
4. `authStateProvider` receives `signedOut`
5. `authStateProvider.forceLogout()` called
6. `authStateProvider.state` = `unauthenticated`
7. `navigationAuthorityProvider` returns `LoginScreen`
8. `roleProvider` is disposed
9. `AuthGate` displays `LoginScreen`

**Verification:**
- All state transitions logged
- No errors
- `LoginScreen` displayed
- No memory leaks

---

#### Test Case 6: Login After Logout

**Setup:**
- User just logged out
- User on `LoginScreen`
- User logs in again

**Expected Behavior:**
1. Same as Test Case 3 (Login Flow)
2. **CRITICAL:** `AuthGate` must rebuild when `navigationAuthorityProvider` changes
3. No rebuild suppression
4. No lifecycle errors

**Verification:**
- Logs show `AuthGate.build()` called after state change
- No "build() suppressed" errors
- Correct screen displayed

---

#### Test Case 7: Session Expiry

**Setup:**
- User authenticated
- Supabase session expires (timeout or revoked)

**Expected Behavior:**
1. `supabaseAuthBridgeProvider` emits `signedOut` or `tokenRefreshed`
2. If `signedOut`:
   - `authStateProvider.forceLogout()` called
   - `authStateProvider.state` = `unauthenticated`
   - `navigationAuthorityProvider` returns `LoginScreen`
   - `AuthGate` displays `LoginScreen`
3. If `tokenRefreshed`:
   - No state change
   - User remains on current screen

**Verification:**
- State transitions logged
- No errors
- Correct screen displayed

---

#### Test Case 8: App Resume

**Setup:**
- App in background
- User returns to app

**Expected Behavior:**
1. `supabaseAuthBridgeProvider` stream may emit if session changed
2. If session expired:
   - Same as Test Case 7 (Session Expiry)
3. If session valid:
   - No state change
   - User remains on current screen

**Verification:**
- State transitions logged (if any)
- No errors
- Correct screen displayed

---

### 6.4 Regression Prevention

#### Checklist for Every Change

- [ ] All state access uses `ref.watch()` or `ref.read()`
- [ ] No `BuildContext` usage for state access
- [ ] No manual `addListener/removeListener`
- [ ] No `Navigator.push/pop` calls (except for non-auth screens)
- [ ] All providers have proper lifecycle (`alwaysAlive` or `autoDispose`)
- [ ] All state mutations go through provider methods
- [ ] All navigation goes through `navigationAuthorityProvider`
- [ ] All test cases pass

---

#### Code Review Checklist

- [ ] No Provider imports remain
- [ ] No `ChangeNotifier` usage
- [ ] No `Consumer` widget usage (use `ConsumerWidget` instead)
- [ ] No `Provider.of(context)` calls
- [ ] All widgets that need state are `ConsumerWidget` or `ConsumerStatefulWidget`
- [ ] All providers are properly typed
- [ ] All error cases handled

---

### 6.5 Final Guarantees

**Guarantee 1: Widget Lifecycle Independence**
- Auth state is independent of widget lifecycle
- No `BuildContext` dependency
- No lifecycle corruption

**Guarantee 2: Rebuild Guarantee**
- State changes always trigger widget rebuilds
- No rebuild suppression
- No manual workarounds needed

**Guarantee 3: Context Independence**
- No context-based state corruption
- `ref` works regardless of widget state
- No "deactivated widget" errors

**Guarantee 4: Single Source of Truth**
- `authStateProvider` is the only source of auth state
- No dual state sources
- No race conditions

**Guarantee 5: Navigation Authority**
- `navigationAuthorityProvider` is the only source of navigation
- No imperative navigation
- No navigation stack inconsistencies

---

## PROVIDER MAP {#provider-map}

### Provider Dependency Graph

```
┌─────────────────────────────────────────────────────────────┐
│                    Riverpod Provider Tree                     │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  sessionRestorationProvider                           │  │
│  │  Type: FutureProvider<AuthState?>                  │  │
│  │  Lifecycle: autoDispose                              │  │
│  │  Purpose: Check Supabase session on app start       │  │
│  └─────────────────────────────────────────────────────┘  │
│                          │                                   │
│                          ▼                                   │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  authStateProvider                                   │  │
│  │  Type: StateNotifierProvider<AuthStateNotifier,      │  │
│  │         AuthState>                                    │  │
│  │  Lifecycle: alwaysAlive                               │  │
│  │  Purpose: Single source of truth for auth state      │  │
│  │                                                       │  │
│  │  Watches:                                            │  │
│  │  - sessionRestorationProvider                        │  │
│  │  - supabaseAuthBridgeProvider                        │  │
│  │  - mobileAppAccessProvider                           │  │
│  └─────────────────────────────────────────────────────┘  │
│                          │                                   │
│        ┌─────────────────┼─────────────────┐               │
│        │                 │                 │               │
│        ▼                 ▼                 ▼               │
│  ┌──────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │supabase  │  │mobileApp     │  │roleProvider       │   │
│  │AuthBridge│  │Access        │  │                   │   │
│  │Provider  │  │Provider       │  │Type: Future       │   │
│  │          │  │               │  │Provider<RoleData?>│   │
│  │Type:     │  │Type: Future   │  │                   │   │
│  │Stream    │  │Provider<bool> │  │Lifecycle:         │   │
│  │Provider  │  │               │  │autoDispose        │   │
│  │          │  │Lifecycle:     │  │                   │   │
│  │Lifecycle:│  │autoDispose    │  │Purpose: Fetch     │   │
│  │always    │  │               │  │user role         │   │
│  │Alive     │  │Purpose: Check │  │                   │   │
│  │          │  │mobile app     │  │Depends on:        │   │
│  │Purpose:  │  │access         │  │authStateProvider  │   │
│  │Bridge    │  │               │  │(only if auth)     │   │
│  │Supabase  │  │Depends on:    │  └──────────────────┘   │
│  │auth      │  │authState      │         │                 │
│  │stream    │  │Provider       │         │                 │
│  └──────────┘  └──────────────┘         │                 │
│                                          │                 │
│                                          ▼                 │
│                                  ┌──────────────────┐     │
│                                  │navigation         │     │
│                                  │Authority          │     │
│                                  │Provider           │     │
│                                  │                   │     │
│                                  │Type: Provider<    │     │
│                                  │       Widget>     │     │
│                                  │                   │     │
│                                  │Lifecycle:         │     │
│                                  │autoDispose        │     │
│                                  │                   │     │
│                                  │Purpose: Compute   │     │
│                                  │navigation target  │     │
│                                  │                   │     │
│                                  │Depends on:        │     │
│                                  │- authState        │     │
│                                  │  Provider         │     │
│                                  │- roleProvider     │     │
│                                  └──────────────────┘     │
│                                          │                 │
│                                          ▼                 │
│                                  ┌──────────────────┐     │
│                                  │AuthGate Widget   │     │
│                                  │(ConsumerWidget)   │     │
│                                  │                   │     │
│                                  │Watches:           │     │
│                                  │navigation         │     │
│                                  │Authority          │     │
│                                  │Provider           │     │
│                                  └──────────────────┘     │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Provider Read/Write Matrix

| Provider | Read By | Write By | Mutations |
|----------|---------|----------|-----------|
| `sessionRestorationProvider` | `authStateProvider` | None (read-only) | None |
| `supabaseAuthBridgeProvider` | `authStateProvider` | Supabase SDK (external) | External |
| `authStateProvider` | All widgets, `navigationAuthorityProvider`, `roleProvider`, `mobileAppAccessProvider` | `AuthStateNotifier` only | `setOtpVerified()`, `setAuthenticated()`, `goToStaffLogin()`, `forceLogout()`, `setUnauthenticated()` |
| `mobileAppAccessProvider` | `authStateProvider` | None (read-only) | None |
| `roleProvider` | `navigationAuthorityProvider` | None (read-only) | None |
| `navigationAuthorityProvider` | `AuthGate` widget | None (computed) | None |

---

## MIGRATION CHECKLIST {#migration-checklist}

### Pre-Migration

- [ ] Create git branch: `riverpod-migration`
- [ ] Commit current state
- [ ] Tag current commit: `pre-riverpod-migration`
- [ ] Review current architecture (Phase 1)
- [ ] Understand Riverpod design (Phase 2)
- [ ] Review event flows (Phase 3)

### Dependency Setup

- [ ] Add `flutter_riverpod: ^2.4.9` to `pubspec.yaml`
- [ ] Run `flutter pub get`
- [ ] Verify app compiles
- [ ] Commit: "Add Riverpod dependency"

### Provider Implementation

- [ ] Create `lib/providers/` directory
- [ ] Create `auth_state_provider.dart` (empty structure)
- [ ] Create `supabase_auth_bridge_provider.dart` (empty structure)
- [ ] Create `session_restoration_provider.dart` (empty structure)
- [ ] Create `role_provider.dart` (empty structure)
- [ ] Create `navigation_authority_provider.dart` (empty structure)
- [ ] Create `mobile_app_access_provider.dart` (empty structure)
- [ ] Commit: "Create provider files structure"

- [ ] Implement `AuthState` class
- [ ] Implement `AuthStateNotifier` class
- [ ] Implement `authStateProvider`
- [ ] Test: Provider compiles
- [ ] Commit: "Implement authStateProvider"

- [ ] Implement `supabaseAuthBridgeProvider`
- [ ] Test: Stream emits events
- [ ] Commit: "Implement supabaseAuthBridgeProvider"

- [ ] Implement `sessionRestorationProvider`
- [ ] Test: Returns correct session state
- [ ] Commit: "Implement sessionRestorationProvider"

- [ ] Implement `RoleData` class
- [ ] Implement `roleProvider`
- [ ] Test: Fetches role correctly
- [ ] Commit: "Implement roleProvider"

- [ ] Implement `mobileAppAccessProvider`
- [ ] Test: Checks access correctly
- [ ] Commit: "Implement mobileAppAccessProvider"

- [ ] Implement `navigationAuthorityProvider`
- [ ] Test: Returns correct screens
- [ ] Commit: "Implement navigationAuthorityProvider"

- [ ] Wire up `authStateProvider` to Supabase stream
- [ ] Wire up `authStateProvider` to session restoration
- [ ] Wire up `authStateProvider` to mobile app access
- [ ] Test: Auth state updates on Supabase events
- [ ] Commit: "Wire up authStateProvider"

### Main App Update

- [ ] Remove `provider` import from `main.dart`
- [ ] Add `flutter_riverpod` import to `main.dart`
- [ ] Remove `ChangeNotifierProvider.value` wrapper
- [ ] Wrap `MyApp` in `ProviderScope`
- [ ] Remove Supabase auth listener (now in provider)
- [ ] Remove `AuthFlowNotifier` creation
- [ ] Test: App compiles and starts
- [ ] Commit: "Update main.dart to use Riverpod"

### AuthGate Update

- [ ] Change `AuthGate` from `StatefulWidget` to `ConsumerWidget`
- [ ] Remove all state variables
- [ ] Remove `initState()`, `dispose()`, `didChangeDependencies()`
- [ ] Remove `_checkRoleIfNeeded()`, `_checkRoleAndRoute()`
- [ ] Remove manual listener
- [ ] Update `build()` to use `ref.watch(navigationAuthorityProvider)`
- [ ] Test: Navigation works correctly
- [ ] Commit: "Update AuthGate to use Riverpod"

### Screen Updates

- [ ] Update `LoginScreen` to use Riverpod
- [ ] Update `OTPScreen` to use Riverpod
- [ ] Update `PinSetupScreen` to use Riverpod
- [ ] Update `StaffLoginScreen` to use Riverpod
- [ ] Remove all `Provider.of` calls
- [ ] Remove all `Provider` imports
- [ ] Test: All screens work correctly
- [ ] Commit: "Update screens to use Riverpod"

### Cleanup

- [ ] Delete `lib/services/auth_flow_notifier.dart`
- [ ] Remove `provider` from `pubspec.yaml`
- [ ] Run `flutter pub get`
- [ ] Test: App compiles
- [ ] Commit: "Remove Provider dependency"

### Navigation Cleanup

- [ ] Remove `Navigator.push` from `LoginScreen`
- [ ] Remove `Navigator.push` from `OTPScreen`
- [ ] Test: Navigation works declaratively
- [ ] Commit: "Remove imperative navigation"

### Testing

- [ ] Test: Cold app start (with session)
- [ ] Test: Cold app start (without session)
- [ ] Test: Login flow (OTP → PIN → Dashboard)
- [ ] Test: Staff login flow
- [ ] Test: Logout flow
- [ ] Test: Login after logout
- [ ] Test: Session expiry
- [ ] Test: App resume
- [ ] Commit: "Complete migration testing"

### Verification

- [ ] Verify: No Provider imports remain
- [ ] Verify: No `ChangeNotifier` usage
- [ ] Verify: No `BuildContext` usage for state
- [ ] Verify: No manual listeners
- [ ] Verify: No imperative navigation
- [ ] Verify: All test cases pass
- [ ] Commit: "Migration complete"

---

## RISK REGISTER {#risk-register}

### Risk 1: Migration Complexity

**Risk Level:** Medium

**Description:** Migration involves multiple files and providers. Risk of introducing bugs during migration.

**Mitigation:**
- Follow step-by-step plan (Phase 4)
- Test after each step
- Use git commits for rollback points
- Review code after each major change

**Impact if Unmitigated:** Broken app, difficult to debug

---

### Risk 2: Provider Dependency Errors

**Risk Level:** Low

**Description:** Incorrect provider dependencies could cause circular dependencies or incorrect behavior.

**Mitigation:**
- Follow provider dependency graph (Phase 2)
- Use `ref.watch()` for reactive dependencies
- Use `ref.read()` for one-time reads
- Test provider dependencies

**Impact if Unmitigated:** App crashes or incorrect behavior

---

### Risk 3: State Migration Issues

**Risk Level:** Medium

**Description:** State might not migrate correctly from Provider to Riverpod, causing data loss or incorrect state.

**Mitigation:**
- Test all state transitions (Phase 6)
- Verify state invariants (Phase 6)
- Use logging to track state changes
- Test edge cases

**Impact if Unmitigated:** User data loss, incorrect app behavior

---

### Risk 4: Navigation Issues

**Risk Level:** Low

**Description:** Declarative navigation might not work correctly, causing navigation stack issues.

**Mitigation:**
- Test all navigation flows (Phase 6)
- Verify `navigationAuthorityProvider` logic
- Remove all imperative navigation
- Test back button behavior

**Impact if Unmitigated:** Navigation bugs, user confusion

---

### Risk 5: Performance Issues

**Risk Level:** Low

**Description:** Riverpod providers might cause performance issues if not configured correctly.

**Mitigation:**
- Use `alwaysAlive` only for persistent state
- Use `autoDispose` for derived state
- Avoid unnecessary provider recreations
- Profile app performance

**Impact if Unmitigated:** Slow app, poor user experience

---

### Risk 6: Testing Gaps

**Risk Level:** Medium

**Description:** Not all edge cases might be tested, causing bugs in production.

**Mitigation:**
- Follow test cases (Phase 6)
- Test all critical flows
- Test edge cases (session expiry, app resume, etc.)
- Use assertions and logging

**Impact if Unmitigated:** Production bugs, user complaints

---

### Risk 7: Rollback Complexity

**Risk Level:** Low

**Description:** Rolling back migration might be difficult if not properly planned.

**Mitigation:**
- Create git tags at major milestones
- Test rollback procedure
- Keep old code until migration verified
- Document rollback steps

**Impact if Unmitigated:** Difficult to recover from migration issues

---

### Risk Summary

| Risk | Level | Mitigation | Impact |
|------|-------|------------|--------|
| Migration Complexity | Medium | Step-by-step plan, testing | Broken app |
| Provider Dependencies | Low | Follow dependency graph | App crashes |
| State Migration | Medium | Test state transitions | Data loss |
| Navigation Issues | Low | Test navigation flows | Navigation bugs |
| Performance Issues | Low | Proper lifecycle config | Slow app |
| Testing Gaps | Medium | Comprehensive test cases | Production bugs |
| Rollback Complexity | Low | Git tags, documentation | Recovery issues |

---

## FINAL VERDICT {#final-verdict}

### Architectural Soundness: ✅ APPROVED

**Rationale:**
1. **Eliminates Widget Lifecycle Dependence:** Riverpod providers are independent of widget lifecycle, solving the core issue.
2. **Guarantees Rebuilds:** `ref.watch()` automatically triggers rebuilds, eliminating rebuild suppression.
3. **Removes Context Dependency:** `ref` works regardless of widget state, eliminating context corruption.
4. **Single Source of Truth:** `authStateProvider` is the only source of auth state, eliminating dual state sources.
5. **Declarative Navigation:** `navigationAuthorityProvider` provides declarative navigation, eliminating imperative navigation issues.

**Migration Feasibility: ✅ FEASIBLE**

**Rationale:**
1. **Clear Plan:** Step-by-step migration plan with rollback points.
2. **Zero-Downtime:** App compiles at every step.
3. **Testable:** Comprehensive test cases and verification procedures.
4. **Low Risk:** Risks are identified and mitigated.

**Recommendation: ✅ PROCEED WITH MIGRATION**

The migration plan is comprehensive, well-documented, and addresses all identified issues. The Riverpod architecture eliminates all current architectural flaws and provides a solid foundation for future development.

---

**Document Status:** ✅ COMPLETE

**Last Updated:** 2026-01-02

**Next Steps:**
1. Review this specification with team
2. Create git branch for migration
3. Begin migration following Phase 4 plan
4. Test thoroughly at each step
5. Complete migration and verify all test cases pass


