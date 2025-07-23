import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Supabase Configuration
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  // Google Maps Configuration
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'AIzaSyCOQo1Khze9YrWKoUq63pdoxfuyzoABcUY';
  
  // App Configuration
  static const String appName = 'وصال';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // Storage Buckets
  static const String donationImagesBucket = 'donation-images';
  static const String profileImagesBucket = 'profile-images';
  static const String reportsBucket = 'reports';
  
  // Notification Configuration
  static const String fcmServerKey = '';
  static const String fcmSenderId = '';
  
  // Feature Flags
  static const bool enableNotifications = true;
  static const bool enableLocationTracking = true;
  static const bool enableOfflineMode = false;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  
  // API Endpoints
  static const String baseApiUrl = 'https://api.wisaal.ma';
  static const String weatherApiUrl = 'https://api.openweathermap.org/data/2.5';
  
  // Cache Configuration
  static const Duration cacheExpiration = Duration(hours: 1);
  static const int maxCacheSize = 100; // MB
  
  // Image Configuration
  static const int maxImageSizeMB = 5;
  static const int imageQuality = 80;
  static const int maxImagesPerDonation = 3;
  
  // Location Configuration
  static const double defaultLatitude = 27.1536; // العيون
  static const double defaultLongitude = -13.2033;
  static const double defaultZoom = 12.0;
  static const double locationAccuracyThreshold = 100.0; // meters
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 500;
  static const int otpLength = 6;
  static const Duration otpExpiration = Duration(minutes: 5);
  
  // Points System
  static const int pointsPerDonation = 10;
  static const int pointsPerVolunteerTask = 15;
  static const int pointsPerRating = 5;
  static const int bonusPointsUrgent = 5;
  static const int bonusPointsLargeQuantity = 5;
  
  // Rating System
  static const int minRating = 1;
  static const int maxRating = 5;
  static const int minRatingsForAverage = 3;
  
  // Time Configuration
  static const Duration taskTimeout = Duration(hours: 24);
  static const Duration donationExpiration = Duration(days: 7);
  static const Duration notificationRetention = Duration(days: 30);
  
  // Development Configuration
  static const bool isDebugMode = true;
  static const bool enableLogging = true;
  static const bool enableTestData = false;
  
  // Social Media Links
  static const String facebookUrl = 'https://facebook.com/wisaal';
  static const String twitterUrl = 'https://twitter.com/wisaal';
  static const String instagramUrl = 'https://instagram.com/wisaal';
  static const String websiteUrl = 'https://wisaal.ma';
  
  // Contact Information
  static const String supportEmail = 'support@wisaal.ma';
  static const String supportPhone = '+212123456789';
  static const String privacyPolicyUrl = 'https://wisaal.ma/privacy';
  static const String termsOfServiceUrl = 'https://wisaal.ma/terms';
  
  // Emergency Configuration
  static const String emergencyContactNumber = '15';
  static const String policeNumber = '19';
  static const String ambulanceNumber = '15';
  
  // Validation Methods
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  static bool isValidPhone(String phone) {
    return RegExp(r'^\+?[0-9]{10,15}$').hasMatch(phone);
  }
  
  static bool isValidOTP(String otp) {
    return RegExp(r'^\d{6}$').hasMatch(otp);
  }
  
  static bool isValidPassword(String password) {
    return password.length >= minPasswordLength;
  }
  
  // Environment Checks
  static bool get isProduction => !isDebugMode;
  static bool get isDevelopment => isDebugMode;
  
  // Initialize configuration
  static Future<void> initialize() async {
    await dotenv.load();
    // Add any additional initialization logic here
  }
}