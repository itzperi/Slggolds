# RLS AUTOPSY REPORT

## Instructions

1. Run `RLS_AUTOPSY.sql` in Supabase SQL Editor
2. Copy the results from each step
3. Fill in this report with findings
4. DO NOT make code changes yet

---

## STEP 1: INVENTORY RESULTS

### Total Policies Found:
- Payments: ___ policies
- Customers: ___ policies  
- Profiles: ___ policies
- Staff_assignments: ___ policies
- User_schemes: ___ policies
- Market_rates: ___ policies
- Schemes: ___ policies
- Staff_metadata: ___ policies
- Withdrawals: ___ policies

### Policy List:
```
[Paste results from Step 1 query here]
```

---

## STEP 2: FOCUS TABLES ANALYSIS

### Payments Table Policies:
```
[Paste results from Step 2a here]
```

### Customers Table Policies:
```
[Paste results from Step 2b here]
```

### Profiles Table Policies:
```
[Paste results from Step 2c here]
```

### Staff_assignments Table Policies:
```
[Paste results from Step 2d here]
```

### User_schemes Table Policies:
```
[Paste results from Step 2e here]
```

### Market_rates Table Policies:
```
[Paste results from Step 2f here]
```

### Schemes Table Policies:
```
[Paste results from Step 2g here]
```

### Staff_metadata Table Policies:
```
[Paste results from Step 2h here]
```

### Withdrawals Table Policies:
```
[Paste results from Step 2i here]
```

---

## STEP 3: INSERT PATH TRACE

### 3a: INSERT Policy Count
- Total INSERT policies on payments: ___
- PERMISSIVE: ___
- RESTRICTIVE: ___

### 3b: INSERT Policy Details
```
[Paste results from Step 3b here]
```

**Analysis:**
- Which policy is most likely failing: ________________
- Why: ________________

### 3c: Auth Resolution Method
```
[Paste results from Step 3c here]
```

**Issues Found:**
- [ ] auth.uid() vs profile.id mismatch
- [ ] Inconsistent auth resolution

### 3d: RLS Dependencies
```
[Paste results from Step 3d here]
```

**Issues Found:**
- [ ] Policy depends on staff_assignments (has RLS)
- [ ] Policy depends on profiles (has RLS)
- [ ] Policy depends on customers (has RLS)

---

## STEP 4: FUNCTION ANALYSIS

### 4a: Helper Functions
```
[Paste results from Step 4a here]
```

**Critical Findings:**
- `is_current_staff_assigned_to_customer()` exists: YES / NO
- Is SECURITY DEFINER: YES / NO
- `get_user_profile()` exists: YES / NO
- Is SECURITY DEFINER: YES / NO

### 4b: Function RLS Table Usage
```
[Paste results from Step 4b here]
```

**Issues:**
- [ ] Function queries staff_assignments without SECURITY DEFINER
- [ ] Function queries profiles without SECURITY DEFINER

---

## STEP 5: MINIMAL REPRODUCTION

### 5a: Current User Context
```
[Paste results from Step 5a here]
```

**Findings:**
- auth.uid(): ________________
- profile.id: ________________
- role: ________________
- is_staff(): TRUE / FALSE
- is_admin(): TRUE / FALSE

### 5b: Test Customer Check
```
[Paste results from Step 5b here]
```

**Findings:**
- is_assigned: TRUE / FALSE

### 5c: Direct Assignment Check
```
[Paste results from Step 5c here]
```

**Findings:**
- direct_assignment_check: TRUE / FALSE
- If FALSE, staff_assignments RLS is blocking

### 5d: Full Policy Simulation
```
[Paste results from Step 5d here]
```

**Findings:**
- condition1_is_staff: TRUE / FALSE
- condition2_is_admin: TRUE / FALSE
- condition3_staff_id_match: TRUE / FALSE
- condition4_assigned: TRUE / FALSE
- **final_policy_result: TRUE / FALSE**

**Which condition failed:** ________________

### 5e: Minimal INSERT Test
```
[Paste error message here if INSERT failed]
```

**Error Analysis:**
- Error code: ________________
- Error message: ________________
- Policy blocking: ________________

---

## STEP 6: POLICY CONFLICT DETECTION

### 6a: Overlapping Policies
```
[Paste results from Step 6a here]
```

**Findings:**
- Multiple INSERT policies: YES / NO
- If YES, list: ________________

### 6b: RESTRICTIVE Policies
```
[Paste results from Step 6b here]
```

**Findings:**
- RESTRICTIVE policies exist: YES / NO
- If YES, these will block even if PERMISSIVE allows

---

## STEP 7: RLS ENABLEMENT

```
[Paste results from Step 7 here]
```

**Findings:**
- payments RLS enabled: YES / NO
- customers RLS enabled: YES / NO
- profiles RLS enabled: YES / NO
- staff_assignments RLS enabled: YES / NO
- user_schemes RLS enabled: YES / NO
- market_rates RLS enabled: YES / NO
- schemes RLS enabled: YES / NO
- staff_metadata RLS enabled: YES / NO
- withdrawals RLS enabled: YES / NO

---

## STEP 8: SELECT PATH TRACE

### 8a: SELECT Policy Count by Table
```
[Paste results from Step 8a here]
```

**Analysis:**
- Which tables have no SELECT policies: ________________
- Which tables have multiple SELECT policies: ________________

### 8b: User_schemes SELECT Policies (HIGH RISK)
```
[Paste results from Step 8b here]
```

**Critical Findings:**
- Uses customer_id filter: YES / NO
- Uses user_id filter: YES / NO
- Uses get_user_profile(): YES / NO
- **Issue:** Query in dashboard uses `user_id` but table has `customer_id` — SCHEMA MISMATCH

### 8c: Market_rates SELECT Policies (BLOCKED)
```
[Paste results from Step 8c here]
```

**Critical Findings:**
- Policy exists: YES / NO
- Public/Authenticated access: YES / NO
- **Status:** ❌ BLOCKED — needs fix

### 8d: Staff_metadata SELECT Policies (HIGH RISK)
```
[Paste results from Step 8d here]
```

**Critical Findings:**
- Uses profile_id filter: YES / NO
- Uses get_user_profile(): YES / NO
- **Status:** Should allow staff to read own metadata

### 8e: Schemes SELECT Policies (LOW RISK)
```
[Paste results from Step 8e here]
```

**Findings:**
- Public/Authenticated access: YES / NO
- **Status:** Should be public (reference data)

---

## STEP 9: TEST QUERIES

### 9a: Market Rates Test (Currently BLOCKED)
```
[Paste results from Step 9a here]
```

**Findings:**
- Query succeeded: YES / NO
- Error message (if failed): ________________
- **Status:** ❌ BLOCKED — needs policy fix

### 9b: User Schemes Test (Staff Perspective)
```
[Paste results from Step 9b here]
```

**Findings:**
- Query succeeded: YES / NO
- Scheme count: ___
- Active count: ___

### 9c: User Schemes Test (Customer Perspective)
```
[Paste results from Step 9c here]
```

**Findings:**
- Query succeeded: YES / NO
- Scheme count: ___
- Active count: ___

### 9d: Staff Metadata Test
```
[Paste results from Step 9d here]
```

**Findings:**
- Query succeeded: YES / NO
- Staff code: ________________
- Staff type: ________________

### 9e: Schemes Test (Should be Public)
```
[Paste results from Step 9e here]
```

**Findings:**
- Query succeeded: YES / NO
- Total schemes: ___
- Gold schemes: ___
- Silver schemes: ___

---

## STEP 10: FUNCTION EXISTENCE CHECK

### 10a: Staff Login Function Check
```
[Paste results from Step 10a here]
```

**Critical Findings:**
- `get_staff_email_by_code()` exists: YES / NO
- Is SECURITY DEFINER: YES / NO
- **Status:** Required for staff login

### 10b: All RLS Helper Functions
```
[Paste results from Step 10b here]
```

**Critical Findings:**
- `get_user_profile()` exists: YES / NO — Is SECURITY DEFINER: YES / NO
- `get_user_role()` exists: YES / NO — Is SECURITY DEFINER: YES / NO
- `is_staff()` exists: YES / NO — Is SECURITY DEFINER: YES / NO
- `is_admin()` exists: YES / NO — Is SECURITY DEFINER: YES / NO
- `is_staff_assigned_to_customer()` exists: YES / NO — Is SECURITY DEFINER: YES / NO
- `is_current_staff_assigned_to_customer()` exists: YES / NO — Is SECURITY DEFINER: YES / NO
- `get_staff_email_by_code()` exists: YES / NO — Is SECURITY DEFINER: YES / NO

---

## STEP 11: MISSING POLICY DETECTION

### 11a: Tables with RLS but No Policies
```
[Paste results from Step 11a here]
```

**Critical Findings:**
- Tables with RLS enabled but no policies: ________________
- **Impact:** These tables will BLOCK ALL queries (RLS enabled = deny by default)

### 11b: Tables Missing SELECT Policies
```
[Paste results from Step 11b here]
```

**Critical Findings:**
- Tables missing SELECT policies: ________________
- **Impact:** These tables cannot be queried (no SELECT access)

---

## ROOT CAUSE ANALYSIS

### Most Likely Causes:

**Payment INSERT:**
[ ] Function doesn't exist
[ ] Function not SECURITY DEFINER
[ ] Multiple conflicting policies
[ ] RESTRICTIVE policy blocking
[ ] RLS on staff_assignments blocking function
[ ] auth.uid() vs profile.id mismatch

**Market Rates SELECT:**
[ ] No SELECT policy exists
[ ] Policy exists but wrong roles
[ ] Policy has restrictions that block access
[ ] RLS enabled but no policy (deny by default)

**User Schemes:**
[ ] Schema mismatch (user_id vs customer_id)
[ ] Missing customer_id filter in policy
[ ] RLS blocking joins

**Staff Metadata:**
[ ] Missing SELECT policy
[ ] Policy doesn't use profile_id filter
[ ] Function doesn't exist

**Other:**
[ ] Other: ________________

### Evidence:
```
[Summarize evidence from above]
```

---

## RECOMMENDATION (NO CODE YET)

### Minimal RLS Design:

1. **Single INSERT Policy:**
   - Name: "Staff can insert payments"
   - Type: PERMISSIVE
   - Condition: `is_staff() AND (is_admin() OR (staff_id = get_user_profile() AND is_current_staff_assigned_to_customer(customer_id)))`

2. **SECURITY DEFINER Function:**
   - Name: `is_current_staff_assigned_to_customer(customer_uuid UUID)`
   - Must be SECURITY DEFINER
   - Must bypass RLS on staff_assignments

3. **No Dependencies:**
   - ❌ No market_rates
   - ❌ No metal calculations
   - ❌ No other RLS-protected tables

4. **Authorization Isolation:**
   - All authorization logic in one SECURITY DEFINER function
   - Policy only calls functions, no direct table queries

---

## NEXT STEPS

### Priority 1 (CRITICAL):
1. [ ] Fix market_rates SELECT policy (currently BLOCKED)
2. [ ] Verify `is_current_staff_assigned_to_customer()` exists and is SECURITY DEFINER
3. [ ] Fix payment INSERT policy (run migration)
4. [ ] Test payment INSERT after fix

### Priority 2 (HIGH):
5. [ ] Fix user_schemes query in customer dashboard (user_id → customer_id)
6. [ ] Verify staff_metadata SELECT policies
7. [ ] Test all SELECT queries from Step 9
8. [ ] Remove duplicate/conflicting policies

### Priority 3 (MEDIUM):
9. [ ] Verify all helper functions exist (Step 10)
10. [ ] Fix any tables with RLS but no policies (Step 11)
11. [ ] Document all RLS policies for future reference

