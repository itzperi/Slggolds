-- ============================================================================
-- STAFF DASHBOARD RPCs
-- ============================================================================
-- Functions to efficiently load staff dashboard data in a single call

-- ----------------------------------------------------------------------------
-- Function: get_staff_dashboard(staff_id)
-- ----------------------------------------------------------------------------
-- Aggregates all high-level metrics for the staff dashboard
-- Returns specific metrics: target_progress, customers_count, overdue_count, etc.
DROP FUNCTION IF EXISTS get_staff_dashboard(UUID);
CREATE OR REPLACE FUNCTION get_staff_dashboard(staff_id_param UUID)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
    target_amount DECIMAL(12, 2);
    collected_today DECIMAL(12, 2);
    assigned_count INTEGER;
    visited_today INTEGER;
    yesterday_collected DECIMAL(12, 2);
BEGIN
    -- 1. Get Daily Target from Metadata
    SELECT daily_target_amount 
    INTO target_amount 
    FROM staff_metadata 
    WHERE profile_id = staff_id_param;

    -- 2. Get Collected Today (sum of payments made by this staff today)
    SELECT COALESCE(SUM(amount), 0)
    INTO collected_today
    FROM payments
    WHERE staff_id = staff_id_param 
    AND payment_date = CURRENT_DATE
    AND status = 'completed'
    AND is_reversal = false;

    -- 3. Get Yesterday's Collection
    SELECT COALESCE(SUM(amount), 0)
    INTO yesterday_collected
    FROM payments
    WHERE staff_id = staff_id_param 
    AND payment_date = CURRENT_DATE - 1
    AND status = 'completed'
    AND is_reversal = false;

    -- 4. Get Assigned Customer Count
    SELECT COUNT(*)
    INTO assigned_count
    FROM staff_assignments
    WHERE staff_id = staff_id_param
    AND is_active = true;

    -- 5. Get Visited Today (Unique customers paid today)
    SELECT COUNT(DISTINCT customer_id)
    INTO visited_today
    FROM payments
    WHERE staff_id = staff_id_param
    AND payment_date = CURRENT_DATE;

    -- Construct JSON response
    result := jsonb_build_object(
        'daily_target', COALESCE(target_amount, 0),
        'collected_today', collected_today,
        'yesterday_collection', yesterday_collected,
        'achievement_pct', CASE WHEN COALESCE(target_amount, 0) > 0 THEN (collected_today / target_amount) * 100 ELSE 0 END,
        'assigned_customers_count', assigned_count,
        'visited_today', visited_today,
        'is_empty_state', (assigned_count = 0) -- Flag for UI to show empty state
    );

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- Function: get_assigned_customers(staff_id, filter)
-- ----------------------------------------------------------------------------
-- Fetch assigned customers list with their status (due/overdue)
DROP FUNCTION IF EXISTS get_assigned_customers(UUID, TEXT);
CREATE OR REPLACE FUNCTION get_assigned_customers(staff_id_param UUID, filter_type TEXT DEFAULT 'all')
RETURNS TABLE (
    customer_id UUID,
    name TEXT,
    phone TEXT,
    address TEXT,
    status TEXT, -- 'due', 'overdue', 'paid'
    last_payment_date DATE,
    next_due_date DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id AS customer_id,
        p.name,
        p.phone,
        c.address,
        'due' AS status, -- Simplified for now; logic to be refined with Schemes
        MAX(pay.payment_date) AS last_payment_date,
        CURRENT_DATE AS next_due_date -- Placeholder
    FROM staff_assignments sa
    JOIN customers c ON c.id = sa.customer_id
    JOIN profiles p ON p.id = c.profile_id
    LEFT JOIN payments pay ON pay.customer_id = c.id
    WHERE sa.staff_id = staff_id_param
    AND sa.is_active = true
    GROUP BY c.id, p.name, p.phone, c.address;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
