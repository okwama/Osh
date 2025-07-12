import 'dart:io';
import 'package:get/get.dart';
import 'package:woosh/services/core/payment_service.dart';
import 'package:woosh/models/client/client_payment_model.dart';
import 'package:woosh/utils/error_handler.dart';

class PaymentController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<ClientPayment> payments = <ClientPayment>[].obs;

  /// Get client payments
  Future<List<ClientPayment>> getClientPayments(int clientId) async {
    try {
      isLoading.value = true;
      final result = await PaymentService.getClientPayments(clientId);
      payments.value = result;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e, context: 'PaymentController.getClientPayments');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Upload client payment
  Future<ClientPayment?> uploadClientPayment({
    required int clientId,
    required double amount,
    required String method,
    File? imageFile,
    List<int>? imageBytes,
  }) async {
    try {
      isLoading.value = true;
      final result = await PaymentService.uploadClientPayment(
        clientId: clientId,
        amount: amount,
        method: method,
        imageFile: imageFile,
        imageBytes: imageBytes,
      );
      if (result != null) {
        // Refresh payments list
        await getClientPayments(clientId);
      }
      return result;
    } catch (e) {
      ErrorHandler.handleGeneralError(e, context: 'PaymentController.uploadClientPayment');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update payment status
  Future<ClientPayment?> updatePaymentStatus({
    required int paymentId,
    required String status,
  }) async {
    try {
      isLoading.value = true;
      final result = await PaymentService.updatePaymentStatus(
        paymentId: paymentId,
        status: status,
      );
      return result;
    } catch (e) {
      ErrorHandler.handleGeneralError(e, context: 'PaymentController.updatePaymentStatus');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get payment statistics for a client
  Future<Map<String, dynamic>> getClientPaymentStats(int clientId) async {
    try {
      isLoading.value = true;
      final result = await PaymentService.getClientPaymentStats(clientId);
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e, context: 'PaymentController.getClientPaymentStats');
      return {
        'total_payments': 0,
        'total_amount': 0.0,
        'verified_payments': 0,
        'pending_payments': 0,
        'rejected_payments': 0,
      };
    } finally {
      isLoading.value = false;
    }
  }
} 