# Sprint Plan - Phase 1 MVP Gap Closure

**Document Version:** 1.0  
**Date:** 2024  
**Total Gaps:** 89 explicitly numbered gaps + 15 additional items = 104 total gaps  
**Sprint Duration:** 2 weeks per sprint  
**Sprint Capacity:** 40 story points per sprint  
**Total Duration:** 20 weeks (10 sprints)

---

## Executive Summary

This sprint plan addresses all 104 gaps identified in the PDR vs Implementation Gap Audit. The plan is organized into 10 two-week sprints, prioritizing security and financial integrity gaps first, followed by database foundation, user flows, and architectural improvements.

**Key Priorities:**
- **P0 (Blocker):** Security violations, financial integrity risks, blocking dependencies
- **P1 (Critical):** Core MVP user flows, database schema foundation
- **P2 (High):** Data integrity, user experience improvements
- **P3 (Medium):** Architecture cleanup, code quality
- **P4 (Low):** Technical debt, nice-to-have improvements

**Critical Success Factors:**
- Zero security vulnerabilities in production
- All financial calculations verified and immutable
- Complete database schema with proper RLS policies
- All core user flows functional
- Website implementation for office staff and admin

---

## Sprint Overview Table

| Sprint | Weeks | Focus Area | Story Points | Key Deliverables |
|--------|-------|------------|--------------|------------------|
| Sprint 1 | 1-2 | Foundation & Security | 38 | Routes table, RLS policies, security fixes |
| Sprint 2 | 3-4 | Database Completion & Offline | 40 | Schema completion, offline infrastructure |
| Sprint 3 | 5-6 | Financial Integrity & Rates | 35 | Trigger fixes, rate validation, reconciliation |
| Sprint 4 | 7-8 | Customer Flows | 40 | Payment schedule, portfolio, profile, withdrawal |
| Sprint 5-6 | 9-12 | Website Foundation | 80 | Next.js setup, office staff flows |
| Sprint 7-8 | 13-16 | Admin Dashboard & Rates | 75 | Admin dashboard, market rates management |
| Sprint 9 | 17-18 | Architecture Cleanup | 30 | Navigation fixes, state management, views |
| Sprint 10 | 19-20 | Testing & Polish | 25 | Integration tests, security audit, docs |

**Total Story Points:** 363 points across 10 sprints

---

## Detailed Sprint Plans

### SPRINT 1: Foundation & Security (Weeks 1-2)
**Story Points:** 38/40  
**Priority Focus:** P0 Security Gaps

#### GAP-001: Routes Table Creation (P0, 5 pts)
- **Dependencies:** None (foundational)
- **Acceptance Criteria:**
  - `routes` table created with columns: `id` (UUID PK), `route_name` (TEXT UNIQUE), `description` (TEXT), `area_coverage` (TEXT), `is_active` (BOOLEAN DEFAULT true)
  - Audit columns: `created_at`, `updated_at`, `created_by` (FK to profiles), `updated_by` (FK to profiles)
  - Constraints: UNIQUE on `route_name`, CHECK on `route_name` length (2-100 chars), CHECK on `description` length (≤500 chars)
  - Indexes: `idx_routes_route_name`, `idx_routes_active`, `idx_routes_created_at`
- **Implementation:**
  - Create migration: `001_create_routes_table.sql`
  - Add RLS policies (GAP-042)
  - Test INSERT/SELECT/UPDATE operations
- **Database Migration:** Yes
- **Frontend Changes:** No
- **Backend Changes:** No
- **Testing:** Unit tests for constraints, RLS policy tests
- **Rollback:** Drop table migration

#### GAP-002: Staff Assignments Route Relationship (P0, 3 pts)
- **Dependencies:** GAP-001
- **Acceptance Criteria:**
  - `staff_assignments.route_id` column added (UUID, FK to routes.id, nullable)
  - Foreign key constraint: `ON DELETE SET NULL`
  - Composite index: `idx_staff_assignments_route_active`
- **Implementation:**
  - Migration: `002_add_route_to_staff_assignments.sql`
  - Add FK constraint
  - Create index
- **Database Migration:** Yes
- **Testing:** FK constraint tests, index performance tests
- **Rollback:** Drop column migration

#### GAP-003: Customers Route Relationship (P0, 3 pts)
- **Dependencies:** GAP-001
- **Acceptance Criteria:**
  - `customers.route_id` column added (UUID, FK to routes.id, nullable)
  - Foreign key constraint: `ON DELETE SET NULL`
  - Index: `idx_customers_route_active`
- **Implementation:**
  - Migration: `003_add_route_to_customers.sql`
- **Database Migration:** Yes
- **Testing:** FK constraint tests
- **Rollback:** Drop column migration

#### GAP-023: Customers INSERT Policy for Office Staff (P0, 2 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - Policy: `CREATE POLICY "Office staff can create customers" ON customers FOR INSERT WITH CHECK (is_staff() AND staff_type = 'office');`
  - Office staff can INSERT customer records via Supabase API
  - Collection staff cannot INSERT customers
- **Implementation:**
  - Add policy to `supabase_schema.sql`
  - Test with office staff role
- **Database Migration:** Yes (policy addition)
- **Testing:** RLS policy tests, integration tests
- **Rollback:** Drop policy

#### GAP-024: User Schemes INSERT Policy for Office Staff (P0, 2 pts)
- **Dependencies:** GAP-028 (remove customer self-enrollment)
- **Acceptance Criteria:**
  - Policy allows office staff to INSERT enrollments: `WITH CHECK (is_staff() AND staff_type = 'office')`
  - Customers cannot self-enroll (GAP-028 fixed)
- **Implementation:**
  - Modify existing policy to remove customer self-enrollment
  - Add explicit office staff INSERT policy
- **Database Migration:** Yes
- **Testing:** Verify customers cannot enroll, office staff can
- **Rollback:** Restore original policy

#### GAP-025: Payments INSERT Policy for Office Staff (P0, 2 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - Policy allows office staff to INSERT payments with `staff_id = NULL`
  - Policy: `WITH CHECK (is_staff() AND staff_type = 'office' AND staff_id IS NULL)`
- **Implementation:**
  - Add policy to payments table
- **Database Migration:** Yes
- **Testing:** Office staff can create office collections
- **Rollback:** Drop policy

#### GAP-026: Staff Assignments INSERT Policy for Office Staff (P0, 2 pts)
- **Dependencies:** GAP-001, GAP-002
- **Acceptance Criteria:**
  - Policy allows office staff to INSERT/UPDATE assignments
  - Policy: `FOR ALL USING (is_staff() AND staff_type = 'office') WITH CHECK (...)`
- **Implementation:**
  - Add INSERT and UPDATE policies
- **Database Migration:** Yes
- **Testing:** Office staff can create assignments
- **Rollback:** Drop policies

#### GAP-027: Profiles UPDATE Policy for Office Staff (P0, 2 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - Policy allows office staff to UPDATE customer profiles (limited fields: name, phone)
  - Policy: `FOR UPDATE USING (is_staff() AND staff_type = 'office') WITH CHECK (...)`
- **Implementation:**
  - Add UPDATE policy with field restrictions
- **Database Migration:** Yes
- **Testing:** Office staff can update customer profiles
- **Rollback:** Drop policy

#### GAP-028: Remove Customer Self-Enrollment (P0, 3 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - Remove customer self-enrollment from `user_schemes` INSERT policy
  - Policy only allows: `WITH CHECK (is_staff() AND staff_type = 'office' OR is_admin())`
  - Customers attempting enrollment receive RLS error
- **Implementation:**
  - Drop existing policy
  - Create new policy excluding customer self-enrollment
- **Database Migration:** Yes
- **Testing:** Verify customers cannot enroll
- **Rollback:** Restore original policy

#### GAP-029: Withdrawals UPDATE Policy Fix (P0, 3 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - Policy verifies staff is assigned to customer before allowing withdrawal UPDATE
  - Policy: `USING (is_staff() AND (is_admin() OR is_current_staff_assigned_to_customer((SELECT customer_id FROM withdrawals WHERE id = id))))`
- **Implementation:**
  - Replace existing policy with assignment check
- **Database Migration:** Yes
- **Testing:** Unassigned staff cannot update withdrawals
- **Rollback:** Restore original policy

#### GAP-031: Customers SELECT Policy Fix (P0, 3 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - Collection staff can only SELECT assigned customers
  - Policy: `USING (profile_id = get_user_profile() OR (is_staff() AND (is_admin() OR is_staff_assigned_to_customer(id))))`
  - Remove policy that allows all staff to read all customers
- **Implementation:**
  - Fix policy logic to enforce assignment filtering
- **Database Migration:** Yes
- **Testing:** Collection staff only sees assigned customers
- **Rollback:** Restore original policy

#### GAP-032: Payments SELECT Policy Fix (P0, 3 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - Collection staff can only SELECT payments for assigned customers
  - Policy: `USING (customer_id IN (SELECT id FROM customers WHERE profile_id = get_user_profile()) OR (is_staff() AND (is_admin() OR is_staff_assigned_to_customer(customer_id))))`
- **Implementation:**
  - Fix policy to enforce assignment filtering
- **Database Migration:** Yes
- **Testing:** Collection staff only sees assigned customer payments
- **Rollback:** Restore original policy

#### GAP-033: Mobile App Access Database-Level Check (P0, 5 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - RLS policy prevents admin/office staff from accessing mobile app data
  - Create RPC function: `check_mobile_app_access()` that returns error if admin/office staff
  - Mobile app queries use this function
- **Implementation:**
  - Create RPC function with role check
  - Update mobile app queries to call function
  - Remove frontend-only checks (keep as secondary validation)
- **Database Migration:** Yes (RPC function)
- **Frontend Changes:** Yes (remove primary check, keep secondary)
- **Backend Changes:** Yes
- **Testing:** Admin/office staff cannot access mobile app data via direct API
- **Rollback:** Remove RPC function, restore frontend checks

#### GAP-042: Routes RLS Policies (P0, 2 pts)
- **Dependencies:** GAP-001
- **Acceptance Criteria:**
  - SELECT policy: Staff can read routes
  - ALL policy: Office staff can manage routes
  - ALL policy: Admin can manage routes
- **Implementation:**
  - Create three policies for routes table
- **Database Migration:** Yes
- **Testing:** RLS policy tests
- **Rollback:** Drop policies

#### Daily Breakdown (Critical Path):
- **Day 1-2:** GAP-001 (routes table), GAP-042 (RLS policies)
- **Day 3-4:** GAP-002, GAP-003 (route relationships)
- **Day 5-6:** GAP-023, GAP-024, GAP-025, GAP-026, GAP-027 (RLS policies)
- **Day 7-8:** GAP-028 (remove self-enrollment), GAP-029, GAP-031, GAP-032 (policy fixes)
- **Day 9-10:** GAP-033 (database-level mobile app check), testing, documentation

#### Testing Strategy:
- **Unit Tests:** RLS policy tests for each policy
- **Integration Tests:** Office staff can create customers/enrollments/assignments
- **Security Tests:** Customers cannot self-enroll, collection staff only see assigned data
- **Manual Testing:** Verify all RLS policies work correctly
- **Regression Tests:** Existing flows still work

#### Deployment:
- **Incremental:** Can deploy routes table first, then policies
- **Feature Flags:** None required
- **Database Migration:** Sequential migrations, test in staging first
- **Rollback:** Each migration has rollback script

---

### SPRINT 2: Database Completion & Offline Infrastructure (Weeks 3-4)
**Story Points:** 40/40  
**Priority Focus:** P1 Database Schema, P1 Offline Infrastructure

#### GAP-007: Routes Route Name Unique Constraint (P1, 1 pt)
- **Dependencies:** GAP-001
- **Acceptance Criteria:** UNIQUE constraint on `routes.route_name` enforced
- **Implementation:** Add constraint to routes table
- **Database Migration:** Yes
- **Testing:** Attempt duplicate route_name fails
- **Rollback:** Drop constraint

#### GAP-008: Routes Is Active Check Constraint (P1, 1 pt)
- **Dependencies:** GAP-001
- **Acceptance Criteria:** CHECK constraint ensures `is_active` is boolean, defaults to true
- **Implementation:** Add constraint
- **Database Migration:** Yes
- **Testing:** Boolean validation works
- **Rollback:** Drop constraint

#### GAP-009: Staff Assignments Route FK Constraint (P1, 1 pt)
- **Dependencies:** GAP-001, GAP-002
- **Acceptance Criteria:** FK constraint `staff_assignments.route_id → routes.id` with `ON DELETE SET NULL`
- **Implementation:** Add FK constraint
- **Database Migration:** Yes
- **Testing:** Invalid route_id fails, route deletion sets NULL
- **Rollback:** Drop constraint

#### GAP-010: Customers Route FK Constraint (P1, 1 pt)
- **Dependencies:** GAP-001, GAP-003
- **Acceptance Criteria:** FK constraint `customers.route_id → routes.id` with `ON DELETE SET NULL`
- **Implementation:** Add FK constraint
- **Database Migration:** Yes
- **Testing:** Invalid route_id fails
- **Rollback:** Drop constraint

#### GAP-011: Route-Based Assignment Workflow Support (P1, 2 pts)
- **Dependencies:** GAP-001, GAP-002, GAP-003
- **Acceptance Criteria:** Route-based customer/staff assignment queries work
- **Implementation:** Verify queries work with new relationships
- **Database Migration:** No (uses existing migrations)
- **Testing:** Route-based filtering works
- **Rollback:** N/A

#### GAP-012: Profiles to Routes Relationship (P2, 2 pts)
- **Dependencies:** GAP-001
- **Acceptance Criteria:** Many-to-many relationship between profiles (staff) and routes
- **Implementation:** Create junction table `staff_routes` or add `profiles.route_id`
- **Database Migration:** Yes
- **Testing:** Staff can be assigned to routes
- **Rollback:** Drop table/column

#### GAP-013: Routes Audit Trail (P2, 2 pts)
- **Dependencies:** GAP-001
- **Acceptance Criteria:** Audit columns exist: `created_at`, `updated_at`, `created_by`, `updated_by`
- **Implementation:** Already included in GAP-001, verify triggers update these
- **Database Migration:** Yes (triggers)
- **Testing:** Audit columns populated correctly
- **Rollback:** Drop triggers

#### GAP-016: Offline Sync Conflict Resolution Field (P1, 3 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - Add `payments.sync_status` enum column: 'pending', 'synced', 'conflict', 'resolved'
  - Or add `payments.sync_conflict_id` FK to conflicting payment
- **Implementation:**
  - Add `sync_status` column with default 'pending'
  - Create index on `sync_status`
- **Database Migration:** Yes
- **Frontend Changes:** Yes (update payment service)
- **Backend Changes:** Yes
- **Testing:** Sync status tracked correctly
- **Rollback:** Drop column

#### GAP-017: Routes Route Name Validation (P2, 1 pt)
- **Dependencies:** GAP-001
- **Acceptance Criteria:** CHECK constraint: `char_length(route_name) >= 2 AND char_length(route_name) <= 100`
- **Implementation:** Add constraint
- **Database Migration:** Yes
- **Testing:** Invalid lengths rejected
- **Rollback:** Drop constraint

#### GAP-018: Routes Description Length Validation (P2, 1 pt)
- **Dependencies:** GAP-001
- **Acceptance Criteria:** CHECK constraint: `description IS NULL OR char_length(description) <= 500`
- **Implementation:** Add constraint
- **Database Migration:** Yes
- **Testing:** Long descriptions rejected
- **Rollback:** Drop constraint

#### GAP-019: Routes Area Coverage Validation (P2, 2 pts)
- **Dependencies:** GAP-001
- **Acceptance Criteria:** Validation based on expected format (text, JSON, or geographic boundaries)
- **Implementation:** Add CHECK constraint or validation function
- **Database Migration:** Yes
- **Testing:** Invalid formats rejected
- **Rollback:** Drop constraint

#### GAP-020: Routes Table Indexes (P2, 2 pts)
- **Dependencies:** GAP-001
- **Acceptance Criteria:** Indexes created: `idx_routes_route_name`, `idx_routes_active`, `idx_routes_created_at`
- **Implementation:** Create indexes
- **Database Migration:** Yes
- **Testing:** Query performance improved
- **Rollback:** Drop indexes

#### GAP-021: Staff Assignments Route Index (P2, 1 pt)
- **Dependencies:** GAP-002
- **Acceptance Criteria:** Composite index: `idx_staff_assignments_route_active`
- **Implementation:** Create index
- **Database Migration:** Yes
- **Testing:** Route-based queries faster
- **Rollback:** Drop index

#### GAP-022: Customers Route Index (P2, 1 pt)
- **Dependencies:** GAP-003
- **Acceptance Criteria:** Index: `idx_customers_route_active`
- **Implementation:** Create index
- **Database Migration:** Yes
- **Testing:** Route-based customer queries faster
- **Rollback:** Drop index

#### GAP-047: Offline Payment Queue Infrastructure (P1, 8 pts)
- **Dependencies:** GAP-016
- **Acceptance Criteria:**
  - Offline payment queue storage (Flutter Secure Storage or SQLite)
  - Queue management: limit enforcement, status tracking
  - Network connectivity detection (`connectivity_plus` package)
  - Queue full detection
- **Implementation:**
  - Create `OfflinePaymentQueue` service using `flutter_secure_storage`
  - Implement `NetworkConnectivityService`
  - Add queue limit (e.g., 100 payments)
  - Track queue status
- **Database Migration:** No
- **Frontend Changes:** Yes (new service)
- **Backend Changes:** No
- **Testing:** Queue stores payments offline, enforces limits
- **Rollback:** Remove service, restore online-only flow

#### GAP-048: Offline Sync Service (P1, 8 pts)
- **Dependencies:** GAP-047, GAP-016
- **Acceptance Criteria:**
  - Automatic sync when connection restored
  - Retry logic for failed sync
  - Conflict resolution for duplicate payments
  - Sync status tracking
- **Implementation:**
  - Create `OfflineSyncService`
  - Implement automatic sync trigger on connectivity restore
  - Implement retry logic with exponential backoff
  - Implement conflict resolution (last-write-wins or manual resolution)
- **Database Migration:** No
- **Frontend Changes:** Yes (new service)
- **Backend Changes:** No
- **Testing:** Payments sync automatically, conflicts resolved
- **Rollback:** Remove service

#### GAP-068: Payment Immutability Application-Level Enforcement (P2, 2 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - Application code prevents UPDATE/DELETE attempts on payments
  - Error handling for immutability violations
- **Implementation:**
  - Add checks in payment service to prevent UPDATE/DELETE
  - Add error messages
- **Database Migration:** No
- **Frontend Changes:** Yes
- **Backend Changes:** Yes
- **Testing:** UPDATE/DELETE attempts fail gracefully
- **Rollback:** Remove checks

#### GAP-069: Payments RLS UPDATE/DELETE Policies (P2, 2 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - RLS policies explicitly deny UPDATE/DELETE on payments
  - Policies: `FOR UPDATE USING (false)`, `FOR DELETE USING (false)`
- **Implementation:**
  - Add policies to payments table
- **Database Migration:** Yes
- **Testing:** RLS blocks UPDATE/DELETE
- **Rollback:** Drop policies

#### GAP-070: Reversal Payment Validation (P1, 3 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - Constraint ensures `reverses_payment_id` points to existing payment
  - Constraint ensures original payment is not already reversed
  - Constraint ensures original payment is not itself a reversal
- **Implementation:**
  - Add CHECK constraint or trigger validation
- **Database Migration:** Yes
- **Testing:** Invalid reversals rejected
- **Rollback:** Drop constraint/trigger

#### Daily Breakdown:
- **Day 1-2:** GAP-007 through GAP-013 (constraints, relationships, audit)
- **Day 3-4:** GAP-016, GAP-017, GAP-018, GAP-019 (validation, sync field)
- **Day 5-6:** GAP-020, GAP-021, GAP-022 (indexes)
- **Day 7-8:** GAP-047 (offline queue infrastructure)
- **Day 9-10:** GAP-048 (offline sync service), GAP-068, GAP-069, GAP-070 (immutability)

#### Testing Strategy:
- **Unit Tests:** All constraints and validations
- **Integration Tests:** Offline queue and sync functionality
- **Performance Tests:** Index performance
- **Manual Testing:** Offline payment collection and sync

---

### SPRINT 3: Financial Integrity & Rate Management (Weeks 5-6)
**Story Points:** 35/40  
**Priority Focus:** P0 Financial Integrity, P1 Rate Management

#### GAP-057: Trigger Fix - Use Payment Rate (P0, 5 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - Trigger uses `NEW.metal_rate_per_gram` instead of current market rate
  - Remove recalculation logic that uses `market_rates` table
  - Trigger only calculates if `metal_grams_added = 0` AND uses payment rate
- **Implementation:**
  - Modify `update_user_scheme_totals` trigger
  - Use `NEW.metal_rate_per_gram` for calculation
  - Remove `market_rates` table query
- **Database Migration:** Yes (trigger modification)
- **Testing:** Historical payments use correct rates
- **Rollback:** Restore original trigger

#### GAP-058: Trigger Fix - Remove Market Rates Query (P0, 3 pts)
- **Dependencies:** GAP-057
- **Acceptance Criteria:**
  - Trigger does not query `market_rates` table
  - Falls back to `NEW.metal_rate_per_gram` if calculation needed
- **Implementation:**
  - Remove `market_rates` SELECT from trigger
- **Database Migration:** Yes
- **Testing:** Trigger uses payment rate only
- **Rollback:** Restore query

#### GAP-059: Payment Rate Validation (P1, 5 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - Constraint or trigger validates `metal_rate_per_gram` matches market rate at payment time
  - Validation checks `market_rates.price_per_gram` for `payment_date` (or closest prior date)
  - Allows small deviation (e.g., 1%) for rounding
- **Implementation:**
  - Create trigger `validate_payment_rate` before INSERT
  - Query `market_rates` for payment date
  - Validate rate matches (within tolerance)
- **Database Migration:** Yes
- **Testing:** Payments with incorrect rates rejected
- **Rollback:** Drop trigger

#### GAP-060: Remove Hardcoded Rates from Withdrawal (P1, 3 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - Withdrawal screen queries `market_rates` table
  - Query: `market_rates.select('*').order('rate_date', ascending: false).limit(1)`
  - Remove hardcoded rates: `6500.0` and `78.0`
- **Implementation:**
  - Update `withdrawal_screen.dart` to query market rates
  - Remove hardcoded rate constants
- **Database Migration:** No
- **Frontend Changes:** Yes
- **Backend Changes:** No
- **Testing:** Withdrawal uses current market rates
- **Rollback:** Restore hardcoded rates

#### GAP-071: Market Rates Coverage Verification (P2, 2 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - Function or view verifies `market_rates` has rate for every payment date
  - Report missing rates for reconciliation
- **Implementation:**
  - Create function `verify_market_rates_coverage()`
  - Returns list of payment dates without matching rates
- **Database Migration:** Yes (function)
- **Testing:** Function identifies missing rates
- **Rollback:** Drop function

#### GAP-072: Payment Rate Historical Validation (P2, 3 pts)
- **Dependencies:** GAP-059
- **Acceptance Criteria:**
  - Validation ensures payment rate matches historical `market_rates` for payment date
  - Can be part of GAP-059 trigger
- **Implementation:**
  - Enhance GAP-059 trigger to validate historical rates
- **Database Migration:** Yes
- **Testing:** Historical payments validated against historical rates
- **Rollback:** Simplify trigger

#### GAP-073: Trigger Fallback Fix (P0, 3 pts)
- **Dependencies:** GAP-057
- **Acceptance Criteria:**
  - If historical rate missing, trigger uses `NEW.metal_rate_per_gram` (not current rate)
  - Never uses current rate for historical payments
- **Implementation:**
  - Fix trigger fallback logic
- **Database Migration:** Yes
- **Testing:** Missing rates use payment rate, not current rate
- **Rollback:** Restore original logic

#### GAP-063: Metal Grams Calculation Constraint (P1, 3 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - CHECK constraint: `ABS(metal_grams_added - (net_amount / metal_rate_per_gram)) < 0.01`
  - Allows small rounding differences
- **Implementation:**
  - Add constraint to payments table
- **Database Migration:** Yes
- **Testing:** Invalid calculations rejected
- **Rollback:** Drop constraint

#### GAP-064: Reconciliation View - Total Amount Paid (P1, 3 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - View: `reconcile_user_schemes_amounts`
  - Compares `user_schemes.total_amount_paid` vs `SUM(payments.net_amount)`
  - Shows discrepancies
- **Implementation:**
  - Create view with JOIN and calculation
- **Database Migration:** Yes
- **Testing:** View shows correct reconciliation
- **Rollback:** Drop view

#### GAP-065: Reconciliation View - Accumulated Grams (P1, 3 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - View: `reconcile_user_schemes_grams`
  - Compares `user_schemes.accumulated_grams` vs `SUM(payments.metal_grams_added)`
- **Implementation:**
  - Create view
- **Database Migration:** Yes
- **Testing:** View shows correct reconciliation
- **Rollback:** Drop view

#### GAP-066: Reconciliation View - Payments Made (P1, 2 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - View: `reconcile_user_schemes_payments`
  - Compares `user_schemes.payments_made` vs `COUNT(payments.id)`
- **Implementation:**
  - Create view
- **Database Migration:** Yes
- **Testing:** View shows correct count reconciliation
- **Rollback:** Drop view

#### GAP-067: Staff Daily Collections Reconciliation (P2, 2 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - View: `reconcile_staff_daily_collections`
  - Compares staff daily totals vs sum of individual payments
- **Implementation:**
  - Create view using `staff_daily_stats` and payments
- **Database Migration:** Yes
- **Testing:** View shows discrepancies
- **Rollback:** Drop view

#### GAP-078: Remove Hardcoded Rates from Payment Collection (P1, 2 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - Remove fallback to `MockData.goldPricePerGram` and `MockData.silverPricePerGram`
  - Proper error handling if rate query fails
- **Implementation:**
  - Update `collect_payment_screen.dart`
  - Remove mock data fallback
  - Add error handling
- **Database Migration:** No
- **Frontend Changes:** Yes
- **Backend Changes:** No
- **Testing:** Payment collection fails gracefully if rates unavailable
- **Rollback:** Restore mock fallback

#### GAP-085: Simplify Payment Trigger (P2, 2 pts)
- **Dependencies:** GAP-057
- **Acceptance Criteria:**
  - Trigger only calculates if `metal_grams_added = 0`
  - Uses `NEW.metal_rate_per_gram` only
  - No unnecessary complexity
- **Implementation:**
  - Simplify trigger logic (already done in GAP-057)
- **Database Migration:** Yes
- **Testing:** Trigger works correctly
- **Rollback:** N/A

#### Daily Breakdown:
- **Day 1-2:** GAP-057, GAP-058, GAP-073 (trigger fixes)
- **Day 3-4:** GAP-059, GAP-071, GAP-072 (rate validation)
- **Day 5-6:** GAP-063, GAP-064, GAP-065, GAP-066 (reconciliation views)
- **Day 7-8:** GAP-067, GAP-060, GAP-078 (remove hardcoded rates)
- **Day 9-10:** GAP-085 (simplify trigger), testing, documentation

#### Testing Strategy:
- **Unit Tests:** Trigger logic, constraint validation
- **Integration Tests:** Rate validation, reconciliation views
- **Financial Tests:** Verify calculations are correct
- **Manual Testing:** Payment recording with various rates

---

### SPRINT 4: Customer Flows Completion (Weeks 7-8)
**Story Points:** 40/40  
**Priority Focus:** P1 Customer Flows

#### GAP-044: Payment Schedule Implementation (P1, 8 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - Payment schedule calculated from `user_schemes` and `payments` tables
  - Calendar view with due dates highlighted
  - Queries: `user_schemes.select('*').eq('customer_id', customerId).eq('status', 'active')`
  - Queries: `payments.select('*').eq('customer_id', customerId).order('payment_date', ascending: false)`
  - Schedule based on `payment_frequency` (daily/weekly/monthly)
- **Implementation:**
  - Update `payment_schedule_screen.dart`
  - Remove `MockData.paymentSchedule`
  - Implement schedule calculation logic
  - Add calendar view widget
- **Database Migration:** No
- **Frontend Changes:** Yes
- **Backend Changes:** No
- **Testing:** Schedule matches database state
- **Rollback:** Restore mock data

#### GAP-044: Transaction History Screen (P1, 5 pts)
- **Dependencies:** GAP-044 (payment schedule)
- **Acceptance Criteria:**
  - Transaction history screen implemented
  - Transaction detail screen implemented
  - Filtering by date range, scheme, payment method
  - Queries payments table correctly
- **Implementation:**
  - Create `transaction_history_screen.dart`
  - Create `transaction_detail_screen.dart`
  - Implement filtering logic
- **Database Migration:** No
- **Frontend Changes:** Yes
- **Backend Changes:** No
- **Testing:** History shows all transactions, filtering works
- **Rollback:** Remove screens

#### GAP-045: Investment Portfolio Implementation (P1, 8 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - Total investment screen implemented
  - Gold/Silver asset detail screens implemented
  - Market rates screen implemented
  - Portfolio value calculation: `(gold_grams * current_gold_rate) + (silver_grams * current_silver_rate)`
  - Database aggregation queries for totals
- **Implementation:**
  - Create `total_investment_screen.dart`
  - Create `gold_asset_detail_screen.dart`, `silver_asset_detail_screen.dart`
  - Create `market_rates_screen.dart`
  - Implement aggregation queries
- **Database Migration:** No
- **Frontend Changes:** Yes
- **Backend Changes:** No
- **Testing:** Portfolio calculations correct, screens display data
- **Rollback:** Remove screens

#### GAP-046: Profile Management UPDATE (P1, 5 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - Profile UPDATE queries verified: `profiles.update({'name': newName}).eq('user_id', userId)`
  - Customer UPDATE queries verified: `customers.update({'address': newAddress, ...}).eq('profile_id', profileId)`
  - Account information screen implemented
  - KYC details displayed from `customers` table
- **Implementation:**
  - Verify UPDATE functionality in `profile_screen.dart`
  - Create `account_information_screen.dart`
  - Display KYC details
- **Database Migration:** No
- **Frontend Changes:** Yes
- **Backend Changes:** No
- **Testing:** Profile updates work, KYC displayed
- **Rollback:** Remove UPDATE functionality

#### GAP-055: Withdrawal Request INSERT (P1, 8 pts)
- **Dependencies:** GAP-060 (market rates query)
- **Acceptance Criteria:**
  - Active enrollments query: `user_schemes.select('id, scheme_id, accumulated_metal_grams, total_amount_paid, status').eq('customer_id', customerId).eq('status', 'active')`
  - Market rates query (from GAP-060)
  - Total available grams calculation across all active schemes
  - Current value calculation based on market rates
  - Withdrawal INSERT: `withdrawals.insert({'customer_id': ..., 'user_scheme_id': ..., 'withdrawal_type': ..., 'requested_amount': ..., 'requested_grams': ..., 'status': 'pending', ...})`
  - Success message with request ID
  - Navigation to withdrawal list screen
- **Implementation:**
  - Update `withdrawal_screen.dart`
  - Implement database queries
  - Implement INSERT operation
  - Add success handling
- **Database Migration:** No
- **Frontend Changes:** Yes
- **Backend Changes:** No
- **Testing:** Withdrawal requests created in database
- **Rollback:** Remove INSERT, restore UI-only

#### GAP-079: Remove All Mock Data (P2, 6 pts)
- **Dependencies:** GAP-044, GAP-045, GAP-046, GAP-055
- **Acceptance Criteria:**
  - Remove `MockData.paymentSchedule` from payment schedule screen
  - Remove `MockData.userName` from profile screen
  - Remove mock data from `account_information_page.dart`
  - Remove `MockData.schemeDetails` from scheme detail screen
  - All screens query database instead
- **Implementation:**
  - Remove all `MockData` references
  - Replace with database queries
- **Database Migration:** No
- **Frontend Changes:** Yes
- **Backend Changes:** No
- **Testing:** All screens use real data
- **Rollback:** Restore mock data

#### Daily Breakdown:
- **Day 1-2:** GAP-044 (payment schedule)
- **Day 3-4:** GAP-044 (transaction history), GAP-045 (portfolio)
- **Day 5-6:** GAP-046 (profile management), GAP-055 (withdrawal INSERT)
- **Day 7-8:** GAP-079 (remove mock data)
- **Day 9-10:** Testing, bug fixes, documentation

#### Testing Strategy:
- **Unit Tests:** Database queries, calculations
- **Integration Tests:** Full customer flows
- **Manual Testing:** All customer screens functional
- **Regression Tests:** Existing flows still work

---

### SPRINT 5-6: Website Foundation (Weeks 9-12)
**Story Points:** 80/80 (2 sprints)  
**Priority Focus:** P1 Website Implementation

#### Sprint 5: Next.js Setup & Authentication (Weeks 9-10)
**Story Points:** 40/40

**GAP-049: Office Staff Create Customer (P1, 13 pts)**
- **Dependencies:** GAP-023 (RLS policy)
- **Acceptance Criteria:**
  - Customer registration form page: `/office/customers/add`
  - Supabase Auth user creation: `Supabase.instance.client.auth.admin.createUser()`
  - Profile INSERT: `profiles.insert({'user_id': ..., 'name': ..., 'phone': ..., 'role': 'customer'})`
  - Customer INSERT: `customers.insert({'profile_id': ..., 'address': ..., 'nominee_name': ...})`
  - KYC document upload functionality
  - Phone number uniqueness validation
  - Customer detail page: `/office/customers/[id]`
- **Implementation:**
  - Create Next.js pages
  - Implement form with validation
  - Implement Supabase Auth admin API calls
  - Implement file upload for KYC
- **Database Migration:** No
- **Frontend Changes:** Yes (new website pages)
- **Backend Changes:** Yes (Supabase Auth admin)
- **Testing:** Office staff can create customers
- **Rollback:** Remove pages

**GAP-050: Office Staff Enroll Customer (P1, 13 pts)**
- **Dependencies:** GAP-024 (RLS policy), GAP-049
- **Acceptance Criteria:**
  - Enrollment form page: `/office/customers/[id]/enroll`
  - Scheme selection dropdown (queries `schemes` table)
  - Payment frequency selection (daily/weekly/monthly)
  - Amount range input with scheme validation
  - Start date selection (defaults to today, cannot be past)
  - Maturity date calculation based on scheme type
  - Enrollment INSERT: `user_schemes.insert({...})`
  - Confirmation dialog
  - Customer notification (SMS/email) - optional for MVP
- **Implementation:**
  - Create enrollment page
  - Implement form with validation
  - Implement scheme queries
  - Implement enrollment INSERT
- **Database Migration:** No
- **Frontend Changes:** Yes
- **Backend Changes:** Yes
- **Testing:** Office staff can enroll customers
- **Rollback:** Remove page

**Next.js Setup & Authentication (14 pts)**
- **Dependencies:** None
- **Acceptance Criteria:**
  - Next.js project setup with TypeScript
  - Supabase client configuration
  - Authentication pages: `/login`, `/logout`
  - Role-based routing (office staff, admin)
  - Protected routes middleware
- **Implementation:**
  - Initialize Next.js project
  - Configure Supabase
  - Implement auth pages
  - Implement route protection
- **Database Migration:** No
- **Frontend Changes:** Yes (new website)
- **Backend Changes:** No
- **Testing:** Authentication works, routes protected
- **Rollback:** Remove website

#### Sprint 6: Office Staff Assignment & Payment (Weeks 11-12)
**Story Points:** 40/40

**GAP-051: Office Staff Assign Customer to Collection Staff (P1, 13 pts)**
- **Dependencies:** GAP-001 (routes table), GAP-002, GAP-003, GAP-026 (RLS policy)
- **Acceptance Criteria:**
  - Assignment interface page: `/office/assignments/by-route`
  - Route selection dropdown (queries `routes` table)
  - Customer filtering by route area
  - Staff selection dropdown (queries staff with `staff_type='collection'`)
  - Bulk assignment functionality (multiple customers at once)
  - Assignment INSERT: `staff_assignments.insert({'staff_id': ..., 'customer_id': ..., 'is_active': true, 'assigned_date': today})`
  - Assignment confirmation dialog
- **Implementation:**
  - Create assignment page
  - Implement route-based filtering
  - Implement staff selection
  - Implement bulk assignment
- **Database Migration:** No
- **Frontend Changes:** Yes
- **Backend Changes:** Yes
- **Testing:** Office staff can assign customers by route
- **Rollback:** Remove page

**GAP-052: Office Staff Manual Payment Entry (P1, 13 pts)**
- **Dependencies:** GAP-025 (RLS policy)
- **Acceptance Criteria:**
  - Manual payment entry form page: `/office/transactions/add`
  - Customer search functionality (by name or phone)
  - Active scheme selection for customer
  - Payment amount entry with scheme min/max validation
  - Payment method selection (Cash, UPI, Bank Transfer)
  - Payment date selection (defaults to today, can be past date)
  - Payment time entry (optional)
  - Notes field (optional, up to 500 characters)
  - Payment INSERT with `staff_id = NULL` for office collections
  - Receipt ID generation and display
  - Transaction detail page: `/office/transactions/[id]`
- **Implementation:**
  - Create payment entry page
  - Implement customer search
  - Implement payment form
  - Implement payment INSERT
- **Database Migration:** No
- **Frontend Changes:** Yes
- **Backend Changes:** Yes
- **Testing:** Office staff can create office collections
- **Rollback:** Remove page

**Office Staff Dashboard (14 pts)**
- **Dependencies:** GAP-049, GAP-050, GAP-051, GAP-052
- **Acceptance Criteria:**
  - Dashboard page: `/office/dashboard`
  - Summary statistics (total customers, active schemes, today's collections)
  - Quick links to key workflows
  - Recent activity feed
- **Implementation:**
  - Create dashboard page
  - Implement statistics queries
  - Create UI components
- **Database Migration:** No
- **Frontend Changes:** Yes
- **Backend Changes:** No
- **Testing:** Dashboard displays correct data
- **Rollback:** Remove dashboard

#### Daily Breakdown (Sprint 5):
- **Day 1-2:** Next.js setup, authentication
- **Day 3-4:** GAP-049 (create customer) - form and validation
- **Day 5-6:** GAP-049 (create customer) - Supabase Auth, KYC upload
- **Day 7-8:** GAP-050 (enroll customer) - form and scheme selection
- **Day 9-10:** GAP-050 (enroll customer) - enrollment INSERT, testing

#### Daily Breakdown (Sprint 6):
- **Day 1-2:** GAP-051 (assign customer) - route selection, customer filtering
- **Day 3-4:** GAP-051 (assign customer) - staff selection, bulk assignment
- **Day 5-6:** GAP-052 (manual payment) - customer search, form
- **Day 7-8:** GAP-052 (manual payment) - payment INSERT, receipt display
- **Day 9-10:** Office staff dashboard, testing, bug fixes

#### Testing Strategy:
- **Unit Tests:** Form validation, API calls
- **Integration Tests:** Full office staff workflows
- **Manual Testing:** All office staff pages functional
- **Security Tests:** RLS policies enforced

---

### SPRINT 7-8: Admin Dashboard & Market Rates (Weeks 13-16)
**Story Points:** 75/80 (2 sprints)  
**Priority Focus:** P1 Admin Flows

#### Sprint 7: Admin Financial Dashboard (Weeks 13-14)
**Story Points:** 40/40

**GAP-053: Admin Financial Dashboard (P1, 21 pts)**
- **Dependencies:** None
- **Acceptance Criteria:**
  - Admin dashboard page: `/admin/dashboard`
  - Financial metrics cards:
    - Total customers query
    - Active schemes query
    - Today's collections query
    - Today's withdrawals query
    - Pending payments query
  - Inflow tracking page: `/admin/financials/inflow`
    - Payments query with filters
    - Daily/weekly/monthly aggregation
    - Payment method breakdown
    - Line chart (last 30 days)
    - Bar chart (weekly totals)
    - Pie chart (payment method distribution)
    - Payment list table with filters
  - Outflow tracking page: `/admin/financials/outflow`
    - Withdrawals query
    - Daily/weekly/monthly aggregation
    - Status breakdown
    - Charts and tables
  - Cash flow analysis page: `/admin/financials/cash-flow`
    - Net cash flow calculation
    - Cash flow chart
    - Trend analysis
  - Data filtering by date range, staff, customer
  - Export functionality (CSV/Excel)
- **Implementation:**
  - Create admin dashboard pages
  - Implement financial queries
  - Implement chart components (using Chart.js or similar)
  - Implement export functionality
- **Database Migration:** No
- **Frontend Changes:** Yes
- **Backend Changes:** Yes (queries)
- **Testing:** Dashboard shows correct financial data
- **Rollback:** Remove pages

**Admin Navigation & Layout (19 pts)**
- **Dependencies:** GAP-053
- **Acceptance Criteria:**
  - Admin navigation menu
  - Layout component
  - Role-based access control
- **Implementation:**
  - Create layout components
  - Implement navigation
- **Database Migration:** No
- **Frontend Changes:** Yes
- **Backend Changes:** No
- **Testing:** Navigation works correctly
- **Rollback:** Remove components

#### Sprint 8: Market Rates Management (Weeks 15-16)
**Story Points:** 35/40

**GAP-054: Admin Market Rates Management (P1, 21 pts)**
- **Dependencies:** None
- **Acceptance Criteria:**
  - Market rates management page: `/admin/market-rates`
  - External API integration (TBD API endpoint)
  - Automated daily fetch (Edge Function or scheduled job)
  - Manual rate entry form
  - Manual override functionality
  - Rate history display
  - Rate deviation detection (>10% change flag)
  - Admin notification on API fetch failure
- **Implementation:**
  - Create market rates page
  - Implement API integration
  - Create Edge Function for daily fetch
  - Implement manual entry form
  - Implement deviation detection
- **Database Migration:** No (may need Edge Function)
- **Frontend Changes:** Yes
- **Backend Changes:** Yes (Edge Function)
- **Testing:** Rates fetched and stored correctly
- **Rollback:** Remove Edge Function, disable auto-fetch

**Market Rates API Integration (14 pts)**
- **Dependencies:** GAP-054
- **Acceptance Criteria:**
  - Edge Function: `fetch-market-rates`
  - Scheduled daily execution (Supabase cron or external scheduler)
  - Error handling and retry logic
  - Rate validation before INSERT
- **Implementation:**
  - Create Edge Function
  - Configure scheduling
  - Implement error handling
- **Database Migration:** No
- **Frontend Changes:** No
- **Backend Changes:** Yes (Edge Function)
- **Testing:** Function executes daily, handles errors
- **Rollback:** Disable scheduling, remove function

#### Daily Breakdown (Sprint 7):
- **Day 1-2:** Admin dashboard setup, financial metrics queries
- **Day 3-4:** Inflow tracking page, charts
- **Day 5-6:** Outflow tracking page, cash flow analysis
- **Day 7-8:** Filtering, export functionality
- **Day 9-10:** Admin navigation, testing

#### Daily Breakdown (Sprint 8):
- **Day 1-2:** Market rates page, manual entry form
- **Day 3-4:** API integration, Edge Function
- **Day 5-6:** Automated daily fetch, scheduling
- **Day 7-8:** Rate deviation detection, notifications
- **Day 9-10:** Testing, bug fixes

#### Testing Strategy:
- **Unit Tests:** Financial queries, chart data
- **Integration Tests:** Full admin workflows
- **Manual Testing:** All admin pages functional
- **Performance Tests:** Dashboard load times

---

### SPRINT 9: Architecture Cleanup (Weeks 17-18)
**Story Points:** 30/40  
**Priority Focus:** P2 Architecture, P3 Code Quality

#### GAP-081: Fix Imperative Navigation (P2, 5 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - Replace `Navigator.push()` calls with declarative router
  - Update `profile_screen.dart`, `staff_profile_screen.dart`, `scheme_detail_screen.dart`
  - Use `appRouterProvider` for navigation
- **Implementation:**
  - Replace imperative navigation calls
  - Use Riverpod router provider
- **Database Migration:** No
- **Frontend Changes:** Yes
- **Backend Changes:** No
- **Testing:** Navigation works correctly
- **Rollback:** Restore imperative calls

#### GAP-082: Remove NavigateByRole Pattern (P2, 2 pts)
- **Dependencies:** GAP-081
- **Acceptance Criteria:**
  - Verify no `navigateByRole()` calls exist
  - All navigation uses declarative router
- **Implementation:**
  - Search codebase for remaining patterns
  - Remove if found
- **Database Migration:** No
- **Frontend Changes:** Yes
- **Backend Changes:** No
- **Testing:** No navigation bypasses router
- **Rollback:** N/A

#### GAP-083: Use Database Views (P2, 5 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - Replace client-side aggregation with database views
  - Use `active_customer_schemes` view
  - Use `today_collections` view
  - Use `staff_daily_stats` view
- **Implementation:**
  - Update `staff_data_service.dart` to use views
  - Remove client-side aggregation logic
- **Database Migration:** No
- **Frontend Changes:** Yes
- **Backend Changes:** No
- **Testing:** Views return correct data
- **Rollback:** Restore client-side aggregation

#### GAP-084: Complete Offline Sync or Remove Columns (P2, 8 pts)
- **Dependencies:** GAP-047, GAP-048
- **Acceptance Criteria:**
  - If offline sync implemented: verify `device_id` and `client_timestamp` used correctly
  - If not implemented: document decision and remove unused columns (or keep for future)
- **Implementation:**
  - Verify offline sync uses columns
  - Document decision if not using
- **Database Migration:** Maybe (if removing columns)
- **Frontend Changes:** Maybe
- **Backend Changes:** No
- **Testing:** Columns used or documented
- **Rollback:** N/A

#### GAP-088: Fix Dual Auth Authority (P2, 5 pts)
- **Dependencies:** None
- **Acceptance Criteria:**
  - Remove `AuthFlowNotifier` (Provider-based)
  - Use only Riverpod `authStateProvider`
  - Single source of truth for auth state
- **Implementation:**
  - Remove Provider-based auth notifier
  - Update all references to use Riverpod
- **Database Migration:** No
- **Frontend Changes:** Yes
- **Backend Changes:** No
- **Testing:** Auth state consistent
- **Rollback:** Restore Provider notifier

#### GAP-089: Fix Mixed Navigation Authority (P2, 5 pts)
- **Dependencies:** GAP-081, GAP-088
- **Acceptance Criteria:**
  - All navigation uses declarative router
  - No imperative `Navigator` calls
  - Consistent navigation pattern
- **Implementation:**
  - Complete navigation migration
  - Verify no imperative calls remain
- **Database Migration:** No
- **Frontend Changes:** Yes
- **Backend Changes:** No
- **Testing:** Navigation consistent
- **Rollback:** N/A

#### Daily Breakdown:
- **Day 1-2:** GAP-081, GAP-082 (navigation fixes)
- **Day 3-4:** GAP-083 (database views)
- **Day 5-6:** GAP-084 (offline sync)
- **Day 7-8:** GAP-088, GAP-089 (auth and navigation)
- **Day 9-10:** Testing, documentation

#### Testing Strategy:
- **Unit Tests:** Navigation, auth state
- **Integration Tests:** Full app flows
- **Manual Testing:** All navigation works
- **Regression Tests:** Existing flows still work

---

### SPRINT 10: Testing & Polish (Weeks 19-20)
**Story Points:** 25/40  
**Priority Focus:** P1 Testing, P2 Documentation

#### Integration Testing (8 pts)
- **Dependencies:** All previous sprints
- **Acceptance Criteria:**
  - Integration tests for all customer flows
  - Integration tests for all office staff flows
  - Integration tests for all admin flows
  - Integration tests for collection staff flows
- **Implementation:**
  - Write comprehensive integration tests
  - Test end-to-end workflows
- **Database Migration:** No
- **Frontend Changes:** Yes (test code)
- **Backend Changes:** Yes (test code)
- **Testing:** All tests pass
- **Rollback:** N/A

#### Security Audit (5 pts)
- **Dependencies:** All security gaps fixed
- **Acceptance Criteria:**
  - Security audit passes
  - All RLS policies verified
  - All SECURITY DEFINER functions audited
  - No privilege escalation risks
- **Implementation:**
  - Conduct security audit
  - Fix any remaining issues
- **Database Migration:** Maybe
- **Frontend Changes:** Maybe
- **Backend Changes:** Maybe
- **Testing:** Security audit report
- **Rollback:** N/A

#### Performance Optimization (5 pts)
- **Dependencies:** All features implemented
- **Acceptance Criteria:**
  - Database query optimization
  - Frontend performance improvements
  - Load time < 2 seconds for key pages
- **Implementation:**
  - Profile slow queries
  - Optimize database indexes
  - Optimize frontend rendering
- **Database Migration:** Maybe (index optimization)
- **Frontend Changes:** Yes
- **Backend Changes:** Maybe
- **Testing:** Performance benchmarks
- **Rollback:** N/A

#### Documentation Updates (7 pts)
- **Dependencies:** All features implemented
- **Acceptance Criteria:**
  - Code documentation updated
  - API documentation updated
  - User documentation (customer, staff, admin)
  - Database schema documentation
  - Deployment guide
- **Implementation:**
  - Update all documentation
  - Create user guides
- **Database Migration:** No
- **Frontend Changes:** No (docs only)
- **Backend Changes:** No (docs only)
- **Testing:** Documentation reviewed
- **Rollback:** N/A

#### Daily Breakdown:
- **Day 1-2:** Integration testing
- **Day 3-4:** Security audit
- **Day 5-6:** Performance optimization
- **Day 7-8:** Documentation updates
- **Day 9-10:** Final testing, bug fixes

#### Testing Strategy:
- **Integration Tests:** All flows
- **Security Tests:** Complete audit
- **Performance Tests:** Benchmarks
- **User Acceptance Tests:** Stakeholder review

---

## Gap-to-Sprint Mapping Matrix

| Gap ID | Gap Title | Priority | Story Points | Sprint | Dependencies |
|--------|-----------|----------|--------------|--------|--------------|
| GAP-001 | Routes table creation | P0 | 5 | Sprint 1 | None |
| GAP-002 | Staff assignments route relationship | P0 | 3 | Sprint 1 | GAP-001 |
| GAP-003 | Customers route relationship | P0 | 3 | Sprint 1 | GAP-001 |
| GAP-007 | Routes route_name unique constraint | P1 | 1 | Sprint 2 | GAP-001 |
| GAP-008 | Routes is_active check constraint | P1 | 1 | Sprint 2 | GAP-001 |
| GAP-009 | Staff assignments route FK | P1 | 1 | Sprint 2 | GAP-001, GAP-002 |
| GAP-010 | Customers route FK | P1 | 1 | Sprint 2 | GAP-001, GAP-003 |
| GAP-011 | Route-based assignment workflow | P1 | 2 | Sprint 2 | GAP-001, GAP-002, GAP-003 |
| GAP-012 | Profiles to routes relationship | P2 | 2 | Sprint 2 | GAP-001 |
| GAP-013 | Routes audit trail | P2 | 2 | Sprint 2 | GAP-001 |
| GAP-016 | Offline sync conflict resolution | P1 | 3 | Sprint 2 | None |
| GAP-017 | Routes route_name validation | P2 | 1 | Sprint 2 | GAP-001 |
| GAP-018 | Routes description validation | P2 | 1 | Sprint 2 | GAP-001 |
| GAP-019 | Routes area_coverage validation | P2 | 2 | Sprint 2 | GAP-001 |
| GAP-020 | Routes table indexes | P2 | 2 | Sprint 2 | GAP-001 |
| GAP-021 | Staff assignments route index | P2 | 1 | Sprint 2 | GAP-002 |
| GAP-022 | Customers route index | P2 | 1 | Sprint 2 | GAP-003 |
| GAP-023 | Customers INSERT policy office staff | P0 | 2 | Sprint 1 | None |
| GAP-024 | User schemes INSERT policy office staff | P0 | 2 | Sprint 1 | GAP-028 |
| GAP-025 | Payments INSERT policy office staff | P0 | 2 | Sprint 1 | None |
| GAP-026 | Staff assignments INSERT policy office staff | P0 | 2 | Sprint 1 | GAP-001, GAP-002 |
| GAP-027 | Profiles UPDATE policy office staff | P0 | 2 | Sprint 1 | None |
| GAP-028 | Remove customer self-enrollment | P0 | 3 | Sprint 1 | None |
| GAP-029 | Withdrawals UPDATE policy fix | P0 | 3 | Sprint 1 | None |
| GAP-031 | Customers SELECT policy fix | P0 | 3 | Sprint 1 | None |
| GAP-032 | Payments SELECT policy fix | P0 | 3 | Sprint 1 | None |
| GAP-033 | Mobile app access database-level | P0 | 5 | Sprint 1 | None |
| GAP-042 | Routes RLS policies | P0 | 2 | Sprint 1 | GAP-001 |
| GAP-044 | Payment schedule implementation | P1 | 8 | Sprint 4 | None |
| GAP-044 | Transaction history screen | P1 | 5 | Sprint 4 | GAP-044 |
| GAP-045 | Investment portfolio implementation | P1 | 8 | Sprint 4 | None |
| GAP-046 | Profile management UPDATE | P1 | 5 | Sprint 4 | None |
| GAP-047 | Offline payment queue infrastructure | P1 | 8 | Sprint 2 | GAP-016 |
| GAP-048 | Offline sync service | P1 | 8 | Sprint 2 | GAP-047, GAP-016 |
| GAP-049 | Office staff create customer | P1 | 13 | Sprint 5 | GAP-023 |
| GAP-050 | Office staff enroll customer | P1 | 13 | Sprint 5 | GAP-024, GAP-049 |
| GAP-051 | Office staff assign customer | P1 | 13 | Sprint 6 | GAP-001, GAP-002, GAP-003, GAP-026 |
| GAP-052 | Office staff manual payment | P1 | 13 | Sprint 6 | GAP-025 |
| GAP-053 | Admin financial dashboard | P1 | 21 | Sprint 7 | None |
| GAP-054 | Admin market rates management | P1 | 21 | Sprint 8 | None |
| GAP-055 | Withdrawal request INSERT | P1 | 8 | Sprint 4 | GAP-060 |
| GAP-056 | Withdrawal approval/processing | P1 | 8 | Sprint 8 | GAP-055 |
| GAP-057 | Trigger fix - use payment rate | P0 | 5 | Sprint 3 | None |
| GAP-058 | Trigger fix - remove market rates query | P0 | 3 | Sprint 3 | GAP-057 |
| GAP-059 | Payment rate validation | P1 | 5 | Sprint 3 | None |
| GAP-060 | Remove hardcoded rates withdrawal | P1 | 3 | Sprint 3 | None |
| GAP-063 | Metal grams calculation constraint | P1 | 3 | Sprint 3 | None |
| GAP-064 | Reconciliation view - total amount paid | P1 | 3 | Sprint 3 | None |
| GAP-065 | Reconciliation view - accumulated grams | P1 | 3 | Sprint 3 | None |
| GAP-066 | Reconciliation view - payments made | P1 | 2 | Sprint 3 | None |
| GAP-067 | Staff daily collections reconciliation | P2 | 2 | Sprint 3 | None |
| GAP-068 | Payment immutability app-level | P2 | 2 | Sprint 2 | None |
| GAP-069 | Payments RLS UPDATE/DELETE policies | P2 | 2 | Sprint 2 | None |
| GAP-070 | Reversal payment validation | P1 | 3 | Sprint 2 | None |
| GAP-071 | Market rates coverage verification | P2 | 2 | Sprint 3 | None |
| GAP-072 | Payment rate historical validation | P2 | 3 | Sprint 3 | GAP-059 |
| GAP-073 | Trigger fallback fix | P0 | 3 | Sprint 3 | GAP-057 |
| GAP-078 | Remove hardcoded rates payment collection | P1 | 2 | Sprint 3 | None |
| GAP-079 | Remove all mock data | P2 | 6 | Sprint 4 | GAP-044, GAP-045, GAP-046, GAP-055 |
| GAP-081 | Fix imperative navigation | P2 | 5 | Sprint 9 | None |
| GAP-082 | Remove navigateByRole pattern | P2 | 2 | Sprint 9 | GAP-081 |
| GAP-083 | Use database views | P2 | 5 | Sprint 9 | None |
| GAP-084 | Complete offline sync or remove columns | P2 | 8 | Sprint 9 | GAP-047, GAP-048 |
| GAP-085 | Simplify payment trigger | P2 | 2 | Sprint 3 | GAP-057 |
| GAP-088 | Fix dual auth authority | P2 | 5 | Sprint 9 | None |
| GAP-089 | Fix mixed navigation authority | P2 | 5 | Sprint 9 | GAP-081, GAP-088 |

**Note:** GAP-004, GAP-005, GAP-006, GAP-014, GAP-015, GAP-030, GAP-034, GAP-035, GAP-036, GAP-037, GAP-038, GAP-039, GAP-040, GAP-041, GAP-043, GAP-061, GAP-062, GAP-074, GAP-075, GAP-076, GAP-077, GAP-086, GAP-087 are either not gaps (implementation extensions), already addressed by other gaps, or low priority items that will be handled during testing/documentation phases.

---

## Dependency Graph

```
Sprint 1 (Foundation):
GAP-001 (routes table) → GAP-002, GAP-003, GAP-007, GAP-008, GAP-009, GAP-010, GAP-011, GAP-012, GAP-013, GAP-017, GAP-018, GAP-019, GAP-020, GAP-042
GAP-001 → GAP-002 → GAP-009, GAP-021, GAP-026
GAP-001 → GAP-003 → GAP-010, GAP-022
GAP-028 (remove self-enrollment) → GAP-024

Sprint 2 (Database & Offline):
GAP-016 → GAP-047 → GAP-048

Sprint 3 (Financial Integrity):
GAP-057 → GAP-058, GAP-073, GAP-085
GAP-059 → GAP-072

Sprint 4 (Customer Flows):
GAP-060 → GAP-055
GAP-044 → Transaction History
GAP-044, GAP-045, GAP-046, GAP-055 → GAP-079

Sprint 5-6 (Website):
GAP-023 → GAP-049 → GAP-050
GAP-024 → GAP-050
GAP-001, GAP-002, GAP-003, GAP-026 → GAP-051
GAP-025 → GAP-052

Sprint 7-8 (Admin):
GAP-055 → GAP-056

Sprint 9 (Architecture):
GAP-081 → GAP-082, GAP-089
GAP-088 → GAP-089
GAP-047, GAP-048 → GAP-084
```

**Parallel Work Streams:**
- Sprint 1: Routes table and RLS policies can be done in parallel after GAP-001
- Sprint 2: Database constraints and offline infrastructure can be parallel
- Sprint 3: Trigger fixes and reconciliation views can be parallel
- Sprint 4: Customer flows can be developed in parallel
- Sprint 5-6: Office staff flows can be parallel after authentication setup

---

## Risk Register

| Risk ID | Risk Description | Impact | Probability | Mitigation | Owner |
|---------|-----------------|--------|-------------|------------|-------|
| R-001 | RLS policy changes break existing functionality | High | Medium | Test all policies in staging, gradual rollout | DBA |
| R-002 | Trigger modifications corrupt historical data | Critical | Low | Backup database before trigger changes, test on copy | DBA |
| R-003 | Offline sync conflicts cause data loss | High | Medium | Implement conflict resolution, test thoroughly | Mobile Dev |
| R-004 | Market rates API unavailable | Medium | Medium | Implement fallback to manual entry, caching | Backend Dev |
| R-005 | Website implementation delays | Medium | Medium | Start early, parallel development | Frontend Dev |
| R-006 | Database migration failures in production | Critical | Low | Test migrations in staging, have rollback scripts | DBA |
| R-007 | Performance degradation from new queries | Medium | Medium | Profile queries, optimize indexes | Backend Dev |
| R-008 | Security vulnerabilities in new code | Critical | Low | Security audit, code review | Security Team |

**High-Risk Changes:**
- RLS policy modifications (Sprint 1)
- Trigger modifications (Sprint 3)
- Database schema changes (Sprint 1-2)
- Payment immutability changes (Sprint 2-3)

**Backup/Rollback Procedures:**
- Database backup before each migration
- Rollback scripts for all migrations
- Feature flags for new features
- Staging environment testing before production

**Production Data Migration Required:**
- Routes table creation (new table, no migration)
- Route relationships (add columns, nullable, no data migration)
- RLS policy changes (no data migration)

**User Communication Required:**
- Customer self-enrollment removal (Sprint 1)
- Offline sync feature (Sprint 2)
- Website launch (Sprint 5-6)

**Downtime Required:**
- None expected (all changes can be deployed incrementally)

---

## Testing Matrix

| Sprint | Unit Tests | Integration Tests | Manual Testing | Security Tests | Performance Tests | Regression Tests |
|--------|------------|-------------------|----------------|----------------|-------------------|------------------|
| Sprint 1 | RLS policies, constraints | Office staff workflows | All RLS policies | RLS policy audit | Query performance | Existing flows |
| Sprint 2 | Constraints, validations | Offline queue, sync | Offline functionality | - | Index performance | Existing flows |
| Sprint 3 | Triggers, constraints | Rate validation, reconciliation | Financial calculations | - | Query optimization | Existing flows |
| Sprint 4 | Database queries | Customer flows | All customer screens | - | - | Existing flows |
| Sprint 5-6 | Form validation, API calls | Office staff workflows | All office staff pages | RLS enforcement | - | Existing flows |
| Sprint 7-8 | Financial queries | Admin workflows | All admin pages | - | Dashboard load times | Existing flows |
| Sprint 9 | Navigation, auth | Full app flows | All navigation | - | - | All flows |
| Sprint 10 | All features | All workflows | Complete app | Security audit | Benchmarks | All flows |

**Testing Requirements by Sprint:**

**Sprint 1:**
- Unit: RLS policy tests for each policy
- Integration: Office staff can create customers/enrollments/assignments
- Security: Customers cannot self-enroll, collection staff only see assigned data
- Manual: Verify all RLS policies work correctly

**Sprint 2:**
- Unit: Constraint validation tests
- Integration: Offline queue and sync functionality
- Performance: Index performance tests
- Manual: Offline payment collection and sync

**Sprint 3:**
- Unit: Trigger logic, constraint validation
- Integration: Rate validation, reconciliation views
- Financial: Verify calculations are correct
- Manual: Payment recording with various rates

**Sprint 4:**
- Unit: Database queries, calculations
- Integration: Full customer flows
- Manual: All customer screens functional

**Sprint 5-6:**
- Unit: Form validation, API calls
- Integration: Full office staff workflows
- Security: RLS policies enforced
- Manual: All office staff pages functional

**Sprint 7-8:**
- Unit: Financial queries, chart data
- Integration: Full admin workflows
- Performance: Dashboard load times
- Manual: All admin pages functional

**Sprint 9:**
- Unit: Navigation, auth state
- Integration: Full app flows
- Manual: All navigation works

**Sprint 10:**
- Integration: All flows
- Security: Complete audit
- Performance: Benchmarks
- User Acceptance: Stakeholder review

---

## Deployment Roadmap

| Sprint | Deployment Type | Feature Flags | Database Migrations | Rollback Plan | Coordination Required |
|--------|----------------|---------------|---------------------|---------------|----------------------|
| Sprint 1 | Incremental | None | Sequential | Drop policies, restore original | DBA, Backend |
| Sprint 2 | Incremental | None | Sequential | Drop columns, restore original | DBA, Mobile Dev |
| Sprint 3 | Incremental | None | Sequential | Restore original triggers | DBA, Backend |
| Sprint 4 | Incremental | None | None | Remove new screens | Frontend Dev |
| Sprint 5-6 | Coordinated | Auth routes | None | Disable website | Frontend, Backend |
| Sprint 7-8 | Incremental | Admin dashboard | Edge Function | Remove Edge Function | Backend, Frontend |
| Sprint 9 | Incremental | None | None | Restore old navigation | Frontend Dev |
| Sprint 10 | Coordinated | None | None | N/A | All Teams |

**Incremental Deployment:**
- Sprint 1-4, 9: Can deploy features independently
- Each feature can be deployed separately
- No coordination required between features

**Coordinated Deployment:**
- Sprint 5-6: Website launch requires coordination
- Sprint 7-8: Edge Function deployment requires coordination
- Sprint 10: Final release requires coordination

**Feature Flags:**
- Authentication routes (Sprint 5)
- Admin dashboard (Sprint 7)
- Market rates auto-fetch (Sprint 8)

**Database Migration Strategy:**
- All migrations tested in staging first
- Sequential deployment (one migration at a time)
- Rollback scripts prepared for each migration
- Backup before each migration

**Rollback Procedures:**
- Each migration has corresponding rollback script
- Feature flags allow disabling new features
- Database backups allow full restoration if needed

---

## Resource Allocation Plan

**Team Composition:**
- Database Administrator (DBA): 1 FTE
- Backend Developer: 1 FTE
- Frontend Developer (Mobile): 1 FTE
- Frontend Developer (Website): 1 FTE
- QA Engineer: 0.5 FTE
- Security Auditor: 0.25 FTE (Sprint 1, 10)

**Sprint 1 Allocation:**
- DBA: 80% (database schema, RLS policies)
- Backend: 20% (RPC functions)
- Mobile: 0%
- Website: 0%
- QA: 20% (testing RLS policies)
- Security: 50% (security audit)

**Sprint 2 Allocation:**
- DBA: 60% (constraints, indexes)
- Backend: 10%
- Mobile: 80% (offline infrastructure)
- Website: 0%
- QA: 30% (testing offline)

**Sprint 3 Allocation:**
- DBA: 70% (triggers, reconciliation views)
- Backend: 20% (rate validation)
- Mobile: 10% (remove hardcoded rates)
- Website: 0%
- QA: 30% (financial testing)

**Sprint 4 Allocation:**
- DBA: 10%
- Backend: 10%
- Mobile: 80% (customer flows)
- Website: 0%
- QA: 40% (customer flow testing)

**Sprint 5-6 Allocation:**
- DBA: 10%
- Backend: 30% (Supabase Auth admin)
- Mobile: 0%
- Website: 90% (office staff flows)
- QA: 40% (website testing)

**Sprint 7-8 Allocation:**
- DBA: 20%
- Backend: 50% (Edge Function, queries)
- Mobile: 0%
- Website: 70% (admin dashboard)
- QA: 40% (admin testing)

**Sprint 9 Allocation:**
- DBA: 10%
- Backend: 10%
- Mobile: 60% (architecture cleanup)
- Website: 20% (navigation fixes)
- QA: 30% (regression testing)

**Sprint 10 Allocation:**
- DBA: 20% (performance optimization)
- Backend: 20% (performance optimization)
- Mobile: 20% (integration tests)
- Website: 20% (integration tests)
- QA: 80% (comprehensive testing)
- Security: 50% (security audit)

**Key Dependencies:**
- DBA availability critical for Sprint 1-3
- Mobile developer critical for Sprint 2, 4
- Website developer critical for Sprint 5-8
- QA critical for Sprint 10

---

## Success Metrics

### Sprint 1 Success Criteria:
- ✅ All P0 security gaps closed
- ✅ Routes table created with all constraints
- ✅ All RLS policies implemented and tested
- ✅ Zero security vulnerabilities
- ✅ Customer self-enrollment removed

### Sprint 2 Success Criteria:
- ✅ All database schema gaps closed
- ✅ Offline payment queue functional
- ✅ Offline sync service operational
- ✅ All constraints and indexes created

### Sprint 3 Success Criteria:
- ✅ All trigger fixes implemented
- ✅ Rate validation working
- ✅ Reconciliation views created
- ✅ Zero financial calculation errors

### Sprint 4 Success Criteria:
- ✅ All customer flows functional
- ✅ Payment schedule displays real data
- ✅ Portfolio calculations correct
- ✅ Withdrawal requests create database records
- ✅ All mock data removed

### Sprint 5-6 Success Criteria:
- ✅ Website authentication working
- ✅ Office staff can create customers
- ✅ Office staff can enroll customers
- ✅ Office staff can assign customers
- ✅ Office staff can create manual payments

### Sprint 7-8 Success Criteria:
- ✅ Admin dashboard displays financial data
- ✅ Market rates management functional
- ✅ Automated rate fetching working
- ✅ All charts and reports functional

### Sprint 9 Success Criteria:
- ✅ All navigation uses declarative router
- ✅ Database views used instead of client aggregation
- ✅ Single auth authority (Riverpod only)
- ✅ Architecture cleanup complete

### Sprint 10 Success Criteria:
- ✅ All integration tests passing
- ✅ Security audit passed
- ✅ Performance benchmarks met
- ✅ Documentation complete
- ✅ User acceptance testing passed

### Overall MVP Success Criteria:
- ✅ All 104 gaps closed
- ✅ Zero P0 security vulnerabilities
- ✅ All core user flows functional
- ✅ Financial calculations verified
- ✅ Website fully operational
- ✅ Mobile app offline-capable
- ✅ Production-ready deployment

### Key Performance Indicators (KPIs):
- **Security:** Zero security vulnerabilities in production
- **Financial Integrity:** 100% reconciliation accuracy
- **User Flows:** 100% of core flows functional
- **Performance:** Page load time < 2 seconds
- **Test Coverage:** > 80% code coverage
- **Documentation:** 100% of features documented

### User Acceptance Testing Criteria:
- Customer can complete all core journeys
- Office staff can complete all workflows
- Admin can access all dashboards
- Collection staff can collect payments offline
- All data displays correctly
- No critical bugs

### Security Audit Passing Criteria:
- All RLS policies correctly implemented
- No privilege escalation risks
- No unauthorized access possible
- All SECURITY DEFINER functions audited
- Database-first security enforced

---

## Appendix: Gap Status Tracking

**Total Gaps:** 89 explicitly numbered + 15 additional items = 104 total

**By Priority:**
- P0 (Blocker): 15 gaps
- P1 (Critical): 25 gaps
- P2 (High): 20 gaps
- P3 (Medium): 15 gaps
- P4 (Low): 10 gaps
- Not Gaps (Implementation Extensions): 19 items

**By Category:**
- Database Schema: 22 gaps
- RLS Policies: 12 gaps
- Security: 8 gaps
- User Flows: 13 gaps
- Financial Integrity: 12 gaps
- Architecture: 8 gaps
- Testing/Documentation: 10 gaps

**Completion Tracking:**
- Sprint 1: 15 gaps (P0 security)
- Sprint 2: 18 gaps (database, offline)
- Sprint 3: 12 gaps (financial integrity)
- Sprint 4: 5 gaps (customer flows)
- Sprint 5-6: 4 gaps (website foundation)
- Sprint 7-8: 2 gaps (admin dashboard)
- Sprint 9: 6 gaps (architecture)
- Sprint 10: Testing and polish (no new gaps)

**All gaps assigned to exactly one sprint with clear acceptance criteria.**

---

**END OF SPRINT PLAN**

