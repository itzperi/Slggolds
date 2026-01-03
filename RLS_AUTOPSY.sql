-- ============================================================================
-- RLS AUTOPSY - Full Policy Analysis
-- ============================================================================
-- Run this in Supabase SQL Editor to diagnose RLS policy conflicts
-- DO NOT make changes - analysis only
-- ============================================================================

-- ----------------------------------------------------------------------------
-- STEP 1: INVENTORY - List ALL RLS policies in public schema
-- ----------------------------------------------------------------------------
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual AS using_clause,
    with_check AS with_check_clause
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, cmd, policyname;

-- ----------------------------------------------------------------------------
-- STEP 2: FOCUS TABLES - Isolate policies for critical tables
-- ----------------------------------------------------------------------------

-- 2a: Payments table policies
SELECT
    'PAYMENTS' as table_focus,
    policyname,
    cmd,
    permissive,
    roles,
    qual AS using_clause,
    with_check AS with_check_clause
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'payments'
ORDER BY cmd, policyname;

-- 2b: Customers table policies
SELECT
    'CUSTOMERS' as table_focus,
    policyname,
    cmd,
    permissive,
    roles,
    qual AS using_clause,
    with_check AS with_check_clause
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'customers'
ORDER BY cmd, policyname;

-- 2c: Profiles table policies
SELECT
    'PROFILES' as table_focus,
    policyname,
    cmd,
    permissive,
    roles,
    qual AS using_clause,
    with_check AS with_check_clause
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'profiles'
ORDER BY cmd, policyname;

-- 2d: Staff_assignments table policies
SELECT
    'STAFF_ASSIGNMENTS' as table_focus,
    policyname,
    cmd,
    permissive,
    roles,
    qual AS using_clause,
    with_check AS with_check_clause
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'staff_assignments'
ORDER BY cmd, policyname;

-- 2e: User_schemes table policies
SELECT
    'USER_SCHEMES' as table_focus,
    policyname,
    cmd,
    permissive,
    roles,
    qual AS using_clause,
    with_check AS with_check_clause
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'user_schemes'
ORDER BY cmd, policyname;

-- 2f: Market_rates table policies
SELECT
    'MARKET_RATES' as table_focus,
    policyname,
    cmd,
    permissive,
    roles,
    qual AS using_clause,
    with_check AS with_check_clause
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'market_rates'
ORDER BY cmd, policyname;

-- 2g: Schemes table policies
SELECT
    'SCHEMES' as table_focus,
    policyname,
    cmd,
    permissive,
    roles,
    qual AS using_clause,
    with_check AS with_check_clause
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'schemes'
ORDER BY cmd, policyname;

-- 2h: Staff_metadata table policies
SELECT
    'STAFF_METADATA' as table_focus,
    policyname,
    cmd,
    permissive,
    roles,
    qual AS using_clause,
    with_check AS with_check_clause
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'staff_metadata'
ORDER BY cmd, policyname;

-- 2i: Withdrawals table policies (if exists)
SELECT
    'WITHDRAWALS' as table_focus,
    policyname,
    cmd,
    permissive,
    roles,
    qual AS using_clause,
    with_check AS with_check_clause
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'withdrawals'
ORDER BY cmd, policyname;

-- ----------------------------------------------------------------------------
-- STEP 3: INSERT PATH TRACE - Analyze payments INSERT policies
-- ----------------------------------------------------------------------------

-- 3a: Count INSERT policies on payments
SELECT
    'INSERT Policy Count' as analysis,
    COUNT(*) as total_insert_policies,
    COUNT(*) FILTER (WHERE permissive = 'PERMISSIVE') as permissive_count,
    COUNT(*) FILTER (WHERE permissive = 'RESTRICTIVE') as restrictive_count
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'payments'
AND cmd = 'INSERT';

-- 3b: List all INSERT policies with details
SELECT
    policyname,
    permissive,
    roles,
    with_check AS policy_condition,
    -- Extract function calls from with_check
    CASE 
        WHEN with_check LIKE '%is_staff%' THEN 'Uses is_staff()'
        WHEN with_check LIKE '%is_admin%' THEN 'Uses is_admin()'
        WHEN with_check LIKE '%get_user_profile%' THEN 'Uses get_user_profile()'
        WHEN with_check LIKE '%is_staff_assigned_to_customer%' THEN 'Uses is_staff_assigned_to_customer()'
        WHEN with_check LIKE '%is_current_staff_assigned_to_customer%' THEN 'Uses is_current_staff_assigned_to_customer()'
        WHEN with_check LIKE '%staff_assignments%' THEN 'References staff_assignments table'
        ELSE 'No known function/table references'
    END as dependencies
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'payments'
AND cmd = 'INSERT'
ORDER BY policyname;

-- 3c: Check for auth.uid() vs profile.id usage
SELECT
    'Auth vs Profile Check' as analysis,
    policyname,
    CASE 
        WHEN with_check LIKE '%auth.uid()%' THEN 'Uses auth.uid() directly'
        WHEN with_check LIKE '%get_user_profile()%' THEN 'Uses get_user_profile() (resolves auth.uid())'
        ELSE 'No auth.uid() usage'
    END as auth_resolution_method
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'payments'
AND cmd = 'INSERT';

-- 3d: Check for RLS-dependent table references
SELECT
    'RLS Dependency Check' as analysis,
    policyname,
    CASE 
        WHEN with_check LIKE '%staff_assignments%' THEN 'References staff_assignments (has RLS)'
        WHEN with_check LIKE '%profiles%' THEN 'References profiles (has RLS)'
        WHEN with_check LIKE '%customers%' THEN 'References customers (has RLS)'
        ELSE 'No RLS-dependent table references'
    END as rls_dependencies
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'payments'
AND cmd = 'INSERT';

-- ----------------------------------------------------------------------------
-- STEP 4: FUNCTION ANALYSIS - Check SECURITY DEFINER functions
-- ----------------------------------------------------------------------------

-- 4a: List all helper functions used in policies
SELECT
    proname as function_name,
    prosecdef as is_security_definer,
    prorettype::regtype as return_type,
    pg_get_functiondef(oid) as function_definition
FROM pg_proc
WHERE proname IN (
    'get_user_profile',
    'get_user_role',
    'is_staff',
    'is_admin',
    'is_staff_assigned_to_customer',
    'is_current_staff_assigned_to_customer'
)
ORDER BY proname;

-- 4b: Check if functions reference RLS-protected tables
SELECT
    proname as function_name,
    prosecdef as is_security_definer,
    CASE 
        WHEN pg_get_functiondef(oid) LIKE '%FROM staff_assignments%' THEN 'Queries staff_assignments'
        WHEN pg_get_functiondef(oid) LIKE '%FROM profiles%' THEN 'Queries profiles'
        WHEN pg_get_functiondef(oid) LIKE '%FROM customers%' THEN 'Queries customers'
        ELSE 'No RLS-protected table queries'
    END as rls_table_usage
FROM pg_proc
WHERE proname IN (
    'get_user_profile',
    'is_staff_assigned_to_customer',
    'is_current_staff_assigned_to_customer'
);

-- ----------------------------------------------------------------------------
-- STEP 5: MINIMAL REPRODUCTION - Test INSERT with minimal data
-- ----------------------------------------------------------------------------

-- 5a: Get current user context
SELECT
    'Current User Context' as test_name,
    auth.uid() as current_auth_uid,
    get_user_profile() as current_profile_id,
    get_user_role() as current_role,
    is_staff() as is_staff_result,
    is_admin() as is_admin_result;

-- 5b: Get test customer ID (replace with actual customer UUID from logs)
-- Using the customer ID from the error logs: e9f4b4b9-c61d-41ad-b900-17da50d2b753
SELECT
    'Test Customer Check' as test_name,
    'e9f4b4b9-c61d-41ad-b900-17da50d2b753'::uuid as customer_id,
    is_current_staff_assigned_to_customer('e9f4b4b9-c61d-41ad-b900-17da50d2b753'::uuid) as is_assigned;

-- 5c: Test assignment function directly
SELECT
    'Assignment Function Test' as test_name,
    get_user_profile() as staff_profile_id,
    'e9f4b4b9-c61d-41ad-b900-17da50d2b753'::uuid as customer_id,
    EXISTS (
        SELECT 1
        FROM staff_assignments sa
        WHERE sa.staff_id = get_user_profile()
        AND sa.customer_id = 'e9f4b4b9-c61d-41ad-b900-17da50d2b753'::uuid
        AND sa.is_active = true
    ) as direct_assignment_check;

-- 5d: Simulate full policy check
SELECT
    'Full Policy Simulation' as test_name,
    is_staff() as condition1_is_staff,
    is_admin() as condition2_is_admin,
    (
        get_user_profile() = get_user_profile() -- staff_id = get_user_profile()
    ) as condition3_staff_id_match,
    is_current_staff_assigned_to_customer('e9f4b4b9-c61d-41ad-b900-17da50d2b753'::uuid) as condition4_assigned,
    -- Full policy
    (
        is_staff() AND (
            is_admin() OR
            (
                get_user_profile() = get_user_profile()
                AND is_current_staff_assigned_to_customer('e9f4b4b9-c61d-41ad-b900-17da50d2b753'::uuid)
            )
        )
    ) as final_policy_result;

-- 5e: Attempt minimal INSERT (will show exact error)
-- Replace user_scheme_id with actual value from logs: 4bb9e8f0-c3fc-48c1-837c-5cf891f2c064
BEGIN;
SET LOCAL role authenticated;

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
    get_user_profile(),
    100.00,
    3.00,
    97.00,
    'cash',
    CURRENT_DATE,
    CURRENT_TIME,
    'completed',
    6245.00,
    0.0155,
    false,
    'test_device',
    NOW()
);

-- If successful, rollback
ROLLBACK;

-- If this fails, the error message will identify the exact policy blocking it

-- ----------------------------------------------------------------------------
-- STEP 6: POLICY CONFLICT DETECTION
-- ----------------------------------------------------------------------------

-- 6a: Check for overlapping policies (same cmd, different conditions) - ALL TABLES
SELECT
    'Policy Overlap Check' as analysis,
    tablename,
    cmd,
    COUNT(*) as policy_count,
    STRING_AGG(policyname, ', ') as policy_names
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('payments', 'customers', 'profiles', 'staff_assignments', 'user_schemes', 'market_rates', 'schemes', 'staff_metadata', 'withdrawals')
GROUP BY tablename, cmd
HAVING COUNT(*) > 1
ORDER BY tablename, cmd;

-- 6b: Check for RESTRICTIVE policies (these block even if PERMISSIVE allows) - ALL TABLES
SELECT
    'RESTRICTIVE Policy Check' as analysis,
    tablename,
    policyname,
    cmd,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('payments', 'customers', 'profiles', 'staff_assignments', 'user_schemes', 'market_rates', 'schemes', 'staff_metadata', 'withdrawals')
AND permissive = 'RESTRICTIVE'
ORDER BY tablename, cmd;

-- ----------------------------------------------------------------------------
-- STEP 7: RLS ENABLEMENT CHECK
-- ----------------------------------------------------------------------------

-- Check if RLS is enabled on ALL tables with RLS
SELECT
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('payments', 'customers', 'profiles', 'staff_assignments', 'user_schemes', 'market_rates', 'schemes', 'staff_metadata', 'withdrawals')
ORDER BY tablename;

-- ----------------------------------------------------------------------------
-- STEP 8: SELECT PATH TRACE - Analyze SELECT policies for all tables
-- ----------------------------------------------------------------------------

-- 8a: Count SELECT policies per table
SELECT
    'SELECT Policy Count' as analysis,
    tablename,
    COUNT(*) as total_select_policies,
    COUNT(*) FILTER (WHERE permissive = 'PERMISSIVE') as permissive_count,
    COUNT(*) FILTER (WHERE permissive = 'RESTRICTIVE') as restrictive_count
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('payments', 'customers', 'profiles', 'staff_assignments', 'user_schemes', 'market_rates', 'schemes', 'staff_metadata', 'withdrawals')
AND cmd = 'SELECT'
GROUP BY tablename
ORDER BY tablename;

-- 8b: Check user_schemes SELECT policies (HIGH RISK - 6 queries)
SELECT
    'USER_SCHEMES SELECT Policies' as analysis,
    policyname,
    permissive,
    roles,
    qual AS using_clause,
    CASE 
        WHEN qual LIKE '%customer_id%' THEN 'Filters by customer_id'
        WHEN qual LIKE '%user_id%' THEN 'Filters by user_id'
        WHEN qual LIKE '%get_user_profile%' THEN 'Uses get_user_profile()'
        WHEN qual LIKE '%auth.uid()%' THEN 'Uses auth.uid()'
        ELSE 'No customer/user filter'
    END as filter_method
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'user_schemes'
AND cmd = 'SELECT'
ORDER BY policyname;

-- 8c: Check market_rates SELECT policies (BLOCKED - needs fix)
SELECT
    'MARKET_RATES SELECT Policies' as analysis,
    policyname,
    permissive,
    roles,
    qual AS using_clause,
    CASE 
        WHEN roles::text LIKE '%public%' OR roles::text LIKE '%authenticated%' THEN 'Public/Authenticated access'
        WHEN qual IS NULL OR qual = '' THEN 'No restrictions (should allow all)'
        ELSE 'Has restrictions'
    END as access_level
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'market_rates'
AND cmd = 'SELECT'
ORDER BY policyname;

-- 8d: Check staff_metadata SELECT policies (HIGH RISK - 4 queries)
SELECT
    'STAFF_METADATA SELECT Policies' as analysis,
    policyname,
    permissive,
    roles,
    qual AS using_clause,
    CASE 
        WHEN qual LIKE '%profile_id%' THEN 'Filters by profile_id'
        WHEN qual LIKE '%get_user_profile%' THEN 'Uses get_user_profile()'
        WHEN qual LIKE '%auth.uid()%' THEN 'Uses auth.uid()'
        ELSE 'No profile filter'
    END as filter_method
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'staff_metadata'
AND cmd = 'SELECT'
ORDER BY policyname;

-- 8e: Check schemes SELECT policies (LOW RISK - 2 queries)
SELECT
    'SCHEMES SELECT Policies' as analysis,
    policyname,
    permissive,
    roles,
    qual AS using_clause,
    CASE 
        WHEN roles::text LIKE '%public%' OR roles::text LIKE '%authenticated%' THEN 'Public/Authenticated access'
        WHEN qual IS NULL OR qual = '' THEN 'No restrictions'
        ELSE 'Has restrictions'
    END as access_level
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'schemes'
AND cmd = 'SELECT'
ORDER BY policyname;

-- ----------------------------------------------------------------------------
-- STEP 9: TEST QUERIES - Test actual SELECT operations
-- ----------------------------------------------------------------------------

-- 9a: Test market_rates SELECT (currently BLOCKED)
SELECT
    'Market Rates Test' as test_name,
    COUNT(*) as rate_count,
    MAX(rate_date) as latest_rate_date
FROM market_rates
WHERE asset_type = 'gold'
ORDER BY rate_date DESC
LIMIT 1;

-- 9b: Test user_schemes SELECT (staff perspective)
SELECT
    'User Schemes Test (Staff)' as test_name,
    COUNT(*) as scheme_count,
    COUNT(*) FILTER (WHERE status = 'active') as active_count
FROM user_schemes
WHERE customer_id IN (
    SELECT customer_id 
    FROM staff_assignments 
    WHERE staff_id = get_user_profile() 
    AND is_active = true
    LIMIT 1
);

-- 9c: Test user_schemes SELECT (customer perspective)
SELECT
    'User Schemes Test (Customer)' as test_name,
    COUNT(*) as scheme_count,
    COUNT(*) FILTER (WHERE status = 'active') as active_count
FROM user_schemes
WHERE customer_id IN (
    SELECT id 
    FROM customers 
    WHERE profile_id = get_user_profile()
    LIMIT 1
);

-- 9d: Test staff_metadata SELECT
SELECT
    'Staff Metadata Test' as test_name,
    profile_id,
    staff_code,
    staff_type,
    daily_target_amount,
    daily_target_customers
FROM staff_metadata
WHERE profile_id = get_user_profile()
LIMIT 1;

-- 9e: Test schemes SELECT (should be public)
SELECT
    'Schemes Test' as test_name,
    COUNT(*) as scheme_count,
    COUNT(*) FILTER (WHERE asset_type = 'gold') as gold_count,
    COUNT(*) FILTER (WHERE asset_type = 'silver') as silver_count
FROM schemes
WHERE is_active = true;

-- ----------------------------------------------------------------------------
-- STEP 10: FUNCTION EXISTENCE CHECK - All helper functions
-- ----------------------------------------------------------------------------

-- 10a: Check if get_staff_email_by_code exists (for staff login)
SELECT
    'Staff Login Function Check' as analysis,
    proname as function_name,
    prosecdef as is_security_definer,
    prorettype::regtype as return_type,
    CASE 
        WHEN proname IS NULL THEN 'FUNCTION DOES NOT EXIST'
        ELSE 'Function exists'
    END as status
FROM pg_proc
WHERE proname = 'get_staff_email_by_code'
LIMIT 1;

-- 10b: List ALL functions used in RLS policies
SELECT
    'All RLS Helper Functions' as analysis,
    proname as function_name,
    prosecdef as is_security_definer,
    prorettype::regtype as return_type,
    CASE 
        WHEN prosecdef = true THEN 'SECURITY DEFINER (bypasses RLS)'
        ELSE 'SECURITY INVOKER (respects RLS)'
    END as security_mode
FROM pg_proc
WHERE proname IN (
    'get_user_profile',
    'get_user_role',
    'is_staff',
    'is_admin',
    'is_staff_assigned_to_customer',
    'is_current_staff_assigned_to_customer',
    'get_staff_email_by_code'
)
ORDER BY proname;

-- ----------------------------------------------------------------------------
-- STEP 11: MISSING POLICY DETECTION
-- ----------------------------------------------------------------------------

-- 11a: Check for tables with RLS enabled but no policies
SELECT
    'Tables with RLS but No Policies' as analysis,
    t.tablename,
    t.rowsecurity as rls_enabled,
    COUNT(p.policyname) as policy_count
FROM pg_tables t
LEFT JOIN pg_policies p ON t.tablename = p.tablename AND t.schemaname = p.schemaname
WHERE t.schemaname = 'public'
AND t.tablename IN ('payments', 'customers', 'profiles', 'staff_assignments', 'user_schemes', 'market_rates', 'schemes', 'staff_metadata', 'withdrawals')
AND t.rowsecurity = true
GROUP BY t.tablename, t.rowsecurity
HAVING COUNT(p.policyname) = 0
ORDER BY t.tablename;

-- 11b: Check for tables with RLS enabled but missing SELECT policies
SELECT
    'Tables Missing SELECT Policies' as analysis,
    t.tablename,
    COUNT(p.policyname) FILTER (WHERE p.cmd = 'SELECT') as select_policy_count
FROM pg_tables t
LEFT JOIN pg_policies p ON t.tablename = p.tablename AND t.schemaname = p.schemaname
WHERE t.schemaname = 'public'
AND t.tablename IN ('payments', 'customers', 'profiles', 'staff_assignments', 'user_schemes', 'market_rates', 'schemes', 'staff_metadata', 'withdrawals')
AND t.rowsecurity = true
GROUP BY t.tablename
HAVING COUNT(p.policyname) FILTER (WHERE p.cmd = 'SELECT') = 0
ORDER BY t.tablename;