-- ============================================================================
-- FIX PAYMENT RLS POLICY - STAFF PAYMENT AUTHORIZATION
-- ============================================================================
-- 
-- PROBLEM:
-- Payment insert fails with "permission denied" because RLS on staff_assignments
-- blocks the EXISTS check inside the payments policy.
--
-- SOLUTION:
-- Create SECURITY DEFINER function that bypasses RLS to check assignments.
-- This isolates payment authorization from staff_assignments RLS.
--
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Step 1: Create SECURITY DEFINER function for assignment check
-- ----------------------------------------------------------------------------
-- This function runs as table owner, bypassing RLS on staff_assignments.
-- It answers ONE question: Is the current staff assigned to this customer?
--
CREATE OR REPLACE FUNCTION is_current_staff_assigned_to_customer(customer_uuid UUID)
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1
        FROM staff_assignments sa
        WHERE sa.staff_id = get_user_profile()
        AND sa.customer_id = customer_uuid
        AND sa.is_active = true
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ----------------------------------------------------------------------------
-- Step 2: Drop existing policy
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Staff can insert payments for assigned customers" ON payments;

-- ----------------------------------------------------------------------------
-- Step 3: Create new policy using SECURITY DEFINER function
-- ----------------------------------------------------------------------------
-- Authorization logic:
-- 1. User must be staff (is_staff())
-- 2. Either admin OR:
--    a. staff_id matches current user's profile
--    b. Staff is assigned to customer (via SECURITY DEFINER function)
--
CREATE POLICY "Staff can insert payments for assigned customers"
    ON payments FOR INSERT
    WITH CHECK (
        is_staff() AND (
            is_admin() OR
            (
                staff_id = get_user_profile()
                AND is_current_staff_assigned_to_customer(customer_id)
            )
        )
    );

-- ----------------------------------------------------------------------------
-- Step 4: Verify policy creation
-- ----------------------------------------------------------------------------
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd,
    with_check
FROM pg_policies
WHERE tablename = 'payments'
AND policyname = 'Staff can insert payments for assigned customers';

-- Expected: Policy should exist with with_check containing
-- 'is_current_staff_assigned_to_customer'

