-- Test RLS Policy for Payment Insert
-- Run this in Supabase SQL Editor while logged in as the staff user

-- Step 1: Check if RLS functions work
SELECT 
    'RLS Function Tests' as test_name,
    is_staff() as is_staff_result,
    get_user_profile() as current_profile_id,
    is_admin() as is_admin_result;

-- Step 2: Test the assignment function
SELECT 
    'Assignment Test' as test_name,
    is_staff_assigned_to_customer('e9f4b4b9-c61d-41ad-b900-17da50d2b753'::uuid) as is_assigned;

-- Step 3: Simulate the exact RLS policy check
-- This is what the policy evaluates:
SELECT 
    'RLS Policy Simulation' as test_name,
    is_staff() as condition1,
    is_admin() as condition2_admin,
    (
        '48ab80f5-7f9f-47aa-a56d-906bb94f9ece'::uuid = get_user_profile()
    ) as condition2_staff_id_match,
    is_staff_assigned_to_customer('e9f4b4b9-c61d-41ad-b900-17da50d2b753'::uuid) as condition3_assigned,
    -- Full policy check
    (
        is_staff() AND (
            is_admin() OR
            (
                '48ab80f5-7f9f-47aa-a56d-906bb94f9ece'::uuid = get_user_profile()
                AND is_staff_assigned_to_customer('e9f4b4b9-c61d-41ad-b900-17da50d2b753'::uuid)
            )
        )
    ) as final_policy_result;

-- Step 4: Try a direct insert (this will show the actual error)
-- Replace the values with actual data from your payment attempt
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
    '4bb9e8f0-c3fc-48c1-837c-5cf891f2c064'::uuid,  -- user_scheme_id from logs
    'e9f4b4b9-c61d-41ad-b900-17da50d2b753'::uuid,  -- customer_id from logs
    '48ab80f5-7f9f-47aa-a56d-906bb94f9ece'::uuid,  -- staff_id from logs
    1000.00,
    30.00,
    970.00,
    'cash',
    CURRENT_DATE,
    CURRENT_TIME,
    'completed',
    6245.00,
    0.1553,
    false,
    'test_device',
    NOW()
);

-- If Step 4 fails, check which condition in Step 3 is false

