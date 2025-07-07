# MOTORGAS Database Schema - Detailed Documentation

## Database Schema Overview

The MOTORGAS application uses a comprehensive MySQL database schema designed for a field service management system with attendance tracking, order management, and location-based services.

## Core Database Tables

### 1. Users Table
**Purpose**: Central user management and authentication

```sql
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  employee_id VARCHAR(20) UNIQUE NOT NULL,
  phone_number VARCHAR(20) UNIQUE NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  password VARCHAR(255) NOT NULL,
  qr_code VARCHAR(255) UNIQUE NOT NULL,
  role ENUM('admin', 'manager', 'employee') DEFAULT 'employee',
  department VARCHAR(50),
  position VARCHAR(50),
  hire_date DATE,
  status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  INDEX idx_employee_id (employee_id),
  INDEX idx_phone_number (phone_number),
  INDEX idx_qr_code (qr_code),
  INDEX idx_status (status),
  INDEX idx_role (role),
  INDEX idx_department (department)
);
```

**Key Features:**
- Unique constraints on employee_id, phone_number, email, and qr_code
- Role-based access control
- Status tracking for user management
- Comprehensive indexing for performance

### 2. Locations Table
**Purpose**: Valid check-in locations with geolocation data

```sql
CREATE TABLE locations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  address TEXT NOT NULL,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  radius_meters INT DEFAULT 100,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  INDEX idx_location (latitude, longitude),
  INDEX idx_is_active (is_active),
  INDEX idx_name (name)
);
```

**Key Features:**
- Geolocation support with precision coordinates
- Configurable check-in radius
- Active/inactive status management

### 3. Attendance Table
**Purpose**: Comprehensive attendance tracking with geolocation

```sql
CREATE TABLE attendance (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  date DATE NOT NULL,
  check_in TIMESTAMP NULL,
  check_out TIMESTAMP NULL,
  check_in_latitude DECIMAL(10, 8) NULL,
  check_in_longitude DECIMAL(11, 8) NULL,
  check_out_latitude DECIMAL(10, 8) NULL,
  check_out_longitude DECIMAL(11, 8) NULL,
  location_id INT NULL,
  status ENUM('present', 'absent', 'late', 'half_day', 'leave', 'holiday', 'remote') DEFAULT 'absent',
  hours_worked DECIMAL(5, 2) DEFAULT 0,
  check_in_method ENUM('qr', 'mobile', 'web', 'manual') NULL,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE SET NULL,
  UNIQUE KEY unique_user_date (user_id, date),
  
  INDEX idx_user_id (user_id),
  INDEX idx_date (date),
  INDEX idx_status (status),
  INDEX idx_check_in_method (check_in_method),
  INDEX idx_location_id (location_id),
  INDEX idx_user_date (user_id, date)
);
```

**Key Features:**
- Geolocation tracking for check-in/check-out
- Multiple check-in methods support
- Unique constraint per user per date
- Comprehensive status tracking

### 4. QR Sessions Table
**Purpose**: Secure QR code session management

```sql
CREATE TABLE qr_sessions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  session_token VARCHAR(255) NOT NULL,
  location_id INT NOT NULL,
  valid_from TIMESTAMP NOT NULL,
  valid_to TIMESTAMP NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_by INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
  
  INDEX idx_session_token (session_token),
  INDEX idx_validity (valid_from, valid_to),
  INDEX idx_location_id (location_id),
  INDEX idx_is_active (is_active)
);
```

**Key Features:**
- Time-based session validity
- Location-specific QR codes
- Secure token generation

### 5. Checkin Records Table
**Purpose**: Detailed check-in/check-out tracking

```sql
CREATE TABLE checkin_records (
  id VARCHAR(255) PRIMARY KEY,
  user_id VARCHAR(255) NOT NULL,
  user_name VARCHAR(255) NOT NULL,
  outlet_id VARCHAR(255) NOT NULL,
  outlet_name VARCHAR(255) NOT NULL,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  address TEXT,
  status INT NOT NULL DEFAULT 0,
  timestamp DATETIME NOT NULL,
  qr_data TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  INDEX idx_user_id (user_id),
  INDEX idx_outlet_id (outlet_id),
  INDEX idx_status (status),
  INDEX idx_timestamp (timestamp),
  INDEX idx_user_outlet (user_id, outlet_id),
  INDEX idx_user_status (user_id, status),
  INDEX idx_timestamp_status (timestamp, status)
);
```

**Key Features:**
- Comprehensive geolocation tracking
- Status-based check-in/check-out
- QR data storage
- Optimized indexing for queries

## Business Logic Tables

### 6. Products Table
**Purpose**: Product catalog management

```sql
CREATE TABLE products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  category VARCHAR(50),
  status ENUM('active', 'inactive') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  INDEX idx_category (category),
  INDEX idx_status (status),
  INDEX idx_name (name)
);
```

### 7. Orders Table
**Purpose**: Order management and tracking

```sql
CREATE TABLE orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL,
  total_amount DECIMAL(10,2) NOT NULL,
  status ENUM('pending', 'confirmed', 'delivered', 'cancelled') DEFAULT 'pending',
  order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  delivery_date TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
  
  INDEX idx_user_id (user_id),
  INDEX idx_status (status),
  INDEX idx_order_date (order_date),
  INDEX idx_product_id (product_id)
);
```

### 8. Outlets Table
**Purpose**: Store/outlet location management

```sql
CREATE TABLE outlets (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  address TEXT NOT NULL,
  latitude DECIMAL(10,8),
  longitude DECIMAL(11,8),
  phone VARCHAR(20),
  email VARCHAR(100),
  status ENUM('active', 'inactive') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  INDEX idx_status (status),
  INDEX idx_location (latitude, longitude),
  INDEX idx_name (name)
);
```

### 9. Visitors Table
**Purpose**: Visitor tracking and management

```sql
CREATE TABLE visitors (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  outlet_id INT NOT NULL,
  visit_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  check_in_time TIMESTAMP NULL,
  check_out_time TIMESTAMP NULL,
  status ENUM('scheduled', 'checked_in', 'checked_out', 'cancelled') DEFAULT 'scheduled',
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (outlet_id) REFERENCES outlets(id) ON DELETE CASCADE,
  
  INDEX idx_user_id (user_id),
  INDEX idx_outlet_id (outlet_id),
  INDEX idx_visit_date (visit_date),
  INDEX idx_status (status)
);
```

### 10. SOS Alerts Table
**Purpose**: Emergency alert system

```sql
CREATE TABLE sos_alerts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  latitude DECIMAL(10,8) NOT NULL,
  longitude DECIMAL(11,8) NOT NULL,
  message TEXT,
  status ENUM('active', 'resolved', 'cancelled') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP NULL,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  
  INDEX idx_user_id (user_id),
  INDEX idx_status (status),
  INDEX idx_location (latitude, longitude),
  INDEX idx_created_at (created_at)
);
```

### 11. Targets Table
**Purpose**: Sales target management

```sql
CREATE TABLE targets (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  title VARCHAR(100) NOT NULL,
  description TEXT,
  target_value DECIMAL(10,2) NOT NULL,
  achieved_value DECIMAL(10,2) DEFAULT 0,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  status ENUM('active', 'completed', 'cancelled') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  
  INDEX idx_user_id (user_id),
  INDEX idx_status (status),
  INDEX idx_dates (start_date, end_date)
);
```

### 12. Leave Requests Table
**Purpose**: Leave management system

```sql
CREATE TABLE leave_requests (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  leave_type ENUM('annual', 'sick', 'personal', 'other') NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  reason TEXT NOT NULL,
  status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
  approved_by INT NULL,
  approved_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL,
  
  INDEX idx_user_id (user_id),
  INDEX idx_status (status),
  INDEX idx_dates (start_date, end_date),
  INDEX idx_approved_by (approved_by)
);
```

## Database Relationships

### Entity Relationship Diagram

```
users (1) ←→ (N) attendance
users (1) ←→ (N) orders
users (1) ←→ (N) visitors
users (1) ←→ (N) sos_alerts
users (1) ←→ (N) targets
users (1) ←→ (N) leave_requests
users (1) ←→ (N) qr_sessions (created_by)

locations (1) ←→ (N) attendance
locations (1) ←→ (N) qr_sessions

products (1) ←→ (N) orders

outlets (1) ←→ (N) visitors

users (1) ←→ (N) leave_requests (approved_by)
```

### Key Relationships:

1. **Users → Attendance**: One user can have multiple attendance records
2. **Users → Orders**: One user can place multiple orders
3. **Users → Visitors**: One user can have multiple visitor records
4. **Locations → Attendance**: One location can have multiple attendance records
5. **Products → Orders**: One product can be in multiple orders
6. **Outlets → Visitors**: One outlet can have multiple visitors

## Indexing Strategy

### Primary Indexes:
- All tables have auto-incrementing primary keys
- Unique constraints on business-critical fields

### Secondary Indexes:
- **Performance Indexes**: Frequently queried fields
- **Composite Indexes**: Multi-field queries
- **Foreign Key Indexes**: Relationship lookups
- **Status Indexes**: Filtering by status
- **Date Indexes**: Time-based queries
- **Geolocation Indexes**: Location-based queries

### Index Optimization:
```sql
-- Example of optimized composite index
CREATE INDEX idx_attendance_user_date_status 
ON attendance(user_id, date, status);

-- Example of geolocation index
CREATE INDEX idx_location_coords 
ON locations(latitude, longitude);
```

## Data Integrity Constraints

### Foreign Key Constraints:
- Cascade deletes for dependent records
- Set NULL for optional relationships
- Restrict deletes for critical relationships

### Check Constraints:
- Valid date ranges
- Positive numeric values
- Valid enum values

### Unique Constraints:
- Business-critical unique fields
- Composite unique constraints where needed

## Performance Considerations

### Query Optimization:
1. **Selective Indexing**: Index only frequently queried fields
2. **Composite Indexes**: Optimize multi-field queries
3. **Covering Indexes**: Include all needed fields in indexes
4. **Partitioning Ready**: Schema designed for future partitioning

### Connection Management:
1. **Connection Pooling**: Efficient connection reuse
2. **Transaction Management**: Proper transaction boundaries
3. **Query Timeout**: Prevent long-running queries
4. **Connection Health**: Monitor connection status

## Security Considerations

### Data Protection:
1. **Password Hashing**: SHA-256 with salt
2. **Input Validation**: Comprehensive data validation
3. **SQL Injection Prevention**: Parameterized queries
4. **Access Control**: Role-based permissions

### Audit Trail:
1. **Created/Updated Timestamps**: Track all changes
2. **User Tracking**: Log user actions
3. **Change History**: Maintain data history

## Backup and Recovery

### Backup Strategy:
1. **Full Backups**: Daily complete backups
2. **Incremental Backups**: Hourly incremental backups
3. **Transaction Logs**: Point-in-time recovery
4. **Offsite Storage**: Disaster recovery

### Recovery Procedures:
1. **Point-in-Time Recovery**: Restore to specific timestamp
2. **Data Validation**: Verify backup integrity
3. **Rollback Procedures**: Quick rollback capabilities

---

*This detailed schema documentation provides comprehensive information about the MOTORGAS database structure, relationships, and optimization strategies.* 