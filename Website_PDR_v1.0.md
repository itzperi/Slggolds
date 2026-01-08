# Website PDR – v1.0 (Derived from Master PDR)

**Version:** 1.0  
**Date:** [Date]  
**Status:** Draft  
**Source:** Derived from Master PDR v1.1 (`PROJECT_DEFINITION_REPORT.md`)  
**Owner:** [Name/Role]

---

## Document Control

- **Version:** 1.0
- **Last Updated:** [Date]
- **Owner:** [Name/Role]
- **Approval Status:** [Draft / Approved / In Review]
- **Source Document:** `PROJECT_DEFINITION_REPORT.md` (Master PDR v1.1)
- **Stakeholder Sign-off:** [List approvers and dates]

---

## Purpose & Authority Statement

### Document Purpose

This Website PDR is a domain-specific Project Definition Report focused exclusively on the **website component** of the SLG Thangangal investment scheme management system. It extracts and formalizes website-related responsibilities, features, and boundaries from the Master PDR.

### Authority and Source of Truth

**The Master PDR is the authoritative system-level specification.**

- **Source Document:** `PROJECT_DEFINITION_REPORT.md` (Master PDR v1.1)
- **This Website PDR:** Derived document focused on website domain only
- **In Case of Conflict:** The Master PDR always prevails
- **Scope:** This document does NOT redefine or contradict the Master PDR
- **Reference:** All system-level requirements, data models, technical architecture, and non-functional requirements are defined in the Master PDR

### Website Domain Scope

This document defines:
- Website responsibility boundaries (what the website is authorized to do)
- Public website scope (marketing and trust layer)
- Office Staff web application scope (operational interface)
- Administrator web application scope (governance and financial oversight)

This document does NOT define:
- Mobile application features or flows
- Backend/database architecture (defined in Master PDR)
- System-wide data models (defined in Master PDR)
- Cross-platform integrations (defined in Master PDR)

---

## 1. Website Responsibility Boundary

### Purpose

This section establishes clear boundaries between the **Website**, **Mobile App**, and **Backend/Database** layers, defining the website as the authoritative control plane for operations and governance. These boundaries ensure that decision-making authority, data creation, and operational control remain centralized in the website interface, while the mobile app serves as a consumption and execution layer.

**Source:** Master PDR Section 2.5

### Core Principle: Website as Control Plane

The website is the **ONLY interface** authorized to perform the following operations:

1. **Customer Creation**
   - Create new customer records with full KYC details
   - Create Supabase Auth user accounts for customers
   - Link customer profiles to authentication accounts
   - **Mobile App:** Cannot create customers (read-only access to own profile)

2. **Scheme Enrollment**
   - Enroll customers into investment schemes
   - Set payment frequency, amount ranges, and enrollment dates
   - Create `user_schemes` records linking customers to schemes
   - **Mobile App:** Cannot enroll customers (customers cannot self-enroll)

3. **Route Management**
   - Create, update, and manage routes (geographic territories)
   - Define route coverage areas and descriptions
   - Activate/deactivate routes
   - **Mobile App:** Cannot manage routes (not accessible on mobile)

4. **Staff Assignment**
   - Assign customers to collection staff members
   - Assign customers to routes
   - Create and manage `staff_assignments` records
   - Bulk assignment operations
   - **Mobile App:** Cannot assign customers (collection staff can only view assigned customers)

5. **Market Rates Management**
   - Fetch daily market rates from external API
   - Manual rate override/correction
   - View rate history and trends
   - **Mobile App:** Cannot update rates (read-only access to current rates)

6. **Withdrawal Approval and Processing**
   - Approve or reject withdrawal requests
   - Process approved withdrawals
   - Update withdrawal status and final amounts
   - **Mobile App:** Cannot approve/process withdrawals (customers can only request, staff can view assigned customers' requests)

7. **Staff Account Management**
   - Create new staff accounts (collection and office staff)
   - Set staff credentials and permissions
   - Manage staff metadata (targets, assignments, status)
   - **Mobile App:** Cannot create or manage staff accounts

8. **Scheme Management**
   - Edit scheme details (amounts, frequencies, features)
   - Enable/disable schemes
   - **Mobile App:** Cannot modify schemes (read-only access to active schemes)

### Mobile App: Consumption and Execution Layer

The mobile app is designed as a **consumption and execution layer**, not a decision-making layer:

**What Mobile App CAN Do:**
- **Customers:** View own data (portfolio, payments, schemes), request withdrawals, update own profile
- **Collection Staff:** View assigned customers, record payment collections, view own performance metrics
- Execute operations that have been **pre-authorized** by website (e.g., record payments for customers already assigned via website)

**What Mobile App CANNOT Do:**
- Create customers
- Enroll customers in schemes
- Manage routes
- Assign customers to staff
- Update market rates
- Approve/process withdrawals
- Create or manage staff accounts
- Modify schemes
- Access website-only features

### Backend: Ultimate Source of Truth

The backend (Supabase + PostgreSQL) is the **ultimate source of truth** and enforces all rules:

**Database Responsibilities:**
- Enforce Row Level Security (RLS) policies that prevent unauthorized access
- Enforce business rules via database triggers (e.g., payment immutability, scheme total updates)
- Validate data integrity via constraints and foreign keys
- Provide RPC functions for complex operations (e.g., staff code resolution)
- Store all historical data immutably (append-only payment records)

**Backend Enforcement:**
- RLS policies prevent mobile app from creating customers, enrollments, or assignments (even if application code attempts it)
- Database triggers prevent payment modifications (UPDATE/DELETE blocked)
- Foreign key constraints ensure referential integrity
- Application code cannot bypass database-level security

### Responsibility Matrix

| Operation | Website | Mobile App | Backend/Database |
|-----------|---------|------------|-----------------|
| **Create Customer** | ✅ Authorized | ❌ Blocked by RLS | ✅ Enforces RLS |
| **Enroll Customer in Scheme** | ✅ Authorized | ❌ Blocked by RLS | ✅ Enforces RLS |
| **Create Route** | ✅ Authorized | ❌ Not Available | ✅ Stores Data |
| **Assign Customer to Staff** | ✅ Authorized | ❌ Blocked by RLS | ✅ Enforces RLS |
| **Update Market Rates** | ✅ Authorized | ❌ Not Available | ✅ Enforces RLS |
| **Approve Withdrawal** | ✅ Authorized | ❌ Blocked by RLS | ✅ Enforces RLS |
| **Create Staff Account** | ✅ Authorized | ❌ Not Available | ✅ Enforces RLS |
| **Modify Scheme** | ✅ Authorized | ❌ Not Available | ✅ Stores Data |
| **Record Payment** | ✅ (Office Collections) | ✅ (Field Collections) | ✅ Enforces RLS |
| **View Own Data** | ✅ (If logged in) | ✅ | ✅ Enforces RLS |
| **Request Withdrawal** | ✅ (If logged in) | ✅ | ✅ Stores Data |

### In Scope / Out of Scope for Website

**IN SCOPE for Website:**
- Customer creation and management (Office Staff)
- Scheme enrollment for customers (Office Staff)
- Route management (Office Staff)
- Customer-to-staff assignment (Office Staff)
- Manual payment entry for office collections (Office Staff)
- Transaction monitoring and reporting (Office Staff)
- Financial dashboard and analytics (Admin)
- Staff account management (Admin)
- Scheme management (Admin)
- Market rates management (Admin)
- Withdrawal approval and processing (Admin/Office Staff)
- System administration UI (Admin)
- Public-facing landing pages (marketing website)
- Mobile-responsive design (website accessible on mobile browsers)

**OUT OF SCOPE for Website:**
- Customer self-service enrollment (customers use mobile app for viewing, office staff use website for enrollment)
- Payment collection in the field (collection staff use mobile app)
- Mobile app functionality (separate mobile application)
- Advanced analytics, machine learning, predictive modeling (deferred to later phase)
- Customer-to-customer interactions or community features
- Push notifications (handled by mobile app infrastructure)
- Location tracking or GPS features (mobile app only)
- Biometric authentication (mobile app only)

### Architectural Intent

This boundary definition ensures:

1. **Single Source of Authority:** Website is the only interface that can create, modify, or authorize operational data (customers, enrollments, assignments, rates)

2. **Separation of Concerns:** Mobile app focuses on execution (payment collection, data viewing) while website focuses on governance (customer management, staff assignment, rate management)

3. **Database-First Security:** All operations are ultimately enforced by database RLS policies, regardless of which interface attempts them

4. **Audit Trail Integrity:** All data creation and modification operations flow through the website, ensuring consistent audit trails and governance

5. **Scalability:** Centralized control plane (website) enables easier management of business rules, permissions, and operational workflows

---

## 2. Public Website Scope (Marketing & Trust Layer)

### Purpose

This section clarifies that the public-facing website (marketing pages) is part of the same system but is logically isolated from core operational functionality. The public website serves as a marketing and trust-building layer, not an operational interface.

**Source:** Master PDR Section 2.6

### What the Public Website IS

The public-facing website serves the following purposes:

1. **Marketing**
   - Company information and brand presentation
   - Services overview and value proposition
   - Investment scheme descriptions and benefits
   - Testimonials and success stories (if applicable)
   - Call-to-action elements directing visitors to contact or learn more

2. **Education**
   - Educational content about gold/silver investment schemes
   - How the investment process works
   - Scheme features and benefits explained
   - Frequently asked questions (FAQ)
   - Investment guides and resources

3. **Trust-Building**
   - Company credentials and certifications
   - Security and compliance information
   - Transparency about processes and policies
   - Contact information and office locations
   - About us and company history

4. **Lead Capture**
   - Contact forms for inquiries
   - Interest forms for potential customers
   - Newsletter signup (if applicable)
   - Request callback or consultation forms

### What the Public Website is NOT

The public-facing website is explicitly prohibited from:

1. **No Authentication into Core System**
   - Public pages do not provide login functionality for customers, staff, or administrators
   - Authentication is only available on authenticated routes (separate from public pages)
   - Public website visitors cannot access any authenticated features

2. **No Direct Writes to Business-Critical Tables**
   - Public website cannot INSERT, UPDATE, or DELETE records in:
     - `profiles` table
     - `customers` table
     - `user_schemes` table
     - `payments` table
     - `withdrawals` table
     - `staff_metadata` table
     - `staff_assignments` table
     - `schemes` table (scheme definitions)
     - `market_rates` table
     - `routes` table
   - Public website has read-only access (if any) to display-only data (e.g., active scheme names and descriptions for marketing)

3. **No Customer Self-Service**
   - Public website cannot create customer accounts
   - Public website cannot enroll customers in schemes
   - Public website cannot process payments or withdrawals
   - Public website cannot access customer data or transaction history

4. **No Financial Operations**
   - Public website cannot record payments
   - Public website cannot process withdrawals
   - Public website cannot view financial data
   - Public website cannot access financial dashboards or reports

### Allowed Data Flows

The public website may interact with the system in the following limited ways:

1. **Contact/Interest Forms**
   - **Allowed:** Submit form data to a separate `leads` or `inquiries` table (not part of core business tables)
   - **Alternative:** Submit form data to external service (email, CRM, third-party form handler)
   - **Data Flow:** `Public Form → Leads Table (or External Service) → Office Staff Review → Manual Customer Creation via Authenticated Website`
   - **RLS Policy:** `leads` table (if created) must have RLS policy allowing unauthenticated INSERT for form submissions, but no other operations

2. **Read-Only Display Data**
   - **Allowed:** Query `schemes` table with `active = true` to display scheme names and descriptions on marketing pages
   - **RLS Policy:** Public read-only policy for active schemes only (no customer-specific data)
   - **Purpose:** Display available schemes for marketing purposes only

3. **Static Content**
   - **Allowed:** Serve static content (HTML, CSS, images) without database interaction
   - **Allowed:** Display hardcoded or CMS-managed content (company info, blog posts, etc.)

### Prohibited Interactions with Core Tables

The public website is explicitly prohibited from any interaction with the following core business tables:

| Table | Prohibited Operations | Reason |
|-------|----------------------|--------|
| `profiles` | All operations (SELECT, INSERT, UPDATE, DELETE) | Contains user authentication and role data |
| `customers` | All operations | Contains customer KYC and personal data |
| `user_schemes` | All operations | Contains customer enrollment data |
| `payments` | All operations | Contains financial transaction data (immutable) |
| `withdrawals` | All operations | Contains withdrawal request data |
| `staff_metadata` | All operations | Contains staff account and performance data |
| `staff_assignments` | All operations | Contains customer-to-staff assignment data |
| `schemes` | INSERT, UPDATE, DELETE (SELECT of active schemes only, if needed for marketing) | Scheme definitions are managed by admin only |
| `market_rates` | All operations | Contains financial rate data |
| `routes` | All operations | Contains operational routing data |

**Enforcement:** These prohibitions are enforced by:
- RLS policies that prevent unauthenticated access to core tables
- Application code that does not attempt to query core tables from public pages
- Separate database schema or table for public website data (e.g., `leads`, `inquiries`)

### Public Website Architecture

**Logical Isolation:**
- Public pages are served from the same Next.js application but use separate routes (e.g., `/`, `/about`, `/services`, `/contact`)
- Public routes do not require authentication
- Public routes do not access authenticated API endpoints

**Data Separation:**
- Public website data (leads, inquiries) stored in separate tables with separate RLS policies
- No foreign key relationships between public website tables and core business tables
- Public website cannot join or query across core business tables

**Security Boundary:**
- Public website operates with minimal database permissions (unauthenticated or read-only for display data)
- RLS policies enforce that public website cannot access authenticated user data
- No session or authentication tokens available on public pages

### Public Website Pages

**Public Pages (No Authentication Required):**
- `/` - Landing page (public-facing marketing website with company information, services overview, contact details)
- `/about` - About us page
- `/services` - Services overview page
- `/contact` - Contact us page

**Authentication Page:**
- `/login` - Authentication page for office staff and administrators (transition from public to authenticated)

**Source:** Master PDR Section 2, Pages & Navigation

---

## 3. Office Staff Web Application Scope

### Purpose

This section defines the operational interface for Office Staff users. Office Staff use the website to manage customers, enrollments, routes, assignments, and monitor transactions. This is the primary operational control plane for day-to-day business operations.

**Source:** Master PDR Section 2 (Website Scope, Office Staff Features) and Section 4 (Office Staff Flows)

### Office Staff Role Definition

**Access Level:** Limited to customer management, route management, assignment management, scheme enrollment, and transaction monitoring

**Authentication:** Email address + password via Supabase Auth (standard email/password authentication)

**Staff Type Requirement:** Must have `staff_type='office'` in `staff_metadata` table and `role='staff'` in `profiles` table

**Source:** Master PDR Section 3 (User Roles & Permissions)

### Office Staff Features

#### 1. Customer Management

**Capabilities:**
- Create new customer records with full KYC details (name, phone, address, nominee information, identity documents)
- View customer list with search and filter capabilities (by name, phone, route, assigned staff, scheme status)
- Edit customer information (profile details, address, nominee information)
- View individual customer profile with complete history (schemes, payments, withdrawals)
- Soft delete customers (mark as inactive, preserve historical data)

**Pages:**
- `/office/customers` - Customer list with search and filters
- `/office/customers/add` - New customer registration form
- `/office/customers/[id]` - Individual customer profile view
- `/office/customers/[id]/edit` - Edit customer information

**Data Operations:**
- INSERT into `profiles` table (create Supabase Auth user account)
- INSERT into `customers` table (create customer record with KYC details)
- SELECT from `customers` table (view all customers, filtered by search/filters)
- UPDATE `customers` table (edit customer information)
- UPDATE `profiles` table (edit customer profile details)

**Source:** Master PDR Section 2 (Website Scope, Office Staff Features, Customer Management)

#### 2. Scheme Enrollment

**Capabilities:**
- **Enroll customers in investment schemes** (select scheme, set payment frequency, amount range, start date)
- View customer's active enrollments
- View enrollment history

**Pages:**
- `/office/customers/[id]/enroll` - Enroll customer in scheme (new scheme enrollment form)

**Data Operations:**
- SELECT from `schemes` table (view active schemes for enrollment)
- INSERT into `user_schemes` table (create enrollment record)
- SELECT from `user_schemes` table (view customer enrollments)

**Business Rules:**
- Customers CANNOT enroll themselves (enrollment performed only by office staff)
- Office staff can create enrollments for any customer
- Enrollment requires: customer selection, scheme selection, payment frequency, amount range (min/max), start date

**Source:** Master PDR Section 2 (Website Scope, Office Staff Features) and Section 4 (Office Staff Flow 4: Enroll Customer in Scheme)

#### 3. Route Management

**Capabilities:**
- Create and manage routes (geographic territories with name, description, area coverage)
- Assign routes to collection staff members
- View route assignments and coverage
- Edit route details and area coverage
- Deactivate routes (preserve historical assignments)

**Pages:**
- `/office/routes` - Route list and management
- `/office/routes/add` - Create new route
- `/office/routes/[id]` - Route details with assigned staff
- `/office/routes/[id]/assign-staff` - Assign staff to route

**Data Operations:**
- INSERT into `routes` table (create new route)
- SELECT from `routes` table (view all routes)
- UPDATE `routes` table (edit route details, activate/deactivate)
- SELECT from `staff_metadata` table (view collection staff for route assignment)

**Source:** Master PDR Section 2 (Website Scope, Office Staff Features, Route Management)

#### 4. Customer-to-Staff Assignment

**Capabilities:**
- Assign customers to collection staff based on route
- Bulk assign multiple customers to a staff member by route
- Manual assignment of individual customers to staff
- Reassign customers when staff changes occur
- View assignment history and track changes
- Remove assignments (deactivate, preserve history)

**Pages:**
- `/office/assignments` - Customer-to-staff assignment interface
- `/office/assignments/by-route` - Bulk assign customers by route
- `/office/assignments/manual` - Manual individual assignment

**Data Operations:**
- SELECT from `routes` table (select route for bulk assignment)
- SELECT from `customers` table (filter customers by route)
- SELECT from `staff_metadata` table (view collection staff members)
- INSERT into `staff_assignments` table (create assignment record)
- UPDATE `staff_assignments` table (reassign or deactivate assignments)
- SELECT from `staff_assignments` table (view assignment history)

**Business Rules:**
- Office staff can assign customers to collection staff
- Assignments can be route-based (bulk) or manual (individual)
- Assignments link customers to collection staff for payment collection

**Source:** Master PDR Section 2 (Website Scope, Office Staff Features, Customer-to-Staff Assignment) and Section 4 (Office Staff Flow 2: Assign Customer to Collection Staff by Route)

#### 5. Transaction Management

**Capabilities:**
- View all transactions (payments and withdrawals) with real-time updates
- Filter transactions by date range, staff member, customer, payment method, route
- Search transactions by customer name, phone, receipt ID
- View detailed transaction information (amount, date, time, method, staff, customer)
- Manual payment entry for office collections (record payments received at office)
- Export transaction data to CSV/Excel format

**Pages:**
- `/office/transactions` - Transaction list with filters
- `/office/transactions/add` - Manual payment entry form
- `/office/transactions/[id]` - Transaction detail view

**Data Operations:**
- SELECT from `payments` table (view all payments with filters)
- SELECT from `withdrawals` table (view all withdrawals)
- INSERT into `payments` table (manual payment entry with `staff_id = NULL` for office collections)
- SELECT from `market_rates` table (get current rates for payment calculation)

**Business Rules:**
- Office staff can enter manual payments for office collections (payments received at office location)
- Manual payments have `staff_id = NULL` to distinguish from field collections
- Payments are append-only (cannot be modified or deleted after creation)

**Source:** Master PDR Section 2 (Website Scope, Office Staff Features, Transaction Management) and Section 4 (Office Staff Flow 3: Manual Payment Entry)

#### 6. Transaction Monitoring

**Capabilities:**
- Real-time dashboard showing today's collections, pending payments, staff activity
- Monitor all staff collection activities
- View transaction trends and patterns
- Track payment methods distribution (cash, UPI, bank transfer)

**Pages:**
- `/office/dashboard` - Office staff dashboard with today's overview

**Data Operations:**
- SELECT from `payments` table (aggregate today's collections)
- SELECT from `user_schemes` table (view pending payments)
- SELECT from `staff_metadata` table (view staff activity)

**Source:** Master PDR Section 2 (Website Scope, Office Staff Features, Transaction Monitoring)

#### 7. Withdrawal Approval and Processing

**Capabilities:**
- View withdrawal requests (pending, approved, processed, rejected)
- Approve or reject withdrawal requests
- Process approved withdrawals
- Update withdrawal status and final amounts

**Data Operations:**
- SELECT from `withdrawals` table (view withdrawal requests)
- UPDATE `withdrawals` table (approve, reject, or process withdrawals)
- SELECT from `market_rates` table (get current rates for withdrawal processing)

**Business Rules:**
- Office staff can update withdrawal status for any customer (if business rule allows)
- Withdrawal approval requires verification of accumulated grams and current rates
- Withdrawal processing updates final amounts and grams based on current rates

**Source:** Master PDR Section 2 (Website Responsibility Boundary) and Section 3 (User Roles & Permissions)

### Office Staff Restrictions

Office Staff CANNOT:
- Access financial dashboards or comprehensive reports (basic reports only)
- Manage staff accounts (admin-only)
- Modify schemes (scheme management is admin-only)
- Update market rates (rates fetched from external API, admin can override)
- View system-wide financial analytics (admin-only)
- Access admin-only reports or advanced analytics
- Modify payment records after creation (payments are append-only)
- Access mobile app (office staff use website only)

**Source:** Master PDR Section 2 (Website Scope, Office Staff Role Restrictions)

### Office Staff User Flows

**Note:** Detailed step-by-step user flows are defined in Master PDR Section 4 (Functional Requirements, Admin / Staff Flows). This section references those flows:

- **Office Staff Flow 1:** Create New Customer (Master PDR Section 4)
- **Office Staff Flow 2:** Assign Customer to Collection Staff by Route (Master PDR Section 4)
- **Office Staff Flow 3:** Manual Payment Entry (Office Collections) (Master PDR Section 4)
- **Office Staff Flow 4:** Enroll Customer in Scheme (Master PDR Section 4)

**Reference:** See Master PDR Section 4 for complete flow definitions with step-by-step instructions, success criteria, and error states.

---

## 4. Administrator Web Application Scope

### Purpose

This section defines the governance and financial oversight interface for Administrator users. Administrators have full system access with complete financial visibility, staff management, scheme management, and system configuration capabilities.

**Source:** Master PDR Section 2 (Website Scope, Administrator Features) and Section 3 (User Roles & Permissions)

### Administrator Role Definition

**Access Level:** Full system access with complete financial visibility

**Authentication:** Email address + password via Supabase Auth (standard email/password authentication)

**Role Requirement:** Must have `role='admin'` in `profiles` table

**Source:** Master PDR Section 3 (User Roles & Permissions)

### Administrator Features

#### 1. Financial Dashboard

**Capabilities:**
- Complete financial overview with key metrics (total customers, active schemes, total collections, withdrawals)
- Daily/weekly/monthly inflow tracking (all payment collections)
- Daily/weekly/monthly outflow tracking (all withdrawals, expenses)
- Net cash flow calculation and visualization
- Real-time financial data updates
- Interactive charts and graphs (line charts, bar charts, pie charts)
- Financial trend analysis (growth rates, comparisons)

**Pages:**
- `/admin/dashboard` - Financial dashboard with complete overview
- `/admin/financials/inflow` - Collections and inflow tracking
- `/admin/financials/outflow` - Withdrawals and outflow tracking
- `/admin/financials/cash-flow` - Net cash flow analysis

**Data Operations:**
- SELECT from `payments` table (aggregate all payments for inflow analysis)
- SELECT from `withdrawals` table (aggregate all withdrawals for outflow analysis)
- SELECT from `customers` table (count total customers)
- SELECT from `user_schemes` table (count active schemes)
- Aggregate calculations for cash flow analysis

**Source:** Master PDR Section 2 (Website Scope, Administrator Features, Financial Dashboard) and Section 4 (Administrator Flow 1: View Financial Dashboard)

#### 2. Complete Financial Data Access

**Capabilities:**
- View all payments across all staff and customers with advanced filtering
- View all withdrawals with status tracking (pending, approved, processed, rejected)
- View all customer enrollments and scheme statuses
- View all staff assignments and route coverage
- Access to historical market rates data
- Export financial data in multiple formats (CSV, Excel, PDF)

**Data Operations:**
- SELECT from all financial tables (payments, withdrawals, user_schemes, staff_assignments, market_rates)
- Export queries for CSV/Excel/PDF generation

**Source:** Master PDR Section 2 (Website Scope, Administrator Features, Complete Financial Data Access)

#### 3. Staff Management

**Capabilities:**
- Create new staff accounts (collection staff and office staff) with credentials
- View all staff members with performance metrics
- Edit staff details (name, phone, email, targets, status)
- Deactivate staff accounts (preserve historical data)
- Set and update daily collection targets for staff
- View staff performance reports (collections, targets, customer visits)

**Pages:**
- `/admin/staff` - Staff list
- `/admin/staff/add` - Create new staff
- `/admin/staff/[id]` - Staff profile and performance
- `/admin/staff/[id]/edit` - Edit staff details

**Data Operations:**
- INSERT into `profiles` table (create Supabase Auth user account for staff)
- INSERT into `staff_metadata` table (create staff metadata record)
- SELECT from `staff_metadata` table (view all staff with performance metrics)
- UPDATE `staff_metadata` table (edit staff details, set targets)
- UPDATE `profiles` table (edit staff profile)

**Source:** Master PDR Section 2 (Website Scope, Administrator Features, Staff Management)

#### 4. Scheme Management

**Capabilities:**
- View all 18 investment schemes (9 Gold schemes, 9 Silver schemes)
- Edit scheme details (name, description, minimum/maximum amounts, payment frequencies, features)
- Enable/disable schemes (control which schemes are available for enrollment)
- View scheme enrollment statistics
- Manage scheme-specific settings and rules

**Pages:**
- `/admin/schemes` - Scheme list
- `/admin/schemes/[id]/edit` - Edit scheme details

**Data Operations:**
- SELECT from `schemes` table (view all schemes)
- UPDATE `schemes` table (edit scheme details, enable/disable)
- SELECT from `user_schemes` table (aggregate enrollment statistics)

**Source:** Master PDR Section 2 (Website Scope, Administrator Features, Scheme Management)

#### 5. Market Rates Management

**Capabilities:**
- **Fetch daily gold and silver market rates from external API** (automated daily fetch via scheduled job or manual trigger)
- View current rates and rate history with date tracking
- Set rate change notifications (optional feature for rate alerts)
- Manual rate override/correction capability (if API fetch fails or requires adjustment)

**Pages:**
- `/admin/market-rates` - Current rates and history
- `/admin/market-rates/update` - Update daily rates

**Data Operations:**
- INSERT into `market_rates` table (store daily rates from API or manual entry)
- SELECT from `market_rates` table (view current rates and history)
- UPDATE `market_rates` table (manual override/correction)

**Business Rules:**
- Market rates are fetched daily from external API (automated)
- Admin can manually override/correct rates if API fetch fails
- Historical rates are preserved for audit and reconciliation

**Source:** Master PDR Section 2 (Website Scope, Administrator Features, Market Rates Management) and Section 4 (Administrator Flow 2: Fetch and Update Market Rates)

#### 6. Basic Reports

**Capabilities:**
- Daily collection report (total collected, breakdown by staff, customer, payment method)
- Weekly collection report (aggregated weekly data with trends)
- Monthly collection report (monthly summaries and comparisons)
- Staff performance report (collections per staff, target vs achievement, customer visits, missed payments)
- Customer payment report (payment history, missed payments, due payments, scheme-wise summary)
- Scheme performance report (enrollments per scheme, collections per scheme, completion rates)
- Basic financial reports (inflow/outflow analysis, net cash flow)
- Export all reports to PDF and Excel formats

**Pages:**
- `/admin/reports/daily` - Daily collection report
- `/admin/reports/weekly` - Weekly collection report
- `/admin/reports/monthly` - Monthly collection report
- `/admin/reports/staff-performance` - Staff performance report
- `/admin/reports/customer-payment` - Customer payment report
- `/admin/reports/scheme-performance` - Scheme performance report

**Data Operations:**
- SELECT from `payments` table (aggregate by date, staff, customer, payment method)
- SELECT from `user_schemes` table (aggregate enrollment and payment statistics)
- SELECT from `staff_metadata` table (aggregate staff performance metrics)
- Export queries for PDF/Excel generation

**Note:** Advanced analytics, machine learning, predictive modeling, and complex financial projections are deferred to a later phase.

**Source:** Master PDR Section 2 (Website Scope, Administrator Features, Basic Reports)

#### 7. System Administration

**Capabilities:**
- **System administration UI for database management** (view database health, monitor queries, manage connections)
- Manage system settings and preferences
- Configure business rules and validation criteria
- Manage user roles and permissions
- View system logs and audit trails

**Pages:**
- `/admin/settings` - System configuration (if applicable)

**Source:** Master PDR Section 2 (Website Scope, Administrator Features, System Administration)

### Administrator Restrictions

Administrators CANNOT:
- Modify payment records after creation (payments are append-only for audit compliance, UPDATE/DELETE prevented by database triggers)
- Delete historical transaction data (data retention policy)
- Bypass Row Level Security (RLS) policies (enforced at database level)
- Access mobile app (admins use website only)
- Modify core database schema or RLS policies (database administration is separate from application access)
- **Access advanced analytics or ML features** (deferred to later phase)

**Source:** Master PDR Section 3 (User Roles & Permissions, Administrator Restrictions)

### Administrator User Flows

**Note:** Detailed step-by-step user flows are defined in Master PDR Section 4 (Functional Requirements, Admin / Staff Flows). This section references those flows:

- **Administrator Flow 1:** View Financial Dashboard (Inflow/Outflow) (Master PDR Section 4)
- **Administrator Flow 2:** Fetch and Update Market Rates (Master PDR Section 4)

**Reference:** See Master PDR Section 4 for complete flow definitions with step-by-step instructions, success criteria, and error states.

---

## 5. Technical Architecture (Website-Specific)

### Web Frontend Stack

**Framework:**
- **Primary:** Next.js 14+ (App Router) - React-based framework with server components and API routes

**Language:**
- **Primary:** TypeScript 5.0+ (strict mode enabled)

**State Management:**
- **Client State:** React Query (TanStack Query) v5+ for server state (API data fetching, caching, synchronization)
- **UI State:** React Context API + `useState` hooks for local component state

**UI Components:**
- **Component Library:** shadcn/ui (headless UI components built on Radix UI)
- **Styling:** Tailwind CSS 3.4+
- **Icons:** Lucide React

**Authentication:**
- **Provider:** Supabase Auth JavaScript client
- **Session Management:** Supabase Auth SDK with automatic token refresh

**API Client:**
- **HTTP Client:** Supabase JavaScript Client (official Supabase SDK for API calls)

**Source:** Master PDR Section 6 (Technical Architecture, Web Frontend Stack)

### Deployment

**Hosting:**
- **Platform:** Vercel (recommended) or similar Next.js-optimized hosting
- **Build:** Next.js production build with static optimization where possible
- **CDN:** Automatic CDN distribution via hosting platform

**Environment:**
- **Development:** Local development with `.env` files
- **Staging:** Staging environment with separate Supabase project
- **Production:** Production environment with production Supabase project

**Source:** Master PDR Section 9 (Deployment & Environments)

### Mobile-Responsive Design

**Requirement:** Website must be accessible and functional on desktop, tablet, and mobile devices

**Implementation:**
- Responsive design using Tailwind CSS breakpoints
- Mobile-optimized navigation (collapsible sidebar, mobile menu)
- Touch-friendly UI elements for mobile devices
- Optimized layouts for different screen sizes

**Source:** Master PDR Section 2 (Website Scope, Navigation Structure)

---

## 6. Authority Boundaries (Non-Negotiable)

### Website Authority

The website is the **ONLY interface** authorized to:
1. Create customers
2. Enroll customers in schemes
3. Manage routes
4. Assign customers to staff
5. Update market rates
6. Approve/process withdrawals
7. Create/manage staff accounts
8. Modify schemes

**Enforcement:** These boundaries are enforced by:
- Database RLS policies that prevent mobile app from performing these operations
- Application code that restricts these operations to website interface only
- Architectural design that centralizes governance in website

**Source:** Master PDR Section 2.5 (Website Responsibility Boundary)

### Public Website Boundaries

The public website is **explicitly prohibited** from:
1. Authentication into core system
2. Direct writes to business-critical tables
3. Customer self-service operations
4. Financial operations

**Enforcement:** These boundaries are enforced by:
- RLS policies that prevent unauthenticated access to core tables
- Application code that does not attempt core operations from public pages
- Separate data tables for public website (leads, inquiries)

**Source:** Master PDR Section 2.6 (Public Website Scope)

### Database Authority

The database (Supabase PostgreSQL) is the **ultimate source of truth** and enforces all rules:
- RLS policies enforce authorization regardless of interface
- Database triggers enforce business rules (payment immutability, scheme totals)
- Foreign key constraints ensure referential integrity
- Application code cannot bypass database-level security

**Source:** Master PDR Section 2.5 (Website Responsibility Boundary, Backend: Ultimate Source of Truth) and Section 6.1 (System Architecture Principles)

---

## 7. Website Security & Data Access Rules

### Purpose

This section defines the security and data access rules that govern all website operations. These rules are enforced at the database level via Row Level Security (RLS) policies and are non-negotiable.

**Source:** Master PDR Section 3 (User Roles & Permissions, Authorization Rules) and Section 6.1 (System Architecture Principles)

### Database-First Security Enforcement

**Principle:** All authorization and data access MUST be enforced at the PostgreSQL database level via Row Level Security (RLS) policies. Frontend checks are secondary, non-authoritative, and cannot be relied upon for security.

**Binding Requirements:**
- **RLS Policies:** Every table MUST have RLS policies that enforce access control based on user role, authentication state, and business relationships
- **No Frontend-Only Security:** Website application code MUST NOT be the sole enforcement mechanism for authorization. Database RLS policies MUST prevent unauthorized access even if frontend checks are bypassed
- **RLS Coverage:** RLS policies MUST cover all operations (SELECT, INSERT, UPDATE, DELETE) for all tables containing business data
- **Enforcement:** If a user attempts to access data they are not authorized for, the database MUST reject the operation regardless of what the frontend allows

**Source:** Master PDR Section 6.1 (System Architecture Principles, Principle 1: Database-First Enforcement)

### Role-Based Access Control (RBAC)

**Permission Model:** Role-Based Access Control (RBAC) with attribute-based checks

**Role Hierarchy:**
```
Administrator (highest privilege)
    ↓ (inherits all staff permissions)
Staff (Collection Staff + Office Staff)
    ↓ (no inheritance, separate role)
Customer (lowest privilege, self-service only)
```

**Permission Inheritance:**
- Administrators inherit all staff permissions (can perform all staff actions)
- Staff roles (collection and office) do not inherit customer permissions (separate role)
- Customers have no permission inheritance (isolated to own data)

**Source:** Master PDR Section 3 (User Roles & Permissions, Authorization Rules)

### Authorization Enforcement Levels

**Database Level:** Row Level Security (RLS) policies enforced on all tables in PostgreSQL
- **Enforcement:** Supabase enforces RLS on all queries automatically
- **Authority:** Database RLS is the authoritative enforcement mechanism
- **Bypass Prevention:** Application code cannot bypass RLS policies

**Application Level:** Role checks in application code before displaying UI elements
- **Purpose:** UI display only (show/hide buttons, menus, pages)
- **Authority:** Non-authoritative. UI hiding does NOT prevent unauthorized access
- **Requirement:** All operations must still pass RLS policy checks at database level

**API Level:** All API requests validated against RLS policies
- **Enforcement:** Supabase enforces RLS on all API requests automatically
- **Validation:** Every SELECT, INSERT, UPDATE, DELETE operation is validated against RLS policies

**Source:** Master PDR Section 3 (User Roles & Permissions, Authorization Enforcement)

### Office Staff Data Access Rules

**Authorized Operations:**
- **Customers:** CREATE, READ, UPDATE (all customers)
- **User Schemes:** CREATE (enrollments for any customer), READ (all enrollments)
- **Routes:** CREATE, READ, UPDATE (all routes)
- **Staff Assignments:** CREATE, READ, UPDATE (all assignments)
- **Payments:** READ (all payments), INSERT (office collections with `staff_id = NULL`)
- **Withdrawals:** READ (all withdrawals), UPDATE (approve/reject/process withdrawals)
- **Profiles:** READ (all customer profiles), UPDATE (customer profiles, limited fields)

**Prohibited Operations:**
- **Staff Metadata:** Cannot CREATE, UPDATE, or DELETE staff accounts
- **Schemes:** Cannot UPDATE scheme definitions (admin-only)
- **Market Rates:** Cannot UPDATE market rates (admin-only, rates fetched from API)
- **Payments:** Cannot UPDATE or DELETE payments (append-only, immutable)

**RLS Policy Enforcement:**
- Office staff operations are validated against RLS policies that check `is_staff() AND staff_type = 'office'`
- RLS policies prevent office staff from accessing admin-only data
- RLS policies allow office staff to read all customers and transactions (read-only access)

**Source:** Master PDR Section 3 (User Roles & Permissions, Office Staff row) and Section 8 (Data Model Overview, Access Constraints)

### Administrator Data Access Rules

**Authorized Operations:**
- **All Operations:** Full access to all tables and operations (inherits all office staff permissions)
- **Staff Management:** CREATE, READ, UPDATE, DELETE staff accounts
- **Scheme Management:** UPDATE scheme definitions, enable/disable schemes
- **Market Rates:** UPDATE market rates (manual override/correction)
- **Financial Data:** READ all financial data (payments, withdrawals, enrollments)
- **System Administration:** Access to system administration UI

**Prohibited Operations:**
- **Payments:** Cannot UPDATE or DELETE payments (append-only for audit compliance, blocked by database triggers)
- **Historical Data:** Cannot DELETE historical transaction data (data retention policy)
- **RLS Bypass:** Cannot bypass Row Level Security policies (enforced at database level)
- **Schema Modification:** Cannot modify core database schema or RLS policies (database administration is separate)

**RLS Policy Enforcement:**
- Administrator operations are validated against RLS policies that check `is_admin()`
- RLS policies allow administrators to access all data across all tables
- Database triggers still prevent payment modifications even for administrators

**Source:** Master PDR Section 3 (User Roles & Permissions, Administrator row) and Section 8 (Data Model Overview, Access Constraints)

### Public Website Data Access Rules

**Authorized Operations:**
- **Leads/Inquiries Table:** INSERT (form submissions only, unauthenticated)
- **Schemes Table:** SELECT (active schemes only, read-only, for marketing display)
- **Static Content:** Serve static content without database interaction

**Prohibited Operations:**
- **All Core Tables:** No access to `profiles`, `customers`, `user_schemes`, `payments`, `withdrawals`, `staff_metadata`, `staff_assignments`, `market_rates`, `routes` tables
- **Authentication:** Cannot authenticate users or access authenticated features
- **Financial Data:** Cannot access any financial or transaction data

**RLS Policy Enforcement:**
- Public website operates with unauthenticated or minimal database permissions
- RLS policies prevent unauthenticated access to core business tables
- Separate `leads` or `inquiries` table (if created) has RLS policy allowing unauthenticated INSERT only

**Source:** Master PDR Section 2.6 (Public Website Scope, Prohibited Interactions with Core Tables)

### Payment Immutability Rules

**Principle:** Payments and financial transactions are immutable after creation. UPDATE and DELETE operations on financial records are permanently prohibited.

**Binding Requirements:**
- **Payment Immutability:** The `payments` table MUST NOT allow UPDATE or DELETE operations. Database triggers MUST block these operations regardless of user role
- **Reversal Pattern:** Payment reversals MUST be implemented as new `payments` records with `is_reversal = true` and `reverses_payment_id` pointing to the original payment
- **Enforcement:** Database triggers prevent payment modifications even if application code attempts them

**Website Application Rules:**
- Website MUST NOT attempt UPDATE or DELETE on `payments` table
- Website MUST NOT provide UI for modifying or deleting payments
- Website MUST implement reversals as new payment records, not modifications

**Source:** Master PDR Section 6.1 (System Architecture Principles, Principle 2: Append-Only Financial Records) and Section 8 (Data Model Overview, Payments row)

### Session Security

**Authentication Provider:** Supabase Auth (managed authentication service)

**Session Management:**
- **Access Token Expiration:** 1 hour (default Supabase setting)
- **Refresh Token Expiration:** 30 days (default Supabase setting)
- **Automatic Token Refresh:** Supabase Auth SDK handles automatic token refresh
- **Session Persistence:** Session persists across browser sessions (cached by Supabase SDK)

**Security Requirements:**
- All authenticated routes MUST verify valid session token
- Expired sessions MUST redirect to login page
- Session tokens MUST be validated on every API request
- HTTPS MUST be enforced for all authentication and data operations

**Source:** Master PDR Section 3 (User Roles & Permissions, Authentication Rules) and Section 5 (Non-Functional Requirements, Security Requirements)

### API Security

**Rate Limiting:**
- **Authentication endpoints:** 10 requests per minute per IP address (prevents brute force)
- **Data endpoints:** 100 requests per minute per authenticated user (prevents abuse)
- **Payment endpoints:** 20 requests per minute per authenticated user (prevents duplicate payments)

**Input Validation:**
- All user inputs MUST be validated client-side and server-side
- Database constraints and RLS policies provide server-side validation
- Application code MUST validate input format, range, and type before submission

**CORS Policy:**
- Website API calls restricted to allowed origins (Supabase project settings)
- Cross-origin requests MUST be explicitly allowed in Supabase configuration

**Source:** Master PDR Section 5 (Non-Functional Requirements, Security Requirements, API Security)

---

## 8. Explicit Website Non-Goals

### Purpose

This section explicitly defines what the website will NOT do in Phase 1. These are non-negotiable exclusions that prevent scope creep and maintain focus on core operational requirements.

**Source:** Master PDR Section 2.4 (Explicit OUT OF SCOPE)

### Website Features - OUT OF SCOPE

**Customer Self-Service:**
- Customer self-service portal on website (customers use mobile app only for self-service)
- Customer self-enrollment in schemes (enrollment performed only by office staff via website)
- Customer payment processing on website (payments collected via mobile app or manual entry)

**Payment Processing:**
- Payment gateway integration on website (payments recorded manually or via mobile app)
- Online payment processing for customers (not in Phase 1 scope)

**Advanced Analytics:**
- Advanced analytics, machine learning, or predictive modeling (deferred to later phase)
- Custom report builder (predefined reports only)
- Complex financial projections beyond basic reports

**Third-Party Integrations:**
- Third-party integrations beyond Supabase (no external CRM, accounting software, etc.)
- Webhook integrations with external services (beyond market price API)
- Single Sign-On (SSO) integration
- API access for third-party integrations (no public API in Phase 1)

**Data Operations:**
- Bulk data import/export beyond basic CSV/Excel export of transactions and reports
- Data archival or automated data purging (data retention policy TBD)
- Custom backup and disaster recovery automation (handled by Supabase)

**Localization:**
- Multi-language support (English only in Phase 1)

**Source:** Master PDR Section 2.4 (Explicit OUT OF SCOPE, Website Features)

### Mobile App Features - OUT OF SCOPE (Website Perspective)

**Mobile Application:**
- Office staff mobile app (office staff use website only)
- Admin mobile app (admins use website only)
- Any mobile app functionality (separate mobile application)

**Mobile-Specific Features:**
- Customer-to-staff assignment on mobile (assignment done on website only)
- Route management on mobile (route management done on website only)
- Scheme creation/editing on mobile (scheme management done on website only)
- Market rate updates on mobile (rate updates done on website only)
- Comprehensive financial reporting on mobile (reports available on website only)

**Source:** Master PDR Section 2.4 (Explicit OUT OF SCOPE, Mobile App Features)

### Shared/Backend Features - OUT OF SCOPE

**Serverless Functions:**
- Edge Functions or serverless functions (using Supabase RPC functions only)

**Scheduled Jobs:**
- Scheduled jobs or cron tasks (handled externally if needed for market price API fetch)

**File Storage:**
- File storage beyond Supabase Storage (if document uploads needed, use Supabase Storage)

**Authentication:**
- Custom authentication providers beyond Supabase Auth

**Source:** Master PDR Section 2.4 (Explicit OUT OF SCOPE, Shared/Backend Features)

### Public Website Non-Goals

**Authentication:**
- Public website cannot provide login functionality (authentication on separate `/login` route)
- Public website cannot authenticate users into core system

**Data Operations:**
- Public website cannot write to business-critical tables
- Public website cannot create customer accounts
- Public website cannot enroll customers in schemes
- Public website cannot process payments or withdrawals
- Public website cannot access customer data or transaction history

**Source:** Master PDR Section 2.6 (Public Website Scope, What the Public Website is NOT)

### Non-Goals Enforcement

**Scope Discipline:**
- Only features explicitly listed as IN SCOPE in Master PDR Section 2.3 are implemented
- Features listed as OUT OF SCOPE are not implemented, regardless of ease of implementation or perceived value
- Features not explicitly listed as IN SCOPE are OUT OF SCOPE by default

**Source:** Master PDR Section 6.1 (System Architecture Principles, Principle 5: Phase-1 Discipline)

---

## 9. Website MVP Success Criteria

### Purpose

This section defines measurable success criteria specific to the website component. These criteria validate that the website meets its operational objectives and serves as the authoritative control plane for the system.

**Source:** Master PDR Section 1 (Project Overview, Success Metrics) - Website-specific extraction

### Operational Efficiency Metrics

**Metric 1: Customer Creation Efficiency**
- **Description:** Time required for office staff to create a new customer record via website
- **Target:** Complete customer creation (including KYC details and profile setup) within 5 minutes per customer
- **Measurement:** Time from form load to successful customer record creation in database, measured as median time across all customer creations
- **Baseline:** Current manual customer registration time (to be established)

**Metric 2: Scheme Enrollment Efficiency**
- **Description:** Time required for office staff to enroll a customer in an investment scheme via website
- **Target:** Complete enrollment (scheme selection, frequency, amount range, start date) within 3 minutes per enrollment
- **Measurement:** Time from enrollment form load to successful `user_schemes` record creation, measured as median time across all enrollments
- **Baseline:** Current manual enrollment time (to be established)

**Metric 3: Staff Assignment Efficiency**
- **Description:** Time required for office staff to assign a new customer to a collection staff member via website
- **Target:** Complete assignment (route selection, customer selection, staff selection) within 2 minutes per customer
- **Measurement:** Time from assignment interface load to successful `staff_assignments` record creation, measured as median time across all assignments
- **Baseline:** Current manual assignment time (estimated 15-30 minutes)

**Source:** Master PDR Section 1 (Project Overview, Success Metrics, Metric 5: Staff Assignment Efficiency)

### Data Quality Metrics

**Metric 4: Customer Enrollment Accuracy**
- **Description:** Percentage of customer enrollments created via website that are complete and accurate (no missing required fields, valid data)
- **Target:** 99% of enrollments are complete and accurate (no data correction required after creation)
- **Measurement:** Count of enrollments with all required fields populated and valid data, divided by total enrollments created, measured monthly
- **Baseline:** N/A (new system)

**Metric 5: Payment Recording Accuracy (Office Collections)**
- **Description:** Percentage of manual payments entered via website that match actual office collections
- **Target:** 100% accuracy (all manual payments correctly recorded with accurate amounts, dates, and customer information)
- **Measurement:** Reconciliation of manual payment entries against office collection records, measured monthly
- **Baseline:** N/A (new system)

### System Availability Metrics

**Metric 6: Website Uptime**
- **Description:** Percentage of time the website is available and operational for office staff and administrators
- **Target:** 99.5% uptime (approximately 3.6 hours of downtime per month maximum)
- **Measurement:** Monitoring service tracking HTTP response codes and database connectivity, calculated as (total_time - downtime) / total_time * 100, measured monthly
- **Baseline:** N/A (new system)

**Metric 7: Website Response Time**
- **Description:** Average page load time for authenticated website pages
- **Target:** Page load time under 3 seconds for 95% of page loads (measured on standard desktop connection)
- **Measurement:** Time from page request to fully rendered page, measured as 95th percentile across all authenticated page loads
- **Baseline:** N/A (new system)

**Source:** Master PDR Section 1 (Project Overview, Success Metrics, Metric 4: System Uptime) and Section 5 (Non-Functional Requirements, Performance Targets)

### User Adoption Metrics

**Metric 8: Office Staff Website Adoption**
- **Description:** Percentage of office staff who use the website for customer management and enrollment operations
- **Target:** 100% of office staff use website for all customer management operations (no manual processes)
- **Measurement:** Count of office staff who have created at least one customer or enrollment via website, divided by total office staff, measured monthly
- **Baseline:** 0% (new system, all staff must adopt)

**Metric 9: Administrator Dashboard Usage**
- **Description:** Frequency of administrator access to financial dashboard and reports
- **Target:** Administrators access financial dashboard at least once per day for decision-making
- **Measurement:** Count of administrator logins with financial dashboard page views, measured weekly
- **Baseline:** N/A (new system)

### Data Integrity Metrics

**Metric 10: RLS Policy Compliance**
- **Description:** Zero unauthorized data access attempts (all operations properly restricted by RLS policies)
- **Target:** 100% compliance (zero RLS policy violations or unauthorized access attempts)
- **Measurement:** Count of RLS policy violations or unauthorized access attempts logged by Supabase, measured monthly
- **Baseline:** N/A (new system, target is zero violations)

**Metric 11: Payment Immutability Compliance**
- **Description:** Zero payment modification attempts (all payments remain immutable after creation)
- **Target:** 100% compliance (zero payment UPDATE or DELETE operations, all reversals implemented as new records)
- **Measurement:** Count of payment UPDATE or DELETE operations blocked by database triggers, measured monthly
- **Baseline:** N/A (new system, target is zero modification attempts)

**Source:** Master PDR Section 6.1 (System Architecture Principles, Principle 1: Database-First Enforcement and Principle 2: Append-Only Financial Records)

### Success Criteria Summary

**Website MVP is considered successful if:**
1. All 11 metrics meet or exceed their target values
2. Website serves as the exclusive control plane for customer creation, enrollment, and staff assignment
3. Zero security violations (RLS policy compliance, payment immutability)
4. Office staff adoption rate of 100% for core operations
5. System uptime of 99.5% or higher
6. All operational efficiency targets met (customer creation, enrollment, assignment)

**Measurement Period:** Metrics are measured monthly for the first 6 months, then quarterly thereafter.

**Source:** Derived from Master PDR Section 1 (Project Overview, Success Metrics)

---

## 10. Reference to Master PDR

### Complete System Requirements

This Website PDR focuses exclusively on website responsibilities and boundaries. For complete system requirements, refer to the Master PDR:

**Master PDR Sections:**
- **Section 1:** Project Overview (business objectives, target users, success metrics)
- **Section 2:** Scope Definition (complete system scope, IN SCOPE, OUT OF SCOPE)
- **Section 3:** User Roles & Permissions (complete role definitions, authentication, authorization)
- **Section 4:** Functional Requirements (complete user flows for all roles)
- **Section 5:** Non-Functional Requirements (performance, security, scalability, availability)
- **Section 6:** Technical Architecture (complete technical stack, database approach, API structure)
- **Section 7:** Integrations (payment processing, notifications, external services)
- **Section 8:** Data Model Overview (complete database schema, relationships, constraints)
- **Section 9:** Deployment & Environments (environment configuration, hosting, CI/CD)
- **Section 10:** Assumptions & Constraints (business assumptions, technical constraints)
- **Section 11:** Risks & Mitigation (technical, product, operational risks)
- **Section 12:** Deliverables & Milestones (phase-wise breakdown)
- **Section 13:** Open Questions

**Source Document:** `PROJECT_DEFINITION_REPORT.md` (Master PDR v1.1)

### Conflict Resolution

**In case of any conflict or ambiguity:**
- The Master PDR always prevails
- This Website PDR does NOT redefine or contradict Master PDR requirements
- This Website PDR extracts and formalizes website-specific content only
- All system-level requirements are defined in the Master PDR

---

## Document End

**Version:** 1.0  
**Last Updated:** [Date]  
**Source:** Master PDR v1.1  
**Status:** Draft
