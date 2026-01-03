# RLS COMPREHENSIVE AUDIT — FULL APP ANALYSIS

**Date:** Current  
**Purpose:** Identify ALL RLS blocking points across the entire app  
**Scope:** All Supabase queries, all tables, all operations

---

## EXECUTIVE SUMMARY

### RLS Status by Table:
- ✅ **profiles**: RLS enabled — 8 queries — **HIGH RISK**
- ✅ **customers**: RLS enabled — 3 queries — **HIGH RISK**
- ✅ **staff_assignments**: RLS enabled — 4 queries — **CRITICAL RISK**
- ✅ **user_schemes**: RLS enabled — 6 queries — **HIGH RISK**
- ✅ **payments**: RLS enabled — 8 queries (1 INSERT) — **CRITICAL RISK** ⚠️ **BLOCKED**
- ✅ **market_rates**: RLS enabled — 1 query — **MEDIUM RISK** ⚠️ **BLOCKED**
- ✅ **schemes**: RLS enabled — 2 queries — **LOW RISK**
- ✅ **staff_metadata**: RLS enabled — 4 queries — **HIGH RISK**

### Overall Assessment:
- **Total Queries:** 36+ database operations
- **Critical Blockers:** 2 (payments INSERT, market_rates SELECT)
- **High Risk:** 15+ queries that depend on RLS policies
- **Medium Risk:** 5 queries
- **Low Risk:** 3 queries

---

## DETAILED BREAKDOWN BY TABLE

### 1. PAYMENTS TABLE (CRITICAL)

**RLS Status:** ✅ Enabled  
**Total Queries:** 8 (7 SELECT, 1 INSERT)

#### 🔴 CRITICAL BLOCKER: Payment INSERT
**Location:** `lib/services/payment_service.dart:178`
```dart
await _supabase.from('payments').insert({...});
```
**Status:** ❌ **BLOCKED** (permission denied 42501)
**RLS Policy:** "Staff can insert payments for assigned customers"
**Issue:** Policy uses `is_current_staff_assigned_to_customer()` function
**Fix Required:** Run `FIX_PAYMENT_RLS_POLICY.sql` migration

#### 🟡 HIGH RISK: Payment SELECT Queries (7 queries)

**Query 1:** `getTodayStats()` - Today's payments
- **Location:** `lib/services/staff_data_service.dart:199`
- **Query:** `payments` WHERE `staff_id = X` AND `payment_date = today`
- **RLS Policy:** "Staff can read assigned customer payments"
- **Risk:** HIGH — Depends on assignment check
- **Status:** ✅ Should work if assignments exist

**Query 2:** `getTodayCollections()` - Today's collections with joins
- **Location:** `lib/services/staff_data_service.dart:294`
- **Query:** `payments` with `customers!inner(profiles!inner(name))`
- **RLS Policy:** "Staff can read assigned customer payments"
- **Risk:** HIGH — Multiple RLS-protected tables in join
- **Status:** ⚠️ May fail if `customers` or `profiles` RLS blocks join

**Query 3:** `getPaymentHistory()` - Customer payment history
- **Location:** `lib/services/staff_data_service.dart:349`
- **Query:** `payments` WHERE `customer_id = X`
- **RLS Policy:** "Staff can read assigned customer payments"
- **Risk:** HIGH — Must verify assignment
- **Status:** ✅ Should work if assignment exists

**Query 4:** `getSchemeBreakdown()` - Payments with scheme joins
- **Location:** `lib/services/staff_data_service.dart:400`
- **Query:** `payments` with `user_schemes!inner(schemes!inner(asset_type))`
- **RLS Policy:** "Staff can read assigned customer payments"
- **Risk:** HIGH — Complex join across RLS-protected tables
- **Status:** ⚠️ May fail if `user_schemes` or `schemes` RLS blocks

**Query 5:** `getAssignedCustomers()` - Today's payments check
- **Location:** `lib/services/staff_data_service.dart:138`
- **Query:** `payments` WHERE `customer_id = X` AND `staff_id = X` AND `payment_date = today`
- **RLS Policy:** "Staff can read assigned customer payments"
- **Risk:** HIGH — Used in customer list loading
- **Status:** ✅ Should work

**Query 6-7:** Customer dashboard queries (if implemented)
- **Location:** `lib/screens/customer/dashboard_screen.dart` (potential)
- **Query:** Customer's own payments
- **RLS Policy:** "Customers can read own payments"
- **Risk:** MEDIUM — Customer can read own data
- **Status:** ✅ Should work

---

### 2. STAFF_ASSIGNMENTS TABLE (CRITICAL)

**RLS Status:** ✅ Enabled  
**Total Queries:** 4 SELECT queries

#### 🔴 CRITICAL RISK: All queries depend on RLS

**Query 1:** `getAssignedCustomers()` - Get assignments
- **Location:** `lib/services/staff_data_service.dart:34`
- **Query:** `staff_assignments` WHERE `staff_id = X` AND `is_active = true`
- **RLS Policy:** "Staff can read own assignments"
- **Risk:** CRITICAL — Blocks entire customer list if fails
- **Status:** ✅ Should work (staff reads own assignments)

**Query 2:** `getTodayStats()` - Get assignments for stats
- **Location:** `lib/services/staff_data_service.dart:224`
- **Query:** `staff_assignments` WHERE `staff_id = X` AND `is_active = true`
- **RLS Policy:** "Staff can read own assignments"
- **Risk:** CRITICAL — Blocks stats calculation
- **Status:** ✅ Should work

**Query 3:** `insertPayment()` - Check assignment (debug)
- **Location:** `lib/services/payment_service.dart:160`
- **Query:** `staff_assignments` (used for verification)
- **RLS Policy:** "Staff can read own assignments"
- **Risk:** MEDIUM — Debug only, not critical
- **Status:** ✅ Should work

**Query 4:** RLS policy check (via function)
- **Location:** `is_current_staff_assigned_to_customer()` function
- **Query:** `staff_assignments` WHERE `staff_id = get_user_profile()` AND `customer_id = X`
- **RLS Policy:** Function uses SECURITY DEFINER (bypasses RLS)
- **Risk:** LOW — Function bypasses RLS
- **Status:** ✅ Should work if function exists

---

### 3. PROFILES TABLE (HIGH RISK)

**RLS Status:** ✅ Enabled  
**Total Queries:** 8 SELECT queries

#### 🟡 HIGH RISK: Multiple queries across app

**Query 1:** `getAssignedCustomers()` - Customer profiles
- **Location:** `lib/services/staff_data_service.dart:93`
- **Query:** `profiles` WHERE `id = profile_id`
- **RLS Policy:** "Staff can read all profiles" OR "Users can read own profile"
- **Risk:** HIGH — Staff needs to read customer profiles
- **Status:** ✅ Should work (staff can read all profiles)

**Query 2:** `getCurrentProfileId()` - Current user profile
- **Location:** `lib/services/role_routing_service.dart:159`
- **Query:** `profiles` WHERE `user_id = auth.uid()`
- **RLS Policy:** "Users can read own profile"
- **Risk:** MEDIUM — Own profile access
- **Status:** ✅ Should work

**Query 3:** `fetchAndValidateRole()` - Role check
- **Location:** `lib/services/role_routing_service.dart:20`
- **Query:** `profiles` WHERE `user_id = auth.uid()`
- **RLS Policy:** "Users can read own profile"
- **Risk:** MEDIUM — Own profile access
- **Status:** ✅ Should work

**Query 4:** `checkMobileAppAccess()` - Profile check
- **Location:** `lib/services/role_routing_service.dart:101`
- **Query:** `profiles` WHERE `user_id = auth.uid()`
- **RLS Policy:** "Users can read own profile"
- **Risk:** MEDIUM — Own profile access
- **Status:** ✅ Should work

**Query 5:** `navigateByRole()` - Profile check
- **Location:** `lib/services/role_routing_service.dart:213`
- **Query:** `profiles` WHERE `user_id = auth.uid()`
- **RLS Policy:** "Users can read own profile"
- **Risk:** MEDIUM — Own profile access
- **Status:** ✅ Should work

**Query 6:** `getCustomerIdFromData()` - Profile lookup by phone
- **Location:** `lib/services/payment_service.dart:91`
- **Query:** `profiles` WHERE `phone = X`
- **RLS Policy:** "Staff can read all profiles"
- **Risk:** HIGH — Staff needs to find customer by phone
- **Status:** ✅ Should work (staff can read all profiles)

**Query 7:** `_checkRoleAndRoute()` - Profile check in AuthGate
- **Location:** `lib/main.dart:197`
- **Query:** `profiles` WHERE `user_id = auth.uid()`
- **RLS Policy:** "Users can read own profile"
- **Risk:** MEDIUM — Own profile access
- **Status:** ✅ Should work

**Query 8:** `getStaffProfileId()` - Staff profile lookup
- **Location:** `lib/services/staff_data_service.dart:14`
- **Query:** `profiles` WHERE `id = staffId`
- **RLS Policy:** "Staff can read all profiles"
- **Risk:** MEDIUM — Staff can read all profiles
- **Status:** ✅ Should work

---

### 4. CUSTOMERS TABLE (HIGH RISK)

**RLS Status:** ✅ Enabled  
**Total Queries:** 3 SELECT queries

#### 🟡 HIGH RISK: Customer data access

**Query 1:** `getAssignedCustomers()` - Get customers
- **Location:** `lib/services/staff_data_service.dart:60`
- **Query:** `customers` WHERE `id IN (customer_ids)`
- **RLS Policy:** "Staff can read assigned customers"
- **Risk:** HIGH — Blocks customer list if fails
- **Status:** ✅ Should work (staff reads assigned customers)

**Query 2:** `getCustomerIdFromData()` - Customer lookup by UUID
- **Location:** `lib/services/payment_service.dart:72`
- **Query:** `customers` WHERE `id = customer_id`
- **RLS Policy:** "Staff can read assigned customers"
- **Risk:** HIGH — Used in payment flow
- **Status:** ✅ Should work

**Query 3:** `getCustomerIdFromData()` - Customer lookup via profile
- **Location:** `lib/services/payment_service.dart:101`
- **Query:** `customers` WHERE `profile_id = profileId`
- **RLS Policy:** "Staff can read assigned customers"
- **Risk:** HIGH — Used in payment flow
- **Status:** ✅ Should work

---

### 5. USER_SCHEMES TABLE (HIGH RISK)

**RLS Status:** ✅ Enabled  
**Total Queries:** 6 SELECT queries

#### 🟡 HIGH RISK: Scheme data access

**Query 1:** `getAssignedCustomers()` - Get user schemes
- **Location:** `lib/services/staff_data_service.dart:107`
- **Query:** `user_schemes` WHERE `customer_id = X` AND `status = 'active'`
- **RLS Policy:** "Staff can read assigned customer schemes"
- **Risk:** HIGH — Blocks customer list if fails
- **Status:** ✅ Should work (staff reads assigned schemes)

**Query 2:** `getTodayStats()` - Active schemes for stats
- **Location:** `lib/services/staff_data_service.dart:235`
- **Query:** `user_schemes` WHERE `status = 'active'`
- **RLS Policy:** "Staff can read assigned customer schemes"
- **Risk:** HIGH — Blocks stats if fails
- **Status:** ⚠️ **POTENTIAL ISSUE** — No `customer_id` filter, may return all active schemes (RLS should filter)

**Query 3:** `getTodayCollections()` - Scheme lookup
- **Location:** `lib/services/staff_data_service.dart:317`
- **Query:** `user_schemes` with `schemes!inner(name)`
- **RLS Policy:** "Staff can read assigned customer schemes"
- **Risk:** HIGH — Used in collections display
- **Status:** ✅ Should work

**Query 4:** `getUserSchemeId()` - Get scheme ID for payment
- **Location:** `lib/services/payment_service.dart:35`
- **Query:** `user_schemes` WHERE `customer_id = X` AND `status = 'active'`
- **RLS Policy:** "Staff can read assigned customer schemes"
- **Risk:** CRITICAL — Blocks payment recording if fails
- **Status:** ✅ Should work

**Query 5:** `getUserSchemeId()` - Fallback to paused scheme
- **Location:** `lib/services/payment_service.dart:49`
- **Query:** `user_schemes` WHERE `customer_id = X` AND `status = 'paused'`
- **RLS Policy:** "Staff can read assigned customer schemes"
- **Risk:** HIGH — Fallback for payment flow
- **Status:** ✅ Should work

**Query 6:** Customer dashboard - Active schemes
- **Location:** `lib/screens/customer/dashboard_screen.dart:1384`
- **Query:** `user_schemes` WHERE `user_id = X` AND `status = 'active'`
- **RLS Policy:** "Customers can read own schemes"
- **Risk:** MEDIUM — Customer reads own data
- **Status:** ⚠️ **POTENTIAL ISSUE** — Query uses `user_id` but table has `customer_id` (schema mismatch)

---

### 6. MARKET_RATES TABLE (MEDIUM RISK)

**RLS Status:** ✅ Enabled  
**Total Queries:** 1 SELECT query

#### 🟠 MEDIUM RISK: Market rate lookup

**Query 1:** `getCurrentMarketRate()` - Get current rate
- **Location:** `lib/services/payment_service.dart:13`
- **Query:** `market_rates` WHERE `asset_type = X` ORDER BY `rate_date DESC` LIMIT 1
- **RLS Policy:** "Everyone can read market rates"
- **Risk:** MEDIUM — Non-critical, optional for payment
- **Status:** ❌ **BLOCKED** (permission denied 42501)
- **Issue:** Policy says "Everyone can read" but query fails
- **Fix Required:** Check if policy exists and is correct

---

### 7. SCHEMES TABLE (LOW RISK)

**RLS Status:** ✅ Enabled  
**Total Queries:** 2 SELECT queries

#### 🟢 LOW RISK: Reference data

**Query 1:** `getAssignedCustomers()` - Scheme details
- **Location:** `lib/services/staff_data_service.dart:124`
- **Query:** `schemes` WHERE `id = scheme_id`
- **RLS Policy:** "Everyone can read active schemes"
- **Risk:** LOW — Reference data
- **Status:** ✅ Should work

**Query 2:** `getTodayCollections()` - Scheme name via join
- **Location:** `lib/services/staff_data_service.dart:319` (via join)
- **Query:** `schemes` via `user_schemes!inner(schemes!inner(name))`
- **RLS Policy:** "Everyone can read active schemes"
- **Risk:** LOW — Reference data
- **Status:** ✅ Should work

---

### 8. STAFF_METADATA TABLE (HIGH RISK)

**RLS Status:** ✅ Enabled  
**Total Queries:** 4 SELECT queries

#### 🟡 HIGH RISK: Staff metadata access

**Query 1:** `fetchStaffType()` - Get staff_type
- **Location:** `lib/services/role_routing_service.dart:60`
- **Query:** `staff_metadata` WHERE `profile_id = X`
- **RLS Policy:** "Staff can read own metadata"
- **Risk:** HIGH — Blocks mobile app access check
- **Status:** ✅ Should work (staff reads own metadata)

**Query 2:** `getDailyTarget()` - Get daily targets
- **Location:** `lib/services/staff_data_service.dart:482`
- **Query:** `staff_metadata` WHERE `profile_id = X`
- **RLS Policy:** "Staff can read own metadata"
- **Risk:** HIGH — Blocks target display
- **Status:** ✅ Should work

**Query 3:** `getStaffEmailByCode()` - Staff login lookup
- **Location:** `lib/services/staff_auth_service.dart:22` (via RPC)
- **Query:** `staff_metadata` with `profiles!inner(email)`
- **RLS Policy:** Function uses SECURITY DEFINER (bypasses RLS)
- **Risk:** LOW — Function bypasses RLS
- **Status:** ⚠️ **POTENTIAL ISSUE** — Function may not exist in database

**Query 4:** Potential other staff metadata queries
- **Location:** Various staff screens
- **Query:** Staff metadata lookups
- **RLS Policy:** "Staff can read own metadata"
- **Risk:** MEDIUM — Staff-specific data
- **Status:** ✅ Should work

---

## CRITICAL BLOCKERS SUMMARY

### 🔴 BLOCKER #1: Payment INSERT (CRITICAL)
- **Table:** `payments`
- **Operation:** INSERT
- **Location:** `lib/services/payment_service.dart:178`
- **Error:** `permission denied for table payments (42501)`
- **Root Cause:** RLS policy not working correctly
- **Fix:** Run `FIX_PAYMENT_RLS_POLICY.sql` migration
- **Impact:** Staff cannot record payments

### 🔴 BLOCKER #2: Market Rates SELECT (MEDIUM)
- **Table:** `market_rates`
- **Operation:** SELECT
- **Location:** `lib/services/payment_service.dart:13`
- **Error:** `permission denied for table market_rates (42501)`
- **Root Cause:** RLS policy may not exist or is incorrect
- **Fix:** Verify/update market_rates RLS policy
- **Impact:** Payment flow can't fetch current rates (but has fallback)

---

## HIGH RISK QUERIES (May Fail)

### 🟡 HIGH RISK #1: `getTodayStats()` - user_schemes query
- **Location:** `lib/services/staff_data_service.dart:235`
- **Query:** `user_schemes` WHERE `status = 'active'` (NO customer_id filter)
- **Issue:** RLS policy requires assignment check, but query doesn't filter by customer
- **Risk:** May return all active schemes instead of only assigned customers
- **Impact:** Stats may show incorrect pending counts

### 🟡 HIGH RISK #2: Customer dashboard - user_schemes query
- **Location:** `lib/screens/customer/dashboard_screen.dart:1384`
- **Query:** `user_schemes` WHERE `user_id = X` (WRONG COLUMN)
- **Issue:** Table has `customer_id`, not `user_id`
- **Risk:** Query will always return empty
- **Impact:** Customer dashboard shows no schemes

### 🟡 HIGH RISK #3: Complex joins with RLS-protected tables
- **Locations:**
  - `getTodayCollections()` - payments with customers!inner(profiles!inner)
  - `getSchemeBreakdown()` - payments with user_schemes!inner(schemes!inner)
- **Issue:** Multiple RLS-protected tables in joins may cause failures
- **Risk:** Joins may fail if any table's RLS blocks
- **Impact:** Collections/breakdown may not display

---

## MEDIUM RISK QUERIES

### 🟠 MEDIUM RISK #1: Profile lookups by phone
- **Location:** `lib/services/payment_service.dart:91`
- **Query:** `profiles` WHERE `phone = X`
- **Issue:** Staff needs to find customer by phone for payment
- **Risk:** RLS policy "Staff can read all profiles" should allow this
- **Status:** ✅ Should work

### 🟠 MEDIUM RISK #2: Customer profile lookups
- **Location:** `lib/services/staff_data_service.dart:93`
- **Query:** `profiles` WHERE `id = profile_id`
- **Issue:** Staff reads customer profiles in loop
- **Risk:** Multiple queries, but RLS should allow
- **Status:** ✅ Should work

---

## LOW RISK QUERIES

### 🟢 LOW RISK #1: Schemes table
- **Status:** ✅ Should work (public read access)
- **Risk:** LOW — Reference data

### 🟢 LOW RISK #2: Own profile queries
- **Status:** ✅ Should work (users read own profile)
- **Risk:** LOW — Standard access pattern

---

## RLS POLICY DEPENDENCIES

### Critical Dependencies:
1. **`is_staff()`** — Used in 15+ queries
2. **`get_user_profile()`** — Used in 10+ queries
3. **`is_current_staff_assigned_to_customer()`** — Used in payment INSERT
4. **`is_staff_assigned_to_customer()`** — Used in payment SELECT

### Function Status Check:
- ✅ `is_staff()` — SECURITY DEFINER
- ✅ `get_user_profile()` — SECURITY DEFINER
- ⚠️ `is_current_staff_assigned_to_customer()` — May not exist
- ✅ `is_staff_assigned_to_customer()` — SECURITY DEFINER

---

## SEVERITY BREAKDOWN

### 🔴 CRITICAL (Blocks Core Functionality):
1. **Payment INSERT** — Staff cannot record payments
2. **Market Rates SELECT** — Payment flow can't get rates (has fallback)

### 🟡 HIGH (May Cause Data Issues):
1. **getTodayStats() user_schemes query** — May return wrong data
2. **Customer dashboard user_schemes query** — Wrong column, always fails
3. **Complex joins** — May fail silently

### 🟠 MEDIUM (May Cause UX Issues):
1. **Profile lookups** — Should work but may fail in edge cases
2. **Staff metadata queries** — Should work but critical for access control

### 🟢 LOW (Should Work):
1. **Schemes queries** — Public access
2. **Own profile queries** — Standard pattern

---

## RECOMMENDED FIX PRIORITY

### Priority 1 (CRITICAL - Fix Immediately):
1. ✅ Run `FIX_PAYMENT_RLS_POLICY.sql` migration
2. ✅ Fix `market_rates` RLS policy (verify "Everyone can read" policy exists)
3. ✅ Verify `is_current_staff_assigned_to_customer()` function exists

### Priority 2 (HIGH - Fix Soon):
1. Fix `getTodayStats()` query — Add customer_id filter or use assignment check
2. Fix customer dashboard query — Change `user_id` to `customer_id`
3. Test all complex joins — Verify they work with RLS

### Priority 3 (MEDIUM - Monitor):
1. Add error handling for profile lookups
2. Add fallbacks for staff metadata queries
3. Monitor RLS policy performance

---

## ESTIMATED FIX EFFORT

- **Critical Fixes:** 1-2 hours (run migrations, verify functions)
- **High Priority Fixes:** 2-3 hours (fix queries, test)
- **Medium Priority:** 1-2 hours (add error handling)
- **Total:** 4-7 hours to fix all RLS issues

---

## CONCLUSION

**RLS Impact:** **HIGH** — 2 critical blockers, 5+ high-risk queries

**Main Issues:**
1. Payment INSERT blocked (critical)
2. Market rates blocked (medium, has fallback)
3. Query design issues (wrong columns, missing filters)

**Fix Complexity:** **MEDIUM** — Most issues are policy/function related, not code changes

**Recommendation:** Fix critical blockers first, then address high-risk queries systematically.

