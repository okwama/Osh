import 'package:woosh/services/database_service.dart';
import 'package:woosh/models/task_model.dart';
import 'package:get_storage/get_storage.dart';

/// Service for managing tasks using direct database connections
class TaskService {
  static final DatabaseService _db = DatabaseService.instance;

  /// Get all tasks for the current user
  static Future<List<Task>> getTasks() async {
    try {

      // Get current user from storage
      final box = GetStorage();
      final salesRepData = box.read('salesRep');
      final int? userId =
          salesRepData is Map<String, dynamic> ? salesRepData['id'] : null;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      const sql = '''
        SELECT 
          t.*,
          sr.name as assignedByName,
          sr.email as assignedByEmail
        FROM tasks t
        LEFT JOIN SalesRep sr ON t.assignedById = sr.id
        WHERE t.salesRepId = ? AND t.isCompleted = 0
        ORDER BY t.createdAt DESC
      ''';

      final results = await _db.query(sql, [userId]);

      return results.map((row) {
        final fields = row.fields;
        return Task(
          id: fields['id'],
          title: fields['title'],
          description: fields['description'],
          createdAt: DateTime.parse(fields['createdAt']),
          completedAt: fields['completedAt'] != null
              ? DateTime.parse(fields['completedAt'])
              : null,
          isCompleted: fields['isCompleted'] == 1,
          salesRepId: fields['salesRepId'],
          priority: fields['priority'] ?? 'medium',
          status: fields['status'] ?? 'pending',
          assignedBy: fields['assignedByName'] != null
              ? AssignedBy(
                  id: fields['assignedById'] ?? 0,
                  username: fields['assignedByName'],
                )
              : null,
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get task history (completed tasks)
  static Future<List<Task>> getTaskHistory() async {
    try {

      // Get current user from storage
      final box = GetStorage();
      final salesRepData = box.read('salesRep');
      final int? userId =
          salesRepData is Map<String, dynamic> ? salesRepData['id'] : null;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      const sql = '''
        SELECT 
          t.*,
          sr.name as assignedByName,
          sr.email as assignedByEmail
        FROM tasks t
        LEFT JOIN SalesRep sr ON t.assignedById = sr.id
        WHERE t.salesRepId = ? AND t.isCompleted = 1
        ORDER BY t.completedAt DESC
      ''';

      final results = await _db.query(sql, [userId]);

      return results.map((row) {
        final fields = row.fields;
        return Task(
          id: fields['id'],
          title: fields['title'],
          description: fields['description'],
          createdAt: DateTime.parse(fields['createdAt']),
          completedAt: fields['completedAt'] != null
              ? DateTime.parse(fields['completedAt'])
              : null,
          isCompleted: fields['isCompleted'] == 1,
          salesRepId: fields['salesRepId'],
          priority: fields['priority'] ?? 'medium',
          status: fields['status'] ?? 'completed',
          assignedBy: fields['assignedByName'] != null
              ? AssignedBy(
                  id: fields['assignedById'] ?? 0,
                  username: fields['assignedByName'],
                )
              : null,
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Complete a task
  static Future<bool> completeTask(int taskId) async {
    try {

      const sql = '''
        UPDATE tasks 
        SET isCompleted = 1, completedAt = NOW(), status = 'completed'
        WHERE id = ?
      ''';

      final result = await _db.query(sql, [taskId]);
      return (result.affectedRows ?? 0) > 0;
    } catch (e) {
      return false;
    }
  }

  /// Create a new task
  static Future<int?> createTask({
    required String title,
    required String description,
    required int salesRepId,
    required String priority,
    int? assignedById,
  }) async {
    try {

      const sql = '''
        INSERT INTO tasks (
          title, description, salesRepId, priority, status, 
          isCompleted, assignedById, createdAt
        ) VALUES (?, ?, ?, ?, 'pending', 0, ?, NOW())
      ''';

      final result = await _db.query(sql, [
        title,
        description,
        salesRepId,
        priority,
        assignedById,
      ]);

      return result.insertId;
    } catch (e) {
      return null;
    }
  }

  /// Update a task
  static Future<bool> updateTask({
    required int taskId,
    String? title,
    String? description,
    String? priority,
    String? status,
  }) async {
    try {

      String sql = 'UPDATE tasks SET ';
      final params = <dynamic>[];
      final updates = <String>[];

      if (title != null) {
        updates.add('title = ?');
        params.add(title);
      }

      if (description != null) {
        updates.add('description = ?');
        params.add(description);
      }

      if (priority != null) {
        updates.add('priority = ?');
        params.add(priority);
      }

      if (status != null) {
        updates.add('status = ?');
        params.add(status);
      }

      if (updates.isEmpty) return false;

      sql += updates.join(', ');
      sql += ' WHERE id = ?';
      params.add(taskId);

      final result = await _db.query(sql, params);
      return (result.affectedRows ?? 0) > 0;
    } catch (e) {
      return false;
    }
  }

  /// Delete a task
  static Future<bool> deleteTask(int taskId) async {
    try {

      const sql = 'DELETE FROM tasks WHERE id = ?';
      final result = await _db.query(sql, [taskId]);

      return (result.affectedRows ?? 0) > 0;
    } catch (e) {
      return false;
    }
  }

  /// Get task statistics
  static Future<Map<String, dynamic>> getTaskStats() async {
    try {

      // Get current user from storage
      final box = GetStorage();
      final salesRepData = box.read('salesRep');
      final int? userId =
          salesRepData is Map<String, dynamic> ? salesRepData['id'] : null;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      const sql = '''
        SELECT 
          COUNT(*) as totalTasks,
          SUM(CASE WHEN isCompleted = 1 THEN 1 ELSE 0 END) as completedTasks,
          SUM(CASE WHEN isCompleted = 0 THEN 1 ELSE 0 END) as pendingTasks,
          SUM(CASE WHEN priority = 'high' THEN 1 ELSE 0 END) as highPriorityTasks,
          SUM(CASE WHEN priority = 'medium' THEN 1 ELSE 0 END) as mediumPriorityTasks,
          SUM(CASE WHEN priority = 'low' THEN 1 ELSE 0 END) as lowPriorityTasks
        FROM tasks 
        WHERE salesRepId = ?
      ''';

      final results = await _db.query(sql, [userId]);

      if (results.isEmpty) {
        return {
          'totalTasks': 0,
          'completedTasks': 0,
          'pendingTasks': 0,
          'highPriorityTasks': 0,
          'mediumPriorityTasks': 0,
          'lowPriorityTasks': 0,
        };
      }

      final fields = results.first.fields;
      return {
        'totalTasks': fields['totalTasks'] ?? 0,
        'completedTasks': fields['completedTasks'] ?? 0,
        'pendingTasks': fields['pendingTasks'] ?? 0,
        'highPriorityTasks': fields['highPriorityTasks'] ?? 0,
        'mediumPriorityTasks': fields['mediumPriorityTasks'] ?? 0,
        'lowPriorityTasks': fields['lowPriorityTasks'] ?? 0,
      };
    } catch (e) {
      return {
        'totalTasks': 0,
        'completedTasks': 0,
        'pendingTasks': 0,
        'highPriorityTasks': 0,
        'mediumPriorityTasks': 0,
        'lowPriorityTasks': 0,
      };
    }
  }
}