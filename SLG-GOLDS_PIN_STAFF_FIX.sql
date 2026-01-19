-- SLG-GOLDS PIN + STAFF LOGIN FIX
-- Supabase SQL Script
-- Date: 2026-01-19
-- Fixes: verify_pin RPC, staff profile, phone normalization

-- ============================================================================
-- 1. CREATE/UPDATE verify_pin RPC FUNCTION
-- ============================================================================
-- Updated to accept phone and pin directly (not hashed)
-- Handles phone normalization (+91 prefix)
-- Returns success boolean and role

-- Drop existing function if it exists (to avoid return type conflicts)
DROP FUNCTION IF EXISTS verify_pin(TEXT, TEXT);

-- Create the verify_pin function with proper return type
CREATE OR REPLACE FUNCTION verify_pin(phone TEXT, pin TEXT)
RETURNS TABLE(success BOOLEAN, role user_role) AS $$
DECLARE
    normalized_phone TEXT;
    hashed_pin TEXT;
    result_role user_role;
BEGIN
    -- Normalize phone number (add +91 prefix if missing)
    normalized_phone := CASE
        WHEN phone LIKE '+%' THEN phone
        ELSE '+91' || phone
    END;

    -- Hash the PIN using SHA-256
    hashed_pin := encode(digest(pin, 'sha256'), 'hex');

    -- Check if PIN matches and return success + role
    SELECT p.role INTO result_role
    FROM profiles p
    WHERE (p.phone = normalized_phone OR p.phone = phone)
    AND p.pin_hash = hashed_pin
    AND p.active = true;

    -- Return result
    RETURN QUERY SELECT
        (result_role IS NOT NULL) as success,
        result_role as role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 2. CREATE STAFF PROFILE FOR staff@slggolds.com
-- ============================================================================
-- First ensure the auth user exists (this should be created manually in Supabase Auth)
-- Then insert the profile

-- FIRST: Create the auth user in Supabase Auth Dashboard
-- Go to Authentication > Users > Add User
-- Email: staff@slggolds.com
-- Password: Staff@123
-- Then get the user ID from the users table

-- Insert staff profile (REPLACE 'YOUR_USER_ID_HERE' with actual UUID from auth.users)
-- The User ID looks like: a1b2c3d4-e5f6-7890-abcd-ef1234567890
DO $$
DECLARE
    staff_user_id_text TEXT := 'YOUR_USER_ID_HERE'; -- 🔴 REPLACE THIS WITH ACTUAL USER ID FROM SUPABASE AUTH
    staff_user_id UUID;
    staff_profile_id UUID;
    phone_owner_id UUID;
BEGIN
    -- Safety: don't crash if placeholder wasn't replaced
    IF staff_user_id_text IS NULL OR staff_user_id_text = '' OR staff_user_id_text = 'YOUR_USER_ID_HERE' THEN
        RAISE NOTICE 'Skipping staff profile insert: replace staff_user_id_text placeholder with real auth.users.id UUID for staff@slggolds.com';
        RETURN;
    END IF;

    staff_user_id := staff_user_id_text::UUID;

    -- Find existing rows (by phone and by user/email)
    SELECT id INTO phone_owner_id FROM profiles WHERE phone = '+919876543210' LIMIT 1;
    SELECT id INTO staff_profile_id
    FROM profiles
    WHERE user_id = staff_user_id
       OR email = 'staff@slggolds.com'
    LIMIT 1;

    -- If both exist and are different, free the phone on the non-phone row, then use the phone row
    IF phone_owner_id IS NOT NULL AND staff_profile_id IS NOT NULL AND phone_owner_id <> staff_profile_id THEN
        UPDATE profiles SET phone = NULL WHERE id = staff_profile_id;
        staff_profile_id := phone_owner_id;
    END IF;

    -- If only phone owner exists, use it
    IF staff_profile_id IS NULL AND phone_owner_id IS NOT NULL THEN
        staff_profile_id := phone_owner_id;
    END IF;

    IF staff_profile_id IS NOT NULL THEN
        UPDATE profiles
        SET
            user_id = staff_user_id,
            role = 'staff',
            phone = '+919876543210',
            name = 'SLG Staff',
            email = 'staff@slggolds.com',
            pin_hash = encode(digest('1234', 'sha256'), 'hex'),
            active = true,
            updated_at = NOW()
        WHERE id = staff_profile_id;
    ELSE
        INSERT INTO profiles (user_id, role, phone, name, email, pin_hash, active)
        VALUES (
            staff_user_id,
            'staff',
            '+919876543210',
            'SLG Staff',
            'staff@slggolds.com',
            encode(digest('1234', 'sha256'), 'hex'), -- PIN: 1234
            true
        );
    END IF;
END $$;

-- Insert staff metadata
DO $$
DECLARE
    staff_profile_id UUID;
BEGIN
    SELECT id INTO staff_profile_id FROM profiles WHERE email = 'staff@slggolds.com' LIMIT 1;
    IF staff_profile_id IS NULL THEN
        RAISE NOTICE 'Skipping staff_metadata insert: staff profile not found (did you set staff_user_id_text UUID?)';
        RETURN;
    END IF;

    UPDATE staff_metadata
    SET
        staff_code = 'ST001',
        staff_type = 'collection',
        daily_target_amount = 50000.00,
        daily_target_customers = 10,
        is_active = true,
        updated_at = NOW()
    WHERE profile_id = staff_profile_id;

    IF NOT FOUND THEN
        INSERT INTO staff_metadata (profile_id, staff_code, staff_type, daily_target_amount, daily_target_customers, is_active)
        VALUES (staff_profile_id, 'ST001', 'collection', 50000.00, 10, true);
    END IF;
END $$;

-- ============================================================================
-- 3. CREATE TEST CUSTOMERS WITH PHONE-ONLY PROFILES
-- ============================================================================
-- These customers can login with phone number only

-- Customer 1: +919876543211 / PIN: 1111
INSERT INTO profiles (phone, name, email, pin_hash, role, active)
VALUES (
    '+919876543211',
    'Rajesh Kumar',
    'rajesh@example.com',
    encode(digest('1111', 'sha256'), 'hex'),
    'customer',
    true
)
ON CONFLICT (phone) DO NOTHING;

INSERT INTO customers (profile_id, address, city, state, pincode, date_of_birth)
VALUES (
    (SELECT id FROM profiles WHERE phone = '+919876543211'),
    '123 Main St, Anna Nagar',
    'Chennai',
    'Tamil Nadu',
    '600040',
    '1985-05-15'::DATE
)
ON CONFLICT (profile_id) DO NOTHING;

-- Customer 2: +919876543212 / PIN: 2222
INSERT INTO profiles (phone, name, email, pin_hash, role, active)
VALUES (
    '+919876543212',
    'Priya Sharma',
    'priya@example.com',
    encode(digest('2222', 'sha256'), 'hex'),
    'customer',
    true
)
ON CONFLICT (phone) DO NOTHING;

INSERT INTO customers (profile_id, address, city, state, pincode, date_of_birth)
VALUES (
    (SELECT id FROM profiles WHERE phone = '+919876543212'),
    '456 Park Road, T. Nagar',
    'Chennai',
    'Tamil Nadu',
    '600017',
    '1990-08-22'::DATE
)
ON CONFLICT (profile_id) DO NOTHING;

-- Customer 3: +919876543213 / PIN: 3333
INSERT INTO profiles (phone, name, email, pin_hash, role, active)
VALUES (
    '+919876543213',
    'Amit Singh',
    'amit@example.com',
    encode(digest('3333', 'sha256'), 'hex'),
    'customer',
    true
)
ON CONFLICT (phone) DO NOTHING;

INSERT INTO customers (profile_id, address, city, state, pincode, date_of_birth)
VALUES (
    (SELECT id FROM profiles WHERE phone = '+919876543213'),
    '789 Gandhi Nagar',
    'Chennai',
    'Tamil Nadu',
    '600020',
    '1978-12-03'::DATE
)
ON CONFLICT (profile_id) DO NOTHING;

-- Customer 4: +919876543214 / PIN: 4444
INSERT INTO profiles (phone, name, email, pin_hash, role, active)
VALUES (
    '+919876543214',
    'Sneha Patel',
    'sneha@example.com',
    encode(digest('4444', 'sha256'), 'hex'),
    'customer',
    true
)
ON CONFLICT (phone) DO NOTHING;

INSERT INTO customers (profile_id, address, city, state, pincode, date_of_birth)
VALUES (
    (SELECT id FROM profiles WHERE phone = '+919876543214'),
    '321 Adyar Bridge Road',
    'Chennai',
    'Tamil Nadu',
    '600020',
    '1992-03-10'::DATE
)
ON CONFLICT (profile_id) DO NOTHING;

-- Customer 5: +919876543215 / PIN: 5555
INSERT INTO profiles (phone, name, email, pin_hash, role, active)
VALUES (
    '+919876543215',
    'Vikram Rao',
    'vikram@example.com',
    encode(digest('5555', 'sha256'), 'hex'),
    'customer',
    true
)
ON CONFLICT (phone) DO NOTHING;

INSERT INTO customers (profile_id, address, city, state, pincode, date_of_birth)
VALUES (
    (SELECT id FROM profiles WHERE phone = '+919876543215'),
    '654 Velachery Main Road',
    'Chennai',
    'Tamil Nadu',
    '600042',
    '1982-11-28'::DATE
)
ON CONFLICT (profile_id) DO NOTHING;

-- ============================================================================
-- 4. ASSIGN TEST CUSTOMERS TO STAFF
-- ============================================================================
-- Assign test customers to the staff member for collection

INSERT INTO staff_assignments (staff_id, customer_id, is_active, assigned_date)
VALUES
    (
        (SELECT id FROM profiles WHERE email = 'staff@slggolds.com'),
        (SELECT c.id FROM customers c JOIN profiles p ON p.id = c.profile_id WHERE p.phone = '+919876543211'),
        true,
        CURRENT_DATE
    ),
    (
        (SELECT id FROM profiles WHERE email = 'staff@slggolds.com'),
        (SELECT c.id FROM customers c JOIN profiles p ON p.id = c.profile_id WHERE p.phone = '+919876543212'),
        true,
        CURRENT_DATE
    ),
    (
        (SELECT id FROM profiles WHERE email = 'staff@slggolds.com'),
        (SELECT c.id FROM customers c JOIN profiles p ON p.id = c.profile_id WHERE p.phone = '+919876543213'),
        true,
        CURRENT_DATE
    ),
    (
        (SELECT id FROM profiles WHERE email = 'staff@slggolds.com'),
        (SELECT c.id FROM customers c JOIN profiles p ON p.id = c.profile_id WHERE p.phone = '+919876543214'),
        true,
        CURRENT_DATE
    ),
    (
        (SELECT id FROM profiles WHERE email = 'staff@slggolds.com'),
        (SELECT c.id FROM customers c JOIN profiles p ON p.id = c.profile_id WHERE p.phone = '+919876543215'),
        true,
        CURRENT_DATE
    );

-- Avoid ON CONFLICT for the same reason; insert only if missing
DELETE FROM staff_assignments
WHERE staff_id IS NULL OR customer_id IS NULL;

INSERT INTO staff_assignments (staff_id, customer_id, is_active, assigned_date)
SELECT
    (SELECT id FROM profiles WHERE email = 'staff@slggolds.com'),
    c.id,
    true,
    CURRENT_DATE
FROM customers c
JOIN profiles p ON p.id = c.profile_id
WHERE p.phone IN (
    '+919876543211',
    '+919876543212',
    '+919876543213',
    '+919876543214',
    '+919876543215'
)
AND NOT EXISTS (
    SELECT 1
    FROM staff_assignments sa
    WHERE sa.staff_id = (SELECT id FROM profiles WHERE email = 'staff@slggolds.com')
      AND sa.customer_id = c.id
      AND sa.is_active = true
);

-- ============================================================================
-- 5. GRANT NECESSARY PERMISSIONS
-- ============================================================================

-- Grant execute permissions on the verify_pin function
GRANT EXECUTE ON FUNCTION verify_pin(TEXT, TEXT) TO authenticated;

-- ============================================================================
-- 6. TEST DATA SUMMARY
-- ============================================================================
/*
STAFF LOGIN:
- Email: staff@slggolds.com
- Password: Staff@123
- PIN: 1234
- Staff Code: ST001
- Assigned Customers: 5 test customers

CUSTOMER PHONE-ONLY LOGIN:
- +919876543211 / PIN: 1111 (Rajesh Kumar)
- +919876543212 / PIN: 2222 (Priya Sharma)
- +919876543213 / PIN: 3333 (Amit Singh)
- +919876543214 / PIN: 4444 (Sneha Patel)
- +919876543215 / PIN: 5555 (Vikram Rao)

EXECUTION STEPS:
1. In Supabase Dashboard → Authentication → Users → Add User
   - Email: staff@slggolds.com
   - Password: Staff@123
   - Confirm Password: Staff@123
   - Click "Create user"

2. Copy the User ID (UUID) from the newly created user

3. In Supabase SQL Editor, run this script BUT FIRST:
   - Replace 'YOUR_USER_ID_HERE' with the actual UUID from step 2

4. Run the entire SQL script in Supabase SQL Editor

5. Test phone-only login by entering phone numbers without +91 prefix

TROUBLESHOOTING:
- If you get "cannot change return type" error, the DROP FUNCTION should handle it
- If function still exists, run: DROP FUNCTION verify_pin(TEXT, TEXT);
- Then run this script again
- Test with: SELECT * FROM verify_pin('+919876543211', '1111');

TEST QUERIES (run after setup):
-- Test verify_pin function
SELECT * FROM verify_pin('+919876543211', '1111'); -- Should return true, customer
SELECT * FROM verify_pin('9876543211', '1111'); -- Should return true, customer (no +91)
SELECT * FROM verify_pin('+919876543210', '1234'); -- Should return true, staff
SELECT * FROM verify_pin('+919876543211', '9999'); -- Should return false, null
*/
