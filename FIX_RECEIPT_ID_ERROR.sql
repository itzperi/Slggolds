-- FIX FOR RECEIPT_ID ERROR
-- This SQL script fixes the "record NEW has no field receipt_id" error
-- The old generate_receipt_id() function needs to be dropped

-- ============================================================================
-- DROP OLD RECEIPT FUNCTIONS
-- ============================================================================

-- Drop any old generate_receipt_id function (if it exists)
DROP FUNCTION IF EXISTS generate_receipt_id() CASCADE;

-- Drop trigger that might reference the old function
DROP TRIGGER IF EXISTS generate_payment_receipt_id ON payments CASCADE;
DROP TRIGGER IF EXISTS generate_receipt_id_trigger ON payments CASCADE;
DROP TRIGGER IF EXISTS trigger_generate_receipt_id ON payments CASCADE;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- The correct function is generate_receipt_number() in supabase_schema.sql
-- Verify it exists:
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name LIKE '%receipt%';

-- Verify the trigger exists:
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'payments'
AND trigger_name LIKE '%receipt%';

-- ============================================================================
-- INSTRUCTIONS
-- ============================================================================

/*
RUN THIS FILE FIRST, then run:
1. supabase_schema.sql (to create the correct generate_receipt_number function)
2. TEST_RLS_PAYMENT_INSERT.sql (should now work)

The error occurred because an old generate_receipt_id() function existed in your
database that referenced the field 'receipt_id', but the actual column name is
'receipt_number'.
*/
