# CURRENT STATUS UPDATE — COMPLETE OVERVIEW

**Date:** January 1, 2026  
**Last Updated:** Just now (added market_rates GRANT)

---

## ✅ WHAT WAS JUST FIXED

### **Market Rates Permission Issue**
- **Problem:** Staff couldn't read `market_rates` table (permission denied error)
- **Fix Applied:** Added `GRANT SELECT ON market_rates TO authenticated;` to `supabase_schema.sql`
- **Status:** ✅ **FIXED** (needs migration run in Supabase)
- **Location:** `supabase_schema.sql:950-951`

**What This Means:**
- Staff can now read market rates for payment calculations
- The RLS policy "Everyone can read market rates" exists, but explicit GRANT ensures it works

---

## 🔴 CRITICAL ISSUES STILL BROKEN

### **Issue #1: Payment INSERT Fails — `user_schemes` Permission Denied**

**Current Error:**
```
PostgrestException: permission denied for table user_schemes (42501)
```

**What's Happening:**
1. Staff tries to record payment → Payment INSERT succeeds (RLS fixed)
2. **BUT** database trigger tries to update `user_schemes` table
3. Trigger fails because staff doesn't have UPDATE permission on `user_schemes`
4. Payment INSERT rolls back → Payment fails

**Root Cause:**
- Payment INSERT triggers `update_user_schemes_totals()` function
- Function tries to `UPDATE user_schemes SET total_amount_paid = ...`
- RLS policy on `user_schemes` blocks UPDATE for staff
- Only customers and admins can update `user_schemes` (by design)

**Why This Is Critical:**
- **Payments cannot be recorded** — core functionality broken
- Even though payment INSERT RLS is fixed, trigger fails
- Staff needs permission to update `user_schemes` totals (via trigger)

**Fix Required:**
- Make `update_user_schemes_totals()` function `SECURITY DEFINER`
- OR grant UPDATE permission on `user_schemes` to authenticated role
- OR change trigger to use SECURITY DEFINER function

**Location:** `supabase_schema.sql:448-500` (trigger function)

---

### **Issue #2: App Starts in Dashboard Instead of Login**

**What's Happening:**
- App opens → Checks for existing Supabase session
- Session exists (from previous login) → Auto-authenticates
- User never sees login screen → Goes straight to dashboard

**Root Cause:**
- `lib/services/auth_flow_notifier.dart:26-34` → `initializeSession()`
- If session exists → Calls `setAuthenticated()`
- This is "remember me" behavior, but user wants **always start at login**

**User Expectation:**
- App should **ALWAYS** start at login screen
- User must manually log in every time (security requirement)

**Fix Required:**
- Change `initializeSession()` to always call `setUnauthenticated()`
- Optionally clear Supabase session on app start

**Location:** `lib/services/auth_flow_notifier.dart:26-34`

---

### **Issue #3: Cannot Login After Logout**

**What's Happening:**
1. User logs out → Session cleared, state = `unauthenticated`
2. Login screen appears ✅
3. User taps "Staff Login" → `StaffLoginScreen` opens ✅
4. User enters credentials → Login succeeds ✅
5. `setAuthenticated()` called → State changes ✅
6. `popUntil((route) => route.isFirst))` called → Should pop to `AuthGate`
7. **BUT** `AuthGate` doesn't rebuild or navigation stack is corrupted
8. User stuck on login screen or sees duplicate login attempts

**Root Cause:**
- `popUntil` in `StaffLoginScreen` conflicts with `AuthGate` declarative routing
- `AuthGate` should handle navigation based on state, not manual `popUntil`
- Navigation stack might be corrupted after logout

**Evidence from Logs:**
- Line 775: `AuthFlowNotifier: Already in authenticated state, skipping duplicate call`
- This suggests `setAuthenticated()` is called twice, or state is already authenticated
- Line 369: `🔵 AuthGate.build: _roleBasedScreen = StaffDashboard` (when unauthenticated!)
- This shows `_roleBasedScreen` is not resetting on logout

**Fix Required:**
1. Remove `popUntil` from `StaffLoginScreen` (let `AuthGate` handle routing)
2. Fix `_roleBasedScreen` reset in `AuthGate` when state becomes `unauthenticated`
3. Ensure `AuthGate` rebuilds after `setAuthenticated()`

**Locations:**
- `lib/screens/staff/staff_login_screen.dart:89` (remove popUntil)
- `lib/main.dart:144` (fix _roleBasedScreen reset)

---

## 🟡 MEDIUM PRIORITY ISSUES

### **Issue #4: Missing Debug Logs**

**What's Missing:**
- No logs showing `AuthGate.build()` calls after state changes
- No logs showing navigation stack state
- Hard to debug why login/navigation fails

**Status:** Not critical, but needed for debugging

---

## 📊 SUMMARY TABLE

| Issue | Severity | Status | Location | Fix Complexity |
|-------|----------|--------|----------|----------------|
| Payment INSERT fails (user_schemes) | 🔴 CRITICAL | ❌ BROKEN | `supabase_schema.sql:448-500` | Medium (SQL) |
| App starts in dashboard | 🔴 HIGH | ❌ BROKEN | `lib/services/auth_flow_notifier.dart:26-34` | Low (1 line change) |
| Cannot login after logout | 🔴 HIGH | ❌ BROKEN | `lib/main.dart:144`, `lib/screens/staff/staff_login_screen.dart:89` | Medium (2 files) |
| Market rates permission | ✅ FIXED | ✅ FIXED | `supabase_schema.sql:950-951` | Done |

---

## 🎯 WHAT NEEDS TO BE DONE NEXT

### **Priority 1: Fix Payment INSERT (CRITICAL)**
**Action:** Make `update_user_schemes_totals()` function `SECURITY DEFINER`

**Why:** Staff needs to update `user_schemes` totals via trigger, but RLS blocks it

**Code Change:**
```sql
-- In supabase_schema.sql, line 448
CREATE OR REPLACE FUNCTION update_user_schemes_totals()
RETURNS TRIGGER AS $$
BEGIN
    -- ... existing code ...
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;  -- ← Add SECURITY DEFINER here
```

**Then:** Run migration in Supabase

---

### **Priority 2: Fix App Start (HIGH)**
**Action:** Force logout on app start

**Code Change:**
```dart
// lib/services/auth_flow_notifier.dart:26-34
void initializeSession() {
  // ALWAYS start unauthenticated
  setUnauthenticated();
  
  // Clear any existing session
  try {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      Supabase.instance.client.auth.signOut();
    }
  } catch (e) {
    // Ignore errors
  }
}
```

---

### **Priority 3: Fix Login After Logout (HIGH)**
**Action 1:** Remove `popUntil` from `StaffLoginScreen`
```dart
// lib/screens/staff/staff_login_screen.dart:89
// REMOVE THIS:
// Navigator.of(context).popUntil((route) => route.isFirst);

// KEEP ONLY:
authFlow.setAuthenticated();
// Let AuthGate handle routing declaratively
```

**Action 2:** Fix `_roleBasedScreen` reset in `AuthGate`
```dart
// lib/main.dart:144
Future<void> _checkRoleIfNeeded() async {
  final authFlow = Provider.of<AuthFlowNotifier>(context, listen: false);
  
  // Reset state when unauthenticated (logout)
  if (authFlow.state == AuthFlowState.unauthenticated) {
    if (_lastState != AuthFlowState.unauthenticated) {
      // Logout detected - reset all routing state
      setState(() {  // ← ADD setState HERE
        _lastState = authFlow.state;
        _roleBasedScreen = null;  // ← Reset to null
        _isCheckingRole = false;
      });
    }
    return;
  }
  // ... rest of method
}
```

---

## 🔍 CURRENT STATE OF FILES

### **Files Modified (Ready to Deploy):**
- ✅ `supabase_schema.sql` — Added `GRANT SELECT ON market_rates TO authenticated;`

### **Files That Need Changes:**
- ❌ `supabase_schema.sql` — Make `update_user_schemes_totals()` SECURITY DEFINER
- ❌ `lib/services/auth_flow_notifier.dart` — Force logout on app start
- ❌ `lib/main.dart` — Fix `_roleBasedScreen` reset
- ❌ `lib/screens/staff/staff_login_screen.dart` — Remove `popUntil`

---

## 🚨 BLOCKERS

1. **Payment recording is completely broken** — Staff cannot record payments
2. **App doesn't start at login** — Security/user expectation violation
3. **Login flow broken after logout** — User cannot access app after logging out

**All three must be fixed before app can be used.**

---

## 📝 NOTES

- **Market rates issue is fixed** — Just needs migration run
- **Payment issue is now about triggers, not RLS** — Different problem
- **Login issues are navigation/state management** — Flutter code changes needed
- **All fixes are straightforward** — No major refactoring needed

---

**END OF STATUS UPDATE**

