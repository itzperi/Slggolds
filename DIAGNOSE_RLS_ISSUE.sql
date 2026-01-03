-- Diagnostic queries to check why payment insert is still failing
-- Run these in Supabase SQL Editor while logged in as the staff user

-- ============================================================================
-- STEP 1: Check if the function exists
-- ============================================================================
SELECT 
    proname as function_name,
    prosecdef as is_security_definer,
    prorettype::regtype as return_type
FROM pg_proc
WHERE proname = 'is_current_staff_assigned_to_customer';

-- Expected: Should return 1 row with is_security_definer = true

-- ============================================================================
-- STEP 2: Check if the policy exists and what it contains
-- ============================================================================
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd,
    with_check
FROM pg_policies
WHERE tablename = 'payments'
AND policyname = 'Staff can insert payments for assigned customers';

-- Expected: Should show policy with with_check containing 
-- 'is_current_staff_assigned_to_customer'

-- ============================================================================
-- STEP 3: Test RLS functions manually
-- ============================================================================
SELECT 
    'RLS Function Tests' as test_name,
    is_staff() as is_staff_result,
    get_user_profile() as current_profile_id,
    is_admin() as is_admin_result;

-- Expected: is_staff_result = true, current_profile_id = UUID

-- ============================================================================
-- STEP 4: Test the new SECURITY DEFINER function
-- ============================================================================
SELECT 
    'Assignment Function Test' as test_name,
    is_current_staff_assigned_to_customer('e9f4b4b9-c61d-41ad-b900-17da50d2b753'::uuid) as is_assigned;

-- Expected: is_assigned = true

-- ============================================================================
-- STEP 5: Simulate the exact RLS policy check
-- ============================================================================
SELECT 
    'Full Policy Check' as test_name,
    is_staff() as condition1_is_staff,
    is_admin() as condition2_is_admin,
    (
        '48ab80f5-7f9f-47aa-a56d-906bb94f9ece'::uuid = get_user_profile()
    ) as condition3_staff_id_match,
    is_current_staff_assigned_to_customer('e9f4b4b9-c61d-41ad-b900-17da50d2b753'::uuid) as condition4_assigned,
    -- Full policy evaluation
    (
        is_staff() AND (
            is_admin() OR
            (
                '48ab80f5-7f9f-47aa-a56d-906bb94f9ece'::uuid = get_user_profile()
                AND is_current_staff_assigned_to_customer('e9f4b4b9-c61d-41ad-b900-17da50d2b753'::uuid)
            )
        )
    ) as final_policy_result;

-- Expected: final_policy_result = true
-- If false, check which condition failed

-- ============================================================================
-- STEP 6: Check if old policy still exists (should be dropped)
-- ============================================================================
SELECT 
    policyname,
    cmd,
    with_check
FROM pg_policies
WHERE tablename = 'payments'
AND cmd = 'INSERT';

-- Expected: Should show ONLY "Staff can insert payments for assigned customers"
-- If multiple policies exist, that's the problem - drop the old ones

-- ============================================================================
-- STEP 7: Direct test insert (will show exact error)
-- ============================================================================
-- Replace values with actual data from your payment attempt
INSERT INTO payments (
    user_scheme_id,
    customer_id,
    staff_id,
    amount,
    gst_amount,
    net_amount,
    payment_method,
    payment_date,
    payment_time,
    status,
    metal_rate_per_gram,
    metal_grams_added,
    is_reversal,
    device_id,
    client_timestamp
) VALUES (
    '4bb9e8f0-c3fc-48c1-837c-5cf891f2c064'::uuid,
    'e9f4b4b9-c61d-41ad-b900-17da50d2b753'::uuid,
    '48ab80f5-7f9f-47aa-a56d-906bb94f9ece'::uuid,
    550.00,
    16.50,
    533.50,
    'cash',
    CURRENT_DATE,
    CURRENT_TIME,
    'completed',
    6245.00,
    0.0854,
    false,
    'test_device',
    NOW()
);

-- If this fails, the error message will show exactly what's wrong

