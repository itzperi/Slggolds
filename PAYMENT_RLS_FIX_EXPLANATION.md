# Payment RLS Policy Fix - Explanation

## Problem

Payment insert was failing with `permission denied for table payments (42501)` even though:
- Staff is authenticated ✅
- Staff profile exists ✅  
- Assignment exists ✅

## Root Cause

The RLS policy on `payments` was using an `EXISTS` clause that queried `staff_assignments`:

```sql
EXISTS (
    SELECT 1
    FROM staff_assignments sa
    WHERE sa.staff_id = get_user_profile()
    AND sa.customer_id = customer_id
    AND sa.is_active = true
)
```

**The problem:** `staff_assignments` has its own RLS policies. When the `payments` policy tries to check assignments, RLS on `staff_assignments` blocks the query, even though the assignment exists.

This creates a circular dependency:
- Payments policy needs to check `staff_assignments`
- But `staff_assignments` RLS blocks the check
- Result: Payment insert fails

## Solution: SECURITY DEFINER Function

### What is SECURITY DEFINER?

Functions marked `SECURITY DEFINER` run with the privileges of the **function owner** (usually the database superuser), not the calling user. This means:

- ✅ Bypasses RLS on all tables
- ✅ Can read any data needed for authorization
- ✅ Returns a simple boolean answer

### The Function

```sql
CREATE OR REPLACE FUNCTION is_current_staff_assigned_to_customer(customer_uuid UUID)
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1
        FROM staff_assignments sa
        WHERE sa.staff_id = get_user_profile()
        AND sa.customer_id = customer_uuid
        AND sa.is_active = true
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE;
```

**What it does:**
1. Resolves `auth.uid()` → staff profile ID via `get_user_profile()`
2. Checks if active assignment exists
3. Returns `true` or `false` only

**Why it works:**
- Runs as database owner → bypasses RLS on `staff_assignments`
- Isolated authorization logic → doesn't depend on other RLS policies
- Simple boolean answer → no data leakage

## Updated RLS Policy

```sql
CREATE POLICY "Staff can insert payments for assigned customers"
    ON payments FOR INSERT
    WITH CHECK (
        is_staff() AND (
            is_admin() OR
            (
                staff_id = get_user_profile()
                AND is_current_staff_assigned_to_customer(customer_id)
            )
        )
    );
```

**Authorization flow:**
1. `is_staff()` → Check if user role is 'staff' or 'admin'
2. If admin → Allow
3. If staff → Check:
   - `staff_id = get_user_profile()` → Payment's staff_id matches current user
   - `is_current_staff_assigned_to_customer(customer_id)` → Staff is assigned (via SECURITY DEFINER)

## Why This Separation is Required

### 1. **Authorization Isolation**

Payment authorization must be **independent** of other tables' RLS policies. If `staff_assignments` RLS changes, payment recording should not break.

### 2. **Operational Authority**

Staff payment recording is an **operational action**, not analytics. It must succeed if:
- Staff is authenticated
- Staff is assigned to customer
- Payment data is valid

It must **NOT** depend on:
- ❌ Market rates (analytics table)
- ❌ Metal calculations (derived data)
- ❌ Other tables' RLS policies

### 3. **Security Model**

- **RLS on `staff_assignments`**: Controls who can **read** assignment data
- **SECURITY DEFINER function**: Allows **authorization checks** to bypass RLS
- **RLS on `payments`**: Controls who can **write** payment data

This separation ensures:
- Staff cannot read all assignments (RLS blocks)
- But authorization checks work (SECURITY DEFINER bypasses)
- Payment writes are properly controlled (RLS on payments)

## Design Constraints Respected

✅ **Do NOT weaken RLS** - `staff_assignments` RLS remains unchanged  
✅ **Do NOT grant broad SELECT** - Staff still cannot read all assignments  
✅ **Do NOT move logic to Flutter** - Authorization stays in database  
✅ **Do NOT require market_rates** - Payment insert is independent

## After Applying

Payments will insert successfully even if:
- ✅ `market_rates` is unreadable
- ✅ Grams calculation is skipped  
- ✅ Other analytics tables fail

**Payment recording is now isolated and authoritative.**

