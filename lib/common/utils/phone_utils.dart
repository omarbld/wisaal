import 'package:url_launcher/url_launcher.dart';

class PhoneUtils {
  /// فتح تطبيق الهاتف للاتصال برقم معين
  static Future<bool> makePhoneCall(String phoneNumber) async {
    // تنظيف رقم الهاتف من المسافات والرموز غير المرغوب فيها
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanNumber,
    );
    
    try {
      if (await canLaunchUrl(launchUri)) {
        return await launchUrl(launchUri);
      } else {
        throw 'Could not launch phone app for $cleanNumber';
      }
    } catch (e) {
      throw 'Error launching phone app: $e';
    }
  }

  /// إرسال رسالة SMS
  static Future<bool> sendSMS(String phoneNumber, {String? message}) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    final Uri launchUri = Uri(
      scheme: 'sms',
      path: cleanNumber,
      queryParameters: message != null ? {'body': message} : null,
    );
    
    try {
      if (await canLaunchUrl(launchUri)) {
        return await launchUrl(launchUri);
      } else {
        throw 'Could not launch SMS app for $cleanNumber';
      }
    } catch (e) {
      throw 'Error launching SMS app: $e';
    }
  }

  /// فتح WhatsApp للمحادثة مع رقم معين
  static Future<bool> openWhatsApp(String phoneNumber, {String? message}) async {
    // إزالة الصفر الأول إذا كان موجوداً وإضافة رمز المغرب
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '212${cleanNumber.substring(1)}';
    } else if (!cleanNumber.startsWith('212')) {
      cleanNumber = '212$cleanNumber';
    }
    
    final Uri launchUri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: '/$cleanNumber',
      queryParameters: message != null ? {'text': message} : null,
    );
    
    try {
      if (await canLaunchUrl(launchUri)) {
        return await launchUrl(
          launchUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch WhatsApp for $cleanNumber';
      }
    } catch (e) {
      throw 'Error launching WhatsApp: $e';
    }
  }

  /// التحقق من صحة رقم الهاتف المغربي
  static bool isValidMoroccanPhone(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // أرقام الهاتف المغربية تبدأ بـ 0 وتتكون من 10 أرقام
    // أو تبدأ بـ +212 أو 212
    if (cleanNumber.length == 10 && cleanNumber.startsWith('0')) {
      return RegExp(r'^0[5-7]\d{8}$').hasMatch(cleanNumber);
    } else if (cleanNumber.length == 12 && cleanNumber.startsWith('212')) {
      return RegExp(r'^212[5-7]\d{8}$').hasMatch(cleanNumber);
    }
    
    return false;
  }

  /// تنسيق رقم الهاتف للعرض
  static String formatPhoneNumber(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleanNumber.startsWith('+212')) {
      // +212 6 12 34 56 78
      if (cleanNumber.length == 13) {
        return '+212 ${cleanNumber.substring(3, 4)} ${cleanNumber.substring(4, 6)} ${cleanNumber.substring(6, 8)} ${cleanNumber.substring(8, 10)} ${cleanNumber.substring(10)}';
      }
    } else if (cleanNumber.startsWith('212')) {
      // 212 6 12 34 56 78
      if (cleanNumber.length == 12) {
        return '212 ${cleanNumber.substring(3, 4)} ${cleanNumber.substring(4, 6)} ${cleanNumber.substring(6, 8)} ${cleanNumber.substring(8, 10)} ${cleanNumber.substring(10)}';
      }
    } else if (cleanNumber.startsWith('0')) {
      // 06 12 34 56 78
      if (cleanNumber.length == 10) {
        return '${cleanNumber.substring(0, 2)} ${cleanNumber.substring(2, 4)} ${cleanNumber.substring(4, 6)} ${cleanNumber.substring(6, 8)} ${cleanNumber.substring(8)}';
      }
    }
    
    return phoneNumber; // إرجاع الرقم كما هو إذا لم يتطابق مع أي تنسيق
  }

  /// الحصول على نوع الشبكة من رقم الهاتف المغربي
  static String? getNetworkProvider(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    String number = cleanNumber;
    
    if (number.startsWith('212')) {
      number = '0${number.substring(3)}';
    }
    
    if (number.length == 10 && number.startsWith('0')) {
      final prefix = number.substring(0, 3);
      switch (prefix) {
        case '061':
        case '062':
        case '063':
        case '064':
        case '065':
        case '066':
        case '067':
          return 'Maroc Telecom';
        case '060':
        case '068':
        case '069':
          return 'Orange';
        case '070':
        case '071':
        case '072':
        case '073':
        case '074':
        case '075':
        case '076':
        case '077':
        case '078':
        case '079':
          return 'Inwi';
        default:
          return null;
      }
    }
    
    return null;
  }
}