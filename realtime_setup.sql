-- SLG-GOLDS REALTIME PORTFOLIO SYNC
-- Supabase Realtime Channels Setup
-- Date: 2026-01-19
-- Enables live portfolio updates when staff records payments

-- ============================================================================
-- 1. ENABLE REALTIME FOR REQUIRED TABLES
-- ============================================================================

-- Remove tables from publication first (ignore errors if not present)
DO $$
BEGIN
    -- Try to drop tables from publication (no error if they don't exist)
    BEGIN
        ALTER PUBLICATION supabase_realtime DROP TABLE payments;
    EXCEPTION WHEN OTHERS THEN
        NULL; -- Ignore error if table not in publication
    END;
    
    BEGIN
        ALTER PUBLICATION supabase_realtime DROP TABLE user_schemes;
    EXCEPTION WHEN OTHERS THEN
        NULL;
    END;
    
    BEGIN
        ALTER PUBLICATION supabase_realtime DROP TABLE market_rates;
    EXCEPTION WHEN OTHERS THEN
        NULL;
    END;
END $$;

-- Enable realtime for payments table (staff payment inserts)
ALTER PUBLICATION supabase_realtime ADD TABLE payments;

-- Enable realtime for user_schemes table (portfolio updates)
ALTER PUBLICATION supabase_realtime ADD TABLE user_schemes;

-- Enable realtime for market_rates table (price updates)
ALTER PUBLICATION supabase_realtime ADD TABLE market_rates;

-- ============================================================================
-- 2. CREATE REALTIME CHANNELS FOR PORTFOLIO SYNC
-- ============================================================================

-- Channel for payment insertions (staff → customer sync)
-- This triggers when staff records a new payment
CREATE OR REPLACE FUNCTION notify_payment_inserted()
RETURNS TRIGGER AS $$
BEGIN
    -- Notify customer's portfolio update
    PERFORM pg_notify(
        'payment_inserted',
        json_build_object(
            'customer_id', NEW.customer_id,
            'user_scheme_id', NEW.user_scheme_id,
            'amount', NEW.amount,
            'net_amount', NEW.net_amount,
            'metal_grams_added', NEW.metal_grams_added,
            'payment_date', NEW.payment_date
        )::text
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Channel for user_scheme updates (portfolio totals)
CREATE OR REPLACE FUNCTION notify_portfolio_updated()
RETURNS TRIGGER AS $$
BEGIN
    -- Notify portfolio changes to customer
    PERFORM pg_notify(
        'portfolio_updated',
        json_build_object(
            'customer_id', NEW.customer_id,
            'user_scheme_id', NEW.id,
            'total_amount_paid', NEW.total_amount_paid,
            'accumulated_grams', NEW.accumulated_grams,
            'payments_made', NEW.payments_made
        )::text
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Channel for market rate updates (price changes)
CREATE OR REPLACE FUNCTION notify_market_rate_updated()
RETURNS TRIGGER AS $$
BEGIN
    -- Notify price changes to all users
    PERFORM pg_notify(
        'market_rate_updated',
        json_build_object(
            'asset_type', NEW.asset_type,
            'price_per_gram', NEW.price_per_gram,
            'change_percent', NEW.change_percent
        )::text
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 3. CREATE TRIGGERS FOR REALTIME NOTIFICATIONS
-- ============================================================================

-- Trigger for payment insertions
DROP TRIGGER IF EXISTS trigger_payment_inserted ON payments;
CREATE TRIGGER trigger_payment_inserted
    AFTER INSERT ON payments
    FOR EACH ROW
    WHEN (NEW.status = 'completed' AND NEW.is_reversal = false)
    EXECUTE FUNCTION notify_payment_inserted();

-- Trigger for portfolio updates
DROP TRIGGER IF EXISTS trigger_portfolio_updated ON user_schemes;
CREATE TRIGGER trigger_portfolio_updated
    AFTER UPDATE ON user_schemes
    FOR EACH ROW
    WHEN (
        OLD.total_amount_paid IS DISTINCT FROM NEW.total_amount_paid OR
        OLD.accumulated_grams IS DISTINCT FROM NEW.accumulated_grams OR
        OLD.payments_made IS DISTINCT FROM NEW.payments_made
    )
    EXECUTE FUNCTION notify_portfolio_updated();

-- Trigger for market rate updates
DROP TRIGGER IF EXISTS trigger_market_rate_updated ON market_rates;
CREATE TRIGGER trigger_market_rate_updated
    AFTER INSERT OR UPDATE ON market_rates
    FOR EACH ROW
    EXECUTE FUNCTION notify_market_rate_updated();

-- ============================================================================
-- 4. SETUP REALTIME POLICIES
-- ============================================================================

-- Allow authenticated users to receive realtime updates for their data
-- Customers can listen to their own portfolio updates
-- Staff can listen to assigned customer portfolio updates

-- Policy for payments realtime (customers see their payments, staff see assigned customer payments)
DROP POLICY IF EXISTS "Realtime payments access" ON payments;
CREATE POLICY "Realtime payments access"
    ON payments FOR SELECT
    TO authenticated
    USING (
        -- Customers can see their own payments
        customer_id IN (
            SELECT id FROM customers WHERE profile_id = get_user_profile()
        ) OR
        -- Staff can see payments for assigned customers
        is_staff() AND (
            is_admin() OR
            is_staff_assigned_to_customer(customer_id)
        )
    );

-- Policy for user_schemes realtime
DROP POLICY IF EXISTS "Realtime user_schemes access" ON user_schemes;
CREATE POLICY "Realtime user_schemes access"
    ON user_schemes FOR SELECT
    TO authenticated
    USING (
        -- Customers can see their own schemes
        customer_id IN (
            SELECT id FROM customers WHERE profile_id = get_user_profile()
        ) OR
        -- Staff can see assigned customer schemes
        is_staff() AND (
            is_admin() OR
            is_staff_assigned_to_customer(customer_id)
        )
    );

-- Policy for market_rates realtime (everyone can see)
DROP POLICY IF EXISTS "Realtime market_rates access" ON market_rates;
CREATE POLICY "Realtime market_rates access"
    ON market_rates FOR SELECT
    TO authenticated
    USING (true);

-- ============================================================================
-- 5. FLUTTER CLIENT REALTIME SUBSCRIPTION EXAMPLE
-- ============================================================================

/*
FLUTTER CODE FOR REALTIME SUBSCRIPTION:

// In Customer Dashboard - Listen for portfolio updates
class CustomerDashboard extends ConsumerStatefulWidget {
  @override
  void initState() {
    super.initState();
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    // Listen for portfolio updates
    Supabase.instance.client
        .channel('portfolio_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'user_schemes',
          callback: (payload) {
            // Update UI with new portfolio data
            ref.invalidate(customerProviders);
          },
        )
        .subscribe();

    // Listen for payment insertions
    Supabase.instance.client
        .channel('payment_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'payments',
          callback: (payload) {
            // Refresh payment history
            ref.invalidate(paymentProviders);
          },
        )
        .subscribe();

    // Listen for market rate changes
    Supabase.instance.client
        .channel('market_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'market_rates',
          callback: (payload) {
            // Update gold/silver prices
            ref.invalidate(marketRateProvider);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    Supabase.instance.client.channel('portfolio_updates').unsubscribe();
    Supabase.instance.client.channel('payment_updates').unsubscribe();
    Supabase.instance.client.channel('market_updates').unsubscribe();
    super.dispose();
  }
}
*/

-- ============================================================================
-- 6. TEST REALTIME FUNCTIONALITY
-- ============================================================================

-- Test function to simulate payment insertion and check notifications
CREATE OR REPLACE FUNCTION test_realtime_notifications()
RETURNS void AS $$
DECLARE
    test_customer_id UUID;
    test_scheme_id UUID;
    test_user_scheme_id UUID;
BEGIN
    -- Get a test customer and scheme
    SELECT c.id INTO test_customer_id
    FROM customers c LIMIT 1;

    SELECT id INTO test_scheme_id
    FROM schemes WHERE active = true LIMIT 1;

    -- Insert test user_scheme
    INSERT INTO user_schemes (customer_id, scheme_id, enrollment_date, status, payment_frequency, min_amount, max_amount)
    VALUES (test_customer_id, test_scheme_id, CURRENT_DATE, 'active', 'monthly', 1000, 5000)
    RETURNING id INTO test_user_scheme_id;

    -- Insert test payment (this should trigger realtime notification)
    INSERT INTO payments (
        user_scheme_id, customer_id, amount, gst_amount, net_amount,
        payment_method, payment_date, status, metal_rate_per_gram, metal_grams_added
    ) VALUES (
        test_user_scheme_id, test_customer_id, 1000, 30, 970,
        'cash', CURRENT_DATE, 'completed', 5000, 0.194
    );

    RAISE NOTICE 'Test payment inserted. Check realtime notifications.';
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SETUP COMPLETE
-- ============================================================================

/*
EXECUTION ORDER:
1. Run this SQL in Supabase SQL Editor
2. Verify realtime is enabled in Supabase Dashboard > Database > Replication
3. Test with Flutter app using the subscription code above
4. Monitor realtime events in Supabase Dashboard > Logs > Realtime

EXPECTED BEHAVIOR:
- Staff records payment → Customer dashboard updates immediately
- Market rates change → All users see updated prices
- Portfolio totals update → Live synchronization
*/
