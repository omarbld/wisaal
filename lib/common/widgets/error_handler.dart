import 'package:flutter/material.dart';

class ErrorHandler {
  static void showError(BuildContext context, String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: duration,
        action: action,
      ),
    );
  }

  static void showSuccess(BuildContext context, String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: duration,
        action: action,
      ),
    );
  }

  static void showWarning(BuildContext context, String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: duration,
        action: action,
      ),
    );
  }

  static void showInfo(BuildContext context, String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: duration,
        action: action,
      ),
    );
  }

  static void showNetworkError(BuildContext context, {
    VoidCallback? onRetry,
  }) {
    showError(
      context,
      'تعذر الاتصال بالإنترنت. تحقق من اتصالك وحاول مرة أخرى.',
      action: onRetry != null
          ? SnackBarAction(
              label: 'إعادة المحاولة',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
    );
  }

  static void showServerError(BuildContext context, {
    VoidCallback? onRetry,
  }) {
    showError(
      context,
      'حدث خطأ في الخادم. يرجى المحاولة مرة أخرى لاحقاً.',
      action: onRetry != null
          ? SnackBarAction(
              label: 'إعادة المحاولة',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
    );
  }

  static String getErrorMessage(dynamic error) {
    if (error == null) return 'حدث خطأ غير معروف';
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'تعذر الاتصال بالإنترنت';
    } else if (errorString.contains('timeout')) {
      return 'انتهت مهلة الاتصال';
    } else if (errorString.contains('permission')) {
      return 'ليس لديك صلاحية للقيام بهذا الإجراء';
    } else if (errorString.contains('not found')) {
      return 'العنصر المطلوب غير موجود';
    } else if (errorString.contains('invalid')) {
      return 'البيانات المدخلة غير صحيحة';
    } else {
      return 'حدث خطأ: ${error.toString()}';
    }
  }
}