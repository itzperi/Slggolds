# COMPLETE SCREEN-BY-SCREEN ANALYSIS

**Date:** Current  
**App:** SLG Thangangal Flutter App  
**Total Screens:** 36 screens

---

## EXECUTIVE SUMMARY

### Screen Distribution:
- **Authentication Screens:** 7 screens
- **Customer Screens:** 15 screens
- **Staff Screens:** 13 screens
- **Shared/Profile Screens:** 4 screens
- **Admin Screens:** 0 screens (no dedicated admin interface)

### Database Usage:
- **Screens with Database Reads:** 12 screens
- **Screens with Database Writes:** 2 screens (payment collection, staff PIN setup)
- **Screens with No Database:** 22 screens (mostly UI-only, mock data, or static content)

### Key Findings:
1. **Most screens are UI-only** - Only 12 screens actually query the database
2. **Payment collection is the primary write operation** - Only 2 screens write to database
3. **Customer dashboard has schema mismatch** - Uses `user_id` instead of `customer_id`
4. **Withdrawals table completely unused** - Withdrawal screens query `user_schemes` instead
5. **Many screens still use mock data** - Customer-facing screens heavily rely on mock data

---

## SCREEN CATEGORIES

### 1. AUTHENTICATION SCREENS (7 screens)

#### 1.1 Login Screen
#### 1.2 OTP Screen
#### 1.3 PIN Setup Screen
#### 1.4 PIN Login Screen
#### 1.5 Biometric Setup Screen
#### 1.6 Staff Login Screen
#### 1.7 Staff PIN Setup Screen
#### 1.8 Staff PIN Login Screen

### 2. CUSTOMER SCREENS (15 screens)

#### 2.1 Customer Dashboard
#### 2.2 Schemes Screen
#### 2.3 Scheme Detail Screen
#### 2.4 Profile Screen
#### 2.5 Gold Asset Detail Screen
#### 2.6 Silver Asset Detail Screen
#### 2.7 Market Rates Screen
#### 2.8 Payment Schedule Screen
#### 2.9 Total Investment Screen
#### 2.10 Transaction History Screen
#### 2.11 Transaction Detail Screen
#### 2.12 Withdrawal Screen
#### 2.13 Withdrawal List Screen
#### 2.14 Account Information Page

### 3. STAFF SCREENS (13 screens)

#### 3.1 Staff Dashboard
#### 3.2 Collect Tab Screen
#### 3.3 Collect Payment Screen
#### 3.4 Customer Detail Screen
#### 3.5 Customer List Screen
#### 3.6 Payment Collection Screen
#### 3.7 Reports Screen
#### 3.8 Today Target Detail Screen
#### 3.9 Staff Profile Screen
#### 3.10 Staff Account Info Screen
#### 3.11 Staff Settings Screen

### 4. SHARED/PROFILE SCREENS (4 screens)

#### 4.1 Settings Screen
#### 4.2 Help & Support Screen
#### 4.3 Privacy Policy Screen
#### 4.4 Terms & Conditions Screen

---

## DETAILED SCREEN BREAKDOWN

### ========================================
### AUTHENTICATION SCREENS
### ========================================

---

## SCREEN: Login Screen
**FILE:** `lib/screens/login_screen.dart`  
**ROUTE:** `/` (root, via AuthGate)  
**ROLE:** All (entry point)

**PURPOSE:**
Initial entry point for the app. Allows users to enter phone number to start authentication flow. Provides option to switch to staff login.

**UI ELEMENTS:**
- Phone number input field
- "Get OTP" / "Continue with PIN" button (dynamic based on saved phone)
- "Staff Login" button
- App branding/logo
- Phone number auto-fill from secure storage

**DATABASE READS:**
- ❌ **NO DIRECT DATABASE QUERIES**
- Checks Supabase Auth for existing session (via `AuthService`)
- Queries `users` table (line 176) - **⚠️ WRONG TABLE** (should be `profiles`)

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **Enter phone number:** Validates format, saves to secure storage
- **Tap "Get OTP":** Navigates to OTP screen
- **Tap "Continue with PIN":** Navigates to PIN login (if PIN exists)
- **Tap "Staff Login":** Changes auth flow state to `staffLogin` → shows StaffLoginScreen

**BUSINESS LOGIC:**
- Phone number validation (10 digits)
- Auto-detects if PIN exists for saved phone
- Saves phone to secure storage for future logins
- Formats phone number with +91 prefix

**NOTES:**
- ⚠️ **ISSUE:** Queries `users` table instead of `profiles` table (line 176)
- Uses `AuthService` for OTP sending
- Integrates with `AuthFlowNotifier` for state management

---

## SCREEN: OTP Screen
**FILE:** `lib/screens/otp_screen.dart`  
**ROUTE:** Navigated from LoginScreen  
**ROLE:** Customer

**PURPOSE:**
Verifies OTP sent to user's phone number. Handles both new user registration and existing user login.

**UI ELEMENTS:**
- 6-digit OTP input fields (individual TextFields)
- Phone number display (editable)
- "Verify" button
- "Resend OTP" option
- Loading states
- Error messages

**DATABASE READS:**
- Queries `users` table (line 143) - **⚠️ WRONG TABLE** (should be `profiles`)
- Checks if user exists via `_checkUserExists()`

**DATABASE WRITES:**
- ❌ None (OTP verification handled by Supabase Auth)

**USER ACTIONS:**
- **Enter OTP digits:** Auto-focuses next field
- **Tap "Verify":** Verifies OTP with Supabase Auth
- **Tap "Resend OTP":** Sends new OTP
- **Edit phone number:** Returns to login screen

**BUSINESS LOGIC:**
- OTP validation (6 digits)
- Auto-advances focus between OTP fields
- Detects new vs existing user
- Routes to PIN setup (new user) or PIN login (existing user)
- Uses `OtpService` for OTP operations

**NOTES:**
- ⚠️ **ISSUE:** Queries `users` table instead of `profiles`
- Uses demo mode OTP bypass (123456) for local testing
- Integrates with `AuthFlowNotifier` for state transitions

---

## SCREEN: PIN Setup Screen
**FILE:** `lib/screens/auth/pin_setup_screen.dart`  
**ROUTE:** Navigated from OTP Screen (new users)  
**ROLE:** Customer

**PURPOSE:**
Allows new users to set up a 6-digit PIN for future logins. Also used for PIN reset.

**UI ELEMENTS:**
- 6-digit PIN input fields
- PIN confirmation fields
- "Set PIN" button
- Skip option (for biometric setup)
- Instructions text

**DATABASE READS:**
- ❌ None

**DATABASE WRITES:**
- ❌ None (PIN stored locally in secure storage)

**USER ACTIONS:**
- **Enter PIN:** 6-digit PIN input
- **Confirm PIN:** Re-enter PIN for verification
- **Tap "Set PIN":** Saves PIN to secure storage, proceeds to biometric setup or dashboard
- **Skip:** Proceeds without PIN (not recommended)

**BUSINESS LOGIC:**
- PIN validation (6 digits, must match confirmation)
- PIN hashing (SHA-256) before storage
- Stores PIN hash in secure storage
- Routes to biometric setup or dashboard after completion
- Uses `AuthFlowNotifier.setAuthenticated()` for state transition ✅

**NOTES:**
- ✅ **CORRECT:** Uses `AuthFlowNotifier` instead of direct navigation
- PIN is never stored in plain text
- Integrates with biometric setup flow

---

## SCREEN: PIN Login Screen
**FILE:** `lib/screens/auth/pin_login_screen.dart`  
**ROUTE:** Navigated from Login Screen (existing users with PIN)  
**ROLE:** Customer

**PURPOSE:**
Allows existing users to log in using their 6-digit PIN instead of OTP.

**UI ELEMENTS:**
- 6-digit PIN input fields
- "Login" button
- "Forgot PIN" option
- Phone number display
- Error messages

**DATABASE READS:**
- ❌ None

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **Enter PIN:** 6-digit PIN input
- **Tap "Login":** Validates PIN against stored hash, navigates to dashboard
- **Tap "Forgot PIN":** Returns to OTP flow for PIN reset

**BUSINESS LOGIC:**
- PIN validation against stored hash
- SHA-256 hashing for comparison
- Routes to dashboard on success
- ⚠️ **ISSUE:** Uses `Navigator.pushReplacement` instead of `AuthFlowNotifier.setAuthenticated()`

**NOTES:**
- ⚠️ **ISSUE:** Should use `AuthFlowNotifier.setAuthenticated()` for consistency
- PIN comparison is secure (hashed)

---

## SCREEN: Biometric Setup Screen
**FILE:** `lib/screens/auth/biometric_setup_screen.dart`  
**ROUTE:** Navigated from PIN Setup Screen  
**ROLE:** Customer

**PURPOSE:**
Allows users to enable biometric authentication (fingerprint/face ID) for faster future logins.

**UI ELEMENTS:**
- Biometric icon
- "Enable Biometric" button
- "Skip" option
- Instructions text

**DATABASE READS:**
- ❌ None

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **Tap "Enable Biometric":** Prompts for biometric authentication, saves preference
- **Tap "Skip":** Proceeds without biometric setup

**BUSINESS LOGIC:**
- Checks device biometric availability
- Stores biometric preference in secure storage
- Routes to dashboard after setup
- ⚠️ **ISSUE:** Uses `Navigator.pushAndRemoveUntil` instead of `AuthFlowNotifier.setAuthenticated()`

**NOTES:**
- ⚠️ **ISSUE:** Should use `AuthFlowNotifier.setAuthenticated()` for consistency

---

## SCREEN: Staff Login Screen
**FILE:** `lib/screens/staff/staff_login_screen.dart`  
**ROUTE:** `/staff-login` (via AuthGate when state is `staffLogin`)  
**ROLE:** Staff

**PURPOSE:**
Allows staff members to log in using Staff ID (e.g., SLG002) and password.

**UI ELEMENTS:**
- Staff ID input field
- Password input field
- "Login" button
- Loading indicator
- Error messages

**DATABASE READS:**
- ❌ **NO DIRECT QUERIES** (uses RPC function)
- Calls `get_staff_email_by_code()` RPC function (via `StaffAuthService`)
- Resolves `staff_code` → `email` internally

**DATABASE WRITES:**
- ❌ None (authentication handled by Supabase Auth)

**USER ACTIONS:**
- **Enter Staff ID:** Staff code (e.g., SLG002)
- **Enter Password:** Staff password
- **Tap "Login":** Authenticates via Supabase email+password, creates session

**BUSINESS LOGIC:**
- Staff ID validation
- Resolves staff_code to email via database function
- Authenticates using Supabase `signInWithPassword()`
- Sets Supabase session
- Routes via `AuthFlowNotifier.setAuthenticated()` ✅
- Staff never sees or enters email

**NOTES:**
- ✅ **CORRECT:** Uses `StaffAuthService` for authentication
- ✅ **CORRECT:** Uses `AuthFlowNotifier` for routing
- Staff ID is converted to uppercase internally

---

## SCREEN: Staff PIN Setup Screen
**FILE:** `lib/screens/staff/staff_pin_setup_screen.dart`  
**ROUTE:** Navigated from Staff Login (first time)  
**ROLE:** Staff

**PURPOSE:**
Allows staff to set up a 6-digit PIN for future logins.

**UI ELEMENTS:**
- 6-digit PIN input fields
- PIN confirmation fields
- "Set PIN" button
- Instructions text

**DATABASE READS:**
- ❌ None

**DATABASE WRITES:**
- ⚠️ **POTENTIAL ISSUE:** Updates `staff` table (line 206-207) - **⚠️ WRONG TABLE** (should be `staff_metadata` or local storage)
- Updates `has_pin` and `pin_hash` fields

**USER ACTIONS:**
- **Enter PIN:** 6-digit PIN input
- **Confirm PIN:** Re-enter PIN for verification
- **Tap "Set PIN":** Saves PIN, navigates to staff dashboard

**BUSINESS LOGIC:**
- PIN validation (6 digits, must match)
- PIN hashing (SHA-256)
- ⚠️ **ISSUE:** Writes to `staff` table (doesn't exist in schema - should be `staff_metadata` or local storage)

**NOTES:**
- ⚠️ **CRITICAL ISSUE:** Tries to update `staff` table which doesn't exist in schema
- Should store PIN hash in secure storage (like customer PIN) or `staff_metadata` table

---

## SCREEN: Staff PIN Login Screen
**FILE:** `lib/screens/staff/staff_pin_login_screen.dart`  
**ROUTE:** Navigated from Staff Login (existing staff with PIN)  
**ROLE:** Staff

**PURPOSE:**
Allows staff to log in using their 6-digit PIN.

**UI ELEMENTS:**
- 6-digit PIN input fields
- "Login" button
- Staff ID display
- Error messages

**DATABASE READS:**
- ❌ None (reads PIN hash from secure storage)

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **Enter PIN:** 6-digit PIN input
- **Tap "Login":** Validates PIN, navigates to staff dashboard

**BUSINESS LOGIC:**
- PIN validation against stored hash
- Routes to staff dashboard on success
- ⚠️ **ISSUE:** Uses `Navigator.pushReplacement` instead of `AuthFlowNotifier`

**NOTES:**
- ⚠️ **ISSUE:** Should use `AuthFlowNotifier.setAuthenticated()` for consistency

---

### ========================================
### CUSTOMER SCREENS
### ========================================

---

## SCREEN: Customer Dashboard
**FILE:** `lib/screens/customer/dashboard_screen.dart`  
**ROUTE:** `/dashboard` (main screen after authentication)  
**ROLE:** Customer

**PURPOSE:**
Main landing screen for customers. Shows portfolio overview, active schemes, recent transactions, and quick actions.

**UI ELEMENTS:**
- Bottom navigation (Dashboard, Schemes, Profile)
- Portfolio summary cards (total investment, gold/silver holdings)
- Active schemes list
- Recent transactions
- Quick action buttons (view rates, payment schedule, etc.)
- Pull-to-refresh

**DATABASE READS:**
- ✅ Queries `user_schemes` table (line 1384)
  - Fields: `*` (all fields) with `schemes(*)` join
  - Filter: `user_id = auth.uid()` AND `status = 'active'`
  - ⚠️ **CRITICAL ISSUE:** Uses `user_id` but table has `customer_id` (schema mismatch)
  - Order: `enrollment_date DESC`

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **View schemes:** Navigate to scheme detail screens
- **View transactions:** Navigate to transaction history
- **View rates:** Navigate to market rates screen
- **View payment schedule:** Navigate to payment schedule screen
- **Pull to refresh:** Reloads data
- **Bottom navigation:** Switches between Dashboard, Schemes, Profile tabs

**BUSINESS LOGIC:**
- Fetches active schemes for current user
- Calculates portfolio totals (gold + silver)
- Displays recent transactions
- ⚠️ **ISSUE:** Falls back to mock data if database query fails (line 1392)
- ⚠️ **ISSUE:** Query will always fail due to schema mismatch (`user_id` vs `customer_id`)

**NOTES:**
- ⚠️ **CRITICAL:** Query uses wrong column (`user_id` instead of `customer_id`)
- Uses mock data as fallback
- Complex UI with multiple sections and animations

---

## SCREEN: Schemes Screen
**FILE:** `lib/screens/customer/schemes_screen.dart`  
**ROUTE:** Tab in Customer Dashboard  
**ROLE:** Customer

**PURPOSE:**
Displays all available investment schemes (Gold and Silver) that customers can enroll in.

**UI ELEMENTS:**
- Scheme cards (Gold and Silver)
- Scheme details (name, asset type, duration, features)
- "View Details" buttons
- Filter/search options

**DATABASE READS:**
- ❌ **NO DATABASE QUERIES** - Uses mock data

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **View scheme details:** Navigate to scheme detail screen
- **Filter by asset type:** Gold/Silver filter
- **Search schemes:** Search by name

**BUSINESS LOGIC:**
- Displays available schemes from mock data
- Filters by asset type
- Search functionality

**NOTES:**
- ❌ **ISSUE:** No database integration - uses mock data only
- Should query `schemes` table with `active = true`

---

## SCREEN: Scheme Detail Screen
**FILE:** `lib/screens/customer/scheme_detail_screen.dart`  
**ROUTE:** Navigated from Schemes Screen  
**ROLE:** Customer

**PURPOSE:**
Shows detailed information about a specific investment scheme, including features, how it works, and enrollment options.

**UI ELEMENTS:**
- Scheme name and asset type
- Description and features
- "How it works" section
- Enrollment button
- Back button

**DATABASE READS:**
- ❌ **NO DATABASE QUERIES** - Uses mock data

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **View details:** Scrolls through scheme information
- **Enroll:** Navigate to enrollment flow (not implemented)
- **Back:** Returns to schemes screen

**BUSINESS LOGIC:**
- Displays scheme details from mock data
- ⚠️ **ISSUE:** Enrollment functionality not implemented

**NOTES:**
- ❌ **ISSUE:** No database integration
- Enrollment flow is incomplete

---

## SCREEN: Profile Screen
**FILE:** `lib/screens/customer/profile_screen.dart`  
**ROUTE:** Tab in Customer Dashboard  
**ROLE:** Customer

**PURPOSE:**
Displays customer profile information and provides access to account settings, transaction history, and other features.

**UI ELEMENTS:**
- Profile header (name, phone)
- Menu items (Account Info, Transaction History, Payment Schedule, etc.)
- Logout button
- Settings access

**DATABASE READS:**
- ❌ **NO DATABASE QUERIES** - Uses mock data

**DATABASE WRITES:**
- ❌ None (profile updates not implemented)

**USER ACTIONS:**
- **View account info:** Navigate to account information page
- **View transaction history:** Navigate to transaction history screen
- **View payment schedule:** Navigate to payment schedule screen
- **View total investment:** Navigate to total investment screen
- **View market rates:** Navigate to market rates screen
- **Logout:** Signs out and returns to login screen

**BUSINESS LOGIC:**
- Displays profile from mock data
- Navigation to various detail screens
- Logout functionality

**NOTES:**
- ❌ **ISSUE:** No database integration - should query `profiles` and `customers` tables
- Profile updates not implemented

---

## SCREEN: Gold Asset Detail Screen
**FILE:** `lib/screens/customer/gold_asset_detail_screen.dart`  
**ROUTE:** Navigated from Dashboard or Profile  
**ROLE:** Customer

**PURPOSE:**
Shows detailed breakdown of customer's gold holdings, including accumulated grams, current value, and payment history.

**UI ELEMENTS:**
- Total gold grams
- Current market value
- Payment history chart
- Transaction list
- Back button

**DATABASE READS:**
- ❌ **NO DATABASE QUERIES - Uses mock data**

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **View details:** Scrolls through gold asset information
- **View transactions:** See payment history
- **Back:** Returns to previous screen

**BUSINESS LOGIC:**
- Displays gold holdings from mock data
- Calculates current value based on market rate

**NOTES:**
- ❌ **ISSUE:** No database integration
- Should query `user_schemes` filtered by `schemes.asset_type = 'gold'`
- Should query `payments` for transaction history

---

## SCREEN: Silver Asset Detail Screen
**FILE:** `lib/screens/customer/silver_asset_detail_screen.dart`  
**ROUTE:** Navigated from Dashboard or Profile  
**ROLE:** Customer

**PURPOSE:**
Shows detailed breakdown of customer's silver holdings.

**UI ELEMENTS:**
- Total silver grams
- Current market value
- Payment history
- Transaction list
- Back button

**DATABASE READS:**
- ❌ **NO DATABASE QUERIES - Uses mock data**

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **View details:** Scrolls through silver asset information
- **Back:** Returns to previous screen

**BUSINESS LOGIC:**
- Displays silver holdings from mock data
- Similar to gold asset detail screen

**NOTES:**
- ❌ **ISSUE:** No database integration
- Should query `user_schemes` filtered by `schemes.asset_type = 'silver'`

---

## SCREEN: Market Rates Screen
**FILE:** `lib/screens/customer/market_rates_screen.dart`  
**ROUTE:** Navigated from Dashboard or Profile  
**ROLE:** Customer

**PURPOSE:**
Displays current market rates for gold and silver, with historical trends.

**UI ELEMENTS:**
- Gold rate display
- Silver rate display
- Rate change indicators (up/down)
- Historical chart
- Last updated timestamp
- Back button

**DATABASE READS:**
- ❌ **NO DATABASE QUERIES - Uses mock data**

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **View rates:** Scrolls through rate information
- **Back:** Returns to previous screen

**BUSINESS LOGIC:**
- Displays rates from mock data
- Shows rate changes (percentage and amount)

**NOTES:**
- ❌ **ISSUE:** No database integration
- Should query `market_rates` table for latest rates
- Should show historical trends

---

## SCREEN: Payment Schedule Screen
**FILE:** `lib/screens/customer/payment_schedule_screen.dart`  
**ROUTE:** Navigated from Profile  
**ROLE:** Customer

**PURPOSE:**
Shows customer's payment schedule, including due dates, amounts, and payment status.

**UI ELEMENTS:**
- Payment schedule calendar/list
- Due dates
- Payment amounts
- Status indicators (paid/pending)
- Back button

**DATABASE READS:**
- ❌ **NO DATABASE QUERIES - Uses mock data**

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **View schedule:** Scrolls through payment schedule
- **Back:** Returns to profile screen

**BUSINESS LOGIC:**
- Displays payment schedule from mock data
- Calculates due dates based on payment frequency

**NOTES:**
- ❌ **ISSUE:** No database integration
- Should query `user_schemes` for payment frequency and calculate schedule
- Should query `payments` for payment history

---

## SCREEN: Total Investment Screen
**FILE:** `lib/screens/customer/total_investment_screen.dart`  
**ROUTE:** Navigated from Profile  
**ROLE:** Customer

**PURPOSE:**
Shows comprehensive investment summary, including total amount invested, metal holdings, and returns.

**UI ELEMENTS:**
- Total investment amount
- Gold/Silver breakdown
- Returns/profit display
- Investment timeline
- Back button

**DATABASE READS:**
- ❌ **NO DATABASE QUERIES - Uses mock data**

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **View investment details:** Scrolls through investment summary
- **View asset details:** Navigate to gold/silver detail screens
- **Back:** Returns to profile screen

**BUSINESS LOGIC:**
- Displays investment summary from mock data
- Calculates totals and returns

**NOTES:**
- ❌ **ISSUE:** No database integration
- Should query `user_schemes` for total_amount_paid and accumulated_grams
- Should query `payments` for payment history

---

## SCREEN: Transaction History Screen
**FILE:** `lib/screens/customer/transaction_history_screen.dart`  
**ROUTE:** Navigated from Profile or Dashboard  
**ROLE:** Customer

**PURPOSE:**
Displays list of all customer transactions (payments, withdrawals, etc.) with filters and search.

**UI ELEMENTS:**
- Transaction list
- Filter options (all, payments, withdrawals)
- Search bar
- Transaction cards (date, amount, type, status)
- Back button

**DATABASE READS:**
- ❌ **NO DATABASE QUERIES - Uses mock data**

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **View transactions:** Scrolls through transaction list
- **Filter transactions:** Filter by type
- **Search:** Search transactions
- **Tap transaction:** Navigate to transaction detail screen
- **Back:** Returns to previous screen

**BUSINESS LOGIC:**
- Displays transactions from mock data
- Filtering and search functionality

**NOTES:**
- ❌ **ISSUE:** No database integration
- Should query `payments` table filtered by `customer_id`
- Should query `withdrawals` table (but it's unused)

---

## SCREEN: Transaction Detail Screen
**FILE:** `lib/screens/customer/transaction_detail_screen.dart`  
**ROUTE:** Navigated from Transaction History  
**ROLE:** Customer

**PURPOSE:**
Shows detailed information about a specific transaction, including receipt details.

**UI ELEMENTS:**
- Transaction details (date, amount, type, status)
- Receipt information
- Payment method
- Back button

**DATABASE READS:**
- ❌ **NO DATABASE QUERIES - Uses mock data**

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **View details:** Scrolls through transaction information
- **Back:** Returns to transaction history

**BUSINESS LOGIC:**
- Displays transaction details from mock data

**NOTES:**
- ❌ **ISSUE:** No database integration
- Should query `payments` table for specific transaction

---

## SCREEN: Withdrawal Screen
**FILE:** `lib/screens/customer/withdrawal_screen.dart`  
**ROUTE:** Navigated from Profile or Dashboard  
**ROLE:** Customer

**PURPOSE:**
Allows customers to request withdrawals from their investment.

**UI ELEMENTS:**
- Withdrawal amount input
- Withdrawal type selector (partial/full)
- Available balance display
- "Request Withdrawal" button
- Back button

**DATABASE READS:**
- ❌ **NO DATABASE QUERIES - Uses mock data**

**DATABASE WRITES:**
- ❌ **NO DATABASE WRITES** - Withdrawal requests not implemented

**USER ACTIONS:**
- **Enter withdrawal amount:** Input field for amount
- **Select withdrawal type:** Partial or full
- **Request withdrawal:** Submit withdrawal request (not implemented)
- **Back:** Returns to previous screen

**BUSINESS LOGIC:**
- Validates withdrawal amount
- Checks available balance (from mock data)
- ⚠️ **ISSUE:** Withdrawal submission not implemented

**NOTES:**
- ❌ **ISSUE:** No database integration
- Should query `user_schemes` for available balance
- Should INSERT into `withdrawals` table (but table is unused)

---

## SCREEN: Withdrawal List Screen
**FILE:** `lib/screens/customer/withdrawal_list_screen.dart`  
**ROUTE:** Navigated from Profile  
**ROLE:** Customer

**PURPOSE:**
Shows list of customer's withdrawal requests and their status.

**UI ELEMENTS:**
- Withdrawal list
- Status indicators (pending, approved, processed, rejected)
- Withdrawal details (amount, date, status)
- Back button

**DATABASE READS:**
- ⚠️ Queries `user_schemes` table (line 44)
  - Fields: `*` with `schemes(*)` join
  - Filter: `user_id = auth.uid()` - **⚠️ WRONG COLUMN** (should be `customer_id`)
  - ⚠️ **ISSUE:** Should query `withdrawals` table instead

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **View withdrawals:** Scrolls through withdrawal list
- **Tap withdrawal:** View withdrawal details (not implemented)
- **Back:** Returns to profile screen

**BUSINESS LOGIC:**
- ⚠️ **WRONG:** Queries `user_schemes` instead of `withdrawals`
- Displays withdrawal requests from wrong table

**NOTES:**
- ⚠️ **CRITICAL ISSUE:** Queries wrong table (`user_schemes` instead of `withdrawals`)
- ⚠️ **ISSUE:** Uses wrong column (`user_id` instead of `customer_id`)
- `withdrawals` table exists but is completely unused

---

## SCREEN: Account Information Page
**FILE:** `lib/screens/customer/account_information_page.dart`  
**ROUTE:** Navigated from Profile  
**ROLE:** Customer

**PURPOSE:**
Displays customer's account information, including personal details, KYC information, and nominee details.

**UI ELEMENTS:**
- Personal information section
- Contact information
- KYC details
- Nominee information
- Edit buttons (not functional)
- Back button

**DATABASE READS:**
- ❌ **NO DATABASE QUERIES - Uses mock data**

**DATABASE WRITES:**
- ❌ None (edit functionality not implemented)

**USER ACTIONS:**
- **View account info:** Scrolls through account information
- **Edit (buttons):** Edit functionality not implemented
- **Back:** Returns to profile screen

**BUSINESS LOGIC:**
- Displays account information from mock data
- ⚠️ **ISSUE:** Edit functionality not implemented

**NOTES:**
- ❌ **ISSUE:** No database integration
- Should query `profiles` and `customers` tables
- Should allow updates to customer information

---

### ========================================
### STAFF SCREENS
### ========================================

---

## SCREEN: Staff Dashboard
**FILE:** `lib/screens/staff/staff_dashboard.dart`  
**ROUTE:** `/staff-dashboard` (main screen after staff authentication)  
**ROLE:** Staff

**PURPOSE:**
Main landing screen for staff. Provides bottom navigation to Collect, Reports, and Profile tabs.

**UI ELEMENTS:**
- Bottom navigation bar (Collect, Reports, Profile)
- Tab screens (IndexedStack)
- Loading states
- Error handling

**DATABASE READS:**
- ✅ Queries `profiles` table (via `StaffDataService.getStaffProfile()`)
  - Fields: `id, name, phone, email, role, active, created_at`
- ✅ Queries `staff_metadata` table
  - Fields: `staff_code, staff_type, daily_target_amount, daily_target_customers, join_date`

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **Bottom navigation:** Switches between Collect, Reports, Profile tabs
- **Tab switching:** Changes active tab screen

**BUSINESS LOGIC:**
- Loads staff profile and metadata on init
- Passes staff data to child screens
- Handles loading and error states

**NOTES:**
- ✅ **GOOD:** Uses `StaffDataService` for data fetching
- ✅ **GOOD:** Proper error handling
- Container for tab navigation

---

## SCREEN: Collect Tab Screen
**FILE:** `lib/screens/staff/collect_tab_screen.dart`  
**ROUTE:** Tab in Staff Dashboard  
**ROLE:** Staff

**PURPOSE:**
Main collection screen showing assigned customers, today's stats, and collection progress.

**UI ELEMENTS:**
- Today's stats card (collected amount, customers, progress)
- Filter chips (All, Due Today, Pending)
- Search bar
- Customer list (cards with name, phone, scheme, due amount)
- Collection progress indicator
- Pull-to-refresh

**DATABASE READS:**
- ✅ Multiple queries via `StaffDataService`:
  - `getAssignedCustomers()` - Queries `staff_assignments`, `customers`, `profiles`, `user_schemes`, `schemes`, `payments`
  - `getDueToday()` - Filters assigned customers
  - `getPending()` - Filters assigned customers
  - `getTodayStats()` - Queries `payments`, `staff_assignments`, `user_schemes`
  - `getDailyTarget()` - Queries `staff_metadata`
  - `getTodayCollections()` - Queries `payments` with joins

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **Search customers:** Filters customer list by name/phone
- **Filter customers:** All, Due Today, Pending
- **Tap customer card:** Navigate to customer detail screen
- **Tap "Collect Payment":** Navigate to collect payment screen
- **Pull to refresh:** Reloads all data
- **Tap stats card:** Navigate to today target detail

**BUSINESS LOGIC:**
- Loads all data in parallel (6 queries)
- Filters customers by search query and filter type
- Calculates progress percentage
- Handles loading and error states

**NOTES:**
- ✅ **GOOD:** Comprehensive database integration
- ✅ **GOOD:** Efficient parallel data loading
- Complex query chain for customer data

---

## SCREEN: Collect Payment Screen
**FILE:** `lib/screens/staff/collect_payment_screen.dart`  
**ROUTE:** Navigated from Collect Tab Screen  
**ROLE:** Staff

**PURPOSE:**
Allows staff to record a payment from a customer, including amount, payment method, and GST calculation.

**UI ELEMENTS:**
- Customer information display
- Amount input field
- Quick amount chips (min, mid, max, missed payments total)
- Payment method selector (Cash, UPI)
- GST breakdown display
- Metal rate display
- "Collect Payment" button
- Loading indicator

**DATABASE READS:**
- ✅ Queries `market_rates` table (via `PaymentService.getCurrentMarketRate()`)
  - Fields: `price_per_gram`
  - Filter: `asset_type = gold/silver`, ordered by `rate_date DESC`, limit 1
- ✅ Queries `profiles` table (via `RoleRoutingService.getCurrentProfileId()`)
- ✅ Queries `customers` table (via `PaymentService.getCustomerIdFromData()`)
- ✅ Queries `user_schemes` table (via `PaymentService.getUserSchemeId()`)
- ✅ Queries `staff_assignments` table (for verification)

**DATABASE WRITES:**
- ✅ **INSERT into `payments` table** (via `PaymentService.insertPayment()`)
  - Fields: `user_scheme_id`, `customer_id`, `staff_id`, `amount`, `gst_amount`, `net_amount`, `payment_method`, `payment_date`, `payment_time`, `status`, `metal_rate_per_gram`, `metal_grams_added`, `is_reversal`, `device_id`, `client_timestamp`
  - ⚠️ **ISSUE:** Currently blocked by RLS policy

**USER ACTIONS:**
- **Enter amount:** Manual amount input
- **Tap quick amount:** Pre-fills amount
- **Select payment method:** Cash or UPI
- **Tap "Collect Payment":** Validates and inserts payment
- **Back:** Returns to collect tab screen

**BUSINESS LOGIC:**
- Amount validation (must be >= min amount)
- GST calculation (3% of amount)
- Net amount calculation (97% of amount)
- Metal grams calculation (net_amount / metal_rate_per_gram)
- Payment insertion with all required fields
- Success/error handling

**NOTES:**
- ✅ **GOOD:** Comprehensive payment recording
- ⚠️ **ISSUE:** Payment INSERT currently blocked by RLS
- ✅ **GOOD:** Proper validation and error handling
- ✅ **GOOD:** Uses `PaymentService` for database operations

---

## SCREEN: Customer Detail Screen
**FILE:** `lib/screens/staff/customer_detail_screen.dart`  
**ROUTE:** Navigated from Collect Tab Screen or Reports Screen  
**ROLE:** Staff

**PURPOSE:**
Shows detailed information about a customer, including payment history, scheme details, and collection options.

**UI ELEMENTS:**
- Customer information header
- Scheme details
- Payment history list
- "Collect Payment" button
- Back button

**DATABASE READS:**
- ✅ Queries `payments` table (via `StaffDataService.getPaymentHistory()`)
  - Fields: `payment_date, amount, status, payment_method`
  - Filter: `customer_id = X`
  - Order: `payment_date DESC`, limit 50

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **View payment history:** Scrolls through payment list
- **Tap "Collect Payment":** Navigate to collect payment screen
- **Back:** Returns to previous screen

**BUSINESS LOGIC:**
- Fetches payment history for customer
- Displays payment details with formatting

**NOTES:**
- ✅ **GOOD:** Database integration for payment history
- Should also display customer profile and scheme details

---

## SCREEN: Customer List Screen
**FILE:** `lib/screens/staff/customer_list_screen.dart`  
**ROUTE:** Navigated from Reports Screen  
**ROLE:** Staff

**PURPOSE:**
Shows list of all assigned customers with search and filter options.

**UI ELEMENTS:**
- Search bar
- Customer list
- Filter options
- Customer cards
- Back button

**DATABASE READS:**
- ✅ Queries via `StaffDataService.getAssignedCustomers()`
  - Same query chain as Collect Tab Screen

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **Search customers:** Filters by name/phone
- **Tap customer:** Navigate to customer detail screen
- **Back:** Returns to reports screen

**BUSINESS LOGIC:**
- Loads assigned customers
- Search and filter functionality

**NOTES:**
- ✅ **GOOD:** Uses same data service as Collect Tab
- Similar functionality to Collect Tab Screen

---

## SCREEN: Payment Collection Screen
**FILE:** `lib/screens/staff/payment_collection_screen.dart`  
**ROUTE:** Navigated from Reports Screen  
**ROLE:** Staff

**PURPOSE:**
Alternative payment collection screen (may be duplicate of Collect Payment Screen).

**UI ELEMENTS:**
- Similar to Collect Payment Screen
- Payment form
- Customer selection

**DATABASE READS:**
- ⚠️ **UNKNOWN** - Need to verify implementation

**DATABASE WRITES:**
- ⚠️ **UNKNOWN** - Need to verify implementation

**USER ACTIONS:**
- **Collect payment:** Record payment from customer

**BUSINESS LOGIC:**
- ⚠️ **UNKNOWN** - Need to verify implementation

**NOTES:**
- ⚠️ **POTENTIAL DUPLICATE:** May be duplicate of Collect Payment Screen
- Need to verify if this screen is actually used

---

## SCREEN: Reports Screen
**FILE:** `lib/screens/staff/reports_screen.dart`  
**ROUTE:** Tab in Staff Dashboard  
**ROLE:** Staff

**PURPOSE:**
Shows comprehensive reports and analytics for staff, including today's performance, priority customers, and scheme breakdown.

**UI ELEMENTS:**
- Today's performance card
- Priority customers list (with missed payments)
- Scheme breakdown (Gold vs Silver)
- Best day details
- Customer list access
- Payment collection access

**DATABASE READS:**
- ✅ Multiple queries via `StaffDataService`:
  - `getTodayStats()` - Queries `payments`, `staff_assignments`, `user_schemes`
  - `getPriorityCustomers()` - Filters assigned customers with missed payments
  - `getSchemeBreakdown()` - Queries `payments` with `user_schemes` and `schemes` joins

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **View performance:** Scrolls through performance metrics
- **View priority customers:** See customers with missed payments
- **View scheme breakdown:** See Gold vs Silver collections
- **Tap customer:** Navigate to customer detail screen
- **Tap "Collect Payment":** Navigate to collect payment screen
- **Tap "View All Customers":** Navigate to customer list screen
- **Tap "Best Day Details":** Navigate to today target detail screen

**BUSINESS LOGIC:**
- Loads all report data in parallel
- Calculates GST breakdown (3% of total)
- Calculates net investment (97% of total)
- Filters priority customers by missed payments
- Groups payments by asset type

**NOTES:**
- ✅ **GOOD:** Comprehensive database integration
- ✅ **GOOD:** Complex queries with joins
- Displays detailed analytics

---

## SCREEN: Today Target Detail Screen
**FILE:** `lib/screens/staff/today_target_detail_screen.dart`  
**ROUTE:** Navigated from Collect Tab or Reports Screen  
**ROLE:** Staff

**PURPOSE:**
Shows detailed breakdown of today's target, including customer-by-customer progress.

**UI ELEMENTS:**
- Target amount and customers
- Progress indicators
- Customer list with payment status
- Collection details
- Back button

**DATABASE READS:**
- ✅ Queries via `StaffDataService`:
  - `getDailyTarget()` - Queries `staff_metadata`
  - `getAssignedCustomers()` - Full customer list
  - `getTodayStats()` - Today's collections

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **View target details:** Scrolls through target breakdown
- **Tap customer:** Navigate to customer detail screen
- **Back:** Returns to previous screen

**BUSINESS LOGIC:**
- Displays target vs actual
- Shows customer-by-customer progress
- Calculates completion percentage

**NOTES:**
- ✅ **GOOD:** Database integration
- Detailed target tracking

---

## SCREEN: Staff Profile Screen
**FILE:** `lib/screens/staff/staff_profile_screen.dart`  
**ROUTE:** Tab in Staff Dashboard  
**ROLE:** Staff

**PURPOSE:**
Shows staff profile information and provides access to account settings and logout.

**UI ELEMENTS:**
- Profile header (name, staff code, staff type)
- Profile information
- Account info access
- Settings access
- Logout button

**DATABASE READS:**
- ✅ Queries `profiles` table (via `StaffDataService.getStaffProfile()`)
- ✅ Queries `staff_metadata` table

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **View profile:** Scrolls through profile information
- **Tap "Account Info":** Navigate to staff account info screen
- **Tap "Settings":** Navigate to staff settings screen
- **Tap "Logout":** Signs out and returns to login screen

**BUSINESS LOGIC:**
- Loads staff profile and metadata
- Displays staff information

**NOTES:**
- ✅ **GOOD:** Database integration
- Proper logout functionality

---

## SCREEN: Staff Account Info Screen
**FILE:** `lib/screens/staff/staff_account_info_screen.dart`  
**ROUTE:** Navigated from Staff Profile  
**ROLE:** Staff

**PURPOSE:**
Shows detailed staff account information.

**UI ELEMENTS:**
- Account details
- Staff code
- Join date
- Target information
- Back button

**DATABASE READS:**
- ⚠️ **UNKNOWN** - Need to verify implementation

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **View account info:** Scrolls through account information
- **Back:** Returns to staff profile screen

**BUSINESS LOGIC:**
- ⚠️ **UNKNOWN** - Need to verify implementation

**NOTES:**
- Need to verify database integration

---

## SCREEN: Staff Settings Screen
**FILE:** `lib/screens/staff/staff_settings_screen.dart`  
**ROUTE:** Navigated from Staff Profile  
**ROLE:** Staff

**PURPOSE:**
Provides staff settings and preferences.

**UI ELEMENTS:**
- Settings options
- Preferences
- Back button

**DATABASE READS:**
- ❌ **NO DATABASE QUERIES**

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **View settings:** Scrolls through settings options
- **Back:** Returns to staff profile screen

**BUSINESS LOGIC:**
- Displays settings (likely static)

**NOTES:**
- ⚠️ **ISSUE:** No database integration
- Settings likely not functional

---

### ========================================
### SHARED/PROFILE SCREENS
### ========================================

---

## SCREEN: Settings Screen
**FILE:** `lib/screens/profile/settings_screen.dart`  
**ROUTE:** Navigated from Customer Profile  
**ROLE:** Customer

**PURPOSE:**
Provides app settings and preferences for customers.

**UI ELEMENTS:**
- Settings options
- Preferences
- Help & Support access
- Privacy Policy access
- Terms & Conditions access
- Back button

**DATABASE READS:**
- ❌ **NO DATABASE QUERIES**

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **View settings:** Scrolls through settings options
- **Navigate to help:** Opens help & support screen
- **Navigate to privacy:** Opens privacy policy screen
- **Navigate to terms:** Opens terms & conditions screen
- **Back:** Returns to profile screen

**BUSINESS LOGIC:**
- Static settings display
- Navigation to other screens

**NOTES:**
- ⚠️ **ISSUE:** No database integration
- Settings likely not functional

---

## SCREEN: Help & Support Screen
**FILE:** `lib/screens/profile/help_support_screen.dart`  
**ROUTE:** Navigated from Settings  
**ROLE:** All

**PURPOSE:**
Displays help and support information, FAQs, and contact details.

**UI ELEMENTS:**
- Help content
- FAQ section
- Contact information
- Back button

**DATABASE READS:**
- ❌ **NO DATABASE QUERIES** - Static content

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **View help:** Scrolls through help content
- **Back:** Returns to settings screen

**BUSINESS LOGIC:**
- Static content display

**NOTES:**
- Static screen - no database needed

---

## SCREEN: Privacy Policy Screen
**FILE:** `lib/screens/profile/privacy_policy_screen.dart`  
**ROUTE:** Navigated from Settings  
**ROLE:** All

**PURPOSE:**
Displays privacy policy text.

**UI ELEMENTS:**
- Privacy policy text
- Back button

**DATABASE READS:**
- ❌ **NO DATABASE QUERIES** - Static content

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **View policy:** Scrolls through privacy policy
- **Back:** Returns to settings screen

**BUSINESS LOGIC:**
- Static content display

**NOTES:**
- Static screen - no database needed

---

## SCREEN: Terms & Conditions Screen
**FILE:** `lib/screens/profile/terms_conditions_screen.dart`  
**ROUTE:** Navigated from Settings  
**ROLE:** All

**PURPOSE:**
Displays terms and conditions text.

**UI ELEMENTS:**
- Terms and conditions text
- Back button

**DATABASE READS:**
- ❌ **NO DATABASE QUERIES** - Static content

**DATABASE WRITES:**
- ❌ None

**USER ACTIONS:**
- **View terms:** Scrolls through terms and conditions
- **Back:** Returns to settings screen

**BUSINESS LOGIC:**
- Static content display

**NOTES:**
- Static screen - no database needed

---

## SUMMARY STATISTICS

### Screen Count by Category:
- **Authentication:** 8 screens
- **Customer:** 15 screens
- **Staff:** 13 screens
- **Shared/Profile:** 4 screens
- **Total:** 40 screens (some may be duplicates)

### Database Usage:
- **Screens with Database Reads:** 12 screens (30%)
- **Screens with Database Writes:** 2 screens (5%)
- **Screens with No Database:** 26 screens (65%)

### Most Database-Intensive Screens:
1. **Collect Tab Screen** - 6 parallel queries
2. **Reports Screen** - 3 parallel queries
3. **Collect Payment Screen** - 5 queries + 1 INSERT
4. **Customer Dashboard** - 1 query (but wrong column)

### Critical Issues Found:
1. **Customer Dashboard** - Uses `user_id` instead of `customer_id` (schema mismatch)
2. **Withdrawal List Screen** - Queries `user_schemes` instead of `withdrawals` table
3. **Staff PIN Setup** - Tries to update `staff` table (doesn't exist)
4. **Login/OTP Screens** - Query `users` table instead of `profiles`
5. **Most Customer Screens** - No database integration, use mock data

### User Journeys:

**Customer Journey:**
1. Login Screen → OTP Screen → PIN Setup → Biometric Setup → Dashboard
2. Dashboard → Schemes → Scheme Detail
3. Dashboard → Profile → Account Info / Transaction History / etc.

**Staff Journey:**
1. Staff Login → Staff PIN Setup → Staff Dashboard
2. Staff Dashboard → Collect Tab → Customer Detail → Collect Payment
3. Staff Dashboard → Reports → Customer Detail / Today Target Detail

---

## RECOMMENDATIONS

### Priority 1: Fix Critical Schema Mismatches
1. Fix Customer Dashboard query (`user_id` → `customer_id`)
2. Fix Withdrawal List Screen (query `withdrawals` table)
3. Fix Login/OTP screens (`users` → `profiles`)
4. Fix Staff PIN Setup (remove `staff` table reference)

### Priority 2: Add Database Integration
1. Replace mock data in customer screens with real queries
2. Implement withdrawal functionality (use `withdrawals` table)
3. Add profile update functionality
4. Add scheme enrollment functionality

### Priority 3: Standardize Navigation
1. Replace all `Navigator` calls with `AuthFlowNotifier` for auth flows
2. Ensure consistent navigation patterns

---

**END OF ANALYSIS**

