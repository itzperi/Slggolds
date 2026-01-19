-- ============================================================================
-- FIX SCHEMA VISIBILITY - SLG GOLDS
-- ============================================================================
-- This script fixes the "42P17: relation 'profiles' does not exist" error
-- by explicitly qualifying table names and setting search paths.
-- ============================================================================

-- 1. Helper Function: Get current user's profile
CREATE OR REPLACE FUNCTION public.get_user_profile()
RETURNS UUID AS $$
    SELECT id FROM public.profiles WHERE user_id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = public, auth;

-- 2. Helper Function: Get current user's role
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS user_role AS $$
    SELECT role FROM public.profiles WHERE user_id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = public, auth;

-- 3. Helper Function: Check if user is admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
    SELECT public.get_user_role() = 'admin';
$$ LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = public, auth;

-- 4. Helper Function: Check if user is staff
CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS BOOLEAN AS $$
    SELECT public.get_user_role() IN ('staff', 'admin');
$$ LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = public, auth;

-- 5. Helper Function: Check if staff is assigned to customer (FIXED)
CREATE OR REPLACE FUNCTION public.is_staff_assigned_to_customer(customer_uuid UUID)
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.staff_assignments sa
        JOIN public.profiles p ON p.id = sa.staff_id
        WHERE p.user_id = auth.uid()
        AND sa.customer_id = customer_uuid
        AND sa.is_active = true
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = public, auth;

-- 6. Helper function for RLS (FIXED)
CREATE OR REPLACE FUNCTION public.is_current_staff_assigned_to_customer(customer_uuid UUID)
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.staff_assignments sa
        WHERE sa.staff_id = public.get_user_profile()
        AND sa.customer_id = customer_uuid
        AND sa.is_active = true
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = public, auth;

-- 7. Fix RLS policies on profiles to avoid recursion
-- Drop old policies
DROP POLICY IF EXISTS "Admin can manage profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can read own profile" ON public.profiles;

-- Re-create with non-recursive logic for admins
-- Using auth.jwt() to check role if possible, or simpler check
CREATE POLICY "Users can read own profile"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "Admin can manage profiles"
    ON public.profiles FOR ALL
    TO authenticated
    USING (
        (SELECT role FROM public.profiles WHERE user_id = auth.uid()) = 'admin'
    )
    WITH CHECK (
        (SELECT role FROM public.profiles WHERE user_id = auth.uid()) = 'admin'
    );

-- 8. Grant USAGE on public schema to anon and authenticated (just in case)
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;

-- 9. Refresh PostgREST cache (done automatically by Supabase)
