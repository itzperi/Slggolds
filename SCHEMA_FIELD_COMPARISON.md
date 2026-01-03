# SCHEMA FIELD COMPARISON

## What You Asked For vs What Exists

### ✅ PERSONAL INFORMATION

| Field | Status | Location | Notes |
|-------|--------|----------|-------|
| **Full Name** | ✅ EXISTS | `profiles.name` | ✅ Present |
| **Date of Birth** | ✅ EXISTS | `customers.date_of_birth` | ✅ Present |
| **Birth Place** | ❌ MISSING | - | Not in schema |
| **Father's Name** | ❌ MISSING | - | Not in schema |
| **Authority No.** | ❌ MISSING | - | Not in schema |
| **Gender** | ❌ MISSING | - | Not in schema |

---

### ⚠️ CONTACT INFORMATION (PARTIAL)

| Field | Status | Location | Notes |
|-------|--------|----------|-------|
| **Business Address** | ❌ MISSING | - | Only one `address` field exists |
| **Business Cell No.** | ❌ MISSING | - | Only one `phone` field exists |
| **Residential Address** | ⚠️ PARTIAL | `customers.address` | Single address field (not labeled as residential) |
| **Residential Cell No.** | ⚠️ PARTIAL | `profiles.phone` | Single phone field (not labeled as residential) |
| **Pin Code** | ✅ EXISTS | `customers.pincode` | ✅ Present |

**Current Schema:**
- `profiles.phone` - Single phone number
- `customers.address` - Single address
- `customers.city` - City
- `customers.state` - State
- `customers.pincode` - Pin code

**Missing:**
- Separate business address
- Separate business phone
- Labeling for residential vs business

---

### ⚠️ NOMINEE INFORMATION (PARTIAL)

| Field | Status | Location | Notes |
|-------|--------|----------|-------|
| **Nominee Full Name** | ✅ EXISTS | `customers.nominee_name` | ✅ Present |
| **Nominee Age** | ❌ MISSING | - | Not in schema |
| **Nominee Birth Place** | ❌ MISSING | - | Not in schema |
| **Relationship** | ✅ EXISTS | `customers.nominee_relation` | ✅ Present |
| **Nominee Address** | ❌ MISSING | - | Not in schema |
| **Nominee Phone** | ✅ EXISTS | `customers.nominee_phone` | ✅ Present |
| **Nominee Pin Code** | ❌ MISSING | - | Not in schema |

**Current Schema:**
- `customers.nominee_name` ✅
- `customers.nominee_relation` ✅
- `customers.nominee_phone` ✅

**Missing:**
- Nominee age
- Nominee birth place
- Nominee address (separate field)
- Nominee pin code

---

### ❌ ACCOUNT/REGISTRATION DETAILS (MOSTLY MISSING)

| Field | Status | Location | Notes |
|-------|--------|----------|-------|
| **Branch** | ❌ MISSING | - | Not in schema |
| **Customer ID** | ⚠️ PARTIAL | `customers.id` | UUID exists, but no display ID (like CUST001) |
| **Book No.** | ❌ MISSING | - | Not in schema |
| **Scheme No.** | ❌ MISSING | - | Not in schema |
| **Scheme (D/W/M)** | ✅ EXISTS | `user_schemes.payment_frequency` | Daily/Weekly/Monthly ✅ |
| **Scheme Type** | ✅ EXISTS | `schemes.asset_type` | Gold/Silver ✅ |
| **Sales Office ID** | ❌ MISSING | - | Not in schema |
| **Sales Office Name** | ❌ MISSING | - | Not in schema |

**Current Schema:**
- `user_schemes.payment_frequency` - ENUM('daily', 'weekly', 'monthly') ✅
- `schemes.asset_type` - ENUM('gold', 'silver') ✅
- `customers.id` - UUID (not a display ID)

**Missing:**
- Branch code/location
- Customer display ID (like CUST001, SLG001)
- Book number
- Scheme number
- Sales office ID
- Sales office name

---

## SUMMARY

### ✅ What EXISTS (11 fields):
1. Full Name (`profiles.name`)
2. Date of Birth (`customers.date_of_birth`)
3. Address (`customers.address`) - single address
4. Pin Code (`customers.pincode`)
5. Phone (`profiles.phone`) - single phone
6. Nominee Name (`customers.nominee_name`)
7. Nominee Relation (`customers.nominee_relation`)
8. Nominee Phone (`customers.nominee_phone`)
9. Payment Frequency (`user_schemes.payment_frequency`) - D/W/M
10. Scheme Type (`schemes.asset_type`) - Gold/Silver
11. Customer ID (`customers.id`) - UUID only, no display ID

### ❌ What's MISSING (18+ fields):
1. Birth Place
2. Father's Name
3. Authority No.
4. Gender
5. Business Address (separate)
6. Business Cell No. (separate)
7. Residential Address (labeled)
8. Residential Cell No. (labeled)
9. Nominee Age
10. Nominee Birth Place
11. Nominee Address
12. Nominee Pin Code
13. Branch
14. Customer Display ID (like CUST001)
15. Book No.
16. Scheme No.
17. Sales Office ID
18. Sales Office Name

---

## RECOMMENDATION

**If you need these fields, you'll need to:**

1. **Add columns to `customers` table:**
   - `birth_place TEXT`
   - `father_name TEXT`
   - `authority_number TEXT`
   - `gender TEXT CHECK (gender IN ('Male', 'Female', 'Others'))`
   - `business_address TEXT`
   - `business_phone TEXT`
   - `residential_address TEXT` (or rename `address` to `residential_address`)
   - `residential_phone TEXT` (or add separate field)
   - `nominee_age INTEGER`
   - `nominee_birth_place TEXT`
   - `nominee_address TEXT`
   - `nominee_pincode TEXT`
   - `branch_code TEXT`
   - `customer_display_id TEXT UNIQUE` (like CUST001)
   - `book_number TEXT`
   - `sales_office_id TEXT`
   - `sales_office_name TEXT`

2. **Add columns to `user_schemes` table:**
   - `scheme_number TEXT` (display ID for the enrollment)

3. **Consider adding a `branches` or `sales_offices` table:**
   - If multiple branches/offices exist
   - Reference via foreign key instead of storing name directly

---

## CURRENT SCHEMA STRUCTURE

```sql
-- profiles (basic user info)
- name ✅
- phone ✅
- email ✅

-- customers (KYC-lite)
- address ✅ (single)
- city ✅
- state ✅
- pincode ✅
- date_of_birth ✅
- pan_number ✅
- aadhaar_number ✅
- nominee_name ✅
- nominee_relation ✅
- nominee_phone ✅

-- user_schemes (enrollment)
- payment_frequency ✅ (D/W/M)
- scheme_id → schemes.asset_type ✅ (Gold/Silver)
```

**Bottom Line:** Your schema has **~40% of the requested fields**. Most personal info basics exist, but business/residential separation, nominee details, and account/registration fields are missing.

