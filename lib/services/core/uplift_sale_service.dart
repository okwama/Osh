import 'package:woosh/services/database_service.dart';
import 'package:woosh/models/uplift_sale_model.dart';
import 'package:get_storage/get_storage.dart';
import 'package:woosh/models/client_model.dart';
import 'package:woosh/models/salerep/sales_rep_model.dart';
import 'package:woosh/models/Products_Inventory/product_model.dart';

/// Service for managing uplift sales using direct database connections
class UpliftSaleService {
  static final DatabaseService _db = DatabaseService.instance;

  /// Create a new uplift sale
  static Future<Map<String, dynamic>> createUpliftSale({
    required int clientId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      // Get current user from storage
      final box = GetStorage();
      final salesRepData = box.read('salesRep');
      final int? userId =
          salesRepData is Map<String, dynamic> ? salesRepData['id'] : null;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      return await _db.transaction((connection) async {
        // Create the uplift sale
        const saleSql = '''
          INSERT INTO upliftSale (
            clientId, userId, status, totalAmount, createdAt, updatedAt
          ) VALUES (?, ?, 'pending', 0, NOW(), NOW())
        ''';

        final saleResult = await connection.query(saleSql, [clientId, userId]);
        final saleId = saleResult.insertId;

        if (saleId == null) {
          throw Exception('Failed to create uplift sale');
        }

        // Create sale items and calculate total
        double totalAmount = 0;
        for (final item in items) {
          const itemSql = '''
            INSERT INTO upliftSaleItem (
              upliftSaleId, productId, quantity, unitPrice, total, createdAt
            ) VALUES (?, ?, ?, ?, ?, NOW())
          ''';

          final itemTotal =
              (item['unitPrice'] as double) * (item['quantity'] as int);
          totalAmount += itemTotal;

          await connection.query(itemSql, [
            saleId,
            item['productId'],
            item['quantity'],
            item['unitPrice'],
            itemTotal,
          ]);
        }

        // Update total amount
        const updateSql = '''
          UPDATE upliftSale 
          SET totalAmount = ?, updatedAt = NOW()
          WHERE id = ?
        ''';
        await connection.query(updateSql, [totalAmount, saleId]);

        return {
          'success': true,
          'message': 'Uplift sale created successfully',
          'saleId': saleId,
          'totalAmount': totalAmount,
        };
      });
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create uplift sale: $e',
      };
    }
  }

  /// Get uplift sales with optional filters - filter by salesRep ID only
  static Future<List<UpliftSale>> getUpliftSales({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? clientId,
    int? userId,
  }) async {
    try {
      // Get current user ID for filtering
      final box = GetStorage();
      final salesRepData = box.read('salesRep');
      final int? currentUserId =
          salesRepData is Map<String, dynamic> ? salesRepData['id'] : null;

      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      String sql = '''
        SELECT 
          us.*,
          c.name as clientName,
          c.contact as clientContact,
          c.address as clientAddress,
          c.region_id,
          c.countryId,
          sr.name as userName,
          sr.email as userEmail
        FROM UpliftSale us
        LEFT JOIN Clients c ON us.clientId = c.id
        LEFT JOIN SalesRep sr ON us.userId = sr.id
        WHERE us.userId = ?
      ''';

      final params = <dynamic>[currentUserId];

      if (status != null && status != 'all') {
        sql += ' AND us.status = ?';
        params.add(status);
      }

      if (clientId != null) {
        sql += ' AND us.clientId = ?';
        params.add(clientId);
      }

      if (userId != null) {
        sql += ' AND us.userId = ?';
        params.add(userId);
      }

      if (startDate != null) {
        sql += ' AND DATE(us.createdAt) >= ?';
        params.add(startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        sql += ' AND DATE(us.createdAt) <= ?';
        params.add(endDate.toIso8601String().split('T')[0]);
      }

      sql += ' ORDER BY us.createdAt DESC';

      final results = await _db.query(sql, params);

      final sales = <UpliftSale>[];
      for (final row in results) {
        final fields = row.fields;

        // Handle DateTime parsing - support both String and DateTime types
        DateTime parseDateTime(dynamic value) {
          if (value is DateTime) {
            return value;
          } else if (value is String) {
            return DateTime.parse(value);
          } else {
            return DateTime.now(); // Fallback
          }
        }

        // Get sale items
        final items = await getUpliftSaleItems(fields['id']);

        sales.add(UpliftSale(
          id: fields['id'],
          clientId: fields['clientId'],
          userId: fields['userId'],
          status: fields['status'],
          totalAmount: (fields['totalAmount'] ?? 0).toDouble(),
          createdAt: parseDateTime(fields['createdAt']),
          updatedAt: parseDateTime(fields['updatedAt']),
          client: fields['clientName'] != null
              ? Client(
                  id: fields['clientId'],
                  name: fields['clientName'],
                  contact: fields['clientContact'],
                  address: fields['clientAddress'],
                  regionId: fields['region_id'] ?? 1,
                  region: 'Default Region',
                  countryId: fields['countryId'] ?? 1,
                )
              : null,
          items: items,
        ));
      }

      return sales;
    } catch (e) {
      rethrow;
    }
  }

  /// Get uplift sale items
  static Future<List<UpliftSaleItem>> getUpliftSaleItems(int saleId) async {
    try {
      const sql = '''
        SELECT 
          usi.*,
          p.name as productName,
          p.image as productImage
        FROM UpliftSaleItem usi
        LEFT JOIN Product p ON usi.productId = p.id
        WHERE usi.upliftSaleId = ?
        ORDER BY usi.id ASC
      ''';

      final results = await _db.query(sql, [saleId]);

      return results.map((row) {
        final fields = row.fields;

        // Handle DateTime parsing - support both String and DateTime types
        DateTime parseDateTime(dynamic value) {
          if (value is DateTime) {
            return value;
          } else if (value is String) {
            return DateTime.parse(value);
          } else {
            return DateTime.now(); // Fallback
          }
        }

        return UpliftSaleItem(
          id: fields['id'],
          upliftSaleId: fields['upliftSaleId'],
          productId: fields['productId'],
          quantity: fields['quantity'],
          unitPrice: (fields['unitPrice'] ?? 0).toDouble(),
          total: (fields['total'] ?? 0).toDouble(),
          createdAt: parseDateTime(fields['createdAt']),
          product: fields['productName'] != null
              ? ProductModel(
                  id: fields['productId'],
                  name: fields['productName'],
                  categoryId: 1,
                  category: 'Default',
                  unitCost: (fields['unitPrice'] ?? 0).toDouble(),
                  description: '',
                  image: fields['productImage'],
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                )
              : null,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get uplift sale by ID - filter by salesRep ID for security
  static Future<UpliftSale?> getUpliftSaleById(int saleId) async {
    try {
      // Get current user ID for security filtering
      final box = GetStorage();
      final salesRepData = box.read('salesRep');
      final int? currentUserId =
          salesRepData is Map<String, dynamic> ? salesRepData['id'] : null;

      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      const sql = '''
        SELECT 
          us.*,
          c.name as clientName,
          c.contact as clientContact,
          c.address as clientAddress,
          c.region_id,
          c.countryId,
          sr.name as userName,
          sr.email as userEmail
        FROM UpliftSale us
        LEFT JOIN Clients c ON us.clientId = c.id
        LEFT JOIN SalesRep sr ON us.userId = sr.id
        WHERE us.id = ? AND us.userId = ?
      ''';

      final results = await _db.query(sql, [saleId, currentUserId]);

      if (results.isEmpty) return null;

      final fields = results.first.fields;
      
      // Handle DateTime parsing - support both String and DateTime types
      DateTime parseDateTime(dynamic value) {
        if (value is DateTime) {
          return value;
        } else if (value is String) {
          return DateTime.parse(value);
        } else {
          return DateTime.now(); // Fallback
        }
      }

      final items = await getUpliftSaleItems(saleId);

      return UpliftSale(
        id: fields['id'],
        clientId: fields['clientId'],
        userId: fields['userId'],
        status: fields['status'],
        totalAmount: (fields['totalAmount'] ?? 0).toDouble(),
        createdAt: parseDateTime(fields['createdAt']),
        updatedAt: parseDateTime(fields['updatedAt']),
        client: fields['clientName'] != null
            ? Client(
                id: fields['clientId'],
                name: fields['clientName'],
                contact: fields['clientContact'],
                address: fields['clientAddress'],
                regionId: fields['region_id'] ?? 1,
                region: 'Default Region',
                countryId: fields['countryId'] ?? 1,
              )
            : null,
        items: items,
      );
    } catch (e) {
      return null;
    }
  }

  /// Update uplift sale status - filter by salesRep ID for security
  static Future<bool> updateUpliftSaleStatus(int saleId, String status) async {
    try {
      // Get current user ID for security filtering
      final box = GetStorage();
      final salesRepData = box.read('salesRep');
      final int? currentUserId =
          salesRepData is Map<String, dynamic> ? salesRepData['id'] : null;

      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      const sql = '''
        UPDATE UpliftSale 
        SET status = ?, updatedAt = NOW()
        WHERE id = ? AND userId = ?
      ''';

      final result = await _db.query(sql, [status, saleId, currentUserId]);
      return (result.affectedRows ?? 0) > 0;
    } catch (e) {
      return false;
    }
  }

  /// Delete uplift sale - filter by salesRep ID for security
  static Future<bool> deleteUpliftSale(int saleId) async {
    try {
      // Get current user ID for security filtering
      final box = GetStorage();
      final salesRepData = box.read('salesRep');
      final int? currentUserId =
          salesRepData is Map<String, dynamic> ? salesRepData['id'] : null;

      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      return await _db.transaction((connection) async {
        // Delete sale items first - only if user owns the sale
        const deleteItemsSql = '''
          DELETE usi FROM UpliftSaleItem usi
          INNER JOIN UpliftSale us ON usi.upliftSaleId = us.id
          WHERE us.id = ? AND us.userId = ?
        ''';
        await connection.query(deleteItemsSql, [saleId, currentUserId]);

        // Delete the sale - only if user owns it
        const deleteSaleSql = '''
          DELETE FROM UpliftSale 
          WHERE id = ? AND userId = ?
        ''';
        final result =
            await connection.query(deleteSaleSql, [saleId, currentUserId]);

        return (result.affectedRows ?? 0) > 0;
      });
    } catch (e) {
      return false;
    }
  }
}