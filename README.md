# 🚀 Woosh - Flutter + GetX + Direct DB Project

A modern Flutter application built with GetX state management and direct MySQL database connections for enterprise sales and inventory management.

## 📋 Project Overview

Woosh is a comprehensive sales management application designed for field sales representatives, featuring:
- **Direct Database Access**: No API/server layer - direct MySQL connections
- **GetX State Management**: Reactive state management with dependency injection
- **Multi-country Support**: Country-specific data isolation and filtering
- **Offline Capability**: Local caching with Hive database
- **Real-time Sync**: Background synchronization with conflict resolution

## 🏗️ Architecture

### Core Principles
- **Controllers** = State Management (GetX controllers)
- **Services** = Database & Business Logic (direct MySQL)
- **Views** = UI Only (no business logic)
- **Models** = Data Structures & Serialization

### Folder Structure
```
lib/
├── controllers/          # GetX controllers for state management
├── services/            # Database and business logic services
│   ├── core/           # Core business services
│   ├── database/       # Database connection and utilities
│   └── hive/          # Local caching services
├── pages/              # UI pages and views
├── models/             # Data models and serialization
├── widgets/            # Reusable UI components
├── utils/              # Utility functions and helpers
├── config/             # Configuration files
└── routes/             # App routing
```

## 🚨 Critical Rules (Must Follow)

### 1. File Size Limit
- **Maximum 500 lines per file**
- Break large files into smaller, focused components
- Extract reusable widgets into separate files
- Split complex services into multiple specialized services

### 2. Architecture Layers
- **Controllers**: Only state management logic
- **Services**: Database operations and business logic
- **Views**: UI only - no business logic
- **Models**: Data structures and serialization

### 3. Security Guidelines
- Always filter by current user ID in database queries
- Use parameterized queries to prevent SQL injection
- Implement proper authentication and authorization
- Validate all user inputs
- Never expose sensitive data in logs

### 4. Database Guidelines
- Use direct MySQL connections (no API/server calls)
- Implement proper connection pooling and error handling
- Use transactions for multi-step operations
- Always include user/country filtering for data isolation

## 🛠️ Development Guidelines

### Code Quality Standards
- Follow Flutter/Dart best practices
- Use meaningful variable and function names
- Add proper documentation and comments
- Implement proper null safety
- Use consistent formatting and style

### Logging Standards
- Use descriptive log messages with emojis
- Log errors with context and stack traces
- Example: `print('🔍 Loading orders with filters: dateFrom=$dateFrom')`

### Error Handling
- Never continue silently after an error
- Report all failures immediately with details
- Show user-friendly error messages
- Implement proper error handling and recovery

### Performance Guidelines
- Implement proper pagination for large datasets
- Use caching for frequently accessed data
- Optimize database queries
- Minimize unnecessary API calls

## 🔧 Setup Instructions

### Prerequisites
- Flutter SDK (latest stable)
- Dart SDK
- MySQL Database
- Git

### Installation
1. Clone the repository
```bash
git clone <repository-url>
cd woosh_update
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure database connection
```bash
# Edit lib/config/database_config.dart
# Update database connection parameters
```

4. Run the application
```bash
flutter run
```

## 📊 Current Status

### ✅ Compliant Areas
- Proper folder structure for most files
- GetX state management implementation
- Direct database connections
- User/country filtering in queries
- Null safety implementation

### ⚠️ Areas Needing Attention
- **Large files** (>500 lines) need modularization
- **Business logic in UI files** needs refactoring
- **SQL injection vulnerabilities** need fixing
- **Inconsistent error handling** needs standardization

## 🚀 Quick Start

### For Developers
1. Read the `.cursorrules` file for detailed guidelines
2. Follow the architecture layers strictly
3. Keep files under 500 lines
4. Implement proper error handling
5. Use descriptive logging with emojis

### For Contributors
1. Check existing functions before creating new ones
2. Reuse existing services and utilities
3. Follow the established project structure
4. Test all database operations
5. Verify security measures work correctly

## 📝 Development Workflow

### Before Making Changes
1. Check for existing similar functionality
2. Verify file size limits
3. Plan architecture layer placement
4. Consider security implications

### During Development
1. Log all major steps with emojis
2. Implement proper error handling
3. Test database operations
4. Verify user data isolation

### After Changes
1. Test error scenarios and edge cases
2. Verify proper user data isolation
3. Check file sizes and modularize if needed
4. Update documentation

## 🔒 Security Checklist

- [ ] User ID filtering in all queries
- [ ] Country ID filtering in all queries
- [ ] Parameterized queries (no string interpolation)
- [ ] Input validation
- [ ] Proper error handling (no empty catch blocks)
- [ ] No sensitive data in logs
- [ ] Authentication checks
- [ ] Authorization checks

## 📈 Performance Checklist

- [ ] Pagination for large datasets
- [ ] Caching for frequent data
- [ ] Optimized database queries
- [ ] Loading states in UI
- [ ] Error retry mechanisms
- [ ] Proper connection pooling

## 🐛 Troubleshooting

### Common Issues
1. **Database Connection Errors**: Check `database_config.dart`
2. **Large File Compilation**: Break files into smaller components
3. **State Management Issues**: Verify GetX controller usage
4. **Security Violations**: Check user/country filtering

### Debug Commands
```bash
# Check for large files
Get-ChildItem -Path lib -Recurse -Filter "*.dart" | ForEach-Object { $lines = (Get-Content $_.FullName | Measure-Object -Line).Lines; [PSCustomObject]@{File=$_.Name; Lines=$lines; Path=$_.FullName} } | Sort-Object Lines -Descending | Select-Object -First 10

# Run tests
flutter test

# Analyze code
flutter analyze
```

## 📚 Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [GetX Documentation](https://pub.dev/packages/get)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [MySQL Documentation](https://dev.mysql.com/doc/)

## 🤝 Contributing

1. Follow the `.cursorrules` guidelines
2. Keep files under 500 lines
3. Implement proper error handling
4. Test all changes thoroughly
5. Update documentation

## 📄 License

[Add your license information here]

---

**Remember**: Security and data integrity are paramount. Always prioritize user data protection and proper access controls.
