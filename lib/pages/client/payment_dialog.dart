import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:woosh/controllers/paymentcontroller/payment_controller.dart';

/// Dialog for adding client payments
class PaymentDialog {
  static Future<void> showAddPaymentDialog(
    BuildContext context,
    int clientId,
    Function() onPaymentAdded,
  ) async {
    final amountController = TextEditingController();
    String? selectedMethod;
    XFile? pickedFile;
    bool uploading = false;
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Client Payment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedMethod,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Cash',
                        child: Text('Cash'),
                      ),
                      DropdownMenuItem(
                        value: 'Cheque',
                        child: Text('Cheque'),
                      ),
                      DropdownMenuItem(
                        value: 'Mpesa',
                        child: Text('Mpesa'),
                      ),
                      DropdownMenuItem(
                        value: 'Bank',
                        child: Text('Bank'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedMethod = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: uploading
                            ? null
                            : () async {
                                try {
                                  final picker = ImagePicker();
                                  final file = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    maxWidth: 1024,
                                    maxHeight: 1024,
                                    imageQuality: 85,
                                  );
                                  if (file != null) {
                                    setState(() => pickedFile = file);
                                  }
                                } catch (e) {
                                  setState(() {
                                    errorMessage =
                                        'Failed to select image. Please try again.';
                                  });
                                }
                              },
                        icon: const Icon(Icons.image),
                        label: const Text('Select Image'),
                      ),
                      const SizedBox(width: 8),
                      if (pickedFile != null)
                        const Text('Selected',
                            style: TextStyle(color: Colors.green)),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: uploading ? null : () => Get.back(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: uploading
                      ? null
                      : () async {
                          final amount = double.tryParse(amountController.text);
                          if (amount == null) {
                            setState(() {
                              errorMessage = 'Please enter a valid amount.';
                            });
                            return;
                          }

                          if (selectedMethod == null) {
                            setState(() {
                              errorMessage = 'Please select a payment method.';
                            });
                            return;
                          }

                          setState(() {
                            uploading = true;
                            errorMessage = null;
                          });

                          try {
                            final paymentController =
                                Get.find<PaymentController>();
                            await paymentController.uploadClientPayment(
                              clientId: clientId,
                              amount: amount,
                              method: selectedMethod!,
                            );

                            Get.back();
                            onPaymentAdded();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Payment uploaded successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            // Handle server errors silently
                            if (e.toString().contains('500') ||
                                e.toString().contains('501') ||
                                e.toString().contains('502') ||
                                e.toString().contains('503')) {
                              print(
                                  'Server error during payment upload - handled silently: $e');
                              // Close dialog silently for server errors
                              Get.back();
                            } else {
                              setState(() {
                                errorMessage =
                                    'Failed to upload payment. Please try again.';
                                uploading = false;
                              });
                            }
                          }
                        },
                  child: uploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
