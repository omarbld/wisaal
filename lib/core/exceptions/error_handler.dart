import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'app_exceptions.dart';

class ErrorHandler {
  static AppException handleError(dynamic error) {
    if (error is AppException) {
      return error;
    }

    if (error is supabase.AuthException) {
      return _handleAuthError(error);
    }

    if (error is supabase.PostgrestException) {
      return _handlePostgrestError(error);
    }

    if (error is supabase.StorageException) {
      return _handleStorageError(error);
    }

    // Handle other common errors
    final errorMessage = error.toString().toLowerCase();

    if (errorMessage.contains('network') ||
        errorMessage.contains('connection') ||
        errorMessage.contains('internet')) {
      return const NoInternetException();
    }

    if (errorMessage.contains('timeout')) {
      return const TimeoutException();
    }

    if (errorMessage.contains('permission')) {
      return PermissionException(error.toString());
    }

    return UnknownException(error.toString());
  }

  static AppException _handleAuthError(supabase.AuthException error) {
    switch (error.message) {
      case 'Invalid login credentials':
        return const InvalidCredentialsException();
      case 'User not found':
        return const UserNotFoundException();
      case 'Email already registered':
        return const EmailAlreadyExistsException();
      case 'Invalid OTP':
      case 'Token has expired or is invalid':
        return const InvalidOTPException();
      case 'JWT expired':
        return const SessionExpiredException();
      default:
        return UnknownException(error.message);
    }
  }

  static AppException _handlePostgrestError(supabase.PostgrestException error) {
    final message = error.message.toLowerCase();
    final code = error.code;

    if (code == '23505') {
      // Unique violation
      return const EmailAlreadyExistsException();
    }

    if (code == '23503') {
      // Foreign key violation
      return const BusinessLogicException('البيانات المرجعية غير موجودة');
    }

    if (code == '42501') {
      // Insufficient privilege
      return const InsufficientPermissionsException();
    }

    if (message.contains('row level security')) {
      return const InsufficientPermissionsException();
    }

    if (message.contains('not found')) {
      return const DataNotFoundException();
    }

    return DatabaseException(error.message, code: code);
  }

  static AppException _handleStorageError(supabase.StorageException error) {
    final message = error.message.toLowerCase();

    if (message.contains('file size')) {
      return const FileSizeExceededException(5);
    }

    if (message.contains('file type') || message.contains('invalid')) {
      return const UnsupportedFileTypeException();
    }

    if (message.contains('upload')) {
      return const FileUploadException();
    }

    return FileException(error.message);
  }

  static void showErrorSnackBar(BuildContext context, AppException error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'إغلاق',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showErrorDialog(BuildContext context, AppException error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خطأ'),
        content: Text(error.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  static Widget buildErrorWidget(AppException error, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getErrorIcon(error),
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            const Text(
              'حدث خطأ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static IconData _getErrorIcon(AppException error) {
    if (error is NetworkException) {
      return Icons.wifi_off;
    } else if (error is InvalidCredentialsException ||
        error is SessionExpiredException) {
      return Icons.lock_outline;
    } else if (error is PermissionException) {
      return Icons.security;
    } else if (error is ValidationException) {
      return Icons.warning_outlined;
    } else if (error is FileException) {
      return Icons.file_present_outlined;
    } else if (error is LocationException) {
      return Icons.location_off;
    } else if (error is QRCodeException) {
      return Icons.qr_code_scanner;
    } else {
      return Icons.error_outline;
    }
  }

  static void logError(AppException error, {StackTrace? stackTrace}) {
    debugPrint('Error: ${error.message}');
    debugPrint('Code: ${error.code}');
    debugPrint('Original Error: ${error.originalError}');
    if (stackTrace != null) {
      debugPrint('Stack Trace: $stackTrace');
    }
  }

  static bool isRecoverableError(AppException error) {
    return error is NetworkException ||
        error is TimeoutException ||
        error is ServerException;
  }

  static String getUserFriendlyMessage(AppException error) {
    if (error is NoInternetException) {
      return 'تحقق من اتصالك بالإنترنت وحاول مرة أخرى';
    } else if (error is ServerException) {
      return 'الخادم غير متاح حالياً، يرجى المحاولة لاحقاً';
    } else if (error is TimeoutException) {
      return 'الطلب يستغرق وقتاً أطول من المعتاد، يرجى المحاولة مرة أخرى';
    } else if (error is SessionExpiredException) {
      return 'انتهت صلاحية جلستك، يرجى تسجيل الدخول مرة أخرى';
    } else {
      return error.message;
    }
  }
}
