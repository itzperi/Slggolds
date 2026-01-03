# SLG Thangangal - Required Smoke Tests

**Purpose:** Validate critical user flows and ensure production readiness  
**Scope:** Authentication, Role-Based Access, Payment Collection, Data Persistence, Error Handling

---

## 🔴 CRITICAL PATH TESTS (Must Pass Before Launch)

### 1. AUTHENTICATION & ROLE-BASED ACCESS

#### Test 1.1: Customer Login Flow
**Priority:** 🔴 CRITICAL  
**Steps:**
1. Launch app → Should show LoginScreen
2. Enter valid customer phone number
3. Receive OTP (or use demo bypass if enabled)
4. Enter OTP → Should verify successfully
5. If first-time user → Should show PIN setup screen
6. Set 6-digit PIN → Should save securely
7. After PIN setup → Should navigate to Customer Dashboard
8. Verify: Dashboard shows customer data (schemes, investments, etc.)

**Expected Results:**
- ✅ OTP verification succeeds
- ✅ PIN is stored securely (not in plain text)
- ✅ Navigation to Customer Dashboard
- ✅ Dashboard loads customer data from Supabase
- ✅ No mock data displayed

**Failure Scenarios to Test:**
- Invalid OTP → Should show error, allow retry
- Network failure during OTP → Should show error message
- Missing profile in database → Should logout and show error

---

#### Test 1.2: Staff (Collection) Login Flow
**Priority:** 🔴 CRITICAL  
**Steps:**
1. Launch app → Should show LoginScreen
2. Enter valid staff phone number (with `staff_type='collection'`)
3. Receive OTP and verify
4. Set/enter PIN
5. After authentication → Should navigate to Staff Dashboard
6. Verify: Dashboard shows assigned customers

**Expected Results:**
- ✅ OTP verification succeeds
- ✅ Role check passes (staff with `staff_type='collection'`)
- ✅ Navigation to Staff Dashboard
- ✅ Dashboard shows only assigned customers
- ✅ Can access payment collection screen

**Failure Scenarios to Test:**
- Staff with `staff_type='office'` → Should logout immediately with error message
- Staff without `staff_metadata` record → Should logout with error
- Inactive staff profile → Should logout with error

---

#### Test 1.3: Admin/Office Staff Access Block
**Priority:** 🔴 CRITICAL  
**Steps:**
1. Attempt login with admin phone number
2. Complete OTP verification
3. Set/enter PIN
4. After authentication → Should check role

**Expected Results:**
- ✅ Admin role detected
- ✅ Immediate logout triggered
- ✅ Error message shown: "This account does not have mobile app access."
- ✅ Navigation to LoginScreen
- ✅ No dashboard access

**Test Cases:**
- Admin user → Should be blocked
- Staff with `staff_type='office'` → Should be blocked
- Staff with missing `staff_type` → Should be blocked (defaults to 'collection' but should validate)

---

#### Test 1.4: PIN Login (Returning User)
**Priority:** 🔴 CRITICAL  
**Steps:**
1. User with existing PIN logs in
2. Enter phone number
3. Verify OTP
4. Should show PIN login screen (not setup)
5. Enter correct PIN → Should authenticate
6. Should navigate to appropriate dashboard (customer/staff)

**Expected Results:**
- ✅ PIN login screen appears for existing users
- ✅ Correct PIN → Authentication succeeds
- ✅ Wrong PIN → Error message, allow retry
- ✅ Role-based routing works after PIN login

**Failure Scenarios:**
- Wrong PIN 3+ times → Should lock account or show warning
- PIN not set but user exists → Should show PIN setup screen

---

#### Test 1.5: Biometric Authentication
**Priority:** 🟠 HIGH  
**Steps:**
1. After PIN setup, enable biometric (if device supports)
2. Logout
3. Login again → Should offer biometric option
4. Use biometric → Should authenticate
5. Should navigate to appropriate dashboard

**Expected Results:**
- ✅ Biometric option appears if device supports it
- ✅ Biometric authentication succeeds
- ✅ Falls back to PIN if biometric fails
- ✅ Role-based routing works

---

#### Test 1.6: Session Persistence (Cold Start)
**Priority:** 🔴 CRITICAL  
**Steps:**
1. Login as customer or staff
2. Close app completely
3. Reopen app
4. Should check Supabase session

**Expected Results:**
- ✅ If valid session exists → Should auto-authenticate
- ✅ Should check role and route appropriately
- ✅ If session expired → Should show LoginScreen
- ✅ No infinite loading states

---

### 2. ROLE-BASED ROUTING

#### Test 2.1: Customer Routing
**Priority:** 🔴 CRITICAL  
**Steps:**
1. Authenticate as customer
2. Verify navigation

**Expected Results:**
- ✅ Routes to `DashboardScreen` (customer)
- ✅ No access to staff screens
- ✅ Back button disabled (can't go back to login)

---

#### Test 2.2: Staff Routing
**Priority:** 🔴 CRITICAL  
**Steps:**
1. Authenticate as staff (collection type)
2. Verify navigation

**Expected Results:**
- ✅ Routes to `StaffDashboard`
- ✅ No access to customer screens
- ✅ Back button disabled

---

#### Test 2.3: Invalid Role Handling
**Priority:** 🔴 CRITICAL  
**Steps:**
1. User with missing profile → Should logout
2. User with inactive profile → Should logout
3. User with invalid role → Should logout

**Expected Results:**
- ✅ All invalid cases trigger logout
- ✅ Error message displayed
- ✅ Navigation to LoginScreen

---

### 3. PAYMENT COLLECTION (STAFF)

#### Test 3.1: Payment Insert - Happy Path
**Priority:** 🔴 CRITICAL  
**Steps:**
1. Staff logs in
2. Navigate to Collect Payment screen
3. Select assigned customer
4. Enter payment amount (e.g., ₹1000)
5. Select payment method (cash/UPI)
6. Submit payment

**Expected Results:**
- ✅ Payment inserted into `payments` table
- ✅ All required fields populated:
  - `user_scheme_id` (UUID)
  - `customer_id` (UUID)
  - `staff_id` (current staff profile UUID)
  - `amount` (₹1000)
  - `gst_amount` (₹30, 3% of amount)
  - `net_amount` (₹970, 97% of amount)
  - `payment_method` ('cash' or 'upi')
  - `metal_rate_per_gram` (from `market_rates` table)
  - `metal_grams_added` (calculated: net_amount / rate)
  - `device_id` (generated)
  - `client_timestamp` (current timestamp)
  - `status` ('completed')
- ✅ Database trigger updates `user_schemes` totals:
  - `total_amount_paid` increased
  - `payments_made` incremented
  - `accumulated_grams` increased
- ✅ Success message shown to staff
- ✅ Payment appears in customer's transaction history

**Database Verification:**
```sql
-- Check payment was inserted
SELECT * FROM payments WHERE customer_id = '<customer_uuid>' ORDER BY created_at DESC LIMIT 1;

-- Check user_scheme totals updated
SELECT total_amount_paid, payments_made, accumulated_grams 
FROM user_schemes WHERE id = '<user_scheme_id>';
```

---

#### Test 3.2: Payment - Market Rate Fetching
**Priority:** 🔴 CRITICAL  
**Steps:**
1. Staff collects payment
2. Verify market rate is fetched from database

**Expected Results:**
- ✅ Market rate fetched from `market_rates` table
- ✅ Rate matches asset type (gold/silver) of customer's scheme
- ✅ Rate is latest available (ORDER BY rate_date DESC)
- ✅ Rate is written to `payments.metal_rate_per_gram` (never recalculated)
- ✅ If rate missing → Should show error, prevent payment

**Database Verification:**
```sql
-- Check market rate exists
SELECT * FROM market_rates 
WHERE asset_type = 'gold' 
ORDER BY rate_date DESC LIMIT 1;
```

---

#### Test 3.3: Payment - GST Calculation
**Priority:** 🔴 CRITICAL  
**Steps:**
1. Staff collects payment of ₹1000
2. Verify GST calculation

**Expected Results:**
- ✅ `gst_amount` = ₹30 (3% of ₹1000)
- ✅ `net_amount` = ₹970 (97% of ₹1000)
- ✅ `metal_grams_added` = net_amount / metal_rate_per_gram
- ✅ Calculations match exactly (no rounding errors)

---

#### Test 3.4: Payment - Staff Assignment Validation
**Priority:** 🔴 CRITICAL  
**Steps:**
1. Staff tries to collect payment for unassigned customer
2. Verify RLS enforcement

**Expected Results:**
- ✅ RLS policy blocks insert
- ✅ Error message shown to staff
- ✅ Payment not inserted
- ✅ Only assigned customers appear in customer list

**Database Verification:**
```sql
-- Check staff assignment
SELECT * FROM staff_assignments 
WHERE staff_id = '<staff_profile_id>' 
AND customer_id = '<customer_id>' 
AND is_active = true;
```

---

#### Test 3.5: Payment - Error Handling
**Priority:** 🔴 CRITICAL  
**Steps:**
1. Network failure during payment submission
2. Invalid customer data
3. Missing user_scheme_id
4. Database constraint violation

**Expected Results:**
- ✅ Network error → Shows error message, allows retry
- ✅ Invalid data → Shows validation error
- ✅ Missing scheme → Shows error, prevents submission
- ✅ Constraint violation → Shows error, payment not inserted

---

#### Test 3.6: Payment - Offline Support Fields
**Priority:** 🟠 HIGH  
**Steps:**
1. Staff collects payment
2. Verify offline sync fields

**Expected Results:**
- ✅ `device_id` is generated and stored
- ✅ `client_timestamp` is set (ISO 8601 format)
- ✅ Fields populated even if online

---

### 4. CUSTOMER FEATURES

#### Test 4.1: Customer Dashboard Data Loading
**Priority:** 🔴 CRITICAL  
**Steps:**
1. Customer logs in
2. Navigate to dashboard
3. Verify data displayed

**Expected Results:**
- ✅ Dashboard loads from Supabase (not mock data)
- ✅ Shows active schemes
- ✅ Shows total investment
- ✅ Shows accumulated metal (gold/silver grams)
- ✅ Shows recent transactions
- ✅ Shows payment schedule
- ✅ All data matches database

**Database Verification:**
```sql
-- Check customer schemes
SELECT * FROM user_schemes 
WHERE customer_id IN (
  SELECT id FROM customers WHERE profile_id = '<profile_id>'
);

-- Check payments
SELECT * FROM payments 
WHERE customer_id IN (
  SELECT id FROM customers WHERE profile_id = '<profile_id>'
) ORDER BY created_at DESC;
```

---

#### Test 4.2: Scheme Enrollment (If Implemented)
**Priority:** 🟡 MEDIUM  
**Steps:**
1. Customer browses schemes
2. Selects a scheme
3. Enrolls in scheme

**Expected Results:**
- ✅ Enrollment creates `user_schemes` record
- ✅ Customer can only enroll for themselves
- ✅ RLS policy allows customer INSERT
- ✅ Enrollment appears in dashboard

**Note:** Check if enrollment is implemented or still using mock data.

---

#### Test 4.3: Transaction History
**Priority:** 🔴 CRITICAL  
**Steps:**
1. Customer views transaction history
2. Verify transactions displayed

**Expected Results:**
- ✅ Shows all payments from `payments` table
- ✅ Sorted by date (newest first)
- ✅ Shows amount, date, payment method
- ✅ Shows GST breakdown
- ✅ Shows metal grams added
- ✅ No mock data

---

#### Test 4.4: Withdrawal Request (If Implemented)
**Priority:** 🟡 MEDIUM  
**Steps:**
1. Customer requests withdrawal
2. Submit withdrawal request

**Expected Results:**
- ✅ Creates `withdrawals` record
- ✅ Status = 'pending'
- ✅ Customer can only request for their own schemes
- ✅ RLS policy allows customer INSERT
- ✅ Request appears in withdrawal list

**Note:** Check if withdrawal submission is implemented (currently shows TODO).

---

#### Test 4.5: Market Rates Display
**Priority:** 🟠 HIGH  
**Steps:**
1. Customer views market rates screen
2. Verify rates displayed

**Expected Results:**
- ✅ Rates fetched from `market_rates` table
- ✅ Shows latest rates for gold and silver
- ✅ Updates when admin updates rates
- ✅ No hardcoded rates

---

### 5. DATA PERSISTENCE & INTEGRITY

#### Test 5.1: Payment Immutability
**Priority:** 🔴 CRITICAL  
**Steps:**
1. Staff collects payment
2. Attempt to update payment (should fail)
3. Attempt to delete payment (should fail)

**Expected Results:**
- ✅ Payment cannot be updated (append-only)
- ✅ Payment cannot be deleted
- ✅ RLS policies prevent UPDATE/DELETE
- ✅ Database triggers enforce immutability

**Database Verification:**
```sql
-- Attempt update (should fail)
UPDATE payments SET amount = 2000 WHERE id = '<payment_id>';
-- Should return permission denied or constraint violation

-- Attempt delete (should fail)
DELETE FROM payments WHERE id = '<payment_id>';
-- Should return permission denied
```

---

#### Test 5.2: User Scheme Totals Update
**Priority:** 🔴 CRITICAL  
**Steps:**
1. Staff collects payment
2. Verify `user_schemes` totals updated

**Expected Results:**
- ✅ Database trigger fires on payment insert
- ✅ `total_amount_paid` increases by payment amount
- ✅ `payments_made` increments by 1
- ✅ `accumulated_grams` increases by calculated grams
- ✅ Totals match sum of all payments

**Database Verification:**
```sql
-- Check trigger updated totals
SELECT 
  total_amount_paid,
  payments_made,
  accumulated_grams,
  (SELECT SUM(amount) FROM payments WHERE user_scheme_id = us.id) as sum_payments,
  (SELECT COUNT(*) FROM payments WHERE user_scheme_id = us.id) as count_payments
FROM user_schemes us
WHERE id = '<user_scheme_id>';
```

---

#### Test 5.3: Phone Number Uniqueness
**Priority:** 🔴 CRITICAL  
**Steps:**
1. Attempt to create profile with duplicate phone
2. Verify constraint enforcement

**Expected Results:**
- ✅ Database constraint prevents duplicate phone
- ✅ Error shown if duplicate phone attempted
- ✅ One phone → One user mapping enforced

**Database Verification:**
```sql
-- Check constraint exists
SELECT constraint_name 
FROM information_schema.table_constraints 
WHERE table_name = 'profiles' 
AND constraint_name = 'profiles_phone_unique';
```

---

#### Test 5.4: Staff Type Constraint
**Priority:** 🔴 CRITICAL  
**Steps:**
1. Verify `staff_type` constraint
2. Attempt invalid staff_type value

**Expected Results:**
- ✅ Only 'collection' or 'office' allowed
- ✅ Default is 'collection'
- ✅ Invalid value rejected

**Database Verification:**
```sql
-- Check constraint
SELECT constraint_name 
FROM information_schema.table_constraints 
WHERE table_name = 'staff_metadata' 
AND constraint_name LIKE '%staff_type%';
```

---

### 6. SECURITY & ACCESS CONTROL

#### Test 6.1: RLS - Customer Data Isolation
**Priority:** 🔴 CRITICAL  
**Steps:**
1. Customer A logs in
2. Attempt to access Customer B's data
3. Verify RLS blocks access

**Expected Results:**
- ✅ Customer can only read own data
- ✅ Cannot see other customers' schemes
- ✅ Cannot see other customers' payments
- ✅ Cannot see other customers' withdrawals

**Database Verification:**
```sql
-- As Customer A, try to read Customer B's data
-- Should return empty result set
SELECT * FROM user_schemes 
WHERE customer_id = '<customer_b_id>';
```

---

#### Test 6.2: RLS - Staff Assignment Enforcement
**Priority:** 🔴 CRITICAL  
**Steps:**
1. Staff logs in
2. Attempt to collect payment for unassigned customer
3. Verify RLS blocks

**Expected Results:**
- ✅ Staff can only see assigned customers
- ✅ Cannot insert payment for unassigned customer
- ✅ RLS policy enforces `staff_assignments` check

---

#### Test 6.3: RLS - Payment Insert Authorization
**Priority:** 🔴 CRITICAL  
**Steps:**
1. Staff collects payment
2. Verify `staff_id` matches current user's profile
3. Verify customer is assigned to staff

**Expected Results:**
- ✅ RLS policy checks `staff_id = get_user_profile()`
- ✅ RLS policy checks `is_staff_assigned_to_customer(customer_id)`
- ✅ Payment insert succeeds only if both conditions true

---

### 7. ERROR HANDLING & EDGE CASES

#### Test 7.1: Network Failure Scenarios
**Priority:** 🔴 CRITICAL  
**Steps:**
1. Disable network
2. Attempt login
3. Attempt payment collection
4. Attempt data fetch

**Expected Results:**
- ✅ Network errors caught and displayed
- ✅ User-friendly error messages
- ✅ No app crashes
- ✅ Retry options available

---

#### Test 7.2: Invalid Data Scenarios
**Priority:** 🔴 CRITICAL  
**Steps:**
1. Missing profile data
2. Missing customer record
3. Missing user_scheme
4. Missing market rates

**Expected Results:**
- ✅ Graceful error handling
- ✅ Error messages shown
- ✅ App doesn't crash
- ✅ Fallback behavior (if applicable)

---

#### Test 7.3: Session Expiry
**Priority:** 🔴 CRITICAL  
**Steps:**
1. Login successfully
2. Wait for session to expire (or manually expire)
3. Attempt to perform action

**Expected Results:**
- ✅ Session expiry detected
- ✅ User logged out automatically
- ✅ Navigation to LoginScreen
- ✅ Error message shown

---

#### Test 7.4: Concurrent Payment Collection
**Priority:** 🟠 HIGH  
**Steps:**
1. Two staff members collect payment for same customer simultaneously
2. Verify data integrity

**Expected Results:**
- ✅ Both payments inserted successfully
- ✅ `user_schemes` totals updated correctly
- ✅ No data corruption
- ✅ No race conditions

---

### 8. UI/UX VALIDATION

#### Test 8.1: Loading States
**Priority:** 🟠 HIGH  
**Steps:**
1. Navigate through app
2. Verify loading indicators

**Expected Results:**
- ✅ Loading indicators shown during data fetch
- ✅ No blank screens
- ✅ Smooth transitions

---

#### Test 8.2: Error Messages
**Priority:** 🟠 HIGH  
**Steps:**
1. Trigger various errors
2. Verify error messages

**Expected Results:**
- ✅ Error messages are user-friendly
- ✅ Messages displayed via SnackBar or dialog
- ✅ Messages are actionable (retry, contact support, etc.)

---

#### Test 8.3: Navigation Flow
**Priority:** 🟠 HIGH  
**Steps:**
1. Navigate through all screens
2. Test back button behavior

**Expected Results:**
- ✅ Back button works correctly
- ✅ No navigation stack issues
- ✅ Can't navigate back to login after authentication
- ✅ Deep linking works (if implemented)

---

## 🟠 HIGH PRIORITY TESTS (Should Pass Before Launch)

### 9. DATA VALIDATION

#### Test 9.1: Payment Amount Validation
**Priority:** 🟠 HIGH  
**Steps:**
1. Staff enters invalid payment amount
2. Verify validation

**Expected Results:**
- ✅ Negative amounts rejected
- ✅ Zero amount rejected
- ✅ Amount within scheme min/max range
- ✅ Decimal precision handled correctly

---

#### Test 9.2: Phone Number Format
**Priority:** 🟠 HIGH  
**Steps:**
1. Enter phone in various formats
2. Verify formatting

**Expected Results:**
- ✅ Phone numbers normalized to +91 format
- ✅ Invalid formats rejected
- ✅ OTP sent to correct number

---

### 10. PERFORMANCE

#### Test 10.1: Dashboard Load Time
**Priority:** 🟠 HIGH  
**Steps:**
1. Measure dashboard load time
2. Verify acceptable performance

**Expected Results:**
- ✅ Dashboard loads in < 2 seconds
- ✅ No blocking UI
- ✅ Data pagination (if large datasets)

---

#### Test 10.2: Payment Submission Time
**Priority:** 🟠 HIGH  
**Steps:**
1. Measure payment submission time
2. Verify acceptable performance

**Expected Results:**
- ✅ Payment submitted in < 3 seconds
- ✅ Loading indicator shown
- ✅ Success feedback immediate

---

## 🟡 MEDIUM PRIORITY TESTS (Nice to Have)

### 11. BIOMETRIC AUTHENTICATION

#### Test 11.1: Biometric Setup
**Priority:** 🟡 MEDIUM  
**Steps:**
1. Setup biometric after PIN
2. Verify storage

**Expected Results:**
- ✅ Biometric preference saved
- ✅ Can enable/disable biometric
- ✅ Falls back to PIN if biometric unavailable

---

### 12. OFFLINE FUNCTIONALITY

#### Test 12.1: Offline Payment Queue
**Priority:** 🟡 MEDIUM  
**Steps:**
1. Collect payment while offline
2. Verify queueing
3. Sync when online

**Expected Results:**
- ✅ Payments queued locally
- ✅ Synced when network available
- ✅ Conflict resolution (if applicable)

**Note:** Check if offline sync is fully implemented.

---

## 📋 TEST EXECUTION CHECKLIST

### Pre-Test Setup
- [ ] Supabase database schema deployed
- [ ] Test data seeded:
  - [ ] Customer profiles (active)
  - [ ] Staff profiles (collection type)
  - [ ] Staff profiles (office type) - for negative testing
  - [ ] Admin profiles - for negative testing
  - [ ] Customer records
  - [ ] Staff metadata records
  - [ ] Staff assignments
  - [ ] Active schemes
  - [ ] User schemes (enrollments)
  - [ ] Market rates (gold and silver)
- [ ] Test devices prepared (Android/iOS)
- [ ] Network conditions tested (online/offline)

### Test Execution Order
1. **Authentication Tests** (1.1 - 1.6)
2. **Role-Based Routing Tests** (2.1 - 2.3)
3. **Payment Collection Tests** (3.1 - 3.6)
4. **Customer Feature Tests** (4.1 - 4.5)
5. **Data Persistence Tests** (5.1 - 5.4)
6. **Security Tests** (6.1 - 6.3)
7. **Error Handling Tests** (7.1 - 7.4)
8. **UI/UX Tests** (8.1 - 8.3)
9. **Data Validation Tests** (9.1 - 9.2)
10. **Performance Tests** (10.1 - 10.2)

### Success Criteria
- ✅ All 🔴 CRITICAL tests pass
- ✅ 90%+ of 🟠 HIGH priority tests pass
- ✅ No data corruption or security breaches
- ✅ All payments persist correctly
- ✅ All role-based access rules enforced
- ✅ Error handling works for all failure scenarios

---

## 🚨 KNOWN GAPS TO ADDRESS

Based on codebase analysis:

1. **Withdrawal Submission** - Currently shows TODO, needs implementation
2. **Scheme Enrollment** - Verify if implemented or still using mock data
3. **Offline Sync** - Check if fully implemented or partial
4. **Biometric Fallback** - Verify error handling
5. **Session Refresh** - Verify automatic token refresh
6. **Payment Reversals** - Check if implemented (for corrections)

---

## 📝 TEST REPORTING TEMPLATE

For each test:
- **Test ID:** (e.g., 1.1)
- **Test Name:** (e.g., Customer Login Flow)
- **Status:** ✅ PASS / ❌ FAIL / ⚠️ PARTIAL
- **Execution Time:** (e.g., 2m 30s)
- **Issues Found:** (list any bugs or issues)
- **Screenshots:** (attach if failure)
- **Database Verification:** (SQL queries and results)
- **Notes:** (any observations)

---

**Last Updated:** Based on current codebase analysis  
**Next Review:** After implementing missing features (withdrawals, enrollment, etc.)

