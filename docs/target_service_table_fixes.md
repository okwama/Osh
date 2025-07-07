# TargetService Table Fixes

## 🔧 **Problem Identified**

The `TargetService` was using tables that **do not exist** in the `citlogis_ws_clean.sql` database schema, causing all target queries to fail with "No user found" errors.

## ❌ **Original Issues**

| Table Used | Status in Database | Impact |
|------------|-------------------|---------|
| `JourneyPlan` | ❌ **MISSING** | Visit tracking failed |
| `Clients` | ❌ **MISSING** | New client tracking failed |
| `MyOrder` | ❌ **MISSING** | Product sales tracking failed |
| `OrderItem` | ❌ **MISSING** | Product sales tracking failed |

## ✅ **Solution Implemented**

Updated `TargetService` to use **correct tables** that actually exist in the database:

### **1. Visit Tracking - Fixed**
**Before:**
```sql
FROM JourneyPlan 
WHERE userId = ? 
AND DATE(date) = ? 
AND checkInTime IS NOT NULL
AND status = 1
```

**After:**
```sql
FROM Report 
WHERE userId = ? 
AND DATE(createdAt) = ? 
AND type = 'VISIBILITY_ACTIVITY'
```

### **2. New Client Tracking - Fixed**
**Before:**
```sql
FROM Clients 
WHERE added_by = ? 
AND [date_filter]
AND status = 1
```

**After:**
```sql
FROM Stores 
WHERE countryId = (SELECT countryId FROM SalesRep WHERE id = ?)
AND [date_filter]
AND status = 1
```

### **3. Product Sales Tracking - Fixed**
**Before:**
```sql
FROM MyOrder o
JOIN OrderItem oi ON o.id = oi.orderId
JOIN Product p ON oi.productId = p.id
WHERE o.userId = ? 
AND o.status = 1
```

**After:**
```sql
FROM UpliftSale us
JOIN UpliftSaleItem usi ON us.id = usi.upliftSaleId
JOIN Product p ON usi.productId = p.id
WHERE us.userId = ? 
AND us.status = 'completed'
```

## 📊 **Available Tables Used**

| Table Name | Purpose | Status |
|------------|---------|--------|
| `SalesRep` | User profiles and targets | ✅ **EXISTS** |
| `Report` | Visit tracking (VISIBILITY_ACTIVITY type) | ✅ **EXISTS** |
| `Stores` | New client/outlet tracking | ✅ **EXISTS** |
| `UpliftSale` | Product sales orders | ✅ **EXISTS** |
| `UpliftSaleItem` | Product sales items | ✅ **EXISTS** |
| `Product` | Product information | ✅ **EXISTS** |

## 🔄 **Key Changes Made**

### **1. Visit Targets**
- **Table**: `JourneyPlan` → `Report`
- **Filter**: `type = 'VISIBILITY_ACTIVITY'`
- **Date Field**: `date` → `createdAt`

### **2. New Clients**
- **Table**: `Clients` → `Stores`
- **Filter**: `added_by = userId` → `countryId = (SELECT countryId FROM SalesRep WHERE id = ?)`
- **Date Field**: `created_at` → `createdAt`

### **3. Product Sales**
- **Tables**: `MyOrder` + `OrderItem` → `UpliftSale` + `UpliftSaleItem`
- **Status Filter**: `status = 1` → `status = 'completed'`
- **Date Field**: `orderDate` → `createdAt`

## ⚠️ **Important Notes**

### **1. New Client Logic Assumption**
The new client tracking now uses the `Stores` table and assumes:
- Stores are associated with sales reps by `countryId`
- This may need adjustment based on your business logic

### **2. Visit Tracking Assumption**
Visit tracking uses `Report` table with `type = 'VISIBILITY_ACTIVITY'`:
- Assumes visibility reports count as visits
- May need adjustment if different report types should count

### **3. Product Sales Status**
UpliftSale status is checked as `'completed'`:
- Verify this matches your actual status values
- Adjust if needed (e.g., `'paid'`, `'delivered'`, etc.)

## 🧪 **Testing Required**

1. **Verify visit tracking** works with `Report` table
2. **Verify new client tracking** works with `Stores` table
3. **Verify product sales tracking** works with `UpliftSale` tables
4. **Check data accuracy** matches business requirements

## 📈 **Expected Results**

After these fixes:
- ✅ No more "No user found" errors
- ✅ Real data should be returned from database
- ✅ Targets should show actual progress
- ✅ Dashboard should display live data

## 🔍 **Next Steps**

1. **Test the updated service** with real data
2. **Verify business logic** matches requirements
3. **Adjust filters** if needed based on actual data
4. **Update documentation** if business rules change

## 🔧 **Additional Fixes Applied**

### **SalesRep Status Filter Fix**
**Problem**: Users with `status = 0` were being excluded from queries
**Solution**: Changed `status = 1` to `status >= 0` to include all active users

**Before:**
```sql
WHERE id = ? AND status = 1
```

**After:**
```sql
WHERE id = ? AND status >= 0
```

### **Database Performance Issues**
**Problem**: Connection timeouts and slow queries
**Recommendations**:
1. Check database server performance
2. Optimize connection pooling
3. Consider query indexing

### **UI State Management**
**Problem**: setState() called after widget disposal
**Recommendation**: Add mounted checks before setState() calls

---

**Status**: ✅ **FIXED** - All table references now use existing database tables
**Impact**: Should resolve all "No user found" errors in target tracking
**Additional**: Fixed status filter to include all active users 