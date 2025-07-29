// Custom exceptions for the Wisaal app

abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

// Authentication Exceptions
class AppAuthException extends AppException {
  const AppAuthException(super.message, {super.code, super.originalError});
}

class InvalidCredentialsException extends AppAuthException {
  const InvalidCredentialsException() : super('بيانات الدخول غير صحيحة');
}

class UserNotFoundException extends AppAuthException {
  const UserNotFoundException() : super('المستخدم غير موجود');
}

class EmailAlreadyExistsException extends AppAuthException {
  const EmailAlreadyExistsException() : super('البريد الإلكتروني مستخدم بالفعل');
}

class InvalidOTPException extends AppAuthException {
  const InvalidOTPException() : super('رمز التحقق غير صحيح أو منتهي الصلاحية');
}

class SessionExpiredException extends AppAuthException {
  const SessionExpiredException() : super('انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى');
}

// Network Exceptions
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});
}

class NoInternetException extends NetworkException {
  const NoInternetException() : super('لا يوجد اتصال بالإنترنت');
}

class ServerException extends NetworkException {
  const ServerException() : super('خطأ في الخادم، يرجى المحاولة لاحقاً');
}

class TimeoutException extends NetworkException {
  const TimeoutException() : super('انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى');
}

// Validation Exceptions
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.originalError});
}

class InvalidEmailException extends ValidationException {
  const InvalidEmailException() : super('البريد الإلكتروني غير صالح');
}

class InvalidPhoneException extends ValidationException {
  const InvalidPhoneException() : super('رقم الهاتف غير صالح');
}

class RequiredFieldException extends ValidationException {
  const RequiredFieldException(String fieldName) : super('$fieldName مطلوب');
}

class InvalidLengthException extends ValidationException {
  const InvalidLengthException(String fieldName, int minLength, int maxLength) 
    : super('$fieldName يجب أن يكون بين $minLength و $maxLength حرف');
}

// Permission Exceptions
class PermissionException extends AppException {
  const PermissionException(super.message, {super.code, super.originalError});
}

class LocationPermissionException extends PermissionException {
  const LocationPermissionException() : super('يرجى السماح بالوصول للموقع');
}

class CameraPermissionException extends PermissionException {
  const CameraPermissionException() : super('يرجى السماح بالوصول للكاميرا');
}

class StoragePermissionException extends PermissionException {
  const StoragePermissionException() : super('يرجى السماح بالوصول للتخزين');
}

// Business Logic Exceptions
class BusinessLogicException extends AppException {
  const BusinessLogicException(super.message, {super.code, super.originalError});
}

class DonationNotFoundException extends BusinessLogicException {
  const DonationNotFoundException() : super('التبرع غير موجود');
}

class DonationAlreadyAcceptedException extends BusinessLogicException {
  const DonationAlreadyAcceptedException() : super('تم قبول هذا التبرع بالفعل');
}

class InvalidActivationCodeException extends BusinessLogicException {
  const InvalidActivationCodeException() : super('كود التفعيل غير صحيح أو مستخدم بالفعل');
}

class VolunteerNotAvailableException extends BusinessLogicException {
  const VolunteerNotAvailableException() : super('المتطوع غير متاح حالياً');
}

class DonationExpiredException extends BusinessLogicException {
  const DonationExpiredException() : super('انتهت صلاحية هذا التبرع');
}

class InsufficientPermissionsException extends BusinessLogicException {
  const InsufficientPermissionsException() : super('ليس لديك صلاحية للقيام بهذا الإجراء');
}

// File Exceptions
class FileException extends AppException {
  const FileException(super.message, {super.code, super.originalError});
}

class FileSizeExceededException extends FileException {
  const FileSizeExceededException(int maxSizeMB) : super('حجم الملف كبير جداً. الحد الأقصى $maxSizeMB ميجابايت');
}

class UnsupportedFileTypeException extends FileException {
  const UnsupportedFileTypeException() : super('نوع الملف غير مدعوم');
}

class FileUploadException extends FileException {
  const FileUploadException() : super('فشل في رفع الملف');
}

// Location Exceptions
class LocationException extends AppException {
  const LocationException(super.message, {super.code, super.originalError});
}

class LocationServiceDisabledException extends LocationException {
  const LocationServiceDisabledException() : super('خدمة الموقع غير مفعلة');
}

class LocationNotFoundException extends LocationException {
  const LocationNotFoundException() : super('لا يمكن تحديد الموقع الحالي');
}

// QR Code Exceptions
class QRCodeException extends AppException {
  const QRCodeException(super.message, {super.code, super.originalError});
}

class InvalidQRCodeException extends QRCodeException {
  const InvalidQRCodeException() : super('رمز QR غير صالح');
}

class QRCodeScanException extends QRCodeException {
  const QRCodeScanException() : super('فشل في مسح رمز QR');
}

// Database Exceptions
class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.originalError});
}

class DataNotFoundException extends DatabaseException {
  const DataNotFoundException() : super('البيانات غير موجودة');
}

class DataInsertException extends DatabaseException {
  const DataInsertException() : super('فشل في حفظ البيانات');
}

class DataUpdateException extends DatabaseException {
  const DataUpdateException() : super('فشل في تحديث البيانات');
}

class DataDeleteException extends DatabaseException {
  const DataDeleteException() : super('فشل في حذف البيانات');
}

// Cache Exceptions
class CacheException extends AppException {
  const CacheException(super.message, {super.code, super.originalError});
}

class CacheNotFoundException extends CacheException {
  const CacheNotFoundException() : super('البيانات غير متوفرة في التخزين المؤقت');
}

class CacheExpiredException extends CacheException {
  const CacheExpiredException() : super('انتهت صلاحية البيانات المحفوظة');
}

// Unknown Exception
class UnknownException extends AppException {
  const UnknownException([String? message]) : super(message ?? 'حدث خطأ غير متوقع');
}