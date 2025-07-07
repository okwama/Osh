import 'package:woosh/services/database_service.dart';

/// Service for managing targets using direct database connections
class TargetService {
  static final DatabaseService _db = DatabaseService.instance;

  /// Get daily visit targets for a user
  static Future<Map<String, dynamic>> getDailyVisitTargets({
    required String userId,
    String? date,
  }) async {
    try {
      print('🔍 Getting daily visit targets for user: $userId, date: $date');

      final targetDate = date ?? DateTime.now().toIso8601String().split('T')[0];

      // Get user's visit target
      const userSql = '''
        SELECT visits_targets FROM SalesRep 
        WHERE id = ? AND status >= 0
      ''';

      final userResults = await _db.query(userSql, [userId]);
      if (userResults.isEmpty) {
        print('⚠️ No user found with ID: $userId');
        return {
          'visitTarget': 0,
          'completedVisits': 0,
          'remainingVisits': 0,
          'progress': 0,
          'status': 'No Target Set',
        };
      }

      final visitTarget = userResults.first.fields['visits_targets'] ?? 0;

      // Get completed visits for the date from Report table (VISIBILITY_ACTIVITY type)
      const visitsSql = '''
        SELECT COUNT(*) as completed_visits
        FROM Report 
        WHERE userId = ? 
        AND DATE(createdAt) = ? 
        AND type = 'VISIBILITY_ACTIVITY'
      ''';

      final visitsResults = await _db.query(visitsSql, [userId, targetDate]);
      final completedVisits =
          visitsResults.first.fields['completed_visits'] ?? 0;

      final remainingVisits = visitTarget - completedVisits;
      final progress =
          visitTarget > 0 ? (completedVisits / visitTarget * 100).round() : 0;
      final status =
          completedVisits >= visitTarget ? 'Target Achieved' : 'In Progress';

      print(
          '✅ Daily visit targets: target=$visitTarget, completed=$completedVisits, progress=$progress%');

      return {
        'visitTarget': visitTarget,
        'completedVisits': completedVisits,
        'remainingVisits': remainingVisits,
        'progress': progress,
        'status': status,
        'date': targetDate,
      };
    } catch (e) {
      print('❌ Error getting daily visit targets: $e');
      return {
        'visitTarget': 0,
        'completedVisits': 0,
        'remainingVisits': 0,
        'progress': 0,
        'status': 'Error',
        'error': e.toString(),
      };
    }
  }

  /// Get monthly visits for a user
  static Future<List<dynamic>> getMonthlyVisits(
      {required String userId}) async {
    try {
      print('🔍 Getting monthly visits for user: $userId');

      // Get visits for the last 30 days from Report table
      const visitsSql = '''
        SELECT 
          DATE(createdAt) as visit_date,
          COUNT(*) as completed_visits
        FROM Report 
        WHERE userId = ? 
        AND createdAt >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        AND type = 'VISIBILITY_ACTIVITY'
        GROUP BY DATE(createdAt)
        ORDER BY visit_date DESC
      ''';

      final visitsResults = await _db.query(visitsSql, [userId]);

      // Get user's daily visit target
      const userSql = '''
        SELECT visits_targets FROM SalesRep 
        WHERE id = ? AND status >= 0
      ''';

      final userResults = await _db.query(userSql, [userId]);
      final dailyTarget = userResults.isNotEmpty
          ? (userResults.first.fields['visits_targets'] ?? 0)
          : 0;

      final List<Map<String, dynamic>> visits = [];

      for (final row in visitsResults) {
        final visitDate = row.fields['visit_date'];
        final completedVisits = row.fields['completed_visits'] ?? 0;
        final progress =
            dailyTarget > 0 ? (completedVisits / dailyTarget * 100).round() : 0;

        visits.add({
          'date': visitDate,
          'visitTarget': dailyTarget,
          'completedVisits': completedVisits,
          'progress': progress,
        });
      }

      print('✅ Monthly visits retrieved: ${visits.length} days');
      return visits;
    } catch (e) {
      print('❌ Error getting monthly visits: $e');
      return [];
    }
  }

  /// Get new clients progress for a user
  static Future<Map<String, dynamic>> getNewClientsProgress(
    int userId, {
    String period = 'current_month',
  }) async {
    try {
      print(
          '🔍 Getting new clients progress for user: $userId, period: $period');

      // Get user's new clients target
      const userSql = '''
        SELECT new_clients FROM SalesRep 
        WHERE id = ? AND status >= 0
      ''';

      final userResults = await _db.query(userSql, [userId]);
      if (userResults.isEmpty) {
        print('⚠️ No user found with ID: $userId');
        return {
          'newClientsTarget': 0,
          'newClientsAdded': 0,
          'remainingClients': 0,
          'progress': 0,
          'status': 'No Target Set',
        };
      }

      final newClientsTarget = userResults.first.fields['new_clients'] ?? 0;

      // Get new clients added based on period from Clients table
      String dateFilter;
      switch (period) {
        case 'current_month':
          dateFilter =
              'MONTH(created_at) = MONTH(CURDATE()) AND YEAR(created_at) = YEAR(CURDATE())';
          break;
        case 'last_month':
          dateFilter =
              'MONTH(created_at) = MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) AND YEAR(created_at) = YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))';
          break;
        case 'current_quarter':
          dateFilter =
              'QUARTER(created_at) = QUARTER(CURDATE()) AND YEAR(created_at) = YEAR(CURDATE())';
          break;
        default:
          dateFilter =
              'MONTH(created_at) = MONTH(CURDATE()) AND YEAR(created_at) = YEAR(CURDATE())';
      }

      // Using Clients table with created_at column and added_by field
      final newClientsSql = '''
        SELECT COUNT(*) as new_clients_count
        FROM Clients 
        WHERE countryId = (SELECT countryId FROM SalesRep WHERE id = ?)
        AND $dateFilter
        AND added_by = ?
      ''';

      final newClientsResults =
          await _db.query(newClientsSql, [userId, userId]);
      final newClientsAdded =
          newClientsResults.first.fields['new_clients_count'] ?? 0;

      final remainingClients = newClientsTarget - newClientsAdded;
      final progress = newClientsTarget > 0
          ? (newClientsAdded / newClientsTarget * 100).round()
          : 0;
      final status = newClientsAdded >= newClientsTarget
          ? 'Target Achieved'
          : 'In Progress';

      print(
          '✅ New clients progress: target=$newClientsTarget, added=$newClientsAdded, progress=$progress%');

      return {
        'newClientsTarget': newClientsTarget,
        'newClientsAdded': newClientsAdded,
        'remainingClients': remainingClients,
        'progress': progress,
        'status': status,
        'period': period,
      };
    } catch (e) {
      print('❌ Error getting new clients progress: $e');
      return {
        'newClientsTarget': 0,
        'newClientsAdded': 0,
        'remainingClients': 0,
        'progress': 0,
        'status': 'Error',
        'error': e.toString(),
      };
    }
  }

  /// Get product sales progress for a user
  static Future<Map<String, dynamic>> getProductSalesProgress(
    int userId, {
    String productType = 'all',
    String period = 'current_month',
  }) async {
    try {
      print(
          '🔍 Getting product sales progress for user: $userId, period: $period, type: $productType');

      // Get user's product targets with timeout handling
      const userSql = '''
        SELECT vapes_targets, pouches_targets FROM SalesRep 
        WHERE id = ? AND status >= 0
      ''';

      dynamic userResults;
      try {
        userResults = await _db.query(userSql, [userId]);
      } catch (e) {
        print('⚠️ Error getting user targets: $e, using defaults');
        userResults = [];
      }
      if (userResults.isEmpty) {
        print('⚠️ No user found with ID: $userId');
        return {
          'summary': {
            'vapes': {
              'target': 0,
              'sold': 0,
              'progress': 0,
              'status': 'No Target Set'
            },
            'pouches': {
              'target': 0,
              'sold': 0,
              'progress': 0,
              'status': 'No Target Set'
            },
            'totalOrders': 0,
            'totalQuantitySold': 0,
          },
          'productBreakdown': [],
        };
      }

      final vapesTarget = userResults.first.fields['vapes_targets'] ?? 0;
      final pouchesTarget = userResults.first.fields['pouches_targets'] ?? 0;

      // Get date filter based on period
      String dateFilter;
      switch (period) {
        case 'current_month':
          dateFilter =
              'MONTH(us.createdAt) = MONTH(CURDATE()) AND YEAR(us.createdAt) = YEAR(CURDATE())';
          break;
        case 'last_month':
          dateFilter =
              'MONTH(us.createdAt) = MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) AND YEAR(us.createdAt) = YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))';
          break;
        case 'current_quarter':
          dateFilter =
              'QUARTER(us.createdAt) = QUARTER(CURDATE()) AND YEAR(us.createdAt) = YEAR(CURDATE())';
          break;
        default:
          dateFilter =
              'MONTH(us.createdAt) = MONTH(CURDATE()) AND YEAR(us.createdAt) = YEAR(CURDATE())';
      }

      // Get product sales data with category filtering using UpliftSale tables
      String categoryFilter = '';
      if (productType == 'vapes') {
        categoryFilter = 'AND p.category LIKE "%vape%"';
      } else if (productType == 'pouches') {
        categoryFilter = 'AND p.category LIKE "%pouch%"';
      }

      // Simplified query to avoid timeouts
      final salesSql = '''
        SELECT 
          p.category,
          p.name as product_name,
          SUM(usi.quantity) as total_quantity,
          COUNT(DISTINCT us.id) as order_count
        FROM UpliftSale us
        INNER JOIN UpliftSaleItem usi ON us.id = usi.upliftSaleId
        INNER JOIN Product p ON usi.productId = p.id
        WHERE us.userId = ? 
        AND us.status = 'completed'
        AND $dateFilter
        $categoryFilter
        GROUP BY p.id, p.category, p.name
        ORDER BY total_quantity DESC
        LIMIT 50
      ''';

      dynamic salesResults;
      try {
        salesResults = await _db.query(salesSql, [userId]);
      } catch (e) {
        print('⚠️ Error getting sales data: $e, using empty results');
        salesResults = [];
      }

      int vapesSold = 0;
      int pouchesSold = 0;
      int totalOrders = 0;
      final List<Map<String, dynamic>> productBreakdown = [];

      for (final row in salesResults) {
        final category =
            (row.fields['category'] ?? '').toString().toLowerCase();
        final productName = row.fields['product_name'] ?? '';
        final quantity = row.fields['total_quantity'] ?? 0;
        final orderCount = (row.fields['order_count'] ?? 0) as int;

        totalOrders += orderCount;

        if (category.contains('vape')) {
          vapesSold += quantity as int;
        } else if (category.contains('pouch')) {
          pouchesSold += quantity as int;
        }

        productBreakdown.add({
          'productName': productName,
          'quantity': quantity,
          'isVape': category.contains('vape'),
          'category': category.contains('vape') ? 'Vapes' : 'Pouches',
          'productTypeDisplay': category.contains('vape') ? 'Vape' : 'Pouch',
          'categoryIcon': category.contains('vape') ? 'cloud' : 'inventory_2',
        });
      }

      final vapesProgress =
          vapesTarget > 0 ? (vapesSold / vapesTarget * 100).round() : 0;
      final pouchesProgress =
          pouchesTarget > 0 ? (pouchesSold / pouchesTarget * 100).round() : 0;

      final vapesStatus =
          vapesSold >= vapesTarget ? 'Target Achieved' : 'In Progress';
      final pouchesStatus =
          pouchesSold >= pouchesTarget ? 'Target Achieved' : 'In Progress';

      print(
          '✅ Product sales: vapes=$vapesSold/$vapesTarget, pouches=$pouchesSold/$pouchesTarget, orders=$totalOrders');

      return {
        'summary': {
          'vapes': {
            'target': vapesTarget,
            'sold': vapesSold,
            'progress': vapesProgress,
            'status': vapesStatus,
          },
          'pouches': {
            'target': pouchesTarget,
            'sold': pouchesSold,
            'progress': pouchesProgress,
            'status': pouchesStatus,
          },
          'totalOrders': totalOrders,
          'totalQuantitySold': vapesSold + pouchesSold,
        },
        'productBreakdown': productBreakdown,
        'period': period,
        'productType': productType,
      };
    } catch (e) {
      print('❌ Error getting product sales progress: $e');
      return {
        'summary': {
          'vapes': {'target': 0, 'sold': 0, 'progress': 0, 'status': 'Error'},
          'pouches': {'target': 0, 'sold': 0, 'progress': 0, 'status': 'Error'},
          'totalOrders': 0,
          'totalQuantitySold': 0,
        },
        'productBreakdown': [],
        'error': e.toString(),
      };
    }
  }

  /// Get dashboard data for a user
  static Future<Map<String, dynamic>> getDashboard(
    int userId, {
    String period = 'current_month',
  }) async {
    try {
      print('🔍 Getting dashboard data for user: $userId, period: $period');

      // Get all target data
      final visitTargets =
          await getDailyVisitTargets(userId: userId.toString());
      final newClients = await getNewClientsProgress(userId, period: period);
      final productSales =
          await getProductSalesProgress(userId, period: period);

      // Calculate overall performance score
      final visitProgress = visitTargets['progress'] ?? 0;
      final newClientsProgress = newClients['progress'] ?? 0;
      final vapesProgress = productSales['summary']?['vapes']?['progress'] ?? 0;
      final pouchesProgress =
          productSales['summary']?['pouches']?['progress'] ?? 0;

      final overallScore = ((visitProgress +
                  newClientsProgress +
                  vapesProgress +
                  pouchesProgress) /
              4)
          .round();
      final allTargetsAchieved = overallScore >= 100;

      print('✅ Dashboard calculated: overall score=$overallScore%');

      return {
        'overallPerformanceScore': overallScore,
        'allTargetsAchieved': allTargetsAchieved,
        'period': period,
        'visitTargets': visitTargets,
        'newClients': newClients,
        'productSales': productSales,
        'success': true,
      };
    } catch (e) {
      print('❌ Error getting dashboard: $e');
      return {
        'overallPerformanceScore': 0,
        'allTargetsAchieved': false,
        'period': period,
        'error': e.toString(),
        'success': false,
      };
    }
  }

  /// Get targets list
  static Future<List<Map<String, dynamic>>> getTargets({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('🔍 Getting targets list, page: $page, limit: $limit');

      // Get targets from SalesRep table
      const targetsSql = '''
        SELECT 
          id,
          name,
          visits_targets,
          new_clients,
          vapes_targets,
          pouches_targets,
          createdAt,
          updatedAt
        FROM SalesRep 
        WHERE status >= 0
        ORDER BY createdAt DESC
        LIMIT ? OFFSET ?
      ''';

      final offset = (page - 1) * limit;
      final targetsResults = await _db.query(targetsSql, [limit, offset]);

      final List<Map<String, dynamic>> targets = [];

      for (final row in targetsResults) {
        final userId = row.fields['id'];

        // Get actual progress for each target type
        final visitTargets =
            await getDailyVisitTargets(userId: userId.toString());
        final newClients = await getNewClientsProgress(userId);
        final productSales = await getProductSalesProgress(userId);

        targets.add({
          'id': userId,
          'title': '${row.fields['name']} - Daily Visits',
          'targetValue': row.fields['visits_targets'] ?? 0,
          'achievedValue': visitTargets['completedVisits'] ?? 0,
          'progress': visitTargets['progress']?.toDouble() ?? 0.0,
          'achieved': (visitTargets['progress'] ?? 0) >= 100,
          'isCurrent': true,
          'startDate': row.fields['createdAt']?.toString() ??
              DateTime.now().toIso8601String(),
          'endDate': DateTime.now().add(Duration(days: 30)).toIso8601String(),
        });

        targets.add({
          'id': userId + 1000, // Unique ID for new clients target
          'title': '${row.fields['name']} - New Clients',
          'targetValue': row.fields['new_clients'] ?? 0,
          'achievedValue': newClients['newClientsAdded'] ?? 0,
          'progress': newClients['progress']?.toDouble() ?? 0.0,
          'achieved': (newClients['progress'] ?? 0) >= 100,
          'isCurrent': true,
          'startDate': row.fields['createdAt']?.toString() ??
              DateTime.now().toIso8601String(),
          'endDate': DateTime.now().add(Duration(days: 30)).toIso8601String(),
        });

        targets.add({
          'id': userId + 2000, // Unique ID for vapes target
          'title': '${row.fields['name']} - Vapes Sales',
          'targetValue': row.fields['vapes_targets'] ?? 0,
          'achievedValue': productSales['summary']?['vapes']?['sold'] ?? 0,
          'progress':
              productSales['summary']?['vapes']?['progress']?.toDouble() ?? 0.0,
          'achieved':
              (productSales['summary']?['vapes']?['progress'] ?? 0) >= 100,
          'isCurrent': true,
          'startDate': row.fields['createdAt']?.toString() ??
              DateTime.now().toIso8601String(),
          'endDate': DateTime.now().add(Duration(days: 30)).toIso8601String(),
        });
      }

      print('✅ Targets list retrieved: ${targets.length} targets');
      return targets;
    } catch (e) {
      print('❌ Error getting targets: $e');
      return [];
    }
  }

  /// Clear any cached data (placeholder for future caching implementation)
  static void clearCache() {
    print('🧹 Clearing targets cache (no cache implemented yet)');
    // Future implementation: Clear any cached data
  }

  /// Get client details for new clients tracking
  static Future<Map<String, dynamic>> getClientDetails(
    int userId, {
    String period = 'current_month',
  }) async {
    try {
      print('🔍 Getting client details for user: $userId, period: $period');

      // Get date filter based on period
      String dateFilter;
      switch (period) {
        case 'current_month':
          dateFilter =
              'MONTH(createdAt) = MONTH(CURDATE()) AND YEAR(createdAt) = YEAR(CURDATE())';
          break;
        case 'last_month':
          dateFilter =
              'MONTH(createdAt) = MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) AND YEAR(createdAt) = YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))';
          break;
        case 'current_quarter':
          dateFilter =
              'QUARTER(createdAt) = QUARTER(CURDATE()) AND YEAR(createdAt) = YEAR(CURDATE())';
          break;
        default:
          dateFilter =
              'MONTH(createdAt) = MONTH(CURDATE()) AND YEAR(createdAt) = YEAR(CURDATE())';
      }

      // Get new clients data from Stores table instead of Clients
      final clientsSql = '''
        SELECT 
          id,
          name,
          countryId,
          status,
          createdAt
        FROM Stores 
        WHERE countryId = (SELECT countryId FROM SalesRep WHERE id = ?)
        AND $dateFilter
        AND status = 1
        ORDER BY createdAt DESC
      ''';

      final clientsResults = await _db.query(clientsSql, [userId]);

      final List<Map<String, dynamic>> newClients = [];

      for (final row in clientsResults) {
        newClients.add({
          'id': row.fields['id'],
          'name': row.fields['name'] ?? '',
          'contact': 'N/A', // Stores table doesn't have contact field
          'created_at': row.fields['createdAt']?.toString() ?? '',
          'status': row.fields['status'] ?? 1,
          'region': 'N/A', // Stores table doesn't have region field
        });
      }

      print('✅ Client details retrieved: ${newClients.length} new clients');

      return {
        'newClients': newClients,
        'totalNewClients': newClients.length,
        'period': period,
      };
    } catch (e) {
      print('❌ Error getting client details: $e');
      return {
        'newClients': [],
        'totalNewClients': 0,
        'error': e.toString(),
      };
    }
  }
}
