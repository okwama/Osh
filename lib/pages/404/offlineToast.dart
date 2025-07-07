import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OfflineToast extends StatelessWidget {
  final String message;
  final Duration duration;
  final VoidCallback? onTap;

  const OfflineToast({
    super.key,
    this.message = "You're offline",
    this.duration = const Duration(seconds: 3),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: Theme.of(context).colorScheme.onErrorContainer,
              size: 20,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Static method to show the toast
  static void show({
    String message = "You're offline",
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    Get.showSnackbar(
      GetSnackBar(
        messageText: OfflineToast(
          message: message,
          onTap: onTap,
        ),
        backgroundColor: Colors.transparent,
        duration: duration,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
        padding: EdgeInsets.zero,
        snackPosition: SnackPosition.TOP,
        animationDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

// Alternative implementation using Get.rawSnackbar for more control
class OfflineToastService {
  static void showOfflineToast({
    String message = "You're offline",
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onRetry,
  }) {
    Get.rawSnackbar(
      messageText: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: Get.theme.colorScheme.onErrorContainer,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: Get.theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  Get.back();
                  onRetry();
                },
                child: Icon(
                  Icons.refresh_rounded,
                  color: Get.theme.colorScheme.onErrorContainer,
                  size: 18,
                ),
              ),
            ],
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      duration: duration,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      snackPosition: SnackPosition.TOP,
      animationDuration: const Duration(milliseconds: 300),
    );
  }
}
