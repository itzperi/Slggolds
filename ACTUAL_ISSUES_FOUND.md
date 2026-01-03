# ACTUAL ISSUES FOUND IN LOGS

## 🔴 ISSUE #1: App Starts in Dashboard (NOT a bug - it's working as designed)

**Evidence:**
- Line 15-16: `AuthFlowNotifier: State transition: AuthFlowState.unauthenticated -> authenticated`
- Line 330-331: Same on app restart

**What's happening:**
- `initializeSession()` finds existing Supabase session
- Auto-authenticates user
- Routes to dashboard

**This is CORRECT behavior** - Supabase sessions persist, so users stay logged in.

**If you want it to ALWAYS start at login**, you need to clear the session on app start (but that's a design choice, not a bug).

---

## 🔴 ISSUE #2: `_roleBasedScreen` NOT Reset on Logout (THE REAL BUG)

**Evidence from logs:**
```
Line 616: supabase.auth: INFO: Signing out user
Line 617: AuthFlowNotifier: State transition: AuthFlowState.authenticated -> unauthenticated
Line 620: 🔵 AuthGate.build: CALLED - Current state = AuthFlowState.unauthenticated
Line 622: 🔵 AuthGate.build: _roleBasedScreen = StaffDashboard  ← ⚠️ STILL SET!
Line 624: 🔵 AuthGate: Returning LoginScreen (unauthenticated)  ← But returns LoginScreen anyway
```

**The Problem:**
- When user logs out, `_roleBasedScreen` should be reset to `null`
- But line 622 shows it's still `StaffDashboard`
- The reset code exists (line 144 in `lib/main.dart`), but it's not working

**Why it's not resetting:**
- Line 144: `_roleBasedScreen = null;` is set, but **NOT wrapped in `setState()`**
- This means the variable is set, but the widget doesn't rebuild
- `build()` is called before `_checkRoleIfNeeded()` runs (because `_checkRoleIfNeeded()` is in a `PostFrameCallback`)
- So `build()` sees the old `StaffDashboard` value

**The Fix:**
- Wrap the reset in `setState()` so the widget rebuilds immediately

---

## 🔴 ISSUE #3: Login After Logout - `popUntil` Works, But AuthGate Doesn't Rebuild

**Evidence from logs:**
```
Line 737: 🔵 StaffLoginScreen: Calling authFlow.setAuthenticated()
Line 738: AuthFlowNotifier: State transition: AuthFlowState.unauthenticated -> authenticated
Line 740: 🔵 StaffLoginScreen: Calling popUntil((route) => route.isFirst)
Line 743: 🔵 StaffLoginScreen: popUntil checking route: unnamed, isFirst = true
Line 744: 🔵 StaffLoginScreen: popUntil completed
Line 760: AUTH LISTENER: Access check result = true
```

**What's happening:**
1. User logs in → `setAuthenticated()` called
2. `popUntil` completes → Returns to `AuthGate`
3. **BUT** no logs showing `AuthGate.build()` being called after `popUntil`
4. **AND** no logs showing routing to dashboard

**The Problem:**
- `popUntil` pops back to `AuthGate`
- But `AuthGate` doesn't rebuild because:
  - `_roleBasedScreen` is still `null` (or wasn't reset properly)
  - `_checkRoleIfNeeded()` needs to be called again
  - But it's only called in `PostFrameCallback` in `build()`
  - If `build()` isn't called, routing never happens

**Why `build()` might not be called:**
- `popUntil` changes navigation stack
- But `AuthGate` is the root widget, so it might not rebuild
- `Provider.of<AuthFlowNotifier>(context, listen: true)` should trigger rebuild
- But if the context is different after `popUntil`, it might not work

---

## 🔴 ISSUE #4: Payment Error Changed (Different Error Now)

**Evidence:**
- Line 177: `permission denied for table market_rates` (first attempt)
- Line 554: `permission denied for table user_schemes` (second attempt)

**What's happening:**
- First payment attempt fails on `market_rates` (expected - non-critical)
- Second payment attempt fails on `user_schemes` (NEW ERROR!)

**This suggests:**
- Payment INSERT might be trying to update `user_schemes` via trigger
- But staff doesn't have permission to UPDATE `user_schemes`
- The trigger might be failing because of RLS on `user_schemes`

---

## 📊 SUMMARY OF ACTUAL ISSUES

1. **`_roleBasedScreen` not reset on logout** - Variable set but not in `setState()`
2. **`AuthGate` doesn't rebuild after `popUntil`** - Navigation stack change doesn't trigger rebuild
3. **Payment INSERT failing on `user_schemes`** - RLS blocking trigger update

---

## 🎯 ROOT CAUSES

### Issue #1: `_roleBasedScreen` Reset
**Location:** `lib/main.dart:144`
**Problem:** `_roleBasedScreen = null;` not in `setState()`
**Fix:** Wrap in `setState(() { _roleBasedScreen = null; })`

### Issue #2: AuthGate Not Rebuilding
**Location:** `lib/main.dart:287-299`
**Problem:** `_checkRoleIfNeeded()` only called in `PostFrameCallback`, might not run after `popUntil`
**Fix:** Call `_checkRoleIfNeeded()` in `didChangeDependencies()` when state changes

### Issue #3: Payment RLS on `user_schemes`
**Location:** Database trigger + RLS policies
**Problem:** Trigger tries to UPDATE `user_schemes`, but staff can't UPDATE
**Fix:** Make trigger run as `SECURITY DEFINER` or grant UPDATE permission to trigger

---

**END OF ANALYSIS**

