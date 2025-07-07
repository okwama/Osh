import 'dart:io';
import 'package:woosh/models/client_payment_model.dart';
import 'package:woosh/services/database_service.dart';

/// Payment service using direct database connections
class PaymentService {
  static final DatabaseService _db = DatabaseService.instance;

  /// Get client payments
  static Future<List<ClientPayment>> getClientPayments(int clientId) async {
    try {

      const sql = '''
        SELECT 
          cp.id,
          cp.clientId,
          cp.userId,
          cp.amount,
          cp.method,
          cp.imageUrl,
          cp.status,
          cp.date
        FROM ClientPayment cp
        WHERE cp.clientId = ?
        ORDER BY cp.date DESC
      ''';

      final results = await _db.query(sql, [clientId]);

      return results.map((row) => _mapToClientPayment(row.fields)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Upload client payment
  static Future<ClientPayment> uploadClientPayment({
    required int clientId,
    required double amount,
    required String method,
    File? imageFile,
    List<int>? imageBytes,
  }) async {
    try {

      // For now, we'll create a simple payment record without image upload
      // In a real implementation, you'd handle image upload to a storage service
      const sql = '''
        INSERT INTO ClientPayment (
          clientId, userId, amount, method, status, date
        ) VALUES (?, ?, ?, ?, ?, ?)
      ''';

      final params = [
        clientId,
        _db.getCurrentUserId(),
        amount,
        method,
        'PENDING', // Default status
        DateTime.now().toIso8601String(),
      ];

      final result = await _db.query(sql, params);
      final paymentId = result.insertId;

      if (paymentId == null) {
        throw Exception('Failed to create payment');
      }

      // Fetch the created payment
      final createdPayment = await getClientPaymentById(paymentId);
      if (createdPayment == null) {
        throw Exception('Failed to fetch created payment');
      }
      return createdPayment;
    } catch (e) {
      rethrow;
    }
  }

  /// Get a specific payment by ID
  static Future<ClientPayment?> getClientPaymentById(int paymentId) async {
    try {

      const sql = '''
        SELECT 
          cp.id,
          cp.clientId,
          cp.userId,
          cp.amount,
          cp.method,
          cp.imageUrl,
          cp.status,
          cp.date
        FROM ClientPayment cp
        WHERE cp.id = ?
      ''';

      final results = await _db.query(sql, [paymentId]);

      if (results.isNotEmpty) {
        return _mapToClientPayment(results.first.fields);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Update payment status
  static Future<ClientPayment> updatePaymentStatus({
    required int paymentId,
    required String status,
  }) async {
    try {

      const sql = '''
        UPDATE ClientPayment 
        SET status = ? 
        WHERE id = ?
      ''';

      await _db.query(sql, [status, paymentId]);

      // Fetch the updated payment
      final updatedPayment = await getClientPaymentById(paymentId);
      if (updatedPayment == null) {
        throw Exception('Failed to fetch updated payment');
      }
      return updatedPayment;
    } catch (e) {
      rethrow;
    }
  }

  /// Get payment statistics for a client
  static Future<Map<String, dynamic>> getClientPaymentStats(
      int clientId) async {
    try {

      const sql = '''
        SELECT 
          COUNT(*) as total_payments,
          SUM(amount) as total_amount,
          COUNT(CASE WHEN status = 'VERIFIED' THEN 1 END) as verified_payments,
          COUNT(CASE WHEN status = 'PENDING' THEN 1 END) as pending_payments,
          COUNT(CASE WHEN status = 'REJECTED' THEN 1 END) as rejected_payments
        FROM ClientPayment
        WHERE clientId = ?
      ''';

      final results = await _db.query(sql, [clientId]);

      if (results.isNotEmpty) {
        final row = results.first.fields;
        return {
          'total_payments': row['total_payments'] ?? 0,
          'total_amount': row['total_amount']?.toDouble() ?? 0.0,
          'verified_payments': row['verified_payments'] ?? 0,
          'pending_payments': row['pending_payments'] ?? 0,
          'rejected_payments': row['rejected_payments'] ?? 0,
        };
      }

      return {
        'total_payments': 0,
        'total_amount': 0.0,
        'verified_payments': 0,
        'pending_payments': 0,
        'rejected_payments': 0,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Helper method to map database row to ClientPayment
  static ClientPayment _mapToClientPayment(Map<String, dynamic> row) {
    return ClientPayment(
      id: row['id'] ?? 0,
      clientId: row['clientId'] ?? 0,
      userId: row['userId'] ?? 0,
      amount: (row['amount'] ?? 0).toDouble(),
      method: row['method'],
      imageUrl: row['imageUrl'],
      status: row['status'] ?? 'PENDING',
      date: DateTime.parse(row['date'] ?? DateTime.now().toIso8601String()),
    );
  }
}