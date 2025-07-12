import 'package:woosh/services/database_service.dart';

class DatabaseTestController {
  static final DatabaseService _db = DatabaseService.instance;

  Future<Map<String, dynamic>> testConnection() async {
    return await _db.testConnection();
  }

  Future<bool> isHealthy() async {
    return await _db.isHealthy();
  }
}
