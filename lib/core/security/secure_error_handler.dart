import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// معالج آمن للأخطاء يمنع تسريب المعلومات الحساسة
class SecureErrorHandler {
  
  /// معالجة الأخطاء وإرجاع رسائل آمنة للمستخدم
  static String getSafeErrorMessage(dynamic error) {
    if (kDebugMode) {
      // في بيئة التطوير، اطبع الخطأ الكامل للمطورين
      print('🐛 Debug Error: $error');
    }
    
    // تحليل نوع الخطأ وإرجاع رسالة آمنة
    if (error is AuthException) {
      return _handleAuthError(error);
    } else if (error is PostgrestException) {
      return _handleDatabaseError(error);
    } else if (error is StorageException) {
      return _handleStorageError(error);
    } else if (error is Exception) {
      return _handleGenericError(error);
    } else {
      return 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى';
    }
  }
  
  /// معالجة أخطاء المصادقة
  static String _handleAuthError(AuthException error) {
    switch (error.statusCode) {
      case '400':
        if (error.message.contains('Invalid login credentials')) {
          return 'بيانات تسجيل الدخول غير صحيحة';
        } else if (error.message.contains('Email not confirmed')) {
          return 'يرجى تأكيد بريدك الإلكتروني أولاً';
        } else if (error.message.contains('Invalid email')) {
          return 'البريد الإلكتروني غير صالح';
        }
        return 'خطأ في البيانات المدخلة';
      
      case '401':
        return 'انتهت صلاحية جلستك، يرجى تسجيل الدخول مرة أخرى';
      
      case '403':
        return 'ليس لديك صلاحية للوصول لهذه الخدمة';
      
      case '422':
        if (error.message.contains('Email rate limit exceeded')) {
          return 'تم تجاوز الحد المسموح لإرسال الرسائل، يرجى المحاولة لاحقاً';
        }
        return 'خطأ في معالجة البيانات';
      
      case '429':
        return 'تم تجاوز الحد المسموح للطلبات، يرجى المحاولة لاحقاً';
      
      default:
        return 'خطأ في المصادقة، يرجى المحاولة مرة أخرى';
    }
  }
  
  /// معالجة أخطاء قاعدة البيانات
  static String _handleDatabaseError(PostgrestException error) {
    final message = error.message.toLowerCase();
    
    if (message.contains('permission denied') || 
        message.contains('row level security') ||
        message.contains('policy')) {
      return 'ليس لديك صلاحية للوصول لهذه البيانات';
    } else if (message.contains('duplicate key') || 
               message.contains('unique constraint')) {
      return 'هذه البيانات موجودة مسبقاً';
    } else if (message.contains('foreign key') || 
               message.contains('violates')) {
      return 'لا يمكن تنفيذ هذا الإجراء بسبب ارتباط البيانات';
    } else if (message.contains('not found')) {
      return 'البيانات المطلوبة غير موجودة';
    } else if (message.contains('connection') || 
               message.contains('timeout')) {
      return 'مشكلة في الاتصال، يرجى التحقق من الإنترنت';
    } else {
      return 'خطأ في معالجة البيانات، يرجى المحاولة مرة أخرى';
    }
  }
  
  /// معالجة أخطاء التخزين
  static String _handleStorageError(StorageException error) {
    final message = error.message.toLowerCase();
    
    if (message.contains('file too large') || 
        message.contains('size')) {
      return 'حجم الملف كبير جداً';
    } else if (message.contains('invalid file type') || 
               message.contains('format')) {
      return 'نوع الملف غير مدعوم';
    } else if (message.contains('permission') || 
               message.contains('access')) {
      return 'ليس لديك صلاحية لرفع الملفات';
    } else {
      return 'خطأ في رفع الملف، يرجى المحاولة مرة أخرى';
    }
  }
  
  /// معالجة الأخطاء العامة
  static String _handleGenericError(Exception error) {
    final message = error.toString().toLowerCase();
    
    if (message.contains('network') || 
        message.contains('connection') ||
        message.contains('internet')) {
      return 'مشكلة في الاتصال، يرجى التحقق من الإنترنت';
    } else if (message.contains('timeout')) {
      return 'انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى';
    } else if (message.contains('format') || 
               message.contains('parse')) {
      return 'خطأ في تنسيق البيانات';
    } else {
      return 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى';
    }
  }
  
  /// تسجيل الأخطاء الأمنية (للمراقبة)
  static void logSecurityEvent(String event, Map<String, dynamic>? details) {
    if (kDebugMode) {
      print('🔒 Security Event: $event');
      if (details != null) {
        print('📋 Details: $details');
      }
    }
    
    // في الإنتاج، يمكن إرسال هذه الأحداث لخدمة مراقبة مثل Sentry
    // Sentry.captureMessage('Security Event: $event', level: SentryLevel.warning);
  }
  
  /// التحقق من صحة المدخلات
  static bool isValidInput(String input, {int maxLength = 1000}) {
    if (input.isEmpty || input.length > maxLength) {
      return false;
    }
    
    // منع الأكواد الضارة
    final dangerousPatterns = [
      '<script',
      'javascript:',
      'onload=',
      'onerror=',
      'eval(',
      'document.cookie',
      'localStorage',
      'sessionStorage',
    ];
    
    final lowerInput = input.toLowerCase();
    for (final pattern in dangerousPatterns) {
      if (lowerInput.contains(pattern)) {
        logSecurityEvent('Dangerous input detected', {'input': input});
        return false;
      }
    }
    
    return true;
  }
  
  /// تنظيف المدخلات من الأكواد الضارة
  static String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // إزالة HTML tags
        .replaceAll(RegExp(r'[<>"\']'), '') // إزالة أحرف خطيرة
        .trim();
  }
  
  /// التحقق من صحة البريد الإلكتروني
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    return emailRegex.hasMatch(email) && email.length <= 254;
  }
  
  /// التحقق من صحة رقم الهاتف
  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[\s\-\(\)]'), ''));
  }
}

/// استثناءات مخصصة للأمان
class SecurityException implements Exception {
  final String message;
  final String? code;
  
  const SecurityException(this.message, {this.code});
  
  @override
  String toString() => 'SecurityException: $message';
}

class InsufficientPermissionsException extends SecurityException {
  const InsufficientPermissionsException() 
      : super('ليس لديك صلاحية للوصول لهذه البيانات', code: 'INSUFFICIENT_PERMISSIONS');
}

class InvalidInputException extends SecurityException {
  const InvalidInputException(String message) 
      : super(message, code: 'INVALID_INPUT');
}

class RateLimitExceededException extends SecurityException {
  const RateLimitExceededException() 
      : super('تم تجاوز الحد المسموح للطلبات', code: 'RATE_LIMIT_EXCEEDED');
}