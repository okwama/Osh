import 'package:get/get.dart';
import 'package:woosh/services/core/notice_service.dart';
import 'package:woosh/models/noticeboard_model.dart';
import 'package:woosh/utils/error_handler.dart';

class NoticeController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<NoticeBoard> notices = <NoticeBoard>[].obs;

  /// Get all notices
  Future<List<NoticeBoard>> getNotices() async {
    try {
      isLoading.value = true;
      final result = await NoticeService.getNotices();
      notices.value = result;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e, context: 'NoticeController.getNotices');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Get notice by ID
  Future<NoticeBoard?> getNoticeById(int noticeId) async {
    try {
      isLoading.value = true;
      final result = await NoticeService.getNoticeById(noticeId);
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e, context: 'NoticeController.getNoticeById');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Create notice
  Future<Map<String, dynamic>> createNotice({
    required String title,
    required String content,
    int? countryId,
  }) async {
    try {
      isLoading.value = true;
      final result = await NoticeService.createNotice(
        title: title,
        content: content,
        countryId: countryId,
      );
      if (result['success'] == true) {
        // Refresh notices list
        await getNotices();
      }
      return result;
    } catch (e) {
      ErrorHandler.handleGeneralError(e, context: 'NoticeController.createNotice');
      return {
        'success': false,
        'message': 'Failed to create notice',
      };
    } finally {
      isLoading.value = false;
    }
  }

  /// Update notice
  Future<bool> updateNotice({
    required int id,
    String? title,
    String? content,
    int? countryId,
  }) async {
    try {
      isLoading.value = true;
      final result = await NoticeService.updateNotice(
        id: id,
        title: title,
        content: content,
        countryId: countryId,
      );
      if (result) {
        // Refresh notices list
        await getNotices();
      }
      return result;
    } catch (e) {
      ErrorHandler.handleGeneralError(e, context: 'NoticeController.updateNotice');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete notice
  Future<bool> deleteNotice(int noticeId) async {
    try {
      isLoading.value = true;
      final result = await NoticeService.deleteNotice(noticeId);
      if (result) {
        // Refresh notices list
        await getNotices();
      }
      return result;
    } catch (e) {
      ErrorHandler.handleGeneralError(e, context: 'NoticeController.deleteNotice');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get recent notices count
  Future<int> getRecentNoticesCount(int days) async {
    try {
      isLoading.value = true;
      final result = await NoticeService.getRecentNoticesCount(days);
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e, context: 'NoticeController.getRecentNoticesCount');
      return 0;
    } finally {
      isLoading.value = false;
    }
  }
} 