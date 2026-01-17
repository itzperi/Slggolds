-- Database Migration Bundle: Sprints 1-3
-- Notes:
-- - All migrations are idempotent (check existence before create/alter).
-- - Each migration includes rollback and validation queries.
-- - Wrap multi-step changes in transactions.
-- - Dates use ISO format placeholders; replace with actual execution date.
-- - Test on staging/sample data before production.

-------------------------------------------------------------------------------
-- Migration: v1.0.1 - Create routes table
-- Sprint: 1
-- Gap IDs: GAP-001, GAP-007, GAP-008, GAP-017, GAP-018, GAP-019, GAP-020
-- Date: 2026-01-13
-- Description: Create routes table with constraints, indexes, audit cols.
-------------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_name = 'routes' AND table_schema = 'public'
  ) THEN
    CREATE TABLE public.routes (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      route_name TEXT NOT NULL,
      description TEXT NULL,
      area_coverage TEXT NULL,
      is_active BOOLEAN NOT NULL DEFAULT TRUE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      created_by UUID NULL REFERENCES public.profiles(id),
      updated_by UUID NULL REFERENCES public.profiles(id)
    );
  END IF;
END $$;

-- Constraints (idempotent)
ALTER TABLE public.routes
  ADD CONSTRAINT IF NOT EXISTS routes_route_name_unique UNIQUE (route_name);
ALTER TABLE public.routes
  ADD CONSTRAINT IF NOT EXISTS routes_is_active_bool CHECK (is_active IN (TRUE, FALSE));
ALTER TABLE public.routes
  ADD CONSTRAINT IF NOT EXISTS routes_route_name_format CHECK (char_length(route_name) BETWEEN 2 AND 100);
ALTER TABLE public.routes
  ADD CONSTRAINT IF NOT EXISTS routes_description_length CHECK (description IS NULL OR char_length(description) <= 500);
ALTER TABLE public.routes
  ADD CONSTRAINT IF NOT EXISTS routes_area_coverage_format CHECK (area_coverage IS NULL OR char_length(area_coverage) > 0);

-- Indexes (idempotent)
CREATE INDEX IF NOT EXISTS idx_routes_route_name ON public.routes(route_name);
CREATE INDEX IF NOT EXISTS idx_routes_active ON public.routes(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_routes_created_at ON public.routes(created_at);

-- Trigger to maintain updated_at
CREATE OR REPLACE FUNCTION public.routes_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS trg_routes_set_updated_at ON public.routes;
CREATE TRIGGER trg_routes_set_updated_at
  BEFORE UPDATE ON public.routes
  FOR EACH ROW EXECUTE FUNCTION public.routes_set_updated_at();

-- Rollback
-- BEGIN;
--   DROP TRIGGER IF EXISTS trg_routes_set_updated_at ON public.routes;
--   DROP FUNCTION IF EXISTS public.routes_set_updated_at();
--   DROP TABLE IF EXISTS public.routes CASCADE;
-- COMMIT;

-- Validation
-- SELECT * FROM public.routes LIMIT 5;
-- \d+ public.routes;

-------------------------------------------------------------------------------
-- Migration: v1.0.2 - Add route_id to staff_assignments
-- Sprint: 1
-- Gap IDs: GAP-002, GAP-009, GAP-021
-- Date: 2026-01-13
-- Description: Add nullable route_id FK and index for route-based assignments.
-------------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='staff_assignments' AND column_name='route_id'
  ) THEN
    ALTER TABLE public.staff_assignments ADD COLUMN route_id UUID NULL;
  END IF;
END $$;

ALTER TABLE public.staff_assignments
  ADD CONSTRAINT IF NOT EXISTS staff_assignments_route_fk
  FOREIGN KEY (route_id) REFERENCES public.routes(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_staff_assignments_route_active
  ON public.staff_assignments(route_id, is_active) WHERE is_active = TRUE;

-- Rollback
-- BEGIN;
--   ALTER TABLE public.staff_assignments DROP CONSTRAINT IF EXISTS staff_assignments_route_fk;
--   ALTER TABLE public.staff_assignments DROP COLUMN IF EXISTS route_id;
--   DROP INDEX IF EXISTS idx_staff_assignments_route_active;
-- COMMIT;

-- Validation
-- SELECT route_id FROM public.staff_assignments LIMIT 5;
-- \d public.staff_assignments;

-------------------------------------------------------------------------------
-- Migration: v1.0.3 - Add route_id to customers
-- Sprint: 1
-- Gap IDs: GAP-003, GAP-010, GAP-022
-- Date: 2026-01-13
-- Description: Add nullable route_id FK and index for route-based customer queries.
-------------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='customers' AND column_name='route_id'
  ) THEN
    ALTER TABLE public.customers ADD COLUMN route_id UUID NULL;
  END IF;
END $$;

ALTER TABLE public.customers
  ADD CONSTRAINT IF NOT EXISTS customers_route_fk
  FOREIGN KEY (route_id) REFERENCES public.routes(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_customers_route_active
  ON public.customers(route_id) WHERE route_id IS NOT NULL;

-- Rollback
-- BEGIN;
--   ALTER TABLE public.customers DROP CONSTRAINT IF EXISTS customers_route_fk;
--   ALTER TABLE public.customers DROP COLUMN IF EXISTS route_id;
--   DROP INDEX IF EXISTS idx_customers_route_active;
-- COMMIT;

-- Validation
-- SELECT route_id FROM public.customers LIMIT 5;
-- \d public.customers;

-------------------------------------------------------------------------------
-- Migration: v1.0.3.5 - Helper function for staff_type
-- Sprint: 1
-- Gap IDs: GAP-023, GAP-024, GAP-025, GAP-026, GAP-027, GAP-042
-- Date: 2026-01-13
-- Description: Create helper function to get staff_type for RLS policies.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_staff_type()
RETURNS TEXT AS $$
  SELECT sm.staff_type
  FROM public.staff_metadata sm
  JOIN public.profiles p ON p.id = sm.profile_id
  WHERE p.user_id = auth.uid()
  LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Rollback
-- BEGIN;
--   DROP FUNCTION IF EXISTS public.get_staff_type();
-- COMMIT;

-- Validation
-- SELECT public.get_staff_type();

-------------------------------------------------------------------------------
-- Migration: v1.0.4 - RLS policies for routes
-- Sprint: 1
-- Gap IDs: GAP-042
-- Date: 2026-01-13
-- Description: Add RLS policies for routes (admin, office staff, staff read).
-------------------------------------------------------------------------------
ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;

-- Admin full access
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='routes' AND policyname='Admin can manage routes'
  ) THEN
    CREATE POLICY "Admin can manage routes" ON public.routes
      FOR ALL USING (is_admin()) WITH CHECK (is_admin());
  END IF;
END $$;

-- Office staff manage
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='routes' AND policyname='Office staff can manage routes'
  ) THEN
    CREATE POLICY "Office staff can manage routes" ON public.routes
      FOR ALL USING (is_staff() AND public.get_staff_type() = 'office')
      WITH CHECK (is_staff() AND public.get_staff_type() = 'office');
  END IF;
END $$;

-- Staff read
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='routes' AND policyname='Staff can read routes'
  ) THEN
    CREATE POLICY "Staff can read routes" ON public.routes
      FOR SELECT USING (is_staff());
  END IF;
END $$;

-- Rollback
-- BEGIN;
--   DROP POLICY IF EXISTS "Admin can manage routes" ON public.routes;
--   DROP POLICY IF EXISTS "Office staff can manage routes" ON public.routes;
--   DROP POLICY IF EXISTS "Staff can read routes" ON public.routes;
--   ALTER TABLE public.routes DISABLE ROW LEVEL SECURITY;
-- COMMIT;

-- Validation
-- SELECT polname, cmd FROM pg_policies WHERE tablename='routes';

-------------------------------------------------------------------------------
-- Migration: v1.0.5 - Fix customer self-enrollment policy
-- Sprint: 1
-- Gap IDs: GAP-028, GAP-076
-- Date: 2026-01-13
-- Description: Remove customer self-enrollment; allow only office staff/admin.
-------------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='user_schemes'
      AND polname='Customers can enroll in schemes'
  ) THEN
    DROP POLICY "Customers can enroll in schemes" ON public.user_schemes;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='user_schemes'
      AND polname='Office staff can enroll customers'
  ) THEN
    CREATE POLICY "Office staff can enroll customers" ON public.user_schemes
      FOR INSERT USING (is_staff() AND public.get_staff_type() = 'office')
      WITH CHECK (is_staff() AND public.get_staff_type() = 'office');
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='user_schemes'
      AND polname='Admin can enroll customers'
  ) THEN
    CREATE POLICY "Admin can enroll customers" ON public.user_schemes
      FOR INSERT USING (is_admin()) WITH CHECK (is_admin());
  END IF;
END $$;

-- Rollback
-- BEGIN;
--   DROP POLICY IF EXISTS "Office staff can enroll customers" ON public.user_schemes;
--   DROP POLICY IF EXISTS "Admin can enroll customers" ON public.user_schemes;
--   -- Optionally restore old policy name if needed
-- COMMIT;

-- Validation
-- SELECT polname, cmd FROM pg_policies WHERE tablename='user_schemes';

-------------------------------------------------------------------------------
-- Migration: v1.0.6 - INSERT policies for office staff
-- Sprint: 1
-- Gap IDs: GAP-023, GAP-024, GAP-025, GAP-026
-- Date: 2026-01-13
-- Description: Add INSERT policies for office staff on customers, user_schemes, payments, staff_assignments.
-------------------------------------------------------------------------------
-- Customers INSERT
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='customers'
      AND polname='Office staff can create customers'
  ) THEN
    CREATE POLICY "Office staff can create customers" ON public.customers
      FOR INSERT WITH CHECK (is_staff() AND public.get_staff_type() = 'office');
  END IF;
END $$;

-- User schemes INSERT (already handled in v1.0.5 but keep idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='user_schemes'
      AND polname='Office staff can enroll customers'
  ) THEN
    CREATE POLICY "Office staff can enroll customers" ON public.user_schemes
      FOR INSERT USING (is_staff() AND public.get_staff_type() = 'office')
      WITH CHECK (is_staff() AND public.get_staff_type() = 'office');
  END IF;
END $$;

-- Payments INSERT for office collections
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='payments'
      AND polname='Office staff can insert office payments'
  ) THEN
    CREATE POLICY "Office staff can insert office payments" ON public.payments
      FOR INSERT WITH CHECK (is_staff() AND public.get_staff_type() = 'office' AND staff_id IS NULL);
  END IF;
END $$;

-- Staff assignments INSERT/UPDATE
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='staff_assignments'
      AND polname='Office staff can manage assignments'
  ) THEN
    CREATE POLICY "Office staff can manage assignments" ON public.staff_assignments
      FOR ALL USING (is_staff() AND public.get_staff_type() = 'office')
      WITH CHECK (is_staff() AND public.get_staff_type() = 'office');
  END IF;
END $$;

-- Rollback
-- BEGIN;
--   DROP POLICY IF EXISTS "Office staff can create customers" ON public.customers;
--   DROP POLICY IF EXISTS "Office staff can enroll customers" ON public.user_schemes;
--   DROP POLICY IF EXISTS "Office staff can insert office payments" ON public.payments;
--   DROP POLICY IF EXISTS "Office staff can manage assignments" ON public.staff_assignments;
-- COMMIT;

-- Validation
-- SELECT polname, cmd FROM pg_policies WHERE tablename IN ('customers','user_schemes','payments','staff_assignments');

-------------------------------------------------------------------------------
-- Migration: v1.0.7 - Profiles UPDATE for office staff
-- Sprint: 1
-- Gap IDs: GAP-027
-- Date: 2026-01-13
-- Description: Allow office staff to update customer profiles (limited fields enforced at app layer).
-------------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='profiles'
      AND polname='Office staff can update customer profiles'
  ) THEN
    CREATE POLICY "Office staff can update customer profiles" ON public.profiles
      FOR UPDATE USING (is_staff() AND public.get_staff_type() = 'office')
      WITH CHECK (is_staff() AND public.get_staff_type() = 'office');
  END IF;
END $$;

-- Rollback
-- BEGIN;
--   DROP POLICY IF EXISTS "Office staff can update customer profiles" ON public.profiles;
-- COMMIT;

-- Validation
-- SELECT polname, cmd FROM pg_policies WHERE tablename='profiles';

-------------------------------------------------------------------------------
-- Migration: v1.0.8 - Withdrawal UPDATE policy fix
-- Sprint: 1
-- Gap IDs: GAP-029
-- Date: 2026-01-13
-- Description: Restrict withdrawal UPDATE to assigned staff or admin.
-------------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='withdrawals'
      AND polname='Staff can update withdrawal status'
  ) THEN
    DROP POLICY "Staff can update withdrawal status" ON public.withdrawals;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='withdrawals'
      AND polname='Assigned staff can update withdrawal status'
  ) THEN
    CREATE POLICY "Assigned staff can update withdrawal status" ON public.withdrawals
      FOR UPDATE USING (
        is_staff() AND (
          is_admin()
          OR is_current_staff_assigned_to_customer(customer_id)
        )
      )
      WITH CHECK (
        is_staff() AND (
          is_admin()
          OR is_current_staff_assigned_to_customer(customer_id)
        )
      );
  END IF;
END $$;

-- Rollback
-- BEGIN;
--   DROP POLICY IF EXISTS "Assigned staff can update withdrawal status" ON public.withdrawals;
--   -- Optionally restore old policy if desired
-- COMMIT;

-- Validation
-- SELECT polname, cmd FROM pg_policies WHERE tablename='withdrawals';

-------------------------------------------------------------------------------
-- Migration: v1.0.9 - Customers SELECT policy fix
-- Sprint: 1
-- Gap IDs: GAP-031
-- Date: 2026-01-13
-- Description: Ensure collection staff only see assigned customers.
-------------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='customers'
      AND polname='Customers policy all staff read'
  ) THEN
    DROP POLICY "Customers policy all staff read" ON public.customers;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='customers'
      AND polname='Staff can read assigned customers'
  ) THEN
    CREATE POLICY "Staff can read assigned customers" ON public.customers
      FOR SELECT USING (
        profile_id = get_user_profile()
        OR (is_staff() AND (is_admin() OR is_staff_assigned_to_customer(id)))
      );
  END IF;
END $$;

-- Rollback
-- BEGIN;
--   DROP POLICY IF EXISTS "Staff can read assigned customers" ON public.customers;
--   -- Optionally recreate previous policy if needed
-- COMMIT;

-- Validation
-- SELECT polname, cmd FROM pg_policies WHERE tablename='customers';

-------------------------------------------------------------------------------
-- Migration: v1.0.10 - Payments SELECT policy fix
-- Sprint: 1
-- Gap IDs: GAP-032
-- Date: 2026-01-13
-- Description: Ensure collection staff only see payments for assigned customers.
-------------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='payments'
      AND polname='Staff can read all payments'
  ) THEN
    DROP POLICY "Staff can read all payments" ON public.payments;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='payments'
      AND polname='Staff can read assigned payments'
  ) THEN
    CREATE POLICY "Staff can read assigned payments" ON public.payments
      FOR SELECT USING (
        customer_id IN (SELECT id FROM customers WHERE profile_id = get_user_profile())
        OR (is_staff() AND (is_admin() OR is_staff_assigned_to_customer(customer_id)))
      );
  END IF;
END $$;

-- Rollback
-- BEGIN;
--   DROP POLICY IF EXISTS "Staff can read assigned payments" ON public.payments;
-- COMMIT;

-- Validation
-- SELECT polname, cmd FROM pg_policies WHERE tablename='payments';

-------------------------------------------------------------------------------
-- Migration: v1.0.11 - Mobile app access database-level check
-- Sprint: 1
-- Gap IDs: GAP-033
-- Date: 2026-01-13
-- Description: Create RPC function to check mobile app access (prevents admin/office staff).
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.check_mobile_app_access()
RETURNS BOOLEAN AS $$
DECLARE
  user_role_val user_role;
  staff_type_val TEXT;
BEGIN
  -- Get user role
  SELECT role INTO user_role_val FROM public.profiles WHERE user_id = auth.uid();
  
  -- Admin cannot access mobile app
  IF user_role_val = 'admin' THEN
    RAISE EXCEPTION 'This account does not have mobile app access.';
  END IF;
  
  -- Customers can always access
  IF user_role_val = 'customer' THEN
    RETURN TRUE;
  END IF;
  
  -- Staff must be collection type
  IF user_role_val = 'staff' THEN
    SELECT sm.staff_type INTO staff_type_val
    FROM public.staff_metadata sm
    JOIN public.profiles p ON p.id = sm.profile_id
    WHERE p.user_id = auth.uid()
    LIMIT 1;
    
    IF staff_type_val IS NULL OR staff_type_val != 'collection' THEN
      RAISE EXCEPTION 'This account does not have mobile app access.';
    END IF;
    
    RETURN TRUE;
  END IF;
  
  -- Unknown role
  RAISE EXCEPTION 'This account does not have mobile app access.';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Rollback
-- BEGIN;
--   DROP FUNCTION IF EXISTS public.check_mobile_app_access();
-- COMMIT;

-- Validation
-- SELECT public.check_mobile_app_access();

-------------------------------------------------------------------------------
-- Migration: v1.1.1 - Add sync_status to payments
-- Sprint: 2
-- Gap IDs: GAP-016
-- Date: 2026-01-13
-- Description: Add sync_status enum for offline sync tracking.
-------------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type WHERE typname = 'payment_sync_status'
  ) THEN
    CREATE TYPE payment_sync_status AS ENUM ('pending','synced','conflict','resolved');
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='payments' AND column_name='sync_status'
  ) THEN
    ALTER TABLE public.payments ADD COLUMN sync_status payment_sync_status NOT NULL DEFAULT 'pending';
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_payments_sync_status ON public.payments(sync_status);

-- Rollback
-- BEGIN;
--   ALTER TABLE public.payments DROP COLUMN IF EXISTS sync_status;
--   DROP INDEX IF EXISTS idx_payments_sync_status;
--   DROP TYPE IF EXISTS payment_sync_status;
-- COMMIT;

-- Validation
-- SELECT sync_status, count(*) FROM public.payments GROUP BY sync_status;

-------------------------------------------------------------------------------
-- Migration: v1.1.2 - Reversal validation constraints
-- Sprint: 2
-- Gap IDs: GAP-070
-- Date: 2026-01-13
-- Description: Validate reversals reference valid original payments.
-------------------------------------------------------------------------------
DO $$
BEGIN
  -- Ensure constraint only added once
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname='payments_reversal_valid'
  ) THEN
    ALTER TABLE public.payments
      ADD CONSTRAINT payments_reversal_valid CHECK (
        NOT is_reversal
        OR (
          reverses_payment_id IS NOT NULL
          AND reverses_payment_id <> id
          AND reverses_payment_id IN (SELECT id FROM public.payments WHERE is_reversal = FALSE)
          AND reverses_payment_id NOT IN (
            SELECT reverses_payment_id FROM public.payments
            WHERE reverses_payment_id IS NOT NULL AND is_reversal = TRUE
          )
        )
      );
  END IF;
END $$;

-- Rollback
-- BEGIN;
--   ALTER TABLE public.payments DROP CONSTRAINT IF EXISTS payments_reversal_valid;
-- COMMIT;

-- Validation
-- SELECT id, is_reversal, reverses_payment_id FROM public.payments WHERE is_reversal = TRUE LIMIT 5;

-------------------------------------------------------------------------------
-- Migration: v1.1.3 - Prevent role change after creation
-- Sprint: 2
-- Gap IDs: GAP-039
-- Date: 2026-01-13
-- Description: Trigger to block role changes except by admin.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.prevent_role_change()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.role IS DISTINCT FROM OLD.role THEN
    IF NOT is_admin() THEN
      RAISE EXCEPTION 'Role change not allowed';
    END IF;
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_prevent_role_change ON public.profiles;
CREATE TRIGGER trg_prevent_role_change
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.prevent_role_change();

-- Rollback
-- BEGIN;
--   DROP TRIGGER IF EXISTS trg_prevent_role_change ON public.profiles;
--   DROP FUNCTION IF EXISTS public.prevent_role_change;
-- COMMIT;

-- Validation
-- -- Attempt an update as non-admin should fail; as admin should pass.

-------------------------------------------------------------------------------
-- Migration: v1.1.4 - Prevent staff_type change after creation
-- Sprint: 2
-- Gap IDs: GAP-040
-- Date: 2026-01-13
-- Description: Trigger to block staff_type changes except by admin.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.prevent_staff_type_change()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.staff_type IS DISTINCT FROM OLD.staff_type THEN
    IF NOT is_admin() THEN
      RAISE EXCEPTION 'Staff type change not allowed';
    END IF;
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_prevent_staff_type_change ON public.staff_metadata;
CREATE TRIGGER trg_prevent_staff_type_change
  BEFORE UPDATE ON public.staff_metadata
  FOR EACH ROW EXECUTE FUNCTION public.prevent_staff_type_change();

-- Rollback
-- BEGIN;
--   DROP TRIGGER IF EXISTS trg_prevent_staff_type_change ON public.staff_metadata;
--   DROP FUNCTION IF EXISTS public.prevent_staff_type_change;
-- COMMIT;

-- Validation
-- -- Attempt an update as non-admin should fail; as admin should pass.

-------------------------------------------------------------------------------
-- Migration: v1.1.5 - Metal grams validation
-- Sprint: 2
-- Gap IDs: GAP-063
-- Date: 2026-01-13
-- Description: Ensure metal_grams_added matches net_amount / metal_rate_per_gram (tolerance).
-------------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname='payments_metal_grams_consistency'
  ) THEN
    ALTER TABLE public.payments
      ADD CONSTRAINT payments_metal_grams_consistency
      CHECK (ABS(metal_grams_added - (net_amount / NULLIF(metal_rate_per_gram,0))) < 0.01);
  END IF;
END $$;

-- Rollback
-- BEGIN;
--   ALTER TABLE public.payments DROP CONSTRAINT IF EXISTS payments_metal_grams_consistency;
-- COMMIT;

-- Validation
-- SELECT id FROM public.payments WHERE ABS(metal_grams_added - (net_amount / NULLIF(metal_rate_per_gram,0))) >= 0.01 LIMIT 5;

-------------------------------------------------------------------------------
-- Migration: v1.2.1 - Reconciliation views
-- Sprint: 3
-- Gap IDs: GAP-064, GAP-065, GAP-066, GAP-067
-- Date: 2026-01-13
-- Description: Create reconciliation views for totals, grams, counts, staff daily collections.
-------------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.reconcile_user_schemes_amounts AS
SELECT us.id AS user_scheme_id,
       us.total_amount_paid AS stored_total,
       COALESCE(SUM(p.net_amount),0) AS calc_total,
       COALESCE(SUM(p.net_amount),0) - us.total_amount_paid AS delta
FROM public.user_schemes us
LEFT JOIN public.payments p ON p.user_scheme_id = us.id AND p.is_reversal = FALSE AND p.status = 'completed'
GROUP BY us.id, us.total_amount_paid;

CREATE OR REPLACE VIEW public.reconcile_user_schemes_grams AS
SELECT us.id AS user_scheme_id,
       us.accumulated_grams AS stored_grams,
       COALESCE(SUM(p.metal_grams_added),0) AS calc_grams,
       COALESCE(SUM(p.metal_grams_added),0) - us.accumulated_grams AS delta
FROM public.user_schemes us
LEFT JOIN public.payments p ON p.user_scheme_id = us.id AND p.is_reversal = FALSE AND p.status = 'completed'
GROUP BY us.id, us.accumulated_grams;

CREATE OR REPLACE VIEW public.reconcile_user_schemes_payments AS
SELECT us.id AS user_scheme_id,
       us.payments_made AS stored_count,
       COALESCE(COUNT(p.id),0) AS calc_count,
       COALESCE(COUNT(p.id),0) - us.payments_made AS delta
FROM public.user_schemes us
LEFT JOIN public.payments p ON p.user_scheme_id = us.id AND p.is_reversal = FALSE AND p.status = 'completed'
GROUP BY us.id, us.payments_made;

CREATE OR REPLACE VIEW public.reconcile_staff_daily_collections AS
SELECT s.id AS staff_id,
       p.payment_date,
       COALESCE(SUM(p.net_amount),0) AS calc_total
FROM public.payments p
LEFT JOIN public.staff_assignments sa ON sa.customer_id = p.customer_id AND sa.is_active = TRUE
LEFT JOIN public.profiles s ON s.id = sa.staff_id
WHERE p.is_reversal = FALSE AND p.status = 'completed'
GROUP BY s.id, p.payment_date;

-- Rollback
-- BEGIN;
--   DROP VIEW IF EXISTS public.reconcile_user_schemes_amounts;
--   DROP VIEW IF EXISTS public.reconcile_user_schemes_grams;
--   DROP VIEW IF EXISTS public.reconcile_user_schemes_payments;
--   DROP VIEW IF EXISTS public.reconcile_staff_daily_collections;
-- COMMIT;

-- Validation
-- SELECT * FROM public.reconcile_user_schemes_amounts LIMIT 5;
-- SELECT * FROM public.reconcile_user_schemes_grams LIMIT 5;
-- SELECT * FROM public.reconcile_user_schemes_payments LIMIT 5;
-- SELECT * FROM public.reconcile_staff_daily_collections LIMIT 5;

-------------------------------------------------------------------------------
-- Migration: v1.2.2 - Trigger fix to use payment rate (not current rate)
-- Sprint: 3
-- Gap IDs: GAP-057, GAP-058, GAP-073, GAP-085
-- Date: 2026-01-13
-- Description: Ensure trigger uses payment-time rate and does not recalc with current rates.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_user_scheme_totals()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  payment_rate NUMERIC;
BEGIN
  payment_rate := NEW.metal_rate_per_gram;

  IF NEW.metal_grams_added = 0 AND NEW.net_amount > 0 AND payment_rate IS NOT NULL AND payment_rate > 0 THEN
    NEW.metal_grams_added := NEW.net_amount / payment_rate;
  END IF;

  IF TG_OP = 'INSERT' THEN
    UPDATE public.user_schemes
    SET total_amount_paid = total_amount_paid + NEW.net_amount,
        accumulated_grams = accumulated_grams + NEW.metal_grams_added,
        payments_made = payments_made + 1
    WHERE id = NEW.user_scheme_id;
  END IF;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_update_user_scheme_totals ON public.payments;
CREATE TRIGGER trg_update_user_scheme_totals
  BEFORE INSERT ON public.payments
  FOR EACH ROW EXECUTE FUNCTION public.update_user_scheme_totals();

-- Rollback
-- BEGIN;
--   DROP TRIGGER IF EXISTS trg_update_user_scheme_totals ON public.payments;
--   -- Optionally restore previous function definition if backed up separately
-- COMMIT;

-- Validation
-- INSERT INTO public.payments (id, user_scheme_id, amount, gst_amount, net_amount, metal_rate_per_gram, metal_grams_added, is_reversal, status)
-- VALUES (gen_random_uuid(), (SELECT id FROM public.user_schemes LIMIT 1), 100, 3, 97, 6500, 0, FALSE, 'completed')
-- RETURNING metal_grams_added;

-------------------------------------------------------------------------------
-- Migration: v1.2.3 - Rate validation constraints
-- Sprint: 3
-- Gap IDs: GAP-059, GAP-071, GAP-072
-- Date: 2026-01-13
-- Description: Validate payment rate matches market rate for payment date (within tolerance).
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.validate_payment_rate()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  expected_rate NUMERIC;
BEGIN
  SELECT price_per_gram INTO expected_rate
  FROM public.market_rates
  WHERE asset_type = NEW.metal_type
    AND rate_date <= COALESCE(NEW.payment_date::date, CURRENT_DATE)
  ORDER BY rate_date DESC
  LIMIT 1;

  IF expected_rate IS NULL THEN
    RAISE EXCEPTION 'No market rate available for payment date';
  END IF;

  IF ABS(NEW.metal_rate_per_gram - expected_rate) / expected_rate > 0.01 THEN
    RAISE EXCEPTION 'Payment rate %. Rate on date % is %', NEW.metal_rate_per_gram, NEW.payment_date, expected_rate;
  END IF;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_validate_payment_rate ON public.payments;
CREATE TRIGGER trg_validate_payment_rate
  BEFORE INSERT ON public.payments
  FOR EACH ROW EXECUTE FUNCTION public.validate_payment_rate();

-- Rollback
-- BEGIN;
--   DROP TRIGGER IF EXISTS trg_validate_payment_rate ON public.payments;
--   DROP FUNCTION IF EXISTS public.validate_payment_rate;
-- COMMIT;

-- Validation
-- INSERT INTO public.payments (id, user_scheme_id, amount, gst_amount, net_amount, metal_rate_per_gram, metal_grams_added, is_reversal, status, payment_date, metal_type)
-- VALUES (gen_random_uuid(), (SELECT id FROM public.user_schemes LIMIT 1), 100, 3, 97, 6500, 0.0149, FALSE, 'completed', CURRENT_DATE, 'gold');

