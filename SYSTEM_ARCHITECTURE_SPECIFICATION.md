# SYSTEM ARCHITECTURE SPECIFICATION
## Complete Stack-Aware System Truth Extraction

**Date:** 2026-01-02  
**Status:** IN PROGRESS  
**Purpose:** Forensic extraction of actual system architecture from codebase

---

## 📋 TABLE OF CONTENTS

- [1️⃣ SYSTEM BOUNDARY & AUTHORITY MAP](#1-system-boundary)
- [2️⃣ END-TO-END EXECUTION FLOWS](#2-execution-flows)
- [3️⃣ DOMAIN DATA FLOW](#3-domain-data-flow)
- [4️⃣ BACKEND SURFACE AREA](#4-backend-surface)
- [5️⃣ DATABASE SCHEMA + RLS INTENT](#5-database-schema)
- [6️⃣ STATE INVENTORY](#6-state-inventory)
- [7️⃣ NAVIGATION & ROUTING AUTHORITY](#7-navigation)
- [8️⃣ FAILURE & EDGE-CASE MATRIX](#8-failure-matrix)
- [9️⃣ CROSS-LAYER CONTRADICTIONS & COUPLING](#9-cross-layer)
- [🔚 10️⃣ CANONICAL TRUTH STATEMENTS](#10-canonical-truth)

---

## 1️⃣ SYSTEM BOUNDARY & AUTHORITY MAP {#1-system-boundary}

| Decision | Authority | Stack Layer | Code Location |
|----------|-----------|-------------|---------------|
| **Auth truth** | Supabase Auth (auth.users) | Supabase / Database | `lib/main.dart:51` (onAuthStateChange listener), `lib/services/auth_service.dart:14` (signInWithOtp), `lib/services/staff_auth_service.dart:48` (signInWithPassword) |
| **Session lifecycle** | Supabase Auth SDK | Supabase | `lib/main.dart:45-46` (initializeSession), `lib/main.dart:51-81` (onAuthStateChange listener), `lib/services/auth_flow_notifier.dart:26-41` (initializeSession) |
| **Role resolution** | Database (profiles.role) | PostgreSQL / RLS | `lib/services/role_routing_service.dart:15-41` (fetchAndValidateRole), `lib/main.dart:238-242` (_checkRoleAndRoute) |
| **Navigation authority** | AuthGate widget (StatefulWidget) | Flutter / Provider | `lib/main.dart:346-398` (AuthGate.build), `lib/main.dart:204-343` (_checkRoleAndRoute) |
| **Payment validation** | Database triggers + RLS | PostgreSQL | `supabase_schema.sql:448-500` (update_user_scheme_totals trigger), `supabase_schema.sql:862-872` (RLS policy "Staff can insert payments for assigned customers") |
| **Staff permission enforcement** | RLS policies + SECURITY DEFINER functions | PostgreSQL | `supabase_schema.sql:623-632` (is_current_staff_assigned_to_customer), `supabase_schema.sql:862-872` (payment INSERT policy) |
| **Audit immutability** | Database triggers | PostgreSQL | `supabase_schema.sql:513-530` (prevent_payment_modification triggers), `supabase_schema.sql:231-273` (payments table - append-only design) |
| **Report correctness** | Database views + client aggregation | PostgreSQL / Flutter | `supabase_schema.sql:1006-1032` (today_collections view), `lib/services/staff_data_service.dart:194-287` (getTodayStats - client-side aggregation) |
| **Mobile app access** | RoleRoutingService.checkMobileAppAccess | Flutter / Database | `lib/services/role_routing_service.dart:79-151` (checkMobileAppAccess), `lib/main.dart:58` (called from auth listener) |
| **Staff code → email resolution** | Database RPC (SECURITY DEFINER) | PostgreSQL | `supabase_schema.sql:639-651` (get_staff_email_by_code), `lib/services/staff_auth_service.dart:25-28` (RPC call) |

**Authority Split Identified:**
- **Auth state:** Supabase Auth (source of truth) + AuthFlowNotifier (UI state) - **DUAL AUTHORITY**
- **Navigation:** AuthGate widget (declarative) + Navigator.push/pop (imperative) - **MIXED AUTHORITY**
- **Role-based routing:** AuthGate._checkRoleAndRoute (widget-owned) + RoleRoutingService (service layer) - **SPLIT AUTHORITY**

---

## 2️⃣ END-TO-END EXECUTION FLOWS {#2-execution-flows}

### 2.1 Cold App Start (Session Present)

**Linear Execution:**

1. **Flutter Widget:** `main()` function
   - **File:** `lib/main.dart:16-89`
   - **Action:** `Supabase.initialize()`, create `AuthFlowNotifier`, call `initializeSession()`

2. **State Transition:** `AuthFlowNotifier.initializeSession()`
   - **File:** `lib/services/auth_flow_notifier.dart:26-41`
   - **Action:** Check `Supabase.instance.client.auth.currentSession`
   - **State Change:** If session exists → `setAuthenticated()`, else → `setUnauthenticated()`

3. **Supabase Call:** Session check (synchronous)
   - **Type:** Auth read
   - **Location:** `lib/services/auth_flow_notifier.dart:28`

4. **Database Effect:** None (session already exists in Supabase Auth)

5. **UI Outcome:** `AuthGate.build()` executes
   - **File:** `lib/main.dart:346-398`
   - **Action:** Reads `authFlow.state` via `Provider.of<AuthFlowNotifier>(context)`
   - **If authenticated:** Returns loading Scaffold, schedules `_checkRoleIfNeeded()` via `addPostFrameCallback`

6. **State Transition:** `_checkRoleIfNeeded()` → `_checkRoleAndRoute()`
   - **File:** `lib/main.dart:169-202`, `204-343`
   - **Action:** Fetches role from `profiles` table

7. **Supabase Call:** Database read
   - **Type:** Direct DB query
   - **Location:** `lib/main.dart:238-242`
   - **Query:** `profiles.select('id, role').eq('user_id', userId).maybeSingle()`
   - **Tables Affected:** `profiles`

8. **Database Effect:** RLS policy "Users can read own profile" evaluated
   - **File:** `supabase_schema.sql:685-688`

9. **UI Outcome:** `setState()` updates `_roleBasedScreen`
   - **File:** `lib/main.dart:307-312`
   - **Action:** Creates `DashboardScreen` or `StaffDashboard` based on role
   - **Widget:** AuthGate rebuilds, returns target screen

**Async Boundaries:**
- `_checkRoleAndRoute()` is async (database query)
- `addPostFrameCallback` schedules execution after frame
- Race condition possible if `authFlow.state` changes during async operation

---

### 2.2 Cold App Start (No Session)

**Linear Execution:**

1. **Flutter Widget:** `main()` function
   - **File:** `lib/main.dart:16-89`
   - **Action:** Same as 2.1

2. **State Transition:** `AuthFlowNotifier.initializeSession()`
   - **File:** `lib/services/auth_flow_notifier.dart:26-41`
   - **Action:** `currentSession` is null
   - **State Change:** `setUnauthenticated()`

3. **Supabase Call:** Session check (synchronous)
   - **Type:** Auth read
   - **Location:** `lib/services/auth_flow_notifier.dart:28`

4. **Database Effect:** None

5. **UI Outcome:** `AuthGate.build()` executes
   - **File:** `lib/main.dart:346-398`
   - **Action:** `authFlow.state == AuthFlowState.unauthenticated`
   - **Returns:** `LoginScreen(key: ValueKey('login_screen'))`

**No async boundaries in this flow.**

---

### 2.3 Customer Login (OTP → PIN → Dashboard)

**Linear Execution:**

1. **Flutter Widget:** `LoginScreen`
   - **File:** `lib/screens/login_screen.dart:159-213`
   - **Action:** User enters phone, taps "Get OTP"

2. **Supabase Call:** `AuthService.sendOTP()`
   - **Type:** Auth API
   - **Location:** `lib/services/auth_service.dart:9-20`
   - **Call:** `_supabase.auth.signInWithOtp(phone: formattedPhone)`

3. **Database Effect:** None (OTP sent via Supabase Auth)

4. **UI Outcome:** `Navigator.push()` to `OTPScreen`
   - **File:** `lib/screens/login_screen.dart:195-203`
   - **Action:** Imperative navigation (not declarative)

5. **Flutter Widget:** `OTPScreen`
   - **File:** `lib/screens/otp_screen.dart`
   - **Action:** User enters OTP

6. **Supabase Call:** `AuthService.verifyOTP()`
   - **Type:** Auth API
   - **Location:** `lib/services/auth_service.dart:23-42`
   - **Call:** `_supabase.auth.verifyOTP(phone, token, type: OtpType.sms)`

7. **Database Effect:** Supabase Auth creates session in `auth.users`

8. **Supabase Event:** `onAuthStateChange` emits `signedIn`
   - **File:** `lib/main.dart:51-81`
   - **Action:** Listener executes

9. **Supabase Call:** `RoleRoutingService.checkMobileAppAccess()`
   - **Type:** Database read
   - **Location:** `lib/main.dart:58`, `lib/services/role_routing_service.dart:79-151`
   - **Queries:** `profiles.select('id, role, active')`, `staff_metadata.select('staff_type')` (if staff)

10. **Database Effect:** RLS policies evaluated
    - **File:** `supabase_schema.sql:685-688` (profiles), `supabase_schema.sql:771-780` (staff_metadata)

11. **State Transition:** `authFlowNotifier.setAuthenticated()`
    - **File:** `lib/main.dart:68`, `lib/services/auth_flow_notifier.dart:65-79`
    - **Action:** Updates `_state = AuthFlowState.authenticated`, calls `notifyListeners()`

12. **Flutter Widget:** `OTPScreen` checks PIN status
    - **File:** `lib/screens/otp_screen.dart:222-243`
    - **Action:** Calls `SecureStorageHelper.isPinSet()`

13. **State Transition:** If PIN not set → `authFlow.setOtpVerified()`
    - **File:** `lib/screens/otp_screen.dart:228-231`
    - **Action:** Updates state to `otpVerifiedNeedsPin`

14. **UI Outcome:** `AuthGate.build()` returns `PinSetupScreen`
    - **File:** `lib/main.dart:360-367`

15. **Flutter Widget:** `PinSetupScreen`
    - **File:** `lib/screens/auth/pin_setup_screen.dart`
    - **Action:** User sets PIN

16. **State Transition:** `authFlow.setAuthenticated()`
    - **File:** `lib/screens/auth/pin_setup_screen.dart:99-109`
    - **Action:** Updates state to `authenticated`

17. **UI Outcome:** `AuthGate.build()` detects authenticated state
    - **File:** `lib/main.dart:369-396`
    - **Action:** `_roleBasedScreen == null`, schedules `_checkRoleIfNeeded()`

18. **State Transition:** `_checkRoleAndRoute()` executes
    - **File:** `lib/main.dart:204-343`
    - **Action:** Fetches role, creates `DashboardScreen`

19. **UI Outcome:** `AuthGate` returns `DashboardScreen`
    - **File:** `lib/main.dart:307-312`

**Async Boundaries:**
- OTP verification (step 6) is async
- Access check (step 9) is async
- Role fetch (step 18) is async
- Race condition: `setAuthenticated()` (step 11) and `OTPScreen` PIN check (step 12) may execute in parallel

---

### 2.4 Staff Login

**Linear Execution:**

1. **Flutter Widget:** `LoginScreen`
   - **File:** `lib/screens/login_screen.dart:559-566`
   - **Action:** User taps "Staff Login" button

2. **State Transition:** `authFlow.goToStaffLogin()`
   - **File:** `lib/screens/login_screen.dart:565`, `lib/services/auth_flow_notifier.dart:82-114`
   - **Action:** Updates `_state = AuthFlowState.staffLogin`, calls `notifyListeners()`

3. **UI Outcome:** `AuthGate.build()` returns `StaffLoginScreen`
   - **File:** `lib/main.dart:356-358`

4. **Flutter Widget:** `StaffLoginScreen`
   - **File:** `lib/screens/staff/staff_login_screen.dart:41-109`
   - **Action:** User enters staff code and password

5. **Supabase Call:** `StaffAuthService.signInWithStaffCode()`
   - **Type:** RPC + Auth API
   - **Location:** `lib/services/staff_auth_service.dart:17-70`
   - **Step 1:** `_client.rpc('get_staff_email_by_code', params: {'staff_code_param': staffCode.toUpperCase()})`
   - **Step 2:** `_client.auth.signInWithPassword(email: email, password: password)`

6. **Database Effect:** RPC function `get_staff_email_by_code` executes
   - **File:** `supabase_schema.sql:639-651`
   - **Tables Affected:** `staff_metadata`, `profiles`
   - **RLS:** Bypassed (SECURITY DEFINER)

7. **Database Effect:** Supabase Auth creates session

8. **Supabase Event:** `onAuthStateChange` emits `signedIn`
   - **File:** `lib/main.dart:51-81`

9. **Supabase Call:** `RoleRoutingService.checkMobileAppAccess()`
   - **Type:** Database read
   - **Location:** `lib/main.dart:58`, `lib/services/role_routing_service.dart:79-151`
   - **Queries:** `profiles.select('id, role, active')`, `staff_metadata.select('staff_type')`

10. **Database Effect:** RLS policies evaluated
    - **File:** `supabase_schema.sql:685-688` (profiles), `supabase_schema.sql:771-780` (staff_metadata)

11. **State Transition:** `authFlowNotifier.setAuthenticated()`
    - **File:** `lib/main.dart:68`, `lib/services/auth_flow_notifier.dart:65-79`

12. **UI Outcome:** `AuthGate.build()` schedules `_checkRoleAndRoute()`
    - **File:** `lib/main.dart:369-396`

13. **State Transition:** `_checkRoleAndRoute()` executes
    - **File:** `lib/main.dart:204-343`
    - **Action:** Fetches role, creates `StaffDashboard(staffId: profileId)`

14. **UI Outcome:** `AuthGate` returns `StaffDashboard`
    - **File:** `lib/main.dart:283-285`

**Async Boundaries:**
- RPC call (step 5) is async
- Auth sign-in (step 5) is async
- Access check (step 9) is async
- Role fetch (step 13) is async

---

### 2.5 Payment / Collection Submission

**Linear Execution:**

1. **Flutter Widget:** `CollectPaymentScreen`
   - **File:** `lib/screens/staff/collect_payment_screen.dart`
   - **Action:** Staff enters amount, selects payment method

2. **Supabase Call:** `PaymentService.getCurrentMarketRate()`
   - **Type:** Database read
   - **Location:** `lib/services/payment_service.dart:12-30`
   - **Query:** `market_rates.select('price_per_gram').eq('asset_type', assetType).order('rate_date', ascending: false).limit(1)`
   - **Tables Affected:** `market_rates`

3. **Database Effect:** RLS policy "Everyone can read market rates" evaluated
   - **File:** `supabase_schema.sql:940-942`

4. **Supabase Call:** `PaymentService.getUserSchemeId()`
   - **Type:** Database read
   - **Location:** `lib/services/payment_service.dart:33-63`
   - **Query:** `user_schemes.select('id').eq('customer_id', customerId).eq('status', 'active')`
   - **Tables Affected:** `user_schemes`

5. **Database Effect:** RLS policy "Staff can read assigned customer schemes" evaluated
   - **File:** `supabase_schema.sql:832-839`

6. **Supabase Call:** `PaymentService.insertPayment()`
   - **Type:** Database write
   - **Location:** `lib/services/payment_service.dart:118-207`, `lib/services/payment_service.dart:185`
   - **Query:** `payments.insert({...})`
   - **Tables Affected:** `payments`

7. **Database Effect:** RLS policy "Staff can insert payments for assigned customers" evaluated
   - **File:** `supabase_schema.sql:862-872`
   - **Function:** `is_current_staff_assigned_to_customer(customer_id)` called
   - **File:** `supabase_schema.sql:623-632`

8. **Database Effect:** Trigger `trigger_update_user_scheme_totals` fires
   - **File:** `supabase_schema.sql:503-507`
   - **Function:** `update_user_scheme_totals()` executes
   - **File:** `supabase_schema.sql:448-500`
   - **Action:** Updates `user_schemes.total_amount_paid`, `payments_made`, `accumulated_grams`

9. **Database Effect:** Trigger attempts UPDATE on `user_schemes`
   - **File:** `supabase_schema.sql:480-486`
   - **RLS:** Policy "Customers can read own schemes" evaluated (UPDATE not explicitly allowed for staff)
   - **Issue:** UPDATE may fail if RLS blocks staff from updating `user_schemes`

10. **UI Outcome:** `Navigator.pop(context, true)`
    - **File:** `lib/screens/staff/collect_payment_screen.dart:172`
    - **Action:** Returns to previous screen with refresh flag

**Async Boundaries:**
- Market rate fetch (step 2) is async
- Scheme ID fetch (step 4) is async
- Payment insert (step 6) is async
- Trigger execution (step 8) is synchronous within transaction

**Race Conditions:**
- Multiple payments for same customer may update `user_schemes` concurrently
- Market rate may change between fetch and insert

---

### 2.6 Logout

**Linear Execution:**

1. **Flutter Widget:** Any authenticated screen (e.g., `ProfileScreen`, `StaffProfileScreen`)
   - **File:** `lib/screens/customer/profile_screen.dart:671`, `lib/screens/staff/staff_profile_screen.dart:334`
   - **Action:** User taps logout button

2. **Supabase Call:** `Supabase.instance.client.auth.signOut()`
   - **Type:** Auth API
   - **Location:** `lib/screens/customer/profile_screen.dart:671`, `lib/services/auth_service.dart:50-52`

3. **Database Effect:** Supabase Auth removes session from `auth.users`

4. **Supabase Event:** `onAuthStateChange` emits `signedOut`
   - **File:** `lib/main.dart:76-80`

5. **State Transition:** `authFlowNotifier.forceLogout()`
   - **File:** `lib/main.dart:79`, `lib/services/auth_flow_notifier.dart:118-133`
   - **Action:** Updates `_state = AuthFlowState.unauthenticated`, clears all temp state, calls `notifyListeners()`

6. **UI Outcome:** `AuthGate.build()` executes
   - **File:** `lib/main.dart:346-398`
   - **Action:** `authFlow.state == AuthFlowState.unauthenticated`
   - **Returns:** `LoginScreen(key: ValueKey('login_screen'))`

7. **State Transition:** `_checkRoleIfNeeded()` resets `_roleBasedScreen = null`
   - **File:** `lib/main.dart:173-182`
   - **Action:** Detects logout, clears cached screen

**Async Boundaries:**
- Sign out (step 2) is async
- Event propagation (step 4) is async

**Issue Identified:**
- `_roleBasedScreen` may not be reset if `_checkRoleIfNeeded()` doesn't execute
- Manual listener `_forceRebuild()` may call `setState()` on unmounted State

---

### 2.7 Login After Logout

**Linear Execution:**

1. **Flutter Widget:** `LoginScreen` (after logout)
   - **File:** `lib/screens/login_screen.dart`
   - **Action:** User enters phone, taps "Get OTP"

2. **Supabase Call:** `AuthService.sendOTP()`
   - **Type:** Auth API
   - **Location:** `lib/services/auth_service.dart:9-20`

3. **UI Outcome:** `Navigator.push()` to `OTPScreen`
   - **File:** `lib/screens/login_screen.dart:195-203`

4. **Flutter Widget:** `OTPScreen`
   - **Action:** User enters OTP

5. **Supabase Call:** `AuthService.verifyOTP()`
   - **Type:** Auth API
   - **Location:** `lib/services/auth_service.dart:23-42`

6. **Supabase Event:** `onAuthStateChange` emits `signedIn`
   - **File:** `lib/main.dart:51-81`

7. **State Transition:** `authFlowNotifier.setAuthenticated()`
   - **File:** `lib/main.dart:68`

8. **UI Outcome:** `AuthGate.build()` executes
   - **File:** `lib/main.dart:346-398`
   - **Issue:** `_roleBasedScreen` may still be null from previous logout
   - **Action:** Schedules `_checkRoleIfNeeded()` via `addPostFrameCallback`

9. **State Transition:** `_checkRoleAndRoute()` executes
   - **File:** `lib/main.dart:204-343`
   - **Action:** Fetches role, creates target screen

10. **UI Outcome:** `AuthGate` returns target screen
    - **File:** `lib/main.dart:307-312`

**Issue Identified:**
- `AuthGate.build()` may not execute if manual listener fails
- `_forceRebuild()` may call `setState()` on unmounted State
- Element ownership may change, causing rebuild suppression

---

### 2.8 Session Expiry / Token Refresh

**Linear Execution:**

1. **Supabase Event:** `onAuthStateChange` emits `tokenRefreshed` or `signedOut`
   - **File:** `lib/main.dart:51-81`
   - **Action:** Supabase SDK manages token lifecycle

2. **State Transition:** If `signedOut` → `authFlowNotifier.forceLogout()`
   - **File:** `lib/main.dart:76-80`
   - **Action:** Updates state to `unauthenticated`

3. **UI Outcome:** `AuthGate.build()` returns `LoginScreen`
   - **File:** `lib/main.dart:352-354`

**Async Boundaries:**
- Token refresh is handled by Supabase SDK (background)
- Event propagation is async

---

## 3️⃣ DOMAIN DATA FLOW (SOURCE OF TRUTH EXPLICIT) {#3-domain-data-flow}

### 3.1 Auth Domain

| Aspect | Details |
|--------|---------|
| **Source of truth** | Supabase Auth (`auth.users` table) - `lib/main.dart:51` (onAuthStateChange listener) |
| **Write authority** | Supabase Auth SDK - `lib/services/auth_service.dart:14` (signInWithOtp), `lib/services/staff_auth_service.dart:48` (signInWithPassword) |
| **Read authority** | `Supabase.instance.client.auth.currentSession` - `lib/services/auth_flow_notifier.dart:28` |
| **Validation location** | Database RLS (implicit via Supabase Auth) + Flutter service layer - `lib/services/role_routing_service.dart:79-151` (checkMobileAppAccess) |
| **Client assumptions** | Session persists across app restarts - `lib/services/auth_flow_notifier.dart:26-41` (initializeSession) |
| **RLS involvement** | None (Supabase Auth is separate from public schema) |
| **Offline implications** | Session cached by Supabase SDK, validated on next network request |
| **Failure behavior** | `signOut()` called, `forceLogout()` executed - `lib/main.dart:64, 74, 79` |

---

### 3.2 Staff Domain

| Aspect | Details |
|--------|---------|
| **Source of truth** | `profiles` table (role='staff') + `staff_metadata` table - `lib/services/staff_data_service.dart:551-590` (getStaffProfile) |
| **Write authority** | Admin only (via RLS) - `supabase_schema.sql:789-792` |
| **Read authority** | Staff can read own metadata - `supabase_schema.sql:771-780`, Staff can read assigned customer profiles - `supabase_schema.sql:694-708` |
| **Validation location** | Database RLS - `supabase_schema.sql:771-792` (staff_metadata policies) |
| **Client assumptions** | `staff_type='collection'` required for mobile app access - `lib/services/role_routing_service.dart:133-140` |
| **RLS involvement** | All queries protected - `supabase_schema.sql:771-792` |
| **Offline implications** | Staff data cached in widget state - `lib/screens/staff/staff_dashboard.dart:49-57` |
| **Failure behavior** | Access denied → logout - `lib/services/role_routing_service.dart:137-139` |

---

### 3.3 Customers Domain

| Aspect | Details |
|--------|---------|
| **Source of truth** | `customers` table + `profiles` table - `lib/services/staff_data_service.dart:29-191` (getAssignedCustomers) |
| **Write authority** | Customers can update own record - `supabase_schema.sql:738-741`, Staff cannot write customers |
| **Read authority** | Customers read own - `supabase_schema.sql:730-735`, Staff read assigned - `supabase_schema.sql:744-751` |
| **Validation location** | Database RLS - `supabase_schema.sql:730-757` |
| **Client assumptions** | Customer must have active `user_schemes` for payment flow - `lib/services/staff_data_service.dart:116-119` |
| **RLS involvement** | All queries protected - `supabase_schema.sql:730-757` |
| **Offline implications** | Customer list cached in widget state - `lib/screens/staff/collect_tab_screen.dart:86` |
| **Failure behavior** | Customer skipped if no profile or scheme - `lib/services/staff_data_service.dart:99-102, 116-119` |

---

### 3.4 Payments Domain

| Aspect | Details |
|--------|---------|
| **Source of truth** | `payments` table (append-only) - `lib/services/payment_service.dart:185` (insert) |
| **Write authority** | Staff can insert for assigned customers - `supabase_schema.sql:862-872` |
| **Read authority** | Customers read own - `supabase_schema.sql:851-858`, Staff read assigned - `supabase_schema.sql:875-882` |
| **Validation location** | Database triggers + RLS - `supabase_schema.sql:503-507` (trigger), `supabase_schema.sql:862-872` (RLS) |
| **Client assumptions** | Market rate fetched at payment time - `lib/services/payment_service.dart:12-30`, GST calculated client-side (3%) - `lib/services/payment_service.dart:171-172` |
| **RLS involvement** | INSERT policy uses `is_current_staff_assigned_to_customer()` - `supabase_schema.sql:862-872` |
| **Offline implications** | Payment cannot be recorded offline (requires database write) |
| **Failure behavior** | Exception thrown, payment not recorded - `lib/services/payment_service.dart:203-206` |

**Critical Issue:**
- Trigger `update_user_scheme_totals()` attempts UPDATE on `user_schemes` - `supabase_schema.sql:480-486`
- RLS may block UPDATE if staff doesn't have UPDATE permission - `CURRENT_STATUS_UPDATE.md:24-53`

---

### 3.5 Collections Domain

| Aspect | Details |
|--------|---------|
| **Source of truth** | `payments` table (aggregated) - `lib/services/staff_data_service.dart:194-287` (getTodayStats) |
| **Write authority** | Derived from payments (no direct writes) |
| **Read authority** | Staff read own collections - `lib/services/staff_data_service.dart:199-204` (payments WHERE staff_id = X) |
| **Validation location** | Client-side aggregation - `lib/services/staff_data_service.dart:206-281` |
| **Client assumptions** | Today's date calculated client-side - `lib/services/staff_data_service.dart:196` |
| **RLS involvement** | Inherited from payments table RLS |
| **Offline implications** | Collections calculated from cached payment data |
| **Failure behavior** | Returns empty stats if query fails - `lib/services/staff_data_service.dart:282-286` |

---

### 3.6 Audits Domain

| Aspect | Details |
|--------|---------|
| **Source of truth** | `payments` table (append-only, immutable) - `supabase_schema.sql:231-273` |
| **Write authority** | Staff can insert (no UPDATE/DELETE) - `supabase_schema.sql:513-530` (triggers prevent modification) |
| **Read authority** | Customers read own, Staff read assigned, Admin read all - `supabase_schema.sql:851-887` |
| **Validation location** | Database triggers enforce immutability - `supabase_schema.sql:513-530` |
| **Client assumptions** | Payments are never modified (reversals are new inserts with `is_reversal=true`) - `supabase_schema.sql:248-250` |
| **RLS involvement** | All reads protected - `supabase_schema.sql:851-887` |
| **Offline implications** | Audit trail only exists after successful database write |
| **Failure behavior** | Payment insert fails, no audit record created |

---

### 3.7 Reports Domain

| Aspect | Details |
|--------|---------|
| **Source of truth** | Database views + client aggregation - `supabase_schema.sql:1006-1032` (today_collections view), `lib/services/staff_data_service.dart:194-287` (client aggregation) |
| **Write authority** | Derived (no direct writes) |
| **Read authority** | Staff read own reports - `lib/services/staff_data_service.dart:194-287` |
| **Validation location** | Client-side aggregation - `lib/services/staff_data_service.dart:206-281` |
| **Client assumptions** | Today's date is correct, payment status is 'completed' - `lib/services/staff_data_service.dart:196, 204` |
| **RLS involvement** | Inherited from underlying tables |
| **Offline implications** | Reports calculated from cached data |
| **Failure behavior** | Returns empty/zero stats if query fails - `lib/services/staff_data_service.dart:282-286` |

---

## 4️⃣ BACKEND SURFACE AREA (COMPLETE) {#4-backend-surface}

### 4.1 Supabase Auth Events

| Interface | Type | Auth Context | Tables Affected | Called From |
|-----------|------|--------------|-----------------|-------------|
| `onAuthStateChange` | Stream | None (listener) | None (auth.users only) | `lib/main.dart:51` (main function) |
| `signInWithOtp` | Auth API | Unauthenticated | None | `lib/services/auth_service.dart:14` |
| `verifyOTP` | Auth API | Unauthenticated | None | `lib/services/auth_service.dart:28` |
| `signInWithPassword` | Auth API | Unauthenticated | None | `lib/services/staff_auth_service.dart:48` |
| `signOut` | Auth API | Authenticated | None | `lib/services/auth_service.dart:51`, `lib/main.dart:64, 74, 226, 248, 266, 320` |
| `currentSession` | Auth read | Any | None | `lib/services/auth_flow_notifier.dart:28`, `lib/services/role_routing_service.dart:82, 48` |

---

### 4.2 Direct DB Reads/Writes from Flutter

| Interface | Type | Auth Context | Tables Affected | Called From |
|-----------|------|--------------|-----------------|-------------|
| `profiles.select()` | DB read | Authenticated | `profiles` | `lib/main.dart:238`, `lib/services/role_routing_service.dart:21, 101, 160, 214`, `lib/services/staff_data_service.dart:15, 93, 554` |
| `profiles.select()` (staff read customer) | DB read | Authenticated (staff) | `profiles` | `lib/services/staff_data_service.dart:93-97` |
| `customers.select()` | DB read | Authenticated | `customers` | `lib/services/staff_data_service.dart:60-75` |
| `staff_metadata.select()` | DB read | Authenticated | `staff_metadata` | `lib/services/role_routing_service.dart:60`, `lib/services/staff_data_service.dart:482, 595` |
| `user_schemes.select()` | DB read | Authenticated | `user_schemes` | `lib/services/payment_service.dart:36, 50`, `lib/services/staff_data_service.dart:107, 236, 317` |
| `user_schemes.select()` (customer) | DB read | Authenticated (customer) | `user_schemes` | `lib/screens/customer/dashboard_screen.dart:1384` |
| `schemes.select()` | DB read | Authenticated | `schemes` | `lib/services/staff_data_service.dart:124` |
| `payments.select()` | DB read | Authenticated | `payments` | `lib/services/staff_data_service.dart:139, 199, 294, 349` |
| `payments.insert()` | DB write | Authenticated (staff) | `payments` | `lib/services/payment_service.dart:185` |
| `market_rates.select()` | DB read | Authenticated | `market_rates` | `lib/services/payment_service.dart:14` |
| `staff_assignments.select()` | DB read | Authenticated (staff) | `staff_assignments` | `lib/services/staff_data_service.dart:34, 224`, `lib/services/payment_service.dart:160` |
| `users.select()` (legacy) | DB read | Unauthenticated | `users` (legacy table, may not exist) | `lib/screens/login_screen.dart:174`, `lib/screens/otp_screen.dart:143` |
| `staff.select()` (legacy) | DB read | Unauthenticated | `staff` (legacy table, may not exist) | `lib/screens/staff/staff_pin_setup_screen.dart:206` |

---

### 4.3 RPC Calls

| Interface | Type | Auth Context | Tables Affected | Called From |
|-----------|------|--------------|-----------------|-------------|
| `get_staff_email_by_code` | RPC (SECURITY DEFINER) | Unauthenticated | `staff_metadata`, `profiles` | `lib/services/staff_auth_service.dart:25-28` |

**Note:** All other database functions are called internally by triggers or RLS policies, not directly from Flutter code.

**Database Functions (Internal Use Only):**
- `get_user_profile()` - `supabase_schema.sql:575-578` - Used by RLS policies
- `get_user_role()` - `supabase_schema.sql:583-586` - Used by RLS policies
- `is_admin()` - `supabase_schema.sql:591-594` - Used by RLS policies
- `is_staff()` - `supabase_schema.sql:599-602` - Used by RLS policies
- `is_staff_assigned_to_customer()` - `supabase_schema.sql:607-617` - Used by RLS policies
- `is_current_staff_assigned_to_customer()` - `supabase_schema.sql:623-632` - Used by RLS policies (payment INSERT)
- `get_customer_profile_for_staff()` - `supabase_schema.sql:659-675` - Not currently called from Flutter
- `update_updated_at_column()` - `supabase_schema.sql:399-405` - Trigger function
- `update_user_scheme_totals()` - `supabase_schema.sql:448-500` - Trigger function (fires on payment INSERT)
- `prevent_payment_modification()` - `supabase_schema.sql:513-530` - Trigger function (prevents UPDATE/DELETE)
- `generate_receipt_number()` - `supabase_schema.sql:536-548` - Trigger function (fires on payment INSERT)

---

### 4.4 Edge Functions

**Status:** None found in codebase

**Evidence:** No references to `functions.invoke()` or Edge Function calls

---

### 4.5 Scheduled Jobs / Cron

**Status:** None found in codebase

**Evidence:** No references to scheduled jobs or cron in Flutter code

**Note:** Database may have scheduled jobs defined in Supabase dashboard (not in codebase)

---

### 4.6 Realtime Subscriptions

**Status:** None found in codebase

**Evidence:** No `.stream()` calls on Supabase tables, no `.subscribe()` calls

**Note:** `onAuthStateChange` is auth stream, not database realtime

---

### 4.7 Storage (Supabase Storage)

**Status:** Commented out / not in use

**Evidence:** 
- `lib/screens/customer/profile_screen.dart:57-58` - Commented-out avatar upload code
- No active storage operations found

**Intended Use:** Avatar image storage (not implemented)

---

### 4.8 Database Views

**Status:** Defined in schema but not directly queried from Flutter

**Views Defined:**
- `active_customer_schemes` - `supabase_schema.sql:977-1001` - Active schemes with customer details
- `today_collections` - `supabase_schema.sql:1006-1031` - Today's completed payments
- `staff_daily_stats` - `supabase_schema.sql:1036-1053` - Daily statistics by staff

**Usage:** Views exist but Flutter code performs client-side aggregation instead of querying views directly

**Evidence:** `lib/services/staff_data_service.dart:194-287` performs client-side aggregation rather than querying `today_collections` or `staff_daily_stats` views

---

### 4.9 Legacy Tables

**Status:** Referenced but may not exist in current schema

**Legacy Table Queries:**
- `users` table - `lib/screens/login_screen.dart:174`, `lib/screens/otp_screen.dart:143`
- **Note:** These queries may fail if `users` table doesn't exist (replaced by `profiles` table)

---

## 5️⃣ DATABASE SCHEMA + RLS INTENT (FINANCIAL FOCUS) {#5-database-schema}

| Table | Purpose | Mutability | Who Writes | Who Reads | RLS Guarantee |
|-------|---------|------------|------------|-----------|---------------|
| **profiles** | User profiles linked to Supabase Auth | Mutable (UPDATE allowed) | Users (own), Admin (all) | Users (own), Staff (assigned customers), Admin (all) | `supabase_schema.sql:685-724` - Users read own, Staff read assigned customers, Admin read all |
| **customers** | Customer-specific data (KYC) | Mutable (UPDATE allowed) | Customers (own), Admin (all) | Customers (own), Staff (assigned), Admin (all) | `supabase_schema.sql:730-757` - Customers read/update own, Staff read assigned, Admin all |
| **staff_metadata** | Staff-specific metadata | Mutable (UPDATE allowed) | Staff (own), Admin (all) | Staff (own), Admin (all), Unauthenticated (staff_code lookup only) | `supabase_schema.sql:764-792` - Staff read own, Admin all, Unauthenticated can lookup staff_code for login |
| **schemes** | Investment scheme definitions | Immutable (admin creates, never updates) | Admin only | Everyone (active schemes), Staff (all) | `supabase_schema.sql:798-806` - Everyone read active, Staff read all, Admin manage |
| **user_schemes** | Customer enrollments | Mutable (UPDATE via triggers only) | Customers (enroll), Admin (all), Triggers (UPDATE totals) | Customers (own), Staff (assigned), Admin (all) | `supabase_schema.sql:812-845` - Customers read/enroll own, Staff read assigned, Admin all, **UPDATE blocked for staff (triggers may fail)** |
| **payments** | Payment records (audit trail) | **APPEND-ONLY** (immutable) | Staff (INSERT for assigned), Admin (INSERT) | Customers (own), Staff (assigned), Admin (all) | `supabase_schema.sql:851-887` - Customers read own, Staff insert/read assigned, Admin all, **UPDATE/DELETE prevented by triggers** |
| **market_rates** | Daily metal rates | Mutable (admin updates daily) | Admin only | Everyone | `supabase_schema.sql:940-951` - Everyone read, Admin manage |
| **staff_assignments** | Staff-customer assignments | Mutable (admin manages) | Admin only | Staff (own), Admin (all) | `supabase_schema.sql:957-968` - Staff read own, Admin all |
| **withdrawals** | Withdrawal requests | Mutable (status updates) | Customers (INSERT), Staff (UPDATE status), Admin (all) | Customers (own), Staff (assigned), Admin (all) | `supabase_schema.sql:896-934` - Customers read/request own, Staff read/update assigned, Admin all |

**Append-Only Tables:**
- **payments:** Enforced by triggers `prevent_payment_update` and `prevent_payment_delete` - `supabase_schema.sql:521-530`

**Implicit Trust Assumptions:**
- Staff code lookup (`get_staff_email_by_code`) trusts unauthenticated requests - `supabase_schema.sql:764-766`
- Market rates are trusted (no validation of rate_date) - `supabase_schema.sql:940-942`

**Multi-Table Invariants:**
- `payments.staff_id` must reference `profiles.id` where `profiles.role='staff'` - `supabase_schema.sql:235`
- `payments.customer_id` must reference `customers.id` - `supabase_schema.sql:234`
- `payments.user_scheme_id` must reference `user_schemes.id` - `supabase_schema.sql:233`
- `user_schemes.customer_id` must reference `customers.id` - `supabase_schema.sql:188`
- `customers.profile_id` must reference `profiles.id` - `supabase_schema.sql:91`
- `staff_metadata.profile_id` must reference `profiles.id` where `profiles.role='staff'` - `supabase_schema.sql:121`

**Enforcement Gaps:**
- Staff cannot UPDATE `user_schemes` directly, but trigger `update_user_scheme_totals()` attempts UPDATE - `supabase_schema.sql:480-486`, `CURRENT_STATUS_UPDATE.md:24-53`
- Function `update_user_scheme_totals()` is not SECURITY DEFINER, so it runs with caller's permissions - `supabase_schema.sql:448-500`

---

## 6️⃣ STATE INVENTORY (CLIENT + BACKEND) {#6-state-inventory}

### 6.1 Client State

| State | Owner | Lifecycle | Reset Trigger |
|-------|-------|-----------|---------------|
| `AuthFlowNotifier._state` | Provider (ChangeNotifier) | Always alive (created in main) | `forceLogout()`, `setUnauthenticated()` - `lib/services/auth_flow_notifier.dart:118-133, 136-150` |
| `AuthFlowNotifier._phoneNumber` | Provider (ChangeNotifier) | Always alive | Cleared on `setAuthenticated()`, `forceLogout()` - `lib/services/auth_flow_notifier.dart:74, 125` |
| `AuthFlowNotifier._isFirstTime` | Provider (ChangeNotifier) | Always alive | Cleared on `setAuthenticated()`, `forceLogout()` - `lib/services/auth_flow_notifier.dart:75, 126` |
| `AuthFlowNotifier._isResetPin` | Provider (ChangeNotifier) | Always alive | Cleared on `setAuthenticated()`, `forceLogout()` - `lib/services/auth_flow_notifier.dart:76, 127` |
| `AuthGate._roleBasedScreen` | StatefulWidget state | Widget lifecycle | Reset to null on logout - `lib/main.dart:178` |
| `AuthGate._isCheckingRole` | StatefulWidget state | Widget lifecycle | Reset to false after role check - `lib/main.dart:212, 310` |
| `AuthGate._lastState` | StatefulWidget state | Widget lifecycle | Updated on state change - `lib/main.dart:193, 197, 200` |
| `LoginScreen._phoneController` | StatefulWidget state | Widget lifecycle | Disposed on widget disposal - `lib/screens/login_screen.dart:68` |
| `LoginScreen._isLoading` | StatefulWidget state | Widget lifecycle | Reset to false after operation - `lib/screens/login_screen.dart:204-206` |
| `OTPScreen._controllers` (6 OTP boxes) | StatefulWidget state | Widget lifecycle | Disposed on widget disposal - `lib/screens/otp_screen.dart:37-38` |
| `StaffDashboard._staffData` | StatefulWidget state | Widget lifecycle | Loaded in `initState()` - `lib/screens/staff/staff_dashboard.dart:49-57` |
| `StaffDashboard._isLoading` | StatefulWidget state | Widget lifecycle | Reset to false after load - `lib/screens/staff/staff_dashboard.dart:51` |
| `CollectTabScreen._customers` | StatefulWidget state | Widget lifecycle | Loaded in `_loadData()` - `lib/screens/staff/collect_tab_screen.dart:86` |
| `CollectTabScreen._isLoading` | StatefulWidget state | Widget lifecycle | Reset to false after load - `lib/screens/staff/collect_tab_screen.dart:61, 68` |
| `CollectPaymentScreen._amountController` | StatefulWidget state | Widget lifecycle | Disposed on widget disposal - `lib/screens/staff/collect_payment_screen.dart:23` |
| `CollectPaymentScreen._isLoading` | StatefulWidget state | Widget lifecycle | Reset to false after operation - `lib/screens/staff/collect_payment_screen.dart:152` |
| Navigation stack | Flutter Navigator | MaterialApp lifecycle | Cleared on `pushAndRemoveUntil` - `lib/services/role_routing_service.dart:191-194, 205-208, 223-226, 238-241, 261-264, 271-274` |
| Cached payment data | Widget state | Widget lifecycle | Refreshed on pull-to-refresh or screen rebuild |

---

### 6.2 Backend State

| State | Owner | Lifecycle | Reset Trigger |
|-------|-------|-----------|---------------|
| Supabase session | Supabase Auth SDK | Persists across app restarts | `signOut()` - `lib/services/auth_service.dart:50-52` |
| `auth.users` record | Supabase Auth | Permanent (until deleted) | Admin deletion |
| `profiles` record | PostgreSQL | Permanent (until deleted) | CASCADE DELETE from `auth.users` - `supabase_schema.sql:61` |
| `user_schemes.total_amount_paid` | PostgreSQL (derived) | Updated by trigger | Payment INSERT trigger - `supabase_schema.sql:482` |
| `user_schemes.payments_made` | PostgreSQL (derived) | Updated by trigger | Payment INSERT trigger - `supabase_schema.sql:483` |
| `user_schemes.accumulated_grams` | PostgreSQL (derived) | Updated by trigger | Payment INSERT trigger - `supabase_schema.sql:484` |
| `market_rates` (latest rate) | PostgreSQL | Updated daily by admin | Admin INSERT - `supabase_schema.sql:345-357` |
| Receipt number sequence | PostgreSQL | Persistent | Auto-increment - `supabase_schema.sql:548` |

---

## 7️⃣ NAVIGATION & ROUTING AUTHORITY {#7-navigation}

**Who Decides Active Screen:**
- **Primary:** `AuthGate.build()` method - `lib/main.dart:346-398`
- **Secondary:** `Navigator.push/pop/pushReplacement` in various screens - `lib/screens/login_screen.dart:124, 195`, `lib/screens/otp_screen.dart:253, 286`, `lib/screens/auth/pin_login_screen.dart:149, 211`

**Where Routing Logic Lives:**
- **Declarative:** `AuthGate.build()` - `lib/main.dart:346-398` (returns widget based on `authFlow.state`)
- **Imperative:** Multiple screens use `Navigator` - `lib/screens/login_screen.dart:124, 195`, `lib/screens/otp_screen.dart:253, 286`, `lib/services/role_routing_service.dart:191-194, 271-274`
- **Role-based:** `AuthGate._checkRoleAndRoute()` - `lib/main.dart:204-343` (fetches role, creates screen)

**How Flutter Enforces It:**
- `MaterialApp.home` is set to `AuthGate()` - `lib/main.dart:109`
- `AuthGate` returns different widgets based on `authFlow.state` - `lib/main.dart:351-397`
- `Navigator` manages screen stack for imperative navigation

**Where Imperative Navigation Exists:**
- `LoginScreen` → `OTPScreen`: `Navigator.push()` - `lib/screens/login_screen.dart:195-203`
- `LoginScreen` → `PinLoginScreen`: `Navigator.pushReplacement()` - `lib/screens/login_screen.dart:124-129`
- `OTPScreen` → `DashboardScreen`: `Navigator.pushAndRemoveUntil()` - `lib/screens/otp_screen.dart:253, 286`
- `PinLoginScreen` → `DashboardScreen`: `Navigator.pushReplacement()` - `lib/screens/auth/pin_login_screen.dart:149`
- `PinLoginScreen` → `OTPScreen`: `Navigator.pushReplacement()` - `lib/screens/auth/pin_login_screen.dart:198`
- `RoleRoutingService.navigateByRole()`: `Navigator.pushAndRemoveUntil()` - `lib/services/role_routing_service.dart:191-194, 271-274`
- `ProfileScreen` → `LoginScreen` (logout): `Navigator.pushAndRemoveUntil()` - `lib/screens/customer/profile_screen.dart:671`
- `StaffProfileScreen` → `StaffLoginScreen` (logout): `Navigator.pushAndRemoveUntil()` - `lib/screens/staff/staff_profile_screen.dart:334`
- All detail screens use `Navigator.push()` for navigation (non-auth)

**Interaction with Auth/Session Changes:**
- `onAuthStateChange` listener calls `authFlowNotifier.setAuthenticated()` or `forceLogout()` - `lib/main.dart:51-81`
- `AuthGate.build()` reacts to `authFlow.state` changes via `Provider.of<AuthFlowNotifier>(context)` - `lib/main.dart:347`
- Manual listener `_forceRebuild()` attempts to force rebuild on `notifyListeners()` - `lib/main.dart:152-157`
- `_checkRoleIfNeeded()` resets `_roleBasedScreen = null` on logout - `lib/main.dart:173-182`

**Issue Identified:**
- Mixed declarative (AuthGate) and imperative (Navigator) navigation
- `Navigator.push()` creates navigation stack that may conflict with `AuthGate` declarative routing
- `_roleBasedScreen` cached state may not reset if `_checkRoleIfNeeded()` doesn't execute

---

## 8️⃣ FAILURE & EDGE-CASE MATRIX (OBSERVED BEHAVIOR) {#8-failure-matrix}

| Scenario | Observed Outcome | Stack Layer | Code Reference |
|----------|------------------|-------------|----------------|
| **Duplicate submit** | Payment insert succeeds, trigger updates `user_schemes` twice | Database trigger | `supabase_schema.sql:503-507` (trigger fires on every INSERT) |
| **Offline payment** | Payment insert fails with network error, no payment recorded | Flutter service | `lib/services/payment_service.dart:203-206` (exception thrown) |
| **Session desync** | `AuthFlowNotifier` state may not match Supabase session after logout → login | Flutter Provider | `lib/main.dart:51-81` (dual state sources), `lib/services/auth_flow_notifier.dart:26-41` (initializeSession) |
| **Staff revoked** | Staff with `staff_type='office'` logged out immediately after login | Flutter service | `lib/services/role_routing_service.dart:133-140` (checkMobileAppAccess) |
| **App killed mid-flow** | Payment insert may complete but UI doesn't reflect success | Flutter widget | `lib/screens/staff/collect_payment_screen.dart:152-173` (no persistence check) |
| **Payment INSERT blocked** | RLS policy blocks payment insert, exception thrown | Database RLS | `lib/services/payment_service.dart:203-206`, `supabase_schema.sql:862-872` |
| **Trigger UPDATE fails** | Payment INSERT succeeds but trigger fails to update `user_schemes` | Database trigger | `supabase_schema.sql:480-486`, `CURRENT_STATUS_UPDATE.md:24-53` |
| **Market rate missing** | Exception thrown, payment cannot be calculated | Flutter service | `lib/services/payment_service.dart:22-24` |
| **Role fetch fails** | `_checkRoleAndRoute()` catches exception, signs out user | Flutter widget | `lib/main.dart:314-342` |
| **Login after logout** | `AuthGate.build()` may not execute, `_roleBasedScreen` remains null | Flutter widget lifecycle | `lib/main.dart:346-398`, manual listener may fail - `lib/main.dart:152-157` |
| **Element ownership change** | `setState()` called on unmounted State, rebuild suppressed | Flutter widget lifecycle | `lib/main.dart:152-157` (`_forceRebuild()` may execute on disposed State) |

---

## 9️⃣ CROSS-LAYER CONTRADICTIONS & COUPLING {#9-cross-layer}

### 9.1 Competing Authorities Across Stack Layers

**Auth State:**
- **Supabase Auth:** Source of truth for session - `lib/main.dart:51` (onAuthStateChange)
- **AuthFlowNotifier:** UI state for flow control - `lib/services/auth_flow_notifier.dart:14-22`
- **Conflict:** Both control auth state, may desync - `lib/main.dart:51-81` (listener updates notifier)

**Navigation:**
- **AuthGate:** Declarative routing based on state - `lib/main.dart:346-398`
- **Navigator:** Imperative navigation in screens - `lib/screens/login_screen.dart:195-203`
- **Conflict:** Navigator creates stack that may conflict with AuthGate declarative routing

**Role Resolution:**
- **AuthGate._checkRoleAndRoute():** Widget-owned role fetch - `lib/main.dart:204-343`
- **RoleRoutingService:** Service layer role fetch - `lib/services/role_routing_service.dart:15-41`
- **Conflict:** Duplicate role fetch logic, different error handling

---

### 9.2 Widget Lifecycle Dependencies

**AuthGate State:**
- `_roleBasedScreen` cached in widget state - `lib/main.dart:122`
- `_isCheckingRole` flag in widget state - `lib/main.dart:123`
- **Issue:** State lost on widget disposal, may not reset on logout - `lib/main.dart:173-182`

**Manual Listener:**
- `authFlow.addListener(_forceRebuild)` in `initState()` - `lib/main.dart:133`
- `authFlow.removeListener(_forceRebuild)` in `dispose()` - `lib/main.dart:145`
- **Issue:** Listener may fire after widget disposal, `setState()` called on unmounted State - `lib/main.dart:152-157`

**PostFrameCallback:**
- `WidgetsBinding.instance.addPostFrameCallback` used for role checks - `lib/main.dart:135, 164, 375`
- **Issue:** Frame-dependent scheduling, may not execute if widget disposed

---

### 9.3 State That Crosses Boundaries Incorrectly

**Auth State:**
- Supabase session (backend) → `AuthFlowNotifier` (client) - `lib/main.dart:51-81`
- **Issue:** No synchronization guarantee, may desync

**Role Data:**
- Database role (backend) → `_roleBasedScreen` widget (client) - `lib/main.dart:204-343`
- **Issue:** Cached in widget state, not provider-owned

**Payment Data:**
- Database payments (backend) → Widget state (client) - `lib/screens/staff/collect_tab_screen.dart:86`
- **Issue:** No offline sync, data lost on widget disposal

---

### 9.4 Assumptions Enforced Only in UI

**Mobile App Access:**
- Enforced in Flutter service - `lib/services/role_routing_service.dart:79-151`
- **Issue:** Not enforced at database level, can be bypassed if service not called

**Staff Type Check:**
- Enforced in Flutter service - `lib/services/role_routing_service.dart:133-140`
- **Issue:** Database allows staff login, Flutter enforces `staff_type='collection'`

**Payment Amount Validation:**
- Client-side validation only - `lib/screens/staff/collect_payment_screen.dart:196-200`
- **Issue:** No database constraint on amount range

---

### 9.5 Places Where Flutter Substitutes Backend Logic

**GST Calculation:**
- Calculated client-side (3%) - `lib/services/payment_service.dart:171`
- **Issue:** Should be database constraint or function

**Metal Grams Calculation:**
- Calculated client-side - `lib/services/payment_service.dart:173`
- **Issue:** Also calculated in trigger - `supabase_schema.sql:473-475` (duplicate logic)

**Today's Date:**
- Calculated client-side - `lib/services/staff_data_service.dart:196`
- **Issue:** Timezone differences, should use database `CURRENT_DATE`

**Payment Statistics:**
- Aggregated client-side - `lib/services/staff_data_service.dart:206-281`
- **Issue:** Should use database views or functions

---

## 🔚 10️⃣ CANONICAL TRUTH STATEMENTS {#10-canonical-truth}

**Authentication:**
In the current system, the authoritative source of truth for authentication is Supabase Auth (`auth.users` table), enforced at the Supabase Auth layer. The `AuthFlowNotifier` (Provider) maintains UI state derived from Supabase Auth, but Supabase Auth is the ultimate authority. Evidence: `lib/main.dart:51` (onAuthStateChange listener), `lib/services/auth_flow_notifier.dart:26-41` (initializeSession reads from Supabase).

**Payments:**
In the current system, the authoritative source of truth for payments is the `payments` table (PostgreSQL), enforced at the database layer via RLS policies and append-only triggers. Payments are immutable (no UPDATE/DELETE allowed), and all payment records are permanent audit entries. Evidence: `supabase_schema.sql:231-273` (payments table), `supabase_schema.sql:513-530` (immutability triggers), `lib/services/payment_service.dart:185` (INSERT only).

**Audits:**
In the current system, the authoritative source of truth for audits is the `payments` table itself, as it is append-only and immutable. Every payment INSERT creates a permanent audit record that cannot be modified or deleted. Reversals are recorded as new payment entries with `is_reversal=true`. Evidence: `supabase_schema.sql:231-273` (payments table design), `supabase_schema.sql:248-250` (reversal fields), `supabase_schema.sql:513-530` (prevention triggers).

**Reports:**
In the current system, the authoritative source of truth for reports is client-side aggregation from the `payments` table. Database views (`active_customer_schemes`, `today_collections`, `staff_daily_stats`) exist in the schema but are not queried by Flutter code. Reports are computed on-demand via client-side aggregation, not stored. Evidence: `supabase_schema.sql:977-1053` (views defined but unused), `lib/services/staff_data_service.dart:194-287` (client aggregation used instead).

**Navigation:**
In the current system, the authoritative source of truth for navigation is split: `AuthGate.build()` provides declarative routing based on `AuthFlowNotifier` state, but multiple screens use imperative `Navigator` calls that create competing navigation stacks. The `AuthGate` widget owns the primary routing decision, but imperative navigation can bypass it. Evidence: `lib/main.dart:346-398` (AuthGate declarative), `lib/screens/login_screen.dart:195-203` (imperative Navigator.push), `lib/services/role_routing_service.dart:271-274` (imperative Navigator.pushAndRemoveUntil).

---

**Document Status:** ✅ COMPLETE - All sections populated with extracted architecture data

