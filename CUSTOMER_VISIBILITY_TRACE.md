# CUSTOMER VISIBILITY TRACE — GROUND TRUTH REPORT

**Date:** Current  
**Purpose:** Locate exact queries and filters that decide customer visibility  
**Status:** FACTS ONLY — NO FIXES

---

## STEP 1 — CUSTOMER FETCH QUERY

### File: `lib/services/staff_data_service.dart`
### Function: `getAssignedCustomers(String staffProfileId)`
### Lines: 29-163

#### FULL QUERY CHAIN:

```dart
// QUERY 1: Staff Assignments
// Lines 32-36
final assignments = await _supabase
    .from('staff_assignments')
    .select('customer_id')
    .eq('staff_id', staffProfileId)
    .eq('is_active', true);

// FILTER: Line 38-40
if (assignments.isEmpty) {
  return [];
}

// QUERY 2: Customers
// Lines 52-67
var query = _supabase
    .from('customers')
    .select('id, profile_id, address');

// Build OR query for multiple customer IDs
if (customerIds.length == 1) {
  query = query.eq('id', customerIds[0]);
} else {
  final orConditions = customerIds
      .map((id) => 'id.eq.$id')
      .join(',');
  query = query.or(orConditions);
}

final customersResponse = await query;

// FILTER: Line 69-71
if (customersResponse.isEmpty) {
  return [];
}

// QUERY 3: Profile (per customer, in loop)
// Lines 81-85
final profile = await _supabase
    .from('profiles')
    .select('id, name, phone')
    .eq('id', profileId)
    .maybeSingle();

// FILTER: Line 87
if (profile == null) continue;

// QUERY 4: User Schemes (per customer, in loop)
// Lines 90-96
final userSchemes = await _supabase
    .from('user_schemes')
    .select('id, scheme_id, status, payment_frequency, min_amount, max_amount, total_amount_paid, payments_made, payments_missed, accumulated_grams')
    .eq('customer_id', customerId)
    .eq('status', 'active')
    .limit(1)
    .maybeSingle();

// FILTER: Line 98
if (userSchemes == null) continue;

// QUERY 5: Scheme (per customer, in loop)
// Lines 102-106
final scheme = await _supabase
    .from('schemes')
    .select('name, asset_type')
    .eq('id', schemeId)
    .maybeSingle();

// FILTER: Line 108
if (scheme == null) continue;

// QUERY 6: Today's Payments (per customer, in loop)
// Lines 112-118
final todayPayments = await _supabase
    .from('payments')
    .select('amount, payment_method')
    .eq('customer_id', customerId)
    .eq('staff_id', staffProfileId)
    .eq('payment_date', today)
    .eq('status', 'completed');
```

---

### File: `lib/services/staff_data_service.dart`
### Function: `getSchemeBreakdown(String staffProfileId)`
### Lines: 335-373

#### FULL QUERY CHAIN:

```dart
// QUERY: Payments with INNER JOINs
// Lines 339-349
final payments = await _supabase
    .from('payments')
    .select('''
      amount,
      user_schemes!inner(
        schemes!inner(asset_type)
      )
    ''')
    .eq('staff_id', staffProfileId)
    .eq('payment_date', today)
    .eq('status', 'completed');
```

**Note:** This uses `!inner` joins, which means:
- Payment MUST have a `user_scheme_id` that exists
- `user_scheme` MUST have a `scheme_id` that exists
- If either is missing, payment is excluded

---

## STEP 2 — ANSWERS WITH CODE PROOF

### Q1: Does customer list query use INNER JOIN?

**ANSWER: NO**

**Proof:**
- Line 52-54: `_supabase.from('customers').select('id, profile_id, address')` — NO joins
- Lines 81-85: Separate query for `profiles` — NO join
- Lines 90-96: Separate query for `user_schemes` — NO join
- Lines 102-106: Separate query for `schemes` — NO join
- Lines 112-118: Separate query for `payments` — NO join

**All queries are separate, executed sequentially in a loop.**

---

### Q2: Does it filter by payment.status?

**ANSWER: YES (for today's payments only)**

**Proof:**
- Line 118: `.eq('status', 'completed')`

**Allowed status:** `'completed'` only

**Note:** This filter is ONLY applied when checking if customer paid today (lines 112-118). It does NOT filter the customer list itself.

---

### Q3: Does it filter by date?

**ANSWER: YES (for today's payments only)**

**Proof:**
- Line 111: `final today = DateFormat('yyyy-MM-dd').format(DateTime.now());`
- Line 117: `.eq('payment_date', today)`

**Filters by:**
- `payment_date` = today (for determining `paidToday` flag)
- Does NOT filter by `next_due_date`
- Does NOT filter customers by date

**Note:** This date filter is ONLY used to determine if customer paid today. It does NOT exclude customers from the list.

---

### Q4: Does it exclude completed schemes?

**ANSWER: YES**

**Proof:**
- Line 94: `.eq('status', 'active')`

**Excludes:**
- `user_schemes` where `status != 'active'`
- Line 98: `if (userSchemes == null) continue;` — customer skipped if no active scheme

---

### Q5: Does it exclude completed payments?

**ANSWER: NO (for customer list)**

**Proof:**
- Customer list query (lines 52-67) does NOT filter by payments
- Payments query (lines 112-118) is only used to set `paidToday` flag
- Completed payments do NOT exclude customers from list

**Note:** However, `getSchemeBreakdown` DOES filter by `status = 'completed'` (line 349).

---

### Q6: Does it exclude customers with zero pending?

**ANSWER: NO**

**Proof:**
- No filter on `payments_missed` in `getAssignedCustomers`
- No filter on pending amount
- All assigned customers with active schemes are included

---

### Q7: Does it calculate "pending" using a formula?

**ANSWER: NO (in getAssignedCustomers)**

**Proof:**
- `getAssignedCustomers` does NOT calculate pending
- It only reads `payments_missed` from `user_schemes` (line 92, 151)

**Pending calculation happens in `getTodayStats`:**
- Line 199: `final pendingCount = totalCustomers - collectedCount;`
- Formula: `totalCustomers - customersCollected`

**Where:**
- `totalCustomers` = length of `getAssignedCustomers()` result (line 197)
- `customersCollected` = count of unique `customer_id` in today's completed payments (line 192)

---

## STEP 3 — DATA FLOW TRACE FOR ONE PAYMENT

### Known Payment:
- `staff_id` = `48ab80f5-7f9f-47aa-a56d-906bb94f9ece`
- `amount` = `1000`
- `status` = `completed`

### TRACE PATH:

#### Step 1: Payment → Customer List

**Entry Point:** `lib/screens/staff/collect_tab_screen.dart:57`
```dart
StaffDataService.getAssignedCustomers(_staffProfileId!)
```

**Query 1: Staff Assignments**
- **File:** `lib/services/staff_data_service.dart:32-36`
- **Query:**
```dart
.from('staff_assignments')
.select('customer_id')
.eq('staff_id', staffProfileId)  // staffProfileId = 48ab80f5-7f9f-47aa-a56d-906bb94f9ece
.eq('is_active', true)
```
- **Condition to pass:** Must return at least one row with `customer_id`
- **Condition that could fail:** No `staff_assignments` record with `staff_id = 48ab80f5-7f9f-47aa-a56d-906bb94f9ece` AND `is_active = true`
- **Exact conditional:** Line 38: `if (assignments.isEmpty) return [];`

**Query 2: Customers**
- **File:** `lib/services/staff_data_service.dart:52-67`
- **Query:**
```dart
.from('customers')
.select('id, profile_id, address')
.eq('id', customerId)  // or .or() for multiple IDs
```
- **Condition to pass:** Customer ID from assignments must exist in `customers` table
- **Condition that could fail:** Customer ID from `staff_assignments` does not exist in `customers` table
- **Exact conditional:** Line 69: `if (customersResponse.isEmpty) return [];`

**Query 3: Profile**
- **File:** `lib/services/staff_data_service.dart:81-85`
- **Query:**
```dart
.from('profiles')
.select('id, name, phone')
.eq('id', profileId)  // profileId from customer.profile_id
.maybeSingle()
```
- **Condition to pass:** `profile` must not be null
- **Condition that could fail:** `customer.profile_id` does not exist in `profiles` table
- **Exact conditional:** Line 87: `if (profile == null) continue;`

**Query 4: User Schemes**
- **File:** `lib/services/staff_data_service.dart:90-96`
- **Query:**
```dart
.from('user_schemes')
.select('id, scheme_id, status, payment_frequency, min_amount, max_amount, total_amount_paid, payments_made, payments_missed, accumulated_grams')
.eq('customer_id', customerId)
.eq('status', 'active')  // ← CRITICAL FILTER
.limit(1)
.maybeSingle()
```
- **Condition to pass:** Must have at least one `user_scheme` with `status = 'active'` for this `customer_id`
- **Condition that could fail:** 
  - No `user_schemes` record for this `customer_id`
  - OR all `user_schemes` have `status != 'active'`
- **Exact conditional:** Line 98: `if (userSchemes == null) continue;`

**Query 5: Scheme**
- **File:** `lib/services/staff_data_service.dart:102-106`
- **Query:**
```dart
.from('schemes')
.select('name, asset_type')
.eq('id', schemeId)  // schemeId from userSchemes.scheme_id
.maybeSingle()
```
- **Condition to pass:** `scheme` must not be null
- **Condition that could fail:** `userSchemes.scheme_id` does not exist in `schemes` table
- **Exact conditional:** Line 108: `if (scheme == null) continue;`

**Query 6: Today's Payments (for paidToday flag)**
- **File:** `lib/services/staff_data_service.dart:112-118`
- **Query:**
```dart
.from('payments')
.select('amount, payment_method')
.eq('customer_id', customerId)
.eq('staff_id', staffProfileId)  // staffProfileId = 48ab80f5-7f9f-47aa-a56d-906bb94f9ece
.eq('payment_date', today)  // today = current date in 'yyyy-MM-dd' format
.eq('status', 'completed')
```
- **Condition to pass:** Payment exists with matching `customer_id`, `staff_id`, `payment_date = today`, `status = 'completed'`
- **Condition that could fail:**
  - Payment `payment_date` is not today
  - Payment `status` is not 'completed'
  - Payment `staff_id` does not match
- **Exact conditional:** Line 120: `final paidToday = todayPayments.isNotEmpty;`

---

#### Step 2: Payment → Scheme Breakdown

**Entry Point:** `lib/screens/staff/reports_screen.dart:46`
```dart
StaffDataService.getSchemeBreakdown(_staffProfileId!)
```

**Query: Payments with INNER JOINs**
- **File:** `lib/services/staff_data_service.dart:339-349`
- **Query:**
```dart
.from('payments')
.select('''
  amount,
  user_schemes!inner(
    schemes!inner(asset_type)
  )
''')
.eq('staff_id', staffProfileId)  // staffProfileId = 48ab80f5-7f9f-47aa-a56d-906bb94f9ece
.eq('payment_date', today)  // today = current date in 'yyyy-MM-dd' format
.eq('status', 'completed')
```

**Condition to pass:**
1. Payment must exist with `staff_id = 48ab80f5-7f9f-47aa-a56d-906bb94f9ece`
2. Payment `payment_date` must equal today
3. Payment `status` must be 'completed'
4. Payment `user_scheme_id` must exist in `user_schemes` table (INNER JOIN requirement)
5. `user_scheme.scheme_id` must exist in `schemes` table (INNER JOIN requirement)

**Condition that could fail:**
- Payment `payment_date` is not today → **MOST LIKELY CAUSE**
- Payment `status` is not 'completed'
- Payment `user_scheme_id` is NULL or does not exist in `user_schemes`
- `user_scheme.scheme_id` is NULL or does not exist in `schemes`
- Payment `staff_id` does not match

**Exact conditional:** None — if query returns empty, `goldTotal` and `silverTotal` remain 0.0 (lines 351-365)

---

## STEP 4 — AUTH / RLS SIDE EFFECTS

### Q1: Do customer queries run before staff_metadata resolves?

**ANSWER: NO**

**Proof:**
- **File:** `lib/screens/staff/collect_tab_screen.dart:45-63`
- **Lines 49-53:**
```dart
_staffProfileId = await RoleRoutingService.getCurrentProfileId();
if (_staffProfileId == null) {
  setState(() => _isLoading = false);
  return;
}
```
- `getCurrentProfileId()` does NOT query `staff_metadata` — it only queries `profiles` (line 159-163 in `role_routing_service.dart`)
- Customer queries (line 57) run AFTER `_staffProfileId` is resolved, but `_staffProfileId` comes from `profiles.id`, not `staff_metadata`

**Conclusion:** Customer queries do NOT depend on `staff_metadata` resolution.

---

### Q2: Are queries skipped on null staff_type?

**ANSWER: NO**

**Proof:**
- **File:** `lib/screens/staff/collect_tab_screen.dart:45-63`
- No check for `staff_type` before calling `getAssignedCustomers()`
- `getAssignedCustomers()` does NOT check `staff_type` (lines 29-163 in `staff_data_service.dart`)

**Conclusion:** Customer queries are NOT skipped based on `staff_type`.

---

### Q3: Does cached provider state block re-fetch?

**ANSWER: NO (for customer list)**

**Proof:**
- **File:** `lib/screens/staff/collect_tab_screen.dart:45-63`
- `_loadData()` is called in `initState()` (line 42)
- Each call to `_loadData()` creates fresh queries (lines 56-63)
- No caching mechanism in `StaffDataService.getAssignedCustomers()`

**However:** If `_loadData()` is not called after payment insertion, UI will show stale data.

**Conclusion:** No caching blocks re-fetch, but UI must call `_loadData()` to refresh.

---

## STEP 5 — CRITICAL FILTERS SUMMARY

### Customer List Visibility Requirements:

1. **MUST have `staff_assignments` record:**
   - `staff_id = staffProfileId`
   - `is_active = true`
   - **Line 38:** `if (assignments.isEmpty) return [];`

2. **MUST have `customers` record:**
   - `id` must match `staff_assignments.customer_id`
   - **Line 69:** `if (customersResponse.isEmpty) return [];`

3. **MUST have `profiles` record:**
   - `id` must match `customer.profile_id`
   - **Line 87:** `if (profile == null) continue;`

4. **MUST have active `user_schemes` record:**
   - `customer_id` must match
   - `status = 'active'` ← **CRITICAL**
   - **Line 98:** `if (userSchemes == null) continue;`

5. **MUST have `schemes` record:**
   - `id` must match `userSchemes.scheme_id`
   - **Line 108:** `if (scheme == null) continue;`

### Scheme Breakdown Visibility Requirements:

1. **MUST have payment with:**
   - `staff_id = staffProfileId`
   - `payment_date = today` ← **CRITICAL**
   - `status = 'completed'`
   - `user_scheme_id` exists (INNER JOIN requirement)
   - `user_scheme.scheme_id` exists (INNER JOIN requirement)

---

## GROUND TRUTH FINDINGS

### Most Likely Causes for Empty Customer List:

1. **No `staff_assignments` record** for `staff_id = 48ab80f5-7f9f-47aa-a56d-906bb94f9ece`
2. **No active `user_schemes`** for the customer (all have `status != 'active'`)
3. **Customer `profile_id` does not exist** in `profiles` table

### Most Likely Causes for Empty Scheme Breakdown:

1. **Payment `payment_date` is not today** (payment was made on a different date)
2. **Payment `status` is not 'completed'**
3. **Payment `user_scheme_id` is NULL or invalid** (INNER JOIN fails)

### Most Likely Cause for Negative Pending Count:

**Formula:** `pendingCount = totalCustomers - collectedCount` (line 199)

**Where:**
- `totalCustomers` = length of `getAssignedCustomers()` result
- `collectedCount` = count of unique `customer_id` in today's completed payments

**If `getAssignedCustomers()` returns empty list (0 customers) but payments exist:**
- `totalCustomers = 0`
- `collectedCount > 0` (if payments exist)
- `pendingCount = 0 - collectedCount = negative`

**Root cause:** Customer list is empty, but payments still exist and are counted.

---

## END OF REPORT





