# PRD Compliance Gap Analysis - SLG-GOLDS
**Date:** 2025-01-02  
**Reference:** PRD_GENERATION_PROMPT.md  
**Focus:** Mobile App (Flutter) + Supabase Database

---

## Executive Summary

This document identifies gaps between the PRD requirements and current implementation for the SLG-GOLDS mobile app and Supabase database. The analysis covers functional requirements, database schema, integrations, and non-functional requirements.

### Overall Compliance: **~75%**

**Status by Component:**
- ✅ **Mobile App (Flutter):** ~85% complete
- ⚠️ **Supabase Database:** ~80% complete
- ❌ **Website (Next.js):** Not in scope (separate project)
- ⚠️ **Integrations:** ~60% complete
- ❌ **Testing:** ~5-10% complete

---

## 1. DATABASE SCHEMA GAPS

### ✅ 1.1 Core Tables - MOSTLY COMPLETE

| Table | Status | Notes |
|-------|--------|-------|
| `profiles` | ✅ Complete | All required fields present |
| `customers` | ✅ Complete | KYC fields present (some unused) |
| `staff_metadata` | ✅ Complete | Staff-specific data complete |
| `schemes` | ✅ Complete | 18 schemes supported |
| `user_schemes` | ✅ Complete | Enrollment tracking complete |
| `payments` | ✅ Complete | Append-only with triggers |
| `withdrawals` | ✅ Complete | RLS policies in place |
| `market_rates` | ✅ Complete | Daily rates tracking |
| `staff_assignments` | ✅ Complete | Assignment tracking |
| `routes` | ⚠️ **MISSING** | Not in main schema, exists in migrations |

#### 🟠 CRITICAL: Routes Table Missing from Main Schema

**Location:** `supabase_schema.sql`  
**Status:** Table exists in `DATABASE_MIGRATIONS_SPRINT_1_TO_3.sql` but not in main schema

**What's Missing:**
- `routes` table not in `supabase_schema.sql`
- RLS policies for routes table missing from main schema
- No foreign key relationship from `staff_assignments.route_id`

**Required Schema:**
```sql
CREATE TABLE IF NOT EXISTS routes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    route_name TEXT NOT NULL UNIQUE,
    description TEXT,
    area_coverage TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES profiles(id),
    updated_by UUID REFERENCES profiles(id),
    CONSTRAINT routes_route_name_length CHECK (char_length(route_name) BETWEEN 2 AND 100)
);
```

**Impact:**
- Route-based assignment not possible
- Website feature incomplete (route management)
- Staff assignments cannot link to routes

**Priority:** 🔴 CRITICAL  
**Effort:** 2-3 hours  
**Action:** Add routes table to main schema with RLS policies

---

### ⚠️ 1.2 Missing Database Functions

#### 🟠 HIGH: Withdrawal Processing Function

**Status:** Missing database function for withdrawal processing

**What's Missing:**
- Function to calculate final withdrawal amounts
- Function to update `user_schemes` after withdrawal processing
- Function to track metal withdrawal amounts

**Required:**
```sql
-- Function to process withdrawal (calculate final amounts, update totals)
CREATE OR REPLACE FUNCTION process_withdrawal(
    withdrawal_id UUID,
    current_rate DECIMAL(10, 2),
    final_grams DECIMAL(10, 4)
) RETURNS void AS $$
-- Update withdrawal with final amounts
-- Update user_schemes: subtract metal_grams, update total_withdrawn
-- Handle full vs partial withdrawal logic
$$;
```

**Priority:** 🟠 HIGH  
**Effort:** 4-6 hours

---

### ⚠️ 1.3 Missing Database Triggers

#### 🟠 HIGH: Withdrawal Processing Trigger

**Status:** Missing trigger for withdrawal status updates

**What's Missing:**
- Trigger to update `user_schemes` when withdrawal status changes to 'processed'
- Trigger to calculate final amounts when withdrawal is approved
- Trigger to track metal withdrawals

**Priority:** 🟠 HIGH  
**Effort:** 3-4 hours

---

### ⚠️ 1.4 Missing Database Views

**Status:** Some views exist, but PRD requires additional views

**What's Missing:**
- Withdrawal status view (pending/approved/processed by customer)
- Staff route assignments view
- Route customer assignments view
- Customer enrollment summary view

**Priority:** 🟡 MEDIUM  
**Effort:** 4-6 hours

---

## 2. MOBILE APP FEATURE GAPS

### ✅ 2.1 Customer Features - MOSTLY COMPLETE

| Feature | Status | Notes |
|---------|--------|-------|
| Portfolio viewing | ✅ Complete | Dashboard shows all schemes |
| Payment tracking | ✅ Complete | Transaction history available |
| Withdrawal requests | ✅ **JUST COMPLETED** | Database submission implemented |
| Profile management | ⚠️ Partial | Image upload missing |
| Payment schedule | ✅ Complete | Schedule view exists |
| Transaction history | ✅ Complete | Full history available |

#### 🟡 MEDIUM: Profile Image Upload (Section 5.1)

**Location:** `lib/screens/customer/profile_screen.dart:56`  
**Status:** TODO exists, implementation missing

**What's Missing:**
- Supabase Storage upload logic
- Avatar URL storage in profiles table
- Image caching and display

**Required:**
```dart
// Upload to Supabase Storage
final file = File(image.path);
final fileName = 'avatars/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
await Supabase.instance.client.storage
    .from('avatars')
    .upload(fileName, file);
final url = Supabase.instance.client.storage
    .from('avatars')
    .getPublicUrl(fileName);
// Update profile with avatar_url
```

**Database Change Required:**
- Add `avatar_url TEXT` column to `profiles` table

**Priority:** 🟡 MEDIUM  
**Effort:** 2-3 hours  
**Dependencies:** Supabase Storage bucket setup

---

#### 🟡 MEDIUM: Receipt Download/Share (Section 5.1)

**Location:** `lib/screens/customer/transaction_detail_screen.dart:197, 220`  
**Status:** TODO exists, implementation missing

**What's Missing:**
- PDF receipt generation
- Download functionality
- Share functionality (WhatsApp, email, etc.)

**Required Packages:**
- `pdf` package (already available in pubspec.yaml)
- `path_provider` for file storage
- `share_plus` for sharing

**Priority:** 🟡 MEDIUM  
**Effort:** 6-8 hours

---

#### 🟡 MEDIUM: Terms & Conditions Navigation (Section 5.1)

**Location:** `lib/screens/login_screen.dart:494, 512`  
**Status:** Screens exist but not linked

**What's Missing:**
- Navigation to Terms & Conditions screen
- Navigation to Privacy Policy screen
- Content population

**Priority:** 🟡 MEDIUM  
**Effort:** 1 hour

---

### ✅ 2.2 Collection Staff Features - COMPLETE

| Feature | Status | Notes |
|---------|--------|-------|
| Assigned customers | ✅ Complete | Staff dashboard shows assignments |
| Payment collection | ✅ Complete | Offline support included |
| Daily targets | ✅ Complete | Target tracking available |
| Performance tracking | ✅ Complete | Reports screen exists |
| Collection history | ✅ Complete | Payment history available |

**Status:** All collection staff features are complete.

---

### ⚠️ 2.3 Offline Capabilities - PARTIALLY COMPLETE

#### 🟠 HIGH: Offline Conflict Resolution (Section 13.4)

**Location:** `lib/services/offline_sync_service.dart`  
**Status:** Basic sync exists, conflict resolution missing

**What's Missing:**
- Duplicate payment detection
- Idempotency key checking
- Conflict resolution strategy (first-wins, last-wins, manual review)
- Conflict reporting UI

**Current Implementation:**
- Basic sync with re-queue on failure
- No duplicate detection
- No conflict resolution

**Required:**
```dart
// Check for duplicate payments before sync
final existingPayment = await checkDuplicatePayment(
  customerId: item.customerId,
  amount: item.amount,
  timestamp: item.clientTimestamp,
);

if (existingPayment != null) {
  // Conflict detected - mark for manual review
  await markConflictForReview(item, existingPayment);
  continue;
}
```

**Priority:** 🟠 HIGH  
**Effort:** 8-12 hours  
**Dependencies:** Payment service, database constraints

---

#### 🟡 MEDIUM: Network Retry Logic (Section 13.2)

**Location:** Service files (payment_service, staff_data_service, etc.)  
**Status:** Missing retry logic with exponential backoff

**What's Missing:**
- Retry logic for network failures
- Exponential backoff
- Retry limit enforcement
- Connectivity detection integration

**Priority:** 🟡 MEDIUM  
**Effort:** 6-8 hours  
**Action:** Create `NetworkService` with retry wrapper

---

## 3. DATABASE FUNCTIONALITY GAPS

### ✅ 3.1 Row Level Security (RLS) - MOSTLY COMPLETE

**Status:** All tables have RLS policies implemented

**Verified Policies:**
- ✅ profiles - Users read own, staff read assigned
- ✅ customers - Customers read own, staff read assigned
- ✅ payments - Append-only, RLS enforced
- ✅ withdrawals - Customers insert own, staff update assigned
- ✅ user_schemes - Customers read own, staff read assigned
- ✅ staff_assignments - Staff read own, admin manage all
- ✅ market_rates - Everyone read, admin manage
- ⚠️ routes - **MISSING** (table doesn't exist in main schema)

**Missing:**
- RLS policies for `routes` table (when added)

---

### ⚠️ 3.2 Database Triggers - PARTIALLY COMPLETE

**Status:** Payment triggers exist, withdrawal triggers missing

**Existing Triggers:**
- ✅ `update_user_scheme_totals` - Updates totals on payment insert
- ✅ `prevent_payment_modification` - Prevents UPDATE/DELETE on payments
- ✅ `generate_receipt_number` - Auto-generates receipt numbers
- ✅ `update_updated_at_column` - Updates timestamps

**Missing Triggers:**
- ⚠️ Withdrawal processing trigger (update user_schemes on withdrawal approval/processing)
- ⚠️ Withdrawal metal calculation trigger

**Priority:** 🟠 HIGH  
**Effort:** 4-6 hours

---

## 4. INTEGRATION GAPS

### ⚠️ 4.1 Market Rates API (Section 10.1)

**Status:** Database structure exists, API integration unclear

**What's Required:**
- External API for fetching daily gold/silver rates
- Scheduled job/function to fetch rates daily
- Error handling and fallback
- Manual override capability for admin

**Current State:**
- `market_rates` table exists
- RLS policies allow admin to insert/update
- API integration status unknown

**Missing:**
- API integration code
- Scheduled fetch mechanism
- Error handling for API failures
- Fallback to last known rate

**Priority:** 🟠 HIGH  
**Effort:** 8-12 hours  
**Dependencies:** External API access, Supabase Edge Functions or cron job

---

### ⚠️ 4.2 Supabase Storage (Section 10.2)

**Status:** Not integrated

**What's Required:**
- Storage bucket for profile images (`avatars`)
- Storage bucket for receipts (optional)
- RLS policies for storage buckets

**Missing:**
- Storage bucket creation
- Upload/download implementation
- Storage RLS policies

**Priority:** 🟡 MEDIUM  
**Effort:** 2-4 hours  
**Action:** Create storage buckets, implement upload in profile screen

---

## 5. NON-FUNCTIONAL REQUIREMENTS GAPS

### ⚠️ 5.1 Performance (Section 8.1)

**Status:** Basic implementation, optimization needed

**Missing:**
- Query optimization (pagination for large lists)
- Image caching strategy
- Lazy loading for lists
- Bundle size optimization

**Priority:** 🟡 MEDIUM  
**Effort:** 12-16 hours

---

### ⚠️ 5.2 Testing (Section 14)

**Status:** Minimal coverage (~5-10%)

**Missing:**
- Unit tests for services
- Integration tests for API
- E2E tests for critical flows
- Widget tests for screens
- RLS policy tests

**Priority:** 🔴 CRITICAL  
**Effort:** 40-60 hours

**Required Test Coverage:**
- AuthService - No tests
- PaymentService - No tests
- StaffDataService - No tests
- OfflineSyncService - No tests
- Withdrawal submission - No tests

---

### ✅ 5.3 Security (Section 8.4)

**Status:** Mostly complete

**Completed:**
- ✅ RLS policies enforced
- ✅ Payment immutability (triggers)
- ✅ Authentication security
- ✅ Authorization enforcement

**Missing:**
- ⚠️ Certificate pinning (medium priority)
- ⚠️ Security audit documentation

---

## 6. BUSINESS RULES GAPS

### ✅ 6.1 Payment Rules (Section 12.1) - COMPLETE

**Status:** All payment rules implemented
- ✅ Payment calculation (amount → grams based on rate)
- ✅ GST calculation (3%)
- ✅ Payment methods (cash, UPI, bank transfer)
- ✅ Payment immutability (append-only)

---

### ✅ 6.2 Scheme Rules (Section 12.2) - COMPLETE

**Status:** All scheme rules implemented
- ✅ 18 schemes (9 gold, 9 silver)
- ✅ Payment frequencies
- ✅ Amount ranges (min/max)
- ✅ Enrollment rules

---

### ⚠️ 6.3 Withdrawal Rules (Section 12.3) - PARTIALLY COMPLETE

**Status:** Request flow complete, approval/processing missing

**What's Complete:**
- ✅ Request submission (just completed)
- ✅ Status tracking
- ✅ RLS policies

**What's Missing:**
- ⚠️ Approval workflow (staff/admin approve)
- ⚠️ Processing workflow (calculate final amounts, update totals)
- ⚠️ Rate calculation at processing time
- ⚠️ Metal withdrawal tracking

**Priority:** 🟠 HIGH  
**Effort:** 8-12 hours  
**Note:** Approval/processing is a website feature (office staff/admin)

---

### ⚠️ 6.4 Assignment Rules (Section 12.4) - PARTIALLY COMPLETE

**Status:** Manual assignment exists, route-based missing

**What's Complete:**
- ✅ Manual assignment (via website)
- ✅ Staff assignment tracking

**What's Missing:**
- ⚠️ Route-based assignment (routes table missing)
- ⚠️ Bulk assignment by route
- ⚠️ Route assignment UI

**Priority:** 🟠 HIGH  
**Effort:** 6-8 hours  
**Dependencies:** Routes table creation

---

## 7. ERROR HANDLING & EDGE CASES

### ✅ 7.1 Authentication Errors (Section 13.1) - COMPLETE

**Status:** All authentication error handling implemented
- ✅ Invalid OTP handling
- ✅ Expired sessions
- ✅ Role validation failures

---

### ⚠️ 7.2 Payment Errors (Section 13.2) - PARTIALLY COMPLETE

**Status:** Basic error handling exists, some missing

**What's Complete:**
- ✅ Network failures (offline queue)
- ✅ Basic error messages

**What's Missing:**
- ⚠️ Duplicate payment prevention (conflict detection)
- ⚠️ Market rate unavailable handling (fallback)
- ⚠️ Retry logic with exponential backoff

**Priority:** 🟠 HIGH  
**Effort:** 6-8 hours

---

### ✅ 7.3 Data Errors (Section 13.3) - MOSTLY COMPLETE

**Status:** Database constraints enforce validation
- ✅ Required fields enforced
- ✅ Data format validation
- ✅ Constraint violations handled

---

### ⚠️ 7.4 Offline Scenarios (Section 13.4) - PARTIALLY COMPLETE

**Status:** Basic offline sync exists, conflict resolution missing

**What's Complete:**
- ✅ Offline payment queue
- ✅ Automatic sync on reconnect
- ✅ Queue persistence

**What's Missing:**
- ⚠️ Conflict resolution (duplicate detection)
- ⚠️ Data conflict resolution strategy
- ⚠️ Conflict reporting UI

**Priority:** 🟠 HIGH  
**Effort:** 8-12 hours

---

## 8. PRIORITY ACTION ITEMS

### Phase 1: Critical Database Fixes

#### 🔴 Priority 1: Add Routes Table to Main Schema
- **Why:** Route-based assignment required by PRD
- **Effort:** 2-3 hours
- **Impact:** High - blocks route management features
- **Action:** Add routes table to `supabase_schema.sql` with RLS policies

#### 🔴 Priority 2: Withdrawal Processing Triggers
- **Why:** Withdrawal approval/processing needs database automation
- **Effort:** 4-6 hours
- **Impact:** High - withdrawal workflow incomplete
- **Action:** Create triggers for withdrawal status updates

#### 🔴 Priority 3: Withdrawal Processing Function
- **Why:** Calculate final amounts and update totals
- **Effort:** 4-6 hours
- **Impact:** High - withdrawal processing incomplete
- **Action:** Create database function for withdrawal processing

---

### Phase 2: High Priority Features

#### 🟠 Priority 4: Offline Conflict Resolution
- **Why:** Prevent duplicate payments during sync
- **Effort:** 8-12 hours
- **Impact:** High - data integrity risk
- **Action:** Implement duplicate detection and conflict resolution

#### 🟠 Priority 5: Market Rates API Integration
- **Why:** Automated rate fetching required
- **Effort:** 8-12 hours
- **Impact:** High - manual rate entry inefficient
- **Action:** Integrate external API, create scheduled fetch

#### 🟠 Priority 6: Network Retry Logic
- **Why:** Better handling of transient network failures
- **Effort:** 6-8 hours
- **Impact:** Medium - user experience improvement
- **Action:** Create NetworkService with retry wrapper

---

### Phase 3: Medium Priority Features

#### 🟡 Priority 7: Profile Image Upload
- **Effort:** 2-3 hours
- **Action:** Implement Supabase Storage upload

#### 🟡 Priority 8: Receipt Download/Share
- **Effort:** 6-8 hours
- **Action:** Implement PDF generation and sharing

#### 🟡 Priority 9: Terms & Conditions Navigation
- **Effort:** 1 hour
- **Action:** Add navigation links

#### 🟡 Priority 10: Database Views
- **Effort:** 4-6 hours
- **Action:** Create additional reporting views

---

### Phase 4: Testing & Quality

#### 🔴 Priority 11: Unit Tests
- **Effort:** 40-60 hours
- **Action:** Write tests for all services

#### 🟠 Priority 12: Integration Tests
- **Effort:** 30-40 hours
- **Action:** Test critical user flows

#### 🟠 Priority 13: E2E Tests
- **Effort:** 25-35 hours
- **Action:** Test complete user journeys

---

## 9. SUMMARY STATISTICS

### By Category

| Category | Completion % | Critical Items | High Items | Medium Items |
|----------|--------------|----------------|------------|--------------|
| **Database Schema** | ~85% | 1 | 2 | 1 |
| **Mobile App Features** | ~85% | 0 | 1 | 5 |
| **Database Functions** | ~70% | 0 | 2 | 0 |
| **Integrations** | ~60% | 0 | 1 | 1 |
| **Testing** | ~5-10% | 1 | 2 | 0 |
| **Performance** | ~60% | 0 | 0 | 3 |

### Total Gaps

- 🔴 **CRITICAL:** 5 items
- 🟠 **HIGH:** 9 items
- 🟡 **MEDIUM:** 10 items
- **Total:** 24 actionable gaps

### Estimated Effort

- **Phase 1 (Critical):** 10-15 hours
- **Phase 2 (High):** 22-32 hours
- **Phase 3 (Medium):** 13-18 hours
- **Phase 4 (Testing):** 95-135 hours
- **Total:** 140-200 hours (~18-25 working days)

---

## 10. COMPLIANCE STATUS BY PRD SECTION

| PRD Section | Status | Completion % | Notes |
|-------------|--------|--------------|-------|
| **Section 3: Scope Definition** | ⚠️ Partial | ~85% | Routes table missing |
| **Section 4: User Roles & Permissions** | ✅ Complete | 100% | All roles implemented |
| **Section 5: Functional Requirements** | ⚠️ Partial | ~80% | Some secondary features missing |
| **Section 6: Data Model & Schema** | ⚠️ Partial | ~85% | Routes table missing |
| **Section 7: Technical Architecture** | ✅ Complete | 100% | Stack matches PRD |
| **Section 8: Non-Functional Requirements** | ⚠️ Partial | ~60% | Testing, performance gaps |
| **Section 10: Integrations** | ⚠️ Partial | ~60% | Market rates API missing |
| **Section 11: Data Access & Security** | ✅ Complete | 100% | RLS policies complete |
| **Section 12: Business Rules** | ⚠️ Partial | ~85% | Withdrawal processing incomplete |
| **Section 13: Error Handling** | ⚠️ Partial | ~70% | Conflict resolution missing |
| **Section 14: Testing Requirements** | ❌ Incomplete | ~5-10% | Minimal coverage |

---

## 11. RECOMMENDATIONS

### Immediate Actions (This Week)
1. Add routes table to main schema (2-3 hours)
2. Implement withdrawal processing triggers (4-6 hours)
3. Add offline conflict resolution (8-12 hours)

### Before Production Release
1. Complete all Phase 1 items
2. Complete all Phase 2 items
3. Achieve 70%+ test coverage
4. Complete market rates API integration
5. Security audit

### Post-Release
1. Complete Phase 3 items incrementally
2. Add comprehensive testing
3. Performance optimization
4. Additional database views

---

**Document Version:** 1.0  
**Last Updated:** 2025-01-02  
**Next Review:** After Phase 1 completion

---

## APPENDIX: PRD Requirements Checklist

### Database Schema (Section 6)
- [x] profiles table
- [x] customers table
- [x] staff_metadata table
- [x] schemes table
- [x] user_schemes table
- [x] payments table
- [x] withdrawals table
- [x] market_rates table
- [x] staff_assignments table
- [ ] **routes table** ❌ MISSING

### Mobile App Features (Section 5)
- [x] Customer portfolio viewing
- [x] Payment tracking
- [x] Withdrawal requests
- [ ] Profile image upload ⚠️ TODO
- [ ] Receipt download/share ⚠️ TODO
- [x] Payment schedule
- [x] Transaction history
- [x] Collection staff features
- [ ] Offline conflict resolution ⚠️ INCOMPLETE

### Integrations (Section 10)
- [ ] Market rates API ⚠️ MISSING
- [ ] Supabase Storage ⚠️ MISSING

### Testing (Section 14)
- [ ] Unit tests ❌ MISSING
- [ ] Integration tests ❌ MISSING
- [ ] E2E tests ❌ MISSING
- [ ] Widget tests ❌ MISSING

---

**End of Gap Analysis**

