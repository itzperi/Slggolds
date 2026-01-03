# CUSTOMER VISIBILITY SOLUTION RESEARCH

**Date:** Current  
**Purpose:** Research and propose solution for customer visibility issues  
**Status:** RESEARCH ONLY — NO EXECUTION

---

## 🎯 EXECUTIVE SUMMARY

### Problem:
- Customer list empty (but payments exist)
- Scheme breakdown empty (but payments exist)
- Pending count negative

### Root Cause:
Customer list requires `user_schemes.status = 'active'`, but payments may reference non-active schemes.

### ✅ RECOMMENDED SOLUTION: **Option C (Hybrid) + Payment Service Update**

**Why Option C (NOT Option A):**
1. **✅ Maintains App Integrity:** Payment flow requires `user_scheme_id` (NOT NULL constraint) → Customer must have scheme
2. **✅ Seamless UI Flow:** Customer list → Payment screen → Payment success (no dead ends)
3. **✅ Complete UI Data:** All required fields (`scheme`, `minAmount`, `maxAmount`, `frequency`) available
4. **✅ Fixes All Symptoms:** Empty list, empty breakdown, negative pending — all fixed

**Why NOT Option A:**
1. **❌ Breaks Payment Flow:** Shows customers without schemes → Payment screen fails
2. **❌ Incomplete UI Data:** Missing scheme info, validation fails
3. **❌ Database Constraint Risk:** Payment requires `user_scheme_id` (NOT NULL)

**Implementation:**
- Remove `.eq('status', 'active')` from `getAssignedCustomers`
- Get latest scheme (any status) instead
- Update `PaymentService.getUserSchemeId()` to allow paused schemes (optional)
- Fix pending calculation to use consistent source

---

## PROBLEM SUMMARY

### Current Symptoms:
1. **Customer list is empty** (but payments exist)
2. **Gold scheme breakdown shows "No collections today"** (but payments exist)
3. **Pending count goes negative**

### Root Cause (Confirmed):
Three incompatible definitions of "customer":
- **Customer list:** `staff_assignments` → requires `user_schemes.status = 'active'`
- **Collections:** `payments` with `payment_date = today`
- **Pending:** `totalCustomers - collectedCount` (where they come from different sources)

---

## SCHEMA ANALYSIS

### Key Tables:

1. **`staff_assignments`** (Lines 369-384 in `supabase_schema.sql`)
   - `staff_id` → `profiles.id`
   - `customer_id` → `customers.id`
   - `is_active` BOOLEAN
   - **Purpose:** Business relationship — which staff collects from which customers

2. **`user_schemes`** (Lines 186-217 in `supabase_schema.sql`)
   - `customer_id` → `customers.id`
   - `status` ENUM: `'active'`, `'paused'`, `'completed'`, `'mature'`, `'cancelled'`
   - **Purpose:** Customer's enrollment in a scheme

3. **`payments`** (Lines 231-265 in `supabase_schema.sql`)
   - `user_scheme_id` NOT NULL → `user_schemes.id`
   - `customer_id` NOT NULL → `customers.id`
   - `staff_id` NULLABLE → `profiles.id`
   - `payment_date` DATE (defaults to CURRENT_DATE)
   - `status` ENUM: `'pending'`, `'completed'`, `'failed'`, `'reversed'`
   - **Purpose:** Payment records (append-only)

### Key Relationships:
- `staff_assignments` is the **business relationship** (staff ↔ customer)
- `user_schemes` is the **product relationship** (customer ↔ scheme)
- `payments` references **both** `user_scheme_id` AND `customer_id`

---

## CURRENT QUERY ANALYSIS

### Customer List Query (`getAssignedCustomers`):
**File:** `lib/services/staff_data_service.dart:29-163`

**Query Chain:**
1. `staff_assignments` WHERE `staff_id = X` AND `is_active = true`
2. `customers` WHERE `id IN (customer_ids)`
3. `profiles` WHERE `id = customer.profile_id` (per customer)
4. `user_schemes` WHERE `customer_id = X` AND `status = 'active'` ← **FILTER**
5. `schemes` WHERE `id = user_scheme.scheme_id` (per customer)
6. `payments` WHERE `customer_id = X` AND `staff_id = X` AND `payment_date = today` AND `status = 'completed'` (for `paidToday` flag)

**Critical Filter:** Line 94: `.eq('status', 'active')`
**Critical Skip:** Line 98: `if (userSchemes == null) continue;`

**Result:** Customer is **excluded** if no active scheme exists.

---

### Collections Query (`getTodayCollections`):
**File:** `lib/services/staff_data_service.dart:229-283`

**Query:**
```dart
.from('payments')
.select('customer_id, amount, payment_method, payment_time, customers!inner(profiles!inner(name))')
.eq('staff_id', staffProfileId)
.eq('payment_date', today)  // ← CRITICAL FILTER
.eq('status', 'completed')
```

**Critical Filter:** Line 245: `.eq('payment_date', today)`

**Result:** Only payments from **today** are included.

---

### Scheme Breakdown Query (`getSchemeBreakdown`):
**File:** `lib/services/staff_data_service.dart:335-373`

**Query:**
```dart
.from('payments')
.select('amount, user_schemes!inner(schemes!inner(asset_type))')
.eq('staff_id', staffProfileId)
.eq('payment_date', today)  // ← CRITICAL FILTER
.eq('status', 'completed')
```

**Critical Filters:**
- Line 348: `.eq('payment_date', today)`
- Line 343: `user_schemes!inner` (INNER JOIN — payment MUST have valid `user_scheme_id`)

**Result:** Only today's payments with valid `user_scheme_id` are included.

---

### Pending Count Calculation (`getTodayStats`):
**File:** `lib/services/staff_data_service.dart:165-226`

**Formula:** Line 199
```dart
final pendingCount = totalCustomers - collectedCount;
```

**Where:**
- `totalCustomers` = `getAssignedCustomers(staffProfileId).length` (line 197)
  - This requires active scheme (from `getAssignedCustomers`)
- `collectedCount` = unique `customer_id` in today's completed payments (line 192)
  - This requires `payment_date = today`

**Problem:** If customer list is empty (0) but payments exist (>0):
- `totalCustomers = 0`
- `collectedCount > 0`
- `pendingCount = 0 - collectedCount = negative`

---

## SOLUTION OPTIONS RESEARCH

### OPTION A: Assignment-Centric (RECOMMENDED)

**Canonical Source of Truth:** `staff_assignments`

**Customer List:**
- Start from `staff_assignments` WHERE `staff_id = X` AND `is_active = true`
- Get `customers` → `profiles`
- Get **LATEST** `user_schemes` (any status, order by `enrollment_date DESC`)
- If no scheme exists, still show customer (with "No active scheme" badge)
- Show scheme info if available, but **don't filter by it**

**Collections:**
- Keep today-only filter (business requirement)
- Show payments from assigned customers

**Pending:**
- `pendingCount = assignedCustomersWithActiveSchemes - customersPaidToday`
- Where:
  - `assignedCustomersWithActiveSchemes` = customers from `staff_assignments` who have at least one `user_schemes.status = 'active'`
  - `customersPaidToday` = unique `customer_id` from today's completed payments

**Pros:**
- `staff_assignments` is the business relationship
- Customer visibility doesn't depend on scheme lifecycle
- Matches business logic: "staff collects from assigned customers"
- Fixes empty customer list issue

**Cons:**
- May show customers without schemes (but can show badge/status)

---

### OPTION B: Payment-Centric

**Canonical Source of Truth:** `payments`

**Customer List:**
- Start from `payments` WHERE `staff_id = X` (all time or recent)
- Get unique `customer_id`
- Get `customers` → `profiles` → `user_schemes`

**Collections:**
- Today's payments only

**Pending:**
- Calculate based on payment history vs expected installments

**Pros:**
- Payments are the source of truth
- Always shows customers who have paid

**Cons:**
- Doesn't show customers who haven't paid yet
- Doesn't respect `staff_assignments` (business relationship)
- May show customers not assigned to staff

---

### OPTION C: Hybrid (Current Architecture, Fixed)

**Canonical Source of Truth:** `staff_assignments` + `user_schemes` (any status)

**Customer List:**
- Start from `staff_assignments` WHERE `staff_id = X` AND `is_active = true`
- Get `customers` → `profiles`
- Get **LATEST** `user_schemes` (any status, not just 'active')
- Show customer with scheme info (including status badge)

**Collections:**
- Today's payments only (keep as-is)

**Pending:**
- `pendingCount = assignedCustomersWithActiveSchemes - customersPaidToday`
- Same as Option A

**Pros:**
- Minimal changes to current code
- Still respects `staff_assignments`
- Shows customers even if scheme is completed/paused

**Cons:**
- Still requires scheme to exist (but any status is OK)

---

## ⚠️ CRITICAL INTEGRITY ANALYSIS

### Payment Flow Requirements (MANDATORY):

1. **Database Constraint:**
   - `payments.user_scheme_id` is **NOT NULL** (line 233 in `supabase_schema.sql`)
   - Payment **MUST** reference a valid `user_scheme_id`

2. **Payment Service Constraint:**
   - `PaymentService.getUserSchemeId()` requires `status = 'active'` (line 38 in `payment_service.dart`)
   - Payment screen **FAILS** if no active scheme found (line 132-134 in `collect_payment_screen.dart`)

3. **UI Data Requirements:**
   - Payment screen expects: `scheme`, `minAmount`, `maxAmount`, `frequency` (lines 84-85, 137, 206-207 in `collect_payment_screen.dart`)
   - Customer card expects: `scheme`, `frequency`, `dueAmount` (lines 389-391, 509 in `collect_tab_screen.dart`)

### Option A (Assignment-Centric) — ❌ BREAKS APP INTEGRITY

**Problems:**
1. **Payment Flow Breaks:**
   - Shows customers without schemes → User clicks customer → Payment screen → Error: "Active scheme not found"
   - `PaymentService.getUserSchemeId()` returns `null` → Payment insertion fails
   - **User experience: Dead end**

2. **UI Incomplete Data:**
   - Customer card shows "N/A" for scheme name
   - No `minAmount`/`maxAmount` for validation
   - No `frequency` for display
   - **UI looks broken**

3. **Database Constraint Violation Risk:**
   - If somehow payment is attempted without `user_scheme_id`, database will reject it
   - **Data integrity compromised**

**Verdict:** ❌ **NOT VIABLE** — Breaks payment flow and user experience

---

### Option C (Hybrid) — ✅ MAINTAINS INTEGRITY (WITH MODIFICATIONS)

**Advantages:**
1. **Payment Flow Works:**
   - Customer has scheme (any status) → Payment screen can get `user_scheme_id`
   - UI has complete data: `scheme`, `minAmount`, `maxAmount`, `frequency`
   - **Seamless user experience**

2. **Fixes Visibility Issue:**
   - Customers with paused/completed schemes appear in list
   - Fixes empty customer list symptom
   - **Maintains business relationship** (`staff_assignments`)

3. **Requires Payment Service Update:**
   - `PaymentService.getUserSchemeId()` should allow paused schemes (business decision)
   - OR: Get latest active, fallback to latest any-status

**Verdict:** ✅ **VIABLE** — Maintains integrity, fixes symptoms, requires small payment service change

---

## REVISED RECOMMENDED SOLUTION: OPTION C (Hybrid) + Payment Service Update

### Rationale:

1. **App Integrity:**
   - Payment flow requires `user_scheme_id` → Customer must have scheme
   - UI requires scheme data → Customer must have scheme
   - **Option C maintains these requirements**

2. **Business Logic:**
   - `staff_assignments` is the business relationship
   - Customer should appear if assigned AND has scheme (any status)
   - Scheme status is informational (can show badge: "Active", "Paused", "Completed")

3. **Fixes All Symptoms:**
   - **Empty customer list:** Fixed — customers with any scheme status appear
   - **Empty scheme breakdown:** Fixed — payments from assigned customers appear
   - **Negative pending:** Fixed — consistent source for calculation

4. **Seamless UI Flow:**
   - Customer list → Customer card → Payment screen → Payment success
   - No dead ends, no errors, complete data at each step
   - **Perfect user experience**

---

## PROPOSED CODE CHANGES (RESEARCH ONLY)

### Change 1: `getAssignedCustomers` — Get Latest Scheme (Any Status)

**File:** `lib/services/staff_data_service.dart:89-98`

**Current:**
```dart
final userSchemes = await _supabase
    .from('user_schemes')
    .select('id, scheme_id, status, payment_frequency, min_amount, max_amount, total_amount_paid, payments_made, payments_missed, accumulated_grams')
    .eq('customer_id', customerId)
    .eq('status', 'active')  // ← REMOVE THIS
    .limit(1)
    .maybeSingle();

if (userSchemes == null) continue;  // ← KEEP THIS (customer must have scheme)
```

**Proposed:**
```dart
// Get latest user scheme (any status) - customer must have scheme for payment flow
final userSchemes = await _supabase
    .from('user_schemes')
    .select('id, scheme_id, status, payment_frequency, min_amount, max_amount, total_amount_paid, payments_made, payments_missed, accumulated_grams')
    .eq('customer_id', customerId)
    .order('enrollment_date', ascending: false)  // Get latest scheme
    .limit(1)
    .maybeSingle();

// Still skip if no scheme exists (payment flow requires scheme)
if (userSchemes == null) continue;
```

**Result:** Customer appears if assigned AND has scheme (any status):
- ✅ Active scheme → Appears
- ✅ Paused scheme → Appears (with status badge)
- ✅ Completed scheme → Appears (with status badge)
- ❌ No scheme → Excluded (payment flow requires scheme)

---

### Change 2: Update Pending Calculation

**File:** `lib/services/staff_data_service.dart:195-199`

**Current:**
```dart
final assignedCustomers = await getAssignedCustomers(staffProfileId);
final totalCustomers = assignedCustomers.length;
final collectedCount = customersCollected.length;
final pendingCount = totalCustomers - collectedCount;
```

**Proposed:**
```dart
// Get assigned customers (from staff_assignments)
final assignments = await _supabase
    .from('staff_assignments')
    .select('customer_id')
    .eq('staff_id', staffProfileId)
    .eq('is_active', true);
    
final assignedCustomerIds = (assignments as List)
    .map((a) => a['customer_id'] as String)
    .toSet();

// Get customers with active schemes
final customersWithActiveSchemes = await _supabase
    .from('user_schemes')
    .select('customer_id')
    .eq('status', 'active')
    .in_('customer_id', assignedCustomerIds.toList());

final activeSchemeCustomerIds = (customersWithActiveSchemes as List)
    .map((c) => c['customer_id'] as String)
    .toSet();

// Pending = customers with active schemes - customers paid today
final pendingCount = activeSchemeCustomerIds.length - customersCollected.length;
```

**Result:** Pending count uses consistent source (assigned customers with active schemes).

---

### Change 3: Update Payment Service — Allow Paused Schemes

**File:** `lib/services/payment_service.dart:31-47`

**Current:**
```dart
static Future<String?> getUserSchemeId(String customerId) async {
  try {
    final response = await _supabase
        .from('user_schemes')
        .select('id')
        .eq('customer_id', customerId)
        .eq('status', 'active')  // ← ONLY active
        .order('enrollment_date', ascending: false)
        .limit(1)
        .maybeSingle();
    return response?['id'] as String?;
  } catch (e) {
    return null;
  }
}
```

**Proposed:**
```dart
static Future<String?> getUserSchemeId(String customerId) async {
  try {
    // First try active scheme
    var response = await _supabase
        .from('user_schemes')
        .select('id, status')
        .eq('customer_id', customerId)
        .eq('status', 'active')
        .order('enrollment_date', ascending: false)
        .limit(1)
        .maybeSingle();
    
    if (response != null) {
      return response['id'] as String?;
    }
    
    // Fallback: Get latest paused scheme (business allows payments to paused schemes)
    response = await _supabase
        .from('user_schemes')
        .select('id, status')
        .eq('customer_id', customerId)
        .eq('status', 'paused')  // Allow paused schemes
        .order('enrollment_date', ascending: false)
        .limit(1)
        .maybeSingle();
    
    return response?['id'] as String?;
  } catch (e) {
    return null;
  }
}
```

**Result:** Payment can be made to active OR paused schemes (business decision: can you pay to resume a paused scheme?).

**Alternative (Stricter):** Only allow active schemes, but get latest scheme (any status) for display purposes.

---

### Change 4: Update Scheme Breakdown — Get Latest Scheme (Any Status)

**File:** `lib/services/staff_data_service.dart:256-264`

**Current:**
```dart
final userScheme = await _supabase
    .from('user_schemes')
    .select('schemes!inner(name)')
    .eq('customer_id', payment['customer_id'] as String)
    .eq('status', 'active')  // ← This might fail if scheme is not active
    .limit(1)
    .maybeSingle();

final schemeName = userScheme?['schemes']?['name'] as String? ?? 'Unknown Scheme';
```

**Proposed:**
```dart
// Get latest scheme (any status) for this customer
// Payment already has user_scheme_id, so we can use it directly
final userScheme = await _supabase
    .from('user_schemes')
    .select('schemes!inner(name)')
    .eq('id', payment['user_scheme_id'] as String)  // Use payment's user_scheme_id directly
    .maybeSingle();

// OR if user_scheme_id not in payment response:
final userScheme = await _supabase
    .from('user_schemes')
    .select('schemes!inner(name)')
    .eq('customer_id', payment['customer_id'] as String)
    .order('enrollment_date', ascending: false)  // Get latest
    .limit(1)
    .maybeSingle();

final schemeName = userScheme?['schemes']?['name'] as String? ?? 'Unknown Scheme';
```

**Result:** Scheme breakdown shows payments even if scheme is not active (uses payment's `user_scheme_id` directly).

---

## ALTERNATIVE: OPTION C (Minimal Change)

If Option A is too aggressive, use **Option C**:

### Change: Remove Active Filter, Get Latest Scheme

**File:** `lib/services/staff_data_service.dart:89-98`

**Current:**
```dart
.eq('status', 'active')
.limit(1)
.maybeSingle();

if (userSchemes == null) continue;
```

**Proposed:**
```dart
.order('enrollment_date', ascending: false)  // Get latest
.limit(1)
.maybeSingle();

// Still skip if no scheme exists (but any status is OK)
if (userSchemes == null) continue;
```

**Result:** Customer appears if they have **any** scheme (active, paused, completed, etc.), but still excluded if no scheme exists.

---

## IMPACT ANALYSIS

### Option A (Assignment-Centric):
- **Customer List:** Shows all assigned customers (even without schemes)
- **Collections:** Unchanged (today's payments)
- **Pending:** Fixed (consistent source)
- **Code Changes:** Medium (remove filter, update pending calc)

### Option C (Hybrid):
- **Customer List:** Shows assigned customers with any scheme status
- **Collections:** Unchanged
- **Pending:** Fixed (consistent source)
- **Code Changes:** Small (remove active filter, get latest scheme)

---

## FINAL RECOMMENDATION: OPTION C (Hybrid) + Payment Service Update

### Why Option C is Best:

1. **✅ Maintains App Integrity:**
   - Payment flow requires `user_scheme_id` → Customer must have scheme
   - UI requires complete data → Customer must have scheme
   - Database constraints satisfied → No integrity violations

2. **✅ Seamless UI Flow:**
   - Customer list → Customer card (complete data) → Payment screen (works) → Payment success
   - No dead ends, no errors, no incomplete data
   - **Perfect user experience**

3. **✅ Fixes All Symptoms:**
   - Empty customer list → Fixed (customers with any scheme status appear)
   - Empty scheme breakdown → Fixed (payments appear with correct scheme)
   - Negative pending → Fixed (consistent source for calculation)

4. **✅ Business Logic Correct:**
   - `staff_assignments` is the business relationship (respected)
   - Customer appears if assigned AND has scheme (any status)
   - Scheme status is informational (can show badge)

5. **✅ Minimal Code Changes:**
   - Remove `.eq('status', 'active')` from `getAssignedCustomers`
   - Add `.order('enrollment_date', ascending: false)` to get latest scheme
   - Update `PaymentService.getUserSchemeId()` to allow paused schemes (optional)
   - Update pending calculation to use consistent source

### Why NOT Option A:

1. **❌ Breaks Payment Flow:**
   - Shows customers without schemes → Payment screen fails
   - User clicks customer → Error: "Active scheme not found"
   - **Dead end in user journey**

2. **❌ Incomplete UI Data:**
   - Customer card shows "N/A" for scheme
   - No `minAmount`/`maxAmount` for validation
   - **UI looks broken**

3. **❌ Database Constraint Risk:**
   - Payment requires `user_scheme_id` (NOT NULL)
   - If payment attempted without scheme, database rejects
   - **Data integrity compromised**

---

## IMPLEMENTATION PRIORITY

1. **CRITICAL:** Change 1 — Update `getAssignedCustomers` (removes active filter)
2. **CRITICAL:** Change 2 — Update pending calculation (consistent source)
3. **IMPORTANT:** Change 3 — Update `PaymentService.getUserSchemeId()` (allow paused schemes)
4. **NICE-TO-HAVE:** Change 4 — Update scheme breakdown (use payment's `user_scheme_id`)

---

## BUSINESS DECISION REQUIRED

**Question:** Can payments be made to paused schemes?

- **If YES:** Update `PaymentService.getUserSchemeId()` to allow paused schemes (Change 3)
- **If NO:** Keep active-only, but customer list will show paused schemes (for visibility only)

**Recommendation:** Allow paused schemes (business can resume paused schemes with payment).

---

## END OF RESEARCH

**Next Steps:**
1. Choose Option A or Option C
2. Implement code changes
3. Test with real data
4. Verify all three symptoms are fixed

