# Comprehensive PRD Generation Prompt for SLG-GOLDS

**Use this prompt in Cursor to generate a complete Product Requirements Document (PRD) for the SLG-GOLDS investment scheme management system.**

---

## Instructions for Cursor

You are tasked with generating a comprehensive Product Requirements Document (PRD) for the **SLG-GOLDS** application - a gold/silver investment scheme management system. This PRD should be production-ready, detailed, and cover all aspects of the system including mobile app, website, backend, integrations, and operations.

### Context

SLG-GOLDS is a digital platform for managing gold and silver investment schemes. The system consists of:
- **Mobile App (Flutter)**: For customers and collection staff
- **Website (Next.js)**: For office staff and administrators  
- **Backend (Supabase/PostgreSQL)**: Database and authentication layer

### Your Task

Generate a complete PRD document that includes ALL of the following sections in detail:

---

## PRD Structure Requirements

### 1. EXECUTIVE SUMMARY
- Project overview and purpose
- Business objectives and strategic outcomes
- Target market and user base
- Key success metrics
- Timeline and milestones overview

### 2. PROJECT OVERVIEW
- **Business Objective**: Detailed description of what the system aims to achieve
- **Problem Statement**: Current pain points and why this solution is needed
- **Target Users**: 
  - Customers (mobile app users)
  - Collection Staff (mobile app users)
  - Office Staff (website users)
  - Administrators (website users)
  - Include user personas, characteristics, needs, and expected volumes
- **Success Metrics**: Measurable KPIs with targets, baselines, and measurement methods
- **Strategic Outcomes**: Long-term business impact

### 3. SCOPE DEFINITION

#### 3.1 IN SCOPE (Detailed Features)

**Mobile App Features:**
- Customer features (portfolio viewing, payment tracking, withdrawal requests, profile management)
- Collection staff features (assigned customer list, payment collection, daily targets, performance tracking)
- Authentication flows (OTP, PIN setup, staff login)
- Offline capabilities and sync

**Website Features:**
- Public website (marketing pages, contact forms)
- Office staff features (customer management, enrollment, route management, assignments, transaction monitoring)
- Administrator features (financial dashboard, staff management, scheme management, market rates, reports)
- Authentication and authorization

**Backend Features:**
- Database schema and relationships
- Row Level Security (RLS) policies
- Database triggers and functions
- API endpoints and data access patterns

#### 3.2 OUT OF SCOPE (Explicit Exclusions)
- Customer self-enrollment (office staff enrolls customers)
- Advanced analytics/ML (deferred to later phase)
- Third-party integrations beyond Supabase
- Multi-language support (English only)
- Mobile app for office staff/admins (website only)

#### 3.3 RESPONSIBILITY BOUNDARIES
- **Website as Control Plane**: Website is the ONLY interface authorized for:
  - Customer creation
  - Scheme enrollment
  - Route management
  - Staff assignment
  - Market rate updates
  - Withdrawal approval
  - Staff account management
  - Scheme modifications
- **Mobile App as Execution Layer**: Mobile app can:
  - View data (customers view own, staff view assigned)
  - Record payments (collection staff)
  - Request withdrawals (customers)
  - Execute pre-authorized operations
- **Database as Ultimate Authority**: All operations enforced by RLS policies

### 4. USER ROLES & PERMISSIONS

#### 4.1 Role Definitions
- **Customer**: Self-service access to own data
- **Collection Staff**: Field collection, assigned customers only
- **Office Staff**: Customer management, enrollment, assignments, monitoring
- **Administrator**: Full system access, financial oversight, staff/scheme management

#### 4.2 Authentication Methods
- Customers: Phone OTP + PIN
- Staff: Staff code + password
- Office Staff/Admin: Email + password

#### 4.3 Authorization Rules
- Role-based access control (RBAC)
- Database-first enforcement (RLS policies)
- Permission inheritance (admin inherits staff permissions)
- Data access rules per role

#### 4.4 Security Requirements
- Session management
- Token refresh
- Rate limiting
- Input validation
- CORS policies

### 5. FUNCTIONAL REQUIREMENTS

#### 5.1 Customer Flows (Mobile App)
- Registration and onboarding
- Login (OTP → PIN setup → Dashboard)
- View portfolio (schemes, accumulated grams, payment history)
- View payment schedule
- Request withdrawal
- Update profile
- View transaction history

#### 5.2 Collection Staff Flows (Mobile App)
- Login (staff code + password)
- View assigned customers
- Record payment collection
- View daily targets and performance
- View collection history
- Update profile

#### 5.3 Office Staff Flows (Website)
- Create new customer (with KYC details)
- Enroll customer in scheme
- Assign customer to collection staff (by route or manual)
- Manage routes
- Manual payment entry (office collections)
- View transaction monitoring dashboard
- Approve/process withdrawals

#### 5.4 Administrator Flows (Website)
- View financial dashboard (inflow/outflow)
- Fetch and update market rates (from external API)
- Manage staff accounts
- Manage schemes (edit, enable/disable)
- Generate reports (daily, weekly, monthly, staff performance, customer payment, scheme performance)
- System administration

### 6. DATA MODEL & SCHEMA

#### 6.1 Core Tables
- `profiles` (user authentication and roles)
- `customers` (customer KYC data)
- `staff_metadata` (staff-specific data)
- `schemes` (18 investment schemes: 9 gold, 9 silver)
- `user_schemes` (customer enrollments)
- `payments` (append-only payment records)
- `withdrawals` (withdrawal requests)
- `market_rates` (daily gold/silver rates)
- `routes` (geographic territories)
- `staff_assignments` (customer-to-staff assignments)

#### 6.2 Relationships
- Foreign key relationships
- Cascade rules
- Referential integrity

#### 6.3 Constraints
- Required fields
- Data types and formats
- Business rules enforced at database level

#### 6.4 Immutability Rules
- Payments are append-only (no UPDATE/DELETE)
- Reversals implemented as new records
- Audit trail preservation

### 7. TECHNICAL ARCHITECTURE

#### 7.1 Mobile App Stack
- **Framework**: Flutter (Dart)
- **State Management**: Provider/Riverpod
- **Backend Client**: Supabase Flutter SDK
- **Authentication**: Supabase Auth
- **Platforms**: iOS, Android

#### 7.2 Website Stack
- **Framework**: Next.js 14+ (App Router)
- **Language**: TypeScript 5.0+
- **State Management**: React Query (TanStack Query) + React Context
- **UI Components**: shadcn/ui + Tailwind CSS
- **Authentication**: Supabase Auth JavaScript client
- **Deployment**: Vercel (recommended)

#### 7.3 Backend Stack
- **Database**: PostgreSQL (via Supabase)
- **Authentication**: Supabase Auth
- **API**: Supabase REST API + RPC functions
- **Security**: Row Level Security (RLS) policies
- **Triggers**: Database triggers for business logic

#### 7.4 Integration Points
- Market rates API (external service for gold/silver prices)
- Supabase services (Auth, Database, Storage if needed)

### 8. NON-FUNCTIONAL REQUIREMENTS

#### 8.1 Performance
- Page load times (< 3 seconds for 95% of requests)
- API response times
- Database query optimization
- Mobile app performance targets

#### 8.2 Scalability
- Expected user volumes
- Data growth projections
- System capacity planning

#### 8.3 Availability
- Uptime target (99.5%)
- Downtime tolerance
- Disaster recovery

#### 8.4 Security
- Data encryption (in transit, at rest)
- Authentication security
- Authorization enforcement
- Audit logging
- Payment immutability

#### 8.5 Usability
- Mobile app UX requirements
- Website UX requirements
- Accessibility considerations
- Responsive design requirements

### 9. USER INTERFACE REQUIREMENTS

#### 9.1 Mobile App UI
- Navigation structure
- Screen layouts and components
- Design system (colors, typography, spacing)
- Mobile-specific interactions (offline indicators, pull-to-refresh)

#### 9.2 Website UI
- Public website pages (landing, about, services, contact)
- Office staff interface (dashboard, customer management, routes, assignments)
- Administrator interface (financial dashboard, reports, settings)
- Responsive design requirements

### 10. INTEGRATIONS

#### 10.1 Market Rates API
- External API for fetching daily gold/silver rates
- Integration method (REST API)
- Error handling and fallback
- Rate update frequency

#### 10.2 Supabase Services
- Authentication integration
- Database integration
- Storage integration (if needed)

### 11. DATA ACCESS & SECURITY

#### 11.1 Row Level Security (RLS) Policies
- Policy definitions per table
- Role-based access patterns
- Unauthenticated access rules
- Staff assignment-based access

#### 11.2 Database Triggers
- Payment immutability enforcement
- User scheme totals updates
- Receipt number generation
- Audit trail maintenance

#### 11.3 Data Access Patterns
- Read patterns (customers read own, staff read assigned)
- Write patterns (who can create/update what)
- Delete patterns (soft delete vs hard delete)

### 12. BUSINESS RULES

#### 12.1 Payment Rules
- Payment calculation (amount → grams based on market rate)
- GST calculation (3%)
- Payment methods (cash, UPI, bank transfer)
- Payment immutability (append-only)

#### 12.2 Scheme Rules
- 18 schemes (9 gold, 9 silver)
- Payment frequencies
- Amount ranges (min/max)
- Enrollment rules

#### 12.3 Withdrawal Rules
- Request → Approval → Processing workflow
- Rate calculation at processing time
- Status tracking

#### 12.4 Assignment Rules
- Route-based assignment
- Manual assignment
- Reassignment rules

### 13. ERROR HANDLING & EDGE CASES

#### 13.1 Authentication Errors
- Invalid OTP
- Expired sessions
- Role validation failures

#### 13.2 Payment Errors
- Network failures during payment
- Duplicate payment prevention
- Market rate unavailable

#### 13.3 Data Errors
- Missing required fields
- Invalid data formats
- Constraint violations

#### 13.4 Offline Scenarios
- Mobile app offline behavior
- Sync on reconnect
- Data conflict resolution

### 14. TESTING REQUIREMENTS

#### 14.1 Unit Testing
- Service layer tests
- Business logic tests

#### 14.2 Integration Testing
- API integration tests
- Database integration tests

#### 14.3 End-to-End Testing
- Critical user flows
- Payment collection flow
- Customer enrollment flow

#### 14.4 Security Testing
- RLS policy validation
- Authorization testing
- Authentication testing

### 15. DEPLOYMENT & ENVIRONMENTS

#### 15.1 Environments
- Development
- Staging
- Production

#### 15.2 Deployment Process
- Mobile app deployment (App Store, Play Store)
- Website deployment (Vercel)
- Database migrations

#### 15.3 Configuration Management
- Environment variables
- API keys and secrets
- Feature flags

### 16. MONITORING & LOGGING

#### 16.1 Application Monitoring
- Error tracking
- Performance monitoring
- User activity tracking

#### 16.2 Database Monitoring
- Query performance
- RLS policy violations
- Trigger execution

#### 16.3 Audit Logging
- Payment audit trail
- User action logging
- System event logging

### 17. ASSUMPTIONS & CONSTRAINTS

#### 17.1 Business Assumptions
- Customer behavior assumptions
- Staff usage patterns
- Growth projections

#### 17.2 Technical Constraints
- Supabase platform limitations
- Mobile platform constraints
- Network connectivity assumptions

#### 17.3 Regulatory Constraints
- Data privacy requirements
- Financial compliance
- KYC requirements

### 18. RISKS & MITIGATION

#### 18.1 Technical Risks
- Database performance at scale
- Mobile app offline sync issues
- API rate limiting

#### 18.2 Product Risks
- Low user adoption
- Data quality issues
- Payment recording errors

#### 18.3 Operational Risks
- Staff training requirements
- System downtime impact
- Data migration challenges

### 19. SUCCESS CRITERIA

#### 19.1 MVP Success Criteria
- All core features functional
- Zero critical security vulnerabilities
- 99.5% uptime achieved
- User adoption targets met

#### 19.2 Phase 1 Success Criteria
- Customer enrollment targets met
- Payment collection efficiency improved
- Staff assignment time reduced
- Financial visibility achieved

### 20. APPENDICES

#### 20.1 Glossary
- Terms and definitions
- Acronyms

#### 20.2 References
- Related documents
- External resources
- API documentation

#### 20.3 Change Log
- Version history
- Document updates

---

## Additional Requirements for PRD Generation

1. **Be Specific**: Include exact field names, table names, API endpoints, and technical details where relevant
2. **Be Comprehensive**: Cover all aspects mentioned in existing documentation (PROJECT_DEFINITION_REPORT.md, Website_PDR_v1.0.md, SYSTEM_ARCHITECTURE_SPECIFICATION.md)
3. **Be Actionable**: Requirements should be clear enough for developers to implement
4. **Include Examples**: Provide examples of data structures, user flows, and error scenarios
5. **Reference Existing Docs**: Where applicable, reference existing documentation files
6. **Consider Edge Cases**: Document error handling, offline scenarios, and failure modes
7. **Security First**: Emphasize database-first security enforcement via RLS policies
8. **Mobile-First**: Detail mobile app requirements including offline capabilities
9. **Website Authority**: Clearly establish website as control plane for operational decisions
10. **Payment Immutability**: Emphasize append-only payment records and audit trail requirements

---

## Expected Output Format

Generate the PRD as a well-structured Markdown document with:
- Clear section headings and subheadings
- Numbered lists for requirements
- Tables for data models and comparisons
- Code blocks for technical specifications
- Diagrams descriptions (ASCII or Mermaid syntax)
- Cross-references between sections

---

## Quality Checklist

Before finalizing the PRD, ensure:
- [ ] All 20 sections are complete
- [ ] Technical details match existing architecture
- [ ] User flows are detailed and step-by-step
- [ ] Security requirements are comprehensive
- [ ] Data model is fully specified
- [ ] Integration points are documented
- [ ] Error handling is covered
- [ ] Success metrics are measurable
- [ ] Out-of-scope items are explicitly listed
- [ ] Responsibility boundaries are clear

---

**Start generating the PRD now. Be thorough, detailed, and production-ready.**

