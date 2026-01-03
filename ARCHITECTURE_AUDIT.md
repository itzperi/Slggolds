# SLG Golds App - Architecture Audit Report

**Date:** 2025-12-17  
**Status:** READ-ONLY AUDIT (No refactoring yet)  
**Purpose:** Identify all state management, navigation patterns, and auth flow conflicts

---

## 1️⃣ ROOT FLOW DECISION

### File: `lib/main.dart`

**Entry Point:**
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(...);
  runApp(const MyApp());
}
```

**Root Widget: `MyApp`**
```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthFlowNotifier(),  // ← Global state created here
      child: MaterialApp(
        home: const AuthGate(),  // ← Root screen decision point
      ),
    );
  }
}
```

**Root Screen Decider: `AuthGate`**
```dart
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthFlowNotifier>(
      builder: (context, authFlow, child) {
        // DECLARATIVE ROUTING - Single source of truth
        switch (authFlow.state) {
          case AuthFlowState.unauthenticated:
            // Nested StreamBuilder for Supabase session check
            return StreamBuilder<AuthState>(
              stream: Supabase.instance.client.auth.onAuthStateChange,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return LoadingScreen();
                }
                final session = snapshot.hasData ? snapshot.data!.session : null;
                if (session != null) {
                  // ⚠️ RACE CONDITION: PostFrameCallback updates state
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    authFlow.setAuthenticated();
                  });
                  return const DashboardScreen();
                }
                return const LoginScreen();
              },
            );

          case AuthFlowState.otpVerifiedNeedsPin:
            return PinSetupScreen(
              phoneNumber: authFlow.phoneNumber ?? '',
              isFirstTime: authFlow.isFirstTime,
              isReset: authFlow.isResetPin,
            );

          case AuthFlowState.authenticated:
            return const DashboardScreen();
        }
      },
    );
  }
}
```

**Conditions Used:**
1. `authFlow.state` (from `AuthFlowNotifier`)
2. `Supabase.instance.client.auth.onAuthStateChange` stream
3. `snapshot.connectionState == ConnectionState.waiting`
4. `session != null` (from Supabase)

**⚠️ CRITICAL ISSUE IDENTIFIED:**
- **Line 81-83:** `WidgetsBinding.instance.addPostFrameCallback` updates state AFTER rendering Dashboard
- This creates a race condition where Dashboard renders, then state changes, causing rebuild
- **Nested StreamBuilder** inside `unauthenticated` case creates dual state sources

---

## 2️⃣ GLOBAL STATE INVENTORY

### A. AuthFlowNotifier (Provider/ChangeNotifier)
**File:** `lib/services/auth_flow_notifier.dart`

**Purpose:** Single source of truth for auth flow state

**State:**
- `_state: AuthFlowState` (enum: unauthenticated, otpVerifiedNeedsPin, authenticated)
- `_phoneNumber: String?`
- `_isFirstTime: bool`
- `_isResetPin: bool`

**Who Writes:**
- `lib/screens/otp_screen.dart` → `authFlow.setOtpVerified()` (lines 216, 331)
- `lib/screens/auth/pin_setup_screen.dart` → `authFlow.setAuthenticated()` (lines 101, 105, 108)
- `lib/main.dart` → `authFlow.setAuthenticated()` (line 82) - **RACE CONDITION**

**Who Reads:**
- `lib/main.dart` → `Consumer<AuthFlowNotifier>` (line 55) - **AuthGate**
- All screens can access via `Provider.of<AuthFlowNotifier>(context)`

**Lifecycle:**
- Created in `MyApp.build()` via `ChangeNotifierProvider`
- Lives for entire app lifetime
- Never disposed (potential memory leak if not handled)

---

### B. Supabase Auth Stream
**File:** `lib/main.dart` (line 64)

**Purpose:** Listen to Supabase authentication state changes

**Stream:** `Supabase.instance.client.auth.onAuthStateChange`

**Who Writes:**
- Supabase SDK (external)
- OTP verification creates session
- Sign out removes session

**Who Reads:**
- `lib/main.dart` → `StreamBuilder` in `AuthGate` (line 63-89)
- `lib/services/auth_service.dart` → `authStateChanges` getter (line 55-57)

**⚠️ CONFLICT:**
- Supabase stream fires independently of `AuthFlowNotifier`
- Creates dual state sources competing for control

---

### C. SecureStorageHelper (Static Class)
**File:** `lib/utils/secure_storage_helper.dart`

**Purpose:** Persistent storage for PINs, phone numbers, biometric preferences

**Storage Keys:**
- `user_pin_hash` - Hashed user PIN
- `user_phone` - User phone number
- `biometric_enabled` - Biometric preference
- `last_auth_timestamp` - Last auth time
- `staff_pin_hash` - Hashed staff PIN
- `staff_id` - Staff ID
- `staff_last_auth_timestamp` - Staff last auth time

**Who Writes:**
- `lib/screens/auth/pin_setup_screen.dart` → `savePin()`, `savePhone()`
- `lib/screens/otp_screen.dart` → `savePhone()`
- `lib/screens/auth/pin_login_screen.dart` → `updateLastAuth()`
- `lib/screens/staff/staff_pin_setup_screen.dart` → `saveStaffPin()`
- `lib/screens/staff/staff_login_screen.dart` → `saveStaffId()`

**Who Reads:**
- `lib/screens/otp_screen.dart` → `isPinSet()` (line 229)
- `lib/screens/auth/pin_login_screen.dart` → `verifyPin()`, `isPinSet()`
- `lib/screens/login_screen.dart` → `getSavedPhone()` (line 43)
- `lib/screens/staff/staff_pin_login_screen.dart` → `verifyStaffPin()`, `isStaffPinSet()`

**⚠️ ISSUE:**
- Static class with no lifecycle management
- No reactive updates when values change
- Screens must manually check on mount

---

### D. Mock Data (Static Classes)
**Files:**
- `lib/utils/mock_data.dart` - Customer mock data
- `lib/mock_data/staff_mock_data.dart` - Staff mock data

**Purpose:** Temporary data for development

**State:** Static lists and maps

**Who Writes:** Code directly modifies static lists

**Who Reads:** All screens that need data

**⚠️ ISSUE:**
- Not reactive
- Changes don't trigger rebuilds
- No state management

---

## 3️⃣ NAVIGATION SURFACE SCAN

### Auth-Related Navigation (MUST BE ZERO)

**🔴 CRITICAL VIOLATIONS FOUND:**

#### `lib/screens/otp_screen.dart`
- **Line 253:** `Navigator.of(context).pushAndRemoveUntil` → PinSetupScreen
  - **Context:** Existing user, first time PIN setup
  - **Status:** ❌ **SHOULD USE STATE, NOT NAVIGATION**
  
- **Line 286:** `Navigator.of(context).pushAndRemoveUntil` → DashboardScreen
  - **Context:** Existing user, PIN already set
  - **Status:** ❌ **SHOULD USE STATE, NOT NAVIGATION**

- **Line 544:** `Navigator.of(context).pop()` → Back button
  - **Status:** ✅ OK (UI navigation, not auth flow)

#### `lib/screens/auth/pin_login_screen.dart`
- **Line 147:** `Navigator.pushReplacement` → DashboardScreen
  - **Context:** PIN login successful
  - **Status:** ❌ **SHOULD USE STATE, NOT NAVIGATION**
  
- **Line 211:** `Navigator.pushAndRemoveUntil` → DashboardScreen
  - **Context:** PIN login successful (alternative path)
  - **Status:** ❌ **SHOULD USE STATE, NOT NAVIGATION**

#### `lib/screens/auth/biometric_setup_screen.dart`
- **Line 70:** `Navigator.pushAndRemoveUntil` → DashboardScreen
  - **Context:** Biometric setup complete
  - **Status:** ❌ **SHOULD USE STATE, NOT NAVIGATION**

#### `lib/screens/login_screen.dart`
- **Line 120:** `Navigator.pushReplacement` → OTPScreen
  - **Context:** Phone number entered, sending OTP
  - **Status:** ⚠️ **DEBATABLE** (Could be UI navigation, but part of auth flow)

- **Line 170:** `Navigator.of(context).push` → OTPScreen
  - **Context:** Staff login button
  - **Status:** ✅ OK (Staff flow separate)

#### `lib/screens/customer/profile_screen.dart`
- **Line 659:** `Navigator.pushAndRemoveUntil` → LoginScreen
  - **Context:** Logout
  - **Status:** ❌ **SHOULD USE STATE (`setUnauthenticated()`)**

#### `lib/screens/staff/staff_profile_screen.dart`
- **Line 334:** `Navigator.pushAndRemoveUntil` → StaffLoginScreen
  - **Context:** Staff logout
  - **Status:** ❌ **SHOULD USE STATE (if staff has AuthFlowNotifier)**

---

### Non-Auth Navigation (OK - These are UI navigation)

**Total Navigator calls found:** 97 instances across 30+ files

**Categories:**
- ✅ **Detail screens** (Dashboard → Scheme Detail, Transaction Detail, etc.)
- ✅ **Modal dialogs** (`Navigator.pop()`)
- ✅ **Back navigation** (`Navigator.pop()`)
- ✅ **Settings/Profile sub-screens**

**Files with most navigation:**
- `dashboard_screen.dart`: 8 calls (all detail screens)
- `reports_screen.dart`: 7 calls (detail screens, modals)
- `profile_screen.dart`: 6 calls (settings, help, etc.)

---

## 4️⃣ AUTH & SESSION LIFECYCLE

### A. App Cold Start

**Event:** `main()` → `runApp(MyApp())`

**State Changes:**
1. `AuthFlowNotifier` created with `_state = unauthenticated`
2. `AuthGate` builds
3. `StreamBuilder` subscribes to `Supabase.auth.onAuthStateChange`
4. Stream emits initial state (waiting → hasData/hasError)

**Expected Screen:**
- If Supabase session exists → Dashboard (with postFrameCallback setting state)
- If no session → LoginScreen

**⚠️ RACE CONDITION:**
- StreamBuilder may emit `session != null` before `AuthFlowNotifier` state updates
- Dashboard renders, then `addPostFrameCallback` fires, causing rebuild

---

### B. Firebase/Supabase Auth State Change

**Event:** Supabase session created/destroyed

**Trigger:** External (OTP verification, sign out, token refresh)

**State Changes:**
1. `Supabase.auth.onAuthStateChange` stream emits new `AuthState`
2. `StreamBuilder` in `AuthGate` rebuilds
3. If `session != null`:
   - Dashboard renders immediately
   - `addPostFrameCallback` sets `authFlow.setAuthenticated()` (delayed)

**Expected Screen:**
- Session created → Dashboard
- Session destroyed → LoginScreen

**⚠️ CONFLICT:**
- Supabase stream can fire while `AuthFlowNotifier` is in `otpVerifiedNeedsPin` state
- StreamBuilder overrides AuthFlowNotifier decision

---

### C. OTP Success

**Event:** User enters correct OTP

**Current Implementation (MIXED - INCONSISTENT):**

**Path 1: New User (CORRECT)**
```dart
// lib/screens/otp_screen.dart:329-334
final authFlow = Provider.of<AuthFlowNotifier>(context, listen: false);
authFlow.setOtpVerified(
  phoneNumber: widget.phone,
  isFirstTime: true,
);
```
- ✅ **Uses state** → Triggers declarative rebuild → PinSetupScreen

**Path 2: Existing User, No PIN (WRONG)**
```dart
// lib/screens/otp_screen.dart:253-261
Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(
    builder: (_) => PinSetupScreen(...),
  ),
  (_) => false,
);
```
- ❌ **Uses navigation** → Bypasses AuthGate → Creates conflict

**Path 3: Existing User, Has PIN (WRONG)**
```dart
// lib/screens/otp_screen.dart:286-291
Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(
    builder: (_) => const DashboardScreen(),
  ),
  (_) => false,
);
```
- ❌ **Uses navigation** → Bypasses AuthGate → Creates conflict

**Expected Behavior:**
- All paths should call `authFlow.setOtpVerified()` or `authFlow.setAuthenticated()`
- No Navigator calls for auth flow

---

### D. PIN Success

**Event:** User completes PIN setup

**Current Implementation (CORRECT):**
```dart
// lib/screens/auth/pin_setup_screen.dart:97-109
final authFlow = Provider.of<AuthFlowNotifier>(context, listen: false);
authFlow.setAuthenticated();
```
- ✅ **Uses state** → Triggers declarative rebuild → Dashboard

**Expected Screen:** Dashboard

**Status:** ✅ **CORRECT**

---

### E. App Resume from Background

**Event:** App returns from background

**State Changes:**
- `Supabase.auth.onAuthStateChange` may emit if session expired/refreshed
- `StreamBuilder` in `AuthGate` rebuilds
- If session invalid → LoginScreen
- If session valid → Dashboard (with postFrameCallback)

**Expected Screen:**
- Valid session → Dashboard
- Invalid/expired session → LoginScreen

**⚠️ ISSUE:**
- No explicit handling of app lifecycle
- Relies on Supabase stream to detect session changes

---

## 5️⃣ SCREEN OWNERSHIP MAP

### Login Screen (`lib/screens/login_screen.dart`)

**Who Decides Navigation:**
- ❌ **Login Screen itself** (line 120: `Navigator.pushReplacement` → OTPScreen)

**Correct Answer:** Should emit event, not navigate

**Current Behavior:**
- User enters phone → Login screen navigates to OTP
- Should instead: Call `authService.sendOTP()` and emit event

---

### OTP Screen (`lib/screens/otp_screen.dart`)

**Who Decides Navigation:**
- ❌ **OTP Screen itself** (lines 253, 286: `Navigator.pushAndRemoveUntil`)
- ✅ **OTP Screen emits state** (lines 216, 331: `authFlow.setOtpVerified()`)

**Status:** **MIXED - INCONSISTENT**

**Current Behavior:**
- New user → Uses state ✅
- Existing user, no PIN → Uses navigation ❌
- Existing user, has PIN → Uses navigation ❌

**Correct Answer:** All paths should emit state only

---

### PIN Setup Screen (`lib/screens/auth/pin_setup_screen.dart`)

**Who Decides Navigation:**
- ✅ **PIN Setup emits state** (lines 97-109: `authFlow.setAuthenticated()`)
- ❌ **NO Navigator calls for auth flow** ✅

**Status:** ✅ **CORRECT**

---

### Dashboard Screen (`lib/screens/customer/dashboard_screen.dart`)

**Who Decides Navigation:**
- ✅ **Dashboard does NOT navigate for auth** (only detail screens)
- ✅ **All Navigator calls are for UI navigation** (detail screens, modals)

**Status:** ✅ **CORRECT**

---

### PIN Login Screen (`lib/screens/auth/pin_login_screen.dart`)

**Who Decides Navigation:**
- ❌ **PIN Login navigates** (lines 147, 211: `Navigator.pushReplacement/pushAndRemoveUntil` → Dashboard)

**Correct Answer:** Should emit `authFlow.setAuthenticated()`

**Status:** ❌ **WRONG**

---

### Biometric Setup Screen (`lib/screens/auth/biometric_setup_screen.dart`)

**Who Decides Navigation:**
- ❌ **Biometric Setup navigates** (line 70: `Navigator.pushAndRemoveUntil` → Dashboard)

**Correct Answer:** Should emit `authFlow.setAuthenticated()`

**Status:** ❌ **WRONG**

---

## 6️⃣ STATE TRANSITION DIAGRAM

```
┌─────────────────┐
│ unauthenticated │ ←── App start, logout
└────────┬────────┘
         │
         │ User enters phone → LoginScreen
         │
         ▼
    ┌─────────┐
    │ OTP Sent│ (UI state, not in AuthFlowState)
    └────┬────┘
         │
         │ OTP verified
         │
         ├─────────────────────────────────────┐
         │                                     │
         ▼                                     ▼
┌──────────────────────┐          ┌──────────────────────┐
│ otpVerifiedNeedsPin  │          │   authenticated     │
│                      │          │                      │
│ Trigger:             │          │ Trigger:            │
│ - New user           │          │ - Existing user     │
│ - First time PIN     │          │   with PIN          │
│ - Reset PIN          │          │ - PIN setup done    │
│                      │          │ - PIN login done    │
│ Screen: PinSetup     │          │ - Biometric done    │
└──────────┬───────────┘          │                      │
           │                      │ Screen: Dashboard  │
           │                      └──────────────────────┘
           │ PIN saved
           │
           ▼
┌──────────────────────┐
│   authenticated      │
│                      │
│ Trigger:             │
│ - PIN setup complete │
│                      │
│ Screen: Dashboard    │
└──────────────────────┘
```

### Transition Details

**1. unauthenticated → otpVerifiedNeedsPin**

**Trigger:** `authFlow.setOtpVerified(phoneNumber, isFirstTime, isResetPin)`

**Who Triggers:**
- `lib/screens/otp_screen.dart:216` (existing user, no PIN)
- `lib/screens/otp_screen.dart:331` (new user)

**Data Required:**
- `phoneNumber: String` (required)
- `isFirstTime: bool` (default: false)
- `isResetPin: bool` (default: false)

**Screen:** PinSetupScreen

---

**2. unauthenticated → authenticated**

**Trigger:** `authFlow.setAuthenticated()`

**Who Triggers:**
- `lib/main.dart:82` (Supabase session exists on app start) ⚠️ **RACE CONDITION**
- `lib/screens/otp_screen.dart` (should trigger, but currently uses Navigator ❌)
- `lib/screens/auth/pin_login_screen.dart` (should trigger, but currently uses Navigator ❌)

**Data Required:** None (clears phoneNumber, isFirstTime, isResetPin)

**Screen:** DashboardScreen

---

**3. otpVerifiedNeedsPin → authenticated**

**Trigger:** `authFlow.setAuthenticated()`

**Who Triggers:**
- `lib/screens/auth/pin_setup_screen.dart:101, 105, 108` ✅ **CORRECT**

**Data Required:** None

**Screen:** DashboardScreen

---

**4. authenticated → unauthenticated**

**Trigger:** `authFlow.setUnauthenticated()`

**Who Triggers:**
- ❌ **NOT CURRENTLY USED** (logout uses Navigator instead)

**Data Required:** None

**Screen:** LoginScreen

---

## 🔴 CRITICAL ISSUES SUMMARY

### Issue 1: Dual State Sources
**Location:** `lib/main.dart:63-89`

**Problem:**
- `AuthFlowNotifier` (declarative) AND `Supabase.auth.onAuthStateChange` (reactive stream) both control routing
- StreamBuilder nested inside `unauthenticated` case creates conflict
- When Supabase session exists, Dashboard renders immediately, then state updates

**Impact:** Race conditions, screen flicker, unexpected rebuilds

---

### Issue 2: Inconsistent Navigation Patterns
**Location:** `lib/screens/otp_screen.dart`

**Problem:**
- New user path uses state ✅
- Existing user paths use Navigator ❌
- Creates tug-of-war between AuthGate and manual navigation

**Impact:** Blank screens, navigation conflicts

---

### Issue 3: Missing State Updates
**Location:** Multiple files

**Problem:**
- PIN Login → Dashboard uses Navigator instead of state
- Biometric Setup → Dashboard uses Navigator instead of state
- Logout uses Navigator instead of `setUnauthenticated()`

**Impact:** AuthGate doesn't know about these transitions

---

### Issue 4: PostFrameCallback Race Condition
**Location:** `lib/main.dart:81-83`

**Problem:**
```dart
if (session != null) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    authFlow.setAuthenticated();
  });
  return const DashboardScreen();
}
```

**Impact:**
- Dashboard renders with `unauthenticated` state
- Then state changes to `authenticated`
- Causes unnecessary rebuild

---

## ✅ CORRECT PATTERNS FOUND

1. **PIN Setup → Dashboard:** Uses `authFlow.setAuthenticated()` ✅
2. **New User OTP → PIN Setup:** Uses `authFlow.setOtpVerified()` ✅
3. **Dashboard UI Navigation:** All Navigator calls are for detail screens ✅

---

## 📋 RECOMMENDATIONS (For Future Refactoring)

1. **Remove Supabase StreamBuilder from AuthGate**
   - Check session once on app start
   - Update `AuthFlowNotifier` state directly
   - Remove nested StreamBuilder

2. **Replace ALL auth-related Navigator calls with state updates**
   - OTP screen: Remove lines 253, 286
   - PIN Login: Replace Navigator with `authFlow.setAuthenticated()`
   - Biometric Setup: Replace Navigator with `authFlow.setAuthenticated()`
   - Logout: Replace Navigator with `authFlow.setUnauthenticated()`

3. **Add explicit app lifecycle handling**
   - Listen to `AppLifecycleState`
   - Re-check session on resume
   - Update `AuthFlowNotifier` accordingly

4. **Make SecureStorageHelper reactive**
   - Wrap in Provider/ChangeNotifier
   - Or use ValueNotifier for PIN state
   - Trigger rebuilds when PIN is set/cleared

---

**END OF AUDIT**

