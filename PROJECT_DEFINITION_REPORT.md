# [PROJECT NAME] - PROJECT DEFINITION REPORT

**Version:** 1.1  
**Date:** [Date]  
**Status:** Draft  
**Owner:** [Name/Role]

---

## Document Control

- **Version:** 1.1
- **Last Updated:** [Date]
- **Owner:** [Name/Role]
- **Approval Status:** [Draft / Approved / In Review]
- **Stakeholder Sign-off:** [List approvers and dates]

---

## 1. PROJECT OVERVIEW

### Business Objective
Enable SLG Thangangal to digitize and scale its gold/silver investment scheme operations by providing a unified platform for customer enrollment, payment collection, staff management, and financial oversight. The system will replace manual processes with automated workflows, reduce operational errors, improve collection efficiency, and provide real-time financial visibility to support business growth and decision-making.

**Strategic Outcomes:**
- Increase customer enrollment capacity by 300% within 12 months
- Reduce payment collection time by 60% through mobile-enabled field collection
- Eliminate manual data entry errors and reconciliation delays
- Enable data-driven decision-making through real-time financial dashboards
- Support geographic expansion by enabling route-based staff assignment and customer management

### Problem Being Solved
SLG Thangangal currently operates gold/silver investment schemes using manual processes that create significant operational bottlenecks and risks:

1. **Manual Payment Collection:** Collection staff record payments on paper or basic spreadsheets, requiring office staff to manually transcribe data, leading to errors, delays, and lost receipts.

2. **Customer Management Fragmentation:** Customer enrollment, scheme assignment, and staff routing are managed through separate systems (spreadsheets, paper records), making it difficult to track customer status, payment history, and staff assignments.

3. **Lack of Real-Time Visibility:** Management cannot access real-time financial data (daily collections, pending payments, staff performance) without manual aggregation, delaying critical business decisions.

4. **Route and Assignment Inefficiency:** Office staff manually assign customers to collection staff based on routes using spreadsheets, making it difficult to optimize assignments, track coverage, and reassign customers when staff changes occur.

5. **Audit and Compliance Risk:** Payment records are not immutable, making it difficult to maintain audit trails and comply with financial regulations. Manual processes increase the risk of data tampering or loss.

6. **Limited Scalability:** Current manual processes do not scale with business growth. Adding new customers, staff, or routes requires proportional increases in administrative overhead.

**Why Now:** The business is experiencing growth that makes manual processes unsustainable. Digital transformation is required to maintain service quality, reduce operational costs, and enable expansion into new markets.

### Target Users

**Primary Users:**

1. **Customers (Mobile App)**
   - **Characteristics:** Individuals investing in gold/silver savings schemes, typically using smartphones, varying technical literacy
   - **Needs:** Easy enrollment in schemes, transparent view of investments, payment reminders, withdrawal requests, transaction history
   - **Interaction:** Mobile app (iOS/Android) for self-service account management, payment tracking, and investment portfolio viewing (scheme enrollment performed by office staff via website)
   - **Volume:** Expected 1,000+ active customers in Year 1

2. **Collection Staff (Mobile App)**
   - **Characteristics:** Field agents collecting payments from customers, using mobile devices in various network conditions
   - **Needs:** Quick access to assigned customer list, fast payment recording, daily target tracking, offline capability for areas with poor connectivity
   - **Interaction:** Mobile app (iOS/Android) optimized for field use, with offline sync capability
   - **Volume:** Expected 20-50 collection staff members

3. **Office Staff (Website)**
   - **Characteristics:** Administrative personnel managing customer enrollment, staff assignments, and route management from desktop workstations
   - **Needs:** Customer registration interface, route management, customer-to-staff assignment tools, transaction monitoring, manual payment entry for office collections
   - **Interaction:** Web application accessible via desktop browsers, optimized for data entry and management workflows
   - **Volume:** Expected 5-10 office staff members

4. **Administrators (Website)**
   - **Characteristics:** Management and financial oversight personnel requiring comprehensive system access and financial reporting
   - **Needs:** Complete financial dashboard (inflow/outflow), all customer and staff data access, scheme management, market rate updates, comprehensive reporting and analytics
   - **Interaction:** Web application with basic reporting, export capabilities, and full system configuration access
   - **Volume:** Expected 2-5 administrators

**Secondary Users:**
- **System Administrators:** Technical staff managing infrastructure, deployments, and system maintenance (not end-users of the application)

### Success Metrics (Measurable)

- **Metric 1: Customer Enrollment Rate**
  - **Description:** Number of new customers enrolled per month through the digital platform
  - **Target:** 100 new customers per month by Month 6, 150 new customers per month by Month 12
  - **Measurement:** Count of new customer records created in `customers` table with `created_at` timestamp, aggregated monthly
  - **Baseline:** Current manual enrollment rate (to be established)

- **Metric 2: Payment Collection Efficiency**
  - **Description:** Average time from payment collection to system recording (field collection to database persistence)
  - **Target:** Reduce from current manual process time (estimated 24-48 hours) to under 5 minutes for 95% of payments
  - **Measurement:** Time difference between `payment_date` + `payment_time` (when collected) and `created_at` timestamp in `payments` table, calculated as median time across all payments
  - **Baseline:** Current manual process time (to be measured)

- **Metric 3: Daily Collection Volume**
  - **Description:** Total amount collected per day across all staff
  - **Target:** Maintain or increase current daily collection volume, with 20% growth target by Month 12
  - **Measurement:** Sum of `amount` field in `payments` table where `payment_date = CURRENT_DATE` and `status = 'completed'`, tracked daily
  - **Baseline:** Current daily collection average (to be established from historical data)

- **Metric 4: System Uptime**
  - **Description:** Percentage of time the system is available and operational for end-users
  - **Target:** 99.5% uptime (approximately 3.6 hours of downtime per month maximum)
  - **Measurement:** Monitoring service tracking HTTP response codes and database connectivity, calculated as (total_time - downtime) / total_time * 100, measured monthly
  - **Baseline:** N/A (new system)

- **Metric 5: Staff Assignment Efficiency**
  - **Description:** Time required for office staff to assign a new customer to a collection staff member
  - **Target:** Reduce assignment time from current manual process (estimated 15-30 minutes) to under 2 minutes per customer
  - **Measurement:** Time from customer creation to `staff_assignments` record creation, measured as median time across all assignments, tracked monthly
  - **Baseline:** Current manual assignment time (to be measured)

---

## 2. SCOPE DEFINITION

### Website Scope

#### Features & Functionality

**Office Staff Features:**
1. **Customer Management**
   - Create new customer records with full KYC details (name, phone, address, nominee information, identity documents)
   - View customer list with search and filter capabilities (by name, phone, route, assigned staff, scheme status)
   - Edit customer information (profile details, address, nominee information)
   - View individual customer profile with complete history (schemes, payments, withdrawals)
   - Soft delete customers (mark as inactive, preserve historical data)
   - **Enroll customers in investment schemes** (select scheme, set payment frequency, amount range, start date)

2. **Route Management**
   - Create and manage routes (geographic territories with name, description, area coverage)
   - Assign routes to collection staff members
   - View route assignments and coverage
   - Edit route details and area coverage
   - Deactivate routes (preserve historical assignments)

3. **Customer-to-Staff Assignment**
   - Assign customers to collection staff based on route
   - Bulk assign multiple customers to a staff member by route
   - Manual assignment of individual customers to staff
   - Reassign customers when staff changes occur
   - View assignment history and track changes
   - Remove assignments (deactivate, preserve history)

4. **Transaction Management**
   - View all transactions (payments and withdrawals) with real-time updates
   - Filter transactions by date range, staff member, customer, payment method, route
   - Search transactions by customer name, phone, receipt ID
   - View detailed transaction information (amount, date, time, method, staff, customer)
   - Manual payment entry for office collections (record payments received at office)
   - Export transaction data to CSV/Excel format

5. **Transaction Monitoring**
   - Real-time dashboard showing today's collections, pending payments, staff activity
   - Monitor all staff collection activities
   - View transaction trends and patterns
   - Track payment methods distribution (cash, UPI, bank transfer)

**Administrator Features:**
1. **Financial Dashboard**
   - Complete financial overview with key metrics (total customers, active schemes, total collections, withdrawals)
   - Daily/weekly/monthly inflow tracking (all payment collections)
   - Daily/weekly/monthly outflow tracking (all withdrawals, expenses)
   - Net cash flow calculation and visualization
   - Real-time financial data updates
   - Interactive charts and graphs (line charts, bar charts, pie charts)
   - Financial trend analysis (growth rates, comparisons)

2. **Complete Financial Data Access**
   - View all payments across all staff and customers with advanced filtering
   - View all withdrawals with status tracking (pending, approved, processed, rejected)
   - View all customer enrollments and scheme statuses
   - View all staff assignments and route coverage
   - Access to historical market rates data
   - Export financial data in multiple formats (CSV, Excel, PDF)

3. **Staff Management**
   - Create new staff accounts (collection staff and office staff) with credentials
   - View all staff members with performance metrics
   - Edit staff details (name, phone, email, targets, status)
   - Deactivate staff accounts (preserve historical data)
   - Set and update daily collection targets for staff
   - View staff performance reports (collections, targets, customer visits)

4. **Scheme Management**
   - View all 18 investment schemes (9 Gold schemes, 9 Silver schemes)
   - Edit scheme details (name, description, minimum/maximum amounts, payment frequencies, features)
   - Enable/disable schemes (control which schemes are available for enrollment)
   - View scheme enrollment statistics
   - Manage scheme-specific settings and rules

5. **Market Rates Management**
   - **Fetch daily gold and silver market rates from external API** (automated daily fetch via scheduled job or manual trigger)
   - View current rates and rate history with date tracking
   - Set rate change notifications (optional feature for rate alerts)
   - Manual rate override/correction capability (if API fetch fails or requires adjustment)

6. **Basic Reports**
   - Daily collection report (total collected, breakdown by staff, customer, payment method)
   - Weekly collection report (aggregated weekly data with trends)
   - Monthly collection report (monthly summaries and comparisons)
   - Staff performance report (collections per staff, target vs achievement, customer visits, missed payments)
   - Customer payment report (payment history, missed payments, due payments, scheme-wise summary)
   - Scheme performance report (enrollments per scheme, collections per scheme, completion rates)
   - Basic financial reports (inflow/outflow analysis, net cash flow)
   - Export all reports to PDF and Excel formats
   - **Note:** Advanced analytics, machine learning, predictive modeling, and complex financial projections are deferred to a later phase

7. **System Administration**
   - **System administration UI for database management** (view database health, monitor queries, manage connections)
   - Manage system settings and preferences
   - Configure business rules and validation criteria
   - Manage user roles and permissions
   - View system logs and audit trails

#### Pages & Navigation

**Public Pages:**
- `/` - Landing page (public-facing marketing website with company information, services overview, contact details)
- `/about` - About us page
- `/services` - Services overview page
- `/contact` - Contact us page
- `/login` - Authentication page for office staff and administrators

**Authenticated Pages - Office Staff:**
- `/office/dashboard` - Office staff dashboard with today's overview
- `/office/customers` - Customer list with search and filters
- `/office/customers/add` - New customer registration form
- `/office/customers/[id]` - Individual customer profile view
- `/office/customers/[id]/edit` - Edit customer information
- `/office/customers/[id]/enroll` - Enroll customer in scheme (new scheme enrollment form)
- `/office/routes` - Route list and management
- `/office/routes/add` - Create new route
- `/office/routes/[id]` - Route details with assigned staff
- `/office/routes/[id]/assign-staff` - Assign staff to route
- `/office/assignments` - Customer-to-staff assignment interface
- `/office/assignments/by-route` - Bulk assign customers by route
- `/office/assignments/manual` - Manual individual assignment
- `/office/transactions` - Transaction list with filters
- `/office/transactions/add` - Manual payment entry form
- `/office/transactions/[id]` - Transaction detail view

**Authenticated Pages - Administrators:**
- `/admin/dashboard` - Financial dashboard with complete overview
- `/admin/financials` - Financial data section
  - `/admin/financials/inflow` - Collections and inflow tracking
  - `/admin/financials/outflow` - Withdrawals and outflow tracking
  - `/admin/financials/cash-flow` - Net cash flow analysis
- `/admin/customers` - All customers management (inherits office staff customer features)
- `/admin/staff` - Staff management
  - `/admin/staff` - Staff list
  - `/admin/staff/add` - Create new staff
  - `/admin/staff/[id]` - Staff profile and performance
  - `/admin/staff/[id]/edit` - Edit staff details
- `/admin/schemes` - Scheme management
  - `/admin/schemes` - Scheme list
  - `/admin/schemes/[id]/edit` - Edit scheme details
- `/admin/market-rates` - Market rates management
  - `/admin/market-rates` - Current rates and history
  - `/admin/market-rates/update` - Update daily rates
- `/admin/reports` - Reports section
  - `/admin/reports/daily` - Daily collection report
  - `/admin/reports/weekly` - Weekly collection report
  - `/admin/reports/monthly` - Monthly collection report
  - `/admin/reports/staff-performance` - Staff performance report
  - `/admin/reports/customer-payment` - Customer payment report
  - `/admin/reports/scheme-performance` - Scheme performance report
- `/admin/settings` - System configuration (if applicable)

**Navigation Structure:**
- Top navigation bar with role-based menu items
- Sidebar navigation for authenticated users (collapsible)
- Breadcrumb navigation for deep pages
- Role-based access control on all routes
- **Mobile-responsive design** (optimized for desktop, tablet, and mobile devices)

#### User Roles on Website

**Office Staff Role:**
- **Access Level:** Limited to customer management, route management, assignment management, scheme enrollment, and transaction monitoring
- **Capabilities:**
  - Create, read, update customers (own created customers and assigned customers)
  - **Enroll customers in investment schemes** (create `user_schemes` records, select scheme, set payment frequency, amount range, start date)
  - Create, read, update routes
  - Assign customers to staff based on routes
  - View all transactions (read-only except manual payment entry)
  - Enter manual payments for office collections
  - Export transaction data
  - View assigned customers and routes
- **Restrictions:**
  - Cannot access financial dashboards or comprehensive reports (basic reports only)
  - Cannot manage staff accounts
  - Cannot modify schemes (scheme management is admin-only)
  - Cannot update market rates (rates fetched from external API)
  - Cannot view system-wide financial analytics
  - Cannot access admin-only reports or advanced analytics

**Administrator Role:**
- **Access Level:** Full system access with complete financial visibility
- **Capabilities:**
  - All office staff capabilities (customer management, routes, assignments, transactions)
  - Complete financial dashboard with inflow/outflow tracking
  - Staff management (create, edit, deactivate staff, set targets)
  - Scheme management (edit schemes, enable/disable)
  - Market rates management (update daily rates, view history)
  - Comprehensive reports and analytics (all report types)
  - Export financial data in multiple formats
  - System configuration access (if applicable)
- **Restrictions:**
  - Cannot modify payment records (payments are append-only for audit)
  - Cannot delete historical transaction data
  - Cannot bypass Row Level Security (RLS) policies

### Mobile Application Scope

#### Platforms

- **iOS:** Minimum version iOS 13.0 (iPhone 6s and later)
- **Android:** Minimum version Android 8.0 (API level 26, Oreo)
- **Cross-platform:** Single Flutter codebase deployed to both platforms

#### Features & Functionality

**Customer Features:**
1. **Authentication**
   - Phone number-based login with OTP verification via SMS
   - 6-digit PIN setup and login (stored securely using Flutter Secure Storage)
   - Optional biometric authentication (Face ID, Touch ID, Fingerprint) for quick login
   - Session management with automatic token refresh

2. **Dashboard**
   - Investment overview showing total gold/silver holdings in grams
   - Current market value of investments
   - Active schemes summary (scheme name, enrollment date, maturity date, total paid)
   - Quick access to payment schedule, transaction history, and withdrawals
   - Real-time market rates display (gold and silver)

3. **Scheme Management**
   - Browse all available investment schemes (18 schemes: 9 Gold, 9 Silver)
   - View detailed scheme information (description, minimum/maximum amounts, payment frequencies, features, terms)
   - **View own scheme enrollments** (enrollment status, progress tracking)
   - **View completed/matured schemes**
   - **Note:** Customers CANNOT enroll themselves in schemes. Enrollment is performed ONLY by office staff via website.

4. **Payment Tracking**
   - View payment schedule calendar (daily, weekly, or monthly based on scheme)
   - View transaction history (all payments made, dates, amounts, methods)
   - View transaction details (receipt ID, payment date, amount, method, gold/silver grams added)
   - Track payment progress toward scheme completion

5. **Investment Portfolio**
   - View total investment summary (total amount paid, total gold grams, total silver grams)
   - View gold asset details (total gold grams, current gold rate, current value)
   - View silver asset details (total silver grams, current silver rate, current value)
   - Real-time portfolio value calculation based on current market rates

6. **Withdrawals**
   - Request withdrawals (partial or full withdrawal from schemes)
   - View withdrawal history and status (pending, approved, processed, rejected)
   - Track withdrawal requests and processing status

7. **Market Rates**
   - View current gold and silver market rates
   - View rate history (optional feature)

8. **Profile Management**
   - View and edit personal profile (name, phone, address)
   - View account information (KYC details, nominee information)
   - App settings (notifications, language, theme)
   - Help and support access
   - Privacy policy and terms & conditions

**Collection Staff Features:**
1. **Authentication**
   - Staff code and password login (staff code format: SLG001, SLG002, etc.)
   - 6-digit PIN setup and login (stored securely)
   - Session management with role validation (only collection staff can access mobile app)

2. **Dashboard**
   - Today's collection target (amount target and customer target)
   - Today's collection progress (amount collected, customers visited, pending customers)
   - Quick stats (total customers assigned, due today count, pending count)
   - Access to collection tab, reports, and profile

3. **Customer Collection**
   - View assigned customers list (filtered by active assignments)
   - Search customers by name or phone
   - Filter customers by payment status (all, due today, pending)
   - View customer details (name, phone, address, active schemes, payment history)
   - Record payment collection (amount, payment method: cash/UPI/bank transfer, date, time)
   - View payment history per customer
   - Track which customers have been collected today

4. **Payment Collection**
   - Quick payment entry interface optimized for field use
   - Support for multiple payment methods (cash, UPI, bank transfer)
   - Automatic calculation of gold/silver grams based on current market rate
   - Receipt generation with unique receipt ID
   - Offline payment recording with automatic sync when connection restored

5. **Target Tracking**
   - View today's target breakdown (amount target vs collected, customer target vs visited)
   - View target details and progress
   - Track daily performance metrics

6. **Reports**
   - View today's collections summary
   - View collection statistics (total collected, customer-wise breakdown)
   - View performance metrics (target achievement, customer visits)

7. **Profile Management**
   - View staff profile (name, staff code, phone, email, join date)
   - View account information
   - App settings
   - Logout functionality

**Shared Mobile Features:**
- Offline data caching for critical data (customer list, schemes, market rates)
- Automatic data synchronization when connection restored
- Push notifications for important updates (payment reminders, withdrawal status, rate updates)
- Error handling with user-friendly error messages
- Loading states and progress indicators
- Responsive design for various screen sizes

#### User Roles on Mobile

**Customer Role:**
- **Access Level:** Self-service access to own account and investments (read-only except profile updates and withdrawal requests)
- **Capabilities:**
  - View own profile, schemes, payments, withdrawals
  - **View own scheme enrollment status and progress** (read-only, cannot enroll)
  - Request withdrawals
  - View market rates and portfolio value
  - Update personal information (name, address, nominee details)
- **Restrictions:**
  - **CANNOT enroll in schemes** (enrollment performed only by office staff)
  - Cannot view other customers' data
  - Cannot access staff features
  - Cannot record payments (payments recorded by staff)
  - Cannot modify payment records
  - Cannot access administrative features

**Collection Staff Role:**
- **Access Level:** Field collection access with assigned customer visibility
- **Capabilities:**
  - View assigned customers only (filtered by `staff_assignments` table)
  - Record payment collections for assigned customers
  - View assigned customers' payment history
  - View own performance metrics and targets
  - View own profile and account information
- **Restrictions:**
  - Cannot view customers not assigned to them
  - Cannot modify payment records after creation (payments are append-only)
  - Cannot create or edit customer records
  - Cannot manage routes or assignments
  - Cannot access office staff or admin features
  - Cannot view system-wide financial data
  - Office staff (`staff_type='office'`) are explicitly blocked from mobile app access

### Explicit IN SCOPE

**Website Features:**
- **Public-facing website with landing pages** (home, about, services, contact pages)
- **Mobile-responsive website design** (optimized for desktop, tablet, and mobile devices)
- Customer CRUD operations (create, read, update, soft delete) for office staff and admin
- **Scheme enrollment for customers** (office staff enrolls customers in schemes via website)
- Route management (create, read, update, deactivate routes)
- Customer-to-staff assignment (individual and bulk by route)
- Transaction viewing and filtering with export to CSV/Excel
- Manual payment entry for office collections
- Financial dashboard for administrators (inflow/outflow tracking, net cash flow)
- Staff management (CRUD operations, target setting, performance tracking)
- Scheme management (view, edit, enable/disable)
- **Daily market price API integration** (automated fetch from external API for gold/silver rates)
- Basic reporting (daily, weekly, monthly, staff performance, customer payment, scheme performance)
- Report export to PDF and Excel formats
- Real-time transaction monitoring
- Role-based access control (office staff vs admin)
- **System administration UI for system and database management**
- **Automated email/SMS notifications** (payment reminders, withdrawal status updates, OTP delivery, system alerts)

**Mobile App Features:**
- Customer authentication (OTP, PIN, biometric)
- Collection staff authentication (staff code/password, PIN)
- Customer dashboard with investment overview
- **Scheme browsing and viewing** (view available schemes and own enrollment status - enrollment via website only)
- Payment schedule and transaction history
- Investment portfolio tracking (gold/silver grams, current value)
- Withdrawal requests and status tracking
- Market rates viewing (rates fetched from external API)
- Collection staff dashboard with target tracking
- Assigned customer list with search and filters
- Payment collection recording (offline-capable)
- Customer detail viewing for collection staff
- Today's target tracking for collection staff
- Basic reports for collection staff
- Offline data caching and synchronization
- Push notifications for important updates
- Cross-platform deployment (iOS and Android)

**Shared/Backend Features:**
- Supabase backend (PostgreSQL database, authentication, Row Level Security)
- Real-time data synchronization
- Audit trail for payments (append-only payment records)
- Secure authentication and session management
- Data encryption in transit and at rest
- Role-based permissions enforced at database level (RLS)

### Explicit OUT OF SCOPE (PHASE 1)

**Website Features:**
- Customer self-service portal on website (customers use mobile app only for self-service)
- Payment gateway integration on website (payments collected via mobile app or manual entry)
- Advanced analytics, machine learning, or predictive modeling (deferred to later phase)
- Third-party integrations beyond Supabase (no external CRM, accounting software, etc.)
- Custom report builder (predefined reports only)
- Bulk data import/export beyond basic CSV/Excel export of transactions and reports
- Multi-language support (English only in Phase 1)

**Mobile App Features:**
- Office staff mobile app (office staff use website only)
- Admin mobile app (admins use website only)
- Customer-to-staff assignment on mobile (assignment done on website only)
- Route management on mobile (route management done on website only)
- Scheme creation/editing on mobile (scheme management done on website only)
- Market rate updates on mobile (rate updates done on website only)
- Comprehensive financial reporting on mobile (reports available on website only)
- Multi-language support (English only in Phase 1)
- Dark mode/theme customization (standard theme only)
- Social media integration or sharing features
- In-app chat or messaging between users
- Customer-to-customer interactions or community features
- Push notifications for marketing or promotional content
- Location tracking or GPS features
- Camera integration for document scanning (future enhancement)
- Biometric payment authorization (PIN only for authentication)

**Shared/Backend Features:**
- Edge Functions or serverless functions (using Supabase RPC functions only)
- Scheduled jobs or cron tasks (handled externally if needed for market price API fetch)
- Webhook integrations with external services (beyond market price API)
- Third-party payment gateway integration (payments recorded manually or via mobile app)
- File storage beyond Supabase Storage (if document uploads needed, use Supabase Storage)
- Data archival or automated data purging (data retention policy TBD)
- Backup and disaster recovery automation (handled by Supabase)
- Custom authentication providers beyond Supabase Auth
- Single Sign-On (SSO) integration
- API access for third-party integrations (no public API in Phase 1)

---

## 2.5. Website Responsibility Boundary

### Purpose

This section establishes clear boundaries between the **Website**, **Mobile App**, and **Backend/Database** layers, defining the website as the authoritative control plane for operations and governance. These boundaries ensure that decision-making authority, data creation, and operational control remain centralized in the website interface, while the mobile app serves as a consumption and execution layer.

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

## 2.6. Public Website Scope (Marketing & Trust Layer)

### Purpose

This section clarifies that the public-facing website (marketing pages) is part of the same system but is logically isolated from core operational functionality. The public website serves as a marketing and trust-building layer, not an operational interface.

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

---

## 3. USER ROLES & PERMISSIONS

| User Role | Description | Authentication Method | Key Permissions | Restrictions | Data Access |
|-----------|-------------|----------------------|-----------------|--------------|-------------|
| **Customer** | Individual investors enrolled in gold/silver investment schemes. Use mobile app for self-service account management, payment tracking, and withdrawal requests. **CANNOT enroll themselves in schemes** - enrollment performed only by office staff via website. | Phone number + OTP verification (SMS), then 6-digit PIN setup/login. Optional biometric authentication (Face ID, Touch ID, Fingerprint) for quick login after initial PIN setup. | View own investment portfolio (gold/silver grams, current value), view own scheme enrollment status (read-only), view payment schedule and transaction history, request withdrawals (partial or full), view market rates, update personal profile information (name, address, nominee details). | **CANNOT enroll in schemes** (enrollment performed only by office staff), cannot record payments (payments recorded by collection staff), cannot view other customers' data, cannot access staff or admin features, cannot modify payment records (payments are append-only), cannot access website features. | Own profile data (`profiles` table where `user_id = auth.uid()`), own customer record (`customers` table where `profile_id` matches), own scheme enrollments (`user_schemes` table where `customer_id` matches - read-only), own payments (`payments` table where `customer_id` matches), own withdrawals (`withdrawals` table where `customer_id` matches), all active schemes (read-only, `schemes` table where `active = true`), current market rates (read-only, `market_rates` table). |
| **Collection Staff** | Field agents who collect payments from customers in assigned geographic areas. Use mobile app for field collection, customer management, and performance tracking. Must have `staff_type='collection'` in `staff_metadata` table. | Staff code (format: SLG001, SLG002, etc.) + password via Supabase Auth email/password, then 6-digit PIN setup/login. Staff code is resolved to email via RPC function `get_staff_email_by_code()`, then standard Supabase Auth sign-in. | View assigned customers list (filtered by `staff_assignments` where `staff_id` matches and `is_active = true`), record payment collections for assigned customers (INSERT into `payments` table), view assigned customers' payment history, view own performance metrics and daily targets, view own profile and account information. | Cannot access customers not assigned to them (enforced by RLS), cannot modify payment records after creation (payments are append-only, UPDATE/DELETE blocked by database triggers), cannot create or edit customer records, cannot manage routes or assignments, cannot access office staff or admin features, cannot view system-wide financial data, cannot access website features, office staff (`staff_type='office'`) are explicitly blocked from mobile app access (enforced by `checkMobileAppAccess()` function). | Own profile data (`profiles` table where `user_id = auth.uid()`), own staff metadata (`staff_metadata` table where `profile_id` matches), assigned customers (`customers` table where `id` IN (SELECT `customer_id` FROM `staff_assignments` WHERE `staff_id` = current_profile_id AND `is_active = true`)), assigned customers' profiles (`profiles` table via RLS policy "Staff can read assigned customer profiles"), assigned customers' payments (`payments` table where `customer_id` IN assigned customers AND `staff_id` matches), own staff assignments (`staff_assignments` table where `staff_id` matches), all schemes (read-only, `schemes` table), current market rates (read-only, `market_rates` table). |
| **Office Staff** | Administrative personnel managing customer enrollment, **scheme enrollment for customers**, route management, customer-to-staff assignments, and transaction monitoring from desktop workstations. Must have `staff_type='office'` in `staff_metadata` table and `role='staff'` in `profiles` table. | Email address + password via Supabase Auth (standard email/password authentication). Session managed by Supabase Auth SDK with automatic token refresh. | Create new customer records with full KYC details (INSERT into `customers` and `profiles` tables), **enroll customers in investment schemes** (INSERT into `user_schemes` table - select scheme, set payment frequency, amount range, start date), read all customers (SELECT from `customers` table, no RLS restriction for staff), update customer information (UPDATE `customers` table), create and manage routes (CRUD on `routes` table, if implemented), assign customers to collection staff based on routes (INSERT/UPDATE `staff_assignments` table), view all transactions (SELECT from `payments` and `withdrawals` tables), enter manual payments for office collections (INSERT into `payments` table with `staff_id = NULL`), export transaction data to CSV/Excel, view transaction monitoring dashboard. | Cannot access mobile app (blocked by `checkMobileAppAccess()` function which requires `staff_type='collection'`), cannot access financial dashboards or comprehensive reports (basic reports only, advanced analytics admin-only), cannot manage staff accounts (admin-only), cannot modify schemes (admin-only), cannot update market rates (rates fetched from external API), cannot view system-wide financial analytics (admin-only), cannot access admin-only reports or advanced analytics, cannot modify payment records after creation (payments are append-only). | All customer records (`customers` table, read access via RLS policy "Staff can read assigned customers" - office staff can read all due to `is_staff()` check), all customer profiles (`profiles` table via staff RLS policy), **all user_schemes records (can create for any customer, can read all via staff RLS policy)**, all routes (`routes` table, if implemented), all staff assignments (`staff_assignments` table, read access), all payments (`payments` table, read access), all withdrawals (`withdrawals` table, read access), all schemes (read-only, `schemes` table), current market rates (read-only, `market_rates` table - fetched from external API), own profile and staff metadata (own records only). |
| **Administrator** | Management and financial oversight personnel with complete system access. Require comprehensive financial visibility, staff management, scheme management, and system configuration capabilities. Must have `role='admin'` in `profiles` table. | Email address + password via Supabase Auth (standard email/password authentication). Session managed by Supabase Auth SDK with automatic token refresh. | All office staff permissions (customer management, scheme enrollment, routes, assignments, transactions), complete financial dashboard access (inflow/outflow tracking, net cash flow analysis), staff management (CREATE, READ, UPDATE, DELETE staff accounts via `profiles` and `staff_metadata` tables), scheme management (UPDATE `schemes` table, enable/disable schemes), **market rates management** (view rates fetched from external API, manual override/correction if needed), **basic reports and analytics** (all report types with export capabilities - advanced analytics deferred to later phase), **system administration UI access** (database management, system monitoring, audit logs), export financial data in multiple formats (CSV, Excel, PDF). | Cannot modify payment records after creation (payments are append-only for audit compliance, UPDATE/DELETE prevented by database triggers), cannot delete historical transaction data (data retention policy), cannot bypass Row Level Security (RLS) policies (enforced at database level), cannot access mobile app (admins use website only), cannot modify core database schema or RLS policies (database administration is separate from application access), **cannot access advanced analytics or ML features** (deferred to later phase). | All data across all tables (full access via RLS policies with `is_admin()` checks): all profiles, all customers, all staff metadata, all schemes, all user_schemes, all payments, all withdrawals, all market rates, all staff assignments, all routes (if implemented). Admin RLS policies use `is_admin()` function which checks `get_user_role() = 'admin'` from `profiles` table. |

### Authentication Rules

**Authentication Provider:** Supabase Auth (managed authentication service)

**Customer Authentication (Mobile App):**
- **Primary Method:** Phone number + OTP verification via SMS
  - User enters 10-digit phone number (formatted as +91XXXXXXXXXX)
  - System sends OTP via Supabase Auth SMS service
  - User enters 6-digit OTP code
  - OTP verified via `Supabase.instance.client.auth.signInWithOtp()`
- **Secondary Method:** 6-digit PIN (required after first OTP login)
  - PIN stored securely using Flutter Secure Storage (encrypted local storage)
  - PIN is 6 digits, numeric only
  - PIN required for subsequent logins after initial OTP verification
  - PIN can be reset via OTP verification flow
- **Optional Method:** Biometric authentication (Face ID, Touch ID, Fingerprint)
  - Available after PIN setup
  - Uses device-native biometric APIs
  - Biometric data stored in device secure enclave (not transmitted to server)
  - Falls back to PIN if biometric fails or unavailable
- **Session Management:**
  - Session token managed by Supabase Auth SDK
  - Access token expiration: 1 hour (default Supabase setting)
  - Refresh token expiration: 30 days (default Supabase setting)
  - Automatic token refresh on app resume
  - Session persists across app restarts (cached by Supabase SDK)

**Collection Staff Authentication (Mobile App):**
- **Primary Method:** Staff code + password
  - Staff enters staff code (format: SLG001, SLG002, etc.)
  - System resolves staff code to email via RPC function `get_staff_email_by_code()`
  - Staff enters password associated with email
  - Authentication via `Supabase.instance.client.auth.signInWithPassword(email, password)`
- **Secondary Method:** 6-digit PIN (required after first password login)
  - Same PIN requirements as customers (6 digits, stored securely)
  - PIN required for subsequent logins
- **Access Control:**
  - Must have `role='staff'` in `profiles` table
  - Must have `staff_type='collection'` in `staff_metadata` table
  - Access validated by `checkMobileAppAccess()` function on login
  - Office staff (`staff_type='office'`) are explicitly blocked from mobile app
- **Session Management:**
  - Same session management as customers (Supabase Auth SDK)
  - Session validated on each app start

**Office Staff Authentication (Website):**
- **Method:** Email address + password
  - Standard Supabase Auth email/password authentication
  - Email must be associated with a profile where `role='staff'` and `staff_type='office'`
  - Password requirements: Minimum 8 characters (enforced by Supabase Auth)
- **Session Management:**
  - Session managed by Supabase Auth SDK (server-side for website)
  - Access token expiration: 1 hour
  - Refresh token expiration: 30 days
  - Session stored in HTTP-only cookies (secure, not accessible via JavaScript)

**Administrator Authentication (Website):**
- **Method:** Email address + password
  - Standard Supabase Auth email/password authentication
  - Email must be associated with a profile where `role='admin'`
  - Password requirements: Minimum 8 characters (enforced by Supabase Auth)
- **Session Management:**
  - Same session management as office staff (Supabase Auth SDK, HTTP-only cookies)

**Multi-Factor Authentication (MFA):**
- **Status:** Not supported in Phase 1
- **Future Consideration:** Optional MFA for administrators (TOTP-based) may be added in future phases

**Password Policy:**
- **Minimum Length:** 8 characters (enforced by Supabase Auth)
- **Complexity Requirements:** No explicit complexity requirements (Supabase Auth default)
- **Expiration Policy:** No password expiration (passwords do not expire)
- **Reset Mechanism:** Password reset via email link (Supabase Auth built-in feature)
- **Password Storage:** Passwords hashed using bcrypt (handled by Supabase Auth, not accessible to application)

**Session Security:**
- All sessions use HTTPS (TLS 1.2+)
- Access tokens are JWT tokens signed by Supabase
- Refresh tokens stored securely (mobile: device secure storage, website: HTTP-only cookies)
- Session invalidation on logout (tokens revoked)
- Automatic session timeout: 30 days of inactivity (refresh token expiration)

### Authorization Rules

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

**Authorization Enforcement:**
- **Database Level:** Row Level Security (RLS) policies enforced on all tables in PostgreSQL
- **Application Level:** Role checks in application code before displaying UI elements
- **API Level:** All API requests validated against RLS policies (Supabase enforces RLS on all queries)

**Role Resolution:**
- User role determined by `profiles.role` column (enum: 'customer', 'staff', 'admin')
- Staff type determined by `staff_metadata.staff_type` column (enum: 'collection', 'office')
- Role resolution via helper functions: `get_user_role()`, `is_admin()`, `is_staff()`
- Role checked on every authenticated request via RLS policies

**Permission Granularity:**
- **Table-Level:** RLS policies control SELECT, INSERT, UPDATE, DELETE per table
- **Row-Level:** RLS policies filter rows based on user role and relationships (e.g., staff can only see assigned customers)
- **Column-Level:** Not explicitly restricted (all columns accessible if row access granted)
- **Action-Level:** Some actions restricted by application logic (e.g., payment UPDATE/DELETE blocked by triggers, not just RLS)

**Special Authorization Rules:**
1. **Payment Immutability:** Payments are append-only. UPDATE and DELETE operations blocked by database triggers regardless of role (audit compliance requirement).
2. **Staff Assignment Authority:** Only administrators can create/update `staff_assignments` records (enforced by RLS policy "Admin can manage staff assignments").
3. **Scheme Management:** Only administrators can UPDATE schemes (enforced by RLS policy "Admin can manage schemes").
4. **Market Rates Management:** Only administrators can INSERT/UPDATE market rates (enforced by RLS policy "Admin can manage market rates").
5. **Mobile App Access Control:** Collection staff (`staff_type='collection'`) can access mobile app. Office staff (`staff_type='office'`) and administrators are blocked from mobile app (enforced by `checkMobileAppAccess()` function).
6. **Staff Code Lookup:** Unauthenticated users can query `staff_metadata` table for staff code to email resolution only (limited SELECT policy for login flow, no sensitive data exposed).

**Cross-Role Data Access:**
- **Staff → Customer Data:** Staff can only access customers assigned to them via `staff_assignments` table (enforced by RLS policy "Staff can read assigned customers").
- **Customer → Staff Data:** Customers cannot access any staff data (no RLS policies grant customer access to staff tables).
- **Office Staff → Collection Staff Data:** Office staff can read collection staff metadata for assignment purposes (via staff RLS policies).
- **Admin → All Data:** Administrators can access all data via `is_admin()` RLS policy checks.

**Permission Escalation Prevention:**
- RLS policies use SECURITY DEFINER functions to prevent privilege escalation
- Application code does not bypass RLS (all queries go through Supabase client which enforces RLS)
- Database triggers enforce business rules regardless of role (e.g., payment immutability)
- No direct database access allowed (all access via Supabase API with RLS enforcement)

---

## 4. FUNCTIONAL REQUIREMENTS

### Core User Journeys

#### Core User Journey 1: Customer First-Time Login and Account Setup

**Actors:** Customer (first-time user, not previously registered)

**Preconditions:**
- Customer has a valid mobile phone number (10 digits, Indian format)
- Customer has not previously registered in the system
- Mobile app is installed and launched
- Device has internet connectivity
- Device supports SMS reception for OTP

**Steps:**
1. **User Action:** Customer launches mobile app
   - **System Response:** App displays `LoginScreen` with phone number input field and "Get OTP" button

2. **User Action:** Customer enters 10-digit phone number (e.g., "9876543210")
   - **System Response:** App validates phone number format (10 digits, numeric only)
   - **System Response:** If invalid format, displays error message "Please enter a valid 10-digit phone number"
   - **System Response:** If valid, formats phone number as "+91XXXXXXXXXX" and enables "Get OTP" button

3. **User Action:** Customer taps "Get OTP" button
   - **System Response:** App calls `AuthService.sendOTP(phone: formattedPhone)`
   - **System Response:** App displays loading indicator
   - **System Response:** Supabase Auth sends OTP via SMS to customer's phone number
   - **System Response:** App navigates to `OTPScreen` with phone number pre-filled

4. **User Action:** Customer receives OTP via SMS and enters 6-digit OTP code
   - **System Response:** App validates OTP format (6 digits, numeric only)
   - **System Response:** If invalid format, displays error message "Please enter a valid 6-digit OTP"

5. **User Action:** Customer taps "Verify OTP" button
   - **System Response:** App calls `AuthService.verifyOTP(phone, token)`
   - **System Response:** App displays loading indicator
   - **System Response:** Supabase Auth verifies OTP token
   - **System Response:** If OTP invalid or expired, displays error message "Invalid or expired OTP. Please request a new OTP" with "Resend OTP" button
   - **System Response:** If OTP valid, Supabase Auth creates session in `auth.users` table

6. **System Action:** `onAuthStateChange` listener detects `signedIn` event
   - **System Response:** App calls `RoleRoutingService.checkMobileAppAccess()`
   - **System Response:** App queries `profiles` table to verify customer role and active status
   - **System Response:** If profile not found or inactive, app calls `signOut()` and displays error message "Account not found. Please contact support."
   - **System Response:** If profile found and active, app sets authentication state to `authenticated`

7. **System Action:** App checks if PIN is set for this phone number
   - **System Response:** App calls `SecureStorageHelper.isPinSet(phoneNumber)`
   - **System Response:** If PIN not set, app transitions to `otpVerifiedNeedsPin` state

8. **System Action:** App displays `PinSetupScreen`
   - **System Response:** Screen shows instruction "Set up a 6-digit PIN for quick login" and PIN input fields (6 digits)

9. **User Action:** Customer enters 6-digit PIN (e.g., "123456")
   - **System Response:** App validates PIN format (exactly 6 digits, numeric only)
   - **System Response:** If invalid format, displays error message "PIN must be exactly 6 digits"

10. **User Action:** Customer confirms PIN by entering it again
    - **System Response:** App validates both PIN entries match
    - **System Response:** If PINs do not match, displays error message "PINs do not match. Please try again."

11. **User Action:** Customer taps "Set PIN" button
    - **System Response:** App stores PIN securely using Flutter Secure Storage (encrypted local storage)
    - **System Response:** App saves phone number to secure storage for future logins
    - **System Response:** App sets authentication state to `authenticated`

12. **System Action:** App fetches customer role from `profiles` table
    - **System Response:** App queries `profiles.select('id, role').eq('user_id', userId).maybeSingle()`
    - **System Response:** If role is 'customer', app creates `DashboardScreen` widget

13. **System Action:** App displays Customer Dashboard
    - **System Response:** Dashboard loads customer data (schemes, investments, market rates) from Supabase
    - **System Response:** Dashboard displays investment overview, active schemes, and quick access buttons

**Success Criteria:**
- Customer successfully receives OTP via SMS
- OTP verification completes successfully
- PIN is stored securely in device secure storage (not in plain text)
- Customer is authenticated and session is created in Supabase Auth
- Customer profile is found in database with role='customer' and active=true
- Customer Dashboard displays with customer's investment data loaded from database
- No mock data is displayed (all data from Supabase)

**Error States:**
- **Invalid phone number format:** App displays error message, prevents OTP request, user can correct phone number
- **OTP send failure (network error):** App displays error message "Failed to send OTP. Please check your internet connection and try again." with "Retry" button
- **OTP send failure (invalid phone):** App displays error message "Unable to send OTP to this number. Please verify your phone number." with option to edit phone number
- **OTP verification failure (invalid code):** App displays error message "Invalid or expired OTP. Please request a new OTP" with "Resend OTP" button (maximum 3 retries)
- **OTP verification failure (expired code):** App displays error message "OTP has expired. Please request a new OTP" with "Resend OTP" button
- **Network failure during OTP verification:** App displays error message "Network error. Please check your internet connection and try again." with "Retry" button
- **Profile not found in database:** App calls `signOut()`, displays error message "Account not found. Please contact support." and returns to LoginScreen
- **Profile inactive:** App calls `signOut()`, displays error message "Your account has been deactivated. Please contact support." and returns to LoginScreen
- **PIN setup failure (storage error):** App displays error message "Failed to save PIN. Please try again." and allows retry
- **Role fetch failure (network error):** App displays error message "Failed to load account information. Please try again." with "Retry" button
- **Role fetch failure (not customer):** App calls `signOut()`, displays error message "Access denied. This account is not authorized for customer access." and returns to LoginScreen

---

#### Core User Journey 2: Customer Returning Login (With PIN)

**Actors:** Customer (returning user, PIN already set)

**Preconditions:**
- Customer has previously completed first-time login and PIN setup
- Customer's phone number is saved in device secure storage
- Customer's PIN is stored in device secure storage
- Mobile app is installed and launched
- Device has internet connectivity (for initial session validation)

**Steps:**
1. **User Action:** Customer launches mobile app
   - **System Response:** App displays `LoginScreen` with phone number auto-filled from secure storage (if available)

2. **User Action:** Customer taps "Continue with PIN" button (or enters phone number if not auto-filled)
   - **System Response:** App navigates to `PinLoginScreen`

3. **User Action:** Customer enters 6-digit PIN
   - **System Response:** App validates PIN format (6 digits, numeric only)
   - **System Response:** If invalid format, displays error message "Please enter a valid 6-digit PIN"

4. **User Action:** Customer taps "Login" button
   - **System Response:** App retrieves stored PIN from secure storage
   - **System Response:** App compares entered PIN with stored PIN
   - **System Response:** If PIN does not match, displays error message "Incorrect PIN. Please try again." and increments failed attempt counter
   - **System Response:** If failed attempts >= 3, displays error message "Too many failed attempts. Please use OTP login." and disables PIN login, shows "Login with OTP" button

5. **System Action:** If PIN matches, app checks for existing Supabase session
   - **System Response:** App calls `Supabase.instance.client.auth.currentSession`
   - **System Response:** If session exists and valid, proceeds to step 7
   - **System Response:** If session expired or missing, proceeds to step 6

6. **System Action:** App validates session with Supabase (if session exists)
   - **System Response:** App calls `RoleRoutingService.checkMobileAppAccess()`
   - **System Response:** App queries `profiles` table to verify customer role and active status
   - **System Response:** If profile not found or inactive, app calls `signOut()`, displays error message, and returns to LoginScreen

7. **System Action:** App fetches customer role from `profiles` table
   - **System Response:** App queries `profiles.select('id, role').eq('user_id', userId).maybeSingle()`
   - **System Response:** If role is 'customer', app creates `DashboardScreen` widget

8. **System Action:** App displays Customer Dashboard
   - **System Response:** Dashboard loads customer data from Supabase
   - **System Response:** Dashboard displays investment overview and active schemes

**Success Criteria:**
- Customer successfully enters correct PIN
- Existing Supabase session is validated or new session is created
- Customer profile is verified as active customer
- Customer Dashboard displays with customer's investment data
- Login completes in under 5 seconds (excluding data loading)

**Error States:**
- **PIN not set (edge case):** App detects PIN not in storage, displays message "PIN not found. Please login with OTP." and navigates to OTP screen
- **Incorrect PIN (1-2 attempts):** App displays error message "Incorrect PIN. Please try again." and allows retry
- **Incorrect PIN (3+ attempts):** App displays error message "Too many failed attempts. Please use OTP login." and disables PIN login, shows "Login with OTP" button
- **Session expired:** App automatically attempts to refresh session, if refresh fails, displays message "Session expired. Please login again." and navigates to LoginScreen
- **Profile not found:** App calls `signOut()`, displays error message "Account not found. Please contact support." and returns to LoginScreen
- **Profile inactive:** App calls `signOut()`, displays error message "Your account has been deactivated. Please contact support." and returns to LoginScreen
- **Network failure during session validation:** App displays error message "Network error. Please check your internet connection and try again." with "Retry" button

---

#### Office Staff Flow 4: Enroll Customer in Scheme

**Actors:** Office Staff

**Preconditions:**
- Office staff is authenticated and logged into website
- Customer record exists in `customers` table
- At least one active scheme exists in `schemes` table with `active = true`
- Customer has not exceeded maximum active scheme enrollments (if business rule exists)
- Device has internet connectivity

**Steps:**
1. **User Action:** Office staff navigates to customer profile page `/office/customers/[id]`
   - **System Response:** App displays customer profile with customer information, active schemes list, payment history
   - **System Response:** App queries `user_schemes` table: `user_schemes.select('*, schemes(*)').eq('customer_id', customerId).eq('status', 'active')`
   - **System Response:** App displays active enrollments list (if any)

2. **User Action:** Office staff taps "Enroll in Scheme" button on customer profile page
   - **System Response:** App navigates to enrollment form page `/office/customers/[id]/enroll`
   - **System Response:** App queries `schemes` table: `schemes.select('*').eq('active', true).order('name')`
   - **System Response:** App displays schemes dropdown with available schemes (grouped by asset type: Gold, Silver)

3. **User Action:** Office staff selects a scheme from dropdown (required)
   - **System Response:** App displays scheme details: scheme name, description, asset type, minimum amount, maximum amount, available payment frequencies
   - **System Response:** App pre-fills enrollment form fields with scheme defaults

4. **User Action:** Office staff selects payment frequency (required): daily, weekly, or monthly
   - **System Response:** App validates selection and enables amount fields

5. **User Action:** Office staff enters minimum amount (required)
   - **System Response:** App validates amount is numeric and within scheme's min/max range
   - **System Response:** If amount < scheme minimum, displays error message "Minimum amount is ₹[scheme_min]. Please enter a valid amount."
   - **System Response:** If amount > scheme maximum, displays error message "Maximum amount is ₹[scheme_max]. Please enter a valid amount."

6. **User Action:** Office staff enters maximum amount (required)
   - **System Response:** App validates amount is numeric and within scheme's min/max range
   - **System Response:** App validates maximum amount >= minimum amount
   - **System Response:** If maximum < minimum, displays error message "Maximum amount must be greater than or equal to minimum amount."

7. **User Action:** Office staff selects start date (required, defaults to today)
   - **System Response:** App validates date is not in the past
   - **System Response:** If date is in the past, displays error message "Start date cannot be in the past."

8. **User Action:** Office staff reviews enrollment details and taps "Confirm Enrollment" button
   - **System Response:** App displays confirmation dialog: "Enroll [Customer Name] in [Scheme Name]? Payment frequency: [frequency], Amount range: ₹[min] - ₹[max], Start date: [date]"
   - **System Response:** Office staff can tap "Cancel" to return to form or "Confirm" to proceed

9. **User Action:** Office staff taps "Confirm" in confirmation dialog
   - **System Response:** App displays loading indicator "Enrolling customer in scheme..."
   - **System Response:** App calculates maturity date based on scheme type and start date
   - **System Response:** App inserts record into `user_schemes` table with fields: `customer_id` (selected customer), `scheme_id` (selected scheme), `enrollment_date` (today), `start_date` (selected date), `maturity_date` (calculated), `payment_frequency` (selected), `min_amount` (entered), `max_amount` (entered), `due_amount` (initialized to min_amount), `status` ('active')

10. **System Action:** Database trigger `update_user_scheme_totals` executes (if applicable)
    - **System Response:** Trigger updates scheme totals and statistics

11. **System Response:** If enrollment successful, app displays success message "Successfully enrolled [Customer Name] in [Scheme Name]!" and navigates back to customer profile page
    - **System Response:** Customer profile page refreshes to show new enrollment in active schemes list
    - **System Response:** Customer receives notification (SMS/email) about enrollment (if automated notifications implemented)

12. **System Response:** If enrollment fails, app displays error message based on failure type (see Error States)

**Success Criteria:**
- Office staff successfully selects customer and scheme
- Enrollment form is completed with valid data
- Enrollment record is created in `user_schemes` table with correct data
- Customer profile reflects new enrollment
- Enrollment completes within 10 seconds (excluding network latency)
- Customer is notified of enrollment (if notifications implemented)

**Error States:**
- **Customer not found:** App displays error message "Customer not found. Please verify customer ID." and redirects to customer list
- **No active schemes available:** App displays message "No schemes available at this time. Please activate a scheme first." and prevents enrollment
- **Network failure during scheme load:** App displays error message "Failed to load schemes. Please check your internet connection." with "Retry" button
- **Invalid amount entered:** App displays specific error message based on validation failure (minimum, maximum, or range validation)
- **Database constraint violation (duplicate enrollment):** App displays error message "Customer is already enrolled in this scheme." and prevents duplicate enrollment
- **Database constraint violation (maximum enrollments exceeded):** App displays error message "Customer has reached maximum number of active enrollments. Please complete or cancel an existing enrollment." (if business rule exists)
- **Enrollment INSERT failure (RLS violation):** App displays error message "You do not have permission to create enrollments. Please contact administrator." (should not occur for office staff, but handled defensively)
- **Enrollment INSERT failure (network error):** App displays error message "Failed to enroll customer. Please check your internet connection and try again." with "Retry" button
- **Enrollment INSERT failure (database error):** App displays error message "An error occurred during enrollment. Please try again or contact support." with error code for support reference
- **Session expired during enrollment:** App detects expired session, redirects to login page with message "Session expired. Please login again."

---

#### Core User Journey 4: Customer View Payment Schedule and Transaction History

**Actors:** Customer (authenticated, enrolled in at least one scheme)

**Preconditions:**
- Customer is authenticated and logged into mobile app
- Customer has at least one active enrollment in `user_schemes` table
- Device has internet connectivity (for initial data load, then can work offline with cached data)

**Steps:**
1. **User Action:** Customer navigates to Payment Schedule screen (from Dashboard or navigation menu)
   - **System Response:** App displays `PaymentScheduleScreen` with calendar view
   - **System Response:** App queries `user_schemes` table: `user_schemes.select('*').eq('customer_id', customerId).eq('status', 'active')`
   - **System Response:** For each active enrollment, app calculates payment schedule based on `payment_frequency` (daily/weekly/monthly) and `start_date`
   - **System Response:** App queries `payments` table: `payments.select('*').eq('customer_id', customerId).order('payment_date', ascending: false)`
   - **System Response:** App displays calendar with due dates highlighted and payment status (paid/pending/missed) for each date

2. **User Action:** Customer views payment schedule for a specific month
   - **System Response:** App displays calendar for selected month
   - **System Response:** Due dates are marked with different colors: green (paid), yellow (pending), red (missed)
   - **System Response:** Customer can tap on a date to view payment details

3. **User Action:** Customer taps on a date with payment
   - **System Response:** App displays payment details: amount, payment method, receipt ID, gold/silver grams added, payment time (if available)

4. **User Action:** Customer navigates to Transaction History screen (from Dashboard or navigation menu)
   - **System Response:** App displays `TransactionHistoryScreen` with list of all transactions
   - **System Response:** App queries `payments` table: `payments.select('*').eq('customer_id', customerId).order('payment_date', ascending: false).limit(50)`
   - **System Response:** App displays transactions in reverse chronological order (newest first)
   - **System Response:** Each transaction shows: date, amount, payment method, receipt ID, scheme name (if applicable)

5. **User Action:** Customer taps on a transaction to view details
   - **System Response:** App navigates to `TransactionDetailScreen` with full transaction information
   - **System Response:** Screen displays: receipt ID, payment date, payment time, amount, payment method, scheme name, gold/silver grams added, gold/silver rate at time of payment, staff name (if collected by staff), notes (if any)

6. **User Action:** Customer can filter transactions by date range, scheme, or payment method
   - **System Response:** App applies filters and refreshes transaction list
   - **System Response:** App displays filtered results with count (e.g., "Showing 15 of 50 transactions")

**Success Criteria:**
- Customer successfully views payment schedule with all due dates
- Customer can see payment status (paid/pending/missed) for each due date
- Customer successfully views complete transaction history
- Transaction details display all relevant information
- Data loads within 5 seconds (initial load, subsequent loads from cache are faster)
- Offline mode works with cached data (if previously loaded)

**Error States:**
- **No active enrollments:** App displays message "You have no active schemes. Please enroll in a scheme to view payment schedule."
- **No transactions found:** App displays message "No transactions found." with option to view schemes
- **Network failure during data load:** App displays error message "Failed to load payment schedule. Please check your internet connection." with "Retry" button. If data was previously cached, app displays cached data with "Last updated: [timestamp]" indicator
- **Network failure during transaction history load:** App displays error message "Failed to load transaction history. Please check your internet connection." with "Retry" button. If data was previously cached, app displays cached data
- **Database query failure:** App displays error message "An error occurred while loading data. Please try again." with "Retry" button
- **Session expired:** App detects expired session, calls `signOut()`, displays message "Session expired. Please login again." and navigates to LoginScreen

---

#### Core User Journey 5: Customer Withdrawal Request

**Actors:** Customer (authenticated, has accumulated gold/silver in active schemes)

**Preconditions:**
- Customer is authenticated and logged into mobile app
- Customer has at least one active enrollment in `user_schemes` table
- Customer has accumulated gold/silver grams (`accumulated_metal_grams > 0` in `user_schemes` table)
- Device has internet connectivity

**Steps:**
1. **User Action:** Customer navigates to Withdrawal screen (from Dashboard or navigation menu)
   - **System Response:** App displays `WithdrawalScreen` with withdrawal request form
   - **System Response:** App queries `user_schemes` table: `user_schemes.select('id, scheme_id, accumulated_metal_grams, total_amount_paid, status').eq('customer_id', customerId).eq('status', 'active')`
   - **System Response:** App queries current market rates: `market_rates.select('*').order('rate_date', ascending: false).limit(1)`
   - **System Response:** App calculates total available gold/silver grams across all active schemes
   - **System Response:** App calculates current value based on market rates

2. **User Action:** Customer views available withdrawal amount
   - **System Response:** Screen displays: total gold grams available, total silver grams available, current gold rate, current silver rate, total current value in INR

3. **User Action:** Customer selects withdrawal type (Partial or Full)
   - **System Response:** If "Partial" selected, app shows input fields for gold grams and silver grams to withdraw
   - **System Response:** If "Full" selected, app pre-fills with all available grams

4. **User Action:** If partial withdrawal, customer enters gold grams to withdraw (e.g., "10.5")
   - **System Response:** App validates amount is numeric and positive
   - **System Response:** App validates amount <= available gold grams
   - **System Response:** If invalid, displays error message "Please enter a valid amount not exceeding [available] grams."

5. **User Action:** If partial withdrawal, customer enters silver grams to withdraw (e.g., "50.0")
   - **System Response:** App validates amount is numeric and positive
   - **System Response:** App validates amount <= available silver grams
   - **System Response:** If invalid, displays error message "Please enter a valid amount not exceeding [available] grams."

6. **User Action:** Customer reviews withdrawal details and taps "Request Withdrawal" button
   - **System Response:** App calculates withdrawal amount in INR based on current market rates
   - **System Response:** App displays confirmation dialog: "Request withdrawal of [gold]g gold and [silver]g silver? Estimated value: ₹[amount] (based on current rates). This request will be reviewed and processed."
   - **System Response:** Customer can tap "Cancel" to return to form or "Confirm" to proceed

7. **User Action:** Customer taps "Confirm" in confirmation dialog
   - **System Response:** App displays loading indicator "Submitting withdrawal request..."
   - **System Response:** App inserts record into `withdrawals` table with fields: `customer_id` (current customer), `user_scheme_id` (if withdrawal from specific scheme, else NULL for full withdrawal), `withdrawal_type` ('partial' or 'full'), `gold_grams` (requested gold grams), `silver_grams` (requested silver grams), `requested_amount` (calculated INR value), `status` ('pending'), `requested_date` (today), `gold_rate_at_request` (current gold rate), `silver_rate_at_request` (current silver rate)

8. **System Response:** If withdrawal request successful, app displays success message "Withdrawal request submitted successfully. Request ID: [withdrawal_id]. Your request will be reviewed and processed."
   - **System Response:** App navigates to Withdrawal List screen showing the new pending request

9. **System Response:** If withdrawal request fails, app displays error message based on failure type (see Error States)

**Success Criteria:**
- Customer successfully views available withdrawal amount
- Customer can select withdrawal type (partial or full)
- Customer can enter valid withdrawal amounts
- Withdrawal request is created in `withdrawals` table with status='pending'
- Customer receives confirmation with request ID
- Withdrawal request appears in withdrawal history

**Error States:**
- **No active enrollments:** App displays message "You have no active schemes. Please enroll in a scheme to request withdrawal."
- **No accumulated grams:** App displays message "You have no accumulated gold/silver to withdraw. Please make payments to accumulate grams."
- **Network failure during data load:** App displays error message "Failed to load withdrawal information. Please check your internet connection." with "Retry" button
- **Market rates not available:** App displays error message "Market rates are not available. Please try again later." and prevents withdrawal request submission
- **Invalid withdrawal amount:** App displays specific error message based on validation failure (exceeds available, negative, non-numeric)
- **Withdrawal INSERT failure (network error):** App displays error message "Failed to submit withdrawal request. Please check your internet connection and try again." with "Retry" button
- **Withdrawal INSERT failure (database error):** App displays error message "An error occurred while submitting withdrawal request. Please try again or contact support." with error code for support reference
- **Session expired:** App detects expired session, calls `signOut()`, displays message "Session expired. Please login again." and navigates to LoginScreen
- **Concurrent withdrawal request (duplicate):** App displays error message "A withdrawal request is already pending. Please wait for it to be processed." (if business rule prevents multiple pending requests)

---

#### Core User Journey 6: Customer View Investment Portfolio and Market Rates

**Actors:** Customer (authenticated, enrolled in schemes)

**Preconditions:**
- Customer is authenticated and logged into mobile app
- Customer has at least one enrollment in `user_schemes` table (active or completed)
- Device has internet connectivity (for market rates, portfolio can use cached data)

**Steps:**
1. **User Action:** Customer navigates to Total Investment screen (from Dashboard or navigation menu)
   - **System Response:** App displays `TotalInvestmentScreen` with investment summary
   - **System Response:** App queries `user_schemes` table: `user_schemes.select('total_amount_paid, accumulated_metal_grams, scheme_id').eq('customer_id', customerId)`
   - **System Response:** App queries `schemes` table to get asset types for each scheme
   - **System Response:** App aggregates: total amount paid across all schemes, total gold grams accumulated, total silver grams accumulated
   - **System Response:** App queries current market rates: `market_rates.select('*').order('rate_date', ascending: false).limit(1)`
   - **System Response:** App calculates current portfolio value: (gold_grams * current_gold_rate) + (silver_grams * current_silver_rate)
   - **System Response:** Screen displays: total amount invested, total gold grams, total silver grams, current gold rate, current silver rate, current portfolio value, profit/loss (if applicable)

2. **User Action:** Customer taps on "Gold Assets" card
   - **System Response:** App navigates to `GoldAssetDetailScreen`
   - **System Response:** App queries `user_schemes` table filtered for gold schemes: joins with `schemes` table where `asset_type = 'gold'`
   - **System Response:** Screen displays: total gold grams, current gold rate per gram, current total value, breakdown by scheme (scheme name, grams in each scheme, value per scheme)

3. **User Action:** Customer taps on "Silver Assets" card
   - **System Response:** App navigates to `SilverAssetDetailScreen`
   - **System Response:** App queries `user_schemes` table filtered for silver schemes: joins with `schemes` table where `asset_type = 'silver'`
   - **System Response:** Screen displays: total silver grams, current silver rate per gram, current total value, breakdown by scheme (scheme name, grams in each scheme, value per scheme)

4. **User Action:** Customer navigates to Market Rates screen (from Dashboard or navigation menu)
   - **System Response:** App displays `MarketRatesScreen` with current rates
   - **System Response:** App queries `market_rates` table: `market_rates.select('*').order('rate_date', ascending: false).limit(1)`
   - **System Response:** Screen displays: current gold rate per gram (INR), current silver rate per gram (INR), rate date, rate update time
   - **System Response:** Screen shows rate change indicator (up/down arrow) if previous rate available for comparison

5. **User Action:** Customer can refresh market rates (pull-to-refresh or refresh button)
   - **System Response:** App queries latest market rates from database
   - **System Response:** App updates displayed rates and timestamp
   - **System Response:** App shows "Last updated: [timestamp]" indicator

**Success Criteria:**
- Customer successfully views total investment summary with accurate calculations
- Customer can view gold and silver asset breakdowns
- Customer can view current market rates
- Portfolio value calculations are accurate based on current rates
- Data loads within 5 seconds (initial load)
- Market rates refresh successfully

**Error States:**
- **No enrollments found:** App displays message "You have no investment records. Please enroll in a scheme to start investing."
- **Network failure during portfolio load:** App displays error message "Failed to load investment portfolio. Please check your internet connection." with "Retry" button. If data was previously cached, app displays cached data with "Last updated: [timestamp]" indicator
- **Network failure during market rates load:** App displays error message "Failed to load market rates. Please check your internet connection." with "Retry" button. If rates were previously cached, app displays cached rates with "Last updated: [timestamp]" indicator
- **Market rates not available:** App displays message "Market rates are not available. Please try again later." and shows last known rates (if cached) or placeholder "Rate unavailable"
- **Database query failure:** App displays error message "An error occurred while loading data. Please try again." with "Retry" button
- **Calculation error (division by zero, null values):** App handles gracefully, displays "Calculation unavailable" for affected fields, logs error for debugging
- **Session expired:** App detects expired session, calls `signOut()`, displays message "Session expired. Please login again." and navigates to LoginScreen

---

#### Core User Journey 7: Customer Profile Management

**Actors:** Customer (authenticated)

**Preconditions:**
- Customer is authenticated and logged into mobile app
- Device has internet connectivity

**Steps:**
1. **User Action:** Customer navigates to Profile screen (from Dashboard or navigation menu)
   - **System Response:** App displays `ProfileScreen` with customer information
   - **System Response:** App queries `profiles` table: `profiles.select('name, phone').eq('user_id', userId).maybeSingle()`
   - **System Response:** App queries `customers` table: `customers.select('*').eq('profile_id', profileId).maybeSingle()`
   - **System Response:** Screen displays: customer name, phone number, address, nominee information (if available)

2. **User Action:** Customer taps "Edit Profile" button
   - **System Response:** App displays edit form with editable fields: name, address, nominee name, nominee relationship, nominee phone

3. **User Action:** Customer modifies profile information (e.g., updates address)
   - **System Response:** App validates input fields (name: required, non-empty; address: optional; nominee fields: optional)

4. **User Action:** Customer taps "Save" button
   - **System Response:** App displays loading indicator "Updating profile..."
   - **System Response:** App updates `profiles` table: `profiles.update({'name': newName}).eq('user_id', userId)`
   - **System Response:** App updates `customers` table: `customers.update({'address': newAddress, 'nominee_name': newNomineeName, ...}).eq('profile_id', profileId)`

5. **System Response:** If update successful, app displays success message "Profile updated successfully."
   - **System Response:** App refreshes profile screen with updated information

6. **User Action:** Customer navigates to Account Information screen (from Profile screen)
   - **System Response:** App displays `AccountInformationPage` with detailed account information
   - **System Response:** App queries `customers` table for KYC details: `customers.select('*').eq('profile_id', profileId).maybeSingle()`
   - **System Response:** Screen displays: customer ID, enrollment date, KYC status, nominee details, account status

**Success Criteria:**
- Customer successfully views profile information
- Customer can edit and update profile information
- Profile updates are saved to database
- Account information displays correctly
- Updates complete within 5 seconds

**Error States:**
- **Profile not found:** App displays error message "Profile not found. Please contact support." and logs error
- **Network failure during profile load:** App displays error message "Failed to load profile. Please check your internet connection." with "Retry" button
- **Invalid input validation:** App displays specific error message for invalid field (e.g., "Name is required.")
- **Profile UPDATE failure (network error):** App displays error message "Failed to update profile. Please check your internet connection and try again." with "Retry" button
- **Profile UPDATE failure (database error):** App displays error message "An error occurred while updating profile. Please try again or contact support." with error code
- **RLS policy violation (unauthorized update):** App displays error message "You do not have permission to update this information. Please contact support." (should not occur for own profile, but handled defensively)
- **Session expired:** App detects expired session, calls `signOut()`, displays message "Session expired. Please login again." and navigates to LoginScreen

---

### Admin / Staff Flows

#### Office Staff Flow 1: Create New Customer

**Actors:** Office Staff

**Preconditions:**
- Office staff is authenticated and logged into website
- Office staff has `role='staff'` and `staff_type='office'` in database
- Device has internet connectivity
- Office staff has necessary KYC information from customer

**Steps:**
1. **User Action:** Office staff navigates to `/office/customers/add` page
   - **System Response:** App displays customer registration form with fields: name, phone number, address, nominee name, nominee relationship, nominee phone, identity document upload (optional)

2. **User Action:** Office staff enters customer name (required field)
   - **System Response:** App validates name is non-empty and contains only letters/spaces
   - **System Response:** If invalid, displays error message "Name is required and must contain only letters and spaces"

3. **User Action:** Office staff enters 10-digit phone number (required field)
   - **System Response:** App validates phone number format (10 digits, numeric only)
   - **System Response:** App checks if phone number already exists in `profiles` table
   - **System Response:** If phone exists, displays error message "This phone number is already registered. Please use existing customer record."

4. **User Action:** Office staff enters customer address (required field)
   - **System Response:** App validates address is non-empty

5. **User Action:** Office staff enters nominee information (optional fields)
   - **System Response:** App validates nominee phone format if provided (10 digits)

6. **User Action:** Office staff uploads identity document (optional)
   - **System Response:** App validates file type (PDF, JPG, PNG) and size (max 5MB)
   - **System Response:** If invalid, displays error message "Invalid file type or size. Please upload PDF, JPG, or PNG file under 5MB."

7. **User Action:** Office staff reviews form and taps "Create Customer" button
   - **System Response:** App displays loading indicator "Creating customer account..."
   - **System Response:** App creates Supabase Auth user via `Supabase.instance.client.auth.admin.createUser()` with email (derived from phone) and phone number
   - **System Response:** App inserts record into `profiles` table with: `user_id` (from auth user), `name`, `phone`, `role='customer'`, `active=true`
   - **System Response:** App inserts record into `customers` table with: `profile_id` (from profiles), `address`, `nominee_name`, `nominee_relationship`, `nominee_phone`, `kyc_status='pending'` (if document uploaded)

8. **System Response:** If customer creation successful, app displays success message "Customer created successfully. Customer ID: [customer_id]"
   - **System Response:** App navigates to customer detail page `/office/customers/[id]` showing newly created customer

9. **System Response:** If customer creation fails, app displays error message based on failure type (see Error States)

**Success Criteria:**
- Supabase Auth user is created successfully
- Profile record is created in `profiles` table with `role='customer'`
- Customer record is created in `customers` table linked to profile
- Customer detail page displays with all entered information
- Customer creation completes within 10 seconds

**Error States:**
- **Phone number already exists:** App displays error message "This phone number is already registered. Please use existing customer record." with link to search for existing customer
- **Invalid phone number format:** App displays error message "Please enter a valid 10-digit phone number."
- **Supabase Auth user creation failure:** App displays error message "Failed to create customer account. Please try again or contact support." with error code
- **Profile INSERT failure (database error):** App displays error message "An error occurred while creating customer profile. Please try again." with "Retry" button
- **Customer INSERT failure (database error):** App displays error message "An error occurred while creating customer record. Please try again." with "Retry" button. Note: Profile may be created but customer record missing, requires manual cleanup
- **RLS policy violation:** App displays error message "You do not have permission to create customers. Please contact administrator." (should not occur for office staff, but handled defensively)
- **Network failure:** App displays error message "Network error. Please check your internet connection and try again." with "Retry" button
- **Session expired:** App detects expired session, redirects to login page with message "Session expired. Please login again."

---

#### Office Staff Flow 2: Assign Customer to Collection Staff by Route

**Actors:** Office Staff

**Preconditions:**
- Office staff is authenticated and logged into website
- Customer record exists in `customers` table
- Route exists in `routes` table (if route-based assignment implemented)
- Collection staff member exists with `staff_type='collection'` in `staff_metadata` table
- Device has internet connectivity

**Steps:**
1. **User Action:** Office staff navigates to `/office/assignments/by-route` page
   - **System Response:** App displays assignment interface with route selector and customer list

2. **User Action:** Office staff selects a route from dropdown
   - **System Response:** App queries `routes` table: `routes.select('*').eq('is_active', true).order('route_name')`
   - **System Response:** App displays route details: route name, assigned staff count, customer count

3. **User Action:** Office staff views unassigned customers for selected route (if route has area coverage)
   - **System Response:** App queries `customers` table filtered by route area (if route assignment logic implemented) or shows all unassigned customers
   - **System Response:** App displays customer list with checkboxes for selection

4. **User Action:** Office staff selects multiple customers (checkboxes) and selects target collection staff member
   - **System Response:** App queries `profiles` table joined with `staff_metadata`: `profiles.select('*, staff_metadata(*)').eq('role', 'staff').eq('staff_metadata.staff_type', 'collection').eq('profiles.active', true)`
   - **System Response:** App displays staff dropdown with staff names and codes

5. **User Action:** Office staff taps "Assign Selected Customers" button
   - **System Response:** App displays confirmation dialog: "Assign [X] customers to [Staff Name]? This will create active assignments."
   - **System Response:** Customer can tap "Cancel" or "Confirm"

6. **User Action:** Office staff taps "Confirm" in dialog
   - **System Response:** App displays loading indicator "Assigning customers..."
   - **System Response:** For each selected customer, app inserts record into `staff_assignments` table with: `staff_id` (selected staff's profile_id), `customer_id` (selected customer), `is_active=true`, `assigned_date` (today)
   - **System Response:** If route assignment implemented, app also links assignment to route (if `route_id` column exists in `staff_assignments`)

7. **System Response:** If assignment successful, app displays success message "Successfully assigned [X] customers to [Staff Name]"
   - **System Response:** App refreshes assignment list showing updated assignments

8. **System Response:** If assignment fails, app displays error message based on failure type (see Error States)

**Success Criteria:**
- All selected customers are assigned to selected staff member
- `staff_assignments` records are created with `is_active=true`
- Assignment appears in staff's assigned customer list (visible in mobile app)
- Assignment completes within 5 seconds for up to 50 customers

**Error States:**
- **No route selected:** App displays error message "Please select a route before assigning customers."
- **No customers selected:** App displays error message "Please select at least one customer to assign."
- **No staff selected:** App displays error message "Please select a collection staff member."
- **Customer already assigned to another staff:** App displays warning message "Customer [Name] is already assigned to [Staff Name]. Do you want to reassign?" with options "Reassign" or "Skip"
- **Staff assignment INSERT failure (database error):** App displays error message "Failed to assign customers. Please try again." with "Retry" button. Partial assignments may exist (some customers assigned, others not)
- **RLS policy violation:** App displays error message "You do not have permission to create assignments. Only administrators can manage assignments." (if office staff cannot create assignments, only admin)
- **Network failure:** App displays error message "Network error. Please check your internet connection and try again." with "Retry" button
- **Session expired:** App detects expired session, redirects to login page

---

#### Office Staff Flow 3: Manual Payment Entry (Office Collections)

**Actors:** Office Staff

**Preconditions:**
- Office staff is authenticated and logged into website
- Customer record exists in `customers` table
- Customer has at least one active enrollment in `user_schemes` table
- Current market rates exist in `market_rates` table
- Device has internet connectivity

**Steps:**
1. **User Action:** Office staff navigates to `/office/transactions/add` page
   - **System Response:** App displays manual payment entry form

2. **User Action:** Office staff searches for customer by name or phone number
   - **System Response:** App queries `customers` table: `customers.select('*, profiles(name, phone)').ilike('profiles.name', '%search%').or('profiles.phone.ilike.%search%')`
   - **System Response:** App displays matching customers in dropdown

3. **User Action:** Office staff selects customer from search results
   - **System Response:** App queries `user_schemes` table: `user_schemes.select('*, schemes(*)').eq('customer_id', customerId).eq('status', 'active')`
   - **System Response:** App displays customer's active schemes in dropdown

4. **User Action:** Office staff selects scheme from dropdown (required)
   - **System Response:** App displays scheme details: scheme name, payment frequency, min/max amounts

5. **User Action:** Office staff enters payment amount (required)
   - **System Response:** App validates amount is numeric and positive
   - **System Response:** App validates amount is within scheme's min/max range
   - **System Response:** If invalid, displays error message "Amount must be between ₹[min] and ₹[max]"

6. **User Action:** Office staff selects payment method (required): Cash, UPI, Bank Transfer
   - **System Response:** App enables payment date field

7. **User Action:** Office staff selects payment date (defaults to today, can be past date)
   - **System Response:** App validates date is not in the future
   - **System Response:** If future date, displays error message "Payment date cannot be in the future."

8. **User Action:** Office staff enters payment time (optional, defaults to current time)
   - **System Response:** App validates time format (HH:MM)

9. **User Action:** Office staff enters notes (optional)
   - **System Response:** App accepts free-form text up to 500 characters

10. **User Action:** Office staff taps "Record Payment" button
    - **System Response:** App queries current market rates: `market_rates.select('*').order('rate_date', ascending: false).limit(1)`
    - **System Response:** App calculates gold/silver grams based on payment amount and current rate (if scheme is gold/silver)
    - **System Response:** App generates unique receipt ID (format: RCP-[timestamp]-[random])
    - **System Response:** App displays loading indicator "Recording payment..."

11. **System Action:** App inserts record into `payments` table with fields: `user_scheme_id` (selected scheme), `customer_id` (selected customer), `staff_id` (NULL for office collections), `amount`, `payment_method`, `payment_date`, `payment_time`, `receipt_id`, `notes`, `gold_rate_at_payment` (if gold scheme), `silver_rate_at_payment` (if silver scheme), `metal_grams_added` (calculated), `status='completed'`

12. **System Action:** Database trigger `update_user_scheme_totals` executes automatically
    - **System Response:** Trigger updates `user_schemes` table: increments `total_amount_paid`, `payments_made`, `accumulated_metal_grams`

13. **System Response:** If payment recording successful, app displays success message "Payment recorded successfully. Receipt ID: [receipt_id]"
    - **System Response:** App navigates to transaction detail page `/office/transactions/[id]` showing recorded payment

14. **System Response:** If payment recording fails, app displays error message based on failure type (see Error States)

**Success Criteria:**
- Payment record is created in `payments` table with all entered information
- Receipt ID is generated and displayed
- `user_schemes` totals are updated via database trigger
- Payment appears in transaction list and customer's payment history
- Payment recording completes within 5 seconds

**Error States:**
- **Customer not found:** App displays error message "Customer not found. Please search again."
- **No active schemes:** App displays error message "Customer has no active schemes. Please enroll customer in a scheme first."
- **Invalid payment amount:** App displays specific error message based on validation failure (below minimum, above maximum, non-numeric)
- **Market rates not available:** App displays error message "Market rates are not available. Please update rates before recording payment." and prevents payment entry
- **Payment INSERT failure (RLS violation):** App displays error message "You do not have permission to record payments. Please contact administrator." (should not occur for office staff, but handled defensively)
- **Payment INSERT failure (database error):** App displays error message "Failed to record payment. Please try again or contact support." with error code
- **Trigger UPDATE failure:** Payment INSERT succeeds but trigger fails to update `user_schemes`. App displays warning message "Payment recorded but totals may not be updated. Please verify and contact support if needed." (critical issue requiring manual intervention)
- **Network failure:** App displays error message "Network error. Please check your internet connection and try again." with "Retry" button
- **Session expired:** App detects expired session, redirects to login page

---

#### Collection Staff Flow 1: Record Payment Collection (Mobile App)

**Actors:** Collection Staff (mobile app)

**Preconditions:**
- Collection staff is authenticated and logged into mobile app
- Collection staff has `role='staff'` and `staff_type='collection'` in database
- Customer is assigned to collection staff via `staff_assignments` table with `is_active=true`
- Customer has at least one active enrollment in `user_schemes` table
- Current market rates exist in `market_rates` table
- Device may or may not have internet connectivity (offline mode supported)

**Steps:**
1. **User Action:** Collection staff navigates to Collect Tab from Staff Dashboard
   - **System Response:** App displays assigned customers list
   - **System Response:** App queries `staff_assignments` table: `staff_assignments.select('customer_id').eq('staff_id', staffProfileId).eq('is_active', true)`
   - **System Response:** App queries assigned customers and displays list

2. **User Action:** Collection staff taps on a customer from list
   - **System Response:** App navigates to `CustomerDetailScreen` showing customer information and active schemes
   - **System Response:** App queries `user_schemes` table: `user_schemes.select('*, schemes(*)').eq('customer_id', customerId).eq('status', 'active')`

3. **User Action:** Collection staff taps "Collect Payment" button
   - **System Response:** App navigates to `CollectPaymentScreen` with customer and scheme pre-filled

4. **User Action:** Collection staff enters payment amount
   - **System Response:** App validates amount is numeric and within scheme's min/max range
   - **System Response:** App displays calculated gold/silver grams based on current market rate (if cached or online)

5. **User Action:** Collection staff selects payment method: Cash, UPI, or Bank Transfer
   - **System Response:** App enables "Record Payment" button

6. **User Action:** Collection staff taps "Record Payment" button
   - **System Response:** App checks internet connectivity
   - **System Response:** If online: proceeds to step 7
   - **System Response:** If offline: proceeds to step 8 (offline queue)

7. **System Action (Online):** App records payment directly
   - **System Response:** App queries current market rates (if not cached): `market_rates.select('*').order('rate_date', ascending: false).limit(1)`
   - **System Response:** App calculates metal grams based on payment amount and current rate
   - **System Response:** App generates unique receipt ID
   - **System Response:** App inserts record into `payments` table with: `user_scheme_id`, `customer_id`, `staff_id` (current staff), `amount`, `payment_method`, `payment_date` (today), `payment_time` (current time), `receipt_id`, `gold_rate_at_payment`, `silver_rate_at_payment`, `metal_grams_added`, `status='completed'`
   - **System Response:** Database trigger updates `user_schemes` totals
   - **System Response:** App displays success message "Payment recorded successfully. Receipt ID: [receipt_id]"
   - **System Response:** App navigates back to customer detail screen

8. **System Action (Offline):** App queues payment for sync
   - **System Response:** App stores payment data in local queue (Flutter Secure Storage or SQLite)
   - **System Response:** App generates temporary receipt ID (format: TEMP-[timestamp]-[random])
   - **System Response:** App displays message "Payment queued. Will sync when online. Temporary Receipt ID: [temp_receipt_id]"
   - **System Response:** App marks payment as "pending sync" in local storage
   - **System Response:** App navigates back to customer detail screen

9. **System Action (Offline Sync):** When connection restored, app automatically syncs queued payments
   - **System Response:** App detects network connectivity restored
   - **System Response:** App retrieves queued payments from local storage
   - **System Response:** For each queued payment, app attempts to insert into `payments` table
   - **System Response:** If sync successful, app removes payment from queue and updates temporary receipt ID to permanent receipt ID
   - **System Response:** If sync fails, app keeps payment in queue and retries on next connection

**Success Criteria:**
- Payment is recorded in `payments` table (online) or queued for sync (offline)
- Receipt ID is generated and displayed to staff
- `user_schemes` totals are updated (online) or queued for update (offline)
- Payment appears in customer's payment history
- Offline payments sync successfully when connection restored
- Payment recording completes within 3 seconds (online) or 1 second (offline queue)

**Error States:**
- **Customer not assigned to staff:** App displays error message "You are not assigned to this customer. Please contact office staff." (enforced by RLS, should not occur if UI filters correctly)
- **No active schemes:** App displays error message "Customer has no active schemes." and prevents payment entry
- **Invalid payment amount:** App displays specific error message based on validation failure
- **Market rates not available (online):** App displays error message "Market rates unavailable. Please try again later." and prevents payment entry
- **Market rates not available (offline):** App uses last cached market rate with warning indicator "Using cached rate from [date]"
- **Payment INSERT failure (RLS violation):** App displays error message "You do not have permission to record this payment. Please contact support." (should not occur if customer is assigned, but handled defensively)
- **Payment INSERT failure (network error, online):** App displays error message "Network error. Payment will be queued for offline sync." and automatically queues payment
- **Payment INSERT failure (database error, online):** App displays error message "Failed to record payment. Please try again or contact support." with error code
- **Offline queue full (storage limit):** App displays warning message "Offline queue is full. Please sync payments before recording more." (if queue limit implemented, e.g., 100 payments)
- **Sync failure (conflict):** If payment with same receipt ID exists, app displays warning "Payment may have been recorded. Please verify." and marks for manual review
- **Session expired:** App detects expired session, calls `signOut()`, displays message "Session expired. Please login again." and navigates to LoginScreen

---

#### Administrator Flow 1: View Financial Dashboard (Inflow/Outflow)

**Actors:** Administrator

**Preconditions:**
- Administrator is authenticated and logged into website
- Administrator has `role='admin'` in `profiles` table
- Device has internet connectivity
- Database contains payment and withdrawal records

**Steps:**
1. **User Action:** Administrator navigates to `/admin/dashboard` page
   - **System Response:** App displays financial dashboard with key metrics cards
   - **System Response:** App queries multiple data sources in parallel:
     - Total customers: `SELECT COUNT(*) FROM customers WHERE profile_id IN (SELECT id FROM profiles WHERE role='customer' AND active=true)`
     - Active schemes: `SELECT COUNT(*) FROM user_schemes WHERE status='active'`
     - Today's collections: `SELECT SUM(amount) FROM payments WHERE payment_date = CURRENT_DATE AND status='completed'`
     - Today's withdrawals: `SELECT SUM(final_amount) FROM withdrawals WHERE processed_at::date = CURRENT_DATE AND status='processed'`
     - Pending payments: `SELECT COUNT(*) FROM user_schemes WHERE status='active' AND due_amount > 0`

2. **System Response:** App displays metrics cards with values and loading states
   - **System Response:** Each metric card shows: label, value, change indicator (if comparison data available), loading spinner while fetching

3. **User Action:** Administrator navigates to `/admin/financials/inflow` page
   - **System Response:** App displays inflow tracking interface
   - **System Response:** App queries `payments` table: `payments.select('*').eq('status', 'completed').order('payment_date', ascending: false).limit(100)`
   - **System Response:** App aggregates: daily totals, weekly totals, monthly totals, payment method breakdown (cash vs digital)

4. **System Response:** App displays charts and graphs:
   - **System Response:** Line chart showing daily collection trends (last 30 days)
   - **System Response:** Bar chart showing weekly collection totals
   - **System Response:** Pie chart showing payment method distribution
   - **System Response:** Table showing detailed payment list with filters

5. **User Action:** Administrator navigates to `/admin/financials/outflow` page
   - **System Response:** App displays outflow tracking interface
   - **System Response:** App queries `withdrawals` table: `withdrawals.select('*').order('created_at', ascending: false)`
   - **System Response:** App aggregates: daily withdrawal totals, weekly totals, monthly totals, status breakdown (pending, approved, processed, rejected)

6. **System Response:** App displays charts and graphs:
   - **System Response:** Line chart showing daily withdrawal trends
   - **System Response:** Bar chart comparing inflow vs outflow
   - **System Response:** Table showing detailed withdrawal list with status filters

7. **User Action:** Administrator navigates to `/admin/financials/cash-flow` page
   - **System Response:** App displays net cash flow analysis
   - **System Response:** App calculates: net cash flow = total inflow - total outflow for selected period
   - **System Response:** App displays: cash flow chart, net position, trend analysis, projections (if implemented)

8. **User Action:** Administrator filters data by date range, staff, or customer
   - **System Response:** App applies filters and refreshes queries
   - **System Response:** App updates charts and tables with filtered data

9. **User Action:** Administrator exports financial data
   - **System Response:** App generates CSV/Excel file with filtered data
   - **System Response:** App triggers file download

**Success Criteria:**
- All financial metrics load and display correctly
- Charts and graphs render with accurate data
- Inflow and outflow calculations are correct
- Net cash flow calculation is accurate
- Data filters work correctly
- Export generates complete data file
- Dashboard loads within 10 seconds (initial load)

**Error States:**
- **Database query failure:** App displays error message "Failed to load financial data. Please try again." with "Retry" button
- **No data available:** App displays message "No financial data available for selected period." with option to adjust filters
- **Calculation error (division by zero, null values):** App handles gracefully, displays "Calculation unavailable" for affected metrics, logs error
- **Export generation failure:** App displays error message "Failed to generate export file. Please try again." with "Retry" button
- **Network failure:** App displays error message "Network error. Please check your internet connection." with "Retry" button
- **Session expired:** App detects expired session, redirects to login page

---

#### Administrator Flow 2: Fetch and Update Market Rates

**Actors:** Administrator

**Preconditions:**
- Administrator is authenticated and logged into website
- Administrator has `role='admin'` in database
- External market price API is accessible and configured
- Device has internet connectivity

**Steps:**
1. **User Action:** Administrator navigates to `/admin/market-rates` page
   - **System Response:** App displays current market rates and rate history
   - **System Response:** App queries `market_rates` table: `market_rates.select('*').order('rate_date', ascending: false).limit(30)` (last 30 days)
   - **System Response:** App displays current rates with "Last fetched: [timestamp]" indicator

2. **User Action:** Administrator taps "Fetch Rates from API" button (automatic daily fetch may also be configured)
   - **System Response:** App displays loading indicator "Fetching market rates from API..."
   - **System Response:** App makes API call to external market price API (e.g., Gold Price API, Silver Price API, or third-party aggregator)
   - **System Response:** App receives response with gold rate per gram (INR) and silver rate per gram (INR)

3. **System Action:** App validates API response
   - **System Response:** If API call successful, app extracts gold and silver rates from response
   - **System Response:** If API call fails, app proceeds to step 4 (manual entry fallback)

4. **System Action (If API Fetch Successful):** App automatically saves rates
   - **System Response:** App checks if rate for today's date already exists
   - **System Response:** If rate exists, app updates existing record: `market_rates.update({'gold_rate': fetchedGoldRate, 'silver_rate': fetchedSilverRate}).eq('rate_date', today)`
   - **System Response:** If rate does not exist, app inserts new record: `market_rates.insert({'rate_date': today, 'gold_rate': fetchedGoldRate, 'silver_rate': fetchedSilverRate})`

5. **System Response:** If API fetch and save successful, app displays success message "Market rates fetched and updated successfully for [date]. Gold: ₹[rate]/gram, Silver: ₹[rate]/gram"
   - **System Response:** App refreshes rate history showing updated rates
   - **System Response:** App triggers real-time update to all connected clients (if real-time subscriptions implemented)

6. **Manual Override Option (If API Fetch Fails or Requires Correction):**
   - **User Action:** Administrator taps "Manual Entry" button
   - **System Response:** App displays rate update form with fields: gold rate per gram (INR), silver rate per gram (INR), rate date (defaults to today)
   - **User Action:** Administrator enters gold rate manually (e.g., "6500.00")
   - **System Response:** App validates rate is numeric and positive
   - **User Action:** Administrator enters silver rate manually (e.g., "78.50")
   - **System Response:** App validates rate is numeric and positive
   - **User Action:** Administrator taps "Save Rates" button
   - **System Response:** App saves rates as described in step 4

**Success Criteria:**
- Market rates are fetched from external API successfully
- Rates are saved to `market_rates` table with today's date
- Rate history displays updated rates
- All clients (mobile app and website) see updated rates (via real-time or on next refresh)
- Rate fetch and update completes within 10 seconds
- Manual override available if API fetch fails

**Error States:**
- **API fetch failure (network error):** App displays error message "Failed to fetch rates from API. Please try again or use manual entry." with "Retry" and "Manual Entry" buttons
- **API fetch failure (invalid response):** App displays error message "Invalid response from API. Please use manual entry." with "Manual Entry" button
- **API fetch failure (API unavailable):** App displays error message "Market price API is currently unavailable. Please use manual entry." with "Manual Entry" button
- **Invalid gold rate (manual entry):** App displays error message "Please enter a valid positive number for gold rate."
- **Invalid silver rate (manual entry):** App displays error message "Please enter a valid positive number for silver rate."
- **Future date selected (manual entry):** App displays error message "Rate date cannot be in the future."
- **Rate UPDATE/INSERT failure (RLS violation):** App displays error message "You do not have permission to update market rates. Please contact system administrator." (should not occur for admin, but handled defensively)
- **Rate UPDATE/INSERT failure (database error):** App displays error message "Failed to update market rates. Please try again or contact support." with error code
- **Network failure:** App displays error message "Network error. Please check your internet connection and try again." with "Retry" button
- **Session expired:** App detects expired session, redirects to login page

---

### CRUD Operations

| Entity | Create | Read | Update | Delete | Notes |
|--------|--------|------|--------|--------|-------|
| **profiles** | Admin (via Supabase Auth admin API), Office Staff (for customers during registration) | Users (own), Staff (assigned customers), Admin (all) | Users (own limited fields: name, phone), Admin (all) | Admin only (soft delete: set active=false) | Linked to Supabase Auth `auth.users`. RLS enforced. Staff can read assigned customer profiles via RLS policy. |
| **customers** | Office Staff, Admin | Customers (own), Staff (assigned), Admin (all) | Customers (own: address, nominee), Office Staff (assigned), Admin (all) | Admin only (soft delete: mark inactive, preserve history) | Linked to `profiles` via `profile_id`. RLS enforced. Staff can only read customers assigned to them. |
| **staff_metadata** | Admin only | Staff (own), Admin (all), Unauthenticated (staff_code lookup only, email resolution) | Staff (own limited fields), Admin (all) | Admin only (deactivate staff) | Linked to `profiles` via `profile_id`. RLS enforced. Unauthenticated SELECT allowed for login flow (staff_code → email resolution). |
| **schemes** | Admin only | Everyone (active schemes), Staff (all schemes), Admin (all) | Admin only | Admin only (soft delete: set active=false) | Immutable after creation (admin creates, never updates in practice). RLS enforced. Customers can only read active schemes. |
| **user_schemes** | Office Staff (enroll customers), Admin (manual enrollment) | Customers (own - read-only), Staff (assigned customers), Admin (all) | Triggers only (UPDATE totals via `update_user_scheme_totals` trigger), Admin (status changes) | Admin only (soft delete: set status='cancelled') | **Customers CANNOT INSERT** (enrollment performed only by office staff). Office Staff can INSERT for customers. Staff cannot UPDATE (triggers may fail if staff lacks UPDATE permission). RLS enforced. |
| **payments** | Collection Staff (INSERT for assigned customers), Office Staff (INSERT for office collections, staff_id=NULL), Admin (INSERT) | Customers (own), Staff (assigned customers), Admin (all) | **APPEND-ONLY** (UPDATE blocked by triggers `prevent_payment_update`, `prevent_payment_delete`) | **APPEND-ONLY** (DELETE blocked by triggers) | Immutable for audit compliance. UPDATE/DELETE prevented by database triggers regardless of role. Reversals are new INSERT records with reversal flag. RLS enforced. |
| **market_rates** | System (via external API fetch) or Admin (manual override) | Everyone (read current rates) | System (via API fetch) or Admin (manual override/correction) | Admin only (for corrections) | Rates fetched daily from external API (automated). Admin can manually override/correct if API fetch fails. Historical rates preserved. RLS enforced. |
| **staff_assignments** | Admin only (Office Staff may have permission if business rule allows) | Staff (own assignments), Admin (all) | Admin only (reassign customers) | Admin only (deactivate: set is_active=false) | Links staff to customers. RLS enforced. Staff can only read their own assignments. |
| **withdrawals** | Customers (INSERT request), Admin (manual request) | Customers (own), Staff (assigned customers), Admin (all) | Staff (UPDATE status for assigned customers: approve/reject), Admin (all status updates) | Admin only (cancel withdrawal) | Customers can request withdrawals. Staff can update status (pending → approved/rejected). Admin has full control. RLS enforced. |
| **routes** | Office Staff, Admin | Office Staff, Admin | Office Staff, Admin | Admin only (deactivate: set is_active=false) | New entity for route management. RLS enforced (if implemented). |

### Error States & Edge Cases

**Authentication Errors:**
- **Invalid OTP:** System displays error message "Invalid or expired OTP. Please request a new OTP." with "Resend OTP" button. Maximum 3 resend attempts per phone number per hour (rate limiting).
- **OTP not received:** System displays message "OTP not received? Check your phone number and try again." with option to resend after 60 seconds.
- **Session expired during operation:** System detects expired session, calls `signOut()`, displays message "Session expired. Please login again." and redirects to appropriate login screen (customer or staff).
- **Concurrent login from multiple devices:** System allows multiple sessions per user. Last login invalidates previous sessions if business rule requires single session (not implemented in Phase 1).

**Authorization Errors:**
- **RLS policy violation (unauthorized access):** System displays error message "You do not have permission to access this resource." and logs security event. User is not shown specific details about what was blocked (security best practice).
- **Role mismatch (staff trying to access customer features):** System detects role mismatch, calls `signOut()`, displays message "Access denied. This account is not authorized for this action." and redirects to appropriate screen.
- **Office staff trying to access mobile app:** System blocks access via `checkMobileAppAccess()` function, calls `signOut()`, displays message "Mobile app access is restricted to collection staff only." and returns to LoginScreen.

**Data Validation Errors:**
- **Duplicate phone number during customer creation:** System detects existing phone in `profiles` table, displays error message "This phone number is already registered. Please use existing customer record." with link to search for customer.
- **Payment amount outside scheme range:** System validates amount against `user_schemes.min_amount` and `max_amount`, displays error message "Amount must be between ₹[min] and ₹[max] for this scheme."
- **Invalid date (future payment date):** System validates payment date is not in the future, displays error message "Payment date cannot be in the future."
- **Missing required fields:** System validates all required fields before submission, displays field-specific error messages (e.g., "Name is required.", "Phone number is required.").

**Database Operation Errors:**
- **Payment INSERT succeeds but trigger UPDATE fails:** Payment record is created but `user_schemes` totals are not updated. System displays warning message "Payment recorded but totals may not be updated. Please verify and contact support." This is a critical issue requiring manual database intervention.
- **Concurrent payment recording (race condition):** Two staff members record payment for same customer simultaneously. Both INSERTs succeed (payments are append-only). System handles gracefully, both payments are recorded. Business logic may need to handle duplicate payments at application level.
- **Customer assignment conflict (customer already assigned):** System detects existing active assignment in `staff_assignments` table, displays warning "Customer is already assigned to [Staff Name]. Do you want to reassign?" with options to reassign or cancel.
- **Market rate update conflict (rate for date already exists):** System detects existing rate for selected date, updates existing record instead of creating duplicate, displays message "Updated existing rate for [date]."

**Network & Connectivity Errors:**
- **Network timeout during payment recording:** System detects timeout (30 seconds), displays error message "Request timed out. Please check your internet connection and try again." Payment is automatically queued for offline sync if on mobile app.
- **Partial network failure (some queries succeed, others fail):** System handles partial failures gracefully. Successful operations are committed, failed operations show error messages. User can retry failed operations individually.
- **Database connection lost during transaction:** System detects connection loss, rolls back transaction (if applicable), displays error message "Connection lost. Please try again." and allows retry.

**Offline-Specific Errors:**
- **Offline queue storage full:** System detects local storage limit reached (e.g., 100 queued payments), displays warning "Offline queue is full. Please sync payments before recording more." and prevents new offline payments.
- **Offline sync conflict (payment already recorded):** System detects payment with same receipt ID or duplicate payment during sync, displays warning "Payment may have been recorded. Please verify." and marks for manual review instead of creating duplicate.
- **Offline data corruption:** System detects corrupted local queue data, clears queue, displays warning "Offline data was corrupted and cleared. Please re-record any pending payments." and logs error for investigation.

**Business Logic Edge Cases:**
- **Customer with no active schemes tries to make payment:** System prevents payment entry, displays message "Customer has no active schemes. Please enroll customer in a scheme first." (Office staff must enroll customer via website)
- **Payment recorded for paused scheme:** System allows payment (business rule: payments can be recorded for paused schemes to resume), updates scheme totals, may change status from 'paused' to 'active' if business rule requires.
- **Withdrawal requested for zero accumulated grams:** System prevents withdrawal request, displays message "You have no accumulated gold/silver to withdraw. Please make payments to accumulate grams."
- **Market rates API fetch fails:** System uses last available rate for calculations, displays warning indicator "Using rate from [date]. API fetch failed." Admin can manually update rates if needed.
- **Staff deactivated while having active assignments:** System preserves assignments (historical data), but staff cannot access mobile app. Office staff must reassign customers to active staff.
- **Customer soft-deleted but has active payments:** System preserves customer record and payment history (soft delete), but customer cannot login. Payments continue to be associated with customer record for audit purposes.

**Data Integrity Edge Cases:**
- **Orphaned payment (customer deleted but payment exists):** System prevents customer deletion if payments exist (foreign key constraint `ON DELETE RESTRICT`). If customer must be deleted, admin must first handle payment records (business process, not system automation).
- **Orphaned assignment (staff deleted but assignment exists):** System prevents staff deletion if active assignments exist. Admin must deactivate assignments before deleting staff, or use soft delete (set active=false).
- **Circular dependency in RLS policies:** System uses SECURITY DEFINER functions to break circular dependencies (e.g., `get_user_profile()`, `is_current_staff_assigned_to_customer()`). Policies reference these functions instead of directly querying tables that have RLS.

**Performance Edge Cases:**
- **Large customer list (1000+ customers) loading slowly:** System implements pagination (limit 50 customers per page), lazy loading, and search/filter to reduce load time. Admin can export full list if needed.
- **Multiple simultaneous payment recordings causing database lock:** System handles concurrent inserts gracefully (PostgreSQL handles concurrent INSERTs). If lock occurs, system retries after short delay (exponential backoff, max 3 retries).
- **Real-time subscription overload (too many connected clients):** System limits real-time subscriptions per user (max 5 concurrent subscriptions). Older subscriptions are automatically closed when new ones are created.

### Offline / Retry Behavior

**Offline Features (Mobile App Only):**

**Features That Work Offline:**
- **View cached customer list (Collection Staff):** Assigned customers list is cached after first load. Staff can view customer list, search, and filter offline using cached data. Cache is marked with "Last updated: [timestamp]" indicator.
- **View cached schemes (Customers and Staff):** Available schemes are cached after first load. Users can browse schemes and view scheme details offline.
- **View cached market rates:** Current market rates are cached. Users can view rates offline, with indicator showing "Using cached rate from [date]".
- **View cached transaction history (Customers):** Payment history is cached after first load. Customers can view transaction history offline.
- **View cached payment schedule (Customers):** Payment schedule is calculated and cached. Customers can view schedule offline.
- **Record payment (Collection Staff, Offline Queue):** Payment recording works offline. Payments are queued in local storage and synced when connection restored.

**Features That Require Online Connection:**
- **Authentication (login, OTP verification):** Requires network connection for Supabase Auth.
- **Customer enrollment:** Requires network connection (performed by office staff via website, not by customers via mobile app).
- **Withdrawal requests:** Requires network connection to create `withdrawals` record.
- **Profile updates:** Requires network connection to UPDATE `profiles` and `customers` tables.
- **All website features:** Website requires online connection (no offline mode).

**Retry Logic:**

**Automatic Retry (Mobile App):**
- **Payment recording (online, transient failure):** System automatically retries failed payment INSERT up to 3 times with exponential backoff (1 second, 2 seconds, 4 seconds). If all retries fail, payment is queued for offline sync.
- **Data fetch (transient network error):** System automatically retries failed queries up to 2 times with 2-second delay. If retries fail, system displays error message and allows manual retry.
- **Offline sync (when connection restored):** System automatically attempts to sync all queued payments when network connectivity is detected. Sync runs in background, user is notified of sync status.

**Manual Retry:**
- **All failed operations:** System provides "Retry" button for all failed operations (network errors, database errors). User can manually retry after fixing issues (e.g., reconnecting to network).

**Retry Limitations:**
- **Maximum retry attempts:** 3 automatic retries for payment recording, 2 retries for data fetches
- **Retry timeout:** 30 seconds total timeout per operation (including retries)
- **Non-retryable errors:** RLS violations, validation errors, authentication failures are not retried (user must fix input or permissions)

**Sync Strategy:**

**Offline Payment Queue:**
- **Queue Storage:** Payments are stored in local SQLite database or Flutter Secure Storage with metadata: customer_id, user_scheme_id, amount, payment_method, payment_date, payment_time, receipt_id (temporary), sync_status ('pending', 'syncing', 'synced', 'failed')
- **Queue Limit:** Maximum 100 queued payments (prevents storage overflow). If limit reached, system prevents new offline payments and displays warning.
- **Sync Trigger:** Automatic sync when network connectivity is detected (Connectivity plugin monitors network state)
- **Sync Process:** System processes queue in FIFO order (oldest payments first). For each payment:
  1. Attempt INSERT into `payments` table
  2. If successful, mark as 'synced' and remove from queue
  3. If failed (non-transient error), mark as 'failed' and keep in queue for manual review
  4. If failed (transient error), keep as 'pending' and retry on next sync
- **Sync Status Indicator:** App displays sync status in UI: "X payments pending sync" with progress indicator during sync

**Data Refresh Strategy:**
- **On App Launch (Online):** App automatically refreshes cached data (customer list, schemes, market rates) if last update was more than 1 hour ago
- **Pull-to-Refresh:** Users can manually refresh data by pulling down on list screens
- **Background Refresh:** App refreshes critical data (market rates, assigned customers) every 30 minutes when app is in foreground and online

**Conflict Resolution:**

**Payment Sync Conflicts:**
- **Duplicate receipt ID:** If payment with same receipt ID exists during sync, system detects duplicate, marks queued payment as 'duplicate', displays warning "Payment may have been recorded. Please verify." and does not create duplicate record
- **Customer assignment changed (payment for unassigned customer):** If customer is no longer assigned to staff when payment syncs, system marks payment as 'failed', displays error "Customer is no longer assigned to you. Please contact office staff." and requires manual intervention
- **Scheme status changed (payment for inactive scheme):** System allows payment (payments are append-only), but displays warning "Payment recorded for inactive scheme. Please verify."

**Data Consistency:**
- **Stale cached data:** System displays "Last updated: [timestamp]" indicator on cached data. Users are informed data may be stale.
- **Cache invalidation:** System invalidates cache when user performs write operations (e.g., after payment recording, cache is refreshed on next data fetch)

---

## 5. NON-FUNCTIONAL REQUIREMENTS

### Performance Targets

**Website Performance:**
- **Page load time (initial):** 3 seconds or less (measured on desktop Chrome, 4G connection, Lighthouse performance score ≥ 80)
- **Page load time (subsequent):** 1 second or less (cached assets, client-side navigation)
- **API response time (database queries):** 500 milliseconds or less for 95th percentile (p95) of requests
- **API response time (aggregation queries):** 2 seconds or less for financial dashboard queries (p95)
- **Search/query results returned within:** 1 second for customer/staff search (up to 1000 records)
- **Report generation (export):** 5 seconds or less for CSV/Excel export (up to 10,000 records)
- **Concurrent user capacity:** 100 simultaneous authenticated users on website (baseline), scalable to 500 users with horizontal scaling

**Mobile App Performance:**
- **App startup time (cold start):** 3 seconds or less (measured on Android 8.0+ and iOS 13.0+, mid-range devices)
- **App startup time (warm start):** 1 second or less (app already in memory)
- **Screen navigation (push):** 200 milliseconds or less (smooth 60fps animation)
- **Data fetch (customer list):** 1 second or less for assigned customers list (up to 200 customers)
- **Data fetch (payment history):** 2 seconds or less for customer payment history (up to 100 payments)
- **Payment recording (online):** 3 seconds or less from tap to success confirmation
- **Payment recording (offline queue):** 1 second or less (local storage write)
- **Offline sync (100 queued payments):** 30 seconds or less when connection restored
- **Search/query results returned within:** 500 milliseconds for customer search (cached data, offline)

**Database Performance:**
- **Simple SELECT queries (single table, indexed):** 50 milliseconds or less (p95)
- **JOIN queries (2-3 tables):** 200 milliseconds or less (p95)
- **Aggregation queries (SUM, COUNT, GROUP BY):** 500 milliseconds or less (p95)
- **INSERT operations (single record):** 100 milliseconds or less (p95)
- **Trigger execution (payment totals update):** 200 milliseconds or less (p95)

**Network Performance:**
- **API request timeout:** 30 seconds (configurable per endpoint)
- **Retry delay (exponential backoff):** 1 second, 2 seconds, 4 seconds (max 3 retries)
- **Offline detection:** 5 seconds or less to detect network connectivity loss

### Security Requirements

**Data Encryption:**
- **In transit:** TLS 1.2 or higher (TLS 1.3 preferred) for all API communications, enforced by Supabase (HTTPS only)
- **At rest:** AES-256 encryption for database storage (enforced by Supabase managed PostgreSQL)
- **Mobile app local storage:** Flutter Secure Storage uses platform-native keychain/keystore (iOS Keychain, Android Keystore) with AES-256 encryption
- **Sensitive data in logs:** No sensitive data (passwords, payment amounts, customer PII) logged in plain text. Logs use masked values (e.g., `phone: ***1234`)

**Authentication:**
- **Mechanism:** Supabase Auth (JWT-based sessions)
  - **Access token expiration:** 1 hour (configurable)
  - **Refresh token expiration:** 30 days (configurable)
  - **Token refresh:** Automatic refresh on token expiry (handled by Supabase client SDK)
  - **Session storage:** JWT stored in secure storage (mobile app) or HTTP-only cookies (website, if implemented)
- **Multi-factor authentication (MFA):** Not required in Phase 1, optional for future enhancement
- **Session management:** Single session per user (configurable). Concurrent logins from multiple devices allowed by default, but can be restricted if business requires
- **Session invalidation:** Sessions invalidated on logout, password change, or admin-initiated revocation

**Authorization:**
- **Method:** Role-Based Access Control (RBAC) enforced at multiple layers:
  - **Database layer:** Row Level Security (RLS) policies on all tables
  - **API layer:** Supabase RLS policies enforce access control (no application-level bypass)
  - **Application layer:** UI elements hidden/disabled based on role (defense in depth, not security boundary)
- **Role hierarchy:** Admin > Office Staff > Collection Staff > Customer (permissions inherited downward)
- **Permission granularity:** Table-level and row-level permissions (RLS policies define who can read/write which rows)
- **Audit logging:** All authentication events (login, logout, session expiry) logged by Supabase Auth. Payment INSERTs are append-only (immutable audit trail)

**Password Policy (Website - Office Staff & Admin):**
- **Minimum length:** 8 characters
- **Complexity requirements:** At least one uppercase letter, one lowercase letter, one number, one special character
- **Expiration policy:** 90 days (configurable, not enforced in Phase 1)
- **Password history:** Prevent reuse of last 5 passwords (not enforced in Phase 1)
- **Account lockout:** Lock account after 5 failed login attempts for 30 minutes (configurable)
- **Password reset:** Email-based password reset with secure token (expires in 1 hour)

**OTP Policy (Mobile App - Customers & Staff):**
- **OTP length:** 6 digits
- **OTP expiration:** 5 minutes from generation
- **OTP resend limit:** Maximum 3 resend attempts per phone number per hour (rate limiting)
- **OTP generation:** Cryptographically secure random number generation (handled by Supabase Auth)
- **OTP delivery:** SMS via Supabase Auth SMS provider (Twilio or similar)

**PIN Policy (Mobile App):**
- **PIN length:** 4-6 digits (user configurable, default 4)
- **PIN storage:** Encrypted in Flutter Secure Storage (never stored in plain text)
- **PIN lockout:** Lock app after 5 failed PIN attempts for 5 minutes (configurable)
- **PIN reset:** Requires OTP verification to reset PIN

**PCI DSS Compliance:**
- **Status:** Not applicable (Phase 1)
- **Reason:** System does not directly process credit card payments. Payment methods are Cash, UPI, and Bank Transfer (handled externally). No cardholder data (CHD) stored or transmitted.
- **Future consideration:** If credit card payments are added, PCI DSS Level 1 compliance will be required (use PCI-compliant payment gateway like Stripe, Razorpay)

**GDPR Compliance (if applicable):**
- **Data residency:** Data stored in Supabase-managed PostgreSQL (region: India, if available, or closest region)
- **Right to deletion:** Users can request account deletion. System implements soft delete (set `active=false`) to preserve audit trail (payments are immutable). Hard delete available for admin with explicit approval.
- **Right to access:** Users can view all their personal data via profile screens
- **Consent management:** Users consent to data collection during registration (implicit consent for required data, explicit consent for optional data like biometrics)
- **Data retention:** Customer data retained indefinitely for audit purposes (payments are append-only). Inactive accounts (soft-deleted) retained for 7 years (configurable, business rule)

**API Security:**
- **Rate limiting:** 
  - **Authentication endpoints:** 10 requests per minute per IP address (prevents brute force)
  - **Data endpoints:** 100 requests per minute per authenticated user (prevents abuse)
  - **Payment endpoints:** 20 requests per minute per authenticated user (prevents duplicate payments)
- **API key rotation:** Supabase API keys (anon, service_role) rotated every 90 days (manual process, not automated in Phase 1)
- **Request signing:** Not implemented in Phase 1 (Supabase handles request validation via JWT)
- **CORS policy:** Website API calls restricted to allowed origins (Supabase project settings)
- **Input validation:** All user inputs validated client-side and server-side (database constraints, RLS policies)

**Secrets Management:**
- **Supabase API keys:** Stored in environment variables (website: `.env` file, not committed to repo; mobile app: compiled into app, anon key is public, service_role key never exposed to client)
- **Third-party API keys (OTP, SMS):** Stored in Supabase project settings (encrypted at rest)
- **Database credentials:** Managed by Supabase (never exposed to application code)
- **Mobile app secrets:** Sensitive keys stored in Flutter Secure Storage (encrypted)
- **Rotation policy:** API keys rotated every 90 days (manual process). Database credentials rotated by Supabase automatically (transparent to application)

**Security Monitoring:**
- **Failed login attempts:** Logged and monitored (Supabase Auth logs)
- **RLS policy violations:** Logged by Supabase (audit trail)
- **Suspicious activity:** Manual monitoring (automated alerts not implemented in Phase 1)
- **Security updates:** Dependencies updated monthly (Flutter, Supabase SDK, website dependencies)

### Scalability Assumptions

**User Growth Projections:**
- **Year 1 (Baseline):**
  - **Customers:** 1,000 - 1,500 active customers (100-150 new enrollments per month)
  - **Collection Staff:** 10 - 20 active staff members
  - **Office Staff:** 3 - 5 active staff members
  - **Administrators:** 1 - 2 administrators
  - **Total authenticated users:** ~1,500 users
- **Year 2 (Growth):**
  - **Customers:** 2,500 - 3,500 active customers (150-200 new enrollments per month)
  - **Collection Staff:** 20 - 30 active staff members
  - **Office Staff:** 5 - 8 active staff members
  - **Administrators:** 2 - 3 administrators
  - **Total authenticated users:** ~3,500 users
- **Year 3 (Mature):**
  - **Customers:** 5,000 - 7,500 active customers (200-250 new enrollments per month)
  - **Collection Staff:** 30 - 50 active staff members
  - **Office Staff:** 8 - 12 active staff members
  - **Administrators:** 3 - 5 administrators
  - **Total authenticated users:** ~7,500 users

**Peak Concurrent Users:**
- **Baseline (Year 1):** 50 - 100 simultaneous authenticated users
  - **Breakdown:** 40-80 customers (mobile app), 5-10 collection staff (mobile app), 3-5 office staff (website), 1-2 administrators (website)
- **Growth (Year 2):** 150 - 250 simultaneous authenticated users
  - **Breakdown:** 120-200 customers, 10-20 collection staff, 5-8 office staff, 2-3 administrators
- **Mature (Year 3):** 300 - 500 simultaneous authenticated users
  - **Breakdown:** 250-400 customers, 20-40 collection staff, 8-12 office staff, 3-5 administrators

**Data Storage Growth:**
- **Year 1:**
  - **Customer data:** ~50 MB (1,500 customers × ~33 KB per customer record including profile, customer, schemes, payments)
  - **Payment records:** ~100 MB (assuming 10,000 payments × ~10 KB per payment record)
  - **Total database size:** ~200 MB (including indexes, metadata, market rates, staff data)
- **Year 2:**
  - **Customer data:** ~120 MB (3,500 customers)
  - **Payment records:** ~300 MB (30,000 payments)
  - **Total database size:** ~500 MB
- **Year 3:**
  - **Customer data:** ~250 MB (7,500 customers)
  - **Payment records:** ~750 MB (75,000 payments)
  - **Total database size:** ~1.5 GB
- **Storage growth rate:** ~500 MB per year (linear growth, assuming consistent enrollment and payment volume)

**Database Scaling Strategy:**
- **Phase 1 (Year 1):** Vertical scaling (single Supabase PostgreSQL instance, upgrade to larger instance if needed)
  - **Baseline:** Supabase Free tier or Pro tier (2 GB RAM, 1 vCPU) sufficient for Year 1
  - **Upgrade trigger:** Database CPU usage > 70% sustained, or storage > 80% capacity
- **Phase 2 (Year 2):** Vertical scaling continued (upgrade to larger instance: 4 GB RAM, 2 vCPU)
  - **Consider read replicas:** If read-heavy workloads (reports, dashboards) cause performance issues
- **Phase 3 (Year 3+):** Evaluate horizontal scaling (sharding, read replicas, or migration to dedicated PostgreSQL cluster)
  - **Sharding strategy:** Not required unless database size exceeds 10 GB or concurrent users exceed 1,000
  - **Read replicas:** Deploy 1-2 read replicas for reporting queries (financial dashboards, exports)
- **Caching strategy:** Implement Redis caching layer (Supabase Edge Functions or external Redis) for frequently accessed data (market rates, active schemes) if database queries become bottleneck

**Application Scaling:**
- **Website:** Stateless application (Next.js), can scale horizontally via load balancer (Vercel handles this automatically)
- **Mobile App:** Client-side application, no server-side scaling required (each user runs app on their device)
- **API (Supabase):** Managed by Supabase, scales automatically (Supabase handles load balancing and scaling)

### Availability & Reliability Expectations

**Uptime SLA:**
- **Target:** 99.5% uptime (approximately 43.8 hours of downtime per year, or ~3.6 hours per month)
- **Measurement:** Uptime measured at API level (Supabase API availability)
- **Exclusions:** Scheduled maintenance windows (announced 48 hours in advance), force majeure events
- **Monitoring:** Uptime monitoring via external service (UptimeRobot, Pingdom, or similar) with 5-minute check interval
- **Alerting:** Email/SMS alerts to administrators if uptime drops below 99% or if downtime exceeds 30 minutes

**Recovery Time Objective (RTO):**
- **Target:** 4 hours (maximum acceptable time to restore service after failure)
- **Breakdown:**
  - **Detection time:** 5 minutes (automated monitoring)
  - **Investigation time:** 30 minutes (identify root cause)
  - **Recovery time:** 3 hours (restore from backup, verify data integrity, resume service)
  - **Buffer:** 25 minutes (contingency)
- **Recovery procedures:** Documented runbooks for common failure scenarios (database corruption, API outage, deployment failure)

**Recovery Point Objective (RPO):**
- **Target:** 1 hour (maximum acceptable data loss in case of failure)
- **Implementation:**
  - **Database backups:** Hourly automated backups (Supabase managed backups)
  - **Point-in-time recovery:** Supabase supports point-in-time recovery (PITR) for last 7 days (configurable)
  - **Data loss scenario:** In worst case (database corruption, backup failure), maximum 1 hour of payment/transaction data may be lost (last backup to failure time)
  - **Mitigation:** Real-time replication (Supabase handles this automatically) reduces RPO to near-zero for hardware failures

**Backup Frequency:**
- **Database backups:**
  - **Full backup:** Daily automated backup (Supabase managed, stored in encrypted storage)
  - **Incremental backup:** Continuous WAL (Write-Ahead Log) archiving (Supabase managed)
  - **Retention:** 30 days of daily backups, 7 days of point-in-time recovery (configurable)
- **Application code backups:**
  - **Version control:** Git repository (GitHub/GitLab) serves as code backup
  - **Deployment artifacts:** Build artifacts stored in CI/CD system (GitHub Actions, Vercel)
- **Configuration backups:**
  - **Environment variables:** Stored in version control (encrypted) or secrets management system (Supabase project settings)
  - **Database schema:** Version controlled in migration files (`supabase_schema.sql`)

**Disaster Recovery Plan:**
- **Geographic redundancy:**
  - **Primary region:** Supabase project hosted in India region (if available) or closest region (Asia-Pacific)
  - **Backup region:** Supabase supports cross-region backups (manual process, not automated in Phase 1)
  - **Failover strategy:** Manual failover to backup region (requires database restore from backup, estimated 4-6 hours)
- **Data replication:**
  - **Real-time replication:** Supabase PostgreSQL uses streaming replication (automatic, transparent)
  - **Read replicas:** Deploy read replica in different region for disaster recovery (optional, not implemented in Phase 1)
- **Recovery procedures:**
  - **Database failure:** Restore from latest backup (Supabase managed restore), verify data integrity, resume service
  - **API outage:** Supabase handles API redundancy automatically (multiple API servers, load balanced)
  - **Application deployment failure:** Rollback to previous deployment version (Vercel supports instant rollback)
- **Testing:** Disaster recovery procedures tested quarterly (restore from backup, verify data integrity, measure RTO/RPO)
- **Communication plan:** Notify stakeholders (customers, staff) via SMS/email if downtime exceeds 1 hour

---

## 6. TECHNICAL ARCHITECTURE

### 6.1. System Architecture Principles (Binding)

#### Purpose

This section documents the fundamental architectural principles that govern all implementation decisions. These principles are **binding and non-negotiable** for Phase 1 implementation. They serve as architectural law, not suggestions.

#### Principle 1: Database-First Enforcement

**Statement:** All authorization and data access MUST be enforced at the PostgreSQL database level via Row Level Security (RLS) policies and database triggers. Frontend checks are secondary, non-authoritative, and cannot be relied upon for security.

**Binding Requirements:**
- **RLS Policies:** Every table MUST have RLS policies that enforce access control based on user role, authentication state, and business relationships (e.g., staff assignments)
- **No Frontend-Only Security:** Application code (mobile app, website) MUST NOT be the sole enforcement mechanism for authorization. Database RLS policies MUST prevent unauthorized access even if frontend checks are bypassed
- **RLS Coverage:** RLS policies MUST cover all operations (SELECT, INSERT, UPDATE, DELETE) for all tables containing business data
- **SECURITY DEFINER Functions:** Helper functions that bypass RLS MUST be minimal, audited, and explicitly documented. They MUST validate authentication and authorization internally
- **Enforcement:** If a user attempts to access data they are not authorized for, the database MUST reject the operation regardless of what the frontend allows

**Implementation Mandate:**
- Frontend code may perform role checks for UI display purposes (showing/hiding buttons, menus)
- Frontend code MUST NOT assume that UI hiding prevents unauthorized access
- All API requests MUST be validated against RLS policies at the database level
- Direct database access (if any) MUST respect RLS policies

**Violation Consequences:**
- Any implementation that relies solely on frontend checks for authorization is a security violation
- Any table without appropriate RLS policies is a security violation
- Any operation that can bypass RLS through application code is a security violation

#### Principle 2: Append-Only Financial Records

**Statement:** Payments and financial transactions are immutable after creation. UPDATE and DELETE operations on financial records are permanently prohibited. Reversals are implemented as new INSERT records, not modifications to existing records.

**Binding Requirements:**
- **Payment Immutability:** The `payments` table MUST NOT allow UPDATE or DELETE operations. Database triggers MUST block these operations regardless of user role
- **Reversal Pattern:** Payment reversals MUST be implemented as new `payments` records with `is_reversal = true` and `reverses_payment_id` pointing to the original payment
- **Audit Trail:** All financial transactions MUST preserve historical state (rates, amounts, timestamps) at the time of transaction
- **No Recalculation:** Financial calculations (metal grams, totals) MUST use the rate stored at payment time (`metal_rate_per_gram`), not current market rates
- **Trigger Logic:** Database triggers that update `user_schemes` totals MUST use payment-time rates, not current rates

**Implementation Mandate:**
- Application code MUST NOT attempt UPDATE or DELETE on `payments` table
- Application code MUST NOT recalculate historical payments using current rates
- Database triggers MUST prevent payment modifications even if application code attempts them
- Reconciliation queries MUST verify that totals match sum of individual payment records

**Violation Consequences:**
- Any code that attempts to UPDATE or DELETE payments is a violation
- Any trigger that recalculates historical payments using current rates is a violation
- Any operation that modifies financial history is a violation

#### Principle 3: Thin Clients

**Statement:** Mobile app and website are thin clients that display data and execute pre-authorized operations. They do not calculate or override financial truth. All business logic and calculations reside in the database (triggers, functions, constraints).

**Binding Requirements:**
- **No Client-Side Financial Calculations:** Mobile app and website MUST NOT calculate financial values (metal grams, totals, rates) independently. They MUST use values provided by the database
- **Database as Calculator:** All financial calculations (GST, net amount, metal grams, scheme totals) MUST be performed by database triggers, functions, or constraints
- **Client Validation Only:** Frontend code may validate user input (format, range checks) but MUST NOT override database calculations
- **Read Database Truth:** Frontend MUST read calculated values from database, not recalculate them

**Implementation Mandate:**
- Application code may calculate values for display preview, but MUST submit to database for authoritative calculation
- Database triggers MUST recalculate and validate all financial values on INSERT/UPDATE
- Application code MUST use database-provided values for all financial operations
- No "smart" client logic that overrides database calculations

**Violation Consequences:**
- Any client-side calculation that overrides database values is a violation
- Any logic that bypasses database triggers is a violation
- Any "optimization" that skips database validation is a violation

#### Principle 4: Single Source of Truth

**Statement:** Supabase PostgreSQL database is the only source of truth for all business data. No caching, local storage, or external systems can override or replace database authority.

**Binding Requirements:**
- **Database Authority:** All business data (customers, payments, schemes, enrollments, rates) MUST be stored in and retrieved from PostgreSQL database
- **No Alternative Sources:** Application code MUST NOT use mock data, hardcoded values, or external caches as substitutes for database queries in production
- **Cache Invalidation:** If caching is used for performance, cache MUST be invalidated on data changes and MUST fall back to database on cache miss
- **Offline Sync:** Offline data (mobile app) MUST be queued and synced to database. Database is authoritative even for offline operations

**Implementation Mandate:**
- All data queries MUST originate from database (Supabase client queries)
- Mock data MUST be removed from production code
- Hardcoded values (rates, totals) MUST be replaced with database queries
- Offline queues MUST sync to database before considering operation complete

**Violation Consequences:**
- Any use of mock data in production is a violation
- Any hardcoded business values (rates, totals) are violations
- Any cache that serves stale data without database fallback is a violation

#### Principle 5: Phase-1 Discipline

**Statement:** Only features explicitly listed as IN SCOPE in Section 2 (Scope Definition) are implemented in Phase 1. Features listed as OUT OF SCOPE are not implemented, regardless of ease of implementation or perceived value.

**Binding Requirements:**
- **IN SCOPE Only:** Implementation MUST include all features listed in Section 2.3 (Explicit IN SCOPE)
- **OUT OF SCOPE Exclusion:** Implementation MUST NOT include any features listed in Section 2.4 (Explicit OUT OF SCOPE)
- **No Scope Creep:** Features not explicitly listed as IN SCOPE are OUT OF SCOPE by default
- **Deferred Features:** Features marked as "deferred to later phase" are OUT OF SCOPE for Phase 1

**Implementation Mandate:**
- Development team MUST reference Section 2 (Scope Definition) before implementing any feature
- Any feature not in IN SCOPE list MUST be rejected or deferred
- "Quick wins" or "easy additions" that are OUT OF SCOPE MUST NOT be implemented
- All stakeholders MUST agree to scope changes before implementation

**Violation Consequences:**
- Any feature implemented that is OUT OF SCOPE is a scope violation
- Any feature omitted that is IN SCOPE is a delivery violation
- Scope changes without stakeholder approval are violations

#### Enforcement and Compliance

**Architectural Review:**
- All implementation decisions MUST be reviewed against these principles
- Any deviation from these principles REQUIRES explicit architectural approval and documentation
- Violations of these principles are considered architectural defects, not feature requests

**Code Review Requirements:**
- Code reviews MUST verify compliance with all five principles
- Database schema changes MUST verify RLS policy coverage (Principle 1)
- Financial logic MUST verify immutability and append-only patterns (Principle 2)
- Client code MUST verify thin client pattern (Principle 3)
- Data access MUST verify single source of truth (Principle 4)
- Feature implementation MUST verify scope compliance (Principle 5)

**Non-Compliance:**
- Code that violates these principles MUST be rejected in code review
- Violations MUST be fixed before merge to main branch
- Repeated violations MAY result in architectural review and process changes

---

### 6.2. Web Frontend Stack

**Framework:**
- **Primary:** Next.js 14+ (App Router) - React-based framework with server components and API routes
- **Rationale:** Server-side rendering (SSR) for improved SEO and performance, built-in API routes for server-side logic, excellent TypeScript support, automatic code splitting, and optimized production builds

**Language:**
- **Primary:** TypeScript 5.0+ (strict mode enabled)
- **Rationale:** Type safety, better IDE support, compile-time error detection, improved maintainability for team development

**State Management:**
- **Client State:** React Query (TanStack Query) v5+ for server state (API data fetching, caching, synchronization)
- **UI State:** React Context API + `useState` hooks for local component state (form state, UI toggles, modal visibility)
- **Global State:** Zustand (optional, for complex cross-component state if needed)
- **Rationale:** React Query handles server state (Supabase API calls) with automatic caching, background refetching, and optimistic updates. Context API is sufficient for simple UI state. Zustand provides lightweight global state if needed.

**Build Tool:**
- **Primary:** Next.js built-in build system (Turbopack in development, Webpack in production)
- **Package Manager:** npm or pnpm
- **Rationale:** Next.js includes optimized build pipeline, no additional configuration needed

**CSS Approach:**
- **Framework:** Tailwind CSS 3.4+ (utility-first CSS framework)
- **Component Library:** shadcn/ui (headless component library built on Radix UI, styled with Tailwind)
- **Rationale:** Rapid UI development, consistent design system, accessible components (Radix UI), easy customization, no runtime CSS-in-JS overhead

**UI Components:**
- **Base Components:** shadcn/ui (Button, Input, Select, Table, Dialog, Dropdown, etc.)
- **Data Visualization:** Recharts (React charting library) for financial dashboards and reports
- **Data Tables:** React Table (TanStack Table) v8+ for sortable, filterable, paginated tables
- **Form Validation:** Zod (schema validation) + React Hook Form (form state management)
- **Rationale:** shadcn/ui provides production-ready, accessible components. Recharts offers flexible charting. React Table handles complex data tables. Zod + React Hook Form ensures type-safe form validation.

**Testing Framework:**
- **Unit Tests:** Vitest (Vite-native test runner, Jest-compatible API)
- **Component Tests:** React Testing Library (component testing utilities)
- **E2E Tests:** Playwright (browser automation, cross-browser testing)
- **Rationale:** Vitest is fast and integrates well with Vite/Next.js. React Testing Library promotes testing user behavior. Playwright provides reliable E2E testing.

**Deployment Target:**
- **Primary:** Vercel (Next.js-optimized hosting platform)
- **Alternative:** Netlify, AWS Amplify, or self-hosted (Docker container on AWS EC2, Azure App Service, or GCP Cloud Run)
- **Rationale:** Vercel provides zero-config deployment, automatic HTTPS, edge network, and seamless Git integration. Alternative platforms offer flexibility if needed.

**Additional Libraries:**
- **Date Handling:** date-fns (lightweight date utility library)
- **HTTP Client:** Supabase JavaScript Client (official Supabase SDK for API calls)
- **Icons:** Lucide React (icon library, consistent with shadcn/ui)
- **Toast Notifications:** sonner (toast notification library, compatible with shadcn/ui)

---

### Mobile Application Stack

**Platform Support:**
- **iOS:** Native Flutter app (iOS 13.0+)
- **Android:** Native Flutter app (Android 8.0+ / API level 26+)
- **Rationale:** Single codebase for both platforms, native performance, consistent UI/UX across platforms, large ecosystem of packages

**Framework & Language:**
- **Framework:** Flutter 3.24+ (Dart SDK 3.10.1+)
- **Language:** Dart 3.10.1+ (null safety enabled, sound null safety)
- **Rationale:** Flutter provides native performance, hot reload for rapid development, rich widget library, and strong tooling support

**State Management:**
- **Primary:** Riverpod 2.5.1+ (explicit state management, compile-time safe, provider replacement)
  - **Pattern:** `Provider` for derived state, `StreamProvider` for reactive streams (auth state), `FutureProvider` for async data fetching, `StateNotifierProvider` for complex state logic
  - **Migration Status:** Currently migrating from Provider to Riverpod (Provider remains for legacy `AuthFlowNotifier`, Riverpod for new state)
- **Legacy (Temporary):** Provider 6.1.5 (for `AuthFlowNotifier` during migration, will be removed after full migration)
- **Local State:** `StatefulWidget` with `setState()` for widget-local UI state (form controllers, loading flags, UI toggles)
- **Rationale:** Riverpod provides compile-time safety, better testability, explicit dependencies, and eliminates BuildContext dependency issues. Provider is legacy and being phased out.

**Architecture Pattern:**
- **Pattern:** Service Layer + State Layer + Presentation Layer
  - **Service Layer:** Stateless service classes (`AuthService`, `PaymentService`, `StaffDataService`) that interact with Supabase API
  - **State Layer:** Riverpod providers that expose service methods and manage reactive state
  - **Presentation Layer:** Flutter widgets (screens, components) that consume Riverpod providers
- **Navigation:** Declarative routing via `appRouterProvider` (Riverpod provider that returns root widget based on auth state and role)
- **Rationale:** Clear separation of concerns, testable service layer, reactive state management, declarative navigation eliminates imperative navigation bugs

**Local Storage:**
- **Sensitive Data:** Flutter Secure Storage 9.2.4+ (PIN, biometric preferences, encrypted storage using platform keychain/keystore)
- **Offline Queue:** SQLite (via `sqflite` package, if implemented) or Flutter Secure Storage (JSON-encoded queue data)
- **Cache:** In-memory caching (Riverpod providers cache data automatically), SharedPreferences 2.5.3+ for non-sensitive preferences (theme, language)
- **Rationale:** Flutter Secure Storage uses platform-native encryption (iOS Keychain, Android Keystore). SQLite provides structured storage for offline queue. SharedPreferences is lightweight for simple preferences.

**Authentication & Security:**
- **Auth Provider:** Supabase Flutter SDK 2.10.3+ (Supabase Auth integration)
- **Biometric Auth:** Local Auth 2.1.7+ (Face ID, Touch ID, fingerprint authentication)
- **PIN Storage:** Flutter Secure Storage (encrypted PIN storage)
- **Session Management:** Supabase Auth SDK handles JWT tokens, automatic refresh, session persistence
- **Rationale:** Supabase Auth provides secure authentication with OTP, password-based login, and session management. Local Auth enables biometric authentication. Flutter Secure Storage ensures sensitive data is encrypted.

**Network & API:**
- **API Client:** Supabase Flutter SDK (PostgREST client for database queries, Auth client for authentication)
- **Offline Support:** Connectivity monitoring (connectivity_plus package) + offline queue for payment recording
- **Error Handling:** Try-catch blocks with user-friendly error messages, automatic retry logic for transient failures
- **Rationale:** Supabase SDK provides type-safe API client with automatic retries. Offline queue ensures payment recording works without network.

**UI Components:**
- **Design System:** Material Design 3 (Flutter's built-in Material widgets)
- **Custom Components:** Reusable widgets in `lib/widgets/` directory (custom buttons, cards, forms)
- **Icons:** Material Icons (built-in), Cupertino Icons 1.0.8+ (iOS-style icons)
- **Fonts:** Google Fonts 6.2.1+ (custom font loading)
- **Rationale:** Material Design 3 provides consistent, accessible UI components. Custom components ensure brand consistency.

**Push Notifications:**
- **Provider:** Firebase Cloud Messaging (FCM) for Android, Apple Push Notification service (APNs) for iOS
- **Implementation:** `firebase_messaging` package (not yet implemented in Phase 1, planned for future)
- **Rationale:** FCM/APNs provide reliable push notification delivery. Implementation deferred to Phase 2.

**Analytics:**
- **Provider:** Firebase Analytics (via `firebase_analytics` package, not yet implemented in Phase 1)
- **Events Tracked:** User actions (login, payment recording, scheme enrollment), screen views, errors
- **Rationale:** Firebase Analytics provides free, comprehensive analytics. Implementation deferred to Phase 2.

**Testing Framework:**
- **Unit Tests:** Flutter Test (built-in testing framework)
- **Widget Tests:** Flutter Test (widget testing utilities)
- **Integration Tests:** Flutter Driver or Integration Test package (E2E testing)
- **Rationale:** Flutter Test is built-in and provides comprehensive testing capabilities.

**App Distribution:**
- **iOS:** App Store (production), TestFlight (beta testing)
- **Android:** Google Play Store (production), Firebase App Distribution (internal testing)
- **Build Tools:** Flutter CLI (`flutter build ios`, `flutter build apk/appbundle`)
- **Rationale:** App Store and Google Play provide official distribution channels. TestFlight and Firebase App Distribution enable beta testing.

**Additional Packages:**
- **Environment Variables:** flutter_dotenv 6.0.0+ (load `.env` file for Supabase credentials)
- **Date Formatting:** intl 0.18.1+ (internationalization and date formatting)
- **Image Picker:** image_picker 1.0.7+ (select images from gallery/camera for KYC documents)
- **URL Launcher:** url_launcher 6.2.0+ (open external URLs, phone dialer, email client)
- **SMS Autofill:** sms_autofill 2.3.0+ (auto-fill OTP from SMS on Android)
- **Crypto:** crypto 3.0.3+ (hashing, encryption utilities)

---

### Backend Architecture

**Platform:**
- **Provider:** Supabase (managed backend-as-a-service platform)
- **Components:**
  - **Database:** PostgreSQL 15+ (managed PostgreSQL instance)
  - **Auth:** Supabase Auth (JWT-based authentication service)
  - **Storage:** Supabase Storage (object storage for file uploads, KYC documents)
  - **Realtime:** Supabase Realtime (PostgreSQL change streams, WebSocket subscriptions)
  - **API:** PostgREST (auto-generated REST API from PostgreSQL schema)
- **Rationale:** Supabase provides complete backend infrastructure without server management, automatic scaling, built-in security (RLS), and developer-friendly API.

**Architecture Pattern:**
- **Pattern:** Serverless / Backend-as-a-Service (BaaS)
- **Database-First Design:** Database schema defines API surface (PostgREST auto-generates REST endpoints from tables)
- **No Custom Backend Server:** All business logic in database (triggers, functions, RLS policies) or client-side (Flutter/Next.js)
- **Edge Functions (Future):** Supabase Edge Functions (Deno runtime) for server-side logic if needed (not implemented in Phase 1)
- **Rationale:** Database-first design reduces API surface area, ensures data consistency, and leverages PostgreSQL's powerful features (triggers, RLS). Serverless architecture eliminates server management overhead.

**API Style:**
- **Primary:** REST API (PostgREST auto-generated from PostgreSQL schema)
- **Endpoints:** Auto-generated from table names (e.g., `GET /rest/v1/profiles`, `POST /rest/v1/payments`)
- **RPC Functions:** PostgreSQL functions exposed as REST endpoints (e.g., `POST /rest/v1/rpc/get_staff_email_by_code`)
- **GraphQL:** Not used (PostgREST REST API is sufficient)
- **gRPC:** Not used (REST API is standard and widely supported)
- **Rationale:** PostgREST provides type-safe, auto-generated REST API with automatic OpenAPI documentation. RPC functions enable custom server-side logic.

**Message Queue:**
- **Status:** Not implemented in Phase 1
- **Future Consideration:** Supabase Realtime can act as message queue for event-driven workflows (payment notifications, status updates)
- **Rationale:** Current architecture doesn't require message queue. Realtime subscriptions provide event-driven capabilities if needed.

**Caching Layer:**
- **Status:** Not implemented in Phase 1
- **Future Consideration:** Redis caching layer (via Supabase Edge Functions or external Redis service) for frequently accessed data (market rates, active schemes)
- **Client-Side Caching:** React Query (website) and Riverpod (mobile app) provide client-side caching
- **Rationale:** Client-side caching is sufficient for Phase 1. Server-side caching can be added if database queries become bottleneck.

**Logging & Monitoring:**
- **Supabase Dashboard:** Built-in logging and monitoring (API logs, database logs, auth logs)
- **Error Tracking:** Supabase provides error logs for API failures, database errors, auth failures
- **Future Consideration:** External monitoring service (Sentry, Datadog) for advanced error tracking and performance monitoring
- **Rationale:** Supabase dashboard provides basic monitoring. External services can be added for advanced observability.

**Backup & Disaster Recovery:**
- **Database Backups:** Supabase managed backups (daily full backups, continuous WAL archiving)
- **Point-in-Time Recovery:** Supabase supports PITR for last 7 days (configurable)
- **Geographic Redundancy:** Supabase handles database replication and failover (transparent to application)
- **Rationale:** Supabase manages backups and disaster recovery, reducing operational overhead.

---

### Database Approach

**Primary Database:**
- **Type:** PostgreSQL 15+ (relational database)
- **Provider:** Supabase managed PostgreSQL (hosted on AWS, GCP, or Azure, region: India or closest region)
- **Rationale:** PostgreSQL provides ACID compliance, strong consistency, powerful query capabilities, JSON support, and excellent performance for relational data.

**Database Design:**
- **Pattern:** Relational database with normalized schema
- **Normalization:** Third Normal Form (3NF) - tables normalized to reduce redundancy
- **Relationships:** Foreign key constraints enforce referential integrity (e.g., `customers.profile_id` → `profiles.id`, `payments.customer_id` → `customers.id`)
- **Enums:** PostgreSQL ENUM types for constrained values (`user_role`, `asset_type`, `payment_method`, `scheme_status`, `payment_status`, `withdrawal_status`, `withdrawal_type`)
- **Rationale:** Normalized schema ensures data consistency, reduces storage, and simplifies updates. Foreign keys prevent orphaned records. ENUMs ensure data integrity.

**Row Level Security (RLS):**
- **Enforcement:** RLS enabled on all tables (`profiles`, `customers`, `staff_metadata`, `schemes`, `user_schemes`, `payments`, `market_rates`, `staff_assignments`, `withdrawals`)
- **Policies:** Role-based policies define who can read/write which rows (e.g., customers read own data, staff read assigned customers, admin reads all)
- **Functions:** SECURITY DEFINER functions (`get_user_profile()`, `is_staff_assigned_to_customer()`) used by RLS policies to break circular dependencies
- **Rationale:** RLS provides database-level security, preventing unauthorized access even if application logic is bypassed. SECURITY DEFINER functions enable complex policy logic.

**Database Triggers:**
- **Purpose:** Enforce business rules, maintain data consistency, generate computed values
- **Key Triggers:**
  - `update_user_scheme_totals()` - Updates `user_schemes` totals (total_amount_paid, payments_made, accumulated_metal_grams) when payment is inserted
  - `prevent_payment_modification()` - Prevents UPDATE/DELETE on `payments` table (enforces append-only audit trail)
  - `generate_receipt_number()` - Generates unique receipt ID for payments
  - `update_updated_at_column()` - Updates `updated_at` timestamp on record modification
- **Rationale:** Triggers ensure data consistency at database level, independent of application logic. Payment immutability is enforced by triggers.

**Indexes:**
- **Strategy:** Indexes on foreign keys, frequently queried columns, and search columns
- **Key Indexes:**
  - `profiles.user_id` (unique index for Supabase Auth lookup)
  - `profiles.phone` (unique index for phone-based login)
  - `profiles.role` (index for role-based queries)
  - `payments.customer_id` (index for customer payment history queries)
  - `payments.staff_id` (index for staff collection queries)
  - `payments.payment_date` (index for date-range queries)
  - `staff_assignments.staff_id` and `staff_assignments.customer_id` (indexes for assignment lookups)
- **Rationale:** Indexes improve query performance, especially for JOINs and WHERE clauses. Foreign key indexes are required for referential integrity checks.

**Read Replicas:**
- **Status:** Not implemented in Phase 1
- **Future Consideration:** Deploy read replica for reporting queries (financial dashboards, exports) if database becomes read-heavy
- **Strategy:** Supabase supports read replicas (manual setup, not automatic). Read replica can be used for read-only queries to reduce load on primary database.
- **Rationale:** Current scale doesn't require read replicas. Can be added if reporting queries cause performance issues.

**Caching Strategy:**
- **Database-Level:** No explicit caching layer (PostgreSQL query cache handles frequently accessed data)
- **Application-Level:** Client-side caching (React Query on website, Riverpod on mobile app) caches API responses
- **Future Consideration:** Redis cache for frequently accessed data (market rates, active schemes) if database queries become bottleneck
- **Rationale:** Client-side caching is sufficient for Phase 1. Database query cache provides additional performance. Redis can be added if needed.

**Data Retention Policy:**
- **Active Data:** All data retained indefinitely (no automatic deletion)
- **Soft Deletes:** Records marked as inactive (`active=false`, `status='cancelled'`) but not deleted (preserves audit trail)
- **Payment Immutability:** Payments are append-only (never deleted, reversals are new records with `is_reversal=true`)
- **Archival:** No automatic archival (all historical data retained in database)
- **Rationale:** Financial data requires long-term retention for audit purposes. Soft deletes preserve historical records. Payment immutability ensures audit trail integrity.

**Database Migrations:**
- **Tool:** Supabase CLI or SQL migration files
- **Version Control:** Migration files stored in repository (`supabase/migrations/` or `supabase_schema.sql`)
- **Idempotency:** All migrations are idempotent (safe to run multiple times, use `CREATE TABLE IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`)
- **Rationale:** Version-controlled migrations ensure schema consistency across environments. Idempotent migrations prevent errors on re-runs.

---

### Authentication Strategy

**Method:**
- **Primary:** Supabase Auth (JWT-based authentication)
- **Token Type:** JSON Web Token (JWT) - access token and refresh token
- **Session Management:** Supabase Auth SDK handles token storage, automatic refresh, and session persistence
- **Rationale:** JWT provides stateless authentication, scalable architecture, and secure token-based access. Supabase Auth handles token lifecycle automatically.

**Token Expiration:**
- **Access Token:** 1 hour (configurable in Supabase dashboard)
- **Refresh Token:** 30 days (configurable in Supabase dashboard)
- **Automatic Refresh:** Supabase SDK automatically refreshes access token when it expires (transparent to application)
- **Session Persistence:** Tokens stored in secure storage (mobile app: Flutter Secure Storage, website: HTTP-only cookies or localStorage)
- **Rationale:** Short access token lifetime reduces security risk if token is compromised. Long refresh token lifetime provides good user experience (users don't need to re-login frequently).

**Authentication Methods:**

**1. Customer Authentication (Mobile App):**
- **Method:** Phone + OTP (One-Time Password)
- **Flow:**
  1. User enters phone number
  2. System sends OTP via SMS (Supabase Auth SMS provider)
  3. User enters OTP
  4. System verifies OTP and creates/authenticates user
  5. User sets PIN (optional biometric authentication)
- **OTP Policy:** 6-digit OTP, 5-minute expiration, max 3 resend attempts per hour
- **Rationale:** Phone + OTP is user-friendly (no password to remember), secure (OTP expires quickly), and common in Indian market.

**2. Staff Authentication (Mobile App):**
- **Method:** Staff Code + Password
- **Flow:**
  1. User enters staff code
  2. System resolves staff code to email via RPC function `get_staff_email_by_code()`
  3. User enters password
  4. System authenticates via Supabase Auth `signInWithPassword()`
- **Rationale:** Staff code provides easy login (no email to remember), password provides security. RPC function enables staff code lookup without exposing email.

**3. Office Staff / Admin Authentication (Website):**
- **Method:** Email + Password
- **Flow:**
  1. User enters email and password
  2. System authenticates via Supabase Auth `signInWithPassword()`
- **Password Policy:** Minimum 8 characters, at least one uppercase, one lowercase, one number, one special character
- **Rationale:** Email + password is standard for web applications. Strong password policy ensures security.

**Single Sign-On (SSO):**
- **Status:** Not implemented in Phase 1
- **Future Consideration:** OAuth providers (Google, Microsoft) via Supabase Auth social providers
- **Rationale:** SSO can be added if business requires integration with external identity providers.

**Multi-Factor Authentication (MFA):**
- **Status:** Not required in Phase 1
- **Optional:** PIN + Biometric authentication on mobile app (local authentication, not MFA)
- **Future Consideration:** TOTP-based MFA (Google Authenticator, Authy) for admin accounts
- **Rationale:** Current security requirements don't mandate MFA. PIN + biometric provides additional security for mobile app.

**Session Security:**
- **Token Storage:** Secure storage (mobile app: Flutter Secure Storage, website: HTTP-only cookies preferred, localStorage as fallback)
- **Token Transmission:** HTTPS only (TLS 1.2+)
- **Token Validation:** Supabase validates JWT signature and expiration on every API request
- **Session Invalidation:** Sessions invalidated on logout, password change, or admin-initiated revocation
- **Rationale:** Secure token storage prevents token theft. HTTPS ensures secure transmission. Token validation ensures only valid tokens are accepted.

**Role-Based Access Control (RBAC):**
- **Enforcement:** Database-level (RLS policies) and application-level (UI hiding/disabled based on role)
- **Roles:** `customer`, `staff`, `admin` (stored in `profiles.role` column)
- **Role Hierarchy:** Admin > Office Staff > Collection Staff > Customer (permissions inherited downward)
- **Rationale:** RLS provides database-level security. Application-level RBAC provides UX (users don't see features they can't access).

---

### API Structure

**Base URL:**
- **Format:** `https://[project-ref].supabase.co/rest/v1/`
- **Example:** `https://abcdefghijklmnop.supabase.co/rest/v1/profiles`
- **Versioning:** URL-based versioning (`/rest/v1/` indicates API version 1)
- **Rationale:** URL-based versioning is explicit and allows multiple API versions to coexist. Supabase uses `/rest/v1/` as standard endpoint.

**Authentication Header:**
- **Format:** `Authorization: Bearer [access_token]`
- **Example:** `Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
- **Token Source:** Supabase Auth access token (JWT)
- **Required:** All authenticated endpoints require valid JWT token (except public endpoints like OTP request)
- **Rationale:** Bearer token authentication is standard for REST APIs. JWT provides stateless authentication.

**Response Format:**
- **Content-Type:** `application/json`
- **Structure:** JSON objects or arrays (PostgREST returns table rows as JSON objects, arrays for multiple rows)
- **Example Response (Single Row):**
  ```json
  {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "name": "John Doe",
    "phone": "+919876543210",
    "role": "customer",
    "active": true,
    "created_at": "2024-01-01T00:00:00Z"
  }
  ```
- **Example Response (Multiple Rows):**
  ```json
  [
    {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "name": "John Doe",
      ...
    },
    {
      "id": "223e4567-e89b-12d3-a456-426614174001",
      "name": "Jane Smith",
      ...
    }
  ]
  ```
- **Rationale:** JSON is standard, human-readable, and widely supported. PostgREST automatically serializes PostgreSQL rows to JSON.

**Error Response Format:**
- **HTTP Status Codes:** Standard HTTP status codes (200 OK, 201 Created, 400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found, 500 Internal Server Error)
- **Error Object Structure:**
  ```json
  {
    "message": "Error description",
    "code": "ERROR_CODE",
    "details": "Additional error details (optional)",
    "hint": "Helpful hint for resolving error (optional)"
  }
  ```
- **Example Error Response (400 Bad Request):**
  ```json
  {
    "message": "new row violates row-level security policy",
    "code": "42501",
    "details": "Policy violation: Staff can only insert payments for assigned customers",
    "hint": "Verify that customer is assigned to staff member"
  }
  ```
- **Example Error Response (401 Unauthorized):**
  ```json
  {
    "message": "JWT expired",
    "code": "PGRST301",
    "details": "Token has expired, please refresh"
  }
  ```
- **Rationale:** Standard HTTP status codes provide clear error categories. Structured error objects provide actionable error information.

**Versioning Strategy:**
- **Current Version:** v1 (URL-based: `/rest/v1/`)
- **Future Versions:** v2, v3, etc. (new versions added as `/rest/v2/`, `/rest/v3/`)
- **Backward Compatibility:** Maintain v1 endpoints when introducing v2 (deprecation period before removal)
- **Rationale:** URL-based versioning allows multiple API versions to coexist, enabling gradual migration.

**Rate Limiting:**
- **Authentication Endpoints:** 10 requests per minute per IP address (prevents brute force attacks)
- **Data Endpoints:** 100 requests per minute per authenticated user (prevents API abuse)
- **Payment Endpoints:** 20 requests per minute per authenticated user (prevents duplicate payments)
- **Enforcement:** Supabase enforces rate limits (configurable in Supabase dashboard)
- **Rate Limit Headers:** Response headers include rate limit information (`X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`)
- **Rationale:** Rate limiting prevents abuse, protects against DDoS attacks, and ensures fair resource usage.

**Pagination:**
- **Method:** Limit/offset pagination (PostgREST standard)
- **Query Parameters:**
  - `limit`: Number of rows to return (default: 100, max: 1000)
  - `offset`: Number of rows to skip (default: 0)
- **Example:** `GET /rest/v1/payments?limit=50&offset=0` (first 50 rows)
- **Response Headers:** `Content-Range` header indicates total count and range (e.g., `Content-Range: 0-49/1000`)
- **Rationale:** Limit/offset pagination is simple and widely supported. PostgREST provides built-in pagination support.

**Query Parameters (PostgREST):**
- **Filtering:** `?column=eq.value` (equals), `?column=gt.value` (greater than), `?column=lt.value` (less than), `?column=ilike.*value*` (case-insensitive like)
- **Sorting:** `?order=column.asc` or `?order=column.desc`
- **Selecting Columns:** `?select=column1,column2` (only return specified columns)
- **Joining:** `?select=*,related_table(*)` (join related table)
- **Example:** `GET /rest/v1/payments?customer_id=eq.123&payment_date=gte.2024-01-01&order=payment_date.desc&limit=50`
- **Rationale:** PostgREST provides powerful query capabilities via URL parameters, enabling flexible data retrieval without custom endpoints.

**RPC Functions:**
- **Endpoint Format:** `POST /rest/v1/rpc/[function_name]`
- **Request Body:** JSON object with function parameters
- **Example:** `POST /rest/v1/rpc/get_staff_email_by_code` with body `{"staff_code": "STAFF001"}`
- **Response:** JSON object or array (function return value)
- **Rationale:** RPC functions enable custom server-side logic (complex queries, business logic) while maintaining REST API structure.

---

## 7. INTEGRATIONS

### Payment Processing

**Status:** Not applicable (Phase 1)

**Rationale:** System does not directly process credit card payments. Payment methods are Cash, UPI, and Bank Transfer (handled externally). No cardholder data (CHD) stored or transmitted. Payments are recorded manually by collection staff (mobile app) or office staff (website) after receiving payment from customer.

**Future Consideration:** If credit card payment gateway integration is required in future phases, PCI DSS Level 1 compliance will be required (use PCI-compliant payment gateway like Stripe, Razorpay).

---

### Market Price API Integration

**Purpose:** Fetch daily gold and silver market rates from external API for automated rate updates

**Service Details:**
- **Provider:** External market price API (specific provider TBD - examples: Gold Price API, Silver Price API, commodity exchanges, financial data providers)
- **Integration Type:** REST API (HTTPS GET/POST requests)
- **Authentication:** API key-based authentication (API key stored in Supabase environment variables, encrypted)
- **Frequency:** Daily automated fetch (via scheduled job/cron task) or manual trigger by administrator
- **Data Fetched:**
  - Gold rate per gram (INR)
  - Silver rate per gram (INR)
  - Rate date/timestamp
  - Optional: historical rate data (if API supports)
- **Storage:** Fetched rates stored in `market_rates` table with `rate_date`, `gold_rate`, `silver_rate`
- **Fallback:** Manual rate entry available if API fetch fails or requires correction

**Failure Handling:**
- **Network failure:** Automatic retry (up to 3 attempts with exponential backoff: 1 min, 5 min, 15 min)
- **API unavailable:** System uses last available rate, displays warning "Using cached rate from [date]. API fetch failed." Admin can manually update rates
- **Invalid response:** System logs error, uses last available rate, notifies admin via dashboard alert. Admin can manually correct rates
- **Rate deviation:** If fetched rate deviates significantly from last rate (>10% change), system flags for admin review before auto-saving
- **Manual override:** Administrator can manually enter/correct rates via website if API fetch fails or requires adjustment

**Security:**
- API key stored in Supabase environment variables (encrypted, not exposed to client)
- API requests made server-side (via Supabase Edge Function or scheduled job) to prevent API key exposure
- Rate of limiting: Respects API provider rate limits (typically 100 requests/day for free tier)

**Implementation Notes:**
- Scheduled job/cron task runs daily at configured time (e.g., 9:00 AM IST) to fetch rates
- Edge Function or external cron service (e.g., GitHub Actions, cron-job.org) handles scheduled API calls
- Rate updates trigger real-time notifications to all connected clients (mobile app and website)

---

### Notifications

**Status:** In Scope (Phase 1) - Automated email/SMS notifications wherever required

| Channel | Provider | Trigger Events | Frequency Limits | Opt-out Options |
|---------|----------|-----------------|-----------------|-----------------|
| **Email** | Supabase Auth (built-in) or SendGrid/AWS SES (if advanced features needed) | OTP delivery, password reset, withdrawal status updates (approved, rejected, processed), scheme enrollment confirmation, payment reminders (optional), system alerts (admin only) | Max 20 emails per user per day (rate limiting to prevent spam) | User preference center (future enhancement), not configurable in Phase 1 |
| **SMS** | Supabase Auth SMS provider (Twilio or similar) | OTP delivery, withdrawal status updates (approved, rejected, processed), scheme enrollment confirmation, payment reminders (optional) | Max 5 SMS per user per day (rate limiting to prevent spam) | User preference center (future enhancement), not configurable in Phase 1 |
| **Push (Mobile)** | Firebase Cloud Messaging (FCM) / Apple Push Notification service (APNs) | Payment reminders, withdrawal status updates, scheme enrollment confirmation, market rate updates, system alerts | Max 10 push notifications per user per day (rate limiting) | App settings (user can disable push notifications in app preferences) |

**Automated Notification Triggers (Phase 1):**
- **Customer Notifications:**
  - OTP delivery (SMS) - during login
  - Scheme enrollment confirmation (SMS/Email) - when office staff enrolls customer
  - Withdrawal status updates (SMS/Email) - when withdrawal approved, rejected, or processed
  - Payment reminders (SMS/Push) - optional, if payment is overdue (future enhancement)
- **Staff Notifications:**
  - Daily target reminders (Push) - optional, to notify collection staff about daily targets
  - Assignment updates (Push) - when new customers assigned to collection staff
- **Admin Notifications:**
  - Market rate API fetch failure (Email) - if API fetch fails, notify admin
  - System alerts (Email) - critical system errors, database issues

**Implementation:**
- Email/SMS notifications handled via Supabase Auth (for OTP/password reset) and Supabase Edge Functions or external service (for business notifications)
- Push notifications implemented via Firebase Cloud Messaging (Android) and Apple Push Notification service (iOS)
- Notification templates stored in database or configuration files
- Notification logs stored in database for audit trail

---

### External Services & APIs

| Service | Purpose | Provider | Authentication | Failure Handling |
|---------|---------|----------|-----------------|-----------------|
| **Market Price API** | Fetch daily gold and silver market rates | External API provider (TBD - examples: Gold Price API, commodity exchanges) | API key (stored in Supabase environment variables) | Automatic retry (3 attempts with exponential backoff), manual override if API fails, use last cached rate as fallback |
| **SMS Provider (OTP)** | Send OTP for customer authentication | Supabase Auth SMS provider (Twilio or similar, configured in Supabase) | Managed by Supabase Auth | Automatic retry by Supabase Auth, fallback to alternative SMS provider if configured |
| **Email Provider** | Send email notifications (OTP, password reset, business notifications) | Supabase Auth email service or SendGrid/AWS SES (if advanced features needed) | Managed by Supabase Auth or API key for external provider | Automatic retry by email provider, fallback to alternative provider if configured |
| **Push Notification Service** | Send push notifications to mobile app | Firebase Cloud Messaging (Android), Apple Push Notification service (iOS) | Firebase service account key, Apple Push Notification certificate | Automatic retry by FCM/APNs, notification queued if device offline, delivery status tracked |

---

### Failure Handling Strategies

**General Failure Handling Principles:**
- **Graceful Degradation:** System continues to operate with reduced functionality when external services fail
- **User Notification:** Users are informed of failures with clear, actionable error messages
- **Automatic Retry:** Transient failures are automatically retried with exponential backoff
- **Manual Override:** Critical operations have manual fallback options (e.g., manual rate entry if API fails)
- **Audit Logging:** All failures are logged for monitoring and troubleshooting

**Market Price API Failure Handling:**
- **Network Failure:** Automatic retry (3 attempts: 1 min, 5 min, 15 min delay). If all retries fail, system uses last cached rate and notifies admin via email.
- **API Unavailable:** System uses last available rate, displays warning "Using cached rate from [date]. API fetch failed." Admin can manually update rates via website.
- **Invalid Response:** System logs error, uses last available rate, notifies admin via dashboard alert. Admin can manually correct rates.
- **Rate Deviation:** If fetched rate deviates significantly from last rate (>10% change), system flags for admin review before auto-saving. Admin can approve or reject rate update.
- **Manual Override:** Administrator can manually enter/correct rates via website if API fetch fails or requires adjustment.

**SMS/Email Notification Failure Handling:**
- **OTP Delivery Failure (SMS):** Automatic retry by Supabase Auth (up to 3 attempts). If all retries fail, user sees error message "OTP not received. Please try again." User can request new OTP after 60 seconds.
- **Email Delivery Failure:** Automatic retry by email provider (up to 3 attempts). If all retries fail, notification is logged and user is notified via alternative channel (SMS or push notification) if available.
- **Push Notification Failure:** Automatic retry by FCM/APNs (up to 3 attempts). If device is offline, notification is queued and delivered when device comes online. Delivery status is tracked for monitoring.
- **Rate Limiting:** If notification rate limits are exceeded, notifications are queued and delivered when rate limit resets. Critical notifications (OTP) bypass rate limits.

**Database Operation Failure Handling:**
- **Connection Failure:** Automatic retry (up to 3 attempts with exponential backoff: 1 sec, 2 sec, 4 sec). If all retries fail, user sees error message "Database connection failed. Please try again." with "Retry" button.
- **RLS Policy Violation:** User sees error message "You do not have permission to perform this action." Error is logged for security monitoring. User cannot retry (permission issue, not transient failure).
- **Constraint Violation:** User sees specific error message based on violation (e.g., "Phone number already exists", "Duplicate enrollment"). Error is logged. User can correct input and retry.
- **Trigger Failure:** Critical trigger failures (e.g., `update_user_scheme_totals` fails) are logged and admin is notified via email. Manual intervention may be required. Payment INSERT may succeed but totals may not update (requires manual correction).

**Offline Operation Failure Handling (Mobile App):**
- **Payment Recording (Offline):** Payments are queued in local storage. When connection restored, automatic sync attempts to upload queued payments. If sync fails, payment remains in queue for manual retry. User is notified of sync status.
- **Data Fetch (Offline):** App uses cached data if available. User sees "Last updated: [timestamp]" indicator. User can manually refresh when connection restored.
- **Offline Queue Full:** If offline queue reaches limit (100 payments), new payments are blocked. User sees warning "Offline queue is full. Please sync payments before recording more." User must sync existing payments before recording new ones.

**API Rate Limiting Failure Handling:**
- **Rate Limit Exceeded:** Request is queued and retried after rate limit window resets. User sees message "Rate limit exceeded. Please try again in a few moments." Critical operations (OTP) have higher rate limits or bypass limits.
- **API Key Expired/Invalid:** Admin is notified via email. System uses cached data if available. Admin must update API key in Supabase environment variables.

**Error Recovery Procedures:**
- **Automatic Recovery:** Transient failures (network, API unavailable) are automatically retried. System recovers without user intervention.
- **User-Initiated Recovery:** Users can manually retry failed operations via "Retry" button. Users can refresh data, sync offline queue, or request new OTP.
- **Admin-Initiated Recovery:** Admin can manually override/correct data if automatic recovery fails (e.g., manual rate entry, manual payment correction, manual enrollment creation).

---

## 8. DATA MODEL OVERVIEW

### Key Entities

| Entity | Primary Key | Key Attributes | Ownership | Access Rules |
|--------|-------------|-----------------|-----------|--------------|
| **profiles** | `id` (UUID) | `user_id` (FK to auth.users), `role` (customer/staff/admin), `phone`, `name`, `email`, `active` | Users own their own profile. System owns profile creation (via Supabase Auth). | Users can read/update own profile (limited fields: name, phone). Staff can read assigned customer profiles. Admin can read/update all profiles. RLS enforced. |
| **customers** | `id` (UUID) | `profile_id` (FK to profiles), `address`, `city`, `state`, `pincode`, `date_of_birth`, `pan_number`, `aadhaar_number`, `nominee_name`, `nominee_relation`, `nominee_phone` | Customers own their own customer record. Office staff create customer records during registration. | Customers can read/update own record (address, nominee details). Staff can read assigned customers. Office staff can read/update all customers. Admin can read/update all customers. RLS enforced. |
| **staff_metadata** | `id` (UUID) | `profile_id` (FK to profiles), `staff_code` (unique), `staff_type` (collection/office), `daily_target_amount`, `daily_target_customers`, `is_active`, `join_date` | Staff own their own metadata. Admin creates/manages staff records. | Staff can read own metadata (limited update). Admin can read/update all staff metadata. Unauthenticated users can lookup staff_code → email (for login). RLS enforced. |
| **schemes** | `id` (UUID) | `scheme_code` (unique), `name`, `asset_type` (gold/silver), `min_daily_amount`, `max_daily_amount`, `installment_amount`, `frequency`, `duration_months`, `entry_fee`, `expected_grams`, `active` | System owns scheme definitions. Admin creates/manages schemes. Schemes are immutable reference data (admin creates, never updates in practice). | Everyone can read active schemes. Staff can read all schemes (active and inactive). Admin can create/update/disable schemes. RLS enforced. |
| **user_schemes** | `id` (UUID) | `customer_id` (FK to customers), `scheme_id` (FK to schemes), `enrollment_date`, `status` (active/paused/completed/mature/cancelled), `payment_frequency`, `min_amount`, `max_amount`, `total_amount_paid`, `payments_made`, `accumulated_grams`, `maturity_date` | Customers own their enrollment records. Office staff create enrollments on behalf of customers. | Customers can read own enrollments (read-only). Staff can read assigned customers' enrollments. Office staff can create enrollments for any customer. Admin can read/update all enrollments. RLS enforced. Totals updated via database triggers. |
| **payments** | `id` (UUID) | `user_scheme_id` (FK to user_schemes), `customer_id` (FK to customers), `staff_id` (FK to profiles, nullable), `amount`, `gst_amount`, `net_amount`, `payment_method`, `payment_date`, `payment_time`, `status`, `metal_rate_per_gram`, `metal_grams_added`, `is_reversal`, `reverses_payment_id`, `receipt_number` | **APPEND-ONLY** - System owns payment records. Staff create payments for assigned customers. Office staff create payments for office collections. | Customers can read own payments (read-only). Staff can insert/read payments for assigned customers. Office staff can insert payments (staff_id = NULL). Admin can read all payments. **UPDATE/DELETE blocked by database triggers** (immutable for audit). RLS enforced. |
| **withdrawals** | `id` (UUID) | `user_scheme_id` (FK to user_schemes), `customer_id` (FK to customers), `withdrawal_type` (partial/full), `requested_amount`, `requested_grams`, `status` (pending/approved/processed/rejected/cancelled), `approved_by` (FK to profiles), `final_amount`, `final_grams` | Customers own their withdrawal requests. Staff approve/process withdrawals for assigned customers. | Customers can insert/read own withdrawals. Staff can read/update status for assigned customers' withdrawals. Admin can read/update all withdrawals. RLS enforced. |
| **market_rates** | `id` (UUID) | `rate_date`, `asset_type` (gold/silver), `price_per_gram`, `change_amount`, `change_percent`, `created_by` (FK to profiles) | System owns market rates (fetched from external API). Admin can manually override/correct rates. | Everyone can read current and historical rates. Admin can insert/update rates (via API fetch or manual entry). RLS enforced. |
| **staff_assignments** | `id` (UUID) | `staff_id` (FK to profiles), `customer_id` (FK to customers), `is_active`, `assigned_date`, `unassigned_date` | Admin owns staff assignments. Office staff may create assignments (if business rule allows). | Staff can read own assignments. Admin can create/update/deactivate all assignments. Office staff may create assignments (if permitted). RLS enforced. |
| **routes** | `id` (UUID) | `route_name`, `description`, `area_coverage`, `is_active` | Admin/Office staff own routes. | Office staff can create/read/update routes. Admin can create/read/update/deactivate all routes. RLS enforced (if implemented). |

### Relationships

**One-to-Many Relationships:**
- **profiles** → **customers** (one profile has one customer record via `profile_id`)
- **profiles** → **staff_metadata** (one profile has one staff_metadata record via `profile_id`)
- **profiles** → **payments** (one profile can have many payments as `staff_id`, nullable)
- **profiles** → **withdrawals** (one profile can approve many withdrawals as `approved_by`, nullable)
- **profiles** → **market_rates** (one profile can create many market rates as `created_by`, nullable)
- **profiles** → **staff_assignments** (one profile can have many assignments as `staff_id`)
- **customers** → **user_schemes** (one customer can have many scheme enrollments)
- **customers** → **payments** (one customer can have many payments)
- **customers** → **withdrawals** (one customer can have many withdrawal requests)
- **customers** → **staff_assignments** (one customer can have many staff assignments)
- **schemes** → **user_schemes** (one scheme can have many customer enrollments)
- **user_schemes** → **payments** (one enrollment can have many payments)
- **user_schemes** → **withdrawals** (one enrollment can have many withdrawal requests)
- **payments** → **payments** (one payment can reverse another payment via `reverses_payment_id`)

**Many-to-Many Relationships:**
- **profiles (staff)** ↔ **customers** (via `staff_assignments` table) - Many staff can be assigned to many customers

**Foreign Key Constraints:**
- `profiles.user_id` → `auth.users.id` (ON DELETE CASCADE) - If Supabase Auth user deleted, profile deleted
- `customers.profile_id` → `profiles.id` (ON DELETE CASCADE) - If profile deleted, customer record deleted
- `staff_metadata.profile_id` → `profiles.id` (ON DELETE CASCADE) - If profile deleted, staff_metadata deleted
- `user_schemes.customer_id` → `customers.id` (ON DELETE CASCADE) - If customer deleted, enrollments deleted
- `user_schemes.scheme_id` → `schemes.id` (ON DELETE RESTRICT) - Cannot delete scheme if enrollments exist
- `payments.user_scheme_id` → `user_schemes.id` (ON DELETE RESTRICT) - Cannot delete enrollment if payments exist
- `payments.customer_id` → `customers.id` (ON DELETE RESTRICT) - Cannot delete customer if payments exist
- `payments.staff_id` → `profiles.id` (ON DELETE SET NULL) - If staff deleted, payment staff_id set to NULL
- `payments.reverses_payment_id` → `payments.id` (ON DELETE RESTRICT) - Cannot delete payment if reversals exist
- `withdrawals.user_scheme_id` → `user_schemes.id` (ON DELETE RESTRICT) - Cannot delete enrollment if withdrawals exist
- `withdrawals.customer_id` → `customers.id` (ON DELETE RESTRICT) - Cannot delete customer if withdrawals exist
- `withdrawals.approved_by` → `profiles.id` (ON DELETE SET NULL) - If approver deleted, approved_by set to NULL
- `market_rates.created_by` → `profiles.id` (ON DELETE SET NULL) - If creator deleted, created_by set to NULL
- `staff_assignments.staff_id` → `profiles.id` (ON DELETE CASCADE) - If staff deleted, assignments deleted
- `staff_assignments.customer_id` → `customers.id` (ON DELETE CASCADE) - If customer deleted, assignments deleted

### Ownership Rules

**User-Owned Data:**
- **profiles:** Users own their own profile data. Users can update limited fields (name, phone). System creates profile during authentication.
- **customers:** Customers own their own customer record. Customers can update address and nominee details. Office staff create customer records during registration.
- **user_schemes:** Customers own their enrollment records (read-only access). Office staff create enrollments on behalf of customers.
- **payments:** Customers own their payment records (read-only access). Payments are created by staff or office staff on behalf of customers.
- **withdrawals:** Customers own their withdrawal requests. Customers can create and view withdrawal requests. Staff approve/process withdrawals.

**Staff-Owned Data:**
- **staff_metadata:** Staff own their own metadata (read-only access). Admin creates and manages staff records.
- **staff_assignments:** Staff can view their own assignments (read-only). Admin creates and manages assignments.

**System-Owned Data:**
- **schemes:** System owns scheme definitions. Admin creates and manages schemes. Schemes are immutable reference data (admin creates, never updates in practice).
- **market_rates:** System owns market rates (fetched from external API). Admin can manually override/correct rates if API fetch fails.
- **payments:** System owns payment records for audit purposes. Payments are append-only (immutable) - no updates or deletes allowed.

**Admin-Owned Data:**
- **All entities:** Admin has full read/write access to all entities for system management and oversight.

### Access Constraints

**Customer Access Constraints:**
- **profiles:** Customers can read/update own profile (limited fields: name, phone). Cannot view other customers' profiles.
- **customers:** Customers can read/update own customer record (address, nominee details). Cannot view other customers' records.
- **user_schemes:** Customers can read own enrollments (read-only). Cannot create enrollments (enrollment performed by office staff). Cannot view other customers' enrollments.
- **payments:** Customers can read own payments (read-only). Cannot create or modify payments. Cannot view other customers' payments.
- **withdrawals:** Customers can create and read own withdrawal requests. Cannot view other customers' withdrawals.
- **schemes:** Customers can read active schemes only (read-only). Cannot create or modify schemes.
- **market_rates:** Customers can read current and historical rates (read-only). Cannot create or modify rates.
- **staff_metadata:** Customers cannot access staff metadata.
- **staff_assignments:** Customers cannot access staff assignments.

**Collection Staff Access Constraints:**
- **profiles:** Staff can read own profile and assigned customer profiles. Cannot view other staff profiles or unassigned customer profiles.
- **customers:** Staff can read assigned customers only (filtered by `staff_assignments` where `is_active = true`). Cannot view unassigned customers.
- **user_schemes:** Staff can read assigned customers' enrollments. Cannot create enrollments. Cannot view unassigned customers' enrollments.
- **payments:** Staff can insert payments for assigned customers only (enforced by RLS policy `is_current_staff_assigned_to_customer()`). Can read assigned customers' payments. Cannot modify payments after creation (payments are append-only). Cannot view unassigned customers' payments.
- **withdrawals:** Staff can read assigned customers' withdrawals. Can update withdrawal status (approve/reject/process) for assigned customers. Cannot view unassigned customers' withdrawals.
- **schemes:** Staff can read all schemes (active and inactive). Cannot create or modify schemes.
- **market_rates:** Staff can read current and historical rates (read-only). Cannot create or modify rates.
- **staff_metadata:** Staff can read own metadata (read-only). Cannot view other staff metadata.
- **staff_assignments:** Staff can read own assignments only. Cannot create or modify assignments.

**Office Staff Access Constraints:**
- **profiles:** Office staff can read all customer profiles. Can update customer profiles (limited fields). Cannot view staff/admin profiles (unless admin).
- **customers:** Office staff can read/update all customer records. Can create new customer records.
- **user_schemes:** Office staff can create enrollments for any customer. Can read all enrollments. Can update enrollment status (if admin).
- **payments:** Office staff can insert payments for office collections (`staff_id = NULL`). Can read all payments. Cannot modify payments after creation (payments are append-only).
- **withdrawals:** Office staff can read all withdrawals. Can update withdrawal status (if admin or if assigned to customer).
- **schemes:** Office staff can read all schemes (read-only). Cannot create or modify schemes (admin-only).
- **market_rates:** Office staff can read current and historical rates (read-only). Cannot create or modify rates (rates fetched from external API or admin-only).
- **staff_metadata:** Office staff can read all staff metadata (read-only). Cannot create or modify staff metadata (admin-only).
- **staff_assignments:** Office staff can create/read/update assignments (if business rule allows). Can view all assignments.

**Administrator Access Constraints:**
- **All entities:** Admin has full read/write access to all entities (profiles, customers, staff_metadata, schemes, user_schemes, payments, withdrawals, market_rates, staff_assignments, routes).
- **payments:** Admin can read all payments. Cannot modify payments after creation (payments are append-only for audit compliance). Can insert payments.
- **RLS policies:** Admin cannot bypass RLS policies (enforced at database level). Admin access is granted via RLS policies using `is_admin()` function.

**Database-Level Constraints:**
- **Payment Immutability:** UPDATE and DELETE operations on `payments` table are blocked by database triggers (`prevent_payment_update`, `prevent_payment_delete`). Reversals are new INSERT records with `is_reversal = true`.
- **Referential Integrity:** Foreign key constraints prevent orphaned records. ON DELETE RESTRICT prevents deletion of parent records if child records exist (e.g., cannot delete scheme if enrollments exist).
- **Data Validation:** Check constraints enforce data integrity (e.g., `payments.amount > 0`, `user_schemes.max_amount >= min_amount`).
- **Unique Constraints:** Unique constraints prevent duplicates (e.g., `profiles.phone` unique, `staff_metadata.staff_code` unique, `market_rates(rate_date, asset_type)` unique).

---

## 9. DEPLOYMENT & ENVIRONMENTS

### Environment Configuration

| Environment | Purpose | Hosting | Database | Secrets Management |
|-------------|---------|---------|----------|-------------------|
| **Development** | Local development and testing by developers | Local machine (Flutter dev server, Next.js dev server) | Supabase Dev project (separate Supabase project for development) or Local PostgreSQL via Docker | `.env` files (not committed to repository, listed in `.gitignore`). `.env.example` template committed with placeholder values. |
| **Staging** | Pre-production testing, UAT (User Acceptance Testing), integration testing | Vercel (Next.js website), Firebase App Distribution (mobile app beta builds) | Supabase Staging project (separate Supabase project for staging, production-like database with test data) | Supabase environment variables (for database config), Vercel environment variables (for website), GitHub Secrets (for CI/CD). |
| **Production** | Live application for end users | Vercel (Next.js website), App Store / Google Play (mobile app), Supabase (backend) | Supabase Production project (managed PostgreSQL with backups, point-in-time recovery) | Supabase environment variables (encrypted), Vercel environment variables (encrypted), GitHub Secrets (for CI/CD), API keys stored in Supabase secrets manager. |

**Environment Isolation:**
- **Development:** Each developer has their own `.env` file with Supabase Dev project credentials. No shared development database (prevents data conflicts).
- **Staging:** Shared Supabase Staging project with test data. Staging database is reset/refreshed periodically from production schema (without sensitive data).
- **Production:** Dedicated Supabase Production project with production data. No direct access from development machines (access via Supabase dashboard only).

**Database Configuration:**
- **Development:** Supabase Free tier or Dev project (sufficient for development). Can be reset/truncated without impact.
- **Staging:** Supabase Pro tier (production-like performance and limits). Test data seeded from production schema structure.
- **Production:** Supabase Pro tier or higher (based on usage). Daily automated backups, point-in-time recovery enabled, read replicas available if needed.

### Hosting Assumptions

**Website Hosting:**
- **Primary:** Vercel (Next.js-optimized hosting platform)
  - **Rationale:** Zero-config deployment, automatic HTTPS, edge network, seamless Git integration, automatic scaling
  - **Deployment:** Automatic deployment on push to `main` branch (production) or `staging` branch (staging)
  - **CDN:** Vercel Edge Network (automatic, global CDN for static assets and API routes)
  - **Custom Domain:** Custom domain configuration via Vercel (e.g., `app.slgthangangal.com`)
  - **SSL/TLS:** Automatic SSL certificates via Vercel (Let's Encrypt)
- **Alternative:** Netlify or AWS Amplify (if Vercel unavailable, but not preferred)

**Mobile App Hosting:**
- **iOS Production:** Apple App Store
  - **Distribution:** App Store Connect (automatic distribution via TestFlight beta → App Store production)
  - **Requirements:** Apple Developer Account ($99/year), App Store Connect access, App Store review process
- **iOS Beta:** TestFlight (Apple's beta testing platform)
  - **Distribution:** Internal testing (up to 100 testers) and External testing (up to 10,000 testers)
- **Android Production:** Google Play Store
  - **Distribution:** Google Play Console (automatic distribution via Internal Testing → Closed Testing → Open Testing → Production)
  - **Requirements:** Google Play Developer Account ($25 one-time fee), Google Play Console access, Play Store review process
- **Android Beta:** Firebase App Distribution
  - **Distribution:** Internal testing for collection staff and beta testers
  - **Requirements:** Firebase project, Firebase App Distribution enabled

**Backend Hosting:**
- **Provider:** Supabase (managed backend-as-a-service)
- **Database:** Supabase managed PostgreSQL (hosted on AWS, GCP, or Azure, region: India or closest region)
- **API:** PostgREST (auto-generated REST API, hosted by Supabase)
- **Auth:** Supabase Auth (managed authentication service, hosted by Supabase)
- **Storage:** Supabase Storage (object storage for KYC documents, hosted by Supabase)
- **Realtime:** Supabase Realtime (PostgreSQL change streams, hosted by Supabase)
- **Edge Functions:** Supabase Edge Functions (Deno runtime, hosted by Supabase, if needed for scheduled jobs like market price API fetch)

**CDN:**
- **Website:** Vercel Edge Network (automatic, included with Vercel hosting)
- **Mobile App Assets:** App Store and Google Play handle app binary distribution (no separate CDN needed)
- **Static Assets:** Vercel Edge Network for website assets, Supabase Storage CDN for file uploads

**Monitoring & Analytics:**
- **Website:** Vercel Analytics (built-in, automatic), optional: external monitoring (Sentry, Datadog)
- **Mobile App:** Firebase Analytics (if implemented), App Store Connect Analytics, Google Play Console Analytics
- **Backend:** Supabase Dashboard (built-in logging and monitoring), optional: external monitoring (Sentry, Datadog)

### CI/CD Expectations

**Repository:**
- **Primary:** GitHub (private repository)
- **Alternative:** GitLab or Bitbucket (if GitHub unavailable)
- **Branching Strategy:** Git Flow or GitHub Flow
  - **Main branches:** `main` (production), `staging` (staging), `develop` (development)
  - **Feature branches:** `feature/feature-name` (branched from `develop`, merged back via Pull Request)
  - **Hotfix branches:** `hotfix/issue-name` (branched from `main`, merged back to `main` and `develop`)

**CI/CD Tool:**
- **Primary:** GitHub Actions (built-in CI/CD for GitHub repositories)
- **Alternative:** GitLab CI (if using GitLab) or CircleCI (if external CI/CD needed)

**CI/CD Pipeline (GitHub Actions):**

**Website (Next.js) Pipeline:**
1. **Trigger:** On push to `staging` or `main` branch, or on Pull Request
2. **Steps:**
   - **Lint:** Run ESLint and TypeScript type checking
   - **Test:** Run unit tests (Vitest) and component tests (React Testing Library)
   - **Build:** Build Next.js production bundle
   - **Deploy:** Deploy to Vercel (staging or production environment)
   - **Notification:** Send deployment status to Slack/email (optional)

**Mobile App (Flutter) Pipeline:**
1. **Trigger:** On push to `staging` or `main` branch, or on Pull Request, or manual trigger
2. **Steps:**
   - **Setup:** Install Flutter SDK, set up Android/iOS build tools
   - **Lint:** Run Dart analysis (`flutter analyze`)
   - **Test:** Run unit tests (`flutter test`) and widget tests
   - **Build:** Build APK (Android) or IPA (iOS) using `flutter build apk --release` or `flutter build ipa --release`
   - **Deploy (Staging):** Upload to Firebase App Distribution (Android) or TestFlight (iOS)
   - **Deploy (Production):** Upload to Google Play Console (Android) or App Store Connect (iOS) for review
   - **Notification:** Send build status to Slack/email (optional)

**Backend (Supabase) Pipeline:**
1. **Trigger:** On push to `main` branch, or manual trigger
2. **Steps:**
   - **Validate:** Validate SQL migration files (syntax checking)
   - **Apply Migrations:** Apply database migrations to Supabase Production project (via Supabase CLI or GitHub Actions)
   - **Verify:** Verify migration success (check for errors, verify schema)
   - **Notification:** Send migration status to Slack/email (optional)

**Deployment Triggers:**
- **Automatic:** On merge to `main` branch (production deployment), on merge to `staging` branch (staging deployment)
- **Manual:** Via GitHub Actions workflow dispatch (for emergency deployments or rollbacks)
- **Scheduled:** Daily market price API fetch (via Supabase Edge Function scheduled job or GitHub Actions cron)

**Testing Requirements:**
- **Unit Tests:** Must pass (Flutter: `flutter test`, Next.js: `npm test`). Minimum 70% code coverage (goal, not enforced in Phase 1).
- **Integration Tests:** Must pass (if implemented). Integration tests verify critical user flows (login, payment recording, enrollment).
- **E2E Tests:** Optional in Phase 1 (can be added in later phases). E2E tests verify complete user journeys.
- **Linting:** Code must pass linting checks (Dart analysis, ESLint, TypeScript checks). No linting errors allowed.

**Approval Process:**
- **Staging Deployment:** Automatic on merge to `staging` branch (no approval required)
- **Production Deployment:** 
  - **Website:** Automatic on merge to `main` branch (Vercel handles deployment)
  - **Mobile App:** Manual approval required via GitHub Actions workflow dispatch or App Store/Play Store review process (human review)
  - **Database Migrations:** Manual approval required via Pull Request review (at least one approval from senior developer or admin)

**Rollback Procedures:**
- **Website:** Instant rollback via Vercel dashboard (previous deployment available for instant rollback)
- **Mobile App:** Version rollback requires new app release (cannot rollback existing app version once published). Hotfix releases can be accelerated via App Store/Play Store fast-track review.
- **Database Migrations:** Rollback via reverse migration scripts (manual process, requires careful testing)

### Environment Variables & Secrets

**Mobile App (Flutter) Environment Variables:**

| Variable | Development | Staging | Production | Sensitivity |
|----------|-------------|---------|------------|-------------|
| `SUPABASE_URL` | `https://[dev-project-ref].supabase.co` | `https://[staging-project-ref].supabase.co` | `https://[prod-project-ref].supabase.co` | Public (embedded in app binary, can be reverse-engineered) |
| `SUPABASE_ANON_KEY` | Dev project anon key | Staging project anon key | Production project anon key | Public (embedded in app binary, can be reverse-engineered, protected by RLS) |
| `MARKET_PRICE_API_KEY` | N/A (not used in dev) | Staging API key (if available) | Production API key | Sensitive (if embedded, consider server-side fetch only) |
| `MARKET_PRICE_API_URL` | N/A (not used in dev) | Staging API endpoint | Production API endpoint | Public (API endpoint URL) |
| `FIREBASE_API_KEY` | Dev Firebase project key | Staging Firebase project key | Production Firebase project key | Public (if push notifications implemented) |
| `FIREBASE_PROJECT_ID` | Dev Firebase project ID | Staging Firebase project ID | Production Firebase project ID | Public (if push notifications implemented) |

**Website (Next.js) Environment Variables:**

| Variable | Development | Staging | Production | Sensitivity |
|----------|-------------|---------|------------|-------------|
| `NEXT_PUBLIC_SUPABASE_URL` | `https://[dev-project-ref].supabase.co` | `https://[staging-project-ref].supabase.co` | `https://[prod-project-ref].supabase.co` | Public (exposed to client, can be reverse-engineered) |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Dev project anon key | Staging project anon key | Production project anon key | Public (exposed to client, can be reverse-engineered, protected by RLS) |
| `SUPABASE_SERVICE_ROLE_KEY` | N/A (not used in client) | N/A (not used in client) | N/A (not used in client) | Sensitive (server-side only, never exposed to client, stored in Vercel environment variables) |
| `MARKET_PRICE_API_KEY` | N/A (not used in dev) | Staging API key | Production API key | Sensitive (server-side only, stored in Vercel environment variables) |
| `MARKET_PRICE_API_URL` | N/A (not used in dev) | Staging API endpoint | Production API endpoint | Public (API endpoint URL) |

**Backend (Supabase) Secrets (Stored in Supabase Dashboard):**

| Variable | Development | Staging | Production | Sensitivity |
|----------|-------------|---------|------------|-------------|
| Database connection string | Dev project connection string | Staging project connection string | Production project connection string | Sensitive (not exposed to application, managed by Supabase) |
| JWT secret | Dev project JWT secret | Staging project JWT secret | Production project JWT secret | Sensitive (managed by Supabase, not accessible to application) |
| SMTP credentials | Dev SMTP config (if custom email) | Staging SMTP config | Production SMTP config | Sensitive (stored in Supabase Auth settings, not accessible to application) |
| SMS provider credentials | Dev SMS config (Twilio, etc.) | Staging SMS config | Production SMS config | Sensitive (stored in Supabase Auth settings, not accessible to application) |

**Secrets Management Strategy:**

**Development:**
- **Method:** `.env` files in project root (not committed to repository)
- **Template:** `.env.example` committed with placeholder values (no actual secrets)
- **Gitignore:** `.env` and `.env.*` listed in `.gitignore` to prevent accidental commits
- **Access:** Each developer has their own `.env` file with Supabase Dev project credentials

**Staging:**
- **Method:** Vercel environment variables (for website), Supabase environment variables (for database), GitHub Secrets (for CI/CD)
- **Access:** Developers with staging access can view/edit environment variables via Vercel dashboard and Supabase dashboard
- **Rotation:** Secrets rotated quarterly or on security incident

**Production:**
- **Method:** Vercel environment variables (encrypted at rest), Supabase environment variables (encrypted at rest), GitHub Secrets (encrypted at rest)
- **Access:** Only administrators and senior developers have access to production environment variables
- **Rotation:** 
  - API keys rotated every 90 days (manual process)
  - Database credentials rotated by Supabase automatically (transparent to application)
  - JWT secrets rotated by Supabase automatically (transparent to application)
- **Audit:** All changes to production secrets are logged and audited (Vercel audit log, Supabase audit log)

**Security Best Practices:**
- **Never commit secrets:** `.env` files never committed to repository. Use `.env.example` as template.
- **Least privilege:** Only necessary secrets exposed to each environment (staging doesn't need production secrets)
- **Encryption:** All secrets encrypted at rest (Vercel, Supabase, GitHub Secrets)
- **Rotation:** Regular rotation of API keys and credentials (90 days for API keys, automatic for database credentials)
- **Monitoring:** Failed authentication attempts logged and monitored (Supabase Auth logs)
- **Backup:** Secrets backed up securely (encrypted backup stored in secure location, only for disaster recovery)

---

## 10. ASSUMPTIONS & CONSTRAINTS

### Business Assumptions

**User Behavior Assumptions:**
- **Customers will use mobile app for self-service:** Customers will primarily use the mobile app to view their investment portfolio, payment history, and request withdrawals. Customers will not need access to the website (website is for office staff and admin only).
- **Customers will accept OTP-based authentication:** Customers are comfortable with phone number + OTP authentication flow. PIN setup is acceptable for subsequent logins. Biometric authentication is optional but desirable.
- **Staff will have reliable mobile internet:** Collection staff will have mobile internet connectivity (3G/4G) in field areas to record payments. Offline capability is required as fallback for poor connectivity areas.
- **Office staff will use desktop workstations:** Office staff will primarily access the website from desktop or laptop computers during business hours. Mobile-responsive design is required for tablet use.
- **Admin will need comprehensive financial visibility:** Administrators will need real-time financial dashboards and reports to make business decisions. Financial data accuracy is critical.

**Market & Growth Assumptions:**
- **Steady customer growth:** Customer base will grow at 100-150 new enrollments per month (Year 1), 150-200 per month (Year 2), 200-250 per month (Year 3). Growth is linear and predictable.
- **Payment collection volume:** Average 10,000-15,000 payments per month in Year 1, 30,000-40,000 per month in Year 2, 60,000-80,000 per month in Year 3. Payment volume grows proportionally with customer base.
- **Staff scalability:** Collection staff will scale from 10-20 staff (Year 1) to 30-50 staff (Year 3). Office staff will scale from 3-5 staff (Year 1) to 8-12 staff (Year 3). Staff onboarding is gradual and manageable.
- **Market rate availability:** External market price API will be available and reliable for daily rate updates. Manual rate entry is acceptable fallback if API unavailable.

**Business Process Assumptions:**
- **Office staff will handle customer enrollment:** Office staff will handle all customer registrations and scheme enrollments in-person or via phone. Customers will not enroll themselves via mobile app.
- **Payment collection via field staff:** Collection staff will collect payments in the field and record them via mobile app. Office staff will record office collections manually via website.
- **Withdrawal processing:** Withdrawal requests will be reviewed and processed by office staff or admin. Withdrawal processing is manual (not automated) in Phase 1.
- **Report generation:** Basic reports (daily, weekly, monthly) are sufficient for Phase 1. Advanced analytics and predictive modeling are deferred to later phases.
- **No direct payment gateway integration:** Payments are recorded manually after receiving cash/UPI/bank transfer. No credit card payment gateway integration required in Phase 1.

**Regulatory & Compliance Assumptions:**
- **Financial data retention:** Financial data (payments, withdrawals) must be retained indefinitely for audit purposes. Payment records are immutable (append-only).
- **KYC compliance:** Customer KYC data (name, address, nominee, identity documents) must be collected and stored securely. KYC document upload is optional but recommended.
- **Data privacy:** Customer data is private and must be protected. Only authorized staff can access customer data. GDPR-style data deletion requests can be handled via soft delete (preserve audit trail).

### Technical Constraints

**Platform Constraints:**
- **Flutter platform support:** Flutter supports iOS 13.0+ and Android 8.0+ only. Older devices are not supported. Minimum device requirements: 2GB RAM, 16GB storage.
- **Supabase limitations:** 
  - **Database size:** Supabase Free tier has 500MB database limit (upgrade to Pro tier for larger databases)
  - **API rate limits:** Supabase has API rate limits (Free tier: 2 million monthly API requests, Pro tier: 50 million)
  - **Storage limits:** Supabase Storage has size limits (Free tier: 1GB, Pro tier: 100GB)
  - **Edge Functions:** Edge Functions have execution time limits (Free tier: 10 seconds, Pro tier: 60 seconds)
- **Vercel limitations:**
  - **Build time:** Vercel has build time limits (Hobby: 45 minutes, Pro: 45 minutes)
  - **Function execution time:** Serverless functions have execution time limits (Hobby: 10 seconds, Pro: 60 seconds)
  - **Bandwidth:** Vercel has bandwidth limits (Hobby: 100GB/month, Pro: 1TB/month)

**Database Constraints:**
- **PostgreSQL version:** Supabase uses PostgreSQL 15+ (cannot downgrade to older versions)
- **RLS enforcement:** Row Level Security (RLS) is enforced at database level. Cannot bypass RLS from application code (SECURITY DEFINER functions are exception).
- **Trigger limitations:** Database triggers have performance implications. Complex triggers may slow down INSERT operations. Trigger execution is synchronous (blocks INSERT until trigger completes).
- **Foreign key constraints:** Foreign key constraints enforce referential integrity. ON DELETE RESTRICT prevents deletion of parent records if child records exist (requires careful deletion order).

**Network & Connectivity Constraints:**
- **Mobile internet reliability:** Mobile internet connectivity may be unreliable in rural/field areas. Offline capability is required for critical operations (payment recording).
- **API rate limits:** External APIs (market price API, SMS provider, email provider) have rate limits. System must handle rate limit exceeded scenarios gracefully.
- **Bandwidth constraints:** Mobile app downloads and updates require sufficient bandwidth. App size should be minimized (<100MB for initial download).

**Data Constraints:**
- **Payment immutability:** Payments are append-only (immutable) for audit compliance. Updates and deletes are blocked by database triggers. Reversals must be new INSERT records with `is_reversal=true`.
- **Offline queue size:** Offline payment queue has storage limit (100 payments). Queue full scenario must be handled gracefully.
- **Data retention:** Historical data must be retained indefinitely. No automatic data purging or archival (requires manual process if needed).

**Security Constraints:**
- **RLS policies:** Row Level Security (RLS) is enforced at database level. Application code cannot bypass RLS (except SECURITY DEFINER functions). All queries must pass RLS policy checks.
- **JWT token expiration:** JWT access tokens expire after 1 hour. Refresh tokens expire after 30 days. Token expiration may cause session expiry during long operations.
- **API key exposure:** Supabase anon key is embedded in mobile app binary and exposed in website client code. Anon key is protected by RLS, but reverse engineering is possible. Service role key must never be exposed to client.
- **Secrets management:** Secrets (API keys, database credentials) must be stored securely. `.env` files cannot be committed to repository. Secrets must be rotated regularly.

**Development Constraints:**
- **Code generation:** Flutter code generation (e.g., `flutter pub get`, `flutter pub run build_runner build`) required for some packages. Build process must account for code generation time.
- **Hot reload limitations:** Hot reload may not work for certain changes (state management changes, native code changes). Full restart may be required.
- **Platform-specific code:** iOS and Android have platform-specific requirements (e.g., iOS requires Apple Developer Account for testing, Android requires Google Play Console for distribution).

### Dependencies

**External Services & APIs (Required):**
- **Supabase (Backend):** Required for database, authentication, storage, and API. System cannot operate without Supabase. Supabase availability and performance directly impact application availability.
  - **SLA:** Supabase Pro tier has 99.95% uptime SLA
  - **Failure Impact:** If Supabase is unavailable, entire system is unavailable (no offline mode for most operations)
  - **Mitigation:** Monitor Supabase status, use Supabase status page, have disaster recovery plan
- **Market Price API (External):** Required for daily gold and silver rate updates. System can operate with cached rates if API unavailable, but manual rate entry may be required.
  - **SLA:** Depends on API provider (TBD)
  - **Failure Impact:** Market rates may become stale if API unavailable. Admin can manually update rates.
  - **Mitigation:** Use last cached rate, manual rate entry fallback, retry logic
- **SMS Provider (via Supabase Auth):** Required for OTP delivery. System cannot authenticate customers if SMS provider unavailable.
  - **SLA:** Managed by Supabase (Twilio or similar provider)
  - **Failure Impact:** Customer login fails if OTP cannot be delivered. Staff login (password-based) unaffected.
  - **Mitigation:** Automatic retry by Supabase Auth, alternative SMS provider if configured
- **Email Provider (via Supabase Auth):** Required for password reset, business notifications. System can operate without email, but user experience degraded.
  - **SLA:** Managed by Supabase
  - **Failure Impact:** Password reset unavailable, notifications not delivered
  - **Mitigation:** Automatic retry by email provider, alternative email provider if configured

**Third-Party Libraries & Tools (Required):**
- **Flutter SDK 3.24+:** Required for mobile app development. Cannot use older Flutter versions (breaking changes, security updates).
  - **Dependency:** Dart SDK 3.10.1+
  - **Updates:** Flutter updates may require code changes (migration guides available)
- **Next.js 14+:** Required for website development. Next.js updates may require code changes (migration guides available).
- **Supabase Flutter SDK 2.10.3+:** Required for mobile app integration with Supabase. SDK updates may require code changes.
- **Supabase JavaScript SDK:** Required for website integration with Supabase. SDK updates may require code changes.
- **React Query (TanStack Query) v5+:** Required for website server state management. Breaking changes in major version updates.
- **Riverpod 2.5.1+:** Required for mobile app state management. Breaking changes in major version updates.
- **Firebase (if push notifications implemented):** Required for push notifications (Firebase Cloud Messaging for Android, Apple Push Notification service for iOS). Firebase updates may require code changes.

**Infrastructure Dependencies (Required):**
- **Vercel:** Required for website hosting. Website cannot be deployed without Vercel (or alternative hosting platform).
  - **SLA:** Vercel Pro tier has 99.9% uptime SLA
  - **Failure Impact:** Website unavailable if Vercel is down
  - **Mitigation:** Monitor Vercel status, have alternative hosting option (Netlify, AWS Amplify)
- **Apple App Store / Google Play Store:** Required for mobile app distribution. Mobile app cannot be distributed without app stores.
  - **SLA:** Managed by Apple/Google (highly available)
  - **Failure Impact:** App updates cannot be published if app stores are down (rare occurrence)
  - **Mitigation:** Monitor app store status, have beta distribution channels (TestFlight, Firebase App Distribution)
- **GitHub (or GitLab/Bitbucket):** Required for code repository and CI/CD. Development workflow depends on version control.
  - **SLA:** GitHub has 99.95% uptime SLA
  - **Failure Impact:** CI/CD pipeline unavailable if GitHub is down, but development can continue locally
  - **Mitigation:** Local Git backup, alternative repository (GitLab, Bitbucket)

**Team & Organizational Dependencies:**
- **Apple Developer Account:** Required for iOS app distribution ($99/year). Cannot publish iOS app without Apple Developer Account.
- **Google Play Developer Account:** Required for Android app distribution ($25 one-time fee). Cannot publish Android app without Google Play Developer Account.
- **Supabase Account:** Required for backend hosting. Supabase Free tier sufficient for development, Pro tier required for production.
- **Market Price API Account:** Required for daily rate updates. API provider and pricing TBD (may have free tier or paid subscription).

**Data Dependencies:**
- **Customer KYC data:** Customer registration requires KYC information (name, phone, address, nominee details). KYC data must be accurate and complete.
- **Scheme definitions:** 18 investment schemes (9 Gold, 9 Silver) must be defined and seeded in database before customer enrollment can begin.
- **Staff records:** Staff members must be created in database before staff can access mobile app or website.

**Timeline Dependencies:**
- **Phase 1 completion depends on:** Supabase setup, database schema deployment, Flutter app development, Next.js website development, app store submission and approval (may take 1-2 weeks for review).
- **Market price API integration:** Market price API integration depends on API provider selection and account setup (may delay daily rate automation).
- **Push notifications:** Push notification implementation depends on Firebase setup and Apple/Google developer account configuration (deferred to Phase 2 if needed).

---

## 11. RISKS & MITIGATION

| Risk Category | Risk Description | Probability | Impact | Mitigation Strategy |
|---------------|------------------|-------------|--------|-------------------|
| **Technical** | **Supabase service outage or degradation** - Database, API, or Auth service unavailable, causing entire system to be unavailable | Medium | High | Monitor Supabase status page, implement health checks, use Supabase Pro tier (99.95% SLA), have disaster recovery plan, consider read replicas for critical queries. Mobile app offline mode for payment recording reduces impact. |
| **Technical** | **Database trigger failure** - Payment INSERT succeeds but `update_user_scheme_totals` trigger fails to update `user_schemes` totals, causing data inconsistency | Low | High | Monitor trigger execution, log trigger failures, alert admin on trigger errors, implement manual reconciliation process, add trigger execution verification in payment recording flow. Test triggers thoroughly in staging before production. |
| **Technical** | **RLS policy violations** - Staff cannot insert payments due to RLS policy blocking, even though customer is assigned (circular dependency or policy bug) | Low | High | Test RLS policies thoroughly in staging, use SECURITY DEFINER functions to break circular dependencies, implement fallback error handling, log all RLS violations for monitoring, have admin override capability for critical situations. |
| **Technical** | **Payment immutability bypass** - Payment records modified or deleted due to trigger failure or malicious access, causing audit trail corruption | Low | Critical | Enforce payment immutability at multiple layers (database triggers, RLS policies, application checks), monitor UPDATE/DELETE attempts, log all modification attempts, implement audit logging for payment changes, regular audit checks. |
| **Technical** | **Session expiration during long operations** - JWT access token expires (1 hour) during long-running operations (batch payment entry, bulk enrollment), causing operation failure | Medium | Medium | Implement automatic token refresh before expiration, handle token expiry gracefully with user-friendly error messages, split long operations into smaller batches, refresh token before starting long operations. |
| **Technical** | **Offline sync conflicts** - Payment recorded offline synced successfully, but duplicate payment created due to race condition or sync conflict, causing duplicate charges | Low | Medium | Implement unique receipt ID validation before sync, check for duplicate payments (same customer, same amount, same date) before inserting, display warning if duplicate detected, require user confirmation before syncing duplicate. |
| **Technical** | **Market price API failure** - External API unavailable or returns invalid data, causing stale rates or payment calculation errors | Medium | Medium | Use cached last available rate with warning indicator, implement automatic retry (3 attempts with exponential backoff), allow admin manual rate override, validate API response before saving, flag rate deviations (>10% change) for admin review. |
| **Technical** | **Mobile app build failures** - Flutter build fails due to dependency conflicts, platform-specific issues, or CI/CD configuration errors, delaying releases | Medium | Low | Maintain stable dependency versions, test builds regularly, use Flutter version pinning, implement CI/CD build verification, have rollback plan for dependency updates, maintain build documentation. |
| **Technical** | **Database performance degradation** - Database queries slow down as data grows (10,000+ payments, 1,000+ customers), causing poor user experience | Medium | Medium | Implement database indexes on frequently queried columns, use pagination for large data sets, implement query optimization, monitor query performance, add read replicas if needed, implement caching layer if performance becomes bottleneck. |
| **Technical** | **Third-party SDK breaking changes** - Supabase SDK, Flutter SDK, or other critical dependencies release breaking changes, requiring code updates | Low | Medium | Pin dependency versions to stable releases, test dependency updates in staging before production, monitor dependency changelogs, maintain migration plan for major version updates, keep dependencies updated regularly to avoid large migration efforts. |
| **Technical** | **API rate limiting exceeded** - Supabase API rate limits exceeded (2M requests/month for Free tier, 50M for Pro tier), causing API calls to be throttled or blocked | Low | Medium | Monitor API usage, upgrade to Pro tier if approaching limits, implement client-side caching to reduce API calls, optimize queries to reduce request count, implement rate limiting awareness in application code. |
| **Technical** | **Mobile app storage limits** - Offline payment queue exceeds device storage limits, preventing new offline payments | Low | Low | Implement queue size limit (100 payments), monitor queue size, display warning when queue full, automatically sync queue when size reaches threshold, clear synced payments from queue. |
| **Product** | **Customer enrollment errors** - Office staff makes errors during enrollment (wrong scheme, wrong amount, wrong customer), causing customer dissatisfaction and data inconsistency | Medium | Medium | Implement enrollment validation (amount range, scheme availability, customer eligibility), require confirmation dialog before enrollment, allow enrollment editing/cancellation within grace period (24 hours), implement enrollment audit log, provide enrollment review process. |
| **Product** | **Payment recording errors** - Staff records wrong payment amount or wrong customer, causing financial discrepancies | Medium | High | Require confirmation dialog before payment recording, display customer and scheme details clearly, implement payment validation (amount within range, customer has active scheme), allow payment reversal process, implement payment audit log, require approval for large payments (optional). |
| **Product** | **Withdrawal processing delays** - Withdrawal requests not processed promptly, causing customer dissatisfaction | Medium | Medium | Implement withdrawal status notifications (SMS/Email), display withdrawal processing time estimate, provide withdrawal status tracking, implement escalation process for delayed withdrawals, monitor withdrawal processing times. |
| **Product** | **Data inconsistency** - Customer data, payment data, or enrollment data becomes inconsistent due to partial updates or failed transactions | Low | High | Implement database transactions for multi-step operations, use database triggers for automatic consistency, implement data validation checks, monitor data consistency, implement reconciliation process for detecting inconsistencies. |
| **Product** | **User adoption resistance** - Staff or customers resist using new digital system, preferring manual processes | Medium | Medium | Provide comprehensive training for staff, create user guides and tutorials, implement user-friendly UI/UX, gather user feedback and iterate, provide support during transition period, demonstrate benefits of digital system. |
| **Product** | **Feature gaps** - Critical features missing or not meeting user expectations, causing dissatisfaction or workflow disruptions | Medium | Medium | Gather user requirements early, conduct user testing before launch, implement feedback loop, prioritize critical features for Phase 1, document known limitations, plan feature enhancements for later phases. |
| **Operational** | **Staff training and onboarding** - New staff members struggle to use mobile app or website effectively, causing errors and inefficiency | Medium | Medium | Provide comprehensive training materials (video tutorials, written guides), conduct training sessions for new staff, implement in-app help and tooltips, provide ongoing support, monitor user activity and provide additional training if needed. |
| **Operational** | **Customer support burden** - Increased support requests due to app usage issues, password resets, or feature questions, overwhelming support team | Medium | Low | Implement self-service features (password reset, FAQ, help documentation), provide in-app help and tooltips, create user guides, implement support ticket system, monitor common issues and update documentation. |
| **Operational** | **Data backup and recovery** - Database backup failure or recovery process issues, causing data loss or extended downtime | Low | Critical | Implement automated daily backups (Supabase managed), test backup restoration regularly (quarterly), implement point-in-time recovery (7 days retention), document recovery procedures, have disaster recovery plan, test disaster recovery procedures annually. |
| **Operational** | **App store review delays** - iOS App Store or Google Play Store review delays or rejections, delaying app releases | Medium | Low | Follow app store guidelines strictly, test app thoroughly before submission, respond to review feedback promptly, maintain app store metadata and screenshots, have alternative distribution channels (TestFlight, Firebase App Distribution) for critical updates. |
| **Operational** | **Market price API provider change** - Current market price API provider discontinues service or changes pricing, requiring migration to new provider | Low | Medium | Research multiple API providers, implement abstraction layer for API calls, maintain manual rate entry fallback, document API integration process, have migration plan ready, test new provider in staging before production. |
| **Operational** | **Supabase pricing increase** - Supabase pricing increases beyond budget, requiring migration to alternative backend or cost optimization | Low | Medium | Monitor Supabase usage and costs, optimize API calls and database usage, implement caching to reduce costs, research alternative backends (self-hosted PostgreSQL, AWS RDS), have migration plan ready, budget for cost increases. |
| **Operational** | **Security incident** - Data breach, unauthorized access, or security vulnerability discovered, causing data exposure or system compromise | Low | Critical | Implement security best practices (RLS, encryption, secure secrets management), conduct security audits regularly, monitor security logs, implement intrusion detection, have incident response plan, report security incidents promptly, notify affected users if data breach occurs. |
| **Operational** | **Staff turnover** - Key staff members leave, causing knowledge loss and operational disruption | Medium | Medium | Document all processes and procedures, maintain up-to-date documentation, conduct knowledge transfer sessions, implement user access management (deactivate accounts on departure), provide training for new staff, maintain institutional knowledge in documentation. |
| **Operational** | **Scalability issues** - System cannot handle increased load (100+ concurrent users, 10,000+ payments/month), causing performance degradation | Low | Medium | Monitor system performance and usage, implement performance optimization, scale Supabase tier if needed, implement read replicas if database becomes bottleneck, optimize queries and caching, plan for horizontal scaling if needed. |

---

## 12. DELIVERABLES & MILESTONES

### Phase 1: Foundation & Core Features (Duration: 8-10 weeks)

**Objective:** Build and deploy core system with essential features for customers and staff, establishing baseline functionality for production use.

**Deliverables:**

1. **Database & Backend Infrastructure**
   - Supabase production project setup with all environments (dev, staging, production)
   - Complete database schema deployed (`supabase_schema.sql` with all tables, RLS policies, triggers, functions)
   - 18 investment schemes seeded in database (9 Gold, 9 Silver)
   - Initial staff records created (admin, office staff, collection staff)
   - Market rates table initialized with current rates

2. **Mobile Application (Flutter) - Customer Features**
   - Customer authentication (OTP, PIN, biometric)
   - Customer dashboard with investment overview
   - Scheme browsing and viewing (read-only, enrollment via website)
   - Payment schedule and transaction history viewing
   - Investment portfolio tracking (gold/silver grams, current value)
   - Withdrawal request functionality
   - Market rates viewing
   - Profile management (view and edit personal information)

3. **Mobile Application (Flutter) - Staff Features**
   - Staff authentication (staff code + password, PIN)
   - Staff dashboard with target tracking
   - Assigned customer list with search and filters
   - Payment collection recording (online and offline-capable with sync)
   - Customer detail viewing for collection staff
   - Basic reports for collection staff (today's collections, targets)

4. **Website (Next.js) - Office Staff Features**
   - Office staff authentication (email + password)
   - Customer management (create, read, update, soft delete)
   - **Scheme enrollment for customers** (office staff enrolls customers via website)
   - Route management (create, read, update, deactivate routes)
   - Customer-to-staff assignment (individual and bulk by route)
   - Transaction viewing and filtering with export to CSV/Excel
   - Manual payment entry for office collections

5. **Website (Next.js) - Administrator Features**
   - Administrator authentication (email + password)
   - Financial dashboard (inflow/outflow tracking, net cash flow)
   - Staff management (create, read, update, deactivate staff)
   - Scheme management (view, edit, enable/disable schemes)
   - Market rates management (fetch from external API, manual override)
   - Basic reports (daily, weekly, monthly, staff performance, customer payment, scheme performance)
   - System administration UI for database management

6. **Public Website**
   - Landing page (home, about, services, contact)
   - Mobile-responsive design (desktop, tablet, mobile)

7. **Infrastructure & DevOps**
   - CI/CD pipeline (GitHub Actions for website and mobile app)
   - Environment configuration (dev, staging, production)
   - Secrets management (Supabase, Vercel, GitHub Secrets)
   - Monitoring and logging setup (Supabase Dashboard, optional external monitoring)

8. **Documentation**
   - User guides (customer, staff, admin)
   - Technical documentation (architecture, API, database schema)
   - Deployment and operations runbooks

**Acceptance Criteria:**

- [ ] **Database:** All tables created with RLS policies, triggers, and functions. Database schema deployed to production. Test data seeded (schemes, staff records). Database accessible via Supabase dashboard.
- [ ] **Customer Mobile App:** 
  - [ ] Customer can login with OTP (SMS received and verified within 30 seconds)
  - [ ] Customer can set PIN and use PIN/biometric for subsequent logins
  - [ ] Customer dashboard displays investment overview (total grams, current value) with accurate calculations
  - [ ] Customer can view all active schemes (18 schemes displayed, grouped by Gold/Silver)
  - [ ] Customer can view own payment history (all payments displayed with receipt ID, amount, date)
  - [ ] Customer can view payment schedule (future payments calculated correctly based on enrollment)
  - [ ] Customer can request withdrawal (withdrawal request created with 'pending' status)
  - [ ] Customer can view market rates (current gold and silver rates displayed)
  - [ ] Customer can update profile (name, address, nominee details saved successfully)
- [ ] **Staff Mobile App:**
  - [ ] Staff can login with staff code + password (authentication successful within 5 seconds)
  - [ ] Staff can set PIN and use PIN for subsequent logins
  - [ ] Staff dashboard displays today's target and progress (amount and customer targets)
  - [ ] Staff can view assigned customers list (only assigned customers displayed, filtered correctly)
  - [ ] Staff can record payment for assigned customer (payment saved to database with receipt ID)
  - [ ] Staff can record payment offline (payment queued, synced when online)
  - [ ] Staff can view customer details (customer information, active schemes, payment history displayed)
  - [ ] Staff can view basic reports (today's collections, target vs achievement displayed correctly)
- [ ] **Website - Office Staff:**
  - [ ] Office staff can login with email + password (authentication successful)
  - [ ] Office staff can create new customer (customer record created with profile, KYC data saved)
  - [ ] **Office staff can enroll customer in scheme** (enrollment created in `user_schemes` table, customer can see enrollment in mobile app)
  - [ ] Office staff can view customer list (all customers displayed with search and filter working)
  - [ ] Office staff can edit customer information (address, nominee details updated successfully)
  - [ ] Office staff can create routes (route created and displayed in route list)
  - [ ] Office staff can assign customers to staff (assignment created in `staff_assignments` table, staff can see assigned customers in mobile app)
  - [ ] Office staff can view all transactions (transactions displayed with filters working)
  - [ ] Office staff can enter manual payment (payment saved to database with `staff_id = NULL`)
  - [ ] Office staff can export transaction data (CSV/Excel file generated and downloaded)
- [ ] **Website - Administrator:**
  - [ ] Administrator can login with email + password (authentication successful)
  - [ ] Administrator can view financial dashboard (inflow, outflow, net cash flow displayed with accurate calculations)
  - [ ] Administrator can manage staff (create, edit, deactivate staff records)
  - [ ] Administrator can manage schemes (edit scheme details, enable/disable schemes)
  - [ ] **Administrator can fetch market rates from external API** (rates fetched and saved automatically, manual override available if API fails)
  - [ ] Administrator can view all reports (daily, weekly, monthly reports generated with accurate data)
  - [ ] Administrator can export reports (PDF/Excel files generated and downloaded)
  - [ ] Administrator can access system administration UI (database health, system logs displayed)
- [ ] **Public Website:**
  - [ ] Landing page displays correctly (home, about, services, contact pages accessible)
  - [ ] Website is mobile-responsive (desktop, tablet, mobile layouts work correctly)
  - [ ] Website loads within 3 seconds (initial load time measured)
- [ ] **Infrastructure:**
  - [ ] CI/CD pipeline runs successfully (website deploys to Vercel on push to `main`, mobile app builds on push)
  - [ ] Environment variables configured correctly (dev, staging, production environments have correct secrets)
  - [ ] Monitoring and logging working (Supabase Dashboard shows logs, optional external monitoring configured)
- [ ] **Performance:**
  - [ ] Mobile app startup time < 3 seconds (cold start measured on Android 8.0+ device)
  - [ ] Website page load time < 3 seconds (initial load measured on desktop Chrome)
  - [ ] Payment recording completes within 3 seconds (online payment recorded and confirmed)
  - [ ] Database queries complete within 500ms (p95 query time measured)
- [ ] **Security:**
  - [ ] RLS policies enforced (staff cannot access unassigned customers, customers cannot access other customers' data)
  - [ ] Payment immutability enforced (payment UPDATE/DELETE blocked by triggers)
  - [ ] Secrets not exposed (API keys not in repository, `.env` files in `.gitignore`)
  - [ ] Authentication working correctly (OTP, password, PIN authentication functional)
- [ ] **Offline Capability:**
  - [ ] Staff can record payments offline (payments queued in local storage)
  - [ ] Offline payments sync when online (queued payments uploaded to database successfully)
  - [ ] App uses cached data when offline (customer list, schemes, market rates displayed from cache)

---

### Phase 2: Enhancements & Optimization (Duration: 6-8 weeks)

**Objective:** Add advanced features, optimize performance, and improve user experience based on Phase 1 feedback.

**Deliverables:**

1. **Enhanced Mobile App Features**
   - Push notifications implementation (Firebase Cloud Messaging for Android, APNs for iOS)
   - Enhanced offline capabilities (expanded offline data caching)
   - Performance optimizations (app size reduction, startup time optimization)
   - UI/UX improvements based on user feedback

2. **Enhanced Website Features**
   - Advanced filtering and search capabilities
   - Enhanced financial dashboards with more detailed analytics
   - Bulk operations (bulk customer creation, bulk enrollment, bulk assignment)
   - Enhanced reporting with more report types

3. **Automated Notifications**
   - Automated email/SMS notifications (payment reminders, withdrawal status updates, enrollment confirmations)
   - Notification preferences and management
   - Notification delivery tracking

4. **Performance & Scalability Improvements**
   - Database query optimization
   - Caching layer implementation (if needed)
   - Read replica setup (if database becomes bottleneck)
   - Mobile app performance optimization

5. **Security Enhancements**
   - Security audit and vulnerability assessment
   - Enhanced error handling and logging
   - Security monitoring and alerting
   - Security best practices documentation

6. **Testing & Quality Assurance**
   - Comprehensive test suite (unit tests, integration tests, E2E tests)
   - Test coverage > 70% (goal)
   - Performance testing and optimization
   - User acceptance testing (UAT) completion

**Acceptance Criteria:**

- [ ] **Push Notifications:**
  - [ ] Push notifications delivered successfully (Android via FCM, iOS via APNs)
  - [ ] Notification delivery rate > 95% (measured over 7 days)
  - [ ] Users can enable/disable push notifications in app settings
- [ ] **Automated Notifications:**
  - [ ] OTP delivery via SMS works (100% delivery rate for OTP)
  - [ ] Withdrawal status update notifications sent (SMS/Email delivered when status changes)
  - [ ] Enrollment confirmation notifications sent (customer notified when enrolled)
- [ ] **Performance:**
  - [ ] Mobile app startup time < 2 seconds (optimized from 3 seconds)
  - [ ] Website page load time < 2 seconds (optimized from 3 seconds)
  - [ ] Database queries complete within 300ms (p95, optimized from 500ms)
  - [ ] Mobile app size < 50MB (optimized from current size)
- [ ] **Testing:**
  - [ ] Unit test coverage > 70% (measured via code coverage tools)
  - [ ] Integration tests pass (critical user flows tested)
  - [ ] E2E tests pass (complete user journeys tested)
  - [ ] UAT completed successfully (all user groups tested and approved)
- [ ] **Security:**
  - [ ] Security audit completed (no critical vulnerabilities found)
  - [ ] Error handling implemented (all critical errors handled gracefully)
  - [ ] Security monitoring active (alerts configured for suspicious activity)
- [ ] **User Experience:**
  - [ ] User feedback collected and prioritized
  - [ ] UI/UX improvements implemented based on feedback
  - [ ] User satisfaction score > 4.0/5.0 (measured via user surveys)

---

### Phase 3: Advanced Features & Scale (Duration: 6-8 weeks)

**Objective:** Add advanced analytics, scale infrastructure, and prepare for long-term growth.

**Deliverables:**

1. **Advanced Analytics & Reporting**
   - Advanced financial analytics (trend analysis, projections, forecasting)
   - Custom report builder (if required)
   - Advanced dashboards with drill-down capabilities
   - Data export in multiple formats (CSV, Excel, PDF)

2. **Infrastructure Scaling**
   - Database scaling (read replicas, query optimization)
   - CDN optimization (if needed)
   - Load balancing (if needed)
   - Performance monitoring and optimization

3. **Advanced Features**
   - Advanced search capabilities (full-text search, faceted search)
   - Advanced filtering (multi-criteria filters, saved filters)
   - Bulk import/export (if required)
   - Advanced user management (role customization, permission granularity)

4. **Integration Enhancements**
   - Additional market price API providers (backup providers)
   - Enhanced notification channels (WhatsApp, if required)
   - Third-party integrations (if required, e.g., accounting software)

5. **Documentation & Training**
   - Comprehensive user documentation
   - Training materials and videos
   - Admin guides and runbooks
   - API documentation

6. **Compliance & Audit**
   - Compliance audit (regulatory requirements)
   - Security audit (penetration testing)
   - Data retention policy implementation
   - Audit trail enhancements

**Acceptance Criteria:**

- [ ] **Advanced Analytics:**
  - [ ] Advanced financial dashboards implemented (trend analysis, projections displayed)
  - [ ] Custom report builder functional (users can create custom reports)
  - [ ] Data export working (all formats: CSV, Excel, PDF generated correctly)
- [ ] **Infrastructure:**
  - [ ] Database scaled appropriately (handles 500+ concurrent users without performance degradation)
  - [ ] Read replicas deployed (if needed, reporting queries use read replicas)
  - [ ] Performance monitoring active (system performance tracked and optimized)
- [ ] **Advanced Features:**
  - [ ] Advanced search functional (full-text search returns relevant results)
  - [ ] Advanced filtering working (multi-criteria filters applied correctly)
  - [ ] Bulk operations working (bulk import/export functional, if implemented)
- [ ] **Integration:**
  - [ ] Backup market price API provider configured (fallback provider available)
  - [ ] Enhanced notifications working (additional channels functional, if implemented)
- [ ] **Documentation:**
  - [ ] User documentation complete (all user groups have comprehensive guides)
  - [ ] Training materials available (video tutorials, written guides created)
  - [ ] Admin guides complete (system administration documented)
- [ ] **Compliance:**
  - [ ] Compliance audit passed (regulatory requirements met)
  - [ ] Security audit passed (penetration testing completed, no critical vulnerabilities)
  - [ ] Data retention policy implemented (data retained according to policy)
  - [ ] Audit trail complete (all critical operations logged and auditable)
- [ ] **Scalability:**
  - [ ] System handles 500+ concurrent users (performance measured and acceptable)
  - [ ] System handles 100,000+ payments/month (performance measured and acceptable)
  - [ ] System uptime > 99.5% (measured over 3 months)

---

## 13. OPEN QUESTIONS

| Question | Stakeholder | Priority | Target Resolution Date |
|----------|-------------|----------|----------------------|
| [Question 1: What needs clarification?] | [Who needs to answer] | [High/Medium/Low] | [Date] |
| [Question 2] | [Who needs to answer] | [High/Medium/Low] | [Date] |
| [Question 3] | [Who needs to answer] | [High/Medium/Low] | [Date] |

---

## Appendix A: Glossary

[Define key terms, acronyms, and domain-specific language used throughout the document]

---

## Appendix B: References

[Links to external documents, specifications, or resources referenced in this PDR]

---

**END OF DOCUMENT**

