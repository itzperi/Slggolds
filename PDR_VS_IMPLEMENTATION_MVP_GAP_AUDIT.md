# PDR vs Implementation — MVP Gap Audit

**Date:** [To be completed]  
**Audit Type:** Implementation Gap Analysis  
**Purpose:** Authoritative record comparing actual implementation against Project Definition Report (PDR) requirements  
**Scope:** Phase 1 MVP features only (as defined in PDR Section 2: Scope Definition)

---

## Audit Context

**Source of Truth:** `PROJECT_DEFINITION_REPORT.md` (PDR)  
**Implementation Reference:** Current codebase (Flutter mobile app, Next.js website, Supabase backend)

**Binding Requirements:**
- Supabase backend (PostgreSQL, Auth, RLS)
- Database-first security (RLS, triggers, RPC functions)
- Append-only financial records (payment immutability enforced)
- Offline-first payment collection (mobile app)
- Strict role separation (customer, collection staff, office staff, admin)
- Phase 1 MVP scope only (no out-of-scope features)

**Audit Methodology:**
- Compare PDR requirements with actual implementation
- Identify gaps, deviations, and violations
- Reference real code artifacts (file paths, line numbers, functions)
- Factual reporting only (no recommendations, timelines, or prioritization)

---

## 1. Database & Data Model Gaps

### 1.1 Missing Tables

**GAP-001: `routes` table is missing**
- **PDR Reference:** Section 8 - Data Model Overview, Key Entities table (row: **routes**)
- **PDR Definition:**
  - Primary Key: `id` (UUID)
  - Key Attributes: `route_name`, `description`, `area_coverage`, `is_active`
  - Ownership: Admin/Office staff own routes
  - Access Rules: Office staff can create/read/update routes. Admin can create/read/update/deactivate all routes. RLS enforced (if implemented).
- **Implementation Status:** Table does not exist in `supabase_schema.sql`
- **Impact:** 
  - Cannot assign customers to routes (required for office staff workflow: "Assign Customer to Collection Staff by Route" - PDR Section 4, Office Staff Flow 2)
  - Route management features on website cannot be implemented
  - Staff assignment by route is not possible

---

### 1.2 Missing Columns

**GAP-002: Missing relationship between `routes` and `staff_assignments`**
- **PDR Reference:** Section 8 - Data Model Overview, Staff Assignments row (implies route-based assignment)
- **PDR Definition:** Office Staff Flow 2 (Section 4) requires assigning customers to staff "by Route"
- **Implementation Status:** `staff_assignments` table exists but has no `route_id` foreign key
- **Missing Column:** `staff_assignments.route_id` (UUID, FK to routes.id, nullable)
- **Impact:** Cannot implement route-based staff assignment workflow required by PDR

**GAP-003: Missing relationship between `routes` and `customers`**
- **PDR Reference:** Section 8 - Data Model Overview, Office Staff Flow 2 (Section 4) requires route-based customer assignment
- **Implementation Status:** `customers` table has no route reference
- **Missing Column:** `customers.route_id` (UUID, FK to routes.id, nullable)
- **Impact:** Cannot track which route a customer belongs to, preventing route-based filtering and reporting

**GAP-004: Missing `payments.notes` column (implementation has it, but PDR doesn't explicitly require it)**
- **PDR Reference:** Section 8 - Data Model Overview, **payments** row (does not list `notes`)
- **Implementation Status:** Column exists in `supabase_schema.sql` line 253: `notes TEXT`
- **Note:** This is an implementation extension, not a gap. Column is present but not required by PDR.

**GAP-005: Missing `user_schemes.completed_date` column verification**
- **PDR Reference:** Section 8 - Data Model Overview, **user_schemes** row (does not explicitly list `completed_date`)
- **Implementation Status:** Column exists in `supabase_schema.sql` line 203: `completed_date DATE`
- **PDR Definition:** `user_schemes` should track status transitions (active/paused/completed/mature/cancelled)
- **Note:** Column exists but may need validation against status enum transitions

**GAP-006: Missing `withdrawals.approved_at` and `withdrawals.processed_at` columns verification**
- **PDR Reference:** Section 8 - Data Model Overview, **withdrawals** row (lists `approved_by`, `final_amount`, `final_grams`, but does not explicitly list `approved_at`, `processed_at`)
- **Implementation Status:** Columns exist in `supabase_schema.sql` lines 312-313: `approved_at TIMESTAMPTZ`, `processed_at TIMESTAMPTZ`
- **Note:** Columns exist but PDR does not explicitly require them. May be implementation extension.

---

### 1.3 Missing Constraints

**GAP-007: Missing unique constraint on `routes.route_name`**
- **PDR Reference:** Section 8 - Data Model Overview, **routes** row (route names should be unique)
- **Implementation Status:** Table does not exist, constraint cannot be verified
- **Missing Constraint:** `CONSTRAINT routes_route_name_unique UNIQUE (route_name)`
- **Impact:** If routes table is created without this constraint, duplicate route names will be allowed, causing data integrity issues

**GAP-008: Missing check constraint on `routes.is_active` (if routes table existed)**
- **PDR Reference:** Section 8 - Data Model Overview, **routes** row (boolean `is_active` field)
- **Implementation Status:** Table does not exist, constraint cannot be verified
- **Missing Constraint:** Standard boolean check (typically defaults to `true`)
- **Impact:** If routes table is created without proper defaults, routes may be inactive by default, breaking workflows

**GAP-009: Missing foreign key constraint for `routes.id` → `staff_assignments.route_id` (when routes table exists)**
- **PDR Reference:** Section 8 - Data Model Overview, Relationships section (route-based assignments)
- **Implementation Status:** Both tables and relationship do not exist
- **Missing Constraint:** `staff_assignments.route_id` → `routes.id` (ON DELETE SET NULL)
- **Impact:** Cannot enforce referential integrity for route-based staff assignments

**GAP-010: Missing foreign key constraint for `routes.id` → `customers.route_id` (when routes table exists)**
- **PDR Reference:** Section 8 - Data Model Overview, Office Staff Flow 2 (route-based customer assignment)
- **Implementation Status:** Both tables and relationship do not exist
- **Missing Constraint:** `customers.route_id` → `routes.id` (ON DELETE SET NULL)
- **Impact:** Cannot enforce referential integrity for route-based customer assignments

---

### 1.4 Broken or Missing Relationships

**GAP-011: Missing `routes` table breaks route-based assignment workflow**
- **PDR Reference:** Section 4 - Functional Requirements, Office Staff Flow 2: "Assign Customer to Collection Staff by Route"
- **PDR Definition:**
  - Step 2: "Office staff selects a route from the route list"
  - Step 3: "System displays customers assigned to the selected route"
  - Step 4: "Office staff selects a customer from the route's customer list"
  - Step 5: "System displays available collection staff members"
  - Step 6: "Office staff selects a collection staff member and confirms assignment"
- **Implementation Status:** `routes` table does not exist. No route-based filtering possible.
- **Impact:** 
  - Cannot implement PDR Section 4, Office Staff Flow 2
  - Office staff cannot assign customers to staff by route
  - Route-based reporting and analytics cannot be implemented

**GAP-012: Missing relationship between `profiles` and `routes` (if routes had staff assignments)**
- **PDR Reference:** Section 8 - Data Model Overview, implies routes can have multiple staff members
- **Implementation Status:** No relationship exists (routes table missing)
- **Missing Relationship:** Many-to-many between `profiles` (staff) and `routes` via intermediate table or direct `profiles.route_id` FK
- **Impact:** Cannot track which staff members are assigned to which routes

---

### 1.5 Auditability and Financial Integrity Gaps

**GAP-013: Missing audit trail for `routes` table (when created)**
- **PDR Reference:** Section 8 - Data Model Overview, Audit immutability requirements
- **Implementation Status:** Table does not exist
- **Missing Columns:** `created_at`, `updated_at`, `created_by` (FK to profiles), `updated_by` (FK to profiles)
- **Impact:** Cannot track who created/modified routes, when routes were created/modified, preventing audit compliance

**GAP-014: Missing `payments.reversal_reason` in PDR (but exists in implementation)**
- **PDR Reference:** Section 8 - Data Model Overview, **payments** row (lists `is_reversal`, `reverses_payment_id`, but does not explicitly list `reversal_reason`)
- **Implementation Status:** Column exists in `supabase_schema.sql` line 250: `reversal_reason TEXT`
- **Note:** This is an implementation extension (good practice) but not required by PDR. No gap.

**GAP-015: Missing `payments.server_timestamp` in PDR (but exists in implementation)**
- **PDR Reference:** Section 8 - Data Model Overview, **payments** row (does not list `server_timestamp`)
- **Implementation Status:** Column exists in `supabase_schema.sql` line 258: `server_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()`
- **PDR Definition:** Payments must have authoritative server timestamp for audit
- **Note:** Column exists but PDR does not explicitly require it. Implementation has good practice for audit integrity.

**GAP-016: Missing reconciliation field for offline sync conflicts**
- **PDR Reference:** Section 4 - Functional Requirements, Offline / Retry Behavior (conflict resolution strategy required)
- **Implementation Status:** `payments` table has `device_id` and `client_timestamp` for offline sync, but no explicit conflict resolution marker
- **Missing Column:** `payments.sync_status` (enum: 'pending', 'synced', 'conflict', 'resolved') or `payments.sync_conflict_id` (FK to conflicting payment)
- **Impact:** Cannot explicitly track payment sync status or resolve conflicts when multiple devices record the same payment offline

---

### 1.6 Data Type and Validation Gaps

**GAP-017: Missing validation for `routes.route_name` format (when routes table is created)**
- **PDR Reference:** Section 8 - Data Model Overview, **routes** row (route_name should be validated)
- **Implementation Status:** Table does not exist, validation cannot be verified
- **Missing Constraint:** `CONSTRAINT routes_route_name_format CHECK (char_length(route_name) >= 2 AND char_length(route_name) <= 100)`
- **Impact:** Invalid route names (empty, too long) will be allowed, causing UI and reporting issues

**GAP-018: Missing validation for `routes.description` length (when routes table is created)**
- **PDR Reference:** Section 8 - Data Model Overview, **routes** row (description should be validated)
- **Implementation Status:** Table does not exist, validation cannot be verified
- **Missing Constraint:** `CONSTRAINT routes_description_length CHECK (description IS NULL OR char_length(description) <= 500)`
- **Impact:** Extremely long descriptions will be allowed, causing UI display issues

**GAP-019: Missing validation for `routes.area_coverage` format (when routes table is created)**
- **PDR Reference:** Section 8 - Data Model Overview, **routes** row (area_coverage should be validated)
- **Implementation Status:** Table does not exist, validation cannot be verified
- **Missing Constraint:** Validation based on expected format (text, JSON, or geographic boundaries)
- **Impact:** Invalid area coverage data will be allowed, preventing accurate route filtering and mapping

---

### 1.7 Index Gaps

**GAP-020: Missing indexes for `routes` table queries (when routes table is created)**
- **PDR Reference:** Section 8 - Data Model Overview, **routes** row (implies frequent queries by route_name, is_active)
- **Implementation Status:** Table does not exist, indexes cannot be verified
- **Missing Indexes:**
  - `CREATE INDEX idx_routes_route_name ON routes(route_name);`
  - `CREATE INDEX idx_routes_active ON routes(is_active) WHERE is_active = true;`
  - `CREATE INDEX idx_routes_created_at ON routes(created_at);`
- **Impact:** Route-based queries will be slow, especially when filtering active routes or searching by name

**GAP-021: Missing composite index for route-based staff assignment queries**
- **PDR Reference:** Section 4 - Functional Requirements, Office Staff Flow 2 (route-based staff assignment)
- **Implementation Status:** Cannot create index (routes table and relationship missing)
- **Missing Index:** `CREATE INDEX idx_staff_assignments_route_active ON staff_assignments(route_id, is_active) WHERE is_active = true;`
- **Impact:** Route-based staff assignment queries will be slow when filtering by route and active status

**GAP-022: Missing composite index for route-based customer queries**
- **PDR Reference:** Section 4 - Functional Requirements, Office Staff Flow 2 (route-based customer filtering)
- **Implementation Status:** Cannot create index (routes table and relationship missing)
- **Missing Index:** `CREATE INDEX idx_customers_route_active ON customers(route_id) WHERE route_id IS NOT NULL;`
- **Impact:** Route-based customer filtering will be slow when filtering customers by route

---

### 1.8 Summary of Critical Gaps

**Critical Missing Components:**
1. **`routes` table** (GAP-001) - Blocks entire route-based workflow required by PDR Section 4, Office Staff Flow 2
2. **Route relationships** (GAP-002, GAP-003, GAP-011) - Cannot assign customers/staff to routes
3. **Route constraints and indexes** (GAP-007, GAP-008, GAP-020) - Data integrity and performance issues when routes table is created

**Medium Priority Gaps:**
4. **Offline sync conflict resolution** (GAP-016) - May cause data inconsistency in offline payment collection
5. **Route auditability** (GAP-013) - Cannot track route changes for compliance

**Low Priority / Implementation Extensions:**
6. **Additional columns in payments** (GAP-014, GAP-015) - Present in implementation but not required by PDR (good practice)

---

## 2. Authentication, Authorization & RLS Gaps

### 2.1 Missing RLS Policies

**GAP-023: Missing INSERT policy for `customers` table (office staff should create customers)**
- **PDR Reference:** Section 8 - Data Model Overview, Office Staff Access Constraints: "Office staff can read/update all customer records. Can create new customer records."
- **PDR Reference:** Section 4 - Functional Requirements, Office Staff Flow 1: "Create New Customer" - Office staff creates customer records during registration
- **Implementation Status:** `customers` table has SELECT and UPDATE policies, but no INSERT policy exists in `supabase_schema.sql` lines 727-757
- **Missing Policy:** `CREATE POLICY "Office staff can create customers" ON customers FOR INSERT WITH CHECK (is_staff() AND staff_type = 'office');`
- **Impact:** Office staff cannot create customer records via Supabase API, violating PDR requirement. Application code attempting customer creation will fail with RLS policy violation.

**GAP-024: Missing INSERT policy for `user_schemes` table for office staff**
- **PDR Reference:** Section 8 - Data Model Overview, Office Staff Access Constraints: "Office staff can create enrollments for any customer."
- **PDR Reference:** Section 4 - Functional Requirements, Office Staff Flow 4: "Enroll Customer in Scheme" - Office staff creates enrollments on behalf of customers
- **Implementation Status:** `user_schemes` table has INSERT policy allowing customers to self-enroll (line 822-829) and admin, but no explicit policy for office staff
- **Current Policy:** `CREATE POLICY "Customers can enroll in schemes" ON user_schemes FOR INSERT WITH CHECK (customer_id IN (SELECT id FROM customers WHERE profile_id = get_user_profile()) OR is_admin());`
- **Missing Policy:** Policy should explicitly allow office staff to create enrollments for any customer
- **Impact:** Office staff cannot create enrollments for customers via Supabase API, violating PDR requirement. Enrollment creation will fail with RLS policy violation unless admin creates it.

**GAP-025: Missing INSERT policy for `payments` table for office staff (office collections with staff_id = NULL)**
- **PDR Reference:** Section 8 - Data Model Overview, Office Staff Access Constraints: "Office staff can insert payments for office collections (`staff_id = NULL`)."
- **PDR Reference:** Section 4 - Functional Requirements, Office Staff Flow 3: "Manual Payment Entry (Office Collections)" - Office staff creates payments with `staff_id = NULL`
- **Implementation Status:** `payments` table has INSERT policy for staff creating payments for assigned customers (lines 862-872), but no policy for office staff creating payments with `staff_id = NULL`
- **Current Policy:** `CREATE POLICY "Staff can insert payments for assigned customers" ON payments FOR INSERT WITH CHECK (is_staff() AND (is_admin() OR (staff_id = get_user_profile() AND is_current_staff_assigned_to_customer(customer_id))));`
- **Missing Policy:** Policy should allow office staff to insert payments with `staff_id = NULL` for any customer
- **Impact:** Office staff cannot create office collection payments via Supabase API, violating PDR requirement. Payment creation will fail with RLS policy violation.

**GAP-026: Missing INSERT policy for `staff_assignments` table for office staff**
- **PDR Reference:** Section 8 - Data Model Overview, Office Staff Access Constraints: "Office staff can create/read/update assignments (if business rule allows)."
- **PDR Reference:** Section 4 - Functional Requirements, Office Staff Flow 2: "Assign Customer to Collection Staff by Route" - Office staff creates assignments
- **Implementation Status:** `staff_assignments` table has SELECT policy for staff (line 957-962) and ALL policy for admin (line 965-968), but no INSERT/UPDATE policy for office staff
- **Missing Policy:** Policy should allow office staff to create and update assignments (if business rule permits)
- **Impact:** Office staff cannot create staff assignments via Supabase API, violating PDR requirement. Assignment creation will fail with RLS policy violation unless admin creates it.

**GAP-027: Missing UPDATE policy for `profiles` table for office staff (to update customer profiles)**
- **PDR Reference:** Section 8 - Data Model Overview, Office Staff Access Constraints: "Office staff can read all customer profiles. Can update customer profiles (limited fields)."
- **Implementation Status:** `profiles` table has UPDATE policy for users updating own profile (lines 712-716) and ALL policy for admin (lines 720-724), but no policy for office staff updating customer profiles
- **Current Policy:** `CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());`
- **Missing Policy:** Policy should allow office staff to update customer profiles (limited fields: name, phone) with appropriate validation
- **Impact:** Office staff cannot update customer profile information via Supabase API, violating PDR requirement. Profile updates will fail with RLS policy violation.

---

### 2.2 Incorrect or Overly Permissive RLS Policies

**GAP-028: `user_schemes` INSERT policy allows customer self-enrollment (violates PDR requirement)**
- **PDR Reference:** Section 8 - Data Model Overview, Customer Access Constraints: "Customers can read own enrollments (read-only). Cannot create enrollments (enrollment performed by office staff)."
- **PDR Reference:** Section 2 - Scope Definition, OUT OF SCOPE: "Customer self-enrollment" explicitly excluded from Phase 1
- **Implementation Status:** Policy at `supabase_schema.sql` lines 822-829 allows customers to enroll themselves: `WITH CHECK (customer_id IN (SELECT id FROM customers WHERE profile_id = get_user_profile()) OR is_admin());`
- **Violation:** Policy allows any authenticated customer to create their own enrollment by matching `customer_id` to their own customer record
- **Impact:** Customers can bypass business rule requiring office staff enrollment. Violates PDR scope definition and access constraints. Creates data integrity risk (customers may enroll with incorrect parameters).

**GAP-029: `withdrawals` UPDATE policy allows any staff to update withdrawal status (should only be assigned staff or admin)**
- **PDR Reference:** Section 8 - Data Model Overview, Collection Staff Access Constraints: "Staff can read assigned customers' withdrawals. Can update withdrawal status (approve/reject/process) for assigned customers."
- **PDR Reference:** Section 8 - Data Model Overview, Office Staff Access Constraints: "Office staff can read all withdrawals. Can update withdrawal status (if admin or if assigned to customer)."
- **Implementation Status:** Policy at `supabase_schema.sql` lines 925-928 allows any staff to update any withdrawal: `CREATE POLICY "Staff can update withdrawal status" ON withdrawals FOR UPDATE USING (is_staff()) WITH CHECK (is_staff());`
- **Violation:** Policy checks only `is_staff()` (which includes both collection and office staff), but does not verify staff is assigned to the customer
- **Impact:** Any staff member (collection or office) can approve/reject/process withdrawals for customers they are not assigned to, violating PDR access constraints. Creates authorization bypass risk.

**GAP-030: `staff_metadata` SELECT policy allows unauthenticated access (security risk)**
- **PDR Reference:** Section 8 - Data Model Overview, Staff Metadata Access Rules: "Unauthenticated users can lookup staff_code → email (for login). RLS enforced."
- **Implementation Status:** Policy at `supabase_schema.sql` lines 764-766 allows all SELECT without authentication: `CREATE POLICY "Allow staff_code lookup for login" ON staff_metadata FOR SELECT USING (true);`
- **Violation:** While this is intentional for login resolution, the policy allows unauthenticated users to query all staff metadata, potentially exposing sensitive information beyond `staff_code` and `email`
- **Impact:** Unauthenticated users can enumerate all staff records, potentially exposing `staff_code`, `staff_type`, `daily_target_amount`, `is_active`, and other metadata. Security risk if application code selects more than `staff_code` and `email` for login.

**GAP-031: `customers` SELECT policy allows all staff to read all customers (should filter by assignment for collection staff)**
- **PDR Reference:** Section 8 - Data Model Overview, Collection Staff Access Constraints: "Staff can read assigned customers only (filtered by `staff_assignments` where `is_active = true`). Cannot view unassigned customers."
- **Implementation Status:** Policy at `supabase_schema.sql` lines 744-751 allows all staff to read all customers: `USING (is_staff() AND (is_admin() OR is_staff_assigned_to_customer(id)));`
- **Note:** Policy correctly checks `is_staff_assigned_to_customer(id)`, but also has a separate policy at lines 730-735 that allows customers to read own record OR all staff: `USING (profile_id = get_user_profile() OR is_staff());`
- **Violation:** The policy at line 730 allows `is_staff()` without checking assignment, effectively bypassing the assignment check in the separate policy
- **Impact:** Collection staff can read all customer records, not just assigned customers, violating PDR access constraints. Policy priority/logic allows staff to bypass assignment filtering.

**GAP-032: `payments` SELECT policy allows all staff to read all payments (should filter by assignment for collection staff)**
- **PDR Reference:** Section 8 - Data Model Overview, Collection Staff Access Constraints: "Staff can insert/read payments for assigned customers only. Cannot view unassigned customers' payments."
- **Implementation Status:** Policy at `supabase_schema.sql` lines 851-858 allows all staff to read all payments: `USING (customer_id IN (SELECT id FROM customers WHERE profile_id = get_user_profile()) OR is_staff());`
- **Violation:** Policy checks `is_staff()` without verifying assignment, allowing any staff to read all customer payments
- **Impact:** Collection staff can read payments for customers they are not assigned to, violating PDR access constraints. Creates data access violation risk.

---

### 2.3 Frontend-Only Security Assumptions

**GAP-033: Mobile app access check enforced in frontend code instead of database RLS**
- **PDR Reference:** Section 8 - Data Model Overview, Authorization Enforcement: "Database Level: Row Level Security (RLS) policies enforced on all tables in PostgreSQL"
- **PDR Reference:** Section 3 - User Roles & Permissions, Collection Staff: Mobile app access restricted to collection staff (`staff_type = 'collection'`)
- **Implementation Status:** Mobile app access check implemented in `lib/services/role_routing_service.dart` lines 79-151: `checkMobileAppAccess()` function queries database and throws exception if admin or office staff
- **Violation:** Security check is performed in application code, not at database level. RLS policies do not prevent office staff or admin from querying mobile app data if they bypass frontend checks
- **Impact:** If application code is bypassed (e.g., direct API calls, modified client), office staff or admin can access mobile app data. Violates "database-first security" architecture principle. Frontend-only security is bypassable.

**GAP-034: Role validation performed in frontend code instead of relying solely on RLS**
- **PDR Reference:** Section 8 - Data Model Overview, Authorization Enforcement: "All API requests validated against RLS policies (Supabase enforces RLS on all queries)"
- **Implementation Status:** Role validation in `lib/services/role_routing_service.dart` lines 15-41 and `lib/main.dart` lines 261-265 queries `profiles` table and validates role in application code
- **Violation:** While RLS policies exist, application code performs additional role checks that could be inconsistent with RLS policies. Creates dual authority (RLS and application code) for role resolution
- **Impact:** Potential inconsistency between RLS policies and application code role checks. If RLS policy is updated but application code is not, security may be weakened or access may be incorrectly denied.

**GAP-035: Staff type check (`staff_type = 'collection'`) performed in frontend instead of database constraint**
- **PDR Reference:** Section 8 - Data Model Overview, Role Resolution: "Staff type determined by `staff_metadata.staff_type` column (enum: 'collection', 'office')."
- **Implementation Status:** Staff type check in `lib/services/role_routing_service.dart` lines 133-140 queries `staff_metadata` and validates `staff_type = 'collection'` in application code
- **Violation:** No database-level constraint or RLS policy prevents office staff from accessing collection staff data if frontend check is bypassed
- **Impact:** Office staff can access collection staff data (payments, assignments, customers) if they bypass frontend validation. Violates role separation requirement.

---

### 2.4 SECURITY DEFINER Function Risks

**GAP-036: `get_staff_email_by_code()` SECURITY DEFINER function allows unauthenticated access**
- **PDR Reference:** Section 8 - Data Model Overview, Authentication Rules: Supabase Auth required for all authenticated operations
- **Implementation Status:** Function at `supabase_schema.sql` lines 639-651 uses `SECURITY DEFINER` and allows unauthenticated access (no `auth.uid()` check in function body)
- **Violation:** Function bypasses RLS and runs with postgres privileges, but can be called without authentication. While intended for login resolution, this creates a privilege escalation risk if called maliciously
- **Impact:** Unauthenticated users can call this function to enumerate staff email addresses by brute-forcing `staff_code` values. Creates information disclosure risk. Function should have rate limiting or IP-based restrictions.

**GAP-037: `get_customer_profile_for_staff()` SECURITY DEFINER function has internal validation but no explicit authentication check**
- **PDR Reference:** Section 8 - Data Model Overview, Authorization Enforcement: All operations must verify authentication
- **Implementation Status:** Function at `supabase_schema.sql` lines 659-678 uses `SECURITY DEFINER` and checks `auth.uid()` internally, but does not explicitly reject unauthenticated calls at function entry
- **Violation:** Function relies on `auth.uid()` being NULL for unauthenticated users, but does not explicitly validate authentication state before processing
- **Impact:** If called by unauthenticated user, function will return empty result set (due to `auth.uid()` being NULL), which is safe but inefficient. Should explicitly reject unauthenticated calls at function entry for clarity and performance.

**GAP-038: Multiple SECURITY DEFINER helper functions bypass RLS without explicit documentation of risks**
- **PDR Reference:** Section 8 - Data Model Overview, Authorization Enforcement: Database-first security with RLS enforced on all tables
- **Implementation Status:** Functions `get_user_profile()`, `get_user_role()`, `is_admin()`, `is_staff()`, `is_staff_assigned_to_customer()`, `is_current_staff_assigned_to_customer()` all use `SECURITY DEFINER` (lines 575-632)
- **Violation:** While necessary to avoid RLS recursion, these functions create a privilege escalation surface. If any function has a logic error, it could bypass RLS in unintended ways
- **Impact:** Changes to these functions could inadvertently weaken RLS enforcement. Functions should be carefully audited and have minimal logic to reduce risk surface.

---

### 2.5 Missing Database Constraints for Authorization

**GAP-039: No database constraint preventing role changes after initial creation**
- **PDR Reference:** Section 8 - Data Model Overview, Role Resolution: "User role determined by `profiles.role` column (enum: 'customer', 'staff', 'admin')."
- **PDR Reference:** Section 3 - User Roles & Permissions, Role Hierarchy: Strict separation between customer, staff, and admin roles
- **Implementation Status:** `profiles` table has `role` column (enum type) but no trigger or constraint preventing role changes after initial profile creation
- **Missing Constraint:** Trigger or check constraint preventing UPDATE of `profiles.role` except by admin or during initial profile creation
- **Impact:** Users or application code could change their own role (e.g., customer → admin) if RLS policy allows UPDATE. Violates role immutability requirement. Creates privilege escalation risk.

**GAP-040: No database constraint preventing staff_type changes after initial creation**
- **PDR Reference:** Section 8 - Data Model Overview, Role Resolution: "Staff type determined by `staff_metadata.staff_type` column (enum: 'collection', 'office')."
- **PDR Reference:** Section 3 - User Roles & Permissions, Collection Staff vs Office Staff: Strict separation between collection and office staff
- **Implementation Status:** `staff_metadata` table has `staff_type` column (TEXT with CHECK constraint) but no trigger preventing staff_type changes after initial creation
- **Missing Constraint:** Trigger or check constraint preventing UPDATE of `staff_metadata.staff_type` except by admin
- **Impact:** Staff members could change their own staff_type (e.g., office → collection) to gain mobile app access if RLS policy allows UPDATE. Violates staff type immutability requirement. Creates privilege escalation risk.

**GAP-041: No database-level constraint preventing admin access to mobile app**
- **PDR Reference:** Section 3 - User Roles & Permissions, Administrator: Admin role is website-only, cannot access mobile app
- **Implementation Status:** Mobile app access check is performed in frontend (`lib/services/role_routing_service.dart` line 123: `if (role == 'admin') throw Exception(...)`)
- **Missing Constraint:** No database-level check (trigger or RPC function) preventing admin from accessing mobile app data if frontend check is bypassed
- **Impact:** Admin users can access mobile app data if they bypass frontend validation or use direct API calls. Violates role separation requirement.

---

### 2.6 Missing RLS Policies for Routes Table (When Created)

**GAP-042: Missing RLS policies for `routes` table (referenced in PDR but table missing)**
- **PDR Reference:** Section 8 - Data Model Overview, **routes** row: "RLS enforced (if implemented)."
- **PDR Reference:** Section 8 - Data Model Overview, Office Staff Access Constraints: Office staff can create/read/update routes
- **Implementation Status:** `routes` table does not exist, but when created, will need RLS policies
- **Missing Policies:**
  - `CREATE POLICY "Office staff can manage routes" ON routes FOR ALL USING (is_staff() AND staff_type = 'office') WITH CHECK (is_staff() AND staff_type = 'office');`
  - `CREATE POLICY "Admin can manage routes" ON routes FOR ALL USING (is_admin()) WITH CHECK (is_admin());`
  - `CREATE POLICY "Staff can read routes" ON routes FOR SELECT USING (is_staff());`
- **Impact:** When routes table is created, it will have no RLS policies, allowing unrestricted access or blocking all access. Violates "RLS enforced on all tables" requirement.

---

### 2.7 Summary of Critical Authorization Gaps

**Critical Violations:**
1. **Customer self-enrollment allowed** (GAP-028) - Violates PDR scope and access constraints
2. **Office staff cannot create customers/enrollments/assignments** (GAP-023, GAP-024, GAP-026) - Blocks required workflows
3. **Frontend-only mobile app access check** (GAP-033) - Bypassable security
4. **Staff can access unassigned customer data** (GAP-031, GAP-032) - Violates access constraints

**Medium Priority Violations:**
5. **Staff can update any withdrawal** (GAP-029) - Authorization bypass
6. **Missing database constraints for role/staff_type changes** (GAP-039, GAP-040) - Privilege escalation risk
7. **Unauthenticated staff_metadata access** (GAP-030) - Information disclosure risk

**Low Priority / Architecture Concerns:**
8. **SECURITY DEFINER function risks** (GAP-036, GAP-037, GAP-038) - Privilege escalation surface
9. **Role validation in frontend** (GAP-034, GAP-035) - Dual authority inconsistency risk

---

## 3. Core User Flow Implementation Gaps

### 3.1 Customer Auth & Dashboard

**GAP-043: Core User Journey 1 - Customer Onboarding & First Login (OTP → PIN → Dashboard)**
- **PDR Reference:** Section 4 - Functional Requirements, Core User Journey 1
- **Status:** ✅ **Fully Implemented**
- **Implementation Files:**
  - `lib/screens/login_screen.dart` - Phone number entry and OTP request
  - `lib/screens/otp_screen.dart` - OTP verification (lines 209-249)
  - `lib/screens/auth/pin_setup_screen.dart` - PIN setup (lines 79-131)
  - `lib/screens/auth/pin_login_screen.dart` - PIN-based login
  - `lib/screens/customer/dashboard_screen.dart` - Customer dashboard
- **Verified Steps:**
  - Step 1-2: Phone number entry and OTP request ✅
  - Step 3-5: OTP verification ✅
  - Step 6-7: Profile verification and PIN check ✅
  - Step 8-11: PIN setup screen ✅
  - Step 12-13: Dashboard navigation ✅

**GAP-044: Core User Journey 4 - Customer View Payment Schedule and Transaction History**
- **PDR Reference:** Section 4 - Functional Requirements, Core User Journey 4
- **Status:** ⚠️ **Partially Implemented**
- **Implementation Files:**
  - `lib/screens/customer/payment_schedule_screen.dart` - Payment schedule UI
  - `lib/screens/customer/dashboard_screen.dart` - Dashboard with transaction summary
- **Implemented:**
  - Payment schedule screen UI exists (line 69: uses `MockData.paymentSchedule`)
  - Dashboard displays active schemes and basic information
- **Missing:**
  - Payment schedule calculation based on `payment_frequency` from `user_schemes` table
  - Payment schedule queries `user_schemes` table to fetch active enrollments
  - Payment schedule queries `payments` table to match payments with due dates
  - Payment schedule calendar view with due dates highlighted
  - Transaction history screen implementation (not found)
  - Transaction detail screen implementation (not found)
  - Transaction filtering by date range, scheme, or payment method
  - Database queries: `user_schemes.select('*').eq('customer_id', customerId).eq('status', 'active')` (not implemented)
  - Database queries: `payments.select('*').eq('customer_id', customerId).order('payment_date', ascending: false).limit(50)` (not implemented)

**GAP-045: Core User Journey 6 - Customer View Investment Portfolio and Market Rates**
- **PDR Reference:** Section 4 - Functional Requirements, Core User Journey 6
- **Status:** ⚠️ **Partially Implemented**
- **Implementation Files:**
  - `lib/screens/customer/dashboard_screen.dart` - Dashboard with investment summary
- **Implemented:**
  - Dashboard displays basic scheme information
  - Market rates display (if implemented in dashboard)
- **Missing:**
  - Total investment screen (`TotalInvestmentScreen`)
  - Gold/Silver asset detail screens (`GoldAssetDetailScreen`, `SilverAssetDetailScreen`)
  - Market rates screen (`MarketRatesScreen`)
  - Portfolio value calculation: `(gold_grams * current_gold_rate) + (silver_grams * current_silver_rate)`
  - Database queries for aggregating total amount paid across all schemes
  - Database queries for aggregating total gold/silver grams by asset type
  - Database queries: `market_rates.select('*').order('rate_date', ascending: false).limit(1)` (market rates screen)

**GAP-046: Core User Journey 7 - Customer Profile Management**
- **PDR Reference:** Section 4 - Functional Requirements, Core User Journey 7
- **Status:** ⚠️ **Partially Implemented**
- **Implementation Files:**
  - `lib/screens/customer/profile_screen.dart` - Profile screen
- **Implemented:**
  - Profile screen displays customer information
- **Missing:**
  - Profile UPDATE queries: `profiles.update({'name': newName}).eq('user_id', userId)` (not verified)
  - Customer UPDATE queries: `customers.update({'address': newAddress, ...}).eq('profile_id', profileId)` (not verified)
  - Account information screen implementation (not found)
  - KYC details display from `customers` table

---

### 3.2 Collection Staff Payment Flow (Including Offline)

**GAP-047: Collection Staff Flow 1 - Record Payment Collection (Mobile App)**
- **PDR Reference:** Section 4 - Functional Requirements, Collection Staff Flow 1
- **Status:** ⚠️ **Partially Implemented (Offline Missing)**
- **Implementation Files:**
  - `lib/screens/staff/collect_payment_screen.dart` - Payment collection screen (lines 76-150)
  - `lib/services/payment_service.dart` - Payment service (lines 117-217)
  - `lib/services/staff_data_service.dart` - Staff data service
- **Implemented (Online Mode):**
  - Step 1-3: Assigned customers list display ✅
  - Step 4-5: Payment amount entry and payment method selection ✅
  - Step 6: "Record Payment" button ✅
  - Step 7 (Online): Payment recording to database ✅
    - Market rate fetching: `PaymentService.getCurrentMarketRate()` (line 128)
    - Payment INSERT: `PaymentService.insertPayment()` (lines 141-150)
    - Receipt ID generation (handled by database trigger)
    - GST calculation: `amount * 0.03` (line 171)
    - Net amount calculation: `amount * 0.97` (line 172)
    - Metal grams calculation: `netAmount / metalRatePerGram` (line 173)
    - Database trigger `update_user_scheme_totals` executes automatically ✅
- **Missing (Offline Mode):**
  - Step 6: Internet connectivity check (not implemented)
  - Step 8 (Offline): Payment queuing in local storage (NOT IMPLEMENTED)
    - No offline queue implementation found
    - No Flutter Secure Storage or SQLite usage for offline payment queue
    - No temporary receipt ID generation for offline payments
  - Step 9 (Offline Sync): Automatic sync when connection restored (NOT IMPLEMENTED)
    - No sync service implementation found
    - No retry logic for failed sync
    - No conflict resolution for duplicate payments
  - Offline queue full detection (not implemented)
  - Offline payment status tracking (not implemented)

**GAP-048: Collection Staff - Offline Support Requirements**
- **PDR Reference:** Section 4 - Functional Requirements, Offline / Retry Behavior: "Record payment (Collection Staff, Offline Queue): Payment recording works offline. Payments are queued in local storage and synced when connection restored."
- **Status:** ❌ **Not Implemented**
- **Missing Components:**
  - Offline payment queue storage (Flutter Secure Storage or SQLite)
  - Offline sync service (`OfflineSyncService`)
  - Network connectivity detection (`connectivity_plus` package or similar)
  - Automatic sync trigger when connection restored
  - Queue management (limit enforcement, status tracking)
  - Sync conflict resolution (duplicate receipt ID detection)

---

### 3.3 Office Staff Customer & Scheme Enrollment

**GAP-049: Office Staff Flow 1 - Create New Customer**
- **PDR Reference:** Section 4 - Functional Requirements, Office Staff Flow 1
- **Status:** ❌ **Not Implemented**
- **Implementation Files:** None found (website not implemented)
- **Missing Components:**
  - Customer registration form page (`/office/customers/add`)
  - Supabase Auth user creation: `Supabase.instance.client.auth.admin.createUser()` (not implemented)
  - Profile INSERT: `profiles.insert({'user_id': ..., 'name': ..., 'phone': ..., 'role': 'customer'})` (not implemented)
  - Customer INSERT: `customers.insert({'profile_id': ..., 'address': ..., 'nominee_name': ...})` (not implemented)
  - KYC document upload functionality (not implemented)
  - Phone number uniqueness validation (not implemented)
  - Customer detail page (`/office/customers/[id]`) (not implemented)

**GAP-050: Office Staff Flow 4 - Enroll Customer in Scheme**
- **PDR Reference:** Section 4 - Functional Requirements, Office Staff Flow 4
- **Status:** ❌ **Not Implemented**
- **Implementation Files:**
  - `lib/screens/customer/scheme_detail_screen.dart` line 466: TODO comment only
- **Missing Components:**
  - Enrollment form page (`/office/customers/[id]/enroll`)
  - Scheme selection dropdown (queries `schemes` table for active schemes)
  - Payment frequency selection (daily/weekly/monthly)
  - Amount range input (min/max) with scheme validation
  - Start date selection (defaults to today, cannot be past)
  - Maturity date calculation based on scheme type
  - Enrollment INSERT: `user_schemes.insert({'customer_id': ..., 'scheme_id': ..., 'enrollment_date': ..., 'payment_frequency': ..., 'min_amount': ..., 'max_amount': ..., 'status': 'active'})` (not implemented)
  - Confirmation dialog before enrollment
  - Success notification to customer (SMS/email) (not implemented)

**GAP-051: Office Staff Flow 2 - Assign Customer to Collection Staff by Route**
- **PDR Reference:** Section 4 - Functional Requirements, Office Staff Flow 2
- **Status:** ❌ **Not Implemented**
- **Missing Components:**
  - Assignment interface page (`/office/assignments/by-route`)
  - Route selection dropdown (queries `routes` table - table missing per GAP-001)
  - Customer filtering by route area (route assignment logic)
  - Staff selection dropdown (queries staff with `staff_type='collection'`)
  - Bulk assignment functionality (multiple customers at once)
  - Assignment INSERT: `staff_assignments.insert({'staff_id': ..., 'customer_id': ..., 'is_active': true, 'assigned_date': today})` (not implemented)
  - Assignment confirmation dialog

**GAP-052: Office Staff Flow 3 - Manual Payment Entry (Office Collections)**
- **PDR Reference:** Section 4 - Functional Requirements, Office Staff Flow 3
- **Status:** ❌ **Not Implemented**
- **Missing Components:**
  - Manual payment entry form page (`/office/transactions/add`)
  - Customer search functionality (by name or phone)
  - Active scheme selection for customer
  - Payment amount entry with scheme min/max validation
  - Payment method selection (Cash, UPI, Bank Transfer)
  - Payment date selection (defaults to today, can be past date)
  - Payment time entry (optional)
  - Notes field (optional, up to 500 characters)
  - Payment INSERT with `staff_id = NULL` for office collections (not implemented)
  - Receipt ID generation and display
  - Transaction detail page (`/office/transactions/[id]`)

---

### 3.4 Admin Financial Visibility

**GAP-053: Administrator Flow 1 - View Financial Dashboard (Inflow/Outflow)**
- **PDR Reference:** Section 4 - Functional Requirements, Administrator Flow 1
- **Status:** ❌ **Not Implemented**
- **Implementation Files:** None found (website not implemented)
- **Missing Components:**
  - Admin dashboard page (`/admin/dashboard`)
  - Financial metrics cards:
    - Total customers query: `SELECT COUNT(*) FROM customers WHERE profile_id IN (SELECT id FROM profiles WHERE role='customer' AND active=true)` (not implemented)
    - Active schemes query: `SELECT COUNT(*) FROM user_schemes WHERE status='active'` (not implemented)
    - Today's collections query: `SELECT SUM(amount) FROM payments WHERE payment_date = CURRENT_DATE AND status='completed'` (not implemented)
    - Today's withdrawals query: `SELECT SUM(final_amount) FROM withdrawals WHERE processed_at::date = CURRENT_DATE AND status='processed'` (not implemented)
    - Pending payments query: `SELECT COUNT(*) FROM user_schemes WHERE status='active' AND due_amount > 0` (not implemented)
  - Inflow tracking page (`/admin/financials/inflow`):
    - Payments query: `payments.select('*').eq('status', 'completed').order('payment_date', ascending: false).limit(100)` (not implemented)
    - Daily/weekly/monthly aggregation (not implemented)
    - Payment method breakdown (cash vs digital) (not implemented)
    - Line chart showing daily collection trends (last 30 days) (not implemented)
    - Bar chart showing weekly collection totals (not implemented)
    - Pie chart showing payment method distribution (not implemented)
    - Payment list table with filters (not implemented)
  - Outflow tracking page (`/admin/financials/outflow`):
    - Withdrawals query: `withdrawals.select('*').order('created_at', ascending: false)` (not implemented)
    - Daily/weekly/monthly withdrawal aggregation (not implemented)
    - Status breakdown (pending, approved, processed, rejected) (not implemented)
    - Line chart showing daily withdrawal trends (not implemented)
    - Bar chart comparing inflow vs outflow (not implemented)
    - Withdrawal list table with status filters (not implemented)
  - Cash flow analysis page (`/admin/financials/cash-flow`):
    - Net cash flow calculation: `total inflow - total outflow` (not implemented)
    - Cash flow chart (not implemented)
    - Net position display (not implemented)
    - Trend analysis (not implemented)
  - Data filtering by date range, staff, or customer (not implemented)
  - Export functionality (CSV/Excel generation) (not implemented)

**GAP-054: Administrator Flow 2 - Fetch and Update Market Rates**
- **PDR Reference:** Section 4 - Functional Requirements, Administrator Flow 2
- **Status:** ❌ **Not Implemented**
- **Missing Components:**
  - Market rates management page (`/admin/market-rates`)
  - External API integration for fetching market prices (TBD API)
  - Automated daily fetch (Edge Function or scheduled job) (not implemented)
  - Manual rate entry form (not implemented)
  - Manual override functionality (not implemented)
  - Rate history display (not implemented)
  - Rate deviation detection (>10% change flag) (not implemented)
  - Admin notification on API fetch failure (not implemented)

---

### 3.5 Withdrawal Request Lifecycle

**GAP-055: Core User Journey 5 - Customer Withdrawal Request**
- **PDR Reference:** Section 4 - Functional Requirements, Core User Journey 5
- **Status:** ⚠️ **Partially Implemented**
- **Implementation Files:**
  - `lib/screens/customer/withdrawal_screen.dart` - Withdrawal request form (lines 1-386)
  - `lib/screens/customer/withdrawal_list_screen.dart` - Withdrawal list screen
- **Implemented:**
  - Withdrawal screen UI exists
  - Withdrawal type selection (Partial/Full)
  - Amount entry fields for partial withdrawal
  - Available balance display (calculated from scheme data)
  - UI validation for withdrawal amounts
- **Missing:**
  - Step 1: Active enrollments query: `user_schemes.select('id, scheme_id, accumulated_metal_grams, total_amount_paid, status').eq('customer_id', customerId).eq('status', 'active')` (not implemented - uses passed scheme data)
  - Step 1: Current market rates query: `market_rates.select('*').order('rate_date', ascending: false).limit(1)` (not implemented - uses hardcoded rates at line 40: `final currentRate = metalType.toString().toLowerCase() == 'gold' ? 6500.0 : 78.0`)
  - Step 1: Total available gold/silver grams calculation across all active schemes (not implemented)
  - Step 1: Current value calculation based on market rates (not implemented)
  - Step 4-5: Gold/silver grams entry validation (amount <= available grams) (not fully implemented)
  - Step 7: Withdrawal INSERT: `withdrawals.insert({'customer_id': ..., 'user_scheme_id': ..., 'withdrawal_type': ..., 'requested_amount': ..., 'requested_grams': ..., 'status': 'pending', ...})` (NOT IMPLEMENTED - no INSERT found in withdrawal_screen.dart)
  - Step 8: Success message with request ID (not implemented)
  - Step 8: Navigation to withdrawal list screen (not verified)

**GAP-056: Withdrawal Approval/Processing Flow**
- **PDR Reference:** Section 4 - Functional Requirements, Collection Staff and Office Staff can update withdrawal status
- **Status:** ❌ **Not Implemented**
- **Missing Components:**
  - Withdrawal approval interface for staff (not found)
  - Withdrawal status update: `withdrawals.update({'status': 'approved', 'approved_by': staffId, 'approved_at': now, 'final_amount': ..., 'final_grams': ...}).eq('id', withdrawalId)` (not implemented)
  - Withdrawal processing: `withdrawals.update({'status': 'processed', 'processed_at': now, 'final_amount': ..., 'final_grams': ...}).eq('id', withdrawalId)` (not implemented)
  - Withdrawal rejection: `withdrawals.update({'status': 'rejected', 'rejection_reason': ...}).eq('id', withdrawalId)` (not implemented)
  - Withdrawal list screen for staff to view pending withdrawals (not found)
  - Customer notification on withdrawal status change (not implemented)

---

### 3.6 Summary of Core Flow Implementation Status

**Fully Implemented Flows:**
1. ✅ Customer Onboarding & First Login (OTP → PIN → Dashboard) (GAP-043)

**Partially Implemented Flows:**
2. ⚠️ Customer Payment Schedule & Transaction History (GAP-044) - UI exists, database queries missing
3. ⚠️ Customer Investment Portfolio & Market Rates (GAP-045) - Dashboard exists, detailed screens missing
4. ⚠️ Customer Profile Management (GAP-046) - Screen exists, UPDATE functionality not verified
5. ⚠️ Collection Staff Payment Collection (Online) (GAP-047) - Payment recording works, offline mode missing
6. ⚠️ Customer Withdrawal Request (GAP-055) - UI exists, database INSERT missing

**Not Implemented Flows:**
7. ❌ Office Staff Create Customer (GAP-049) - Website not implemented
8. ❌ Office Staff Enroll Customer in Scheme (GAP-050) - Website not implemented
9. ❌ Office Staff Assign Customer to Collection Staff (GAP-051) - Website not implemented, routes table missing
10. ❌ Office Staff Manual Payment Entry (GAP-052) - Website not implemented
11. ❌ Admin Financial Dashboard (GAP-053) - Website not implemented
12. ❌ Admin Market Rates Management (GAP-054) - Website not implemented, API integration missing
13. ❌ Withdrawal Approval/Processing (GAP-056) - Staff interface not implemented

**Critical Missing Infrastructure:**
- Website implementation (Next.js) for Office Staff and Admin workflows
- Offline payment queue and sync service for Collection Staff
- Market rates API integration and scheduled fetch
- Withdrawal INSERT functionality (customer withdrawal requests)
- Withdrawal status management (staff approval/processing)

---

## 4. Financial Logic & Integrity Gaps

### 4.1 Rate Usage and Historical Correctness

**GAP-057: Trigger `update_user_scheme_totals` recalculates `metal_grams_added` using current market rate instead of payment rate**
- **PDR Reference:** Section 8 - Data Model Overview, **payments** row: "metal_rate_per_gram" - Rate at time of payment. Column comment states: "Rate used at time of payment. Must be written by application. Never recalculated."
- **PDR Reference:** Section 8 - Data Model Overview, Access Constraints: Payments are append-only (immutable) - no updates or deletes allowed for audit compliance
- **Implementation Status:** Trigger `update_user_scheme_totals` at `supabase_schema.sql` lines 472-475 recalculates `metal_grams_added` if `metal_grams_added = 0`:
  ```sql
  IF NEW.metal_grams_added = 0 AND NEW.net_amount > 0 AND current_rate > 0 THEN
      NEW.metal_grams_added := NEW.net_amount / current_rate;
  END IF;
  ```
  Where `current_rate` is fetched from `market_rates` table (lines 461-465), not from `NEW.metal_rate_per_gram`
- **Risk Introduced:** If application code sets `metal_grams_added = 0` (or omits it), trigger will recalculate using current market rate instead of the rate stored at payment time. This violates historical correctness: payment made at rate X will be recalculated using rate Y (current rate), causing incorrect metal grams for historical payments. Creates audit trail inconsistency and reconciliation failure.

**GAP-058: Trigger `update_user_scheme_totals` uses latest market rate from `market_rates` table instead of rate stored in payment**
- **PDR Reference:** Section 8 - Data Model Overview, Column comment on `payments.metal_rate_per_gram`: "Rate used at time of payment. Must be written by application. Never recalculated."
- **Implementation Status:** Trigger at `supabase_schema.sql` lines 460-470 fetches latest rate from `market_rates` table:
  ```sql
  SELECT price_per_gram INTO current_rate
  FROM market_rates
  WHERE asset_type = scheme_asset_type
  ORDER BY rate_date DESC
  LIMIT 1;
  ```
  Only falls back to `NEW.metal_rate_per_gram` if no rate found (line 469). Otherwise uses current rate from `market_rates` table
- **Risk Introduced:** If `metal_grams_added = 0`, trigger calculates grams using current market rate (which may differ from payment-time rate stored in `metal_rate_per_gram`). This creates inconsistency: `metal_rate_per_gram` stores historical rate X, but `metal_grams_added` is calculated using current rate Y. Violates requirement that payment data must reflect historical state at payment time. Prevents accurate reconciliation and audit trail verification.

**GAP-059: No validation that `metal_rate_per_gram` matches market rate at payment time**
- **PDR Reference:** Section 4 - Functional Requirements, Collection Staff Flow 1: "App queries current market rates: `market_rates.select('*').order('rate_date', ascending: false).limit(1)`" - Application should use current rate at payment time
- **PDR Reference:** Section 8 - Data Model Overview, **payments** row: `metal_rate_per_gram` should reflect rate used at payment time
- **Implementation Status:** Application code (`lib/services/payment_service.dart` line 128) fetches current market rate and stores it in `metal_rate_per_gram` (line 196). No database constraint or trigger validates that stored rate matches rate that was current at `payment_date`
- **Risk Introduced:** Application code could store incorrect rate (e.g., if cache is stale, if rate fetch fails and fallback rate is used, if manual entry error). No database-level verification ensures historical correctness. If wrong rate is stored, all downstream calculations (metal grams, accumulated grams) will be incorrect and cannot be detected without manual reconciliation. Creates silent data corruption risk.

**GAP-060: Withdrawal screen uses hardcoded market rates instead of querying `market_rates` table**
- **PDR Reference:** Section 4 - Functional Requirements, Core User Journey 5: "App queries current market rates: `market_rates.select('*').order('rate_date', ascending: false).limit(1)`"
- **Implementation Status:** `lib/screens/customer/withdrawal_screen.dart` line 40 uses hardcoded rates: `final currentRate = metalType.toString().toLowerCase() == 'gold' ? 6500.0 : 78.0;`
- **Risk Introduced:** Withdrawal value calculations use incorrect rates if actual market rates differ from hardcoded values. Customer may request withdrawal based on wrong rate, leading to incorrect `requested_amount` calculation and potential disputes. Violates requirement to use current market rates from database.

---

### 4.2 Payment Calculation Integrity

**GAP-061: GST and net amount calculations in application code not verified against stored values**
- **PDR Reference:** Section 8 - Data Model Overview, **payments** table constraints: `payments_gst_calculation CHECK (ABS(gst_amount - (amount * 0.03)) < 0.01)` and `payments_net_calculation CHECK (ABS(net_amount - (amount * 0.97)) < 0.01)`
- **Implementation Status:** Application code (`lib/services/payment_service.dart` lines 171-172) calculates: `gstAmount = amount * 0.03` and `netAmount = amount * 0.97`. Database constraints verify these calculations (lines 261-266 in `supabase_schema.sql`)
- **Note:** Database constraints are correctly implemented and verify calculations. No gap identified.

**GAP-062: Metal grams calculation can be overridden by trigger if application sets `metal_grams_added = 0`**
- **PDR Reference:** Section 8 - Data Model Overview, **payments** row: `metal_grams_added` should be calculated at payment time using `net_amount / metal_rate_per_gram`
- **Implementation Status:** Application code (`lib/services/payment_service.dart` line 173) calculates: `metalGramsAdded = netAmount / metalRatePerGram` and inserts it (line 197). However, trigger `update_user_scheme_totals` (line 473-475) recalculates if `metal_grams_added = 0`
- **Risk Introduced:** If application code fails to calculate or sets `metal_grams_added = 0` (e.g., due to bug, null handling, or incorrect rate), trigger will recalculate using current market rate instead of payment-time rate. This creates inconsistency where application-calculated value is overwritten by database trigger using different rate. Application code may appear correct, but database value differs, causing silent data corruption.

**GAP-063: No constraint ensuring `metal_grams_added` matches `net_amount / metal_rate_per_gram`**
- **PDR Reference:** Section 8 - Data Model Overview, **payments** row: `metal_grams_added` is calculated as `net_amount / metal_rate_per_gram`
- **Implementation Status:** `payments` table has check constraints for GST and net amount (lines 261-266), but no check constraint validating `metal_grams_added = net_amount / metal_rate_per_gram` (allowing small rounding differences)
- **Risk Introduced:** If application code calculates incorrect `metal_grams_added` (e.g., division error, wrong rate used, rounding error), database will accept invalid value. No validation ensures stored grams match payment amount and rate. Creates data integrity risk where `metal_grams_added` may be inconsistent with `net_amount` and `metal_rate_per_gram`, preventing accurate reconciliation and portfolio valuation.

---

### 4.3 Reconciliation Capability

**GAP-064: No database view or function to reconcile `user_schemes.total_amount_paid` against sum of payments**
- **PDR Reference:** Section 8 - Data Model Overview, **user_schemes** row: `total_amount_paid` is updated via database trigger `update_user_scheme_totals`
- **PDR Reference:** Section 4 - Functional Requirements, Error States: "Trigger UPDATE failure: Payment INSERT succeeds but trigger fails to update `user_schemes`. App displays warning message 'Payment recorded but totals may not be updated. Please verify and contact support if needed.'"
- **Implementation Status:** Trigger `update_user_scheme_totals` updates `user_schemes.total_amount_paid` (line 482), but no view, function, or query exists to verify that `user_schemes.total_amount_paid` equals `SUM(payments.net_amount WHERE user_scheme_id = X AND is_reversal = false AND status = 'completed')`
- **Risk Introduced:** If trigger fails silently (e.g., UPDATE permission issue, constraint violation, concurrent modification), `user_schemes.total_amount_paid` will be incorrect. No automated reconciliation detects drift between calculated totals and sum of actual payments. Manual reconciliation requires writing custom queries. Violates requirement for verifiable financial data integrity. Prevents detection of trigger failures and data corruption.

**GAP-065: No database view or function to reconcile `user_schemes.accumulated_grams` against sum of payment grams**
- **PDR Reference:** Section 8 - Data Model Overview, **user_schemes** row: `accumulated_grams` is updated via database trigger `update_user_scheme_totals`
- **Implementation Status:** Trigger updates `user_schemes.accumulated_grams` (line 484), but no view or function exists to verify that `user_schemes.accumulated_grams` equals `SUM(payments.metal_grams_added WHERE user_scheme_id = X AND is_reversal = false AND status = 'completed')`
- **Risk Introduced:** If trigger fails or miscalculates `metal_grams_added`, `accumulated_grams` will be incorrect. No automated reconciliation detects inconsistency. Customer portfolio value calculations will be wrong. Withdrawal requests may allow withdrawals exceeding actual accumulated grams. Creates financial risk where system may permit invalid withdrawals based on incorrect totals.

**GAP-066: No database view or function to reconcile `user_schemes.payments_made` against count of payments**
- **PDR Reference:** Section 8 - Data Model Overview, **user_schemes** row: `payments_made` is updated via database trigger `update_user_scheme_totals`
- **Implementation Status:** Trigger updates `user_schemes.payments_made` (line 483), but no view or function exists to verify that `user_schemes.payments_made` equals `COUNT(payments.id WHERE user_scheme_id = X AND is_reversal = false AND status = 'completed')`
- **Risk Introduced:** If trigger fails or reversal logic miscalculates, `payments_made` count will be incorrect. No automated reconciliation detects count drift. Reporting and analytics will show wrong payment counts. Business metrics (e.g., average payment amount, payment frequency) will be incorrect based on wrong denominator.

**GAP-067: No reconciliation queries or reports for staff daily collections**
- **PDR Reference:** Section 4 - Functional Requirements, Collection Staff Flow 1: Staff collects payments and totals are tracked in `user_schemes` table
- **Implementation Status:** Views `today_collections` (line 1006) and `staff_daily_stats` (line 1036) aggregate payment data, but no reconciliation view exists to verify that staff daily totals match sum of individual payments
- **Risk Introduced:** If payment INSERT succeeds but trigger fails to update `user_schemes`, daily collection totals may be incorrect. No automated reconciliation detects discrepancies between aggregate totals and individual payment records. Staff performance reports and daily targets will show incorrect data, affecting business decisions.

---

### 4.4 Payment Immutability Violations

**GAP-068: Database triggers prevent UPDATE/DELETE but no application-level enforcement**
- **PDR Reference:** Section 8 - Data Model Overview, **payments** row: "UPDATE/DELETE blocked by database triggers" (immutable for audit)
- **Implementation Status:** Triggers `prevent_payment_update` (line 521) and `prevent_payment_delete` (line 527) block UPDATE/DELETE operations. Application code does not attempt UPDATE/DELETE, but no application-level checks prevent attempts
- **Note:** Database triggers are correctly implemented and provide sufficient protection. Application-level enforcement is not required if database triggers are reliable. No gap identified, but note that if triggers are disabled or bypassed, application has no additional protection.

**GAP-069: RLS policies do not explicitly block UPDATE/DELETE on payments table**
- **PDR Reference:** Section 8 - Data Model Overview, **payments** row: "UPDATE/DELETE blocked by database triggers" (immutable for audit)
- **Implementation Status:** RLS policies on `payments` table (lines 851-891) only define SELECT and INSERT policies. No UPDATE or DELETE policies exist, which means RLS allows UPDATE/DELETE operations (which are then blocked by triggers)
- **Note:** While triggers prevent UPDATE/DELETE, RLS policies could explicitly deny these operations as defense-in-depth. However, current implementation (triggers blocking) is sufficient. No gap identified, but note that RLS could provide additional layer of protection if triggers fail.

**GAP-070: Reversal payment logic does not verify original payment exists and is not already reversed**
- **PDR Reference:** Section 8 - Data Model Overview, **payments** row: Reversals are new INSERT records with `is_reversal = true` and `reverses_payment_id` pointing to original payment
- **Implementation Status:** Constraint `payments_reversal_logic` (line 269-272) ensures reversal flag matches `reverses_payment_id`, but no constraint ensures original payment exists, is not already reversed, and is not itself a reversal
- **Risk Introduced:** If application code creates reversal with invalid `reverses_payment_id` (e.g., points to non-existent payment, points to another reversal, points to already-reversed payment), database will accept invalid reversal. Trigger will incorrectly subtract from totals based on invalid reversal, causing financial data corruption. No validation prevents double-reversal or reversal of reversals.

---

### 4.5 Historical Rate Preservation

**GAP-071: No mechanism to verify `market_rates` table has rate for every payment date**
- **PDR Reference:** Section 8 - Data Model Overview, **market_rates** row: Daily market rates are fetched from external API and stored in `market_rates` table
- **PDR Reference:** Section 4 - Functional Requirements, Administrator Flow 2: Market rates are fetched daily and stored historically
- **Implementation Status:** `payments.metal_rate_per_gram` stores rate at payment time, but no constraint or validation ensures that rate matches rate in `market_rates` table for `payment_date` (or closest prior date)
- **Risk Introduced:** If market rates are missing for historical dates (e.g., API fetch failed, data not backfilled), payments made on those dates cannot be verified against historical rates. No reconciliation detects payments made at rates that don't match historical `market_rates` table. Prevents verification that payment rates were correct at payment time.

**GAP-072: No validation that payment `metal_rate_per_gram` matches historical `market_rates.price_per_gram` for payment date**
- **PDR Reference:** Section 8 - Data Model Overview, **payments** row: `metal_rate_per_gram` should reflect rate used at payment time, which should match rate from `market_rates` table for that date
- **Implementation Status:** Application code stores rate in `metal_rate_per_gram` (line 196 in `payment_service.dart`), but no database constraint or trigger validates that stored rate matches `market_rates.price_per_gram WHERE rate_date = payment_date` (or closest prior date)
- **Risk Introduced:** If application code stores incorrect rate (e.g., uses stale cache, uses wrong date's rate, manual entry error), database will accept payment with incorrect rate. No validation ensures stored rate matches historical rate for payment date. Prevents detection of rate errors and reconciliation against historical rate data.

**GAP-073: Trigger recalculates `metal_grams_added` using current rate if historical rate is missing**
- **PDR Reference:** Section 8 - Data Model Overview, **payments** row: `metal_rate_per_gram` must be written by application and never recalculated
- **Implementation Status:** Trigger `update_user_scheme_totals` (line 467-470) falls back to `NEW.metal_rate_per_gram` if no rate found in `market_rates` table, but if `metal_grams_added = 0`, it still uses current rate from `market_rates` table (lines 461-465) before fallback
- **Risk Introduced:** If historical payment is inserted with `metal_grams_added = 0` and `market_rates` table has current rate but not historical rate, trigger will calculate grams using current rate instead of historical rate stored in `metal_rate_per_gram`. This corrupts historical payment data by using wrong rate for calculation. Violates requirement that historical payments must use historical rates.

---

### 4.6 Summary of Financial Integrity Risks

**Critical Risks:**
1. **Trigger recalculates historical data** (GAP-057, GAP-058, GAP-073) - Violates immutability and historical correctness
2. **No reconciliation capability** (GAP-064, GAP-065, GAP-066) - Cannot detect trigger failures or data corruption
3. **Rate validation missing** (GAP-059, GAP-071, GAP-072) - No verification that stored rates match historical rates

**Medium Risks:**
4. **Reversal validation missing** (GAP-070) - Allows invalid reversals
5. **Hardcoded rates in withdrawal** (GAP-060) - Incorrect withdrawal calculations
6. **Metal grams calculation can be overridden** (GAP-062, GAP-063) - Application-calculated values can be silently replaced

**Low Risks:**
7. **No application-level immutability checks** (GAP-068, GAP-069) - Relies solely on database triggers (may be sufficient but lacks defense-in-depth)

---

## 5. Architectural Deviations & Violations

### 5.1 Database-First Security Violations

**GAP-074: Mobile app access check implemented in frontend instead of database RLS**
- **Architectural Decision:** Section 8 - Data Model Overview, Authorization Enforcement: "Database Level: Row Level Security (RLS) policies enforced on all tables in PostgreSQL"
- **Binding Requirement:** "Database-first security (RLS, triggers, RPC functions)"
- **Implementation Status:** Mobile app access check in `lib/services/role_routing_service.dart` lines 79-151 performs role and staff_type validation in application code, throwing exceptions if admin or office staff
- **Violation:** Security enforcement is in application layer, not database layer. RLS policies do not prevent office staff or admin from querying mobile app data if frontend check is bypassed
- **Impact:** Contradicts "database-first security" architecture. If application code is bypassed (direct API calls, modified client), unauthorized users can access mobile app data. Frontend-only security is bypassable and violates architectural principle.

**GAP-075: Role and staff_type validation performed in frontend code instead of relying solely on RLS**
- **Architectural Decision:** Section 8 - Data Model Overview, Authorization Enforcement: "All API requests validated against RLS policies (Supabase enforces RLS on all queries)"
- **Binding Requirement:** "Database-first security (RLS, triggers, RPC functions)"
- **Implementation Status:** Role validation in `lib/services/role_routing_service.dart` lines 15-41 and `lib/main.dart` lines 261-265 queries `profiles` table and validates role in application code. Staff type check at lines 133-140 validates `staff_type = 'collection'` in application code
- **Violation:** Creates dual authority: RLS policies enforce access at database level, but application code performs additional validation that could be inconsistent with RLS policies
- **Impact:** Potential inconsistency between RLS policies and application code. If RLS policy is updated but application code is not, security may be weakened or access incorrectly denied. Violates single source of truth principle (database should be authoritative).

**GAP-076: Customer self-enrollment allowed by RLS policy despite PDR requirement**
- **Architectural Decision:** Section 8 - Data Model Overview, Customer Access Constraints: "Customers can read own enrollments (read-only). Cannot create enrollments (enrollment performed by office staff)."
- **Binding Requirement:** "Strict role separation (customer, collection staff, office staff, admin)"
- **Implementation Status:** RLS policy at `supabase_schema.sql` lines 822-829 allows customers to enroll themselves: `WITH CHECK (customer_id IN (SELECT id FROM customers WHERE profile_id = get_user_profile()) OR is_admin());`
- **Violation:** Policy contradicts PDR requirement that customers cannot create enrollments. Enrollment should be office staff-only operation enforced at database level
- **Impact:** Customers can bypass business rule requiring office staff enrollment. Violates role separation and database-first security. Creates data integrity risk.

---

### 5.2 Misplaced Logic (Frontend vs Database)

**GAP-077: Payment schedule calculation should be database query, not client-side mock data**
- **Architectural Decision:** Section 6 - Technical Architecture, Database Approach: "Client-side caching" - implies database is source of truth, client caches for performance
- **Implementation Status:** `lib/screens/customer/payment_schedule_screen.dart` line 69 uses `MockData.paymentSchedule` instead of querying `user_schemes` and `payments` tables
- **Violation:** Payment schedule logic is in frontend using mock data, not derived from database queries. Should query `user_schemes` for active enrollments and `payments` for payment history, then calculate schedule based on `payment_frequency`
- **Impact:** Payment schedule does not reflect actual database state. Customers see incorrect due dates and payment status. Violates database-first architecture where database is source of truth.

**GAP-078: Market rates hardcoded in withdrawal screen instead of database query**
- **Architectural Decision:** Section 8 - Data Model Overview, **market_rates** row: Rates stored in `market_rates` table, fetched from external API
- **Implementation Status:** `lib/screens/customer/withdrawal_screen.dart` line 40 uses hardcoded rates: `final currentRate = metalType.toString().toLowerCase() == 'gold' ? 6500.0 : 78.0;`
- **Violation:** Market rates should be queried from `market_rates` table, not hardcoded in application code. Database is source of truth for rates
- **Impact:** Withdrawal calculations use incorrect rates if actual market rates differ. Violates database-first architecture. Prevents accurate withdrawal value calculations.

**GAP-079: Mock data used in production screens instead of database queries**
- **Architectural Decision:** Section 6 - Technical Architecture, Database Approach: Database is authoritative source of truth
- **Implementation Status:** Multiple screens use `MockData`:
  - `lib/screens/customer/payment_schedule_screen.dart` line 69: `MockData.paymentSchedule`
  - `lib/screens/customer/profile_screen.dart` lines 191, 373: `MockData.userName`
  - `lib/screens/customer/account_information_page.dart` line 25: Mock data for account information
  - `lib/screens/customer/scheme_detail_screen.dart` lines 43, 48: `MockData.schemeDetails`
- **Violation:** Production screens display mock data instead of querying database. Database should be source of truth, not mock data structures
- **Impact:** Users see incorrect data that does not reflect actual database state. Violates database-first architecture and creates data inconsistency risk.

**GAP-080: Payment collection fallback to mock rates instead of database error handling**
- **Architectural Decision:** Section 8 - Data Model Overview, **market_rates** row: Rates stored in database, should be queried
- **Implementation Status:** `lib/screens/staff/collect_payment_screen.dart` lines 51-60 falls back to `MockData.goldPricePerGram` and `MockData.silverPricePerGram` if database query fails
- **Violation:** Application code uses mock data as fallback instead of proper error handling. Should display error to user or use last known rate from database, not hardcoded mock values
- **Impact:** If market rate query fails, payment uses incorrect mock rate instead of actual rate. Violates database-first architecture and creates financial calculation errors.

---

### 5.3 Navigation Authority Violations

**GAP-081: Imperative navigation calls bypass declarative router**
- **Architectural Decision:** Section 7 - Technical Architecture, Navigation: Declarative routing via `AuthGate` and `appRouterProvider` (Riverpod-based)
- **Binding Requirement:** "Replace AuthGate with declarative appRouterProvider" (from earlier architectural decisions)
- **Implementation Status:** Multiple screens use imperative `Navigator.push()` calls:
  - `lib/screens/customer/profile_screen.dart` lines 423, 436, 449, 462: `Navigator.push()` for navigation
  - `lib/screens/staff/staff_profile_screen.dart` lines 252, 271, 286: `Navigator.push()` for navigation
  - `lib/screens/customer/scheme_detail_screen.dart` lines 49, 491: `Navigator.pushReplacement()` and `Navigator.push()`
- **Violation:** Imperative navigation creates competing navigation stacks that bypass declarative router. Navigation should be state-driven via `appRouterProvider`, not imperative `Navigator` calls
- **Impact:** Creates mixed navigation authority. Imperative calls can bypass `AuthGate` routing logic, causing state desynchronization and navigation inconsistencies. Violates declarative navigation architecture.

**GAP-082: `navigateByRole()` method disabled but pattern may exist elsewhere**
- **Architectural Decision:** Earlier architectural decision to disable `navigateByRole()` to prevent bypassing `AuthGate`
- **Implementation Status:** `lib/services/role_routing_service.dart` line 174 throws `UnimplementedError` for `navigateByRole()`, but other imperative navigation patterns may exist
- **Violation:** While `navigateByRole()` is disabled, other imperative navigation patterns (e.g., direct `Navigator.push()` calls) still exist and can bypass declarative router
- **Impact:** Declarative navigation architecture is partially enforced. Imperative navigation still possible via direct `Navigator` calls, creating navigation authority split.

---

### 5.4 Unnecessary Complexity or Out-of-Scope Implementation

**GAP-083: Database views defined but not used by application code**
- **Architectural Decision:** Section 6 - Technical Architecture, Database Approach: Views should be used for reporting and aggregation
- **Implementation Status:** Views `active_customer_schemes` (line 977), `today_collections` (line 1006), and `staff_daily_stats` (line 1036) are defined in `supabase_schema.sql` but not queried by Flutter code. Application code performs client-side aggregation instead (`lib/services/staff_data_service.dart:194-287`)
- **Violation:** Database views exist but application code duplicates aggregation logic in client. Creates unnecessary complexity: database provides views but application ignores them and reimplements logic
- **Impact:** Duplicate logic between database views and application code. If view logic changes, application code must be updated separately. Violates DRY principle and database-first architecture.

**GAP-084: Offline sync infrastructure columns exist but offline sync not implemented**
- **Architectural Decision:** Section 4 - Functional Requirements, Offline / Retry Behavior: "Record payment (Collection Staff, Offline Queue): Payment recording works offline"
- **Binding Requirement:** "Offline-first payment collection (mobile app)"
- **Implementation Status:** `payments` table has `device_id` (line 256) and `client_timestamp` (line 257) columns for offline sync, but no offline queue implementation exists. No Flutter Secure Storage or SQLite usage for offline payment queue
- **Violation:** Database schema includes offline sync infrastructure, but application code does not implement offline functionality. Columns exist but are unused, creating false impression that offline sync is implemented
- **Impact:** Database schema suggests offline capability, but application cannot queue payments offline. Violates offline-first requirement. Columns are dead code that adds complexity without functionality.

**GAP-085: Payment trigger recalculates metal grams using current rate (unnecessary complexity)**
- **Architectural Decision:** Section 8 - Data Model Overview, **payments** row: `metal_rate_per_gram` must be written by application and never recalculated
- **Implementation Status:** Trigger `update_user_scheme_totals` (lines 460-475) fetches current market rate from `market_rates` table and recalculates `metal_grams_added` if `metal_grams_added = 0`
- **Violation:** Trigger adds unnecessary complexity by recalculating values that should be set by application. Application code already calculates `metal_grams_added` correctly (line 173 in `payment_service.dart`). Trigger recalculation using current rate contradicts requirement to use payment-time rate
- **Impact:** Creates dual calculation paths (application and trigger) that can produce different results. Trigger uses current rate instead of payment-time rate, violating historical correctness. Adds complexity without benefit.

**GAP-086: Multiple SECURITY DEFINER functions create privilege escalation surface**
- **Architectural Decision:** Section 8 - Data Model Overview, Authorization Enforcement: Database-first security with RLS enforced on all tables
- **Implementation Status:** Six SECURITY DEFINER functions exist (lines 575-632, 639-651, 659-678) that bypass RLS to avoid recursion. Functions are necessary but create large privilege escalation surface
- **Violation:** While necessary to avoid RLS recursion, multiple SECURITY DEFINER functions increase attack surface. Any logic error in these functions could bypass RLS in unintended ways
- **Impact:** Creates unnecessary complexity in security model. Functions should have minimal logic, but current implementation has complex queries and joins. Increases risk of privilege escalation if functions are modified incorrectly.

**GAP-087: Customer self-enrollment RLS policy contradicts PDR (out-of-scope feature enabled)**
- **Architectural Decision:** Section 2 - Scope Definition, OUT OF SCOPE: "Customer self-enrollment" explicitly excluded from Phase 1
- **Binding Requirement:** "Phase 1 MVP scope only (no out-of-scope features)"
- **Implementation Status:** RLS policy at `supabase_schema.sql` lines 822-829 allows customers to create their own enrollments, which is explicitly out of scope
- **Violation:** Policy enables feature that is explicitly excluded from Phase 1 MVP scope. Customers should not be able to enroll themselves
- **Impact:** Out-of-scope feature is enabled at database level. Customers can self-enroll despite PDR requirement that enrollment is office staff-only. Violates scope definition.

---

### 5.5 State Management Architecture Violations

**GAP-088: Dual auth authority (Supabase Auth + AuthFlowNotifier) creates state synchronization risk**
- **Architectural Decision:** Earlier architectural decisions to migrate from Provider to Riverpod, establish single auth authority
- **Binding Requirement:** Migration to Riverpod for state management
- **Implementation Status:** `lib/main.dart` lines 51-81 has Supabase `onAuthStateChange` listener that updates `AuthFlowNotifier` state. Riverpod `authStateProvider` also observes Supabase Auth. Creates dual authority: Supabase Auth → AuthFlowNotifier (Provider) and Supabase Auth → Riverpod
- **Violation:** Two state management systems (Provider and Riverpod) both observe Supabase Auth, creating potential state desynchronization. Architecture decision was to migrate to Riverpod, but Provider-based `AuthFlowNotifier` still receives direct updates
- **Impact:** State can become inconsistent if one system updates but other does not. Violates single source of truth principle. Creates complexity in state synchronization.

**GAP-089: Mixed navigation authority (declarative AuthGate + imperative Navigator)**
- **Architectural Decision:** Earlier architectural decisions to use declarative navigation via `AuthGate` and `appRouterProvider`
- **Implementation Status:** `lib/main.dart` uses `appRouterProvider` (declarative), but multiple screens use `Navigator.push()` (imperative) for sub-navigation
- **Violation:** Root navigation is declarative, but sub-navigation is imperative. Creates mixed navigation patterns that can conflict
- **Impact:** Navigation authority is split between declarative router and imperative Navigator calls. Can cause navigation stack inconsistencies and state desynchronization.

---

### 5.6 Summary of Architectural Violations

**Critical Violations:**
1. **Frontend-only security** (GAP-074, GAP-075) - Contradicts database-first security architecture
2. **Customer self-enrollment enabled** (GAP-076, GAP-087) - Out-of-scope feature enabled, contradicts PDR
3. **Mock data in production** (GAP-079) - Violates database-first architecture

**Medium Priority Violations:**
4. **Misplaced logic** (GAP-077, GAP-078, GAP-080) - Frontend calculations instead of database queries
5. **Imperative navigation** (GAP-081, GAP-082) - Bypasses declarative router
6. **Dual auth authority** (GAP-088) - State synchronization risk

**Low Priority / Complexity Issues:**
7. **Unused database views** (GAP-083) - Duplicate logic
8. **Unused offline columns** (GAP-084) - Dead code
9. **Trigger recalculation** (GAP-085) - Unnecessary complexity
10. **Multiple SECURITY DEFINER functions** (GAP-086) - Large attack surface

---

## 6. Summary of Missing / Incomplete MVP Requirements

### 6.1 Database & Schema Components

**Missing Tables:**
- `routes` table (GAP-001)

**Missing Columns:**
- `staff_assignments.route_id` (FK to routes.id) (GAP-002)
- `customers.route_id` (FK to routes.id) (GAP-003)
- `payments.sync_status` or `payments.sync_conflict_id` for offline sync conflicts (GAP-016)
- `routes.created_at`, `routes.updated_at`, `routes.created_by`, `routes.updated_by` (when routes table created) (GAP-013)

**Missing Constraints:**
- `routes.route_name` UNIQUE constraint (GAP-007)
- `routes.is_active` check constraint with default (GAP-008)
- `staff_assignments.route_id` → `routes.id` FK (GAP-009)
- `customers.route_id` → `routes.id` FK (GAP-010)
- `routes.route_name` format validation (GAP-017)
- `routes.description` length validation (GAP-018)
- `routes.area_coverage` format validation (GAP-019)
- `payments.metal_grams_added` validation against `net_amount / metal_rate_per_gram` (GAP-063)
- Reversal payment validation (original payment exists, not already reversed, not itself a reversal) (GAP-070)
- `profiles.role` UPDATE prevention (except admin) (GAP-039)
- `staff_metadata.staff_type` UPDATE prevention (except admin) (GAP-040)

**Missing Indexes:**
- `idx_routes_route_name` (GAP-020)
- `idx_routes_active` (GAP-020)
- `idx_routes_created_at` (GAP-020)
- `idx_staff_assignments_route_active` (GAP-021)
- `idx_customers_route_active` (GAP-022)

**Missing Relationships:**
- `routes` → `staff_assignments` (via `route_id`) (GAP-002, GAP-011)
- `routes` → `customers` (via `route_id`) (GAP-003, GAP-011)
- `profiles` (staff) → `routes` (many-to-many or direct FK) (GAP-012)

---

### 6.2 RLS Policies

**Missing INSERT Policies:**
- `customers` INSERT for office staff (GAP-023)
- `user_schemes` INSERT for office staff (explicit policy) (GAP-024)
- `payments` INSERT for office staff with `staff_id = NULL` (GAP-025)
- `staff_assignments` INSERT for office staff (GAP-026)

**Missing UPDATE Policies:**
- `profiles` UPDATE for office staff (to update customer profiles) (GAP-027)

**Incorrect/Overly Permissive Policies:**
- `user_schemes` INSERT allows customer self-enrollment (should be office staff only) (GAP-028)
- `withdrawals` UPDATE allows any staff (should verify assignment) (GAP-029)
- `staff_metadata` SELECT allows unauthenticated access (security risk) (GAP-030)
- `customers` SELECT allows all staff (should filter by assignment for collection staff) (GAP-031)
- `payments` SELECT allows all staff (should filter by assignment for collection staff) (GAP-032)

**Missing Policies (When Routes Table Created):**
- `routes` SELECT for staff (GAP-042)
- `routes` ALL for office staff (GAP-042)
- `routes` ALL for admin (GAP-042)

---

### 6.3 Security & Authorization

**Frontend-Only Security (Should Be Database-Level):**
- Mobile app access check (GAP-033, GAP-074)
- Role validation in frontend (GAP-034, GAP-075)
- Staff type check in frontend (GAP-035, GAP-075)

**Missing Database Constraints:**
- Role change prevention (GAP-039)
- Staff type change prevention (GAP-040)
- Admin mobile app access prevention (database-level) (GAP-041)

**SECURITY DEFINER Function Risks:**
- `get_staff_email_by_code()` allows unauthenticated access (GAP-036)
- `get_customer_profile_for_staff()` lacks explicit auth check (GAP-037)
- Multiple SECURITY DEFINER functions create large attack surface (GAP-038, GAP-086)

---

### 6.4 Core User Flows

**Fully Implemented:**
- Customer Onboarding & First Login (OTP → PIN → Dashboard) (GAP-043)

**Partially Implemented (Missing Components):**
- Customer Payment Schedule & Transaction History:
  - Payment schedule calculation from `user_schemes` and `payments` tables (GAP-044)
  - Calendar view with due dates highlighted (GAP-044)
  - Transaction history screen (GAP-044)
  - Transaction detail screen (GAP-044)
  - Transaction filtering (GAP-044)
- Customer Investment Portfolio & Market Rates:
  - Total investment screen (GAP-045)
  - Gold/Silver asset detail screens (GAP-045)
  - Market rates screen (GAP-045)
  - Portfolio value calculation (GAP-045)
  - Database aggregation queries (GAP-045)
- Customer Profile Management:
  - Profile UPDATE queries verification (GAP-046)
  - Customer UPDATE queries verification (GAP-046)
  - Account information screen (GAP-046)
  - KYC details display (GAP-046)
- Collection Staff Payment Collection:
  - Offline payment queue (GAP-047, GAP-048)
  - Offline sync service (GAP-048)
  - Network connectivity detection (GAP-048)
  - Automatic sync on connection restore (GAP-048)
  - Queue management and conflict resolution (GAP-048)
- Customer Withdrawal Request:
  - Active enrollments query (GAP-055)
  - Market rates query (uses hardcoded rates) (GAP-055, GAP-060)
  - Total available grams calculation (GAP-055)
  - Current value calculation (GAP-055)
  - Withdrawal INSERT to database (GAP-055)
  - Success message with request ID (GAP-055)

**Not Implemented:**
- Office Staff Create Customer (GAP-049):
  - Customer registration form page
  - Supabase Auth user creation
  - Profile and customer INSERT
  - KYC document upload
  - Phone uniqueness validation
  - Customer detail page
- Office Staff Enroll Customer in Scheme (GAP-050):
  - Enrollment form page
  - Scheme selection dropdown
  - Payment frequency selection
  - Amount range input with validation
  - Start date selection
  - Maturity date calculation
  - Enrollment INSERT
  - Confirmation dialog
  - Customer notification
- Office Staff Assign Customer to Collection Staff (GAP-051):
  - Assignment interface page
  - Route selection (routes table missing)
  - Customer filtering by route
  - Staff selection dropdown
  - Bulk assignment functionality
  - Assignment INSERT
  - Confirmation dialog
- Office Staff Manual Payment Entry (GAP-052):
  - Manual payment entry form page
  - Customer search
  - Active scheme selection
  - Payment amount entry with validation
  - Payment method selection
  - Payment date/time entry
  - Notes field
  - Payment INSERT with `staff_id = NULL`
  - Receipt ID display
  - Transaction detail page
- Admin Financial Dashboard (GAP-053):
  - Admin dashboard page
  - Financial metrics queries (total customers, active schemes, today's collections, today's withdrawals, pending payments)
  - Inflow tracking page with queries, aggregation, charts, and tables
  - Outflow tracking page with queries, aggregation, charts, and tables
  - Cash flow analysis page with calculation, chart, and trend analysis
  - Data filtering
  - Export functionality
- Admin Market Rates Management (GAP-054):
  - Market rates management page
  - External API integration
  - Automated daily fetch (Edge Function or scheduled job)
  - Manual rate entry form
  - Manual override functionality
  - Rate history display
  - Rate deviation detection
  - Admin notification on API failure
- Withdrawal Approval/Processing (GAP-056):
  - Withdrawal approval interface for staff
  - Withdrawal status UPDATE queries
  - Withdrawal processing logic
  - Withdrawal rejection logic
  - Withdrawal list screen for staff
  - Customer notification on status change

---

### 6.5 Financial Logic & Integrity

**Rate Usage Issues:**
- Trigger recalculates `metal_grams_added` using current rate instead of payment rate (GAP-057, GAP-058, GAP-073)
- No validation that `metal_rate_per_gram` matches market rate at payment time (GAP-059)
- Withdrawal screen uses hardcoded rates instead of database query (GAP-060)
- No mechanism to verify `market_rates` has rate for every payment date (GAP-071)
- No validation that payment rate matches historical `market_rates` for payment date (GAP-072)

**Payment Calculation Issues:**
- Metal grams calculation can be overridden by trigger (GAP-062)
- No constraint ensuring `metal_grams_added` matches `net_amount / metal_rate_per_gram` (GAP-063)

**Reconciliation Capability Missing:**
- No reconciliation view/function for `user_schemes.total_amount_paid` vs sum of payments (GAP-064)
- No reconciliation view/function for `user_schemes.accumulated_grams` vs sum of payment grams (GAP-065)
- No reconciliation view/function for `user_schemes.payments_made` vs count of payments (GAP-066)
- No reconciliation queries for staff daily collections (GAP-067)

**Payment Immutability Issues:**
- Reversal payment logic does not verify original payment exists and is not already reversed (GAP-070)

---

### 6.6 Website Implementation

**Missing Website (Next.js):**
- Entire website implementation for Office Staff workflows (GAP-049, GAP-050, GAP-051, GAP-052)
- Entire website implementation for Admin workflows (GAP-053, GAP-054)
- Public-facing landing pages (PDR Section 2)
- Mobile-responsive website design (PDR Section 2)
- System administration UI (PDR Section 2)

**Missing Website Pages:**
- Public: `/`, `/about`, `/services`, `/contact`, `/login`
- Office Staff: `/office/dashboard`, `/office/customers`, `/office/customers/add`, `/office/customers/[id]`, `/office/customers/[id]/edit`, `/office/customers/[id]/enroll`, `/office/routes`, `/office/routes/add`, `/office/routes/[id]`, `/office/routes/[id]/assign-staff`, `/office/assignments`, `/office/assignments/by-route`, `/office/assignments/manual`, `/office/transactions`, `/office/transactions/add`, `/office/transactions/[id]`
- Admin: `/admin/dashboard`, `/admin/financials/inflow`, `/admin/financials/outflow`, `/admin/financials/cash-flow`, `/admin/customers`, `/admin/staff`, `/admin/staff/add`, `/admin/staff/[id]`, `/admin/staff/[id]/edit`, `/admin/schemes`, `/admin/schemes/[id]/edit`, `/admin/market-rates`, `/admin/market-rates/update`, `/admin/reports/*`, `/admin/settings`

---

### 6.7 Infrastructure & Services

**Missing Offline Support:**
- Offline payment queue storage (Flutter Secure Storage or SQLite) (GAP-048)
- Offline sync service implementation (GAP-048)
- Network connectivity detection (GAP-048)
- Automatic sync trigger on connection restore (GAP-048)
- Queue management (limit enforcement, status tracking) (GAP-048)
- Sync conflict resolution (GAP-048)

**Missing API Integration:**
- Market rates external API integration (GAP-054)
- Automated daily fetch (Edge Function or scheduled job) (GAP-054)
- API failure handling and retry logic (GAP-054)
- Rate deviation detection (>10% change flag) (GAP-054)

**Missing Notifications:**
- Automated email notifications (PDR Section 7)
- Automated SMS notifications (PDR Section 7)
- Push notifications (PDR Section 7)
- Customer notification on enrollment (GAP-050)
- Customer notification on withdrawal status change (GAP-056)
- Admin notification on API fetch failure (GAP-054)

---

### 6.8 Data Integrity & Validation

**Missing Validation:**
- Phone number uniqueness validation in customer creation (GAP-049)
- Payment rate validation against historical `market_rates` (GAP-059, GAP-072)
- Reversal payment validation (original exists, not reversed, not itself reversal) (GAP-070)
- Metal grams calculation validation (GAP-063)

**Missing Reconciliation:**
- `user_schemes.total_amount_paid` reconciliation (GAP-064)
- `user_schemes.accumulated_grams` reconciliation (GAP-065)
- `user_schemes.payments_made` reconciliation (GAP-066)
- Staff daily collections reconciliation (GAP-067)

**Missing Audit Trail:**
- Route audit trail (created_at, updated_at, created_by, updated_by) (GAP-013)

---

### 6.9 Code Quality & Architecture

**Mock Data Usage:**
- `lib/screens/customer/payment_schedule_screen.dart` uses `MockData.paymentSchedule` (GAP-044, GAP-079)
- `lib/screens/customer/profile_screen.dart` uses `MockData.userName` (GAP-079)
- `lib/screens/customer/account_information_page.dart` uses mock data (GAP-079)
- `lib/screens/customer/scheme_detail_screen.dart` uses `MockData.schemeDetails` (GAP-079)
- `lib/screens/staff/collect_payment_screen.dart` falls back to `MockData` rates (GAP-080)

**Imperative Navigation:**
- Multiple `Navigator.push()` calls in profile screens (GAP-081)
- `Navigator.pushReplacement()` in scheme detail screen (GAP-081)

**Unused Database Components:**
- Database views (`active_customer_schemes`, `today_collections`, `staff_daily_stats`) not queried by application (GAP-083)
- Offline sync columns (`device_id`, `client_timestamp`) exist but offline sync not implemented (GAP-084)

**Architectural Violations:**
- Frontend-only security checks (GAP-074, GAP-075)
- Dual auth authority (Supabase Auth + AuthFlowNotifier + Riverpod) (GAP-088)
- Mixed navigation authority (declarative + imperative) (GAP-081, GAP-082, GAP-089)
- Customer self-enrollment enabled (out-of-scope) (GAP-076, GAP-087)

---

### 6.10 Complete List of Missing MVP Requirements

**Database Schema:**
1. `routes` table with all columns, constraints, indexes, and RLS policies
2. `staff_assignments.route_id` column and FK constraint
3. `customers.route_id` column and FK constraint
4. `payments.sync_status` or `sync_conflict_id` for offline sync
5. `payments.metal_grams_added` validation constraint
6. Reversal payment validation constraints
7. Role and staff_type UPDATE prevention triggers
8. Reconciliation views/functions for `user_schemes` totals

**RLS Policies:**
9. `customers` INSERT for office staff
10. `user_schemes` INSERT for office staff (explicit, remove customer self-enrollment)
11. `payments` INSERT for office staff with `staff_id = NULL`
12. `staff_assignments` INSERT/UPDATE for office staff
13. `profiles` UPDATE for office staff (customer profiles)
14. `withdrawals` UPDATE policy fix (verify assignment)
15. `customers` SELECT policy fix (filter by assignment for collection staff)
16. `payments` SELECT policy fix (filter by assignment for collection staff)
17. `routes` RLS policies (when table created)

**Security:**
18. Database-level mobile app access prevention (admin/office staff)
19. Database-level role change prevention
20. Database-level staff_type change prevention
21. SECURITY DEFINER function authentication checks
22. Rate limiting for `get_staff_email_by_code()`

**Customer Flows:**
23. Payment schedule calculation from database
24. Payment schedule calendar view
25. Transaction history screen
26. Transaction detail screen
27. Transaction filtering
28. Total investment screen
29. Gold/Silver asset detail screens
30. Market rates screen
31. Portfolio value calculation
32. Profile UPDATE functionality verification
33. Account information screen
34. KYC details display
35. Withdrawal INSERT to database
36. Withdrawal market rates query (replace hardcoded)
37. Withdrawal total available grams calculation
38. Withdrawal current value calculation

**Collection Staff Flows:**
39. Offline payment queue storage
40. Offline sync service
41. Network connectivity detection
42. Automatic sync on connection restore
43. Queue management and conflict resolution
44. Offline queue full detection

**Office Staff Flows (Website):**
45. Customer registration form
46. Supabase Auth user creation
47. Profile and customer INSERT
48. KYC document upload
49. Customer detail page
50. Enrollment form page
51. Scheme selection dropdown
52. Enrollment INSERT
53. Customer notification on enrollment
54. Assignment interface page
55. Route selection dropdown
56. Customer filtering by route
57. Staff selection dropdown
58. Bulk assignment functionality
59. Assignment INSERT
60. Manual payment entry form
61. Customer search
62. Payment INSERT with `staff_id = NULL`
63. Transaction detail page

**Admin Flows (Website):**
64. Admin dashboard page
65. Financial metrics queries
66. Inflow tracking page with charts and tables
67. Outflow tracking page with charts and tables
68. Cash flow analysis page
69. Data filtering functionality
70. Export functionality (CSV/Excel)
71. Market rates management page
72. External API integration
73. Automated daily fetch
74. Manual rate entry form
75. Manual override functionality
76. Rate history display
77. Rate deviation detection
78. Admin notification on API failure

**Withdrawal Flows:**
79. Withdrawal approval interface for staff
80. Withdrawal status UPDATE queries
81. Withdrawal processing logic
82. Withdrawal rejection logic
83. Withdrawal list screen for staff
84. Customer notification on status change

**Infrastructure:**
85. Website implementation (Next.js)
86. Public-facing landing pages
87. Mobile-responsive website design
88. System administration UI
89. Automated email notifications
90. Automated SMS notifications
91. Push notifications
92. Market rates API integration
93. Scheduled job for daily rate fetch

**Data Integrity:**
94. Phone number uniqueness validation
95. Payment rate validation against historical rates
96. Reconciliation views/functions
97. Route audit trail columns

**Code Quality:**
98. Remove all mock data usage
99. Replace hardcoded rates with database queries
100. Remove imperative navigation (use declarative router)
101. Use database views instead of client-side aggregation
102. Implement offline sync or remove offline columns
103. Fix trigger to use payment rate, not current rate
104. Remove customer self-enrollment from RLS policy

---

**END OF DOCUMENT STRUCTURE**

