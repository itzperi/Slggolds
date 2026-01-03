# OPTION C (HYBRID) — IMPLEMENTATION STEPS

**Solution:** Get latest scheme (any status) instead of requiring active only  
**Goal:** Fix customer visibility while maintaining app integrity

---

## STEP 1: Update `getAssignedCustomers` — Remove Active Filter

**File:** `lib/services/staff_data_service.dart`  
**Lines:** 89-98

### Current Code:
```dart
// Get active user schemes
final userSchemes = await _supabase
    .from('user_schemes')
    .select('id, scheme_id, status, payment_frequency, min_amount, max_amount, total_amount_paid, payments_made, payments_missed, accumulated_grams')
    .eq('customer_id', customerId)
    .eq('status', 'active')  // ← REMOVE THIS LINE
    .limit(1)
    .maybeSingle();

if (userSchemes == null) continue;
```

### Change To:
```dart
// Get latest user scheme (any status) - customer must have scheme for payment flow
final userSchemes = await _supabase
    .from('user_schemes')
    .select('id, scheme_id, status, payment_frequency, min_amount, max_amount, total_amount_paid, payments_made, payments_missed, accumulated_grams')
    .eq('customer_id', customerId)
    .order('enrollment_date', ascending: false)  // ← ADD THIS: Get latest scheme
    .limit(1)
    .maybeSingle();

// Still skip if no scheme exists (payment flow requires scheme)
if (userSchemes == null) continue;
```

**What This Does:**
- Removes requirement for `status = 'active'`
- Gets latest scheme (any status: active, paused, completed, etc.)
- Still requires scheme to exist (maintains payment flow integrity)

---

## STEP 2: Update Pending Calculation — Use Consistent Source

**File:** `lib/services/staff_data_service.dart`  
**Lines:** 195-199

### Current Code:
```dart
// Get total assigned customers
final assignedCustomers = await getAssignedCustomers(staffProfileId);
final totalCustomers = assignedCustomers.length;
final collectedCount = customersCollected.length;
final pendingCount = totalCustomers - collectedCount;
```

### Change To:
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

// Get customers with active schemes (for pending calculation)
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

**What This Does:**
- Uses `staff_assignments` as source of truth
- Counts only customers with active schemes for pending
- Prevents negative pending count

**Note:** If `.in_()` method doesn't work, use this alternative:
```dart
// Alternative if .in_() doesn't work
final customersWithActiveSchemes = await _supabase
    .from('user_schemes')
    .select('customer_id')
    .eq('status', 'active');

final activeSchemeCustomerIds = (customersWithActiveSchemes as List)
    .where((c) => assignedCustomerIds.contains(c['customer_id'] as String))
    .map((c) => c['customer_id'] as String)
    .toSet();
```

---

## STEP 3: Update `getTodayCollections` — Get Latest Scheme (Any Status)

**File:** `lib/services/staff_data_service.dart`  
**Lines:** 256-264

### Current Code:
```dart
// Get scheme name from user_schemes
final userScheme = await _supabase
    .from('user_schemes')
    .select('schemes!inner(name)')
    .eq('customer_id', payment['customer_id'] as String)
    .eq('status', 'active')  // ← REMOVE THIS
    .limit(1)
    .maybeSingle();
```

### Change To:
```dart
// Get latest scheme (any status) for this customer
// Note: Payment already has user_scheme_id, but we query by customer_id for consistency
final userScheme = await _supabase
    .from('user_schemes')
    .select('schemes!inner(name)')
    .eq('customer_id', payment['customer_id'] as String)
    .order('enrollment_date', ascending: false)  // ← ADD THIS: Get latest
    .limit(1)
    .maybeSingle();
```

**What This Does:**
- Removes active-only filter
- Gets latest scheme (any status) for display
- Ensures scheme breakdown shows correctly

---

## STEP 4: Update `getSchemeBreakdown` — Get Latest Scheme (Any Status)

**File:** `lib/services/staff_data_service.dart`  
**Lines:** 335-373 (find the query that filters by status)

### Find This Code:
```dart
.eq('status', 'active')  // Look for this in getSchemeBreakdown
```

### Change To:
```dart
// Remove .eq('status', 'active') if present
// The query already uses user_schemes!inner which ensures valid scheme exists
```

**What This Does:**
- Scheme breakdown shows payments even if scheme is not active
- Uses payment's `user_scheme_id` directly (already in query)

---

## STEP 5: (OPTIONAL) Update `PaymentService.getUserSchemeId` — Allow Paused Schemes

**File:** `lib/services/payment_service.dart`  
**Lines:** 31-47

### Current Code:
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

### Change To (If Business Allows Payments to Paused Schemes):
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
    
    // Fallback: Get latest paused scheme (if business allows payments to resume paused schemes)
    response = await _supabase
        .from('user_schemes')
        .select('id, status')
        .eq('customer_id', customerId)
        .eq('status', 'paused')
        .order('enrollment_date', ascending: false)
        .limit(1)
        .maybeSingle();
    
    return response?['id'] as String?;
  } catch (e) {
    return null;
  }
}
```

**What This Does:**
- Allows payments to active OR paused schemes
- Business decision: Can you pay to resume a paused scheme?

**Alternative (Keep Active Only):**
- Skip this step if business only allows payments to active schemes
- Customer list will show paused/completed schemes (for visibility)
- Payment will only work for active schemes

---

## STEP 6: Test the Changes

### Test Cases:

1. **Customer with Active Scheme:**
   - Should appear in customer list
   - Payment screen should work
   - Should show in scheme breakdown

2. **Customer with Paused Scheme:**
   - Should appear in customer list
   - Payment screen should work (if Step 5 implemented)
   - Should show in scheme breakdown

3. **Customer with Completed Scheme:**
   - Should appear in customer list
   - Payment screen may not work (depends on Step 5)
   - Should show in scheme breakdown

4. **Pending Count:**
   - Should not go negative
   - Should match: (customers with active schemes) - (customers paid today)

5. **Scheme Breakdown:**
   - Should show payments even if scheme is not active
   - Should group by asset type correctly

---

## SUMMARY OF CHANGES

| Step | File | Change | Required? |
|------|------|--------|-----------|
| 1 | `staff_data_service.dart` | Remove `.eq('status', 'active')`, add `.order('enrollment_date')` | ✅ YES |
| 2 | `staff_data_service.dart` | Fix pending calculation to use consistent source | ✅ YES |
| 3 | `staff_data_service.dart` | Update `getTodayCollections` to get latest scheme | ✅ YES |
| 4 | `staff_data_service.dart` | Update `getSchemeBreakdown` (if needed) | ✅ YES |
| 5 | `payment_service.dart` | Allow paused schemes (optional) | ⚠️ OPTIONAL |

---

## EXPECTED RESULTS

After implementation:
- ✅ Customer list shows customers with any scheme status (active, paused, completed)
- ✅ Scheme breakdown shows payments correctly
- ✅ Pending count is accurate (no negative values)
- ✅ Payment flow works (if Step 5 implemented)
- ✅ UI has complete data (scheme, minAmount, maxAmount, frequency)

---

## ROLLBACK PLAN

If issues occur:
1. Revert Step 1: Add back `.eq('status', 'active')` and remove `.order('enrollment_date')`
2. Revert Step 2: Restore original pending calculation
3. Revert Steps 3-4: Restore original queries
4. Revert Step 5: Restore active-only in `PaymentService`

---

**Ready to implement?** Execute steps 1-4 first, then test. Add Step 5 only if business allows payments to paused schemes.



