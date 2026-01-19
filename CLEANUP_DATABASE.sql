-- ============================================================================
-- CLEANUP ALL OLD FUNCTIONS AND TRIGGERS
-- RUN THIS FIRST BEFORE ANY OTHER SQL FILES
-- ============================================================================

-- Step 1: Check what currently exists
SELECT 
    'EXISTING TRIGGERS ON PAYMENTS TABLE:' as info,
    trigger_name,
    action_statement as function_called
FROM information_schema.triggers
WHERE event_object_table = 'payments'
ORDER BY trigger_name;

SELECT 
    'EXISTING RECEIPT FUNCTIONS:' as info,
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name LIKE '%receipt%';

-- ============================================================================
-- Step 2: DROP ALL OLD TRIGGERS ON PAYMENTS TABLE
-- ============================================================================

-- Drop ALL triggers on payments (we'll recreate the correct ones)
DROP TRIGGER IF EXISTS trigger_update_user_scheme_totals ON payments CASCADE;
DROP TRIGGER IF EXISTS prevent_payment_update ON payments CASCADE;
DROP TRIGGER IF EXISTS prevent_payment_delete ON payments CASCADE;
DROP TRIGGER IF EXISTS generate_payment_receipt_number ON payments CASCADE;
DROP TRIGGER IF EXISTS generate_receipt_id_trigger ON payments CASCADE;
DROP TRIGGER IF EXISTS trigger_generate_receipt_id ON payments CASCADE;
DROP TRIGGER IF EXISTS trigger_payment_inserted ON payments CASCADE;

-- ============================================================================
-- Step 3: DROP ALL OLD RECEIPT FUNCTIONS
-- ============================================================================

-- Drop old receipt functions (both id and number versions)
DROP FUNCTION IF EXISTS generate_receipt_id() CASCADE;
DROP FUNCTION IF EXISTS generate_receipt_number() CASCADE;

-- ============================================================================
-- Step 4: DROP OLD PAYMENT-RELATED FUNCTIONS
-- ============================================================================

DROP FUNCTION IF EXISTS update_user_scheme_totals() CASCADE;
DROP FUNCTION IF EXISTS prevent_payment_modification() CASCADE;
DROP FUNCTION IF EXISTS notify_payment_inserted() CASCADE;

-- ============================================================================
-- VERIFICATION - Check everything is cleaned
-- ============================================================================

SELECT 
    'REMAINING TRIGGERS (should be empty):' as info,
    trigger_name
FROM information_schema.triggers
WHERE event_object_table = 'payments';

SELECT 
    'REMAINING RECEIPT FUNCTIONS (should be empty):' as info,
    routine_name
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name LIKE '%receipt%';

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Database cleaned successfully!';
    RAISE NOTICE '📋 Next steps:';
    RAISE NOTICE '   1. Run supabase_schema.sql';
    RAISE NOTICE '   2. Run realtime_setup.sql';
    RAISE NOTICE '   3. Run TEST_RLS_PAYMENT_INSERT.sql';
END $$;
