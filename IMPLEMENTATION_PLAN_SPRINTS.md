# IMPLEMENTATION PLAN — EXECUTIVE SPRINTS

**Goal:**
Move from widget-owned authority → explicit system authority
Without breaking prod
Without rewriting everything at once

🔢 OVERVIEW (READ ONCE)

Total: 7 sprints (was 6, added critical database fix)
Sprint length: 2–3 days each (realistic, not fantasy)
Rule: Each sprint ends in a working app

You never leave the app in a broken state.

---

## 🟦 SPRINT 0 — SAFETY & FREEZE (½ day)

This is boring. It saves you weeks.

**Objectives:**
- Freeze current behavior
- Prevent accidental regression

**Tasks:**
1. Tag repo: `legacy-auth-baseline`
2. Save architecture doc as `/docs/architecture_current.md`
3. Add a banner comment in `main.dart`:
   ```dart
   // ⚠️ LEGACY AUTH FLOW — DO NOT MODIFY
   // See /docs/architecture_current.md
   ```
4. Disable "quick fixes" mindset

**Exit Criteria:**
- ✅ App still works exactly as today
- ✅ You have a rollback point

---

## 🟦 SPRINT 1 — RIVERPOD BOOTSTRAP (1 day)

No behavior change yet. Just wiring.

**Objectives:**
- Introduce Riverpod without removing Provider
- No auth logic moved yet

**Tasks:**
1. Add `flutter_riverpod` dependency
2. Wrap app with `ProviderScope`
3. Create:
   ```
   lib/state/
     auth/
       auth_session_provider.dart
   ```
4. Implement read-only session provider:
   ```dart
   final supabaseSessionProvider = StreamProvider<Session?>(
     (ref) => Supabase.instance.client.auth.onAuthStateChange
       .map((e) => e.session),
   );
   ```

**Exit Criteria:**
- ✅ App compiles
- ✅ No logic removed
- ✅ No screens changed

---

## 🟦 SPRINT 2 — SINGLE AUTH AUTHORITY (2 days)

This kills the root cause.

**Objectives:**
- Riverpod becomes only reader of auth
- Provider stops deciding auth truth

**Tasks:**
1. Create `auth_state_provider.dart`:
   ```dart
   enum AuthState { unauthenticated, authenticated }
   ```
2. Derive auth state only from Supabase session
3. Remove `initializeSession()` logic
4. `AuthFlowNotifier` stops reading Supabase directly
5. Supabase listener updates Riverpod only

**Delete / Deprecate:**
- `AuthFlowNotifier.initializeSession`
- Manual auth state syncing

**Exit Criteria:**
- ✅ Login works
- ✅ Logout works
- ✅ Login after logout works (still ugly routing, but stable)

---

## 🟦 SPRINT 3 — DECLARATIVE NAVIGATION (2 days)

This replaces AuthGate without breaking UI.

**Objectives:**
- One place decides the screen
- No widget owns routing state

**Tasks:**
1. Create:
   ```
   lib/state/navigation/app_router_provider.dart
   ```
2. Router derives screen from:
   - auth state
   - role state
3. Replace `AuthGate` with:
   ```dart
   home: Consumer(
     builder: (_, ref, __) {
       return ref.watch(appRouterProvider);
     },
   );
   ```
4. Delete:
   - `_roleBasedScreen`
   - `_checkRoleIfNeeded`
   - manual listeners
5. Leave Navigator only for non-auth flows

**Exit Criteria:**
- ✅ No `setState()` in auth routing
- ✅ No post-frame callbacks
- ✅ Login-after-logout works consistently

---

## 🟦 SPRINT 4 — ROLE & ACCESS AUTHORITY (2 days)

Moves "who can use the app" out of widgets.

**Objectives:**
- Role checks become data, not UI logic

**Tasks:**
1. Create `user_profile_provider`
2. Fetch profile once per session
3. Remove:
   - `RoleRoutingService`
   - widget-owned role fetching
4. Cache role in Riverpod
5. Router reads role from provider

**Exit Criteria:**
- ✅ Staff/customer routing works
- ✅ No DB reads inside widgets
- ✅ Role logic is testable

---

## 🟦 SPRINT 4.5 — DATABASE TRIGGER FIX (CRITICAL) (½ day)

**⚠️ MUST FIX BEFORE SPRINT 5** — Payment flow is broken without this.

**Objectives:**
- Fix `user_schemes` UPDATE permission issue
- Ensure payment triggers work correctly

**Problem:**
- Payment INSERT succeeds but trigger `update_user_scheme_totals()` fails
- RLS blocks staff from UPDATE on `user_schemes` table
- Function runs with caller's permissions (not SECURITY DEFINER)

**Tasks:**
1. Make `update_user_scheme_totals()` function `SECURITY DEFINER`:
   ```sql
   CREATE OR REPLACE FUNCTION update_user_scheme_totals()
   RETURNS TRIGGER AS $$
   BEGIN
       -- ... existing code ...
   END;
   $$ LANGUAGE plpgsql SECURITY DEFINER;  -- ← Add this
   ```
2. Run migration in Supabase
3. Test payment INSERT → verify `user_schemes` totals update
4. Verify trigger still prevents invalid updates

**Exit Criteria:**
- ✅ Payment INSERT succeeds
- ✅ `user_schemes` totals update correctly
- ✅ No RLS permission errors
- ✅ Test payment recorded in database

**Reference:**
- `SYSTEM_ARCHITECTURE_SPECIFICATION.md:710-711` (enforcement gap)
- `CURRENT_STATUS_UPDATE.md:24-53` (critical issue)

---

## 🟦 SPRINT 5 — PAYMENT AUTHORITY (3 days)

This is where money becomes real.

**Objectives:**
- Flutter stops validating payments
- Backend owns invariants

**Tasks:**
1. Create Edge Function: `create_payment`
2. Move:
   - GST calc
   - gram calc
   - assignment check
3. Flutter sends intent only
4. Lock RLS to block direct inserts (optional, can be later)
5. Add audit insert inside function

**Prerequisites:**
- ✅ Sprint 4.5 completed (database trigger fixed)

**Exit Criteria:**
- ✅ Invalid payments cannot be created
- ✅ Modified client cannot cheat
- ✅ Audit log always written

---

## 🟦 SPRINT 6 — REPORTS & CLEANUP (2 days)

Remove silent lies.

**Objectives:**
- Kill client aggregation
- Remove dead code
- Clean up legacy references

**Tasks:**
1. Switch reports to DB views / Edge Functions:
   - Use `today_collections` view
   - Use `staff_daily_stats` view
   - Use `active_customer_schemes` view
2. Delete client-side aggregation:
   - `lib/services/staff_data_service.dart:194-287` (getTodayStats)
   - All other client-side report calculations
3. Remove legacy table references:
   - `users` table queries - `lib/screens/login_screen.dart:174`, `lib/screens/otp_screen.dart:143`
   - `staff` table queries - `lib/screens/staff/staff_pin_setup_screen.dart:206`
4. Remove Provider entirely:
   - Delete `AuthFlowNotifier`
   - Remove `ChangeNotifierProvider`
   - Remove all `Provider.of` calls
5. Migrate SecureStorage to Riverpod (if needed):
   - Consider if `SecureStorageHelper` should become a provider
   - Currently static class, may stay as-is

**Exit Criteria:**
- ✅ Reports match DB
- ✅ No legacy auth code
- ✅ No legacy table references
- ✅ Architecture doc still matches system

---

## 🧠 HOW TO USE THIS PLAN

1. **One sprint at a time**
2. **Never skip exit criteria**
3. **If stuck → revert to last sprint tag**
4. **No "small optimizations" mid-sprint**
5. **Test database fixes immediately** (Sprint 4.5)

---

## 🏁 FINAL REALITY CHECK

**Before Starting:**
- [ ] Database trigger issue identified (`update_user_scheme_totals()`)
- [ ] Legacy table references documented
- [ ] Architecture spec saved
- [ ] Rollback point created

**After Sprint 6:**
- [ ] All payments go through Edge Function
- [ ] Reports use database views
- [ ] No Provider code remains
- [ ] No legacy table queries
- [ ] Architecture doc matches reality

---

## 📋 MISSING ITEMS ADDED

Based on `SYSTEM_ARCHITECTURE_SPECIFICATION.md` review:

1. **Sprint 4.5 (NEW):** Database trigger fix — Critical blocker for payments
2. **Sprint 6 (ENHANCED):** Explicit legacy table cleanup (`users`, `staff`)
3. **Sprint 6 (ENHANCED):** Database views usage (switch from client aggregation)
4. **Sprint 6 (ENHANCED):** SecureStorage migration consideration

**Critical Issues Documented:**
- `update_user_scheme_totals()` function needs `SECURITY DEFINER` — `SYSTEM_ARCHITECTURE_SPECIFICATION.md:710-711`
- Legacy table references may cause failures — `SYSTEM_ARCHITECTURE_SPECIFICATION.md:670-677`
- Database views exist but unused — `SYSTEM_ARCHITECTURE_SPECIFICATION.md:655-667`

