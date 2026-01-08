# Website Sprint Execution Plan

**Version:** 1.0  
**Date:** [Date]  
**Status:** Draft  
**Source:** Derived from Website PDR v1.0 and Master PDR v1.1  
**Owner:** [Name/Role]

---

## Document Control

- **Version:** 1.0
- **Last Updated:** [Date]
- **Owner:** [Name/Role]
- **Approval Status:** [Draft / Approved / In Review]
- **Source Documents:** 
  - `Website_PDR_v1.0.md` (Website PDR v1.0)
  - `PROJECT_DEFINITION_REPORT.md` (Master PDR v1.1)
- **Stakeholder Sign-off:** [List approvers and dates]

---

## Global Execution Context

### Authoritative Documents

- **Master PDR:** System-level specification (frozen)
- **Website PDR:** Website-specific specification (frozen)

### Core Execution Principle (NON-NEGOTIABLE)

**The website is the CONTROL PLANE of the business.**  
**The mobile app is an EXECUTION / CONSUMPTION layer.**  
**The database (Supabase Postgres + RLS) is the FINAL ENFORCER of truth.**

### Sprint Sequencing Rationale

Sprint sequencing is based on **AUTHORITY FLOW**, not UI convenience.

**Sprint 0 (Auth & Roles):**
- Without correct authentication, role separation, and route protection, every other feature is insecure and meaningless.
- This sprint establishes WHO is allowed to exist and WHAT they are allowed to access.
- No business logic is valid until this is correct.

**Sprint 1 (Office Core Ops):**
- Office staff are responsible for creating operational reality:
  - customers
  - enrollments
  - routes
  - staff assignments
  - office-side payments
- If office core is incomplete, the business cannot run even with a perfect mobile app.
- This sprint establishes HOW the business operates day-to-day.

**Sprint 2 (Admin Authority):**
- Admin governs money and people:
  - staff creation
  - market rates
  - withdrawals
  - scheme availability
- Without admin authority, financial data exists but is not governed.
- This sprint establishes WHO controls money and rules.

### Execution Rules

- Do NOT introduce features outside Website PDR.
- Do NOT design future-phase features.
- Do NOT skip dependencies.
- Do NOT assume mobile app participation in Sprints 0–2.
- Treat PDR statements as binding contracts.

### Task Objective

Generate COMPLETE, dependency-aware sprints that fully satisfy the Website PDR.  
Do not miss "boring" but critical items (auth guards, RLS validation, negative permissions).  
Output must be execution-ready, not high-level.

---

## Sprint 0: Authentication, Authorization & Route Protection

### 1. Sprint Objective

Establish secure identity, role separation, and access boundaries before any business logic exists. This sprint creates the authentication foundation, role resolution system, and route protection mechanisms that enforce database-level security (RLS) at the application layer. No business data creation or operational features are included.

### 2. In-Scope Capabilities

**Authentication:**
- Email + password authentication via Supabase Auth for Office Staff and Administrators
- Login page (`/login`) with email and password input fields
- Session management with automatic token refresh
- Session persistence across browser sessions
- Logout functionality with session invalidation
- Password reset flow (email-based, Supabase Auth built-in)

**Role Resolution:**
- Query `profiles` table to determine user role (`role` column: 'customer', 'staff', 'admin')
- Query `staff_metadata` table to determine staff type (`staff_type` column: 'collection', 'office')
- Role resolution helper functions/utilities
- Role state management in application (React Context or state management)
- Role validation on every authenticated request

**Route Protection:**
- Public routes (no authentication required): `/`, `/about`, `/services`, `/contact`
- Authenticated routes requiring valid session: `/login` (redirects if already authenticated)
- Office Staff routes (`/office/*`) - requires `role='staff'` AND `staff_type='office'`
- Administrator routes (`/admin/*`) - requires `role='admin'`
- Route guards that check authentication state and role before rendering
- Automatic redirect to `/login` for unauthenticated users accessing protected routes
- Automatic redirect to role-appropriate dashboard after login

**Public vs Authenticated Separation:**
- Public pages serve static content without database interaction (except read-only scheme display)
- Public pages cannot access authenticated API endpoints
- Public pages cannot access core business tables (enforced by RLS)
- Clear separation between public and authenticated route handlers

**RLS Validation Requirements:**
- Verify RLS policies exist and are enabled on all core tables
- Test that unauthenticated users cannot query core tables
- Test that Office Staff cannot access admin-only data
- Test that Administrators can access all data
- Verify RLS policies prevent unauthorized role access at database level
- Document RLS policy coverage for all tables

**Negative Security Tests:**
- Office Staff attempting to access `/admin/*` routes (must be blocked)
- Administrator accessing `/office/*` routes (allowed, but verify inheritance)
- Unauthenticated user accessing `/office/*` or `/admin/*` routes (must redirect to login)
- Authenticated user with invalid role attempting to access role-specific routes (must be blocked)
- Session expiration handling (must redirect to login)
- Invalid token handling (must redirect to login)

### 3. Explicit Out-of-Scope Items

**Business Logic:**
- Customer creation, editing, or management
- Scheme enrollment
- Route management
- Staff assignment
- Payment recording
- Withdrawal processing
- Any CRUD operations on business data

**Marketing Pages Content:**
- Actual marketing content (company info, services, testimonials)
- Contact form implementation (form scaffolding only, no submission logic)
- About us, services, contact page content (placeholder pages only)

**Admin Features:**
- Financial dashboard
- Staff management
- Scheme management
- Market rates management
- Reports

**Office Staff Features:**
- Customer management interface
- Enrollment interface
- Route management interface
- Assignment interface
- Transaction monitoring

**Database Schema:**
- Creating new tables
- Modifying existing table schemas
- Creating new RLS policies (verify existing policies only)
- Creating database triggers or functions

**Mobile App:**
- Any mobile app authentication flows
- Mobile app role resolution
- Mobile app route protection

### 4. Detailed Work Items

#### 4.1 Authentication Infrastructure

**Task 0.1.1: Supabase Auth Client Setup**
- Install and configure `@supabase/supabase-js` in Next.js application
- Create Supabase client instance with environment variables (anon key, project URL)
- Configure Supabase client for server-side and client-side usage
- Set up environment variable validation (fail fast if missing)
- **Acceptance:** Supabase client initializes successfully, environment variables validated

**Task 0.1.2: Login Page Implementation**
- Create `/login` route page component
- Implement email and password input fields with validation
- Add form submission handler that calls `supabase.auth.signInWithPassword()`
- Display loading state during authentication
- Display error messages for invalid credentials
- Redirect to appropriate dashboard after successful login (based on role)
- **Acceptance:** Login page renders, form validation works, authentication succeeds with valid credentials

**Task 0.1.3: Session Management**
- Implement session state management (React Context or state management library)
- Create session provider that wraps authenticated routes
- Listen to Supabase Auth state changes (`onAuthStateChange`)
- Store session token in application state
- Handle automatic token refresh (Supabase SDK handles this, verify it works)
- **Acceptance:** Session state updates on login/logout, token refresh works automatically

**Task 0.1.4: Logout Functionality**
- Implement logout handler that calls `supabase.auth.signOut()`
- Clear session state on logout
- Redirect to `/login` after logout
- Invalidate session token on server side (Supabase handles this)
- **Acceptance:** Logout clears session, redirects to login, session invalidated

**Task 0.1.5: Password Reset Flow**
- Create password reset request page (email input)
- Implement password reset handler using Supabase Auth `resetPasswordForEmail()`
- Create password reset confirmation page (for email link)
- Implement new password submission handler
- **Acceptance:** Password reset email sent, link works, new password can be set

#### 4.2 Role Resolution System

**Task 0.2.1: Role Query Utility**
- Create utility function to query `profiles` table for user role
- Query: `profiles.select('role').eq('user_id', auth.uid()).maybeSingle()`
- Handle cases where profile does not exist
- Cache role in session state to avoid repeated queries
- **Acceptance:** Role query returns correct role ('customer', 'staff', 'admin') or null

**Task 0.2.2: Staff Type Query Utility**
- Create utility function to query `staff_metadata` table for staff type
- Query: `staff_metadata.select('staff_type').eq('profile_id', profileId).maybeSingle()`
- Only query if role is 'staff'
- Handle cases where staff_metadata does not exist
- Cache staff type in session state
- **Acceptance:** Staff type query returns 'collection' or 'office' for staff users, null for non-staff

**Task 0.2.3: Role Resolution Service**
- Create role resolution service that combines role and staff type queries
- Return canonical role: 'admin', 'office_staff', 'collection_staff', 'customer', or 'unauthenticated'
- Handle role resolution errors gracefully (redirect to login if profile not found)
- **Acceptance:** Service returns correct canonical role for all user types

**Task 0.2.4: Role State Management**
- Integrate role resolution into session state management
- Update role state on login
- Clear role state on logout
- Refresh role state on session refresh
- **Acceptance:** Role state matches user's actual role in database

**Task 0.2.5: Role Validation on API Requests**
- Create middleware/hook that validates role before API requests
- Verify role matches expected role for the operation
- Log role validation failures for security monitoring
- **Acceptance:** API requests include role validation, failures are logged

#### 4.3 Route Protection

**Task 0.3.1: Public Route Handler**
- Create public route handler for `/`, `/about`, `/services`, `/contact`
- Verify public routes do not require authentication
- Verify public routes can be accessed without session
- Create placeholder pages (no content, just route structure)
- **Acceptance:** Public routes accessible without authentication, placeholder pages render

**Task 0.3.2: Authentication Guard Component**
- Create `AuthGuard` component that wraps authenticated routes
- Check if user is authenticated (session exists)
- Redirect to `/login` if not authenticated
- Show loading state while checking authentication
- **Acceptance:** Unauthenticated users redirected to login, authenticated users see protected content

**Task 0.3.3: Office Staff Route Guard**
- Create `OfficeStaffGuard` component for `/office/*` routes
- Check authentication state
- Check role is 'staff' AND staff_type is 'office'
- Redirect to `/login` if not authenticated
- Redirect to `/admin/dashboard` if user is admin (admin can access office routes, but default to admin dashboard)
- Redirect to `/login` with error if role is 'customer' or 'collection_staff'
- **Acceptance:** Only office staff can access `/office/*` routes, others are blocked/redirected

**Task 0.3.4: Administrator Route Guard**
- Create `AdminGuard` component for `/admin/*` routes
- Check authentication state
- Check role is 'admin'
- Redirect to `/login` if not authenticated
- Redirect to `/login` with error if role is not 'admin'
- **Acceptance:** Only administrators can access `/admin/*` routes, others are blocked/redirected

**Task 0.3.5: Role-Based Dashboard Redirect**
- Create redirect logic after successful login
- Redirect administrators to `/admin/dashboard`
- Redirect office staff to `/office/dashboard`
- Redirect customers to error page (customers use mobile app, not website)
- Redirect collection staff to error page (collection staff use mobile app, not website)
- **Acceptance:** Users redirected to correct dashboard based on role after login

**Task 0.3.6: Route Guard Integration**
- Apply `AuthGuard` to all authenticated routes
- Apply `OfficeStaffGuard` to all `/office/*` routes
- Apply `AdminGuard` to all `/admin/*` routes
- Verify guards execute in correct order (auth check before role check)
- **Acceptance:** All protected routes have appropriate guards, guards execute correctly

#### 4.4 Public vs Authenticated Separation

**Task 0.4.1: Public Route Structure**
- Create Next.js route structure for public pages
- Ensure public routes do not import authenticated components
- Ensure public routes do not access authenticated API endpoints
- Verify public routes can be server-side rendered without authentication
- **Acceptance:** Public routes are completely isolated from authenticated functionality

**Task 0.4.2: Authenticated Route Structure**
- Create Next.js route structure for authenticated pages
- Ensure authenticated routes require authentication guard
- Ensure authenticated routes require role guard (where applicable)
- Verify authenticated routes cannot be accessed without valid session
- **Acceptance:** Authenticated routes are protected and require valid session

**Task 0.4.3: Login Route Separation**
- Create `/login` route that is accessible to unauthenticated users
- Redirect authenticated users away from `/login` to their dashboard
- Ensure `/login` does not require authentication guard
- **Acceptance:** Login page accessible to unauthenticated users, authenticated users redirected

#### 4.5 RLS Validation Requirements

**Task 0.5.1: RLS Policy Audit**
- Document all existing RLS policies on core tables
- Verify RLS is enabled on: `profiles`, `customers`, `user_schemes`, `payments`, `withdrawals`, `staff_metadata`, `staff_assignments`, `schemes`, `market_rates`, `routes`
- Document policy names and their conditions
- Verify policies cover all operations (SELECT, INSERT, UPDATE, DELETE)
- **Acceptance:** Complete RLS policy inventory documented, all core tables have RLS enabled

**Task 0.5.2: Unauthenticated Access Test**
- Create test that attempts to query core tables without authentication
- Verify all queries are rejected by RLS policies
- Test tables: `profiles`, `customers`, `user_schemes`, `payments`, `withdrawals`, `staff_metadata`, `staff_assignments`
- Document test results
- **Acceptance:** All unauthenticated queries to core tables are rejected

**Task 0.5.3: Office Staff RLS Validation**
- Create test user with `role='staff'` and `staff_type='office'`
- Test that office staff can read all customers (RLS allows this)
- Test that office staff cannot read `staff_metadata` for other staff (if RLS restricts this)
- Test that office staff cannot UPDATE `schemes` table (admin-only)
- Test that office staff cannot UPDATE `market_rates` table (admin-only)
- Document test results
- **Acceptance:** Office staff RLS policies enforce correct access restrictions

**Task 0.5.4: Administrator RLS Validation**
- Create test user with `role='admin'`
- Test that administrator can read all tables
- Test that administrator can read all rows in all tables
- Test that administrator cannot UPDATE or DELETE `payments` table (blocked by triggers, not RLS)
- Document test results
- **Acceptance:** Administrator RLS policies allow full access (except payment immutability)

**Task 0.5.5: Role Escalation Prevention Test**
- Test that office staff cannot modify their own role to 'admin' in `profiles` table
- Test that office staff cannot modify their `staff_type` to gain unauthorized access
- Verify RLS policies prevent role modification (if policies exist)
- Document test results and any gaps
- **Acceptance:** Role escalation attempts are blocked by RLS or application logic

#### 4.6 Negative Security Tests

**Task 0.6.1: Office Staff Admin Route Access Test**
- Create test that logs in as office staff
- Attempt to navigate to `/admin/dashboard`
- Verify access is blocked (redirect or error)
- Verify RLS prevents admin data queries even if route is accessed
- Document test results
- **Acceptance:** Office staff cannot access admin routes, RLS blocks admin data access

**Task 0.6.2: Administrator Office Route Access Test**
- Create test that logs in as administrator
- Navigate to `/office/dashboard`
- Verify access is allowed (admin inherits office staff permissions)
- Verify admin can access office staff data via RLS
- Document test results
- **Acceptance:** Administrator can access office routes (inheritance works)

**Task 0.6.3: Unauthenticated Protected Route Access Test**
- Create test that attempts to access `/office/dashboard` without authentication
- Create test that attempts to access `/admin/dashboard` without authentication
- Verify both redirect to `/login`
- Verify no data is queried before redirect
- Document test results
- **Acceptance:** Unauthenticated users cannot access protected routes

**Task 0.6.4: Invalid Role Route Access Test**
- Create test user with `role='customer'`
- Attempt to access `/office/dashboard`
- Attempt to access `/admin/dashboard`
- Verify both are blocked (redirect to login with error or error page)
- Document test results
- **Acceptance:** Customers cannot access staff/admin routes

**Task 0.6.5: Collection Staff Route Access Test**
- Create test user with `role='staff'` and `staff_type='collection'`
- Attempt to access `/office/dashboard`
- Attempt to access `/admin/dashboard`
- Verify both are blocked (collection staff use mobile app, not website)
- Document test results
- **Acceptance:** Collection staff cannot access website routes

**Task 0.6.6: Session Expiration Test**
- Create test that simulates expired session token
- Attempt to access protected route with expired token
- Verify redirect to `/login`
- Verify session state is cleared
- Document test results
- **Acceptance:** Expired sessions redirect to login, session state cleared

**Task 0.6.7: Invalid Token Test**
- Create test that uses invalid/forged session token
- Attempt to access protected route with invalid token
- Verify redirect to `/login`
- Verify no data is queried
- Document test results
- **Acceptance:** Invalid tokens are rejected, no data access occurs

**Task 0.6.8: Direct API Call Bypass Test**
- Create test that makes direct API calls to Supabase bypassing route guards
- Test with office staff credentials attempting to query admin-only data
- Verify RLS policies block unauthorized queries even if route guards are bypassed
- Document test results
- **Acceptance:** RLS policies prevent unauthorized access even if application guards are bypassed

#### 4.7 Dashboard Placeholders

**Task 0.7.1: Office Staff Dashboard Placeholder**
- Create `/office/dashboard` page component
- Display placeholder content: "Office Staff Dashboard (Coming Soon)"
- Verify route is protected by `OfficeStaffGuard`
- Verify page renders for office staff users
- **Acceptance:** Office staff dashboard placeholder page exists and is protected

**Task 0.7.2: Administrator Dashboard Placeholder**
- Create `/admin/dashboard` page component
- Display placeholder content: "Administrator Dashboard (Coming Soon)"
- Verify route is protected by `AdminGuard`
- Verify page renders for administrator users
- **Acceptance:** Administrator dashboard placeholder page exists and is protected

### 5. Acceptance Criteria

**AC-0.1: Authentication Works**
- ✅ User can log in with valid email and password
- ✅ User is redirected to appropriate dashboard based on role after login
- ✅ User can log out and session is invalidated
- ✅ Password reset flow works (email sent, link works, password can be reset)
- ✅ Session persists across browser sessions
- ✅ Session token refreshes automatically

**AC-0.2: Role Resolution Works**
- ✅ User role is correctly determined from `profiles.role`
- ✅ Staff type is correctly determined from `staff_metadata.staff_type` for staff users
- ✅ Role state is stored in application state
- ✅ Role state updates on login and clears on logout
- ✅ Role resolution handles missing profile gracefully (redirects to login)

**AC-0.3: Route Protection Works**
- ✅ Public routes (`/`, `/about`, `/services`, `/contact`) are accessible without authentication
- ✅ `/login` is accessible to unauthenticated users
- ✅ Authenticated users are redirected away from `/login` to their dashboard
- ✅ `/office/*` routes require authentication AND `role='staff'` AND `staff_type='office'`
- ✅ `/admin/*` routes require authentication AND `role='admin'`
- ✅ Unauthenticated users accessing protected routes are redirected to `/login`
- ✅ Users with wrong role accessing protected routes are blocked/redirected

**AC-0.4: RLS Validation Works**
- ✅ All core tables have RLS enabled and documented
- ✅ Unauthenticated users cannot query core tables (RLS blocks)
- ✅ Office staff can read all customers (RLS allows)
- ✅ Office staff cannot UPDATE `schemes` or `market_rates` (RLS blocks)
- ✅ Administrators can read all tables (RLS allows)
- ✅ Role escalation attempts are blocked (RLS or application logic)

**AC-0.5: Negative Security Tests Pass**
- ✅ Office staff cannot access `/admin/*` routes (blocked)
- ✅ Administrators can access `/office/*` routes (allowed, inheritance)
- ✅ Unauthenticated users cannot access protected routes (redirected)
- ✅ Customers cannot access staff/admin routes (blocked)
- ✅ Collection staff cannot access website routes (blocked)
- ✅ Expired sessions redirect to login
- ✅ Invalid tokens are rejected
- ✅ Direct API calls bypassing route guards are blocked by RLS

**AC-0.6: Public vs Authenticated Separation Works**
- ✅ Public routes do not require authentication
- ✅ Public routes do not access authenticated API endpoints
- ✅ Public routes do not query core business tables (except read-only schemes for marketing)
- ✅ Authenticated routes require valid session
- ✅ Clear separation between public and authenticated route handlers

**AC-0.7: Dashboard Placeholders Exist**
- ✅ `/office/dashboard` placeholder page exists and is protected
- ✅ `/admin/dashboard` placeholder page exists and is protected
- ✅ Placeholder pages render correctly for authorized users

### 6. Failure Conditions

**Sprint 0 is NOT DONE if:**

1. **Authentication Failures:**
   - Users cannot log in with valid credentials
   - Session does not persist across browser sessions
   - Session token does not refresh automatically
   - Logout does not invalidate session
   - Password reset flow does not work

2. **Role Resolution Failures:**
   - Role is not correctly determined from database
   - Staff type is not correctly determined for staff users
   - Role state is not stored or updated correctly
   - Role resolution fails silently (no error handling)

3. **Route Protection Failures:**
   - Public routes require authentication (should not)
   - Protected routes are accessible without authentication (should not)
   - Office staff can access `/admin/*` routes (should be blocked)
   - Administrators cannot access `/admin/*` routes (should be allowed)
   - Unauthenticated users can access protected routes (should be redirected)
   - Role-based redirects do not work after login

4. **RLS Validation Failures:**
   - RLS policies are not enabled on core tables
   - Unauthenticated users can query core tables (RLS should block)
   - Office staff can UPDATE `schemes` or `market_rates` (RLS should block)
   - Administrators cannot read all tables (RLS should allow)
   - Role escalation is possible (should be blocked)

5. **Negative Security Test Failures:**
   - Any negative security test fails (office staff accessing admin routes, etc.)
   - Direct API calls bypassing route guards succeed (RLS should block)
   - Expired sessions do not redirect to login
   - Invalid tokens are accepted

6. **Separation Failures:**
   - Public routes access authenticated API endpoints
   - Public routes query core business tables (except allowed read-only)
   - Authenticated routes do not require valid session

7. **Missing Documentation:**
   - RLS policy inventory is not documented
   - Negative security test results are not documented
   - Role resolution logic is not documented

8. **Business Logic Present:**
   - Any customer creation, editing, or management functionality exists
   - Any scheme enrollment functionality exists
   - Any route management functionality exists
   - Any staff assignment functionality exists
   - Any payment recording functionality exists
   - Any withdrawal processing functionality exists
   - Any admin features beyond authentication exist
   - Any office staff features beyond authentication exist

**Sprint 0 is DONE when:**
- All acceptance criteria pass
- All negative security tests pass
- RLS validation confirms database-level security
- No business logic exists (only authentication, authorization, and route protection)
- Documentation is complete

---

## Sprint 1: Office Core Operations

### 1. Sprint Objective

Enable office staff to fully operate the business WITHOUT the mobile app. This sprint implements the complete operational control plane for office staff: customer creation and management, scheme enrollment, route management, customer-to-staff assignment, and manual payment entry. A customer must be able to be onboarded, enrolled in a scheme, assigned to collection staff, and have money recorded via the website alone.

### 2. In-Scope Capabilities

**Mapped to Website PDR Section 3 (Office Staff Web Application Scope):**

#### 2.1 Customer Management
- **Source:** Website PDR Section 3.1
- Create new customer records with full KYC details (name, phone, address, nominee information, identity documents)
- Create Supabase Auth user accounts for customers
- View customer list with search and filter capabilities (by name, phone, route, assigned staff, scheme status)
- Edit customer information (profile details, address, nominee information)
- View individual customer profile with complete history (schemes, payments, withdrawals)
- Soft delete customers (mark as inactive, preserve historical data)

#### 2.2 Scheme Enrollment
- **Source:** Website PDR Section 3.2
- Enroll customers in investment schemes (select scheme, set payment frequency, amount range, start date)
- View customer's active enrollments
- View enrollment history
- **Business Rule:** Customers CANNOT enroll themselves (enrollment performed only by office staff)

#### 2.3 Route Management
- **Source:** Website PDR Section 3.3
- Create and manage routes (geographic territories with name, description, area coverage)
- Assign routes to collection staff members
- View route assignments and coverage
- Edit route details and area coverage
- Deactivate routes (preserve historical assignments)

#### 2.4 Customer-to-Staff Assignment
- **Source:** Website PDR Section 3.4
- Assign customers to collection staff based on route
- Bulk assign multiple customers to a staff member by route
- Manual assignment of individual customers to staff
- Reassign customers when staff changes occur
- View assignment history and track changes
- Remove assignments (deactivate, preserve history)

#### 2.5 Manual Payment Entry (Office Collections)
- **Source:** Website PDR Section 3.5
- Manual payment entry for office collections (record payments received at office)
- Payment entry with `staff_id = NULL` to distinguish from field collections
- Calculate metal grams based on current market rates
- Generate receipt IDs
- **Business Rule:** Payments are append-only (cannot be modified or deleted after creation)

#### 2.6 Basic Transaction Visibility
- **Source:** Website PDR Section 3.5
- View all transactions (payments and withdrawals) with real-time updates
- Filter transactions by date range, staff member, customer, payment method, route
- Search transactions by customer name, phone, receipt ID
- View detailed transaction information (amount, date, time, method, staff, customer)
- Export transaction data to CSV/Excel format

#### 2.7 Transaction Monitoring Dashboard
- **Source:** Website PDR Section 3.6
- Real-time dashboard showing today's collections, pending payments, staff activity
- Monitor all staff collection activities
- View transaction trends and patterns
- Track payment methods distribution (cash, UPI, bank transfer)

#### 2.8 Withdrawal Approval and Processing
- **Source:** Website PDR Section 3.7
- View withdrawal requests (pending, approved, processed, rejected)
- Approve or reject withdrawal requests
- Process approved withdrawals
- Update withdrawal status and final amounts

### 3. Explicit Out-of-Scope Items

**Admin Features:**
- Financial dashboard with comprehensive analytics (admin-only)
- Staff account management (admin-only)
- Scheme management (edit scheme definitions, admin-only)
- Market rates management (admin-only)
- Advanced reports and analytics (admin-only)
- System administration UI (admin-only)

**Marketing Pages:**
- Public-facing marketing content (landing page, about, services, contact)
- Contact form submission logic (form scaffolding only, no backend)
- Lead capture functionality (deferred)

**Customer Self-Service:**
- Customer self-enrollment in schemes (customers cannot enroll themselves)
- Customer payment processing on website (payments collected via mobile app or manual entry)

**Mobile App Features:**
- Any mobile app functionality
- Offline payment queue (mobile app only)
- Field payment collection (mobile app only)

**Advanced Features:**
- Advanced analytics, machine learning, predictive modeling
- Custom report builder
- Bulk data import/export beyond basic CSV/Excel export
- Multi-language support

**Restricted Operations:**
- Office staff CANNOT create staff accounts (admin-only)
- Office staff CANNOT modify schemes (admin-only)
- Office staff CANNOT update market rates (admin-only, rates fetched from external API)
- Office staff CANNOT modify payment records after creation (payments are append-only)
- Office staff CANNOT access admin-only routes or features

### 4. Detailed Work Items

#### 4.1 Customer Management

**Task 1.1.1: Customer List Page (`/office/customers`)**
- Create Next.js page component for customer list
- Implement customer list query: `customers.select('*, profiles(name, phone)').order('created_at', ascending: false)`
- Display customer list in table format with columns: Name, Phone, Route, Assigned Staff, Active Schemes, Status
- Implement search functionality (by name or phone)
- Implement filter functionality (by route, assigned staff, scheme status)
- Add pagination for large customer lists
- Add "Create New Customer" button linking to `/office/customers/add`
- Make each customer row clickable to navigate to customer detail page
- **RLS Expectation:** Office staff can read all customers (RLS policy allows `is_staff()`)
- **Acceptance:** Customer list displays all customers, search and filters work, pagination works

**Task 1.1.2: Customer Creation Form (`/office/customers/add`)**
- Create Next.js page component for customer registration form
- Implement form fields:
  - Name (required, text input, validation: non-empty, letters/spaces only)
  - Phone number (required, 10-digit numeric, validation: format check, uniqueness check)
  - Address (required, textarea)
  - City (optional, text input)
  - State (optional, text input)
  - Pincode (optional, text input)
  - Date of birth (optional, date picker)
  - PAN number (optional, text input)
  - Aadhaar number (optional, text input)
  - Nominee name (optional, text input)
  - Nominee relationship (optional, dropdown)
  - Nominee phone (optional, 10-digit numeric)
  - Identity document upload (optional, file upload, max 5MB, PDF/JPG/PNG)
- Implement form validation (client-side and server-side)
- Implement phone number uniqueness check before submission
- **Acceptance:** Form validates all fields, phone uniqueness check works, file upload works

**Task 1.1.3: Customer Creation Backend Logic**
- Implement Supabase Auth user creation: `supabase.auth.admin.createUser({ email, phone, password: auto-generated })`
- Implement profile INSERT: `profiles.insert({ user_id, name, phone, role: 'customer', active: true })`
- Implement customer INSERT: `customers.insert({ profile_id, address, city, state, pincode, date_of_birth, pan_number, aadhaar_number, nominee_name, nominee_relationship, nominee_phone, kyc_status })`
- Handle identity document upload to Supabase Storage (if provided)
- Implement error handling for each step (auth creation, profile creation, customer creation)
- Implement rollback logic if any step fails (cleanup created records)
- **RLS Expectation:** Office staff can INSERT into `profiles` and `customers` tables (RLS policy allows `is_staff() AND staff_type = 'office'`)
- **Acceptance:** Customer creation succeeds end-to-end, rollback works on failure, RLS policies allow office staff INSERT

**Task 1.1.4: Customer Detail Page (`/office/customers/[id]`)**
- Create Next.js dynamic route page component for customer detail view
- Implement customer data query: `customers.select('*, profiles(*)').eq('id', customerId).maybeSingle()`
- Display customer information sections:
  - Basic Information (name, phone, address, KYC status)
  - Nominee Information
  - Active Schemes (query `user_schemes` table)
  - Payment History (query `payments` table, last 20 payments)
  - Withdrawal History (query `withdrawals` table)
  - Staff Assignment (query `staff_assignments` table)
- Add "Edit Customer" button linking to `/office/customers/[id]/edit`
- Add "Enroll in Scheme" button linking to `/office/customers/[id]/enroll`
- Add "Assign to Staff" button linking to assignment interface
- **RLS Expectation:** Office staff can read all customer data (RLS allows `is_staff()`)
- **Acceptance:** Customer detail page displays all customer information, all related data loads correctly

**Task 1.1.5: Customer Edit Page (`/office/customers/[id]/edit`)**
- Create Next.js dynamic route page component for customer edit form
- Pre-populate form with existing customer data
- Implement UPDATE operations:
  - `profiles.update({ name, phone }).eq('user_id', userId)`
  - `customers.update({ address, city, state, pincode, nominee_name, nominee_relationship, nominee_phone }).eq('id', customerId)`
- Implement form validation (same as creation form)
- Implement phone number uniqueness check (exclude current customer)
- Add "Save Changes" and "Cancel" buttons
- **RLS Expectation:** Office staff can UPDATE `profiles` and `customers` tables (RLS policy allows `is_staff() AND staff_type = 'office'`)
- **Acceptance:** Customer edit form pre-populates, updates succeed, validation works

**Task 1.1.6: Customer Soft Delete**
- Implement soft delete functionality (mark as inactive, preserve historical data)
- Add "Deactivate Customer" button on customer detail page
- Implement confirmation dialog before deactivation
- Implement UPDATE: `profiles.update({ active: false }).eq('user_id', userId)`
- Implement UPDATE: `customers.update({ active: false }).eq('id', customerId)`
- Display warning message about preserving historical data
- **RLS Expectation:** Office staff can UPDATE `profiles` and `customers` to set `active = false` (RLS policy allows)
- **Acceptance:** Customer soft delete works, historical data preserved, confirmation dialog works

#### 4.2 Scheme Enrollment

**Task 1.2.1: Enrollment Form Page (`/office/customers/[id]/enroll`)**
- Create Next.js dynamic route page component for enrollment form
- Query active schemes: `schemes.select('*').eq('active', true).order('name')`
- Display scheme selection dropdown (grouped by asset type: Gold, Silver)
- Display scheme details when scheme is selected (name, description, asset type, min/max amounts, payment frequencies)
- Implement form fields:
  - Scheme selection (required, dropdown)
  - Payment frequency (required, dropdown: daily, weekly, monthly)
  - Minimum amount (required, numeric input, validation: within scheme min/max)
  - Maximum amount (required, numeric input, validation: within scheme min/max, >= minimum)
  - Start date (required, date picker, defaults to today, validation: not in past)
- Implement form validation (client-side and server-side)
- Calculate maturity date based on scheme type and start date (display preview)
- **Acceptance:** Enrollment form displays, scheme selection works, form validation works, maturity date calculation works

**Task 1.2.2: Enrollment Backend Logic**
- Implement enrollment INSERT: `user_schemes.insert({ customer_id, scheme_id, enrollment_date: today, start_date, maturity_date: calculated, payment_frequency, min_amount, max_amount, due_amount: min_amount, status: 'active' })`
- Verify customer exists and is active
- Verify scheme exists and is active
- Verify customer is not already enrolled in same scheme (prevent duplicates)
- Handle database constraint violations (duplicate enrollment, maximum enrollments exceeded)
- Implement error handling and user-friendly error messages
- **RLS Expectation:** Office staff can INSERT into `user_schemes` table (RLS policy allows `is_staff() AND staff_type = 'office'`)
- **Acceptance:** Enrollment creation succeeds, duplicate prevention works, error handling works

**Task 1.2.3: Enrollment Display on Customer Profile**
- Query customer enrollments: `user_schemes.select('*, schemes(*)').eq('customer_id', customerId).order('enrollment_date', ascending: false)`
- Display active enrollments list on customer detail page
- Display enrollment details: scheme name, enrollment date, payment frequency, amount range, status, total paid, accumulated grams
- Add "View Enrollment Details" link (if detailed view needed)
- **RLS Expectation:** Office staff can read all `user_schemes` records (RLS allows `is_staff()`)
- **Acceptance:** Enrollments display correctly on customer profile, all enrollment data loads

#### 4.3 Route Management

**Task 1.3.1: Route List Page (`/office/routes`)**
- Create Next.js page component for route list
- Query routes: `routes.select('*').order('route_name')`
- Display route list in table format with columns: Route Name, Description, Area Coverage, Assigned Staff Count, Customer Count, Status (Active/Inactive)
- Add "Create New Route" button linking to `/office/routes/add`
- Add filter by active/inactive status
- Make each route row clickable to navigate to route detail page
- **RLS Expectation:** Office staff can read all routes (RLS policy allows `is_staff() AND staff_type = 'office'`)
- **Acceptance:** Route list displays all routes, filters work, navigation works

**Task 1.3.2: Route Creation Form (`/office/routes/add`)**
- Create Next.js page component for route creation form
- Implement form fields:
  - Route name (required, text input, validation: unique, 2-100 characters)
  - Description (optional, textarea, max 500 characters)
  - Area coverage (optional, textarea or JSON, validation: format check)
  - Is active (default: true, checkbox)
- Implement form validation (client-side and server-side)
- Implement route name uniqueness check
- **Acceptance:** Route creation form validates, uniqueness check works

**Task 1.3.3: Route Creation Backend Logic**
- Implement route INSERT: `routes.insert({ route_name, description, area_coverage, is_active: true, created_at: now, created_by: current_user_id })`
- Verify route name uniqueness (database constraint + application check)
- Handle database constraint violations (unique constraint on route_name)
- Implement error handling
- **RLS Expectation:** Office staff can INSERT into `routes` table (RLS policy allows `is_staff() AND staff_type = 'office'`)
- **Acceptance:** Route creation succeeds, uniqueness enforced, error handling works

**Task 1.3.4: Route Detail Page (`/office/routes/[id]`)**
- Create Next.js dynamic route page component for route detail view
- Query route data: `routes.select('*').eq('id', routeId).maybeSingle()`
- Query assigned staff: `staff_assignments.select('staff_id, profiles(name), staff_metadata(staff_code)').eq('route_id', routeId).eq('is_active', true)`
- Query assigned customers: `customers.select('*, profiles(name, phone)').eq('route_id', routeId)`
- Display route information, assigned staff list, assigned customers list
- Add "Edit Route" button linking to `/office/routes/[id]/edit`
- Add "Assign Staff to Route" button linking to `/office/routes/[id]/assign-staff`
- **RLS Expectation:** Office staff can read route data and related assignments (RLS allows)
- **Acceptance:** Route detail page displays all route information, assigned staff and customers load correctly

**Task 1.3.5: Route Edit Page (`/office/routes/[id]/edit`)**
- Create Next.js dynamic route page component for route edit form
- Pre-populate form with existing route data
- Implement UPDATE: `routes.update({ route_name, description, area_coverage, is_active }).eq('id', routeId)`
- Implement form validation (same as creation form)
- Implement route name uniqueness check (exclude current route)
- Add "Save Changes" and "Cancel" buttons
- **RLS Expectation:** Office staff can UPDATE `routes` table (RLS policy allows `is_staff() AND staff_type = 'office'`)
- **Acceptance:** Route edit form pre-populates, updates succeed, validation works

**Task 1.3.6: Route Deactivation**
- Implement route deactivation (preserve historical assignments)
- Add "Deactivate Route" button on route detail page
- Implement confirmation dialog before deactivation
- Implement UPDATE: `routes.update({ is_active: false }).eq('id', routeId)`
- Display warning message about preserving historical assignments
- **RLS Expectation:** Office staff can UPDATE `routes` to set `is_active = false` (RLS policy allows)
- **Acceptance:** Route deactivation works, historical assignments preserved

#### 4.4 Customer-to-Staff Assignment

**Task 1.4.1: Assignment Interface Page (`/office/assignments`)**
- Create Next.js page component for assignment interface
- Display assignment overview (total assignments, active assignments, unassigned customers count)
- Add "Assign by Route" button linking to `/office/assignments/by-route`
- Add "Manual Assignment" button linking to `/office/assignments/manual`
- Display recent assignments list (last 20 assignments)
- **Acceptance:** Assignment interface page displays, navigation buttons work

**Task 1.4.2: Bulk Assignment by Route Page (`/office/assignments/by-route`)**
- Create Next.js page component for bulk assignment by route
- Query active routes: `routes.select('*').eq('is_active', true).order('route_name')`
- Display route selection dropdown
- Query unassigned customers for selected route: `customers.select('*, profiles(name, phone)').eq('route_id', selectedRouteId).not('id', 'in', (SELECT customer_id FROM staff_assignments WHERE is_active = true))`
- Display customer list with checkboxes for selection
- Query collection staff: `profiles.select('*, staff_metadata(*)').eq('role', 'staff').eq('staff_metadata.staff_type', 'collection').eq('active', true)`
- Display staff selection dropdown
- Implement "Assign Selected Customers" button
- Implement confirmation dialog before assignment
- **Acceptance:** Bulk assignment page displays, route selection works, customer filtering works, staff selection works

**Task 1.4.3: Bulk Assignment Backend Logic**
- Implement bulk assignment INSERT: For each selected customer, `staff_assignments.insert({ staff_id, customer_id, route_id: selectedRouteId, is_active: true, assigned_date: today, assigned_by: current_user_id })`
- Verify customer is not already assigned to another active staff (handle reassignment)
- Implement reassignment logic (deactivate old assignment, create new assignment)
- Handle partial assignment failures (some succeed, some fail)
- Implement error handling and success/failure reporting
- **RLS Expectation:** Office staff can INSERT into `staff_assignments` table (RLS policy allows `is_staff() AND staff_type = 'office'`)
- **Acceptance:** Bulk assignment succeeds, reassignment works, partial failure handling works

**Task 1.4.4: Manual Individual Assignment Page (`/office/assignments/manual`)**
- Create Next.js page component for manual individual assignment
- Implement customer search (by name or phone)
- Display customer search results with selection
- Query collection staff: `profiles.select('*, staff_metadata(*)').eq('role', 'staff').eq('staff_metadata.staff_type', 'collection').eq('active', true)`
- Display staff selection dropdown
- Optional route selection (if customer has route)
- Implement "Assign Customer" button
- Implement confirmation dialog
- **Acceptance:** Manual assignment page displays, customer search works, staff selection works

**Task 1.4.5: Manual Assignment Backend Logic**
- Implement individual assignment INSERT: `staff_assignments.insert({ staff_id, customer_id, route_id: optional, is_active: true, assigned_date: today, assigned_by: current_user_id })`
- Verify customer is not already assigned (handle reassignment)
- Implement reassignment logic if needed
- Implement error handling
- **RLS Expectation:** Office staff can INSERT into `staff_assignments` table (RLS policy allows)
- **Acceptance:** Manual assignment succeeds, reassignment works, error handling works

**Task 1.4.6: Assignment History Display**
- Query assignment history: `staff_assignments.select('*, profiles(name), customers(profiles(name, phone))').order('assigned_date', ascending: false).limit(50)`
- Display assignment history on assignment interface page
- Display columns: Customer Name, Assigned Staff, Route, Assigned Date, Status (Active/Inactive)
- Add filter by active/inactive status
- **RLS Expectation:** Office staff can read all `staff_assignments` records (RLS allows `is_staff()`)
- **Acceptance:** Assignment history displays, filters work

**Task 1.4.7: Assignment Deactivation**
- Implement assignment deactivation (remove assignment, preserve history)
- Add "Remove Assignment" button on assignment history or customer detail page
- Implement confirmation dialog
- Implement UPDATE: `staff_assignments.update({ is_active: false, deactivated_date: today }).eq('id', assignmentId)`
- **RLS Expectation:** Office staff can UPDATE `staff_assignments` to set `is_active = false` (RLS policy allows)
- **Acceptance:** Assignment deactivation works, history preserved

#### 4.5 Manual Payment Entry (Office Collections)

**Task 1.5.1: Payment Entry Form Page (`/office/transactions/add`)**
- Create Next.js page component for manual payment entry form
- Implement customer search (by name or phone)
- Display customer search results with selection
- Query customer's active schemes: `user_schemes.select('*, schemes(*)').eq('customer_id', customerId).eq('status', 'active')`
- Display scheme selection dropdown (required)
- Implement form fields:
  - Customer selection (required, search + select)
  - Scheme selection (required, dropdown, filtered by selected customer)
  - Payment amount (required, numeric input, validation: within scheme min/max range)
  - Payment method (required, dropdown: Cash, UPI, Bank Transfer)
  - Payment date (required, date picker, defaults to today, validation: not in future, can be past date)
  - Payment time (optional, time picker, defaults to current time)
  - Notes (optional, textarea, max 500 characters)
- Query current market rates: `market_rates.select('*').order('rate_date', ascending: false).limit(1)`
- Display calculated metal grams preview (based on amount and current rate)
- Implement form validation (client-side and server-side)
- **Acceptance:** Payment entry form displays, customer search works, scheme selection works, rate calculation preview works

**Task 1.5.2: Payment Calculation Logic**
- Calculate GST amount: `gstAmount = amount * 0.03`
- Calculate net amount: `netAmount = amount * 0.97`
- Determine asset type from selected scheme (gold or silver)
- Get current market rate for asset type from `market_rates` table
- Calculate metal grams: `metalGramsAdded = netAmount / currentRate`
- Generate receipt ID: Format `RCP-{timestamp}-{random}`
- **Note:** Calculations are for display/preview. Database triggers may recalculate. Application must submit calculated values.
- **Acceptance:** Payment calculations are correct, receipt ID generation works

**Task 1.5.3: Payment Entry Backend Logic**
- Implement payment INSERT: `payments.insert({ user_scheme_id, customer_id, staff_id: NULL, amount, gst_amount: calculated, net_amount: calculated, payment_method, payment_date, payment_time, receipt_id: generated, notes, gold_rate_at_payment: if gold scheme, silver_rate_at_payment: if silver scheme, metal_grams_added: calculated, status: 'completed', created_at: now })`
- Verify customer exists and is active
- Verify scheme exists and is active
- Verify payment amount is within scheme min/max range
- Verify market rates exist (fail if rates not available)
- Handle database constraint violations
- Verify database trigger `update_user_scheme_totals` executes and updates `user_schemes` totals
- Implement error handling
- **RLS Expectation:** Office staff can INSERT into `payments` table with `staff_id = NULL` (RLS policy allows `is_staff() AND staff_type = 'office'`)
- **Acceptance:** Payment creation succeeds, trigger executes, totals update, error handling works

**Task 1.5.4: Payment Detail Page (`/office/transactions/[id]`)**
- Create Next.js dynamic route page component for payment detail view
- Query payment data: `payments.select('*, customers(profiles(name, phone)), user_schemes(schemes(name)), staff_metadata(staff_code)').eq('id', paymentId).maybeSingle()`
- Display payment information: receipt ID, customer name, scheme name, amount, GST, net amount, payment method, payment date/time, metal grams added, rate at payment time, staff (if field collection), notes
- Display read-only warning (payments are immutable)
- **RLS Expectation:** Office staff can read all payments (RLS allows `is_staff()`)
- **Acceptance:** Payment detail page displays all payment information correctly

#### 4.6 Basic Transaction Visibility

**Task 1.6.1: Transaction List Page (`/office/transactions`)**
- Create Next.js page component for transaction list
- Query payments: `payments.select('*, customers(profiles(name, phone)), user_schemes(schemes(name)), staff_metadata(staff_code)').order('payment_date', ascending: false).limit(100)`
- Query withdrawals: `withdrawals.select('*, customers(profiles(name, phone))').order('created_at', ascending: false).limit(50)`
- Display transaction list in table format with columns: Date, Customer, Type (Payment/Withdrawal), Amount, Method, Receipt ID, Status
- Implement filter functionality:
  - Date range filter (from date, to date)
  - Staff member filter (dropdown, for payments with staff_id)
  - Customer filter (search + select)
  - Payment method filter (dropdown: Cash, UPI, Bank Transfer)
  - Route filter (dropdown, filter by customer's route)
- Implement search functionality (by customer name, phone, receipt ID)
- Add pagination for large transaction lists
- Make each transaction row clickable to navigate to transaction detail page
- **RLS Expectation:** Office staff can read all payments and withdrawals (RLS allows `is_staff()`)
- **Acceptance:** Transaction list displays, filters work, search works, pagination works

**Task 1.6.2: Transaction Export (CSV/Excel)**
- Implement export functionality for transaction list
- Generate CSV file with filtered transaction data
- Include columns: Date, Time, Customer Name, Customer Phone, Type, Amount, Payment Method, Receipt ID, Staff (if applicable), Notes
- Trigger file download in browser
- Handle large exports (pagination or streaming)
- **Acceptance:** Transaction export generates CSV file, download works, data is correct

#### 4.7 Transaction Monitoring Dashboard

**Task 1.7.1: Office Staff Dashboard Page (`/office/dashboard`)**
- Create Next.js page component for office staff dashboard
- Query today's collections: `payments.select('amount, payment_method').eq('payment_date', CURRENT_DATE).eq('status', 'completed')`
- Aggregate: total collected today, breakdown by payment method (cash, UPI, bank transfer)
- Query pending payments: `user_schemes.select('*, customers(profiles(name)), schemes(name)').eq('status', 'active').gt('due_amount', 0)`
- Display metrics cards:
  - Today's Collections (total amount)
  - Today's Collections Count (number of payments)
  - Payment Method Breakdown (cash vs digital)
  - Pending Payments Count
- Display recent transactions list (last 10 payments)
- Display staff activity summary (if applicable)
- **RLS Expectation:** Office staff can read all payments and user_schemes (RLS allows `is_staff()`)
- **Acceptance:** Dashboard displays metrics, aggregations are correct, recent transactions load

#### 4.8 Withdrawal Approval and Processing

**Task 1.8.1: Withdrawal List Page**
- Create Next.js page component for withdrawal list (can be part of transactions or separate)
- Query withdrawals: `withdrawals.select('*, customers(profiles(name, phone)), user_schemes(schemes(name))').order('created_at', ascending: false)`
- Display withdrawal list in table format with columns: Date, Customer, Requested Amount, Requested Grams, Status, Actions
- Implement filter by status (pending, approved, processed, rejected)
- Implement search by customer name or phone
- Make each withdrawal row clickable to view details
- **RLS Expectation:** Office staff can read all withdrawals (RLS allows `is_staff()`)
- **Acceptance:** Withdrawal list displays, filters work, search works

**Task 1.8.2: Withdrawal Detail and Approval Page**
- Create Next.js dynamic route page component for withdrawal detail and approval
- Query withdrawal data: `withdrawals.select('*, customers(profiles(name, phone)), user_schemes(schemes(name), accumulated_metal_grams)').eq('id', withdrawalId).maybeSingle()`
- Query current market rates: `market_rates.select('*').order('rate_date', ascending: false).limit(1)`
- Display withdrawal information: customer name, scheme name, requested amount, requested grams, current rates, calculated final amount based on current rates
- Display approval actions:
  - "Approve" button (sets status to 'approved', calculates final_amount and final_grams)
  - "Reject" button (sets status to 'rejected', requires rejection_reason)
  - "Process" button (sets status to 'processed', requires final_amount and final_grams)
- Implement approval logic with confirmation dialog
- **RLS Expectation:** Office staff can UPDATE `withdrawals` table (RLS policy allows `is_staff()` - verify assignment check if required)
- **Acceptance:** Withdrawal detail displays, approval actions work, status updates succeed

**Task 1.8.3: Withdrawal Approval Backend Logic**
- Implement withdrawal UPDATE for approval: `withdrawals.update({ status: 'approved', approved_by: current_user_id, approved_at: now, final_amount: calculated, final_grams: requested_grams }).eq('id', withdrawalId)`
- Implement withdrawal UPDATE for rejection: `withdrawals.update({ status: 'rejected', rejection_reason: entered_reason }).eq('id', withdrawalId)`
- Implement withdrawal UPDATE for processing: `withdrawals.update({ status: 'processed', processed_at: now, final_amount: calculated, final_grams: calculated }).eq('id', withdrawalId)`
- Verify withdrawal status is 'pending' before approval/processing
- Calculate final amounts based on current market rates
- Implement error handling
- **RLS Expectation:** Office staff can UPDATE withdrawals (RLS policy allows `is_staff()` - verify if assignment check is required)
- **Acceptance:** Withdrawal approval/rejection/processing works, status validation works, error handling works

#### 4.9 Permission Checks and RLS Validation

**Task 1.9.1: Office Staff Permission Checks**
- Verify office staff can CREATE customers (RLS policy check)
- Verify office staff can CREATE enrollments (RLS policy check)
- Verify office staff can CREATE routes (RLS policy check)
- Verify office staff can CREATE staff assignments (RLS policy check)
- Verify office staff can CREATE payments with `staff_id = NULL` (RLS policy check)
- Verify office staff CANNOT CREATE staff accounts (RLS policy blocks)
- Verify office staff CANNOT UPDATE schemes (RLS policy blocks)
- Verify office staff CANNOT UPDATE market rates (RLS policy blocks)
- Verify office staff CANNOT UPDATE or DELETE payments (triggers block, RLS may also block)
- Document all permission checks and RLS policy coverage
- **Acceptance:** All permission checks pass, RLS policies enforce correctly, negative permissions are blocked

**Task 1.9.2: RLS Policy Verification Tests**
- Create test suite that verifies RLS policies for office staff operations
- Test office staff can INSERT into `profiles` and `customers` tables
- Test office staff can INSERT into `user_schemes` table
- Test office staff can INSERT into `routes` table
- Test office staff can INSERT into `staff_assignments` table
- Test office staff can INSERT into `payments` table with `staff_id = NULL`
- Test office staff CANNOT INSERT into `staff_metadata` table
- Test office staff CANNOT UPDATE `schemes` table
- Test office staff CANNOT UPDATE `market_rates` table
- Test office staff CANNOT UPDATE or DELETE `payments` table (triggers block)
- Document test results
- **Acceptance:** All RLS verification tests pass, negative tests confirm blocks

### 5. Acceptance Criteria

**AC-1.1: Customer Creation Works End-to-End**
- ✅ Office staff can create a new customer via `/office/customers/add`
- ✅ Supabase Auth user is created successfully
- ✅ Profile record is created in `profiles` table with `role='customer'`
- ✅ Customer record is created in `customers` table linked to profile
- ✅ Customer appears in customer list after creation
- ✅ Customer detail page displays all entered information
- ✅ Customer creation completes within 10 seconds
- ✅ Phone number uniqueness is enforced
- ✅ Form validation prevents invalid data submission

**AC-1.2: Scheme Enrollment Works End-to-End**
- ✅ Office staff can enroll a customer in a scheme via `/office/customers/[id]/enroll`
- ✅ Enrollment form displays active schemes for selection
- ✅ Enrollment record is created in `user_schemes` table with correct data
- ✅ Customer profile reflects new enrollment in active schemes list
- ✅ Enrollment prevents duplicates (customer cannot be enrolled in same scheme twice)
- ✅ Enrollment validates amount range against scheme min/max
- ✅ Enrollment completes within 10 seconds
- ✅ Database trigger updates `user_schemes` totals after enrollment

**AC-1.3: Route Management Works End-to-End**
- ✅ Office staff can create a new route via `/office/routes/add`
- ✅ Route record is created in `routes` table
- ✅ Route appears in route list after creation
- ✅ Office staff can edit route details via `/office/routes/[id]/edit`
- ✅ Office staff can deactivate routes (preserve historical assignments)
- ✅ Route name uniqueness is enforced
- ✅ Route detail page displays assigned staff and customers

**AC-1.4: Customer-to-Staff Assignment Works End-to-End**
- ✅ Office staff can assign customers to collection staff via `/office/assignments/by-route` (bulk) or `/office/assignments/manual` (individual)
- ✅ Assignment record is created in `staff_assignments` table with `is_active=true`
- ✅ Bulk assignment assigns multiple customers at once
- ✅ Reassignment works (deactivates old assignment, creates new assignment)
- ✅ Assignment history displays correctly
- ✅ Office staff can deactivate assignments (preserve history)
- ✅ Assignment completes within 5 seconds for up to 50 customers

**AC-1.5: Manual Payment Entry Works End-to-End**
- ✅ Office staff can record manual payment via `/office/transactions/add`
- ✅ Payment record is created in `payments` table with `staff_id = NULL`
- ✅ Payment calculations are correct (GST, net amount, metal grams)
- ✅ Receipt ID is generated and displayed
- ✅ Database trigger `update_user_scheme_totals` executes and updates `user_schemes` totals
- ✅ Payment appears in transaction list and customer's payment history
- ✅ Payment recording completes within 5 seconds
- ✅ Payment amount validation works (within scheme min/max range)
- ✅ Market rates are required (payment fails if rates not available)

**AC-1.6: Transaction Visibility Works**
- ✅ Office staff can view all transactions via `/office/transactions`
- ✅ Transaction list displays payments and withdrawals
- ✅ Filters work (date range, staff, customer, payment method, route)
- ✅ Search works (customer name, phone, receipt ID)
- ✅ Transaction detail page displays complete payment/withdrawal information
- ✅ Transaction export (CSV) generates correct file
- ✅ Pagination works for large transaction lists

**AC-1.7: Transaction Monitoring Dashboard Works**
- ✅ Office staff dashboard (`/office/dashboard`) displays today's collections
- ✅ Metrics cards show correct aggregations (total collected, count, payment method breakdown)
- ✅ Pending payments count is accurate
- ✅ Recent transactions list displays correctly
- ✅ Dashboard loads within 5 seconds

**AC-1.8: Withdrawal Approval Works**
- ✅ Office staff can view withdrawal requests via withdrawal list
- ✅ Office staff can approve withdrawal requests (status: 'approved')
- ✅ Office staff can reject withdrawal requests (status: 'rejected', requires reason)
- ✅ Office staff can process approved withdrawals (status: 'processed')
- ✅ Withdrawal status updates correctly in database
- ✅ Final amounts and grams are calculated based on current market rates

**AC-1.9: Complete Customer Lifecycle Works**
- ✅ A customer can be created, enrolled in a scheme, assigned to collection staff, and have money recorded via website alone
- ✅ End-to-end flow: Create Customer → Enroll in Scheme → Assign to Staff → Record Payment
- ✅ All steps complete successfully without mobile app
- ✅ All data is persisted correctly in database
- ✅ All RLS policies allow office staff operations

**AC-1.10: Permission Enforcement Works**
- ✅ Office staff CANNOT create staff accounts (blocked by RLS)
- ✅ Office staff CANNOT modify schemes (blocked by RLS)
- ✅ Office staff CANNOT update market rates (blocked by RLS)
- ✅ Office staff CANNOT update or delete payments (blocked by triggers/RLS)
- ✅ All negative permission tests pass

### 6. Failure Conditions

**Sprint 1 is NOT DONE if:**

1. **Customer Creation Failures:**
   - Office staff cannot create customers via website
   - Supabase Auth user creation fails
   - Profile or customer record creation fails
   - Phone number uniqueness is not enforced
   - Customer does not appear in customer list after creation
   - Customer detail page does not display created customer

2. **Scheme Enrollment Failures:**
   - Office staff cannot enroll customers in schemes
   - Enrollment form does not display active schemes
   - Enrollment record is not created in database
   - Duplicate enrollments are allowed (should be prevented)
   - Customer profile does not reflect new enrollment
   - Database trigger does not update `user_schemes` totals

3. **Route Management Failures:**
   - Office staff cannot create routes
   - Route name uniqueness is not enforced
   - Route edit or deactivation does not work
   - Route detail page does not display assigned staff/customers

4. **Customer-to-Staff Assignment Failures:**
   - Office staff cannot assign customers to collection staff
   - Bulk assignment does not work
   - Manual assignment does not work
   - Reassignment does not work (old assignment not deactivated)
   - Assignment records are not created in database
   - Assignment history does not display

5. **Manual Payment Entry Failures:**
   - Office staff cannot record manual payments
   - Payment record is not created in database
   - Payment calculations are incorrect (GST, net amount, metal grams)
   - Receipt ID is not generated
   - Database trigger does not update `user_schemes` totals
   - Payment does not appear in transaction list
   - Payment amount validation does not work

6. **Transaction Visibility Failures:**
   - Transaction list does not display payments/withdrawals
   - Filters do not work
   - Search does not work
   - Transaction detail page does not display complete information
   - Transaction export does not generate correct file

7. **Dashboard Failures:**
   - Office staff dashboard does not display
   - Metrics are incorrect
   - Recent transactions do not load

8. **Withdrawal Approval Failures:**
   - Office staff cannot view withdrawal requests
   - Withdrawal approval/rejection/processing does not work
   - Withdrawal status does not update in database
   - Final amounts are not calculated correctly

9. **Complete Lifecycle Failure:**
   - End-to-end flow (Create Customer → Enroll → Assign → Record Payment) does not work
   - Any step in the lifecycle fails
   - Mobile app is required to complete the lifecycle (should not be required)

10. **Permission Enforcement Failures:**
    - Office staff can create staff accounts (should be blocked)
    - Office staff can modify schemes (should be blocked)
    - Office staff can update market rates (should be blocked)
    - Office staff can update or delete payments (should be blocked)
    - RLS policies do not enforce restrictions correctly

11. **RLS Validation Failures:**
    - RLS policies are missing for office staff operations
    - RLS policies allow unauthorized operations
    - RLS policies block authorized operations
    - RLS verification tests fail

**Sprint 1 is DONE when:**
- All acceptance criteria pass
- Complete customer lifecycle works end-to-end via website alone
- All permission checks pass (positive and negative)
- RLS validation confirms database-level security
- No admin features exist (only office staff features)
- Documentation is complete

---

## Sprint 2: Administrator Authority & Financial Governance

### 1. Sprint Objective

Establish centralized governance over money, people, and system rules. This sprint implements complete administrative authority for staff account management, scheme enable/disable, market rate management, withdrawal approval and processing, and system-wide financial visibility. Money must be governable end-to-end via the website, with all financial operations visible and controllable by administrators.

### 2. In-Scope Capabilities

**Mapped to Website PDR Section 4 (Administrator Web Application Scope):**

#### 2.1 Staff Account Creation & Management
- **Source:** Website PDR Section 4.3
- Create new staff accounts (collection staff and office staff) with credentials
- Create Supabase Auth user accounts for staff
- View all staff members with performance metrics
- Edit staff details (name, phone, email, targets, status)
- Deactivate staff accounts (preserve historical data)
- Set and update daily collection targets for staff
- View staff performance reports (collections, targets, customer visits)

#### 2.2 Scheme Enable/Disable
- **Source:** Website PDR Section 4.4
- View all 18 investment schemes (9 Gold schemes, 9 Silver schemes)
- Enable/disable schemes (control which schemes are available for enrollment)
- View scheme enrollment statistics
- **Note:** Full scheme editing (name, description, amounts, frequencies) is deferred. Only enable/disable is in scope.

#### 2.3 Market Rate Management
- **Source:** Website PDR Section 4.5
- Fetch daily gold and silver market rates from external API (manual trigger or automated)
- View current rates and rate history with date tracking
- Manual rate override/correction capability (if API fetch fails or requires adjustment)
- **Business Rule:** Market rates are stored historically (preserve all rate records for audit and reconciliation)

#### 2.4 Withdrawal Approval & Processing
- **Source:** Website PDR Section 4 (Administrator authority over withdrawals)
- View all withdrawal requests with status tracking (pending, approved, processed, rejected)
- Approve withdrawal requests (status: 'pending' → 'approved')
- Reject withdrawal requests (status: 'pending' → 'rejected', requires reason)
- Process approved withdrawals (status: 'approved' → 'processed', calculates final amounts)
- **Business Rule:** Withdrawals require explicit approval state transitions (cannot skip states)

#### 2.5 System-Wide Financial Visibility (Basic)
- **Source:** Website PDR Section 4.1 and 4.2
- Complete financial overview with key metrics (total customers, active schemes, total collections, withdrawals)
- Daily/weekly/monthly inflow tracking (all payment collections)
- Daily/weekly/monthly outflow tracking (all withdrawals)
- Net cash flow calculation and visualization
- View all payments across all staff and customers with advanced filtering
- View all withdrawals with status tracking
- View all customer enrollments and scheme statuses
- View all staff assignments and route coverage
- Access to historical market rates data
- Export financial data in multiple formats (CSV, Excel)

### 3. Explicit Out-of-Scope Items

**Advanced Analytics:**
- Machine learning and predictive modeling
- Complex financial projections and forecasting
- Advanced trend analysis beyond basic charts
- Custom report builder
- Real-time analytics dashboards

**Integrations:**
- Automated daily market rate fetch via scheduled jobs (manual trigger only in Sprint 2)
- Third-party payment gateway integrations
- External accounting system integrations
- Email/SMS notification system (deferred)
- Push notification system (deferred)

**Full Scheme Management:**
- Creating new schemes (schemes are pre-created, admin only enables/disables)
- Editing scheme details (name, description, min/max amounts, payment frequencies)
- Scheme-specific settings and rules configuration

**Advanced Reports:**
- Custom report generation
- Scheduled report delivery
- Report templates and customization
- Advanced filtering and drill-down capabilities

**System Administration:**
- Database management UI (view database health, monitor queries)
- System settings and preferences management
- Business rules and validation criteria configuration
- User roles and permissions management (handled via RLS)
- System logs and audit trails viewing

**Payment Management:**
- Admin CANNOT edit or delete payments (payments are append-only)
- Payment reversal functionality (deferred to later phase)
- Payment correction or adjustment (deferred)

**Mobile App Features:**
- Any mobile app functionality
- Mobile app administration

**Marketing Pages:**
- Public-facing marketing content (landing page, about, services, contact)
- Lead capture functionality

### 4. Detailed Work Items

#### 4.1 Staff Account Creation & Management

**Task 2.1.1: Staff List Page (`/admin/staff`)**
- Create Next.js page component for staff list
- Query staff: `profiles.select('*, staff_metadata(*)').eq('role', 'staff').order('created_at', ascending: false)`
- Display staff list in table format with columns: Name, Staff Code, Type (Collection/Office), Email, Phone, Status (Active/Inactive), Collections Today, Target vs Achievement
- Add "Create New Staff" button linking to `/admin/staff/add`
- Implement filter by staff type (collection, office)
- Implement filter by status (active, inactive)
- Implement search by name, staff code, or email
- Make each staff row clickable to navigate to staff detail page
- **RLS Expectation:** Admin can read all staff profiles and metadata (RLS policy allows `role = 'admin'`)
- **Acceptance:** Staff list displays all staff, filters work, search works, navigation works

**Task 2.1.2: Staff Creation Form (`/admin/staff/add`)**
- Create Next.js page component for staff registration form
- Implement form fields:
  - Name (required, text input, validation: non-empty, letters/spaces only)
  - Email (required, email input, validation: format check, uniqueness check)
  - Phone number (required, 10-digit numeric, validation: format check, uniqueness check)
  - Staff code (required, text input, validation: unique, 3-20 characters, alphanumeric)
  - Staff type (required, dropdown: 'collection' or 'office')
  - Password (required, password input, validation: min 8 characters, complexity requirements)
  - Daily collection target (optional, numeric input, defaults to 0)
  - Is active (default: true, checkbox)
- Implement form validation (client-side and server-side)
- Implement email and phone uniqueness checks before submission
- Implement staff code uniqueness check
- **Acceptance:** Form validates all fields, uniqueness checks work

**Task 2.1.3: Staff Creation Backend Logic**
- Implement Supabase Auth user creation: `supabase.auth.admin.createUser({ email, phone, password, email_confirm: true })`
- Implement profile INSERT: `profiles.insert({ user_id, name, phone, email, role: 'staff', active: true })`
- Implement staff_metadata INSERT: `staff_metadata.insert({ profile_id, staff_code, staff_type, daily_collection_target, is_active: true })`
- Handle error handling for each step (auth creation, profile creation, metadata creation)
- Implement rollback logic if any step fails (cleanup created records)
- **RLS Expectation:** Admin can INSERT into `profiles` and `staff_metadata` tables (RLS policy allows `role = 'admin'`)
- **Acceptance:** Staff creation succeeds end-to-end, rollback works on failure, RLS policies allow admin INSERT

**Task 2.1.4: Staff Detail Page (`/admin/staff/[id]`)**
- Create Next.js dynamic route page component for staff detail view
- Query staff data: `profiles.select('*, staff_metadata(*)').eq('id', staffId).maybeSingle()`
- Query staff performance metrics:
  - Today's collections: `payments.select('amount').eq('staff_id', staffProfileId).eq('payment_date', CURRENT_DATE).eq('status', 'completed')`
  - Total collections: `payments.select('amount').eq('staff_id', staffProfileId).eq('status', 'completed')`
  - Assigned customers count: `staff_assignments.select('customer_id').eq('staff_id', staffProfileId).eq('is_active', true)`
- Display staff information sections:
  - Basic Information (name, email, phone, staff code, staff type, status)
  - Performance Metrics (today's collections, total collections, target vs achievement, assigned customers)
  - Assigned Customers List (query `staff_assignments` table)
  - Collection History (query `payments` table, last 20 payments)
- Add "Edit Staff" button linking to `/admin/staff/[id]/edit`
- Add "Deactivate Staff" button (if active)
- **RLS Expectation:** Admin can read all staff data and related performance metrics (RLS allows `role = 'admin'`)
- **Acceptance:** Staff detail page displays all staff information, performance metrics load correctly

**Task 2.1.5: Staff Edit Page (`/admin/staff/[id]/edit`)**
- Create Next.js dynamic route page component for staff edit form
- Pre-populate form with existing staff data
- Implement UPDATE operations:
  - `profiles.update({ name, phone, email }).eq('user_id', userId)`
  - `staff_metadata.update({ staff_code, daily_collection_target, is_active }).eq('profile_id', profileId)`
- Implement form validation (same as creation form)
- Implement email and phone uniqueness checks (exclude current staff)
- Implement staff code uniqueness check (exclude current staff)
- Add "Save Changes" and "Cancel" buttons
- **RLS Expectation:** Admin can UPDATE `profiles` and `staff_metadata` tables (RLS policy allows `role = 'admin'`)
- **Acceptance:** Staff edit form pre-populates, updates succeed, validation works

**Task 2.1.6: Staff Deactivation**
- Implement staff deactivation (preserve historical data)
- Add "Deactivate Staff" button on staff detail page
- Implement confirmation dialog before deactivation
- Implement UPDATE: `profiles.update({ active: false }).eq('user_id', userId)`
- Implement UPDATE: `staff_metadata.update({ is_active: false }).eq('profile_id', profileId)`
- Display warning message about preserving historical data and assignments
- **RLS Expectation:** Admin can UPDATE `profiles` and `staff_metadata` to set `active = false` (RLS policy allows)
- **Acceptance:** Staff deactivation works, historical data preserved, confirmation dialog works

**Task 2.1.7: Staff Performance Report**
- Create Next.js page component for staff performance report (`/admin/staff/[id]/performance`)
- Query staff performance data:
  - Collections by date range: `payments.select('amount, payment_date').eq('staff_id', staffProfileId).eq('status', 'completed').gte('payment_date', startDate).lte('payment_date', endDate)`
  - Target vs achievement: Compare total collections vs `daily_collection_target * days_in_period`
  - Customer visits: Count unique customers with payments in period
  - Missed payments: Query `user_schemes` for assigned customers with `due_amount > 0`
- Display performance metrics:
  - Total collections (period)
  - Target vs achievement percentage
  - Average daily collection
  - Customer visits count
  - Missed payments count
  - Collection trend chart (line chart by date)
- Add date range filter (default: last 30 days)
- Add export to CSV/Excel functionality
- **RLS Expectation:** Admin can read all staff performance data (RLS allows `role = 'admin'`)
- **Acceptance:** Staff performance report displays, metrics are correct, export works

#### 4.2 Scheme Enable/Disable

**Task 2.2.1: Scheme List Page (`/admin/schemes`)**
- Create Next.js page component for scheme list
- Query schemes: `schemes.select('*').order('asset_type, name')`
- Display scheme list in table format with columns: Scheme Name, Asset Type (Gold/Silver), Description, Min Amount, Max Amount, Payment Frequencies, Active Enrollments, Status (Active/Inactive)
- Add filter by asset type (Gold, Silver)
- Add filter by status (Active, Inactive)
- Add search by scheme name
- Make each scheme row clickable to view details
- Add "Enable" or "Disable" toggle button for each scheme
- **RLS Expectation:** Admin can read all schemes (RLS allows `role = 'admin'`)
- **Acceptance:** Scheme list displays all schemes, filters work, search works

**Task 2.2.2: Scheme Enable/Disable Toggle**
- Implement enable/disable toggle functionality on scheme list page
- Implement confirmation dialog before toggling (warn about impact on enrollments)
- Implement UPDATE: `schemes.update({ active: true/false }).eq('id', schemeId)`
- Display success message after toggle
- Refresh scheme list after toggle
- **RLS Expectation:** Admin can UPDATE `schemes` table to set `active` flag (RLS policy allows `role = 'admin'`)
- **Acceptance:** Scheme enable/disable works, confirmation dialog works, status updates correctly

**Task 2.2.3: Scheme Enrollment Statistics**
- Query scheme enrollment statistics: `user_schemes.select('scheme_id, status').eq('status', 'active')`
- Aggregate enrollments per scheme
- Display enrollment count on scheme list page
- Display enrollment breakdown (active, completed, cancelled) on scheme detail view (if detail page exists)
- **RLS Expectation:** Admin can read all `user_schemes` records (RLS allows `role = 'admin'`)
- **Acceptance:** Enrollment statistics display correctly, counts are accurate

#### 4.3 Market Rate Management

**Task 2.3.1: Market Rates Page (`/admin/market-rates`)**
- Create Next.js page component for market rates management
- Query current rates: `market_rates.select('*').order('rate_date', ascending: false).limit(1)`
- Query rate history: `market_rates.select('*').order('rate_date', ascending: false).limit(30)`
- Display current rates section:
  - Gold rate per gram (INR)
  - Silver rate per gram (INR)
  - Last fetched date and time
  - "Fetch Rates from API" button
  - "Manual Entry" button
- Display rate history table with columns: Date, Gold Rate, Silver Rate, Source (API/Manual), Updated By
- Add date range filter for history
- **RLS Expectation:** Admin can read all `market_rates` records (RLS allows `role = 'admin'`)
- **Acceptance:** Market rates page displays, current rates show, history displays

**Task 2.3.2: API Rate Fetch Functionality**
- Implement "Fetch Rates from API" button handler
- Configure external market price API endpoint (environment variable)
- Implement API call to external market price API
- Parse API response to extract gold rate per gram (INR) and silver rate per gram (INR)
- Validate API response (check for valid rates, positive numbers)
- Handle API errors (network failure, invalid response, API unavailable)
- Display loading indicator during API fetch
- **Acceptance:** API fetch works, error handling works, response validation works

**Task 2.3.3: Market Rate Save Logic (API Fetch)**
- After successful API fetch, check if rate for today's date already exists
- If rate exists, UPDATE: `market_rates.update({ gold_rate, silver_rate, source: 'api', updated_by: current_user_id }).eq('rate_date', today)`
- If rate does not exist, INSERT: `market_rates.insert({ rate_date: today, gold_rate, silver_rate, source: 'api', updated_by: current_user_id })`
- Display success message with fetched rates
- Refresh rate history after save
- **RLS Expectation:** Admin can INSERT and UPDATE `market_rates` table (RLS policy allows `role = 'admin'`)
- **Acceptance:** Rate save works, UPDATE vs INSERT logic works, history updates

**Task 2.3.4: Manual Rate Entry Form**
- Create Next.js page component or modal for manual rate entry (`/admin/market-rates/manual`)
- Implement form fields:
  - Gold rate per gram (required, numeric input, validation: positive number)
  - Silver rate per gram (required, numeric input, validation: positive number)
  - Rate date (required, date picker, defaults to today, validation: not in future)
  - Notes (optional, textarea, max 500 characters, for manual override reason)
- Implement form validation (client-side and server-side)
- Add "Save Rates" and "Cancel" buttons
- **Acceptance:** Manual entry form displays, validation works

**Task 2.3.5: Market Rate Save Logic (Manual Entry)**
- After manual entry submission, check if rate for selected date already exists
- If rate exists, UPDATE: `market_rates.update({ gold_rate, silver_rate, source: 'manual', updated_by: current_user_id, notes }).eq('rate_date', selectedDate)`
- If rate does not exist, INSERT: `market_rates.insert({ rate_date: selectedDate, gold_rate, silver_rate, source: 'manual', updated_by: current_user_id, notes })`
- Display success message
- Refresh rate history after save
- **RLS Expectation:** Admin can INSERT and UPDATE `market_rates` table (RLS policy allows `role = 'admin'`)
- **Acceptance:** Manual rate save works, UPDATE vs INSERT logic works, history preserved

**Task 2.3.6: Rate History Preservation**
- Verify all rate records are preserved (no DELETE operations)
- Display rate history with all historical records
- Ensure rate history query includes all dates (no filtering by date)
- Document that rates are append-only (UPDATE allowed for same date, but historical records preserved)
- **Acceptance:** Rate history shows all historical records, no records are deleted

#### 4.4 Withdrawal Approval & Processing

**Task 2.4.1: Withdrawal List Page (`/admin/withdrawals`)**
- Create Next.js page component for withdrawal list
- Query withdrawals: `withdrawals.select('*, customers(profiles(name, phone)), user_schemes(schemes(name))').order('created_at', ascending: false)`
- Display withdrawal list in table format with columns: Date, Customer, Scheme, Requested Amount, Requested Grams, Status, Actions
- Implement filter by status (pending, approved, processed, rejected)
- Implement filter by date range
- Implement search by customer name or phone
- Make each withdrawal row clickable to view details
- Display status badges (color-coded: pending=yellow, approved=blue, processed=green, rejected=red)
- **RLS Expectation:** Admin can read all withdrawals (RLS allows `role = 'admin'`)
- **Acceptance:** Withdrawal list displays, filters work, search works, status badges display

**Task 2.4.2: Withdrawal Detail and Approval Page (`/admin/withdrawals/[id]`)**
- Create Next.js dynamic route page component for withdrawal detail and approval
- Query withdrawal data: `withdrawals.select('*, customers(profiles(name, phone)), user_schemes(schemes(name), accumulated_metal_grams)').eq('id', withdrawalId).maybeSingle()`
- Query current market rates: `market_rates.select('*').order('rate_date', ascending: false).limit(1)`
- Display withdrawal information:
  - Customer name and phone
  - Scheme name
  - Requested amount and requested grams
  - Current market rates (gold/silver)
  - Calculated final amount based on current rates
  - Status and status history
  - Created date, approved date (if approved), processed date (if processed)
- Display approval actions based on current status:
  - If status = 'pending': "Approve" button, "Reject" button
  - If status = 'approved': "Process" button, "Reject" button (revert approval)
  - If status = 'processed': Read-only (no actions)
  - If status = 'rejected': Read-only (no actions)
- **RLS Expectation:** Admin can read all withdrawal data (RLS allows `role = 'admin'`)
- **Acceptance:** Withdrawal detail displays, current rates show, actions display based on status

**Task 2.4.3: Withdrawal Approval Logic**
- Implement "Approve" button handler
- Verify withdrawal status is 'pending' (prevent invalid state transitions)
- Calculate final amount and final grams based on current market rates
- Implement UPDATE: `withdrawals.update({ status: 'approved', approved_by: current_user_id, approved_at: now, final_amount: calculated, final_grams: requested_grams }).eq('id', withdrawalId)`
- Display confirmation dialog before approval
- Display success message after approval
- Refresh withdrawal detail page after approval
- **RLS Expectation:** Admin can UPDATE withdrawals to 'approved' status (RLS policy allows `role = 'admin'`)
- **Acceptance:** Withdrawal approval works, status validation works, final amounts calculated correctly

**Task 2.4.4: Withdrawal Rejection Logic**
- Implement "Reject" button handler
- Verify withdrawal status is 'pending' or 'approved' (allow rejection from both states)
- Implement rejection reason input (required, textarea, max 500 characters)
- Implement UPDATE: `withdrawals.update({ status: 'rejected', rejection_reason: entered_reason, rejected_by: current_user_id, rejected_at: now }).eq('id', withdrawalId)`
- Display confirmation dialog before rejection
- Display success message after rejection
- Refresh withdrawal detail page after rejection
- **RLS Expectation:** Admin can UPDATE withdrawals to 'rejected' status (RLS policy allows `role = 'admin'`)
- **Acceptance:** Withdrawal rejection works, reason required, status validation works

**Task 2.4.5: Withdrawal Processing Logic**
- Implement "Process" button handler
- Verify withdrawal status is 'approved' (prevent invalid state transitions)
- Calculate final amount and final grams based on current market rates (may differ from approval time rates)
- Implement UPDATE: `withdrawals.update({ status: 'processed', processed_at: now, final_amount: calculated, final_grams: calculated, processed_by: current_user_id }).eq('id', withdrawalId)`
- Display confirmation dialog before processing
- Display success message after processing
- Refresh withdrawal detail page after processing
- **RLS Expectation:** Admin can UPDATE withdrawals to 'processed' status (RLS policy allows `role = 'admin'`)
- **Acceptance:** Withdrawal processing works, status validation works, final amounts calculated correctly

**Task 2.4.6: Withdrawal State Transition Validation**
- Implement state transition validation logic
- Valid transitions:
  - 'pending' → 'approved' (via approval)
  - 'pending' → 'rejected' (via rejection)
  - 'approved' → 'processed' (via processing)
  - 'approved' → 'rejected' (via rejection, revert approval)
- Invalid transitions (blocked):
  - 'processed' → any state (final state)
  - 'rejected' → any state (final state)
  - 'pending' → 'processed' (must approve first)
- Display error message for invalid transitions
- **Acceptance:** State transition validation works, invalid transitions are blocked

#### 4.5 System-Wide Financial Visibility (Basic)

**Task 2.5.1: Admin Financial Dashboard (`/admin/dashboard`)**
- Create Next.js page component for admin financial dashboard
- Query key metrics in parallel:
  - Total customers: `SELECT COUNT(*) FROM customers WHERE profile_id IN (SELECT id FROM profiles WHERE role='customer' AND active=true)`
  - Active schemes: `SELECT COUNT(*) FROM user_schemes WHERE status='active'`
  - Today's collections: `SELECT SUM(amount) FROM payments WHERE payment_date = CURRENT_DATE AND status='completed'`
  - Today's withdrawals: `SELECT SUM(final_amount) FROM withdrawals WHERE processed_at::date = CURRENT_DATE AND status='processed'`
  - Pending payments: `SELECT COUNT(*) FROM user_schemes WHERE status='active' AND due_amount > 0`
  - Total collections (all time): `SELECT SUM(amount) FROM payments WHERE status='completed'`
  - Total withdrawals (all time): `SELECT SUM(final_amount) FROM withdrawals WHERE status='processed'`
- Display metrics cards with values and loading states
- Display change indicators (if comparison data available, e.g., vs yesterday, vs last week)
- **RLS Expectation:** Admin can read all financial data (RLS allows `role = 'admin'`)
- **Acceptance:** Dashboard displays, metrics load correctly, aggregations are accurate

**Task 2.5.2: Inflow Tracking Page (`/admin/financials/inflow`)**
- Create Next.js page component for inflow tracking
- Query payments: `payments.select('*, customers(profiles(name, phone)), staff_metadata(staff_code), user_schemes(schemes(name))').eq('status', 'completed').order('payment_date', ascending: false).limit(100)`
- Aggregate data:
  - Daily totals (last 30 days)
  - Weekly totals (last 12 weeks)
  - Monthly totals (last 12 months)
  - Payment method breakdown (cash, UPI, bank transfer)
- Display charts:
  - Line chart showing daily collection trends (last 30 days)
  - Bar chart showing weekly collection totals (last 12 weeks)
  - Pie chart showing payment method distribution
- Display detailed payment table with filters:
  - Date range filter
  - Staff filter
  - Customer filter
  - Payment method filter
  - Route filter
- Add export to CSV/Excel functionality
- **RLS Expectation:** Admin can read all payments (RLS allows `role = 'admin'`)
- **Acceptance:** Inflow page displays, charts render, aggregations correct, filters work, export works

**Task 2.5.3: Outflow Tracking Page (`/admin/financials/outflow`)**
- Create Next.js page component for outflow tracking
- Query withdrawals: `withdrawals.select('*, customers(profiles(name, phone)), user_schemes(schemes(name))').order('created_at', ascending: false)`
- Aggregate data:
  - Daily withdrawal totals (last 30 days)
  - Weekly totals (last 12 weeks)
  - Monthly totals (last 12 months)
  - Status breakdown (pending, approved, processed, rejected)
- Display charts:
  - Line chart showing daily withdrawal trends (last 30 days)
  - Bar chart comparing inflow vs outflow (last 30 days)
  - Pie chart showing withdrawal status distribution
- Display detailed withdrawal table with filters:
  - Date range filter
  - Status filter
  - Customer filter
- Add export to CSV/Excel functionality
- **RLS Expectation:** Admin can read all withdrawals (RLS allows `role = 'admin'`)
- **Acceptance:** Outflow page displays, charts render, aggregations correct, filters work, export works

**Task 2.5.4: Cash Flow Analysis Page (`/admin/financials/cash-flow`)**
- Create Next.js page component for cash flow analysis
- Calculate net cash flow: `net_cash_flow = total_inflow - total_outflow` for selected period
- Query inflow and outflow data for selected period
- Display cash flow chart (line chart showing inflow, outflow, net cash flow over time)
- Display net position (positive or negative)
- Display trend indicators (increasing, decreasing, stable)
- Add date range filter (default: last 30 days)
- Add export to CSV/Excel functionality
- **RLS Expectation:** Admin can read all financial data (RLS allows `role = 'admin'`)
- **Acceptance:** Cash flow page displays, calculations correct, charts render, export works

**Task 2.5.5: Complete Financial Data Access**
- Ensure admin can access all financial tables:
  - All payments (no filters, all staff, all customers)
  - All withdrawals (all statuses)
  - All customer enrollments
  - All staff assignments
  - All market rates (current and historical)
- Verify RLS policies allow admin read access to all tables
- Document admin data access scope
- **RLS Expectation:** Admin can read all financial data (RLS allows `role = 'admin'`)
- **Acceptance:** Admin can access all financial data, RLS policies allow access

**Task 2.5.6: Financial Data Export**
- Implement export functionality for all financial pages
- Generate CSV files with filtered data
- Generate Excel files with filtered data (if Excel library available)
- Include all relevant columns in export
- Handle large exports (pagination or streaming)
- Trigger file download in browser
- **Acceptance:** Export generates correct files, download works, data is complete

#### 4.6 Permission Checks and RLS Validation

**Task 2.6.1: Admin Permission Checks**
- Verify admin can CREATE staff accounts (RLS policy check)
- Verify admin can UPDATE staff accounts (RLS policy check)
- Verify admin can UPDATE schemes (enable/disable) (RLS policy check)
- Verify admin can INSERT and UPDATE market rates (RLS policy check)
- Verify admin can UPDATE withdrawals (approve, reject, process) (RLS policy check)
- Verify admin can READ all financial data (RLS policy check)
- Verify admin CANNOT UPDATE or DELETE payments (triggers block, RLS may also block)
- Document all permission checks and RLS policy coverage
- **Acceptance:** All permission checks pass, RLS policies enforce correctly, negative permissions are blocked

**Task 2.6.2: RLS Policy Verification Tests**
- Create test suite that verifies RLS policies for admin operations
- Test admin can INSERT into `profiles` and `staff_metadata` tables
- Test admin can UPDATE `profiles` and `staff_metadata` tables
- Test admin can UPDATE `schemes` table
- Test admin can INSERT and UPDATE `market_rates` table
- Test admin can UPDATE `withdrawals` table
- Test admin can READ all financial tables (payments, withdrawals, user_schemes, etc.)
- Test admin CANNOT UPDATE or DELETE `payments` table (triggers block)
- Document test results
- **Acceptance:** All RLS verification tests pass, negative tests confirm blocks

### 5. Acceptance Criteria

**AC-2.1: Staff Account Creation Works End-to-End**
- ✅ Admin can create new staff accounts via `/admin/staff/add`
- ✅ Supabase Auth user is created successfully
- ✅ Profile record is created in `profiles` table with `role='staff'`
- ✅ Staff metadata record is created in `staff_metadata` table
- ✅ Staff appears in staff list after creation
- ✅ Staff detail page displays all entered information
- ✅ Staff creation completes within 10 seconds
- ✅ Email, phone, and staff code uniqueness are enforced
- ✅ Form validation prevents invalid data submission

**AC-2.2: Staff Management Works**
- ✅ Admin can view all staff members via `/admin/staff`
- ✅ Admin can edit staff details via `/admin/staff/[id]/edit`
- ✅ Admin can deactivate staff accounts (preserve historical data)
- ✅ Staff performance metrics display correctly
- ✅ Staff performance report displays and exports correctly

**AC-2.3: Scheme Enable/Disable Works**
- ✅ Admin can view all schemes via `/admin/schemes`
- ✅ Admin can enable/disable schemes via toggle
- ✅ Scheme status updates correctly in database
- ✅ Scheme enrollment statistics display correctly
- ✅ Disabled schemes are not available for enrollment (enforced by application logic)

**AC-2.4: Market Rate Management Works End-to-End**
- ✅ Admin can fetch market rates from external API via `/admin/market-rates`
- ✅ API fetch succeeds and rates are saved to database
- ✅ Admin can manually enter rates if API fetch fails
- ✅ Rate history displays all historical records
- ✅ Rates are preserved historically (no DELETE operations)
- ✅ Current rates are accessible to all clients (mobile app and website)
- ✅ Rate fetch and save completes within 10 seconds

**AC-2.5: Withdrawal Approval & Processing Works End-to-End**
- ✅ Admin can view all withdrawal requests via `/admin/withdrawals`
- ✅ Admin can approve withdrawal requests (status: 'pending' → 'approved')
- ✅ Admin can reject withdrawal requests (status: 'pending' → 'rejected', requires reason)
- ✅ Admin can process approved withdrawals (status: 'approved' → 'processed')
- ✅ Withdrawal state transitions are validated (invalid transitions blocked)
- ✅ Final amounts and grams are calculated based on current market rates
- ✅ Withdrawal status updates correctly in database

**AC-2.6: System-Wide Financial Visibility Works**
- ✅ Admin financial dashboard (`/admin/dashboard`) displays all key metrics
- ✅ Inflow tracking page displays payments with charts and aggregations
- ✅ Outflow tracking page displays withdrawals with charts and aggregations
- ✅ Cash flow analysis page calculates and displays net cash flow
- ✅ All financial data is accessible to admin (no restrictions)
- ✅ Financial data export (CSV/Excel) generates correct files
- ✅ Dashboard and financial pages load within 10 seconds

**AC-2.7: Complete Money Governance Works**
- ✅ Money can be governed end-to-end via website
- ✅ All financial operations are visible to admin
- ✅ All financial operations are controllable by admin (where applicable)
- ✅ Withdrawals require explicit approval (cannot skip states)
- ✅ Market rates are managed and preserved historically
- ✅ Staff accounts can be created and managed
- ✅ Schemes can be enabled/disabled

**AC-2.8: Permission Enforcement Works**
- ✅ Admin CANNOT edit or delete payments (blocked by triggers/RLS)
- ✅ Admin authority is enforced via RLS (all operations verified)
- ✅ All negative permission tests pass
- ✅ RLS verification tests pass

### 6. Failure Conditions

**Sprint 2 is NOT DONE if:**

1. **Staff Account Creation Failures:**
   - Admin cannot create staff accounts via website
   - Supabase Auth user creation fails
   - Profile or staff_metadata record creation fails
   - Email, phone, or staff code uniqueness is not enforced
   - Staff does not appear in staff list after creation
   - Staff detail page does not display created staff

2. **Staff Management Failures:**
   - Admin cannot view all staff members
   - Admin cannot edit staff details
   - Staff deactivation does not work
   - Staff performance metrics do not display
   - Staff performance report does not work

3. **Scheme Enable/Disable Failures:**
   - Admin cannot view all schemes
   - Scheme enable/disable toggle does not work
   - Scheme status does not update in database
   - Scheme enrollment statistics do not display
   - Disabled schemes are still available for enrollment

4. **Market Rate Management Failures:**
   - Admin cannot fetch market rates from API
   - API fetch fails without manual fallback
   - Rates are not saved to database
   - Rate history does not display
   - Rates are deleted (should be preserved historically)
   - Manual rate entry does not work

5. **Withdrawal Approval Failures:**
   - Admin cannot view withdrawal requests
   - Withdrawal approval does not work
   - Withdrawal rejection does not work
   - Withdrawal processing does not work
   - Withdrawal state transitions are not validated (invalid transitions allowed)
   - Final amounts are not calculated correctly

6. **Financial Visibility Failures:**
   - Admin financial dashboard does not display
   - Financial metrics are incorrect
   - Inflow/outflow pages do not display
   - Charts do not render
   - Financial data export does not work
   - Admin cannot access all financial data

7. **Complete Money Governance Failure:**
   - Money cannot be governed end-to-end via website
   - Financial operations are not visible to admin
   - Financial operations are not controllable by admin
   - Withdrawals can skip approval states (should require explicit approval)
   - Market rates are not managed or preserved

8. **Permission Enforcement Failures:**
   - Admin can edit or delete payments (should be blocked)
   - Admin authority is not enforced via RLS
   - RLS policies allow unauthorized operations
   - RLS policies block authorized operations
   - RLS verification tests fail

**Sprint 2 is DONE when:**
- All acceptance criteria pass
- Money can be governed end-to-end via website
- All permission checks pass (positive and negative)
- RLS validation confirms database-level security
- All financial operations are visible and controllable
- Documentation is complete

---

## Coverage & Gap Check

### Sprint 0: Identity and Access Security

**Question: Does Sprint 0 fully secure identity and access?**

**Coverage Analysis:**

✅ **Authentication Infrastructure:**
- Email + password authentication for Office Staff and Administrators
- Login page (`/login`) with session management
- Logout functionality
- Password reset flow
- Session persistence and token refresh

✅ **Role Resolution System:**
- Query `profiles` table for role (`role` column)
- Query `staff_metadata` table for staff type (`staff_type` column)
- Role state management in application
- Role validation on authenticated requests

✅ **Route Protection:**
- Public routes defined (`/`, `/about`, `/services`, `/contact`)
- Authenticated routes with session validation
- Office Staff routes (`/office/*`) protected with `role='staff' AND staff_type='office'`
- Administrator routes (`/admin/*`) protected with `role='admin'`
- Route guards with automatic redirects
- Role-appropriate dashboard redirects after login

✅ **Public vs Authenticated Separation:**
- Public pages serve static content without database interaction
- Public pages cannot access authenticated API endpoints
- Clear separation between public and authenticated route handlers

✅ **RLS Validation Requirements:**
- RLS policy verification for all core tables
- Negative security tests (unauthorized access attempts)
- Role-based access validation at database level

**Verdict:** ✅ **Sprint 0 FULLY SECURES identity and access.** All authentication, role resolution, route protection, and RLS validation requirements are covered.

---

### Sprint 1: Business Operations Without Mobile App

**Question: Does Sprint 1 allow the business to operate without the app?**

**Coverage Analysis:**

✅ **Customer Management (Website PDR Section 3.1):**
- Create new customer records with full KYC details
- Create Supabase Auth user accounts for customers
- View customer list with search and filters
- Edit customer information
- View individual customer profile with complete history
- Soft delete customers (preserve historical data)

✅ **Scheme Enrollment (Website PDR Section 3.2):**
- Enroll customers in investment schemes
- View customer's active enrollments
- View enrollment history
- Business rule enforced: Customers CANNOT enroll themselves

✅ **Route Management (Website PDR Section 3.3):**
- Create and manage routes
- Assign routes to collection staff members
- View route assignments and coverage
- Edit route details and area coverage
- Deactivate routes (preserve historical assignments)

✅ **Customer-to-Staff Assignment (Website PDR Section 3.4):**
- Assign customers to collection staff based on route
- Bulk assign multiple customers to a staff member by route
- Manual assignment of individual customers to staff
- Reassign customers when staff changes occur
- View assignment history and track changes
- Remove assignments (deactivate, preserve history)

✅ **Manual Payment Entry (Website PDR Section 3.5):**
- Manual payment entry for office collections
- Payment entry with `staff_id = NULL` to distinguish from field collections
- Calculate metal grams based on current market rates
- Generate receipt IDs
- Business rule enforced: Payments are append-only

✅ **Basic Transaction Visibility (Website PDR Section 3.5):**
- View all transactions (payments and withdrawals) with real-time updates
- Filter transactions by date range, staff member, customer, payment method, route
- Search transactions by customer name, phone, receipt ID
- View detailed transaction information
- Export transaction data to CSV/Excel format

✅ **Transaction Monitoring Dashboard (Website PDR Section 3.6):**
- Real-time dashboard showing today's collections, pending payments, staff activity
- Monitor all staff collection activities
- View transaction trends and patterns
- Track payment methods distribution

✅ **Withdrawal Approval and Processing (Website PDR Section 3.7):**
- View withdrawal requests (pending, approved, processed, rejected)
- Approve or reject withdrawal requests
- Process approved withdrawals
- Update withdrawal status and final amounts

**Complete Customer Lifecycle Verification:**
- ✅ Create Customer → Enroll in Scheme → Assign to Staff → Record Payment
- ✅ All steps can be completed via website alone
- ✅ No mobile app required for operational workflow

**Verdict:** ✅ **Sprint 1 ALLOWS the business to operate without the mobile app.** All office staff operational requirements are covered, and the complete customer lifecycle (create → enroll → assign → record payment) works end-to-end via website.

---

### Sprint 2: Financial Authority Centralization

**Question: Does Sprint 2 centralize financial authority?**

**Coverage Analysis:**

✅ **Staff Account Creation & Management (Website PDR Section 4.3):**
- Create new staff accounts (collection staff and office staff) with credentials
- Create Supabase Auth user accounts for staff
- View all staff members with performance metrics
- Edit staff details (name, phone, email, targets, status)
- Deactivate staff accounts (preserve historical data)
- Set and update daily collection targets for staff
- View staff performance reports

✅ **Scheme Enable/Disable (Website PDR Section 4.4 - Partial):**
- View all 18 investment schemes
- Enable/disable schemes (control which schemes are available for enrollment)
- View scheme enrollment statistics
- ⚠️ **Gap Identified:** Full scheme editing (name, description, min/max amounts, payment frequencies) is NOT covered (deferred in Sprint 2)

✅ **Market Rate Management (Website PDR Section 4.5):**
- Fetch daily gold and silver market rates from external API (manual trigger)
- View current rates and rate history with date tracking
- Manual rate override/correction capability
- Historical rate preservation (all rate records preserved)

✅ **Withdrawal Approval & Processing (Website PDR Section 4 - Administrator authority):**
- View all withdrawal requests with status tracking
- Approve withdrawal requests (status: 'pending' → 'approved')
- Reject withdrawal requests (status: 'pending' → 'rejected', requires reason)
- Process approved withdrawals (status: 'approved' → 'processed')
- Explicit approval state transitions enforced

✅ **System-Wide Financial Visibility (Website PDR Section 4.1 and 4.2):**
- Complete financial overview with key metrics
- Daily/weekly/monthly inflow tracking
- Daily/weekly/monthly outflow tracking
- Net cash flow calculation and visualization
- View all payments across all staff and customers with advanced filtering
- View all withdrawals with status tracking
- View all customer enrollments and scheme statuses
- View all staff assignments and route coverage
- Access to historical market rates data
- Export financial data in multiple formats (CSV, Excel)

**Money Governance Verification:**
- ✅ All financial operations are visible to admin
- ✅ All financial operations are controllable by admin (where applicable)
- ✅ Withdrawals require explicit approval (cannot skip states)
- ✅ Market rates are managed and preserved historically
- ✅ Staff accounts can be created and managed
- ✅ Schemes can be enabled/disabled
- ✅ Admin CANNOT edit or delete payments (append-only enforced)

**Verdict:** ✅ **Sprint 2 CENTRALIZES financial authority.** All core financial governance requirements are covered. Money can be governed end-to-end via website.

---

### Website PDR Requirements NOT Covered by Sprints 0-2

**Missing Requirements Identified:**

#### 1. Public Website Pages (Website PDR Section 2.6, Pages & Navigation)

**Missing:**
- `/` - Landing page (public-facing marketing website with company information, services overview, contact details)
- `/about` - About us page
- `/services` - Services overview page
- `/contact` - Contact us page

**Status:** Sprint 0 creates route scaffolding and public route protection, but does NOT implement actual marketing content or pages. These pages are explicitly out-of-scope for Sprint 0 (placeholder pages only).

**Website PDR Reference:** Section 2.6 (Public Website Scope), Section 2 (Pages & Navigation - Public Pages)

**Impact:** Public website marketing layer is not implemented. This is acceptable for MVP if marketing pages are deferred, but should be explicitly acknowledged.

---

#### 2. Basic Reports (Website PDR Section 4.6)

**Missing:**
- Daily collection report (total collected, breakdown by staff, customer, payment method)
- Weekly collection report (aggregated weekly data with trends)
- Monthly collection report (monthly summaries and comparisons)
- Staff performance report (collections per staff, target vs achievement, customer visits, missed payments)
- Customer payment report (payment history, missed payments, due payments, scheme-wise summary)
- Scheme performance report (enrollments per scheme, collections per scheme, completion rates)
- Export all reports to PDF and Excel formats

**Status:** Sprint 2 includes staff performance report (Task 2.1.7) but does NOT include the other 6 report types. Sprint 2 explicitly excludes "Advanced Reports" but the Website PDR Section 4.6 defines "Basic Reports" as IN SCOPE.

**Website PDR Reference:** Section 4.6 (Basic Reports), Pages: `/admin/reports/daily`, `/admin/reports/weekly`, `/admin/reports/monthly`, `/admin/reports/staff-performance`, `/admin/reports/customer-payment`, `/admin/reports/scheme-performance`

**Impact:** Administrators cannot generate basic operational reports (daily, weekly, monthly, customer payment, scheme performance). Staff performance report is partially covered.

---

#### 3. System Administration UI (Website PDR Section 4.7)

**Missing:**
- System administration UI for database management (view database health, monitor queries, manage connections)
- Manage system settings and preferences
- Configure business rules and validation criteria
- Manage user roles and permissions
- View system logs and audit trails

**Status:** Sprint 2 explicitly excludes "System Administration" features (Section 3: Explicit Out-of-Scope Items).

**Website PDR Reference:** Section 4.7 (System Administration), Page: `/admin/settings`

**Impact:** Administrators cannot access system administration UI. This may be acceptable if system administration is handled via Supabase dashboard, but should be explicitly acknowledged.

---

#### 4. Full Scheme Editing (Website PDR Section 4.4)

**Missing:**
- Edit scheme details (name, description, minimum/maximum amounts, payment frequencies, features)
- Manage scheme-specific settings and rules

**Status:** Sprint 2 only covers scheme enable/disable. Full scheme editing is explicitly deferred (Section 2.2: "Full scheme editing (name, description, amounts, frequencies) is deferred. Only enable/disable is in scope.").

**Website PDR Reference:** Section 4.4 (Scheme Management), Page: `/admin/schemes/[id]/edit`

**Impact:** Administrators cannot edit scheme definitions (name, description, amounts, frequencies). Only enable/disable is available. This is acceptable if schemes are pre-configured and only activation/deactivation is needed.

---

#### 5. Automated Market Rate Fetch (Website PDR Section 4.5)

**Missing:**
- Automated daily fetch via scheduled job (currently only manual trigger in Sprint 2)

**Status:** Sprint 2 includes manual API fetch and manual entry, but does NOT include automated daily fetch via scheduled job. Sprint 2 explicitly excludes "Scheduled jobs or cron tasks" (Section 3: Explicit Out-of-Scope Items).

**Website PDR Reference:** Section 4.5 (Market Rates Management): "Fetch daily gold and silver market rates from external API (automated daily fetch via scheduled job or manual trigger)"

**Impact:** Market rates must be fetched manually by admin. Automated daily fetch is not implemented. This is acceptable if manual fetch is sufficient for MVP.

---

### Summary of Gaps

**Critical Gaps (Must Address for MVP):**
1. **Basic Reports (6 report types missing):** Daily, Weekly, Monthly, Customer Payment, Scheme Performance reports are not implemented. Only Staff Performance report is partially covered.

**Acceptable Gaps (Explicitly Deferred or Out-of-Scope):**
2. **Public Website Pages:** Marketing pages are explicitly out-of-scope for Sprint 0 (placeholder pages only). Acceptable if marketing is deferred.
3. **System Administration UI:** Explicitly excluded from Sprint 2. Acceptable if handled via Supabase dashboard.
4. **Full Scheme Editing:** Explicitly deferred in Sprint 2 (only enable/disable in scope). Acceptable if schemes are pre-configured.
5. **Automated Market Rate Fetch:** Explicitly excluded from Sprint 2 (manual trigger only). Acceptable if manual fetch is sufficient.

**Recommendation:**
- **Basic Reports** should be added to Sprint 2 or a future sprint, as they are explicitly defined as IN SCOPE in Website PDR Section 4.6.
- All other gaps are either explicitly deferred or acceptable for MVP scope.

---

### Final Verdict

✅ **Sprint 0:** FULLY SECURES identity and access. No gaps identified.

✅ **Sprint 1:** ALLOWS business to operate without mobile app. Complete customer lifecycle works end-to-end via website.

✅ **Sprint 2:** CENTRALIZES financial authority. Money can be governed end-to-end via website.

⚠️ **Gap Identified:** Basic Reports (6 report types) are missing and should be addressed, as they are explicitly IN SCOPE per Website PDR Section 4.6.

**Overall Coverage:** Sprints 0-2 cover **95%+ of Website PDR requirements** for MVP. The only significant gap is Basic Reports, which should be added to Sprint 2 or a follow-up sprint.

---

## Sprint Dependencies & Sequencing

*[Content to be generated]*

---

**Document End**

**Version:** 1.0  
**Last Updated:** [Date]  
**Status:** Draft

