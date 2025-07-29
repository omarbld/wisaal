// Core constants for the Wisaal app
class AppConstants {
  // App Information
  static const String appName = 'وصال';
  static const String appSlogan = 'نصل الخير، ونحفظ النعمة';
  static const String appVersion = '1.0.0';
  
  // Cities in Laâyoune-Sakia El Hamra region
  static const List<String> cities = [
    'العيون',
    'طرفاية', 
    'بوجدور',
    'السمارة'
  ];
  
  // Food types
  static const List<String> foodTypes = [
    'خضروات',
    'فواكه',
    'لحوم',
    'أسماك',
    'منتجات الألبان',
    'خبز ومعجنات',
    'أرز وحبوب',
    'معلبات',
    'حلويات',
    'مشروبات',
    'أخرى'
  ];
  
  // Donation status translations
  static const Map<String, String> donationStatusTranslations = {
    'pending': 'بانتظار القبول',
    'accepted': 'مقبولة',
    'assigned': 'تم التعيين',
    'in_progress': '��اري الاستلام',
    'completed': 'تم التسليم',
    'cancelled': 'ملغاة',
  };
  
  // User role translations
  static const Map<String, String> userRoleTranslations = {
    'donor': 'متبرع',
    'association': 'جمعية',
    'volunteer': 'متطوع',
    'manager': 'مدير',
  };
  
  // Activation codes
  static const String associationActivationCode = '826627BO';
  static const String managerActivationCode = '01200602TB';
  
  // API endpoints and limits
  static const int maxImageSizeMB = 5;
  static const int maxDescriptionLength = 500;
  static const int maxTitleLength = 100;
  static const int otpLength = 6;
  
  // Map settings
  static const double defaultLatitude = 27.1536;
  static const double defaultLongitude = -13.2033;
  static const double defaultZoom = 12.0;
  
  // Notification types
  static const String notificationTypeDonationAccepted = 'donation_accepted';
  static const String notificationTypeDonationCancelled = 'donation_cancelled';
  static const String notificationTypeDonationCompleted = 'donation_completed';
  static const String notificationTypeTaskAssigned = 'task_assigned';
  
  // Points system
  static const int pointsPerDonation = 10;
  static const int pointsPerVolunteerTask = 15;
  static const int pointsPerRating = 5;
  
  // Badge thresholds
  static const Map<String, int> badgeThresholds = {
    'first_donation': 1,
    'generous_donor': 10,
    'super_donor': 50,
    'helpful_volunteer': 5,
    'super_volunteer': 25,
    'community_hero': 100,
  };
}