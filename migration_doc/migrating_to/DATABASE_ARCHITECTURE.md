# MOTORGAS Database System Architecture Documentation

## Overview

The MOTORGAS application implements a hybrid database architecture that supports both mobile and web platforms with different authentication and data access strategies. The system uses MySQL as the primary database with a sophisticated service layer for data management.

## Architecture Components

### 1. Database Layer

#### Primary Database: MySQL
- **Host**: 102.218.215.35
- **Database**: citlogis_forecourt
- **Port**: 3306
- **Connection Pool**: Singleton pattern with connection management

#### Database Service (`lib/services/database_service.dart`)
```dart
class DatabaseService {
  // Singleton pattern for connection management
  static DatabaseService? _instance;
  static MySqlConnection? _connection;
  
  // Core methods:
  - initialize() - Establishes database connection
  - query() - Executes SELECT queries
  - execute() - Executes INSERT/UPDATE/DELETE queries
  - beginTransaction() / commit() / rollback() - Transaction management
  - isConnected() / reconnect() - Connection health monitoring
}
```

**Key Features:**
- Platform-aware (skips MySQL on web platform)
- Connection pooling and health monitoring
- Transaction support
- Error handling and logging
- Automatic reconnection on connection loss

### 2. Schema Management

#### Database Schema Helper (`lib/services/db_schema_helper.dart`)
Defines the complete database schema with the following tables:

1. **users** - User authentication and profile data
2. **products** - Product catalog
3. **orders** - Order management
4. **outlets** - Store/outlet locations
5. **visitors** - Visitor tracking
6. **sos_alerts** - Emergency alerts
7. **targets** - Sales targets and goals
8. **leave_requests** - Leave management

#### Core Tables Structure:

**Users Table:**
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
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

**Attendance System:**
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
  status ENUM('present', 'absent', 'late', 'half_day', 'leave', 'holiday', 'remote'),
  hours_worked DECIMAL(5, 2) DEFAULT 0,
  check_in_method ENUM('qr', 'mobile', 'web', 'manual') NULL,
  notes TEXT
);
```

### 3. Authentication System

#### Hybrid Authentication Service (`lib/services/hybrid_auth_service.dart`)
Implements platform-specific authentication strategies:

**Mobile Platform:**
- Direct MySQL database authentication
- QR code-based login
- Session management with local storage

**Web Platform:**
- Mock authentication (for development)
- Local storage-based session management
- API-based authentication (extensible)

#### Database Authentication Service (`lib/services/db_auth_service.dart`)
```dart
class DbAuthService {
  // Authentication methods:
  - login(phoneNumber, password) - Standard login
  - loginWithQrCode(qrCode) - QR-based authentication
  - getUserById(userId) - User retrieval
  - updateProfile(userId, data) - Profile updates
  - changePassword(userId, currentPassword, newPassword) - Password management
}
```

**Security Features:**
- SHA-256 password hashing
- QR code authentication
- Session token generation
- Role-based access control

### 4. Data Models

The application uses a comprehensive model system (`lib/models/`) with the following key models:

#### Core Models:
- **UserModel** - User authentication and profile data
- **AttendanceModel** - Attendance tracking with geolocation
- **CheckinModel** - Check-in/check-out records
- **LocationModel** - Valid check-in locations
- **QRSessionModel** - QR session management

#### Business Models:
- **ProductModel** - Product catalog
- **OrderModel** - Order management
- **OutletModel** - Store locations
- **TargetModel** - Sales targets
- **LeaveModel** - Leave requests
- **SOSModel** - Emergency alerts
- **VisitorModel** - Visitor tracking

#### Report Models (`lib/models/report/`):
- **FeedbackReportModel** - Customer feedback reports
- **ProductReportModel** - Product performance reports
- **ReportModel** - Generic reporting
- **VisibilityReportModel** - Product visibility reports

### 5. Service Layer Architecture

#### Service Organization:
```
lib/services/
├── database_service.dart      # Core database connection
├── db_schema_helper.dart      # Schema definitions
├── db_auth_service.dart       # Database authentication
├── hybrid_auth_service.dart   # Platform-specific auth
├── api_service.dart          # REST API integration
├── attendance_service.dart    # Attendance management
├── checkin_service.dart      # Check-in operations
├── product_service.dart      # Product management
├── sos_service.dart          # Emergency services
└── visitor_service.dart      # Visitor management
```

### 6. Data Flow Architecture

#### Mobile Platform Flow:
```
User Action → HybridAuthService → DbAuthService → DatabaseService → MySQL
```

#### Web Platform Flow:
```
User Action → HybridAuthService → ApiService → REST API → Database
```

### 7. Performance Optimization Features

#### Database Optimization:
- **Indexing Strategy**: Comprehensive indexing on frequently queried fields
- **Connection Pooling**: Singleton pattern for connection management
- **Query Optimization**: Prepared statements and parameterized queries
- **Transaction Management**: ACID compliance for critical operations

#### Application-Level Optimization:
- **Caching**: Local storage for user sessions and frequently accessed data
- **Lazy Loading**: On-demand data loading for large datasets
- **Error Handling**: Graceful degradation and retry mechanisms
- **Platform Detection**: Optimized code paths for different platforms

### 8. Security Architecture

#### Authentication Security:
- **Password Hashing**: SHA-256 with salt
- **QR Code Authentication**: Secure session-based QR codes
- **Session Management**: Token-based sessions with expiration
- **Role-Based Access**: Granular permission system

#### Data Security:
- **SQL Injection Prevention**: Parameterized queries
- **Connection Security**: Encrypted database connections
- **Input Validation**: Comprehensive data validation
- **Error Handling**: Secure error messages without data leakage

### 9. Scalability Considerations

#### Database Scalability:
- **Connection Pooling**: Efficient connection management
- **Indexing Strategy**: Optimized for read-heavy workloads
- **Partitioning Ready**: Schema designed for future partitioning
- **Backup Strategy**: Automated backup and recovery

#### Application Scalability:
- **Service Layer**: Modular design for easy scaling
- **Caching Strategy**: Multi-level caching approach
- **Async Operations**: Non-blocking database operations
- **Error Recovery**: Robust error handling and recovery

### 10. Monitoring and Maintenance

#### Database Monitoring:
- **Connection Health**: Automatic connection monitoring
- **Query Performance**: Query execution time tracking
- **Error Logging**: Comprehensive error logging
- **Health Checks**: Regular database health verification

#### Application Monitoring:
- **Performance Metrics**: Response time monitoring
- **Error Tracking**: Comprehensive error reporting
- **User Analytics**: Usage pattern analysis
- **Health Endpoints**: Application health monitoring

## Configuration

### Database Configuration:
```dart
// Database connection settings
static const String _host = '102.218.215.35';
static const String _user = 'citlogis_bryan';
static const String _password = '@bo9511221.qwerty';
static const String _database = 'citlogis_forecourt';
static const int _port = 3306;
```

### Environment Variables:
- Database credentials should be moved to environment variables
- Connection pooling parameters configurable
- Timeout settings adjustable per environment

## Deployment Considerations

### Production Deployment:
1. **Database Security**: Use environment variables for credentials
2. **Connection Pooling**: Optimize connection pool size
3. **Monitoring**: Implement comprehensive monitoring
4. **Backup Strategy**: Regular automated backups
5. **SSL/TLS**: Encrypted database connections

### Development Environment:
1. **Local Database**: Development database setup
2. **Mock Data**: Sample data for testing
3. **Debug Logging**: Enhanced logging for development
4. **Hot Reload**: Fast development iteration

## Future Enhancements

### Planned Improvements:
1. **Microservices Architecture**: Service decomposition
2. **Real-time Updates**: WebSocket integration
3. **Advanced Caching**: Redis integration
4. **Analytics Integration**: Business intelligence
5. **API Gateway**: Centralized API management

### Performance Optimizations:
1. **Query Optimization**: Advanced query tuning
2. **Caching Strategy**: Multi-level caching
3. **Database Sharding**: Horizontal scaling
4. **CDN Integration**: Content delivery optimization

---

*This documentation provides a comprehensive overview of the MOTORGAS database system architecture. For specific implementation details, refer to the individual service files and database schema definitions.* 