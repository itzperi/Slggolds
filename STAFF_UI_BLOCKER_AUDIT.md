# STAFF UI BLOCKER AUDIT — READ ONLY REPORT

**Date:** Current  
**Purpose:** Identify exact reasons why Staff UI shows 0 customers, 0 targets, empty reports after mock data removal  
**Status:** FACTS ONLY — NO CODE CHANGES

---

## 1. DATA FLOW TRACE

### Entry Point: Staff Dashboard Initialization
**File:** `lib/main.dart:196`  
**Action:** `StaffDashboard(staffId: profileId)`  
**Value:** `profileId` = UUID from `profiles.id` (not staff_code like SLG001/SLG002)

### Step 1: Profile ID Resolution
**File:** `lib/screens/staff/collect_tab_screen.dart:49`  
**Function:** `RoleRoutingService.getCurrentProfileId()`  
**Query:**
```sql
SELECT id FROM profiles WHERE user_id = auth.uid()
```
**Result:** Returns `profiles.id` (UUID) or `null`

**CRITICAL FACT:** If `_staffProfileId` is `null`, `_loadData()` returns early at line 50-52, resulting in:
- `_customers = []`
- `_totalCustomers = 0`
- `_targetAmount = 0.0`

### Step 2: Assigned Customers Query
**File:** `lib/services/staff_data_service.dart:26-159`  
**Function:** `getAssignedCustomers(String staffProfileId)`

**Query Chain:**

#### 2.1: Staff Assignments
```sql
SELECT customer_id 
FROM staff_assignments 
WHERE staff_id = <staffProfileId> 
  AND is_active = true
```
**Location:** Line 29-33  
**Filter:** `if (assignments.isEmpty) return [];` (Line 35-37)

**BLOCKER #1:** If no `staff_assignments` records exist for this `staffProfileId`, function returns empty list immediately.

#### 2.2: Customer Records
```sql
SELECT id, profile_id, address 
FROM customers 
WHERE id IN (<customer_ids>)
```
**Location:** Line 49-64  
**Filter:** `if (customersResponse.isEmpty) return [];` (Line 66-68)

**BLOCKER #2:** If customer IDs from assignments don't exist in `customers` table, returns empty.

#### 2.3: Profile Lookup (Per Customer)
```sql
SELECT id, name, phone 
FROM profiles 
WHERE id = <profile_id>
```
**Location:** Line 78-82  
**Filter:** `if (profile == null) continue;` (Line 84)

**BLOCKER #3:** If profile missing, customer is skipped (not counted).

#### 2.4: Active User Schemes (Per Customer)
```sql
SELECT id, scheme_id, status, payment_frequency, min_amount, max_amount, 
       total_amount_paid, payments_made, payments_missed, accumulated_grams
FROM user_schemes 
WHERE customer_id = <customer_id> 
  AND status = 'active'
LIMIT 1
```
**Location:** Line 87-93  
**Filter:** `if (userSchemes == null) continue;` (Line 95)

**BLOCKER #4:** If customer has no active `user_schemes`, customer is skipped.

#### 2.5: Scheme Details (Per Customer)
```sql
SELECT name, asset_type 
FROM schemes 
WHERE id = <scheme_id>
```
**Location:** Line 99-103  
**Filter:** `if (scheme == null) continue;` (Line 105)

**BLOCKER #5:** If scheme record missing, customer is skipped.

#### 2.6: Today's Payments Check (Per Customer)
```sql
SELECT amount, payment_method 
FROM payments 
WHERE customer_id = <customer_id> 
  AND staff_id = <staffProfileId> 
  AND payment_date = <today>
  AND status = 'completed'
```
**Location:** Line 109-115  
**Purpose:** Determines `paidToday` flag

**NOTE:** This is not a blocker (returns empty list if no payments), but affects `paidToday` flag.

### Step 3: Target Data Query
**File:** `lib/services/staff_data_service.dart:402-417`  
**Function:** `getDailyTarget(String staffProfileId)`

**Query:**
```sql
SELECT daily_target_amount, daily_target_customers 
FROM staff_metadata 
WHERE profile_id = <staffProfileId>
```
**Location:** Line 404-408

**BLOCKER #6:** If `staff_metadata` record doesn't exist for `staffProfileId`, returns:
```dart
{'amount': 0.0, 'customers': 0}
```

**CRITICAL FACT:** Default values in schema are `0.00` and `0`, so even if record exists but targets not set, shows `0/0`.

### Step 4: Today's Stats Query
**File:** `lib/services/staff_data_service.dart:162-230`  
**Function:** `getTodayStats(String staffProfileId)`

**Query:**
```sql
SELECT amount, payment_method, customer_id 
FROM payments 
WHERE staff_id = <staffProfileId> 
  AND payment_date = <today>
  AND status = 'completed'
```
**Location:** Line 167-172

**Dependency:** Calls `getAssignedCustomers(staffProfileId)` at line 192 to get `totalCustomers`.

**BLOCKER #7:** If `getAssignedCustomers()` returns empty (due to blockers #1-5), then:
- `totalCustomers = 0`
- `collectedCount = 0` (from payments)
- `pendingCount = 0`
- All stats = 0

---

## 2. CONTRACT COMPARISON

### StaffMockData.assignedCustomers Structure
**File:** `lib/mock_data/staff_mock_data.dart:33-246`

**Fields Provided (ALL NON-NULL):**
```dart
{
  'id': 'C001',                    // String, always present
  'name': 'Ravi Kumar',            // String, always present
  'phone': '+91 9876543210',       // String, always present
  'customerId': 'C12345',          // String, always present
  'address': '123 Main Street...', // String, always present
  'scheme': 'Gold Scheme 3',       // String, always present
  'schemeNumber': 3,               // int, always present
  'frequency': 'Daily',            // String, always present
  'minAmount': 550.0,              // double, always present
  'maxAmount': 1000.0,             // double, always present
  'dueAmount': 750.0,              // double, always present
  'totalPayments': 245,            // int, always present
  'missedPayments': 2,             // int, always present
  'paidToday': false,              // bool, always present
}
```

### StaffDataService.getAssignedCustomers() Return Structure
**File:** `lib/services/staff_data_service.dart:135-151`

**Fields Returned:**
```dart
{
  'id': customerId,                                    // String (from DB)
  'customer_id': customerId,                           // String (duplicate for compatibility)
  'name': profile['name'] ?? 'Unknown',               // String (nullable, has fallback)
  'phone': profile['phone'] ?? '',                    // String (nullable, has fallback)
  'address': customer['address'] ?? '',               // String (nullable, has fallback)
  'scheme': scheme['name'] ?? 'Unknown Scheme',       // String (nullable, has fallback)
  'schemeNumber': _extractSchemeNumber(...),          // int (always 1+)
  'frequency': frequency,                             // String (mapped from DB enum)
  'minAmount': minAmount,                              // double (from DB, non-null)
  'maxAmount': maxAmount,                              // double (from DB, non-null)
  'dueAmount': dueAmount,                              // double (calculated, non-null)
  'totalPayments': userSchemes['payments_made'] ?? 0, // int (nullable, has fallback)
  'missedPayments': userSchemes['payments_missed'] ?? 0, // int (nullable, has fallback)
  'paidToday': paidToday,                             // bool (calculated, non-null)
  'user_scheme_id': userSchemes['id'],                // String (for payment insertion)
}
```

### Missing/Changed Fields Analysis

**✅ PRESENT:** All required fields exist with fallbacks.

**⚠️ POTENTIAL NULLS:**
- `profile['name']` can be null → falls back to 'Unknown'
- `profile['phone']` can be null → falls back to ''
- `customer['address']` can be null → falls back to ''
- `scheme['name']` can be null → falls back to 'Unknown Scheme'
- `userSchemes['payments_made']` can be null → falls back to 0
- `userSchemes['payments_missed']` can be null → falls back to 0

**❌ MISSING FIELD:**
- `'customerId'` field (mock had both `id` and `customerId`) — but code uses `id` or `customer_id`, so this is fine.

**✅ FIELD NAME CHANGES:**
- None — all field names match mock data structure.

---

## 3. FILTER ANALYSIS

### Filter 1: Staff Assignments Existence
**Location:** `lib/services/staff_data_service.dart:35-37`  
**Condition:** `if (assignments.isEmpty) return [];`  
**Intent:** ✅ Intentional — staff must have assignments to see customers  
**Strictness:** ✅ Same as mock (mock assumed all customers assigned)  
**Impact:** If no `staff_assignments` records exist → **0 customers**

### Filter 2: Customer Records Existence
**Location:** `lib/services/staff_data_service.dart:66-68`  
**Condition:** `if (customersResponse.isEmpty) return [];`  
**Intent:** ✅ Intentional — customers must exist  
**Strictness:** ✅ Same as mock  
**Impact:** If customer IDs from assignments don't match `customers.id` → **0 customers**

### Filter 3: Profile Existence (Per Customer)
**Location:** `lib/services/staff_data_service.dart:84`  
**Condition:** `if (profile == null) continue;`  
**Intent:** ✅ Intentional — customer must have profile  
**Strictness:** ✅ Same as mock (mock assumed profiles exist)  
**Impact:** If `customers.profile_id` doesn't match `profiles.id` → customer skipped

### Filter 4: Active User Schemes (Per Customer)
**Location:** `lib/services/staff_data_service.dart:95`  
**Condition:** `if (userSchemes == null) continue;`  
**Intent:** ✅ Intentional — only show customers with active schemes  
**Strictness:** ⚠️ **STRICTER THAN MOCK** — mock showed all customers regardless of scheme status  
**Impact:** If customer has no active `user_schemes` → customer skipped  
**CRITICAL:** This is the most likely blocker if customers exist but have no active schemes.

### Filter 5: Scheme Details Existence (Per Customer)
**Location:** `lib/services/staff_data_service.dart:105`  
**Condition:** `if (scheme == null) continue;`  
**Intent:** ✅ Intentional — scheme must exist  
**Strictness:** ✅ Same as mock  
**Impact:** If `user_schemes.scheme_id` doesn't match `schemes.id` → customer skipped

### Filter 6: User Schemes Status = 'active'
**Location:** `lib/services/staff_data_service.dart:91`  
**Condition:** `.eq('status', 'active')`  
**Intent:** ✅ Intentional — only active schemes  
**Strictness:** ⚠️ **STRICTER THAN MOCK** — mock didn't filter by status  
**Impact:** If `user_schemes.status` is not 'active' → customer skipped

### Filter 7: Staff Type = 'collection' (Mobile App Access)
**Location:** `lib/services/role_routing_service.dart:98-103`  
**Condition:** `if (staffType != 'collection') throw Exception(...)`  
**Intent:** ✅ Intentional — only collection staff can access mobile app  
**Strictness:** ✅ New requirement (not in mock)  
**Impact:** If `staff_metadata.staff_type` is 'office' or null → logout, never reaches dashboard

**NOTE:** This filter happens BEFORE dashboard loads, so if staff reaches dashboard, they are collection type.

---

## 4. STAFF TYPE IMPACT

### Current Implementation
**File:** `lib/services/role_routing_service.dart:98-103`

**Logic:**
```dart
if (role == 'staff') {
  final staffType = await fetchStaffType(profileId);
  if (staffType != 'collection') {
    throw Exception('This account does not have mobile app access.');
  }
  return true;
}
```

**Facts:**
- ✅ Office staff (`staff_type = 'office'`) are **excluded** — they cannot reach dashboard
- ✅ Collection staff (`staff_type = 'collection'`) are **required** — only they can access
- ❌ **NO FALLBACK** — if `staff_metadata` record missing or `staff_type` is null → logout

**Impact on Empty UI:**
- If staff reaches dashboard, they MUST be collection type
- If `staff_metadata` doesn't exist → staff blocked before dashboard
- If `staff_metadata.staff_type` is null → staff blocked before dashboard

**Database Default:**
- Schema default: `staff_type TEXT NOT NULL DEFAULT 'collection'` (line 123)
- So if record exists, it should be 'collection' unless explicitly set to 'office'

---

## 5. NUMERIC NULLS ANALYSIS

### Fields That Can Be Null (But Have Fallbacks)

**File:** `lib/services/staff_data_service.dart`

1. **Line 128-129:** `min_amount`, `max_amount`
   - Source: `userSchemes['min_amount']`, `userSchemes['max_amount']`
   - Type: `num` (can be null in DB)
   - Usage: `(userSchemes['min_amount'] as num).toDouble()`
   - **RISK:** If null, `as num` cast fails → runtime error
   - **Current Code:** No null check before cast

2. **Line 147:** `payments_made`
   - Source: `userSchemes['payments_made']`
   - Type: `int?` (nullable)
   - Usage: `userSchemes['payments_made'] as int? ?? 0`
   - **SAFE:** Has fallback

3. **Line 148:** `payments_missed`
   - Source: `userSchemes['payments_missed']`
   - Type: `int?` (nullable)
   - Usage: `userSchemes['payments_missed'] as int? ?? 0`
   - **SAFE:** Has fallback

4. **Line 411:** `daily_target_amount`
   - Source: `metadata?['daily_target_amount']`
   - Type: `num?` (nullable)
   - Usage: `(metadata?['daily_target_amount'] as num?)?.toDouble() ?? 0.0`
   - **SAFE:** Has fallback

5. **Line 412:** `daily_target_customers`
   - Source: `metadata?['daily_target_customers']`
   - Type: `int?` (nullable)
   - Usage: `metadata?['daily_target_customers'] as int? ?? 0`
   - **SAFE:** Has fallback

### Fields Used in Arithmetic (Potential Null Issues)

**File:** `lib/screens/staff/collect_tab_screen.dart`

1. **Line 77:** `_progress = _targetAmount > 0 ? (_collectedAmount / _targetAmount).clamp(0.0, 1.0) : 0.0;`
   - **SAFE:** Checks for `> 0` before division

2. **Line 315:** `dueAmount.toStringAsFixed(0)`
   - Source: `customer['dueAmount'] as double`
   - **RISK:** If `dueAmount` is null in map → runtime error
   - **Current Code:** Assumes non-null (but calculated, so should be safe)

3. **Line 444:** `paidAmount.toStringAsFixed(0)`
   - Source: `todayPayment['amount'] as double?`
   - **SAFE:** Nullable with null check before usage

**File:** `lib/services/staff_data_service.dart:420-426`

4. **Line 421-423:** `calculateTotalDue()`
   ```dart
   final missedCount = customer['missedPayments'] as int;
   final dueAmount = customer['dueAmount'] as double;
   final minAmount = customer['minAmount'] as double;
   ```
   - **RISK:** If any of these are null in map → runtime error
   - **Current Code:** Assumes non-null (but all have fallbacks in `getAssignedCustomers()`)

---

## 6. EXACT ROOT CAUSES

### A. EXACT REASON: customers = 0

**Primary Blockers (in order of likelihood):**

1. **NO STAFF ASSIGNMENTS** (Most Likely)
   - **Location:** `staff_data_service.dart:35-37`
   - **Condition:** `staff_assignments` table has no records for `staffProfileId`
   - **Query:** `SELECT customer_id FROM staff_assignments WHERE staff_id = <uuid> AND is_active = true`
   - **Result:** Returns empty → function returns `[]` immediately

2. **NO ACTIVE USER_SCHEMES** (Very Likely)
   - **Location:** `staff_data_service.dart:95`
   - **Condition:** Customers exist but have no `user_schemes` with `status = 'active'`
   - **Query:** `SELECT ... FROM user_schemes WHERE customer_id = <id> AND status = 'active' LIMIT 1`
   - **Result:** Returns null → customer skipped via `continue`

3. **MISSING PROFILES** (Less Likely)
   - **Location:** `staff_data_service.dart:84`
   - **Condition:** `customers.profile_id` doesn't match `profiles.id`
   - **Result:** Customer skipped

4. **MISSING SCHEMES** (Less Likely)
   - **Location:** `staff_data_service.dart:105`
   - **Condition:** `user_schemes.scheme_id` doesn't match `schemes.id`
   - **Result:** Customer skipped

5. **PROFILE ID RESOLUTION FAILURE** (Possible)
   - **Location:** `collect_tab_screen.dart:49-52`
   - **Condition:** `RoleRoutingService.getCurrentProfileId()` returns null
   - **Result:** `_loadData()` returns early, `_customers = []`

### B. EXACT REASON: targets = 0/0

**Location:** `lib/services/staff_data_service.dart:402-417`

**Query:**
```sql
SELECT daily_target_amount, daily_target_customers 
FROM staff_metadata 
WHERE profile_id = <staffProfileId>
```

**Blockers:**

1. **NO STAFF_METADATA RECORD**
   - **Condition:** `staff_metadata` table has no record for `staffProfileId`
   - **Result:** Returns `{'amount': 0.0, 'customers': 0}` (line 415)

2. **TARGETS NOT SET (DEFAULT VALUES)**
   - **Condition:** Record exists but `daily_target_amount = 0.00` and `daily_target_customers = 0`
   - **Schema Default:** `DEFAULT 0.00` and `DEFAULT 0` (lines 124-125)
   - **Result:** Shows `0/0` even if record exists

3. **PROFILE ID MISMATCH**
   - **Condition:** `staff_metadata.profile_id` doesn't match `staffProfileId`
   - **Result:** Returns default `{'amount': 0.0, 'customers': 0}`

### C. EXACT REASON: reports crash or show empty

**Location:** `lib/screens/staff/reports_screen.dart:20-52`

**Dependencies:**
- `getTodayStats()` → depends on `getAssignedCustomers()` (line 192)
- `getPriorityCustomers()` → depends on `getAssignedCustomers()` (line 320)
- `getSchemeBreakdown()` → depends on today's payments (line 340-350)

**Blockers:**

1. **EMPTY ASSIGNED CUSTOMERS**
   - If `getAssignedCustomers()` returns `[]`:
     - `totalCustomers = 0` (line 193)
     - `priorityCustomers = []` (line 321-323)
     - All stats show 0

2. **NO TODAY'S PAYMENTS**
   - If no payments today:
     - `totalAmount = 0.0` (line 174)
     - `customersCollected = 0` (line 194)
     - `schemeBreakdown = {'Gold': 0.0, 'Silver': 0.0}` (line 368)

3. **NULL HANDLING IN UI**
   - **Line 224:** `(_todayStats['completionPercent'] as num?)?.toDouble() ?? 0.0)`
   - **RISK:** Extra closing parenthesis causes syntax error (should be fixed)
   - **Line 247, 282:** Similar nullable access patterns
   - **SAFE:** All have fallbacks

---

## 7. MINIMAL LIST OF MISSING MAPPINGS OR FILTERS

### Missing Data Requirements (Must Exist in DB):

1. **staff_assignments records**
   - Required: At least one record with `staff_id = <staffProfileId>` and `is_active = true`
   - Missing → 0 customers

2. **customers records**
   - Required: Records matching `customer_id` from `staff_assignments`
   - Missing → 0 customers

3. **profiles records**
   - Required: Records matching `customers.profile_id`
   - Missing → customers filtered out

4. **user_schemes records**
   - Required: At least one record per customer with `status = 'active'`
   - Missing → customers filtered out

5. **schemes records**
   - Required: Records matching `user_schemes.scheme_id`
   - Missing → customers filtered out

6. **staff_metadata record**
   - Required: Record with `profile_id = <staffProfileId>`
   - Missing → targets show 0/0

### Stricter Filters Than Mock:

1. **Active Schemes Only**
   - Mock: Showed all customers
   - Real: Only customers with `user_schemes.status = 'active'`
   - **Impact:** Customers with paused/completed/cancelled schemes are hidden

2. **Staff Assignments Required**
   - Mock: Assumed all customers assigned
   - Real: Must have `staff_assignments` record
   - **Impact:** Unassigned customers never appear

---

## 8. WHAT MUST CHANGE (DATA ONLY)

### To Restore Staff UI Functionality:

1. **Create staff_assignments records**
   - Insert records linking `staffProfileId` (UUID) to `customer_id` (UUID)
   - Set `is_active = true`
   - **Without this:** 0 customers guaranteed

2. **Ensure active user_schemes exist**
   - For each assigned customer, ensure at least one `user_schemes` record with `status = 'active'`
   - **Without this:** Customers filtered out even if assigned

3. **Create staff_metadata record**
   - Insert record with `profile_id = <staffProfileId>`
   - Set `daily_target_amount > 0` and `daily_target_customers > 0`
   - **Without this:** Targets show 0/0

4. **Verify data integrity**
   - `customers.profile_id` must match `profiles.id`
   - `user_schemes.scheme_id` must match `schemes.id`
   - **Without this:** Customers filtered out

5. **Fix null handling in min_amount/max_amount**
   - **Location:** `staff_data_service.dart:128-129`
   - **Current:** `(userSchemes['min_amount'] as num).toDouble()`
   - **Risk:** If null, cast fails
   - **Fix Required:** Add null check: `(userSchemes['min_amount'] as num?)?.toDouble() ?? 0.0`

6. **Verify staffProfileId resolution**
   - Ensure `RoleRoutingService.getCurrentProfileId()` returns valid UUID
   - **Without this:** Early return, 0 customers

---

## SUMMARY

**Primary Blocker:** Missing `staff_assignments` records linking staff to customers.

**Secondary Blocker:** Customers exist but have no active `user_schemes`.

**Tertiary Blocker:** Missing `staff_metadata` record or targets set to 0.

**All filters are intentional and correct — the issue is missing data in database, not incorrect code logic.**

