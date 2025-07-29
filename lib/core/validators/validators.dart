import '../constants.dart';
import '../exceptions/app_exceptions.dart';

class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'البريد الإلكتروني غير صالح';
    }
    
    return null;
  }
  
  // Phone validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'رقم الهاتف مطلوب';
    }
    
    // Remove any non-digit characters
    final cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanPhone.length != 10) {
      return 'رقم الهاتف يجب أن يتكون من 10 أرقام';
    }
    
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
      return 'رقم الهاتف يجب أن ي��توي على أرقام فقط';
    }
    
    return null;
  }
  
  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'الاسم مطلوب';
    }
    
    if (value.trim().length < 2) {
      return 'الاسم يجب أن يكون حرفين على الأقل';
    }
    
    if (value.trim().length > 50) {
      return 'الاسم طويل جداً';
    }
    
    // Check for valid characters (Arabic, English, spaces)
    if (!RegExp(r'^[\u0600-\u06FFa-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'الاسم يجب أن يحتوي على حروف فقط';
    }
    
    return null;
  }
  
  // OTP validation
  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'رمز التحقق مطلوب';
    }
    
    if (value.length != AppConstants.otpLength) {
      return 'رمز التحقق يجب أن يتكون من ${AppConstants.otpLength} أرقام';
    }
    
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'رمز التحقق يجب أن يحتوي على أرقام فقط';
    }
    
    return null;
  }
  
  // Title validation
  static String? validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'العنوان مطلوب';
    }
    
    if (value.trim().length < 3) {
      return 'العنوان قصير جداً';
    }
    
    if (value.trim().length > AppConstants.maxTitleLength) {
      return 'العنوان طويل جداً (الحد الأقصى ${AppConstants.maxTitleLength} حرف)';
    }
    
    return null;
  }
  
  // Description validation
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'الوصف مطلوب';
    }
    
    if (value.trim().length < 10) {
      return 'الوصف قصير جداً (10 أحرف على الأقل)';
    }
    
    if (value.trim().length > AppConstants.maxDescriptionLength) {
      return 'الوصف طويل جداً (الحد الأقصى ${AppConstants.maxDescriptionLength} حرف)';
    }
    
    return null;
  }
  
  // Quantity validation
  static String? validateQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'الكمية مطلوبة';
    }
    
    final quantity = int.tryParse(value);
    if (quantity == null) {
      return 'الكمية يجب أن تكون رقماً';
    }
    
    if (quantity <= 0) {
      return 'الكمية يجب أن تكون أكبر من صفر';
    }
    
    if (quantity > 1000) {
      return 'الكمية كبيرة جداً';
    }
    
    return null;
  }
  
  // Address validation
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'العنوان مطلوب';
    }
    
    if (value.trim().length < 10) {
      return 'العنوان قصير جداً';
    }
    
    if (value.trim().length > 200) {
      return 'العنوان طويل جداً';
    }
    
    return null;
  }
  
  // City validation
  static String? validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'المدينة مطلوبة';
    }
    
    if (!AppConstants.cities.contains(value)) {
      return 'المدينة غير مدعومة';
    }
    
    return null;
  }
  
  // Food type validation
  static String? validateFoodType(String? value) {
    if (value == null || value.isEmpty) {
      return 'نوع الطعام مطلوب';
    }
    
    if (!AppConstants.foodTypes.contains(value)) {
      return 'نوع الطعام غير صالح';
    }
    
    return null;
  }
  
  // Expiry date validation
  static String? validateExpiryDate(DateTime? value) {
    if (value == null) {
      return 'تاريخ انتهاء الصلاحية مطلوب';
    }
    
    final now = DateTime.now();
    if (value.isBefore(now)) {
      return 'تاريخ انتهاء الصلاحية لا يمكن أن يكون في الماضي';
    }
    
    // Check if expiry date is too far in the future (more than 1 year)
    final oneYearFromNow = now.add(const Duration(days: 365));
    if (value.isAfter(oneYearFromNow)) {
      return 'تاريخ انتهاء الصلاحية بعيد جداً';
    }
    
    return null;
  }
  
  // Rating validation
  static String? validateRating(int? value) {
    if (value == null) {
      return 'التقييم مطلوب';
    }
    
    if (value < 1 || value > 5) {
      return 'التقييم يجب أن يكون بين 1 و 5';
    }
    
    return null;
  }
  
  // Comment validation
  static String? validateComment(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Comment is optional
    }
    
    if (value.trim().length < 5) {
      return 'التعليق قصير جداً';
    }
    
    if (value.trim().length > 500) {
      return 'التعليق طويل جداً';
    }
    
    return null;
  }
  
  // Activation code validation
  static String? validateActivationCode(String? value, String userRole) {
    if (value == null || value.isEmpty) {
      return 'كود التفعيل مطلوب';
    }
    
    if (userRole == 'manager' && value != AppConstants.managerActivationCode) {
      return 'كود تفعيل المدير غير صح��ح';
    }
    
    if (userRole == 'association' && value != AppConstants.associationActivationCode) {
      return 'كود تفعيل الجمعية غير صحيح';
    }
    
    if (userRole == 'volunteer') {
      // For volunteers, we'll validate against the database
      if (value.length != 8) {
        return 'كود التفعيل يجب أن يتكون من 8 أحرف';
      }
    }
    
    return null;
  }
  
  // Password validation (if needed for future features)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    
    if (value.length > 50) {
      return 'كلمة المرور طويلة جداً';
    }
    
    return null;
  }
  
  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'تأكيد كلمة المرور مطلوب';
    }
    
    if (value != password) {
      return 'كلمة المرور غير متطابقة';
    }
    
    return null;
  }
  
  // Generic required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName مطلوب';
    }
    return null;
  }
  
  // Generic length validation
  static String? validateLength(String? value, String fieldName, int minLength, int maxLength) {
    if (value == null || value.isEmpty) {
      return '$fieldName مطلوب';
    }
    
    if (value.length < minLength) {
      return '$fieldName قصير جداً (الحد الأدنى $minLength أحرف)';
    }
    
    if (value.length > maxLength) {
      return '$fieldName طويل جداً (الحد الأقصى $maxLength حرف)';
    }
    
    return null;
  }
  
  // Validate multiple fields at once
  static List<String> validateMultiple(Map<String, String?> fields, Map<String, String? Function(String?)> validators) {
    final errors = <String>[];
    
    for (final entry in fields.entries) {
      final fieldName = entry.key;
      final value = entry.value;
      final validator = validators[fieldName];
      
      if (validator != null) {
        final error = validator(value);
        if (error != null) {
          errors.add(error);
        }
      }
    }
    
    return errors;
  }
  
  // Validate form and throw exception if invalid
  static void validateAndThrow(Map<String, String?> fields, Map<String, String? Function(String?)> validators) {
    final errors = validateMultiple(fields, validators);
    if (errors.isNotEmpty) {
      throw ValidationException(errors.first);
    }
  }
}