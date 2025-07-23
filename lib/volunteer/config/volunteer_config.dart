import 'package:flutter/material.dart';

/// إعدادات وثوابت خاصة بدور المتطوع
class VolunteerConfig {
  
  // ألوان خاصة بالمتطوع
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color accentColor = Color(0xFF03DAC6);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  
  // أحجام وأبعاد
  static const double cardElevation = 4.0;
  static const double borderRadius = 12.0;
  static const double iconSize = 24.0;
  static const double avatarRadius = 30.0;
  
  // مدد الحركات
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  
  // نصوص ثابتة
  static const Map<String, String> texts = {
    'welcome': 'مرحباً بك',
    'availableDonations': 'التبرعات المتاحة',
    'myTasks': 'مهامي النشطة',
    'completedTasks': 'المهام المكتملة',
    'inProgressTasks': 'قيد التنفيذ',
    'assignedTasks': 'مُعيَّنة',
    'rating': 'التقييم',
    'points': 'النقاط',
    'urgent': 'عاجل',
    'accept': 'قبول',
    'details': 'تفاصيل',
    'viewAll': 'عرض الكل',
    'refresh': 'تحديث',
    'search': 'بحث',
    'filter': 'فلتر',
    'noTasks': 'لا توجد مهام نشطة',
    'noDonations': 'لا توجد تبرعات متاحة',
    'loadingError': 'خطأ في تحميل البيانات',
    'acceptSuccess': 'تم قبول التبرع بنجاح! 🎉',
    'acceptError': 'خطأ في قبول التبرع',
    'notLinkedToAssociation': 'لم يتم ربطك بأي جمعية. يرجى التواصل مع الإدارة.',
  };
  
  // أنواع الفلاتر
  static const List<Map<String, dynamic>> filters = [
    {'label': 'الكل', 'icon': Icons.all_inclusive, 'value': 'all'},
    {'label': 'عاجل', 'icon': Icons.priority_high, 'value': 'urgent'},
    {'label': 'قريب', 'icon': Icons.location_on, 'value': 'nearby'},
    {'label': 'جديد', 'icon': Icons.new_releases, 'value': 'new'},
  ];
  
  // حالات المهام
  static const Map<String, Map<String, dynamic>> taskStatuses = {
    'assigned': {
      'label': 'مُعيَّنة',
      'color': Color(0xFFFF9800),
      'icon': Icons.assignment,
    },
    'in_progress': {
      'label': 'قيد التنفيذ',
      'color': Color(0xFF2196F3),
      'icon': Icons.pending_actions,
    },
    'completed': {
      'label': 'مكتملة',
      'color': Color(0xFF4CAF50),
      'icon': Icons.check_circle,
    },
  };
  
  // أنواع الطعام مع الأيقونات
  static const Map<String, IconData> foodTypeIcons = {
    'fruits': Icons.apple,
    'فواكه': Icons.apple,
    'vegetables': Icons.eco,
    'خضروات': Icons.eco,
    'meat': Icons.restaurant,
    'لحوم': Icons.restaurant,
    'dairy': Icons.local_drink,
    'ألبان': Icons.local_drink,
    'bread': Icons.bakery_dining,
    'خبز': Icons.bakery_dining,
    'canned': Icons.inventory,
    'معلبات': Icons.inventory,
    'sweets': Icons.cake,
    'حلويات': Icons.cake,
    'beverages': Icons.local_cafe,
    'مشروبات': Icons.local_cafe,
  };
  
  // إعدادات الشبكة والتحديث
  static const int maxRetries = 3;
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration refreshInterval = Duration(minutes: 5);
  
  // إعدادات الصفحات
  static const int donationsPerPage = 20;
  static const int tasksPerPage = 10;
  static const int maxRecentTasks = 5;
  
  // إعدادات الخريطة
  static const double defaultZoom = 14.0;
  static const double maxDistance = 50.0; // كيلومتر
  
  // إعدادات الإشعارات
  static const Map<String, String> notificationTypes = {
    'task_assigned': 'تم تعيين مهمة جديدة',
    'task_updated': 'تم تحديث المهمة',
    'rating_received': 'تم استلام تقييم جديد',
    'points_earned': 'تم كسب نقاط جديدة',
    'badge_earned': 'تم الحصول على شارة جديدة',
  };
  
  // رسائل التحفيز
  static const List<String> motivationalMessages = [
    'أنت تصنع فرقاً حقيقياً! 💪',
    'كل مهمة تكملها تساعد شخصاً محتاجاً 🤝',
    'استمر في العطاء، أنت رائع! ⭐',
    'عملك التطوعي يلهم الآخرين 🌟',
    'شكراً لك على خدمة المجتمع 🙏',
    'أنت بطل حقيقي في مجتمعك! 🦸‍♂️',
  ];
  
  // إعدادات النقاط والشارات
  static const Map<String, int> pointsSystem = {
    'task_completed': 10,
    'urgent_task_completed': 15,
    'rating_5_stars': 5,
    'rating_4_stars': 3,
    'consecutive_tasks': 20,
    'weekly_goal': 50,
    'monthly_goal': 200,
  };
  
  // مستويات المتطوع
  static const Map<String, Map<String, dynamic>> volunteerLevels = {
    'beginner': {
      'label': 'متطوع مبتدئ',
      'minPoints': 0,
      'maxPoints': 99,
      'color': Color(0xFF9E9E9E),
      'icon': Icons.person,
    },
    'active': {
      'label': 'متطوع نشط',
      'minPoints': 100,
      'maxPoints': 499,
      'color': Color(0xFF2196F3),
      'icon': Icons.person_pin,
    },
    'expert': {
      'label': 'متطوع خبير',
      'minPoints': 500,
      'maxPoints': 999,
      'color': Color(0xFF4CAF50),
      'icon': Icons.star,
    },
    'champion': {
      'label': 'بطل المجتمع',
      'minPoints': 1000,
      'maxPoints': 9999,
      'color': Color(0xFFFF9800),
      'icon': Icons.emoji_events,
    },
    'legend': {
      'label': 'أسطورة التطوع',
      'minPoints': 10000,
      'maxPoints': 999999,
      'color': Color(0xFF9C27B0),
      'icon': Icons.workspace_premium,
    },
  };
  
  /// الحصول على مستوى المتطوع بناءً على النقاط
  static Map<String, dynamic> getVolunteerLevel(int points) {
    for (final level in volunteerLevels.entries) {
      final levelData = level.value;
      if (points >= levelData['minPoints'] && points <= levelData['maxPoints']) {
        return {
          'key': level.key,
          ...levelData,
        };
      }
    }
    return volunteerLevels['beginner']!;
  }
  
  /// الحصول على أيقونة نوع الطعام
  static IconData getFoodTypeIcon(String? foodType) {
    if (foodType == null) return Icons.fastfood_outlined;
    return foodTypeIcons[foodType.toLowerCase()] ?? Icons.fastfood_outlined;
  }
  
  /// الحصول على معلومات حالة المهمة
  static Map<String, dynamic> getTaskStatusInfo(String status) {
    return taskStatuses[status] ?? {
      'label': 'غير معروف',
      'color': const Color(0xFF9E9E9E),
      'icon': Icons.help_outline,
    };
  }
  
  /// الحصول على رسالة تحفيزية عشوائية
  static String getRandomMotivationalMessage() {
    final random = DateTime.now().millisecondsSinceEpoch % motivationalMessages.length;
    return motivationalMessages[random];
  }
  
  /// تنسيق عدد النقاط
  static String formatPoints(int points) {
    if (points >= 1000000) {
      return '${(points / 1000000).toStringAsFixed(1)}م';
    } else if (points >= 1000) {
      return '${(points / 1000).toStringAsFixed(1)}ك';
    } else {
      return points.toString();
    }
  }
  
  /// تنسيق التقييم
  static String formatRating(double rating) {
    return rating.toStringAsFixed(1);
  }
  
  /// تحديد لون التقييم
  static Color getRatingColor(double rating) {
    if (rating >= 4.5) return const Color(0xFF4CAF50);
    if (rating >= 3.5) return const Color(0xFF8BC34A);
    if (rating >= 2.5) return const Color(0xFFFF9800);
    if (rating >= 1.5) return const Color(0xFFFF5722);
    return const Color(0xFFF44336);
  }
}