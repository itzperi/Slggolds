-- ============================================================================
-- Create Default Authentication Accounts for SLG-GOLDS
-- ============================================================================
-- This script creates default staff and admin accounts for authentication
-- Staff: Staff/Staff@007 (email: staff@slggolds.com)
-- Admin: Admin/Admin@007 (email: admin@slggolds.com)
--
-- IMPORTANT: Run this AFTER creating the auth users via Supabase Auth
-- The script assumes auth.users entries exist and creates matching profiles
-- ============================================================================

-- ============================================================================
-- STEP 1: Create Staff Account (if not exists)
-- ============================================================================
-- First, create auth user via Supabase Auth API or Dashboard:
-- Email: staff@slggolds.com
-- Password: Staff@007
-- Then run this section to create profile and staff_metadata

DO $$
DECLARE
    staff_user_id UUID;
    staff_profile_id UUID;
BEGIN
    -- Check if staff user exists in auth.users (you need to create this first via Supabase Auth)
    -- For now, we'll use a function that tries to find or create
    
    -- Try to find existing staff user by email
    SELECT id INTO staff_user_id
    FROM auth.users
    WHERE email = 'staff@slggolds.com'
    LIMIT 1;
    
    -- If staff user doesn't exist, you need to create it via Supabase Auth Dashboard
    -- or use Supabase Admin API:
    -- INSERT INTO auth.users (email, encrypted_password, email_confirmed_at, created_at, updated_at)
    -- VALUES ('staff@slggolds.com', crypt('Staff@007', gen_salt('bf')), NOW(), NOW(), NOW());
    -- Then get the user_id
    
    IF staff_user_id IS NOT NULL THEN
        -- Create profile if not exists
        INSERT INTO profiles (user_id, role, phone, name, email, active)
        VALUES (
            staff_user_id,
            'staff',
            '+911000000001',
            'Default Staff',
            'staff@slggolds.com',
            true
        )
        ON CONFLICT (user_id) DO UPDATE
        SET role = 'staff',
            email = 'staff@slggolds.com',
            active = true
        RETURNING id INTO staff_profile_id;
        
        -- Create staff_metadata if not exists
        INSERT INTO staff_metadata (profile_id, staff_code, staff_type, daily_target_amount, daily_target_customers, is_active)
        VALUES (
            staff_profile_id,
            'STAFF',
            'collection',
            10000.00,
            10,
            true
        )
        ON CONFLICT (profile_id) DO UPDATE
        SET staff_code = 'STAFF',
            staff_type = 'collection',
            is_active = true;
            
        RAISE NOTICE 'Staff account created/updated: staff@slggolds.com (Staff/Staff@007)';
    ELSE
        RAISE NOTICE 'Staff user not found in auth.users. Please create user via Supabase Auth Dashboard first.';
    END IF;
END $$;

-- ============================================================================
-- STEP 2: Create Admin Account (if not exists)
-- ============================================================================
-- First, create auth user via Supabase Auth API or Dashboard:
-- Email: admin@slggolds.com
-- Password: Admin@007
-- Then run this section to create profile

DO $$
DECLARE
    admin_user_id UUID;
    admin_profile_id UUID;
BEGIN
    -- Try to find existing admin user by email
    SELECT id INTO admin_user_id
    FROM auth.users
    WHERE email = 'admin@slggolds.com'
    LIMIT 1;
    
    -- If admin user doesn't exist, create it via Supabase Auth Dashboard
    -- or use Supabase Admin API
    
    IF admin_user_id IS NOT NULL THEN
        -- Create profile if not exists
        INSERT INTO profiles (user_id, role, phone, name, email, active)
        VALUES (
            admin_user_id,
            'admin',
            '+911000000000',
            'Default Administrator',
            'admin@slggolds.com',
            true
        )
        ON CONFLICT (user_id) DO UPDATE
        SET role = 'admin',
            email = 'admin@slggolds.com',
            active = true
        RETURNING id INTO admin_profile_id;
            
        RAISE NOTICE 'Admin account created/updated: admin@slggolds.com (Admin/Admin@007)';
    ELSE
        RAISE NOTICE 'Admin user not found in auth.users. Please create user via Supabase Auth Dashboard first.';
    END IF;
END $$;

-- ============================================================================
-- VERIFICATION: Check created accounts
-- ============================================================================

-- Check staff account
SELECT 
    p.id as profile_id,
    p.user_id,
    p.role,
    p.name,
    p.email,
    p.phone,
    p.active,
    sm.staff_code,
    sm.staff_type
FROM profiles p
LEFT JOIN staff_metadata sm ON sm.profile_id = p.id
WHERE p.email IN ('staff@slggolds.com', 'admin@slggolds.com')
ORDER BY p.email;

-- ============================================================================
-- NOTES FOR MANUAL SETUP:
-- ============================================================================
-- If the script shows "user not found", you need to create auth users manually:
--
-- OPTION 1: Via Supabase Dashboard
-- 1. Go to Authentication > Users
-- 2. Click "Add user" > "Create new user"
-- 3. Email: staff@slggolds.com, Password: Staff@007
-- 4. Email: admin@slggolds.com, Password: Admin@007
-- 5. Then re-run this script to create profiles
--
-- OPTION 2: Via Supabase Management API (using service role key)
-- POST https://your-project.supabase.co/auth/v1/admin/users
-- Headers: {
--   "apikey": "YOUR_SERVICE_ROLE_KEY",
--   "Authorization": "Bearer YOUR_SERVICE_ROLE_KEY",
--   "Content-Type": "application/json"
-- }
-- Body: {
--   "email": "staff@slggolds.com",
--   "password": "Staff@007",
--   "email_confirm": true
-- }
-- ============================================================================

