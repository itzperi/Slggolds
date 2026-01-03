# CURRENT STATUS & NEXT STEPS

**Date:** Current  
**Purpose:** Clear status of what's done vs. what's remaining from the audit

---

## ✅ WHAT WE JUST COMPLETED (Phases 1-5)

### Customer Visibility Fix (COMPLETE)
- ✅ **Phase 1:** Customer list shows all assigned customers (any scheme status)
- ✅ **Phase 2:** Pending count fixed (never negative, consistent source)
- ✅ **Phase 3:** Collections display shows scheme names (any status)
- ✅ **Phase 4:** Scheme breakdown verified (already correct)
- ✅ **Phase 5:** Payment flow allows active + paused schemes

**Result:** Customer visibility issues are **FULLY RESOLVED**. ✅

---

## 🔴 WHAT'S STILL BROKEN (From Audit)

### CRITICAL BLOCKERS

#### 1. **RLS Circular Dependency** — BLOCKING LOGIN
**Status:** 🔴 CRITICAL  
**Impact:** Staff cannot log in if RLS is broken  
**Fix:** SQL in Supabase (5 minutes)  
**File:** `supabase_schema.sql` (already has fix, needs to be run)

#### 2. **Missing Staff Profile Service Methods**
**Status:** 🔴 CRITICAL  
**Impact:** Profile screens show mock data  
**Files Affected:**
- `staff_dashboard.dart` (line 31)
- `staff_profile_screen.dart` (line 23)
- `staff_account_info_screen.dart` (line 16)

**Missing Methods:**
- `getStaffProfile(String profileId)` — Fetch profile + metadata
- `getStaffMetadata(String profileId)` — Fetch staff_metadata

**Fix Required:** Add to `lib/services/staff_data_service.dart`

#### 3. **Mock Data Still Used in Core Screens**
**Status:** 🔴 CRITICAL  
**Files Still Using Mock Data:**
- ✅ `collect_tab_screen.dart` — **FIXED** (uses real data)
- ✅ `reports_screen.dart` — **FIXED** (uses real data)
- ✅ `customer_detail_screen.dart` — **FIXED** (uses real data)
- ❌ `staff_dashboard.dart` — **BROKEN** (line 31: `StaffMockData.staffInfo`)
- ❌ `staff_profile_screen.dart` — **BROKEN** (line 23: `StaffMockData.staffInfo`)
- ❌ `staff_account_info_screen.dart` — **BROKEN** (line 16: `StaffMockData.staffInfo`)
- ❌ `today_target_detail_screen.dart` — **BROKEN** (lines 26-31: all mock data)
- ❌ `customer_list_screen.dart` — **UNUSED** (dead code, uses mock)
- ❌ `payment_collection_screen.dart` — **UNUSED** (dead code, uses mock)

---

## 📊 COMPLETION STATUS

| Component | Status | What We Did | What's Left |
|-----------|--------|-------------|-------------|
| **Customer Visibility** | ✅ COMPLETE | Phases 1-5 | Nothing |
| **Collect Tab** | ✅ COMPLETE | Real data | Nothing |
| **Reports Screen** | ✅ COMPLETE | Real data | Nothing |
| **Customer Detail** | ✅ COMPLETE | Real data | Nothing |
| **Payment Flow** | ✅ COMPLETE | Real data + paused schemes | Nothing |
| **Staff Dashboard** | 🔴 BROKEN | Nothing | Add profile service + remove mock |
| **Staff Profile** | 🔴 BROKEN | Nothing | Add profile service + remove mock |
| **Account Info** | 🔴 BROKEN | Nothing | Add profile service + remove mock |
| **Target Detail** | 🔴 BROKEN | Nothing | Replace all mock with real data |
| **RLS** | ⚠️ UNKNOWN | SQL fix exists | Run SQL in Supabase |

---

## 🎯 NEXT STEPS (Priority Order)

### **STEP 1: Verify RLS Status** (5 minutes)
**Action:** Check if RLS fix was already applied  
**How:** Try staff login — if it works, RLS is fixed  
**If Broken:** Run SQL from audit (lines 21-28 in audit doc)

### **STEP 2: Add Staff Profile Service Methods** (1-2 hours)
**File:** `lib/services/staff_data_service.dart`  
**Add:**
```dart
static Future<Map<String, dynamic>> getStaffProfile(String profileId) async {
  // Fetch from profiles + staff_metadata
  // Return: name, phone, email, staff_code, targets, etc.
}

static Future<Map<String, dynamic>> getStaffMetadata(String profileId) async {
  // Fetch from staff_metadata
  // Return: staff_code, targets, join_date, etc.
}
```

### **STEP 3: Fix Staff Dashboard** (30 minutes)
**File:** `lib/screens/staff/staff_dashboard.dart`  
**Change:**
- Remove: `StaffMockData.staffInfo[widget.staffId]`
- Add: `await StaffDataService.getStaffProfile(widget.staffId)` in `initState()`
- Add loading state while fetching

### **STEP 4: Fix Staff Profile Screen** (30 minutes)
**File:** `lib/screens/staff/staff_profile_screen.dart`  
**Change:**
- Remove: `StaffMockData.staffInfo[staffId]`
- Add: `await StaffDataService.getStaffProfile(staffId)` in build/initState
- Add loading state

### **STEP 5: Fix Account Info Screen** (30 minutes)
**File:** `lib/screens/staff/staff_account_info_screen.dart`  
**Change:**
- Remove: `StaffMockData.staffInfo[staffId]`
- Add: `await StaffDataService.getStaffProfile(staffId)`
- Add loading state

### **STEP 6: Fix Today Target Detail Screen** (1 hour)
**File:** `lib/screens/staff/today_target_detail_screen.dart`  
**Change:**
- Remove ALL `StaffMockData` calls (lines 26-31)
- Replace with:
  - `StaffDataService.getTodayStats(staffProfileId)`
  - `StaffDataService.getTodayCollections(staffProfileId)`
  - `StaffDataService.getAssignedCustomers(staffProfileId)`

### **STEP 7: Cleanup Dead Code** (15 minutes)
**Remove:**
- `lib/screens/staff/customer_list_screen.dart` (unused)
- `lib/screens/staff/payment_collection_screen.dart` (unused)

---

## 📋 QUICK ACTION CHECKLIST

### **IMMEDIATE (Today)**
- [ ] **Verify RLS** — Test staff login
- [ ] **Add Staff Profile Service** — `getStaffProfile()` + `getStaffMetadata()`
- [ ] **Fix Staff Dashboard** — Remove mock, use real service

### **THIS WEEK**
- [ ] **Fix Staff Profile Screen** — Use real service
- [ ] **Fix Account Info Screen** — Use real service
- [ ] **Fix Today Target Detail** — Replace all mock data
- [ ] **Remove Dead Code** — Delete unused screens

### **BEFORE LAUNCH**
- [ ] **Test All Screens** — Verify no mock data remains
- [ ] **Test Edge Cases** — Empty data, errors, etc.
- [ ] **Remove Mock Imports** — Clean up unused imports

---

## 🧠 WHAT WE ACCOMPLISHED

**Customer Visibility Fix (Phases 1-5):**
- ✅ Fixed empty customer list
- ✅ Fixed negative pending count
- ✅ Fixed "No collections today" when payments exist
- ✅ Fixed scheme breakdown consistency
- ✅ Fixed payment flow for paused schemes

**This was a MAJOR fix** — the core data flow is now correct.

---

## 🚨 WHAT'S STILL BLOCKING

**Profile Screens:**
- Staff Dashboard shows empty/mock data
- Staff Profile shows mock data
- Account Info shows mock data
- Target Detail shows mock data

**Root Cause:** Missing service methods + mock data not removed

**Estimated Fix Time:** 3-4 hours of focused work

---

## 💡 RECOMMENDATION

**Start with Step 2** (Add Staff Profile Service Methods) because:
1. It unblocks all profile screens
2. It's the foundation for everything else
3. Once done, Steps 3-5 are just "remove mock, use service"

**Then do Steps 3-6** in order (each screen fix is independent)

**Finally Step 7** (cleanup)

---

## 🎯 BOTTOM LINE

**What's Done:**
- ✅ Customer visibility (Phases 1-5) — **COMPLETE**
- ✅ Core data flow (Collect, Reports, Payments) — **COMPLETE**

**What's Left:**
- 🔴 Profile screens (Dashboard, Profile, Account, Target) — **NEED SERVICE METHODS + MOCK REMOVAL**
- ⚠️ RLS (if not already fixed) — **NEED SQL EXECUTION**

**You're ~70% done with the audit. The remaining 30% is profile screens + cleanup.**



