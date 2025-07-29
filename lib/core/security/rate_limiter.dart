import 'dart:collection';

/// نظام تحديد معدل الطلبات لمنع هجمات DDoS والاستخدام المفرط
class RateLimiter {
  static final RateLimiter _instance = RateLimiter._internal();
  factory RateLimiter() => _instance;
  RateLimiter._internal();
  
  // تخزين آخر طلبات كل endpoint
  final Map<String, Queue<DateTime>> _requests = {};
  
  // إعدادات Rate Limiting لكل نوع من الطلبات
  static const Map<String, RateLimit> _limits = {
    'auth_login': RateLimit(maxRequests: 5, windowMinutes: 15), // 5 محاولات تسجيل دخول كل 15 دقيقة
    'auth_otp': RateLimit(maxRequests: 3, windowMinutes: 10),   // 3 طلبات OTP كل 10 دقائق
    'donation_create': RateLimit(maxRequests: 10, windowMinutes: 60), // 10 تبرعات كل ساعة
    'notification_send': RateLimit(maxRequests: 20, windowMinutes: 60), // 20 إشعار كل ساعة
    'profile_update': RateLimit(maxRequests: 5, windowMinutes: 30), // 5 تحديثات ملف شخصي كل 30 دقيقة
    'rating_submit': RateLimit(maxRequests: 10, windowMinutes: 60), // 10 تقييمات كل ساعة
    'search_query': RateLimit(maxRequests: 100, windowMinutes: 60), // 100 بحث كل ساعة
    'file_upload': RateLimit(maxRequests: 20, windowMinutes: 60), // 20 رفع ملف كل ساعة
    'general_api': RateLimit(maxRequests: 200, windowMinutes: 60), // 200 طلب عام كل ساعة
  };
  
  /// التحقق من إمكانية تنفيذ الطلب
  bool canMakeRequest(String endpoint, {String? userId}) {
    final key = _getKey(endpoint, userId);
    final limit = _limits[endpoint] ?? _limits['general_api']!;
    
    final now = DateTime.now();
    final windowStart = now.subtract(Duration(minutes: limit.windowMinutes));
    
    // إنشاء قائمة الطلبات إذا لم تكن موجودة
    _requests[key] ??= Queue<DateTime>();
    
    // إزالة الطلبات القديمة خارج النافزة الزمنية
    while (_requests[key]!.isNotEmpty && 
           _requests[key]!.first.isBefore(windowStart)) {
      _requests[key]!.removeFirst();
    }
    
    // التحقق من عدد الطلبات
    if (_requests[key]!.length >= limit.maxRequests) {
      _logRateLimitExceeded(endpoint, userId, limit);
      return false;
    }
    
    // إضافة الطلب الحالي
    _requests[key]!.addLast(now);
    return true;
  }
  
  /// الحصول على مفتاح فريد للمستخدم والـ endpoint
  String _getKey(String endpoint, String? userId) {
    return '${userId ?? 'anonymous'}_$endpoint';
  }
  
  /// تسجيل تجاوز الحد المسموح
  void _logRateLimitExceeded(String endpoint, String? userId, RateLimit limit) {
    print('⚠️ Rate limit exceeded for $endpoint by user ${userId ?? 'anonymous'}');
    print('📊 Limit: ${limit.maxRequests} requests per ${limit.windowMinutes} minutes');
    
    // في الإنتاج، يمكن إرسال تنبيه للمراقبة
    // SecurityLogger.logRateLimitExceeded(endpoint, userId, limit);
  }
  
  /// الحصول على عدد الطلبات المتبقية
  int getRemainingRequests(String endpoint, {String? userId}) {
    final key = _getKey(endpoint, userId);
    final limit = _limits[endpoint] ?? _limits['general_api']!;
    
    final now = DateTime.now();
    final windowStart = now.subtract(Duration(minutes: limit.windowMinutes));
    
    if (!_requests.containsKey(key)) {
      return limit.maxRequests;
    }
    
    // إزالة الطلبات القديمة
    while (_requests[key]!.isNotEmpty && 
           _requests[key]!.first.isBefore(windowStart)) {
      _requests[key]!.removeFirst();
    }
    
    return limit.maxRequests - _requests[key]!.length;
  }
  
  /// الحصول على وقت إعادة التعيين
  DateTime? getResetTime(String endpoint, {String? userId}) {
    final key = _getKey(endpoint, userId);
    final limit = _limits[endpoint] ?? _limits['general_api']!;
    
    if (!_requests.containsKey(key) || _requests[key]!.isEmpty) {
      return null;
    }
    
    return _requests[key]!.first.add(Duration(minutes: limit.windowMinutes));
  }
  
  /// مسح جميع الطلبات (للاختبار فقط)
  void clearAll() {
    _requests.clear();
  }
  
  /// مسح طلبات مستخدم معين
  void clearUser(String userId) {
    _requests.removeWhere((key, _) => key.startsWith('${userId}_'));
  }
}

/// إعدادات Rate Limiting
class RateLimit {
  final int maxRequests;
  final int windowMinutes;
  
  const RateLimit({
    required this.maxRequests,
    required this.windowMinutes,
  });
}

/// Mixin لإضافة Rate Limiting للـ widgets
mixin RateLimitedWidget {
  final RateLimiter _rateLimiter = RateLimiter();
  
  /// تنفيذ عملية مع Rate Limiting
  Future<T?> executeWithRateLimit<T>(
    String endpoint,
    Future<T> Function() operation, {
    String? userId,
    void Function()? onRateLimitExceeded,
  }) async {
    if (!_rateLimiter.canMakeRequest(endpoint, userId: userId)) {
      onRateLimitExceeded?.call();
      return null;
    }
    
    try {
      return await operation();
    } catch (e) {
      rethrow;
    }
  }
  
  /// التحقق من إمكانية تنفيذ العملية
  bool canExecute(String endpoint, {String? userId}) {
    return _rateLimiter.canMakeRequest(endpoint, userId: userId);
  }
  
  /// الحصول على معلومات Rate Limit
  RateLimitInfo getRateLimitInfo(String endpoint, {String? userId}) {
    return RateLimitInfo(
      remaining: _rateLimiter.getRemainingRequests(endpoint, userId: userId),
      resetTime: _rateLimiter.getResetTime(endpoint, userId: userId),
    );
  }
}

/// معلومات Rate Limit
class RateLimitInfo {
  final int remaining;
  final DateTime? resetTime;
  
  const RateLimitInfo({
    required this.remaining,
    this.resetTime,
  });
  
  bool get isExceeded => remaining <= 0;
  
  Duration? get timeUntilReset {
    if (resetTime == null) return null;
    final now = DateTime.now();
    return resetTime!.isAfter(now) ? resetTime!.difference(now) : null;
  }
}

/// استثناء تجاوز Rate Limit
class RateLimitExceededException implements Exception {
  final String endpoint;
  final DateTime? resetTime;
  final int remainingRequests;
  
  const RateLimitExceededException({
    required this.endpoint,
    this.resetTime,
    this.remainingRequests = 0,
  });
  
  @override
  String toString() {
    final resetTimeStr = resetTime != null 
        ? 'يمكنك المحاولة مرة أخرى في ${resetTime!.toLocal()}'
        : 'يرجى المحاولة لاحقاً';
    
    return 'تم تجاوز الحد المسموح للطلبات. $resetTimeStr';
  }
}