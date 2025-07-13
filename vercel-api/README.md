# Woosh API - Vercel Serverless

Fast, secure API for Woosh Flutter app using Vercel serverless functions.

## 🚀 Quick Deploy

### 1. Install Dependencies
```bash
npm install
```

### 2. Deploy to Vercel
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel --prod
```

### 3. Get Your API URL
After deployment, you'll get a URL like:
```
https://woosh-api.vercel.app
```

## 📡 API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/refresh` - Refresh JWT token

### Database Queries
- `POST /api/query` - Execute SQL queries (your existing queries)

## 🔧 Flutter Integration

### 1. Update Database Config
```dart
// lib/config/database_config.dart
class DatabaseConfig {
  // Change this line
  static const String apiUrl = 'https://your-vercel-url.vercel.app/api';
  
  // Keep existing config for gradual migration
  static const String host = '102.218.215.35';
  // ... rest unchanged
}
```

### 2. Create API Service
```dart
// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = DatabaseConfig.apiUrl;
  
  static Future<List<Map<String, dynamic>>> query(String sql, [List<Object?>? values]) async {
    final response = await http.post(
      Uri.parse('$baseUrl/query'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'sql': sql, 'values': values}),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    }
    throw Exception('Query failed: ${response.body}');
  }
}
```

### 3. Update Database Service
```dart
// lib/services/database_service.dart
// Replace direct DB calls with API calls
Future<Results> query(String sql, [List<Object?>? values]) async {
  try {
    final results = await ApiService.query(sql, values);
    return Results(results); // Convert to your Results format
  } catch (e) {
    // Fallback to direct DB if needed
    return await _queryExecutor.execute(sql, values);
  }
}
```

## 🔐 Environment Variables

Set these in Vercel dashboard:

```env
DB_HOST=102.218.215.35
DB_USER=citlogis_bryan
DB_PASSWORD=@bo9511221.qwerty
DB_NAME=citlogis_ws
DB_PORT=3306
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
```

## 🛡️ Security Features

- ✅ JWT Authentication
- ✅ SQL Injection Protection
- ✅ CORS Configuration
- ✅ Rate Limiting (configurable)
- ✅ Input Validation
- ✅ Error Logging

## 📊 Performance

- ⚡ **Global Edge Functions** - Fast worldwide access
- ⚡ **Auto-scaling** - Handles traffic spikes
- ⚡ **Connection Pooling** - Optimized database connections
- ⚡ **Caching** - Built-in Vercel caching

## 🔄 Migration Strategy

### Phase 1: Deploy API (30 minutes)
- Deploy to Vercel
- Test endpoints
- Update Flutter config

### Phase 2: Gradual Migration (1 week)
- Move one service at a time
- Keep direct DB as fallback
- Monitor performance

### Phase 3: Full Migration (1 day)
- Remove direct DB connections
- Add authentication headers
- Optimize queries

## 🐛 Troubleshooting

### Common Issues

1. **Connection Timeout**
   - Check database credentials
   - Verify network connectivity

2. **CORS Errors**
   - Ensure proper headers in vercel.json
   - Check Flutter app origin

3. **JWT Errors**
   - Verify JWT_SECRET is set
   - Check token expiration

### Debug Mode
```bash
# Local development
vercel dev

# Check logs
vercel logs
```

## 📈 Monitoring

- **Vercel Analytics** - Built-in performance monitoring
- **Function Logs** - Real-time error tracking
- **Database Metrics** - Query performance

## 🔄 Updates

To update the API:
```bash
# Make changes to code
git add .
git commit -m "Update API"

# Deploy
vercel --prod
```

## 📞 Support

For issues or questions:
1. Check Vercel logs
2. Review function execution times
3. Monitor database connections
4. Test endpoints individually 