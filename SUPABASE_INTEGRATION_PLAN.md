# SLG Thangangal - Supabase Integration Plan

**Project:** Gold/Silver Investment Scheme App  
**Deadline:** 12 days  
**Date:** December 2024

---

## 1. AUDIT REPORT

### 1.1 All Screens

#### User (Customer) Screens (15 screens)
1. `lib/screens/login_screen.dart` - Phone number login
2. `lib/screens/otp_screen.dart` - OTP verification
3. `lib/screens/auth/pin_setup_screen.dart` - PIN setup
4. `lib/screens/auth/pin_login_screen.dart` - PIN login
5. `lib/screens/auth/biometric_setup_screen.dart` - Biometric setup
6. `lib/screens/customer/dashboard_screen.dart` - Main dashboard
7. `lib/screens/customer/schemes_screen.dart` - Browse schemes
8. `lib/screens/customer/scheme_detail_screen.dart` - Scheme details
9. `lib/screens/customer/payment_schedule_screen.dart` - Payment calendar
10. `lib/screens/customer/transaction_history_screen.dart` - All transactions
11. `lib/screens/customer/transaction_detail_screen.dart` - Transaction details
12. `lib/screens/customer/total_investment_screen.dart` - Investment summary
13. `lib/screens/customer/gold_asset_detail_screen.dart` - Gold holdings
14. `lib/screens/customer/silver_asset_detail_screen.dart` - Silver holdings
15. `lib/screens/customer/market_rates_screen.dart` - Gold/Silver rates
16. `lib/screens/customer/profile_screen.dart` - User profile
17. `lib/screens/customer/account_information_page.dart` - Account details
18. `lib/screens/profile/settings_screen.dart` - App settings
19. `lib/screens/profile/help_support_screen.dart` - Help & support
20. `lib/screens/profile/privacy_policy_screen.dart` - Privacy policy
21. `lib/screens/profile/terms_conditions_screen.dart` - Terms & conditions

#### Staff Screens (12 screens)
1. `lib/screens/staff/staff_login_screen.dart` - Staff login (ID/Password)
2. `lib/screens/staff/staff_dashboard.dart` - Main dashboard (3 tabs)
3. `lib/screens/staff/collect_tab_screen.dart` - Collection tab (main)
4. `lib/screens/staff/today_target_detail_screen.dart` - Target breakdown
5. `lib/screens/staff/customer_detail_screen.dart` - Customer details
6. `lib/screens/staff/collect_payment_screen.dart` - Record payment
7. `lib/screens/staff/payment_collection_screen.dart` - Quick collection
8. `lib/screens/staff/customer_list_screen.dart` - All customers (unused)
9. `lib/screens/staff/reports_screen.dart` - Reports & analytics
10. `lib/screens/staff/staff_profile_screen.dart` - Staff profile
11. `lib/screens/staff/staff_account_info_screen.dart` - Account info
12. `lib/screens/staff/staff_settings_screen.dart` - Settings

### 1.2 Mock Data Files

1. **`lib/mock_data/staff_mock_data.dart`**
   - Staff credentials (SLG001, SLG002)
   - Staff info (name, phone, email, role, joinDate, assignedCustomers)
   - 42 assigned customers with full details
   - Payment history per customer
   - Today's collections
   - Daily targets (amount: 45000, customers: 42)
   - Helper methods for stats

2. **`lib/utils/mock_data.dart`**
   - User portfolio data (gold/silver grams, values)
   - Market rates (gold/silver prices)
   - 18 scheme definitions (9 Gold + 9 Silver)
   - Active schemes for user
   - Payment calendar preview
   - Transaction history
   - Account information
   - Nominee data

### 1.3 Services/Helpers

1. **`lib/services/auth_service.dart`** ✅ **READY FOR SUPABASE**
   - Already uses Supabase
   - `sendOTP()`, `verifyOTP()`, `signOut()`, `getCurrentUser()`
   - Auth state stream

2. **`lib/utils/secure_storage_helper.dart`** - Secure storage for PIN/biometric
3. **`lib/utils/biometric_helper.dart`** - Biometric authentication
4. **`lib/utils/constants.dart`** - App colors, spacing, text styles

### 1.4 Mock Data vs Real Data Status

#### ✅ **READY FOR REAL DATA** (Has Supabase queries)
- `lib/services/auth_service.dart` - Already using Supabase auth
- `lib/screens/customer/dashboard_screen.dart` - Has `_fetchActiveSchemes()` with Supabase query (lines 1369-1416)

#### ❌ **USING MOCK DATA** (Needs integration)
- All staff screens - Using `StaffMockData`
- Customer screens (except dashboard) - Using `MockData`
- Payment collection - Mock data
- Reports - Mock calculations
- Transaction history - Mock data
- Scheme listings - Mock data

### 1.5 Dependencies Currently Installed

```yaml
dependencies:
  flutter: sdk
  cupertino_icons: ^1.0.8
  supabase_flutter: ^2.10.3          # ✅ Already installed
  flutter_dotenv: ^6.0.0             # ✅ Already installed
  shared_preferences: ^2.5.3
  flutter_secure_storage: ^9.2.4
  local_auth: ^2.1.7
  crypto: ^3.0.3
  google_fonts: ^6.2.1
  sms_autofill: ^2.3.0
  image_picker: ^1.0.7
  url_launcher: ^6.2.0
  intl: ^0.18.1
```

### 1.6 Missing Dependencies for Supabase Integration

**All required dependencies are already installed!** ✅

Optional but recommended:
- `connectivity_plus: ^6.0.0` - For offline detection
- `sqflite: ^2.3.0` - For local caching (if needed)

---

## 2. DATABASE REQUIREMENTS

### 2.1 Database Schema

Based on code analysis, here are the required tables:

#### **Table: `customers` (users)**
Stores customer/user information.

```sql
CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  date_of_birth DATE,
  father_name TEXT,
  birth_place TEXT,
  aadhaar_no TEXT,
  gender TEXT CHECK (gender IN ('Male', 'Female', 'Other')),
  business_address TEXT,
  residential_address TEXT,
  email TEXT,
  customer_id TEXT UNIQUE, -- CUST-2024-001 format
  book_no TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_customers_phone ON customers(phone);
CREATE INDEX idx_customers_customer_id ON customers(customer_id);
CREATE INDEX idx_customers_active ON customers(is_active);
```

#### **Table: `nominees`**
Stores nominee information for customers.

```sql
CREATE TABLE nominees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  gender TEXT CHECK (gender IN ('Male', 'Female', 'Other')),
  father_name TEXT,
  age INTEGER,
  relationship TEXT NOT NULL, -- Spouse, Father, Mother, etc.
  birth_place TEXT,
  address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(customer_id)
);

CREATE INDEX idx_nominees_customer ON nominees(customer_id);
```

#### **Table: `schemes`**
Stores the 18 investment schemes (9 Gold + 9 Silver).

```sql
CREATE TABLE schemes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scheme_id TEXT UNIQUE NOT NULL, -- gold-scheme-1, silver-scheme-1, etc.
  name TEXT NOT NULL, -- Gold Scheme 1, Silver Scheme 1
  asset_type TEXT NOT NULL CHECK (asset_type IN ('gold', 'silver')),
  variant_id TEXT, -- Links to corresponding silver/gold scheme
  active BOOLEAN DEFAULT TRUE,
  tagline TEXT,
  min_daily_amount DECIMAL(10,2) NOT NULL,
  max_daily_amount DECIMAL(10,2) NOT NULL,
  installment_amount DECIMAL(10,2), -- Average
  frequency TEXT DEFAULT 'daily' CHECK (frequency IN ('daily', 'weekly', 'monthly')),
  duration_months INTEGER DEFAULT 12,
  metal_accumulation TEXT, -- "2 g", "100 g", etc.
  entry_fee DECIMAL(10,2) DEFAULT 0,
  total_investment DECIMAL(12,2), -- Expected total
  expected_grams DECIMAL(8,3), -- Expected metal in grams
  current_price DECIMAL(10,2), -- Current metal price per gram
  features JSONB, -- Array of feature strings
  how_it_works JSONB, -- Array of step strings
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_schemes_asset_type ON schemes(asset_type);
CREATE INDEX idx_schemes_active ON schemes(active);
CREATE INDEX idx_schemes_scheme_id ON schemes(scheme_id);
```

#### **Table: `user_schemes` (enrollments)**
Stores customer enrollments in schemes.

```sql
CREATE TABLE user_schemes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  scheme_id UUID REFERENCES schemes(id) ON DELETE RESTRICT,
  enrollment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  start_date DATE NOT NULL,
  maturity_date DATE NOT NULL,
  payment_frequency TEXT NOT NULL CHECK (payment_frequency IN ('daily', 'weekly', 'monthly')),
  min_amount DECIMAL(10,2) NOT NULL, -- Customer's chosen min
  max_amount DECIMAL(10,2) NOT NULL, -- Customer's chosen max
  due_amount DECIMAL(10,2) NOT NULL, -- Current due amount
  total_payments INTEGER DEFAULT 0, -- Total payments made
  missed_payments INTEGER DEFAULT 0, -- Count of missed payments
  total_amount_paid DECIMAL(12,2) DEFAULT 0,
  accumulated_metal_grams DECIMAL(10,3) DEFAULT 0, -- Actual accumulated
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled', 'paused')),
  entry_fee_paid BOOLEAN DEFAULT FALSE,
  entry_fee_amount DECIMAL(10,2) DEFAULT 0,
  assigned_staff_id UUID REFERENCES staff(id), -- Collection agent
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_user_schemes_customer ON user_schemes(customer_id);
CREATE INDEX idx_user_schemes_scheme ON user_schemes(scheme_id);
CREATE INDEX idx_user_schemes_status ON user_schemes(status);
CREATE INDEX idx_user_schemes_staff ON user_schemes(assigned_staff_id);
CREATE INDEX idx_user_schemes_active ON user_schemes(customer_id, status) WHERE status = 'active';
```

#### **Table: `staff`**
Stores staff/collection agent information.

```sql
CREATE TABLE staff (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id TEXT UNIQUE NOT NULL, -- SLG001, SLG002, etc.
  password_hash TEXT NOT NULL, -- Hashed password
  name TEXT NOT NULL,
  phone TEXT UNIQUE NOT NULL,
  email TEXT,
  role TEXT DEFAULT 'Collection Agent',
  join_date DATE NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  daily_target_amount DECIMAL(10,2) DEFAULT 0,
  daily_target_customers INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_staff_staff_id ON staff(staff_id);
CREATE INDEX idx_staff_phone ON staff(phone);
CREATE INDEX idx_staff_active ON staff(is_active);
```

#### **Table: `payments`**
Stores all payment records.

```sql
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_scheme_id UUID REFERENCES user_schemes(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  staff_id UUID REFERENCES staff(id), -- Who collected (if staff)
  amount DECIMAL(10,2) NOT NULL,
  payment_method TEXT NOT NULL CHECK (payment_method IN ('cash', 'gpay', 'upi', 'bank_transfer')),
  payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  payment_time TIME, -- For staff collections
  status TEXT DEFAULT 'paid' CHECK (status IN ('paid', 'missed', 'refunded')),
  receipt_id TEXT UNIQUE, -- RCP-001 format
  notes TEXT,
  gold_rate_at_payment DECIMAL(10,2), -- Snapshot of rate
  silver_rate_at_payment DECIMAL(10,2), -- Snapshot of rate
  metal_grams_added DECIMAL(10,3), -- Metal accumulated from this payment
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_payments_user_scheme ON payments(user_scheme_id);
CREATE INDEX idx_payments_customer ON payments(customer_id);
CREATE INDEX idx_payments_staff ON payments(staff_id);
CREATE INDEX idx_payments_date ON payments(payment_date);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_customer_date ON payments(customer_id, payment_date DESC);
```

#### **Table: `payment_schedule`**
Stores expected payment dates for each enrollment.

```sql
CREATE TABLE payment_schedule (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_scheme_id UUID REFERENCES user_schemes(id) ON DELETE CASCADE,
  due_date DATE NOT NULL,
  expected_amount DECIMAL(10,2) NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'missed', 'skipped')),
  payment_id UUID REFERENCES payments(id), -- If paid, link to payment
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_scheme_id, due_date)
);

CREATE INDEX idx_payment_schedule_user_scheme ON payment_schedule(user_scheme_id);
CREATE INDEX idx_payment_schedule_due_date ON payment_schedule(due_date);
CREATE INDEX idx_payment_schedule_status ON payment_schedule(status);
CREATE INDEX idx_payment_schedule_pending ON payment_schedule(user_scheme_id, status) WHERE status = 'pending';
```

#### **Table: `market_rates`**
Stores historical gold/silver rates.

```sql
CREATE TABLE market_rates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rate_date DATE NOT NULL DEFAULT CURRENT_DATE,
  gold_rate_per_gram DECIMAL(10,2) NOT NULL,
  silver_rate_per_gram DECIMAL(10,2) NOT NULL,
  gold_change DECIMAL(10,2) DEFAULT 0, -- Change from previous day
  silver_change DECIMAL(10,2) DEFAULT 0,
  gold_change_percent DECIMAL(5,2) DEFAULT 0,
  silver_change_percent DECIMAL(5,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(rate_date)
);

CREATE INDEX idx_market_rates_date ON market_rates(rate_date DESC);
```

#### **Table: `staff_assignments`**
Tracks which customers are assigned to which staff.

```sql
CREATE TABLE staff_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id UUID REFERENCES staff(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  user_scheme_id UUID REFERENCES user_schemes(id) ON DELETE CASCADE,
  assigned_date DATE NOT NULL DEFAULT CURRENT_DATE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(staff_id, customer_id, user_scheme_id)
);

CREATE INDEX idx_staff_assignments_staff ON staff_assignments(staff_id, is_active);
CREATE INDEX idx_staff_assignments_customer ON staff_assignments(customer_id);
```

### 2.2 Row Level Security (RLS) Policies

```sql
-- Enable RLS on all tables
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE nominees ENABLE ROW LEVEL SECURITY;
ALTER TABLE schemes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_schemes ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_schedule ENABLE ROW LEVEL SECURITY;
ALTER TABLE market_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_assignments ENABLE ROW LEVEL SECURITY;

-- Customers can only see their own data
CREATE POLICY "Customers can view own data"
  ON customers FOR SELECT
  USING (auth.uid()::text = id::text);

-- Customers can see their own schemes
CREATE POLICY "Customers can view own schemes"
  ON user_schemes FOR SELECT
  USING (
    customer_id IN (
      SELECT id FROM customers WHERE id::text = auth.uid()::text
    )
  );

-- Customers can see their own payments
CREATE POLICY "Customers can view own payments"
  ON payments FOR SELECT
  USING (
    customer_id IN (
      SELECT id FROM customers WHERE id::text = auth.uid()::text
    )
  );

-- Staff can view assigned customers
CREATE POLICY "Staff can view assigned customers"
  ON customers FOR SELECT
  USING (
    id IN (
      SELECT customer_id FROM staff_assignments 
      WHERE staff_id IN (
        SELECT id FROM staff WHERE staff_id = current_setting('app.current_staff_id', true)
      )
    )
  );

-- Staff can view assigned user_schemes
CREATE POLICY "Staff can view assigned schemes"
  ON user_schemes FOR SELECT
  USING (
    assigned_staff_id IN (
      SELECT id FROM staff WHERE staff_id = current_setting('app.current_staff_id', true)
    )
  );

-- Staff can insert payments for assigned customers
CREATE POLICY "Staff can insert payments"
  ON payments FOR INSERT
  WITH CHECK (
    customer_id IN (
      SELECT customer_id FROM staff_assignments 
      WHERE staff_id IN (
        SELECT id FROM staff WHERE staff_id = current_setting('app.current_staff_id', true)
      ) AND is_active = true
    )
  );

-- Market rates are public (read-only for all)
CREATE POLICY "Market rates are public"
  ON market_rates FOR SELECT
  TO authenticated
  USING (true);

-- Schemes are public (read-only for all authenticated)
CREATE POLICY "Schemes are public"
  ON schemes FOR SELECT
  TO authenticated
  USING (active = true);
```

### 2.3 Functions & Triggers

```sql
-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables
CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_schemes_updated_at BEFORE UPDATE ON user_schemes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to calculate accumulated metal
CREATE OR REPLACE FUNCTION calculate_metal_accumulated(
  p_user_scheme_id UUID,
  p_payment_amount DECIMAL,
  p_metal_type TEXT
)
RETURNS DECIMAL AS $$
DECLARE
  v_rate DECIMAL;
  v_grams DECIMAL;
BEGIN
  -- Get current rate
  SELECT 
    CASE 
      WHEN p_metal_type = 'gold' THEN gold_rate_per_gram
      ELSE silver_rate_per_gram
    END INTO v_rate
  FROM market_rates
  ORDER BY rate_date DESC
  LIMIT 1;
  
  -- Calculate grams
  v_grams := p_payment_amount / v_rate;
  
  RETURN v_grams;
END;
$$ LANGUAGE plpgsql;

-- Function to update user_scheme stats after payment
CREATE OR REPLACE FUNCTION update_user_scheme_on_payment()
RETURNS TRIGGER AS $$
BEGIN
  -- Update total payments and amount
  UPDATE user_schemes
  SET 
    total_payments = total_payments + 1,
    total_amount_paid = total_amount_paid + NEW.amount,
    accumulated_metal_grams = accumulated_metal_grams + COALESCE(NEW.metal_grams_added, 0),
    updated_at = NOW()
  WHERE id = NEW.user_scheme_id;
  
  -- Update payment schedule
  UPDATE payment_schedule
  SET 
    status = 'paid',
    payment_id = NEW.id,
    updated_at = NOW()
  WHERE user_scheme_id = NEW.user_scheme_id
    AND due_date = NEW.payment_date
    AND status = 'pending';
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_payment_insert
  AFTER INSERT ON payments
  FOR EACH ROW
  EXECUTE FUNCTION update_user_scheme_on_payment();
```

---

## 3. SUPABASE INTEGRATION PLAN

### Step 1: Setup Supabase Project (Day 1 - 2 hours)

1. **Create Supabase Project**
   - Go to https://supabase.com
   - Create new project
   - Note: Project URL and anon key

2. **Configure Environment Variables**
   ```bash
   # Create .env file in project root
   SUPABASE_URL=your-project-url
   SUPABASE_ANON_KEY=your-anon-key
   ```

3. **Update `lib/main.dart`**
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';
   import 'package:supabase_flutter/supabase_flutter.dart';

   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     
     await dotenv.load(fileName: ".env");
     
     await Supabase.initialize(
       url: dotenv.env['SUPABASE_URL']!,
       anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
     );
     
     runApp(MyApp());
   }
   ```

### Step 2: Create Database Schema (Day 1 - 4 hours)

1. **Run SQL Scripts**
   - Open Supabase SQL Editor
   - Run all CREATE TABLE statements from Section 2.1
   - Run RLS policies from Section 2.2
   - Run functions and triggers from Section 2.3

2. **Seed Initial Data**
   ```sql
   -- Insert 18 schemes
   INSERT INTO schemes (scheme_id, name, asset_type, variant_id, ...) VALUES
   ('gold-scheme-1', 'Gold Scheme 1', 'gold', 'silver-scheme-1', ...),
   -- ... (all 18 schemes)
   ```

3. **Create Staff Users**
   ```sql
   -- Insert staff (password will be hashed in app)
   INSERT INTO staff (staff_id, name, phone, email, role, join_date) VALUES
   ('SLG001', 'Rajesh Kumar', '+91 9988776655', 'rajesh@slggolds.com', 'Collection Agent', '2024-01-01'),
   ('SLG002', 'Priya Sharma', '+91 9876543210', 'priya@slggolds.com', 'Collection Agent', '2024-02-15');
   ```

### Step 3: Create Service Layer (Day 2-3 - 8 hours)

#### **3.1 Customer Service** (`lib/services/customer_service.dart`)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerService {
  final _supabase = Supabase.instance.client;

  // Get customer profile
  Future<Map<String, dynamic>?> getCustomerProfile(String userId) async {
    final response = await _supabase
        .from('customers')
        .select('*, nominees(*)')
        .eq('id', userId)
        .single();
    return response;
  }

  // Get active schemes for customer
  Future<List<Map<String, dynamic>>> getActiveSchemes(String userId) async {
    final response = await _supabase
        .from('user_schemes')
        .select('*, schemes(*)')
        .eq('customer_id', userId)
        .eq('status', 'active')
        .order('enrollment_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Get payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory(
    String userId, {
    int limit = 50,
  }) async {
    final response = await _supabase
        .from('payments')
        .select('*, user_schemes(schemes(name))')
        .eq('customer_id', userId)
        .order('payment_date', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  // Get payment schedule
  Future<List<Map<String, dynamic>>> getPaymentSchedule(
    String userSchemeId,
  ) async {
    final response = await _supabase
        .from('payment_schedule')
        .select('*')
        .eq('user_scheme_id', userSchemeId)
        .order('due_date', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // Get market rates
  Future<Map<String, dynamic>?> getLatestMarketRates() async {
    final response = await _supabase
        .from('market_rates')
        .select('*')
        .order('rate_date', ascending: false)
        .limit(1)
        .single();
    return response;
  }

  // Enroll in scheme
  Future<Map<String, dynamic>> enrollInScheme({
    required String customerId,
    required String schemeId,
    required String paymentFrequency,
    required double minAmount,
    required double maxAmount,
    required DateTime startDate,
  }) async {
    // Get scheme details
    final scheme = await _supabase
        .from('schemes')
        .select('*')
        .eq('id', schemeId)
        .single();

    // Calculate maturity date (12 months from start)
    final maturityDate = DateTime(
      startDate.year + 1,
      startDate.month,
      startDate.day,
    );

    // Create enrollment
    final enrollment = await _supabase
        .from('user_schemes')
        .insert({
          'customer_id': customerId,
          'scheme_id': schemeId,
          'start_date': startDate.toIso8601String(),
          'maturity_date': maturityDate.toIso8601String(),
          'payment_frequency': paymentFrequency,
          'min_amount': minAmount,
          'max_amount': maxAmount,
          'due_amount': (minAmount + maxAmount) / 2,
        })
        .select()
        .single();

    // Generate payment schedule
    await _generatePaymentSchedule(
      enrollment['id'],
      startDate,
      maturityDate,
      paymentFrequency,
      (minAmount + maxAmount) / 2,
    );

    return enrollment;
  }

  Future<void> _generatePaymentSchedule(
    String userSchemeId,
    DateTime startDate,
    DateTime maturityDate,
    String frequency,
    double amount,
  ) async {
    final dates = <DateTime>[];
    var current = startDate;

    while (current.isBefore(maturityDate)) {
      dates.add(current);
      switch (frequency) {
        case 'daily':
          current = current.add(Duration(days: 1));
          break;
        case 'weekly':
          current = current.add(Duration(days: 7));
          break;
        case 'monthly':
          current = DateTime(current.year, current.month + 1, current.day);
          break;
      }
    }

    final schedule = dates.map((date) => {
      'user_scheme_id': userSchemeId,
      'due_date': date.toIso8601String(),
      'expected_amount': amount,
      'status': 'pending',
    }).toList();

    await _supabase.from('payment_schedule').insert(schedule);
  }
}
```

#### **3.2 Staff Service** (`lib/services/staff_service.dart`)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class StaffService {
  final _supabase = Supabase.instance.client;

  // Staff login (ID + Password)
  Future<Map<String, dynamic>?> staffLogin(
    String staffId,
    String password,
  ) async {
    // Get staff record
    final staff = await _supabase
        .from('staff')
        .select('*')
        .eq('staff_id', staffId)
        .eq('is_active', true)
        .single();

    if (staff == null) return null;

    // Verify password (hash comparison)
    final passwordHash = _hashPassword(password);
    if (staff['password_hash'] != passwordHash) {
      return null;
    }

    // Set current staff context (for RLS)
    await _supabase.rpc('set_current_staff', {'staff_id': staffId});

    return staff;
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // Get assigned customers
  Future<List<Map<String, dynamic>>> getAssignedCustomers(
    String staffId,
  ) async {
    final staff = await _supabase
        .from('staff')
        .select('id')
        .eq('staff_id', staffId)
        .single();

    final response = await _supabase
        .from('staff_assignments')
        .select('''
          customer_id,
          customers(*),
          user_schemes(
            *,
            schemes(*)
          )
        ''')
        .eq('staff_id', staff['id'])
        .eq('is_active', true);

    return List<Map<String, dynamic>>.from(response);
  }

  // Record payment
  Future<Map<String, dynamic>> recordPayment({
    required String customerId,
    required String userSchemeId,
    required String staffId,
    required double amount,
    required String method,
    DateTime? paymentDate,
  }) async {
    final date = paymentDate ?? DateTime.now();
    
    // Get current rates
    final rates = await _supabase
        .from('market_rates')
        .select('*')
        .order('rate_date', ascending: false)
        .limit(1)
        .single();

    // Get scheme type
    final scheme = await _supabase
        .from('user_schemes')
        .select('schemes(asset_type)')
        .eq('id', userSchemeId)
        .single();

    final metalType = scheme['schemes']['asset_type'];
    final rate = metalType == 'gold' 
        ? rates['gold_rate_per_gram'] 
        : rates['silver_rate_per_gram'];
    
    final metalGrams = amount / rate;

    // Insert payment
    final payment = await _supabase
        .from('payments')
        .insert({
          'customer_id': customerId,
          'user_scheme_id': userSchemeId,
          'staff_id': staffId,
          'amount': amount,
          'payment_method': method,
          'payment_date': date.toIso8601String(),
          'payment_time': TimeOfDay.now().format(context),
          'gold_rate_at_payment': rates['gold_rate_per_gram'],
          'silver_rate_at_payment': rates['silver_rate_per_gram'],
          'metal_grams_added': metalGrams,
        })
        .select()
        .single();

    return payment;
  }

  // Get today's collections
  Future<List<Map<String, dynamic>>> getTodayCollections(
    String staffId,
  ) async {
    final staff = await _supabase
        .from('staff')
        .select('id')
        .eq('staff_id', staffId)
        .single();

    final today = DateTime.now().toIso8601String().split('T')[0];

    final response = await _supabase
        .from('payments')
        .select('''
          *,
          customers(name, phone),
          user_schemes(schemes(name))
        ''')
        .eq('staff_id', staff['id'])
        .eq('payment_date', today)
        .order('payment_time', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Get reports stats
  Future<Map<String, dynamic>> getTodayStats(String staffId) async {
    final staff = await _supabase
        .from('staff')
        .select('id')
        .eq('staff_id', staffId)
        .single();

    final today = DateTime.now().toIso8601String().split('T')[0];

    // Get collections
    final collections = await _supabase
        .from('payments')
        .select('amount, payment_method')
        .eq('staff_id', staff['id'])
        .eq('payment_date', today);

    final total = collections.fold<double>(
      0.0,
      (sum, p) => sum + (p['amount'] as num).toDouble(),
    );

    final cash = collections
        .where((p) => p['payment_method'] == 'cash')
        .fold<double>(0.0, (sum, p) => sum + (p['amount'] as num).toDouble());

    final gpay = collections
        .where((p) => p['payment_method'] == 'gpay')
        .fold<double>(0.0, (sum, p) => sum + (p['amount'] as num).toDouble());

    // Get assigned customers count
    final assigned = await _supabase
        .from('staff_assignments')
        .select('customer_id', const FetchOptions(count: CountOption.exact))
        .eq('staff_id', staff['id'])
        .eq('is_active', true);

    // Get collected count
    final collected = await _supabase
        .from('payments')
        .select('customer_id', const FetchOptions(count: CountOption.exact))
        .eq('staff_id', staff['id'])
        .eq('payment_date', today);

    return {
      'totalAmount': total,
      'cashAmount': cash,
      'gpayAmount': gpay,
      'totalCustomers': assigned.count ?? 0,
      'customersCollected': collected.count ?? 0,
      'pendingCount': (assigned.count ?? 0) - (collected.count ?? 0),
    };
  }
}
```

#### **3.3 Scheme Service** (`lib/services/scheme_service.dart`)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SchemeService {
  final _supabase = Supabase.instance.client;

  // Get all active schemes
  Future<List<Map<String, dynamic>>> getAllSchemes({
    String? assetType, // 'gold' or 'silver'
  }) async {
    var query = _supabase
        .from('schemes')
        .select('*')
        .eq('active', true)
        .order('scheme_id', ascending: true);

    if (assetType != null) {
      query = query.eq('asset_type', assetType);
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  // Get scheme details
  Future<Map<String, dynamic>?> getSchemeDetails(String schemeId) async {
    final response = await _supabase
        .from('schemes')
        .select('*')
        .eq('scheme_id', schemeId)
        .single();
    return response;
  }
}
```

### Step 4: Replace Mock Data (Day 4-6 - 12 hours)

#### **4.1 Update Customer Screens**

**Dashboard Screen:**
```dart
// lib/screens/customer/dashboard_screen.dart
final customerService = CustomerService();
final schemeService = SchemeService();

// Replace MockData with:
final activeSchemes = await customerService.getActiveSchemes(userId);
final marketRates = await customerService.getLatestMarketRates();
```

**Schemes Screen:**
```dart
// lib/screens/customer/schemes_screen.dart
final schemes = await schemeService.getAllSchemes();
// Filter by assetType if needed
```

**Transaction History:**
```dart
// lib/screens/customer/transaction_history_screen.dart
final transactions = await customerService.getPaymentHistory(userId);
```

#### **4.2 Update Staff Screens**

**Collect Tab Screen:**
```dart
// lib/screens/staff/collect_tab_screen.dart
final staffService = StaffService();
final customers = await staffService.getAssignedCustomers(staffId);
final todayStats = await staffService.getTodayStats(staffId);
```

**Collect Payment Screen:**
```dart
// lib/screens/staff/collect_payment_screen.dart
await staffService.recordPayment(
  customerId: customerId,
  userSchemeId: userSchemeId,
  staffId: staffId,
  amount: amount,
  method: method,
);
```

**Reports Screen:**
```dart
// lib/screens/staff/reports_screen.dart
final stats = await staffService.getTodayStats(staffId);
final collections = await staffService.getTodayCollections(staffId);
```

### Step 5: Add Real-time Updates (Day 7 - 4 hours)

```dart
// lib/services/realtime_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class RealtimeService {
  final _supabase = Supabase.instance.client;

  // Listen to payment updates for customer
  Stream<List<Map<String, dynamic>>> watchPayments(String customerId) {
    return _supabase
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('customer_id', customerId)
        .order('payment_date', ascending: false);
  }

  // Listen to market rate updates
  Stream<Map<String, dynamic>?> watchMarketRates() {
    return _supabase
        .from('market_rates')
        .stream(primaryKey: ['id'])
        .order('rate_date', ascending: false)
        .limit(1)
        .map((data) => data.isNotEmpty ? data.first : null);
  }

  // Listen to today's collections for staff
  Stream<List<Map<String, dynamic>>> watchTodayCollections(String staffId) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    return _supabase
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('staff_id', staffId)
        .eq('payment_date', today);
  }
}
```

### Step 6: Handle Offline Mode (Day 8 - 6 hours)

```dart
// lib/services/offline_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class OfflineService {
  final _connectivity = Connectivity();
  final _prefs = SharedPreferences.getInstance();

  // Check connectivity
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // Cache data locally
  Future<void> cacheData(String key, Map<String, dynamic> data) async {
    final prefs = await _prefs;
    await prefs.setString(key, jsonEncode(data));
  }

  // Get cached data
  Future<Map<String, dynamic>?> getCachedData(String key) async {
    final prefs = await _prefs;
    final data = prefs.getString(key);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  // Queue offline actions
  Future<void> queueAction(String action, Map<String, dynamic> data) async {
    final prefs = await _prefs;
    final queue = prefs.getStringList('offline_queue') ?? [];
    queue.add(jsonEncode({'action': action, 'data': data}));
    await prefs.setStringList('offline_queue', queue);
  }

  // Sync queued actions when online
  Future<void> syncQueue() async {
    if (!await isOnline()) return;

    final prefs = await _prefs;
    final queue = prefs.getStringList('offline_queue') ?? [];

    for (final item in queue) {
      final action = jsonDecode(item);
      // Process action based on type
      // e.g., recordPayment, updateProfile, etc.
    }

    await prefs.remove('offline_queue');
  }
}
```

### Step 7: Error Handling (Day 9 - 4 hours)

```dart
// lib/utils/error_handler.dart
class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is PostgrestException) {
      return error.message;
    } else if (error is AuthException) {
      return error.message;
    } else if (error.toString().contains('network')) {
      return 'No internet connection. Please check your network.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }

  static void showError(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getErrorMessage(error)),
        backgroundColor: AppColors.danger,
      ),
    );
  }
}
```

---

## 4. ADMIN PANEL REQUIREMENTS

### 4.1 Pages Needed

1. **Dashboard**
   - Total customers
   - Active schemes
   - Today's collections
   - Pending payments
   - Staff performance

2. **Customers Management**
   - List all customers
   - Add new customer
   - Edit customer details
   - View customer profile
   - View customer schemes
   - View payment history

3. **Schemes Management**
   - List all 18 schemes
   - Edit scheme details (rates, amounts)
   - Enable/disable schemes

4. **Staff Management**
   - List all staff
   - Add new staff
   - Edit staff details
   - Assign customers to staff
   - View staff performance
   - Set daily targets

5. **Payments Management**
   - View all payments
   - Filter by date, staff, customer
   - Export payments
   - Manual payment entry (for office)

6. **Reports**
   - Daily collection report
   - Weekly/Monthly reports
   - Staff performance report
   - Customer payment report
   - Scheme-wise report

7. **Market Rates**
   - Update gold/silver rates daily
   - View rate history
   - Set rate change notifications

8. **Assignments**
   - Assign customers to staff
   - Reassign customers
   - View assignment history

### 4.2 CRUD Operations

**Customers:**
- Create: Add new customer with all details
- Read: View customer list, search, filter
- Update: Edit customer info, nominee details
- Delete: Soft delete (mark inactive)

**Staff:**
- Create: Add new staff with credentials
- Read: View staff list, performance
- Update: Edit staff details, targets
- Delete: Deactivate staff

**Schemes:**
- Read: View all schemes
- Update: Edit scheme amounts, rates, features

**Payments:**
- Read: View all payments, filter, export
- Create: Manual payment entry (office collections)

**Assignments:**
- Create: Assign customer to staff
- Update: Reassign customer
- Delete: Remove assignment

### 4.3 Reports Needed

1. **Daily Collection Report**
   - Total collected amount
   - Cash vs Digital breakdown
   - Staff-wise breakdown
   - Customer-wise breakdown

2. **Staff Performance Report**
   - Collections per staff
   - Target vs Achievement
   - Customer visit count
   - Missed payments count

3. **Customer Payment Report**
   - Payment history
   - Missed payments
   - Due payments
   - Scheme-wise summary

4. **Scheme Performance Report**
   - Enrollments per scheme
   - Collections per scheme
   - Completion rates

---

## 5. IMPLEMENTATION CHECKLIST

### Priority Order (12 Days)

#### **Day 1-2: Foundation** (16 hours)
- [ ] Setup Supabase project
- [ ] Create database schema (all tables)
- [ ] Setup RLS policies
- [ ] Create functions and triggers
- [ ] Seed initial data (18 schemes, 2 staff)
- [ ] Test database connections

**Complexity:** Medium  
**Dependencies:** None

#### **Day 3-4: Service Layer** (16 hours)
- [ ] Create `CustomerService`
- [ ] Create `StaffService`
- [ ] Create `SchemeService`
- [ ] Create `RealtimeService`
- [ ] Create `OfflineService`
- [ ] Create `ErrorHandler`
- [ ] Unit tests for services

**Complexity:** Medium  
**Dependencies:** Database schema must be ready

#### **Day 5-6: Customer App Integration** (16 hours)
- [ ] Replace mock data in dashboard
- [ ] Replace mock data in schemes screen
- [ ] Replace mock data in transaction history
- [ ] Replace mock data in payment schedule
- [ ] Replace mock data in profile screens
- [ ] Add real-time updates for rates
- [ ] Test all customer flows

**Complexity:** Easy-Medium  
**Dependencies:** Services must be ready

#### **Day 7-8: Staff App Integration** (16 hours)
- [ ] Replace mock data in staff login
- [ ] Replace mock data in collect tab
- [ ] Replace mock data in customer detail
- [ ] Replace mock data in collect payment
- [ ] Replace mock data in reports
- [ ] Add real-time updates for collections
- [ ] Test all staff flows

**Complexity:** Easy-Medium  
**Dependencies:** Services must be ready

#### **Day 9: Offline & Error Handling** (8 hours)
- [ ] Implement offline detection
- [ ] Add local caching
- [ ] Queue offline actions
- [ ] Sync queue on reconnect
- [ ] Add error handling throughout
- [ ] Add loading states
- [ ] Test offline scenarios

**Complexity:** Medium  
**Dependencies:** All integrations complete

#### **Day 10: Testing & Bug Fixes** (8 hours)
- [ ] End-to-end testing
- [ ] Fix bugs
- [ ] Performance optimization
- [ ] Security review
- [ ] Edge case handling

**Complexity:** Medium  
**Dependencies:** All features complete

#### **Day 11: Admin Panel Setup** (8 hours)
- [ ] Setup Next.js project
- [ ] Create basic pages structure
- [ ] Implement authentication
- [ ] Create customer management
- [ ] Create staff management
- [ ] Create basic reports

**Complexity:** Medium-Hard  
**Dependencies:** Database ready

#### **Day 12: Final Polish & Deployment** (8 hours)
- [ ] Final testing
- [ ] Documentation
- [ ] Deploy to production
- [ ] Monitor and fix issues

**Complexity:** Easy  
**Dependencies:** Everything complete

### Parallel Tasks

**Can be done in parallel:**
- Customer app integration + Staff app integration (Day 5-8)
- Admin panel development (can start Day 9)
- Testing + Bug fixes (ongoing)

**Must be sequential:**
- Database → Services → App Integration
- Integration → Testing → Deployment

### Testing Strategy

1. **Unit Tests:** Service layer functions
2. **Integration Tests:** API calls, database operations
3. **Widget Tests:** Critical screens
4. **E2E Tests:** Complete user flows
5. **Performance Tests:** Load testing, query optimization
6. **Security Tests:** RLS policies, authentication

---

## 6. POTENTIAL ISSUES & SOLUTIONS

### 6.1 Data Migration

**Issue:** Existing mock data needs to be migrated

**Solution:**
```sql
-- Create migration script
-- Insert customers from mock data
-- Insert enrollments
-- Insert payment history
-- Assign to staff
```

### 6.2 Performance Bottlenecks

**Issues:**
- Large payment history queries
- Real-time subscriptions on large datasets
- Complex joins in reports

**Solutions:**
- Add pagination to all list queries
- Use indexes (already defined)
- Cache frequently accessed data
- Use materialized views for reports
- Limit real-time subscriptions

### 6.3 Security Considerations

**Issues:**
- Staff password storage
- RLS policy complexity
- API key exposure

**Solutions:**
- Hash passwords (SHA-256)
- Test RLS policies thoroughly
- Use environment variables
- Implement rate limiting
- Add audit logs

### 6.4 Offline Mode Challenges

**Issues:**
- Payment conflicts when syncing
- Data consistency
- Queue management

**Solutions:**
- Use timestamps for conflict resolution
- Validate data before syncing
- Implement retry logic
- Show sync status to users

### 6.5 Real-time Updates

**Issues:**
- Too many subscriptions
- Battery drain
- Network usage

**Solutions:**
- Subscribe only when screen is active
- Use debouncing for rate updates
- Unsubscribe on screen dispose
- Use background sync for critical updates

---

## 7. CODE EXAMPLES

### 7.1 Complete Customer Service Example

See Section 3.1 above.

### 7.2 Complete Staff Service Example

See Section 3.2 above.

### 7.3 Real-time Subscription Example

```dart
// In dashboard_screen.dart
StreamSubscription? _paymentSubscription;

@override
void initState() {
  super.initState();
  _setupRealtime();
}

void _setupRealtime() {
  final userId = AuthService().getCurrentUser()?.id;
  if (userId == null) return;

  _paymentSubscription = RealtimeService()
      .watchPayments(userId)
      .listen((payments) {
    setState(() {
      _payments = payments;
    });
  });
}

@override
void dispose() {
  _paymentSubscription?.cancel();
  super.dispose();
}
```

### 7.4 Offline Payment Queue Example

```dart
// In collect_payment_screen.dart
Future<void> _recordPayment() async {
  final offlineService = OfflineService();
  
  if (await offlineService.isOnline()) {
    // Record directly
    await staffService.recordPayment(...);
  } else {
    // Queue for later
    await offlineService.queueAction('record_payment', {
      'customer_id': customerId,
      'amount': amount,
      'method': method,
    });
    
    // Show offline message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment queued. Will sync when online.')),
    );
  }
}
```

---

## 8. TIMELINE ESTIMATE

**Total: 12 Days (96 hours)**

- **Days 1-2:** Database setup (16h)
- **Days 3-4:** Service layer (16h)
- **Days 5-6:** Customer app (16h)
- **Days 7-8:** Staff app (16h)
- **Day 9:** Offline & errors (8h)
- **Day 10:** Testing (8h)
- **Day 11:** Admin panel (8h)
- **Day 12:** Polish & deploy (8h)

**Buffer:** Add 2-3 days for unexpected issues.

---

## 9. NEXT STEPS

1. **Immediate (Today):**
   - Create Supabase project
   - Run database schema SQL
   - Seed initial data

2. **This Week:**
   - Build service layer
   - Start customer app integration
   - Start staff app integration

3. **Next Week:**
   - Complete integrations
   - Add offline mode
   - Build admin panel
   - Test and deploy

---

**END OF DOCUMENT**
