import 'package:woosh/services/core/session_service.dart';
import 'package:woosh/services/core/target_service.dart';

class UserStatsController {
  Future<dynamic> getCurrentSession(int userId) async {
    return await SessionService.getCurrentSession(userId);
  }

  Future<Map<String, dynamic>> getDailyVisitTargets(
      {required String userId}) async {
    return await TargetService.getDailyVisitTargets(userId: userId);
  }

  Future<Map<String, dynamic>> getSessionHistory(String userId, {required String startDate, required String endDate}) async {
    return await SessionService.getSessionHistory(userId, startDate: startDate, endDate: endDate);
  }
}
