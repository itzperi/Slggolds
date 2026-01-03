-- ============================================================================
-- SLG Thangangal - Production Database Schema
-- ============================================================================
-- Supabase PostgreSQL Schema
-- Version: 1.0.0
-- Date: December 2024
--
-- ARCHITECTURAL RULES:
-- 1. Authentication via Supabase Auth only (auth.users)
-- 2. Payments are APPEND-ONLY (immutable for audit)
-- 3. Row Level Security (RLS) enforced on all tables
-- 4. Offline sync support (device_id, client_timestamp)
-- 5. Server is authoritative source
--
-- This migration is IDEMPOTENT - safe to run multiple times
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- ENUMS
-- ============================================================================

-- User roles in the system
CREATE TYPE user_role AS ENUM ('customer', 'staff', 'admin');

-- Scheme asset types
CREATE TYPE asset_type AS ENUM ('gold', 'silver');

-- Payment frequency options
CREATE TYPE payment_frequency AS ENUM ('daily', 'weekly', 'monthly');

-- Payment methods
CREATE TYPE payment_method AS ENUM ('cash', 'upi', 'bank_transfer', 'other');

-- User scheme status
CREATE TYPE scheme_status AS ENUM ('active', 'paused', 'completed', 'mature', 'cancelled');

-- Payment status
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'reversed');

-- Withdrawal status
CREATE TYPE withdrawal_status AS ENUM ('pending', 'approved', 'processed', 'rejected', 'cancelled');

-- Withdrawal type
CREATE TYPE withdrawal_type AS ENUM ('partial', 'full');

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- profiles
-- ----------------------------------------------------------------------------
-- Links Supabase Auth users to application roles and basic profile data
-- All authenticated users (customer, staff, admin) have a profile
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    role user_role NOT NULL DEFAULT 'customer',
    phone TEXT NOT NULL,
    name TEXT NOT NULL,
    email TEXT,
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Offline sync support
    device_id TEXT,
    client_timestamp TIMESTAMPTZ,
    -- Constraints
    CONSTRAINT profiles_phone_format CHECK (phone ~ '^\+?[1-9]\d{1,14}$'),
    CONSTRAINT profiles_name_length CHECK (char_length(name) >= 2 AND char_length(name) <= 100),
    CONSTRAINT profiles_phone_unique UNIQUE (phone)
);

-- Indexes for profiles
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_phone ON profiles(phone);
CREATE INDEX IF NOT EXISTS idx_profiles_active ON profiles(active) WHERE active = true;

-- ----------------------------------------------------------------------------
-- customers
-- ----------------------------------------------------------------------------
-- Customer-specific data (KYC-lite fields)
-- Links to profiles via profile_id
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,
    address TEXT,
    city TEXT,
    state TEXT,
    pincode TEXT,
    date_of_birth DATE,
    pan_number TEXT,
    aadhaar_number TEXT,
    nominee_name TEXT,
    nominee_relation TEXT,
    nominee_phone TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Offline sync support
    device_id TEXT,
    client_timestamp TIMESTAMPTZ,
    -- Constraints
    CONSTRAINT customers_pincode_format CHECK (pincode IS NULL OR pincode ~ '^\d{6}$')
);

-- Indexes for customers
CREATE INDEX IF NOT EXISTS idx_customers_profile_id ON customers(profile_id);

-- ----------------------------------------------------------------------------
-- staff_metadata
-- ----------------------------------------------------------------------------
-- Staff-specific metadata (staff code, targets, assignments)
-- Links to profiles via profile_id
CREATE TABLE IF NOT EXISTS staff_metadata (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,
    staff_code TEXT NOT NULL UNIQUE,
    staff_type TEXT NOT NULL DEFAULT 'collection' CHECK (staff_type IN ('collection', 'office')),
    daily_target_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    daily_target_customers INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    join_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Offline sync support
    device_id TEXT,
    client_timestamp TIMESTAMPTZ,
    -- Constraints
    CONSTRAINT staff_metadata_staff_code_format CHECK (staff_code ~ '^[A-Z0-9]+$'),
    CONSTRAINT staff_metadata_target_amount_positive CHECK (daily_target_amount >= 0),
    CONSTRAINT staff_metadata_target_customers_positive CHECK (daily_target_customers >= 0)
);

-- Indexes for staff_metadata
CREATE INDEX IF NOT EXISTS idx_staff_metadata_profile_id ON staff_metadata(profile_id);
CREATE INDEX IF NOT EXISTS idx_staff_metadata_staff_code ON staff_metadata(staff_code);
CREATE INDEX IF NOT EXISTS idx_staff_metadata_active ON staff_metadata(is_active) WHERE is_active = true;

-- ----------------------------------------------------------------------------
-- schemes
-- ----------------------------------------------------------------------------
-- Available investment schemes (Gold/Silver)
-- Immutable reference data (admin creates, never updates)
CREATE TABLE IF NOT EXISTS schemes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scheme_code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    asset_type asset_type NOT NULL,
    min_daily_amount DECIMAL(10, 2) NOT NULL,
    max_daily_amount DECIMAL(10, 2) NOT NULL,
    installment_amount DECIMAL(10, 2) NOT NULL, -- Average/recommended amount
    frequency payment_frequency NOT NULL,
    duration_months INTEGER NOT NULL,
    entry_fee DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    expected_grams DECIMAL(10, 4) NOT NULL, -- Expected metal accumulation
    metal_accumulation_text TEXT NOT NULL, -- e.g., "500 mg", "1 g", "25 g"
    description TEXT,
    features JSONB, -- Array of feature strings
    how_it_works JSONB, -- Array of step strings
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Constraints
    CONSTRAINT schemes_amount_range CHECK (min_daily_amount > 0 AND max_daily_amount >= min_daily_amount),
    CONSTRAINT schemes_installment_range CHECK (installment_amount >= min_daily_amount AND installment_amount <= max_daily_amount),
    CONSTRAINT schemes_duration_positive CHECK (duration_months > 0),
    CONSTRAINT schemes_entry_fee_non_negative CHECK (entry_fee >= 0),
    CONSTRAINT schemes_expected_grams_positive CHECK (expected_grams > 0)
);

-- Indexes for schemes
CREATE INDEX IF NOT EXISTS idx_schemes_code ON schemes(scheme_code);
CREATE INDEX IF NOT EXISTS idx_schemes_asset_type ON schemes(asset_type);
CREATE INDEX IF NOT EXISTS idx_schemes_active ON schemes(active) WHERE active = true;

-- ----------------------------------------------------------------------------
-- user_schemes
-- ----------------------------------------------------------------------------
-- Customer enrollments in schemes
-- Tracks enrollment, payments, and status
CREATE TABLE IF NOT EXISTS user_schemes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    scheme_id UUID NOT NULL REFERENCES schemes(id) ON DELETE RESTRICT,
    enrollment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status scheme_status NOT NULL DEFAULT 'active',
    payment_frequency payment_frequency NOT NULL,
    min_amount DECIMAL(10, 2) NOT NULL, -- Customer's chosen min (within scheme range)
    max_amount DECIMAL(10, 2) NOT NULL, -- Customer's chosen max (within scheme range)
    -- Payment tracking
    total_amount_paid DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    payments_made INTEGER NOT NULL DEFAULT 0,
    payments_missed INTEGER NOT NULL DEFAULT 0,
    -- Metal accumulation (calculated from payments)
    accumulated_grams DECIMAL(10, 4) NOT NULL DEFAULT 0.0000,
    -- Dates
    maturity_date DATE,
    completed_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Offline sync support
    device_id TEXT,
    client_timestamp TIMESTAMPTZ,
    -- Constraints
    CONSTRAINT user_schemes_amount_range CHECK (min_amount > 0 AND max_amount >= min_amount),
    CONSTRAINT user_schemes_totals_non_negative CHECK (
        total_amount_paid >= 0 AND
        payments_made >= 0 AND
        payments_missed >= 0 AND
        accumulated_grams >= 0
    )
);

-- Indexes for user_schemes
CREATE INDEX IF NOT EXISTS idx_user_schemes_customer_id ON user_schemes(customer_id);
CREATE INDEX IF NOT EXISTS idx_user_schemes_scheme_id ON user_schemes(scheme_id);
CREATE INDEX IF NOT EXISTS idx_user_schemes_status ON user_schemes(status);
CREATE INDEX IF NOT EXISTS idx_user_schemes_enrollment_date ON user_schemes(enrollment_date);
CREATE INDEX IF NOT EXISTS idx_user_schemes_active ON user_schemes(status) WHERE status = 'active';

-- ----------------------------------------------------------------------------
-- payments
-- ----------------------------------------------------------------------------
-- APPEND-ONLY payment records (immutable for audit)
-- All payments, including reversals, are inserts
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_scheme_id UUID NOT NULL REFERENCES user_schemes(id) ON DELETE RESTRICT,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    staff_id UUID REFERENCES profiles(id) ON DELETE SET NULL, -- NULL for self-payments
    -- Payment details
    amount DECIMAL(12, 2) NOT NULL, -- Gross amount collected
    gst_amount DECIMAL(12, 2) NOT NULL, -- GST (3% of amount)
    net_amount DECIMAL(12, 2) NOT NULL, -- Net investment (amount - GST)
    payment_method payment_method NOT NULL,
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    payment_time TIME,
    status payment_status NOT NULL DEFAULT 'completed',
    -- Metal calculation
    metal_rate_per_gram DECIMAL(10, 2) NOT NULL, -- Rate at time of payment
    metal_grams_added DECIMAL(10, 4) NOT NULL DEFAULT 0.0000, -- net_amount / rate
    -- Reversal tracking (for corrections)
    is_reversal BOOLEAN NOT NULL DEFAULT false,
    reverses_payment_id UUID REFERENCES payments(id) ON DELETE RESTRICT, -- If this reverses another payment
    reversal_reason TEXT, -- Why this payment was reversed
    -- Metadata
    receipt_number TEXT UNIQUE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Offline sync support
    device_id TEXT NOT NULL, -- Device that created this payment
    client_timestamp TIMESTAMPTZ NOT NULL, -- Client's timestamp when payment was recorded
    server_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(), -- Server's authoritative timestamp
    -- Constraints
    CONSTRAINT payments_amount_positive CHECK (amount > 0),
    CONSTRAINT payments_gst_calculation CHECK (
        ABS(gst_amount - (amount * 0.03)) < 0.01 -- Allow small rounding differences
    ),
    CONSTRAINT payments_net_calculation CHECK (
        ABS(net_amount - (amount * 0.97)) < 0.01 -- Allow small rounding differences
    ),
    CONSTRAINT payments_metal_rate_positive CHECK (metal_rate_per_gram > 0),
    CONSTRAINT payments_metal_grams_non_negative CHECK (metal_grams_added >= 0),
    CONSTRAINT payments_reversal_logic CHECK (
        (is_reversal = false AND reverses_payment_id IS NULL) OR
        (is_reversal = true AND reverses_payment_id IS NOT NULL)
    )
);

-- Indexes for payments
CREATE INDEX IF NOT EXISTS idx_payments_user_scheme_id ON payments(user_scheme_id);
CREATE INDEX IF NOT EXISTS idx_payments_customer_id ON payments(customer_id);
CREATE INDEX IF NOT EXISTS idx_payments_staff_id ON payments(staff_id);
CREATE INDEX IF NOT EXISTS idx_payments_payment_date ON payments(payment_date);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_receipt_number ON payments(receipt_number);
CREATE INDEX IF NOT EXISTS idx_payments_created_at ON payments(created_at);
CREATE INDEX IF NOT EXISTS idx_payments_reversal ON payments(is_reversal, reverses_payment_id);
-- Composite index for daily collections report
CREATE INDEX IF NOT EXISTS idx_payments_staff_date ON payments(staff_id, payment_date) WHERE status = 'completed' AND is_reversal = false;
-- Composite index for customer payment history
CREATE INDEX IF NOT EXISTS idx_payments_customer_date ON payments(customer_id, payment_date DESC) WHERE status = 'completed' AND is_reversal = false;

-- ----------------------------------------------------------------------------
-- Column Comments: payments
-- ----------------------------------------------------------------------------
-- CRITICAL: metal_rate_per_gram must be written by application at payment time
-- Never recalculated or derived later. This ensures accounting immutability.
COMMENT ON COLUMN payments.metal_rate_per_gram IS
'Rate used at time of payment. Must be written by application. Never recalculated.';

-- ----------------------------------------------------------------------------
-- withdrawals
-- ----------------------------------------------------------------------------
-- Customer withdrawal requests
-- Tracks requests, approvals, and processing
CREATE TABLE IF NOT EXISTS withdrawals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_scheme_id UUID NOT NULL REFERENCES user_schemes(id) ON DELETE RESTRICT,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    withdrawal_type withdrawal_type NOT NULL,
    requested_amount DECIMAL(12, 2), -- NULL for full withdrawals
    requested_grams DECIMAL(10, 4), -- Metal grams to withdraw
    status withdrawal_status NOT NULL DEFAULT 'pending',
    -- Processing
    approved_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    approved_at TIMESTAMPTZ,
    processed_at TIMESTAMPTZ,
    rejection_reason TEXT,
    -- Final amounts (set on approval/processing)
    final_amount DECIMAL(12, 2),
    final_grams DECIMAL(10, 4),
    -- Metadata
    request_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Offline sync support
    device_id TEXT,
    client_timestamp TIMESTAMPTZ,
    -- Constraints
    CONSTRAINT withdrawals_amount_positive CHECK (requested_amount IS NULL OR requested_amount > 0),
    CONSTRAINT withdrawals_grams_positive CHECK (requested_grams > 0),
    CONSTRAINT withdrawals_type_amount_logic CHECK (
        (withdrawal_type = 'full' AND requested_amount IS NULL) OR
        (withdrawal_type = 'partial' AND requested_amount IS NOT NULL)
    )
);

-- Indexes for withdrawals
CREATE INDEX IF NOT EXISTS idx_withdrawals_user_scheme_id ON withdrawals(user_scheme_id);
CREATE INDEX IF NOT EXISTS idx_withdrawals_customer_id ON withdrawals(customer_id);
CREATE INDEX IF NOT EXISTS idx_withdrawals_status ON withdrawals(status);
CREATE INDEX IF NOT EXISTS idx_withdrawals_created_at ON withdrawals(created_at);

-- ----------------------------------------------------------------------------
-- market_rates
-- ----------------------------------------------------------------------------
-- Daily market rates for gold and silver
-- Admin updates daily, historical data preserved
CREATE TABLE IF NOT EXISTS market_rates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rate_date DATE NOT NULL DEFAULT CURRENT_DATE,
    asset_type asset_type NOT NULL,
    price_per_gram DECIMAL(10, 2) NOT NULL,
    change_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00, -- Change from previous day
    change_percent DECIMAL(5, 2) NOT NULL DEFAULT 0.00, -- Percentage change
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Constraints
    CONSTRAINT market_rates_price_positive CHECK (price_per_gram > 0),
    CONSTRAINT market_rates_unique_date_asset UNIQUE (rate_date, asset_type)
);

-- Indexes for market_rates
CREATE INDEX IF NOT EXISTS idx_market_rates_date ON market_rates(rate_date DESC);
CREATE INDEX IF NOT EXISTS idx_market_rates_asset_type ON market_rates(asset_type);
CREATE INDEX IF NOT EXISTS idx_market_rates_latest ON market_rates(asset_type, rate_date DESC);

-- ----------------------------------------------------------------------------
-- staff_assignments
-- ----------------------------------------------------------------------------
-- Which staff members are assigned to which customers
-- Many-to-many relationship
CREATE TABLE IF NOT EXISTS staff_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    staff_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    is_active BOOLEAN NOT NULL DEFAULT true,
    assigned_date DATE NOT NULL DEFAULT CURRENT_DATE,
    unassigned_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Constraints
    CONSTRAINT staff_assignments_unique_active UNIQUE (staff_id, customer_id, is_active) 
        DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT staff_assignments_dates_logic CHECK (
        unassigned_date IS NULL OR unassigned_date >= assigned_date
    )
);

-- Indexes for staff_assignments
CREATE INDEX IF NOT EXISTS idx_staff_assignments_staff_id ON staff_assignments(staff_id);
CREATE INDEX IF NOT EXISTS idx_staff_assignments_customer_id ON staff_assignments(customer_id);
CREATE INDEX IF NOT EXISTS idx_staff_assignments_active ON staff_assignments(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_staff_assignments_staff_active ON staff_assignments(staff_id, is_active) WHERE is_active = true;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Function: Update updated_at timestamp
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customers_updated_at
    BEFORE UPDATE ON customers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_staff_metadata_updated_at
    BEFORE UPDATE ON staff_metadata
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_schemes_updated_at
    BEFORE UPDATE ON schemes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_schemes_updated_at
    BEFORE UPDATE ON user_schemes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_withdrawals_updated_at
    BEFORE UPDATE ON withdrawals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_staff_assignments_updated_at
    BEFORE UPDATE ON staff_assignments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ----------------------------------------------------------------------------
-- Function: Update user_schemes totals on payment insert
-- ----------------------------------------------------------------------------
-- When a payment is inserted, update the user_scheme totals
-- Handles both regular payments and reversals
CREATE OR REPLACE FUNCTION update_user_scheme_totals()
RETURNS TRIGGER AS $$
DECLARE
    scheme_asset_type asset_type;
    current_rate DECIMAL(10, 2);
BEGIN
    -- Get scheme asset type and current market rate
    SELECT s.asset_type INTO scheme_asset_type
    FROM schemes s
    JOIN user_schemes us ON us.scheme_id = s.id
    WHERE us.id = NEW.user_scheme_id;

    -- Get latest market rate for this asset type
    SELECT price_per_gram INTO current_rate
    FROM market_rates
    WHERE asset_type = scheme_asset_type
    ORDER BY rate_date DESC
    LIMIT 1;

    -- If no rate found, use the rate from payment (for historical payments)
    IF current_rate IS NULL THEN
        current_rate := NEW.metal_rate_per_gram;
    END IF;

    -- Calculate metal grams if not already set
    IF NEW.metal_grams_added = 0 AND NEW.net_amount > 0 AND current_rate > 0 THEN
        NEW.metal_grams_added := NEW.net_amount / current_rate;
    END IF;

    -- Update user_scheme totals
    IF NEW.is_reversal = false AND NEW.status = 'completed' THEN
        -- Regular payment: add to totals
        UPDATE user_schemes
        SET
            total_amount_paid = total_amount_paid + NEW.net_amount,
            payments_made = payments_made + 1,
            accumulated_grams = accumulated_grams + NEW.metal_grams_added,
            updated_at = NOW()
        WHERE id = NEW.user_scheme_id;
    ELSIF NEW.is_reversal = true AND NEW.status = 'completed' THEN
        -- Reversal: subtract from totals
        UPDATE user_schemes
        SET
            total_amount_paid = GREATEST(0, total_amount_paid - NEW.net_amount),
            payments_made = GREATEST(0, payments_made - 1),
            accumulated_grams = GREATEST(0, accumulated_grams - NEW.metal_grams_added),
            updated_at = NOW()
        WHERE id = NEW.user_scheme_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update totals on payment insert
CREATE TRIGGER trigger_update_user_scheme_totals
    AFTER INSERT ON payments
    FOR EACH ROW
    WHEN (NEW.status = 'completed')
    EXECUTE FUNCTION update_user_scheme_totals();

-- ----------------------------------------------------------------------------
-- Function: Enforce payment immutability
-- ----------------------------------------------------------------------------
-- Prevent UPDATE and DELETE on payments table (append-only)
CREATE OR REPLACE FUNCTION prevent_payment_modification()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Payments are immutable. Use reversal entries for corrections.';
END;
$$ LANGUAGE plpgsql;

-- Trigger to prevent payment updates
CREATE TRIGGER prevent_payment_update
    BEFORE UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION prevent_payment_modification();

-- Trigger to prevent payment deletes
CREATE TRIGGER prevent_payment_delete
    BEFORE DELETE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION prevent_payment_modification();

-- ----------------------------------------------------------------------------
-- Function: Generate receipt number
-- ----------------------------------------------------------------------------
-- Auto-generate receipt number if not provided
CREATE OR REPLACE FUNCTION generate_receipt_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.receipt_number IS NULL THEN
        NEW.receipt_number := 'RCP-' || TO_CHAR(NOW(), 'YYYY') || '-' || 
            LPAD(NEXTVAL('receipt_number_seq')::TEXT, 8, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create sequence for receipt numbers
CREATE SEQUENCE IF NOT EXISTS receipt_number_seq START 1;

-- Trigger to generate receipt number
CREATE TRIGGER generate_payment_receipt_number
    BEFORE INSERT ON payments
    FOR EACH ROW
    WHEN (NEW.receipt_number IS NULL)
    EXECUTE FUNCTION generate_receipt_number();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE schemes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_schemes ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE withdrawals ENABLE ROW LEVEL SECURITY;
ALTER TABLE market_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_assignments ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------------------
-- Helper function: Get current user's profile
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_user_profile()
RETURNS UUID AS $$
    SELECT id FROM profiles WHERE user_id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ----------------------------------------------------------------------------
-- Helper function: Get current user's role
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS user_role AS $$
    SELECT role FROM profiles WHERE user_id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ----------------------------------------------------------------------------
-- Helper function: Check if user is admin
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
    SELECT get_user_role() = 'admin';
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ----------------------------------------------------------------------------
-- Helper function: Check if user is staff
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION is_staff()
RETURNS BOOLEAN AS $$
    SELECT get_user_role() IN ('staff', 'admin');
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ----------------------------------------------------------------------------
-- Helper function: Check if staff is assigned to customer
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION is_staff_assigned_to_customer(customer_uuid UUID)
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1
        FROM staff_assignments sa
        JOIN profiles p ON p.id = sa.staff_id
        WHERE p.user_id = auth.uid()
        AND sa.customer_id = customer_uuid
        AND sa.is_active = true
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ----------------------------------------------------------------------------
-- Helper function: Check if current staff is assigned to customer (for RLS)
-- Uses SECURITY DEFINER to bypass RLS on staff_assignments
-- ----------------------------------------------------------------------------
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
-- Function: Get staff email by staff_code (for login)
-- ----------------------------------------------------------------------------
-- This function bypasses RLS to allow staff_code → email lookup during login
-- SECURITY DEFINER runs with the privileges of the function owner (postgres)
CREATE OR REPLACE FUNCTION get_staff_email_by_code(staff_code_param TEXT)
RETURNS TABLE(email TEXT, user_id UUID) AS $$
BEGIN
    RETURN QUERY
    SELECT p.email, p.user_id
    FROM staff_metadata sm
    INNER JOIN profiles p ON p.id = sm.profile_id
    WHERE sm.staff_code = UPPER(staff_code_param)
    AND sm.is_active = true
    AND p.email IS NOT NULL
    AND p.email != '';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- Function: Get customer profile (for staff access)
-- ----------------------------------------------------------------------------
-- This function bypasses RLS to allow staff to read customer profiles
-- SECURITY DEFINER runs with the privileges of the function owner (postgres)
-- Only returns profile if staff is assigned to the customer
CREATE OR REPLACE FUNCTION get_customer_profile_for_staff(profile_id_param UUID)
RETURNS TABLE(id UUID, name TEXT, phone TEXT) AS $$
BEGIN
    -- Verify staff is assigned to a customer with this profile_id
    IF EXISTS (
        SELECT 1
        FROM staff_assignments sa
        JOIN customers c ON c.id = sa.customer_id
        JOIN profiles p ON p.id = sa.staff_id
        WHERE p.user_id = auth.uid()
        AND c.profile_id = profile_id_param
        AND sa.is_active = true
    ) THEN
        RETURN QUERY
        SELECT pr.id, pr.name, pr.phone
        FROM profiles pr
        WHERE pr.id = profile_id_param;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- RLS Policies: profiles
-- ----------------------------------------------------------------------------
-- Users can read their own profile
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
CREATE POLICY "Users can read own profile"
    ON profiles FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- Staff can read profiles of assigned customers
-- This allows staff to see customer names/phones for collection purposes
-- Uses get_user_profile() to avoid circular dependency (SECURITY DEFINER)
DROP POLICY IF EXISTS "Staff can read assigned customer profiles" ON profiles;
CREATE POLICY "Staff can read assigned customer profiles"
    ON profiles FOR SELECT
    TO authenticated
    USING (
        -- Staff can read profile if it belongs to a customer assigned to them
        -- Use get_user_profile() instead of querying profiles directly to avoid recursion
        EXISTS (
            SELECT 1
            FROM staff_assignments sa
            JOIN customers c ON c.id = sa.customer_id
            WHERE sa.staff_id = get_user_profile()  -- SECURITY DEFINER, no recursion
            AND c.profile_id = profiles.id
            AND sa.is_active = true
        )
    );

-- Users can update their own profile (limited fields)
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Admin can insert/update/delete profiles
DROP POLICY IF EXISTS "Admin can manage profiles" ON profiles;
CREATE POLICY "Admin can manage profiles"
    ON profiles FOR ALL
    TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());

-- ----------------------------------------------------------------------------
-- RLS Policies: customers
-- ----------------------------------------------------------------------------
-- Customers can read their own customer record
CREATE POLICY "Customers can read own record"
    ON customers FOR SELECT
    USING (
        profile_id = get_user_profile() OR
        is_staff()
    );

-- Customers can update their own record
CREATE POLICY "Customers can update own record"
    ON customers FOR UPDATE
    USING (profile_id = get_user_profile())
    WITH CHECK (profile_id = get_user_profile());

-- Staff can read assigned customers
CREATE POLICY "Staff can read assigned customers"
    ON customers FOR SELECT
    USING (
        is_staff() AND (
            is_admin() OR
            is_staff_assigned_to_customer(id)
        )
    );

-- Admin can manage all customers
CREATE POLICY "Admin can manage customers"
    ON customers FOR ALL
    USING (is_admin())
    WITH CHECK (is_admin());

-- ----------------------------------------------------------------------------
-- RLS Policies: staff_metadata
-- ----------------------------------------------------------------------------
-- Allow unauthenticated staff_code lookups for login (email resolution only)
-- This is safe because we only expose staff_code and email, not sensitive data
CREATE POLICY "Allow staff_code lookup for login"
    ON staff_metadata FOR SELECT
    USING (true);  -- Allow all SELECT for login resolution

-- Staff can read their own metadata
-- NOTE: Uses subquery to avoid circular dependency (staff_metadata RLS queries profiles, but profiles RLS doesn't query staff_metadata)
DROP POLICY IF EXISTS "Staff can read own metadata" ON staff_metadata;
CREATE POLICY "Staff can read own metadata"
    ON staff_metadata FOR SELECT
    TO authenticated
    USING (
        profile_id IN (
            SELECT id
            FROM profiles
            WHERE user_id = auth.uid()
        )
    );

-- Staff can update their own metadata (limited fields)
CREATE POLICY "Staff can update own metadata"
    ON staff_metadata FOR UPDATE
    USING (profile_id = get_user_profile())
    WITH CHECK (profile_id = get_user_profile());

-- Admin can manage all staff metadata
CREATE POLICY "Admin can manage staff metadata"
    ON staff_metadata FOR ALL
    USING (is_admin())
    WITH CHECK (is_admin());

-- ----------------------------------------------------------------------------
-- RLS Policies: schemes
-- ----------------------------------------------------------------------------
-- Everyone can read active schemes
CREATE POLICY "Everyone can read active schemes"
    ON schemes FOR SELECT
    USING (active = true OR is_staff());

-- Admin can manage schemes
CREATE POLICY "Admin can manage schemes"
    ON schemes FOR ALL
    USING (is_admin())
    WITH CHECK (is_admin());

-- ----------------------------------------------------------------------------
-- RLS Policies: user_schemes
-- ----------------------------------------------------------------------------
-- Customers can read their own schemes
CREATE POLICY "Customers can read own schemes"
    ON user_schemes FOR SELECT
    USING (
        customer_id IN (
            SELECT id FROM customers WHERE profile_id = get_user_profile()
        ) OR
        is_staff()
    );

-- Customers can insert their own schemes (enrollment)
CREATE POLICY "Customers can enroll in schemes"
    ON user_schemes FOR INSERT
    WITH CHECK (
        customer_id IN (
            SELECT id FROM customers WHERE profile_id = get_user_profile()
        ) OR
        is_admin()
    );

-- Staff can read assigned customer schemes
CREATE POLICY "Staff can read assigned customer schemes"
    ON user_schemes FOR SELECT
    USING (
        is_staff() AND (
            is_admin() OR
            is_staff_assigned_to_customer(customer_id)
        )
    );

-- Admin can manage all user schemes
CREATE POLICY "Admin can manage user schemes"
    ON user_schemes FOR ALL
    USING (is_admin())
    WITH CHECK (is_admin());

-- ----------------------------------------------------------------------------
-- RLS Policies: payments
-- ----------------------------------------------------------------------------
-- Customers can read their own payments
CREATE POLICY "Customers can read own payments"
    ON payments FOR SELECT
    USING (
        customer_id IN (
            SELECT id FROM customers WHERE profile_id = get_user_profile()
        ) OR
        is_staff()
    );

-- Staff can insert payments for assigned customers
-- Uses SECURITY DEFINER function to bypass RLS on staff_assignments
CREATE POLICY "Staff can insert payments for assigned customers"
    ON payments FOR INSERT
    WITH CHECK (
        is_staff() AND (
            is_admin() OR
            (
                staff_id = get_user_profile() AND
                is_current_staff_assigned_to_customer(customer_id)
            )
        )
    );

-- Staff can read payments for assigned customers
CREATE POLICY "Staff can read assigned customer payments"
    ON payments FOR SELECT
    USING (
        is_staff() AND (
            is_admin() OR
            is_staff_assigned_to_customer(customer_id)
        )
    );

-- Admin can read all payments
CREATE POLICY "Admin can read all payments"
    ON payments FOR SELECT
    USING (is_admin());

-- Payments are immutable (no UPDATE/DELETE via RLS)
-- Enforced by triggers, but RLS adds extra layer

-- ----------------------------------------------------------------------------
-- RLS Policies: withdrawals
-- ----------------------------------------------------------------------------
-- Customers can read their own withdrawals
CREATE POLICY "Customers can read own withdrawals"
    ON withdrawals FOR SELECT
    USING (
        customer_id IN (
            SELECT id FROM customers WHERE profile_id = get_user_profile()
        ) OR
        is_staff()
    );

-- Customers can insert their own withdrawal requests
CREATE POLICY "Customers can request withdrawals"
    ON withdrawals FOR INSERT
    WITH CHECK (
        customer_id IN (
            SELECT id FROM customers WHERE profile_id = get_user_profile()
        )
    );

-- Staff can read assigned customer withdrawals
CREATE POLICY "Staff can read assigned customer withdrawals"
    ON withdrawals FOR SELECT
    USING (
        is_staff() AND (
            is_admin() OR
            is_staff_assigned_to_customer(customer_id)
        )
    );

-- Admin and staff can update withdrawal status
CREATE POLICY "Staff can update withdrawal status"
    ON withdrawals FOR UPDATE
    USING (is_staff())
    WITH CHECK (is_staff());

-- Admin can manage all withdrawals
CREATE POLICY "Admin can manage withdrawals"
    ON withdrawals FOR ALL
    USING (is_admin())
    WITH CHECK (is_admin());

-- ----------------------------------------------------------------------------
-- RLS Policies: market_rates
-- ----------------------------------------------------------------------------
-- Everyone can read market rates
CREATE POLICY "Everyone can read market rates"
    ON market_rates FOR SELECT
    USING (true);

-- Admin can manage market rates
CREATE POLICY "Admin can manage market rates"
    ON market_rates FOR ALL
    USING (is_admin())
    WITH CHECK (is_admin());

-- Explicit GRANT for market_rates (ensures authenticated users can read)
GRANT SELECT ON market_rates TO authenticated;

-- ----------------------------------------------------------------------------
-- RLS Policies: staff_assignments
-- ----------------------------------------------------------------------------
-- Staff can read their own assignments
CREATE POLICY "Staff can read own assignments"
    ON staff_assignments FOR SELECT
    USING (
        staff_id = get_user_profile() OR
        is_staff()
    );

-- Admin can manage all assignments
CREATE POLICY "Admin can manage assignments"
    ON staff_assignments FOR ALL
    USING (is_admin())
    WITH CHECK (is_admin());

-- ============================================================================
-- VIEWS FOR REPORTING
-- ============================================================================

-- ----------------------------------------------------------------------------
-- View: Active customer schemes with details
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW active_customer_schemes AS
SELECT
    us.id,
    us.customer_id,
    c.profile_id,
    p.name AS customer_name,
    p.phone AS customer_phone,
    us.scheme_id,
    s.name AS scheme_name,
    s.asset_type,
    us.status,
    us.payment_frequency,
    us.min_amount,
    us.max_amount,
    us.total_amount_paid,
    us.payments_made,
    us.payments_missed,
    us.accumulated_grams,
    us.enrollment_date,
    us.maturity_date
FROM user_schemes us
JOIN customers c ON c.id = us.customer_id
JOIN profiles p ON p.id = c.profile_id
JOIN schemes s ON s.id = us.scheme_id
WHERE us.status = 'active';

-- ----------------------------------------------------------------------------
-- View: Today's collections by staff
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW today_collections AS
SELECT
    p.id AS payment_id,
    p.staff_id,
    sp.name AS staff_name,
    p.customer_id,
    cp.name AS customer_name,
    p.user_scheme_id,
    s.name AS scheme_name,
    p.amount,
    p.gst_amount,
    p.net_amount,
    p.payment_method,
    p.payment_date,
    p.payment_time,
    p.receipt_number,
    p.created_at
FROM payments p
JOIN profiles sp ON sp.id = p.staff_id
JOIN customers c ON c.id = p.customer_id
JOIN profiles cp ON cp.id = c.profile_id
JOIN user_schemes us ON us.id = p.user_scheme_id
JOIN schemes s ON s.id = us.scheme_id
WHERE p.payment_date = CURRENT_DATE
AND p.status = 'completed'
AND p.is_reversal = false;

-- ----------------------------------------------------------------------------
-- View: Staff daily statistics
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW staff_daily_stats AS
SELECT
    p.staff_id,
    sp.name AS staff_name,
    p.payment_date,
    COUNT(DISTINCT p.customer_id) AS customers_visited,
    COUNT(*) AS payments_count,
    SUM(p.amount) AS total_collected,
    SUM(p.gst_amount) AS total_gst,
    SUM(p.net_amount) AS total_net,
    SUM(p.metal_grams_added) AS total_grams_added,
    COUNT(CASE WHEN p.payment_method = 'cash' THEN 1 END) AS cash_count,
    COUNT(CASE WHEN p.payment_method = 'upi' THEN 1 END) AS upi_count
FROM payments p
JOIN profiles sp ON sp.id = p.staff_id
WHERE p.status = 'completed'
AND p.is_reversal = false
GROUP BY p.staff_id, sp.name, p.payment_date;

-- ============================================================================
-- INITIAL DATA (OPTIONAL - COMMENTED OUT)
-- ============================================================================

-- Uncomment and modify as needed for initial setup
-- Note: This should be run after creating admin user in Supabase Auth

/*
-- Example: Create admin profile (replace USER_ID with actual auth.users.id)
INSERT INTO profiles (user_id, role, phone, name, email, active)
VALUES (
    'USER_ID_HERE'::UUID,
    'admin',
    '+911234567890',
    'Admin User',
    'admin@slggolds.com',
    true
);
*/

-- ============================================================================
-- MIGRATION: Add staff_type column to staff_metadata (if not exists)
-- ============================================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'staff_metadata' AND column_name = 'staff_type'
    ) THEN
        ALTER TABLE staff_metadata 
        ADD COLUMN staff_type TEXT NOT NULL DEFAULT 'collection' 
        CHECK (staff_type IN ('collection', 'office'));
    END IF;
END $$;

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================

