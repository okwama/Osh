import 'package:woosh/services/database_service.dart';
import 'package:woosh/models/noticeboard_model.dart';

/// Service for managing notice board using direct database connections
class NoticeService {
  static final DatabaseService _db = DatabaseService.instance;

  /// Get all notices
  static Future<List<NoticeBoard>> getNotices() async {
    try {

      const sql = '''
        SELECT 
          id, title, content, createdAt, updatedAt, countryId
        FROM NoticeBoard 
        ORDER BY createdAt DESC
      ''';

      final results = await _db.query(sql);

      return results.map((row) {
        final fields = row.fields;
        return NoticeBoard(
          id: fields['id'],
          title: fields['title'] ?? '',
          content: fields['content'] ?? '',
          createdAt: fields['createdAt'] is DateTime
              ? fields['createdAt']
              : DateTime.parse(fields['createdAt'].toString()),
          updatedAt: fields['updatedAt'] is DateTime
              ? fields['updatedAt']
              : DateTime.parse(fields['updatedAt'].toString()),
          countryId: fields['countryId'],
        );
      }).toList();
    } catch (e) {
      print('❌ Error getting notices: $e');
      rethrow;
    }
  }

  /// Get notice by ID
  static Future<NoticeBoard?> getNoticeById(int id) async {
    try {

      const sql = '''
        SELECT 
          id, title, content, createdAt, updatedAt, countryId
        FROM NoticeBoard 
        WHERE id = ?
      ''';

      final results = await _db.query(sql, [id]);

      if (results.isEmpty) return null;

      final fields = results.first.fields;
      return NoticeBoard(
        id: fields['id'],
        title: fields['title'] ?? '',
        content: fields['content'] ?? '',
        createdAt: fields['createdAt'] is DateTime
            ? fields['createdAt']
            : DateTime.parse(fields['createdAt'].toString()),
        updatedAt: fields['updatedAt'] is DateTime
            ? fields['updatedAt']
            : DateTime.parse(fields['updatedAt'].toString()),
        countryId: fields['countryId'],
      );
    } catch (e) {
      print('❌ Error getting notice by ID: $e');
      return null;
    }
  }

  /// Create a new notice
  static Future<Map<String, dynamic>> createNotice({
    required String title,
    required String content,
    int? countryId,
  }) async {
    try {

      const sql = '''
        INSERT INTO NoticeBoard (
          title, content, countryId, createdAt, updatedAt
        ) VALUES (?, ?, ?, NOW(), NOW())
      ''';

      final result = await _db.query(sql, [title, content, countryId]);

      if (result.insertId != null) {
        return {
          'success': true,
          'message': 'Notice created successfully',
          'noticeId': result.insertId,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create notice',
        };
      }
    } catch (e) {
      print('❌ Error creating notice: $e');
      return {
        'success': false,
        'message': 'Failed to create notice: $e',
      };
    }
  }

  /// Update a notice
  static Future<bool> updateNotice({
    required int id,
    String? title,
    String? content,
    int? countryId,
  }) async {
    try {

      final updateFields = <String>[];
      final params = <dynamic>[];

      if (title != null) {
        updateFields.add('title = ?');
        params.add(title);
      }

      if (content != null) {
        updateFields.add('content = ?');
        params.add(content);
      }

      if (countryId != null) {
        updateFields.add('countryId = ?');
        params.add(countryId);
      }

      if (updateFields.isEmpty) {
        return false;
      }

      updateFields.add('updatedAt = NOW()');
      params.add(id);

      final sql = '''
        UPDATE NoticeBoard 
        SET ${updateFields.join(', ')}
        WHERE id = ?
      ''';

      final result = await _db.query(sql, params);
      return (result.affectedRows ?? 0) > 0;
    } catch (e) {
      print('❌ Error updating notice: $e');
      return false;
    }
  }

  /// Delete a notice
  static Future<bool> deleteNotice(int id) async {
    try {

      const sql = 'DELETE FROM NoticeBoard WHERE id = ?';

      final result = await _db.query(sql, [id]);
      return (result.affectedRows ?? 0) > 0;
    } catch (e) {
      print('❌ Error deleting notice: $e');
      return false;
    }
  }

  /// Get count of recent notices (last N days)
  static Future<int> getRecentNoticesCount(int days) async {
    try {

      final sql = '''
        SELECT COUNT(*) as count
        FROM NoticeBoard 
        WHERE createdAt >= DATE_SUB(NOW(), INTERVAL ? DAY)
      ''';

      final results = await _db.query(sql, [days]);
      return results.first['count'] ?? 0;
    } catch (e) {
      print('❌ Error getting recent notices count: $e');
      return 0;
    }
  }

  /// Get count of unread notices (notices created after last read timestamp)
  static Future<int> getUnreadNoticesCount(DateTime lastReadTime) async {
    try {

      const sql = '''
        SELECT COUNT(*) as count
        FROM NoticeBoard 
        WHERE createdAt > ?
      ''';

      final results = await _db.query(sql, [lastReadTime.toIso8601String()]);
      return results.first['count'] ?? 0;
    } catch (e) {
      print('❌ Error getting unread notices count: $e');
      return 0;
    }
  }
}
