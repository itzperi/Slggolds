# Debug Payment RLS Permission Denied

## Step 1: Check the App Logs

After adding the debug logging, try to record a payment again and check the Flutter console logs. You should see:

```
PaymentService.insertPayment: DEBUG START
  - staffId: [UUID]
  - current auth.uid(): [UUID]
  - current user profile: {...}
  - staffId matches profile.id: true/false
  - staff_assignment: {...}
```

## Step 2: Run These SQL Queries in Supabase SQL Editor

### Query 1: Check Current User's Profile
```sql
-- Replace 'YOUR_AUTH_USER_ID' with the actual auth.uid() from logs
SELECT 
    id as profile_id,
    user_id as auth_user_id,
    role,
    active,
    name,
    email
FROM profiles
WHERE user_id = 'YOUR_AUTH_USER_ID';
```

**What to check:**
- ✅ `role` should be `'staff'` or `'admin'`
- ✅ `active` should be `true`
- ✅ `profile_id` should match the `staffId` being inserted

---

### Query 2: Check Staff Assignment
```sql
-- Replace with actual IDs from Query 1
SELECT 
    sa.id,
    sa.staff_id,
    sa.customer_id,
    sa.is_active,
    p_staff.name as staff_name,
    p_customer.name as customer_name
FROM staff_assignments sa
JOIN profiles p_staff ON p_staff.id = sa.staff_id
JOIN customers c ON c.id = sa.customer_id
JOIN profiles p_customer ON p_customer.id = c.profile_id
WHERE sa.staff_id = 'STAFF_PROFILE_ID_FROM_QUERY_1'
  AND sa.customer_id = 'CUSTOMER_ID_FROM_LOGS'
  AND sa.is_active = true;
```

**What to check:**
- ✅ Should return at least 1 row
- ✅ `is_active` should be `true`
- ✅ `staff_id` should match the profile_id from Query 1

---

### Query 3: Test RLS Functions Manually
```sql
-- Check if is_staff() returns true
SELECT is_staff() as is_staff_result;

-- Check if get_user_profile() returns correct ID
SELECT get_user_profile() as current_profile_id;

-- Check if assignment function works
SELECT is_staff_assigned_to_customer('CUSTOMER_ID_FROM_LOGS') as is_assigned;
```

**What to check:**
- ✅ `is_staff_result` should be `true`
- ✅ `current_profile_id` should match the `staffId` being inserted
- ✅ `is_assigned` should be `true`

---

### Query 4: Simulate the RLS Policy Check
```sql
-- This simulates what the RLS policy checks
SELECT 
    is_staff() as condition1_is_staff,
    get_user_profile() as condition2_profile_id,
    'STAFF_ID_FROM_LOGS' = get_user_profile()::text as condition2_match,
    is_staff_assigned_to_customer('CUSTOMER_ID_FROM_LOGS') as condition3_assigned,
    -- Final result
    (
        is_staff() 
        AND (
            is_admin() 
            OR (
                'STAFF_ID_FROM_LOGS' = get_user_profile()::text
                AND is_staff_assigned_to_customer('CUSTOMER_ID_FROM_LOGS')
            )
        )
    ) as final_policy_result;
```

**What to check:**
- ✅ `final_policy_result` should be `true`
- If any condition is `false`, that's your problem

---

## Step 3: Common Issues & Fixes

### Issue 1: `staffId` doesn't match `get_user_profile()`
**Symptom:** `staffId matches profile.id: false` in logs

**Fix:** The `staffId` being passed to `insertPayment()` must be the profile UUID, not the auth user_id.

**Check:**
```sql
-- Verify the staffId in your code matches this:
SELECT id FROM profiles WHERE user_id = auth.uid();
```

---

### Issue 2: No Staff Assignment Found
**Symptom:** `staff_assignment: null` in logs

**Fix:** Create the assignment:
```sql
INSERT INTO staff_assignments (staff_id, customer_id, is_active)
VALUES (
    'STAFF_PROFILE_ID',
    'CUSTOMER_ID',
    true
);
```

---

### Issue 3: Role is not 'staff' or 'admin'
**Symptom:** `is_staff_result: false` in Query 3

**Fix:** Update the profile role:
```sql
UPDATE profiles
SET role = 'staff'
WHERE id = 'PROFILE_ID';
```

---

### Issue 4: Profile is inactive
**Symptom:** `active: false` in Query 1

**Fix:** Activate the profile:
```sql
UPDATE profiles
SET active = true
WHERE id = 'PROFILE_ID';
```

---

## Step 4: Quick Diagnostic Query

Run this all-in-one diagnostic:

```sql
WITH current_user_profile AS (
    SELECT id, role, active, user_id
    FROM profiles
    WHERE user_id = auth.uid()
),
current_assignments AS (
    SELECT sa.*
    FROM staff_assignments sa
    WHERE sa.staff_id = (SELECT id FROM current_user_profile)
      AND sa.is_active = true
)
SELECT 
    'Profile Check' as check_type,
    CASE 
        WHEN (SELECT id FROM current_user_profile) IS NULL THEN '❌ No profile found'
        WHEN (SELECT role FROM current_user_profile) NOT IN ('staff', 'admin') THEN '❌ Role is not staff/admin'
        WHEN (SELECT active FROM current_user_profile) = false THEN '❌ Profile is inactive'
        ELSE '✅ Profile OK'
    END as result
UNION ALL
SELECT 
    'Assignment Check' as check_type,
    CASE 
        WHEN (SELECT COUNT(*) FROM current_assignments) = 0 THEN '❌ No active assignments'
        ELSE '✅ Has ' || (SELECT COUNT(*)::text FROM current_assignments) || ' active assignment(s)'
    END as result
UNION ALL
SELECT 
    'RLS Function Check' as check_type,
    CASE 
        WHEN is_staff() = false THEN '❌ is_staff() returns false'
        WHEN get_user_profile() IS NULL THEN '❌ get_user_profile() returns NULL'
        ELSE '✅ RLS functions OK'
    END as result;
```

This will show you exactly what's wrong.

---

## Step 5: After Fixing, Test Again

1. Try recording a payment again
2. Check the logs for the debug output
3. If it still fails, check which condition in Query 4 is false

