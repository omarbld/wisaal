import 'package:supabase_flutter/supabase_flutter.dart';

/// خدمة إدارة بيانات المتطوع
class VolunteerService {
  static final _supabase = Supabase.instance.client;
  
  /// جلب بيانات لوحة التحكم للمتطوع
  static Future<Map<String, dynamic>?> getDashboardData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase.rpc(
        'get_volunteer_dashboard_data',
        params: {'p_user_id': user.id},
      );

      return response as Map<String, dynamic>?;
    } catch (e) {
      print('خطأ في جلب بيانات اللوحة: $e');
      return null;
    }
  }
  
  /// جلب معلومات الجمعية المرتبطة بالمتطوع
  static Future<Map<String, dynamic>?> getAssociationInfo() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final volunteerData = await _supabase
          .from('users')
          .select('associated_with_association_id')
          .eq('id', user.id)
          .single();

      final associationId = volunteerData['associated_with_association_id'];
      if (associationId == null) return null;

      final associationData = await _supabase
          .from('users')
          .select('full_name, phone, city, avatar_url, email')
          .eq('id', associationId)
          .single();

      return associationData;
    } catch (e) {
      print('خطأ في جلب معلومات الجمعية: $e');
      return null;
    }
  }
  
  /// جلب التبرعات المتاحة للمتطوع
  static Future<List<Map<String, dynamic>>> getAvailableDonations({
    String filter = 'all',
    int limit = 20,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // جلب معرف الجمعية
      final volunteerData = await _supabase
          .from('users')
          .select('associated_with_association_id')
          .eq('id', user.id)
          .single();

      final associationId = volunteerData['associated_with_association_id'];
      if (associationId == null) return [];

      // بناء الاستعلام مع تضمين بيانات الموقع
      var query = _supabase
          .from('donations')
          .select('''
            *, 
            donor:donor_id(full_name, phone, city, avatar_url),
            association:association_id(full_name)
          ''')
          .eq('status', 'pending')
          .eq('association_id', associationId);

      // تطبيق الفلاتر
      switch (filter) {
        case 'urgent':
          query = query.eq('is_urgent', true);
          break;
        case 'new':
          final yesterday = DateTime.now().subtract(const Duration(days: 1));
          query = query.filter('created_at', 'gte', yesterday.toIso8601String());
          break;
        // يمكن إضافة فلاتر أخرى مثل المسافة
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('خطأ في جلب التبرعات المتاحة: $e');
      return [];
    }
  }
  
  /// جلب المهام النشطة للمتطوع
  static Future<List<Map<String, dynamic>>> getActiveTasks({
    int limit = 10,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('donations')
          .select('''
            *, 
            donor:donor_id(full_name, phone, city, avatar_url),
            association:association_id(full_name, phone)
          ''')
          .eq('volunteer_id', user.id)
          .in_('status', ['assigned', 'in_progress'])
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('خطأ في جلب المهام النشطة: $e');
      return [];
    }
  }
  
  /// جلب المهام المكتملة للمتطوع
  static Future<List<Map<String, dynamic>>> getCompletedTasks({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('donations')
          .select('''
            *, 
            donor:donor_id(full_name, phone, city),
            association:association_id(full_name),
            rating:ratings(rating, comment, created_at)
          ''')
          .eq('volunteer_id', user.id)
          .eq('status', 'completed')
          .order('delivered_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('خطأ في جلب المهام المكتملة: $e');
      return [];
    }
  }
  
  /// قبول تبرع
  static Future<bool> acceptDonation(String donationId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('donations')
          .update({
            'volunteer_id': user.id,
            'status': 'assigned',
          })
          .eq('donation_id', donationId);

      return true;
    } catch (e) {
      print('خطأ في قبول التبرع: $e');
      return false;
    }
  }
  
  /// تحديث حالة المهمة
  static Future<bool> updateTaskStatus(String donationId, String newStatus) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final updateData = <String, dynamic>{
        'status': newStatus,
      };

      // إضافة الطوابع الزمنية حسب الحالة
      switch (newStatus) {
        case 'in_progress':
          updateData['picked_up_at'] = DateTime.now().toIso8601String();
          break;
        case 'completed':
          updateData['delivered_at'] = DateTime.now().toIso8601String();
          break;
      }

      await _supabase
          .from('donations')
          .update(updateData)
          .eq('donation_id', donationId)
          .eq('volunteer_id', user.id);

      return true;
    } catch (e) {
      print('خطأ في تحديث حالة المهمة: $e');
      return false;
    }
  }
  
  /// جلب الإحصائيات الشخصية للمتطوع
  static Future<Map<String, dynamic>> getPersonalStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return {};

      // جلب بيانات المستخدم
      final userResponse = await _supabase
          .from('users')
          .select('points, created_at')
          .eq('id', user.id)
          .single();

      // جلب إحصائيات المهام
      final tasksResponse = await _supabase
          .from('donations')
          .select('status, created_at, delivered_at')
          .eq('volunteer_id', user.id);

      // جلب التقييمات
      final ratingsResponse = await _supabase
          .from('ratings')
          .select('rating, created_at')
          .eq('volunteer_id', user.id);

      // حساب الإحصائيات
      final totalTasks = tasksResponse.length;
      final completedTasks = tasksResponse.where((t) => t['status'] == 'completed').length;
      final inProgressTasks = tasksResponse.where((t) => t['status'] == 'in_progress').length;
      final assignedTasks = tasksResponse.where((t) => t['status'] == 'assigned').length;

      double avgRating = 0.0;
      if (ratingsResponse.isNotEmpty) {
        final totalRating = ratingsResponse.fold<double>(
          0.0,
          (sum, rating) => sum + (rating['rating'] ?? 0).toDouble(),
        );
        avgRating = totalRating / ratingsResponse.length;
      }

      // حساب المهام هذا الشهر
      final thisMonth = DateTime.now();
      final startOfMonth = DateTime(thisMonth.year, thisMonth.month, 1);
      final tasksThisMonth = tasksResponse.where((t) {
        final createdAt = DateTime.parse(t['created_at']);
        return createdAt.isAfter(startOfMonth);
      }).length;

      // حساب متوسط وقت الإنجاز
      final completedWithTimes = tasksResponse.where((t) => 
        t['status'] == 'completed' && 
        t['created_at'] != null && 
        t['delivered_at'] != null
      ).toList();

      double avgCompletionHours = 0.0;
      if (completedWithTimes.isNotEmpty) {
        final totalHours = completedWithTimes.fold<double>(0.0, (sum, task) {
          final created = DateTime.parse(task['created_at']);
          final delivered = DateTime.parse(task['delivered_at']);
          return sum + delivered.difference(created).inHours;
        });
        avgCompletionHours = totalHours / completedWithTimes.length;
      }

      return {
        'points': userResponse['points'] ?? 0,
        'total_tasks': totalTasks,
        'completed_tasks': completedTasks,
        'in_progress_tasks': inProgressTasks,
        'assigned_tasks': assignedTasks,
        'avg_rating': avgRating,
        'total_ratings': ratingsResponse.length,
        'tasks_this_month': tasksThisMonth,
        'avg_completion_hours': avgCompletionHours,
        'member_since': userResponse['created_at'],
        'completion_rate': totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0.0,
      };
    } catch (e) {
      print('خطأ في جلب الإحصائيات الشخصية: $e');
      return {};
    }
  }
  
  /// جلب الشارات المكتسبة
  static Future<List<Map<String, dynamic>>> getEarnedBadges() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase.rpc(
        'get_user_badges',
        params: {'p_user_id': user.id},
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('خطأ في جلب الشارات: $e');
      return [];
    }
  }
  
  /// جلب ترتيب المتطوع في لوحة الصدارة
  static Future<Map<String, dynamic>?> getLeaderboardPosition() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase.rpc('get_leaderboard');
      final leaderboard = List<Map<String, dynamic>>.from(response ?? []);
      
      final userPosition = leaderboard.indexWhere((entry) => 
        entry['user_id'] == user.id
      );

      if (userPosition != -1) {
        return {
          'position': userPosition + 1,
          'total_participants': leaderboard.length,
          'points': leaderboard[userPosition]['points'],
          'percentile': ((leaderboard.length - userPosition) / leaderboard.length * 100).round(),
        };
      }

      return null;
    } catch (e) {
      print('خطأ في جلب ترتيب لوحة الصدارة: $e');
      return null;
    }
  }
  
  /// تسجيل ساعات العمل التطوعي
  static Future<bool> logVolunteerHours({
    required String donationId,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase.rpc(
        'log_volunteer_hours',
        params: {
          'p_volunteer_id': user.id,
          'p_donation_id': donationId,
          'p_start_time': startTime.toIso8601String(),
          'p_end_time': endTime.toIso8601String(),
          'p_notes': notes,
        },
      );

      return true;
    } catch (e) {
      print('خطأ في تسجيل ساعات العمل: $e');
      return false;
    }
  }
  
  /// البحث في التبرعات المتاحة
  static Future<List<Map<String, dynamic>>> searchDonations({
    String? query,
    String? foodType,
    bool? isUrgent,
    String? city,
    int limit = 20,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // جلب معرف الجمعية
      final volunteerData = await _supabase
          .from('users')
          .select('associated_with_association_id')
          .eq('id', user.id)
          .single();

      final associationId = volunteerData['associated_with_association_id'];
      if (associationId == null) return [];

      // بناء الاستعلام
      var queryBuilder = _supabase
          .from('donations')
          .select('''
            *, 
            donor:donor_id(full_name, phone, city, avatar_url),
            association:association_id(full_name)
          ''')
          .eq('status', 'pending')
          .eq('association_id', associationId);

      // تطبيق الفلاتر
      if (query != null && query.isNotEmpty) {
        queryBuilder = queryBuilder.filter('title', 'ilike', '%$query%').filter('description', 'ilike', '%$query%');
      }
      
      if (foodType != null && foodType.isNotEmpty) {
        queryBuilder = queryBuilder.filter('food_type', 'eq', foodType);
      }
      
      if (isUrgent != null) {
        queryBuilder = queryBuilder.filter('is_urgent', 'eq', isUrgent);
      }

      final response = await queryBuilder
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('خطأ ��ي البحث في التبرعات: $e');
      return [];
    }
  }
  
  /// تحديث موقع المتطوع
  static Future<bool> updateLocation(double latitude, double longitude) async {
    try {
      await _supabase.rpc(
        'update_user_location',
        params: {
          'lat': latitude,
          'lng': longitude,
        },
      );

      return true;
    } catch (e) {
      print('خطأ في تحديث الموقع: $e');
      return false;
    }
  }
  
  /// جلب الإشعارات
  static Future<List<Map<String, dynamic>>> getNotifications({
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      var query = _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id);

      if (unreadOnly) {
        query = query.eq('is_read', false);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('خطأ في جلب الإشعارات: $e');
      return [];
    }
  }
  
  /// تحديد الإشعار كمقروء
  static Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      return true;
    } catch (e) {
      print('خطأ في تحديد الإشعار كمقروء: $e');
      return false;
    }
  }

  /// جلب التبرعات للخريطة مع بيانات الموقع
  static Future<List<Map<String, dynamic>>> getDonationsForMap() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // جلب معرف الجمعية
      final volunteerData = await _supabase
          .from('users')
          .select('associated_with_association_id')
          .eq('id', user.id)
          .single();

      final associationId = volunteerData['associated_with_association_id'];
      if (associationId == null) return [];

      // استخدام الدالة المخصصة للحصول على بيانات الخريطة
      final response = await _supabase.rpc(
        'get_map_data_with_coordinates',
        params: {
          'p_user_role': 'volunteer',
          'p_user_id': user.id,
        },
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('خطأ في جلب بيانات الخريطة: $e');
      
      // Fallback: try to get donations with manual coordinate extraction
      try {
        final user = _supabase.auth.currentUser;
        if (user == null) return [];

        final volunteerData = await _supabase
            .from('users')
            .select('associated_with_association_id')
            .eq('id', user.id)
            .single();

        final associationId = volunteerData['associated_with_association_id'];
        if (associationId == null) return [];

        final donations = await _supabase
            .from('donations')
            .select('*, donor:donor_id(full_name)')
            .eq('status', 'pending')
            .eq('association_id', associationId)
            .not('location', 'is', null);

        // Process the donations to extract coordinates
        final processedDonations = <Map<String, dynamic>>[];
        for (final donation in donations) {
          if (donation['location'] != null) {
            try {
              // Try to extract coordinates using PostGIS functions
              final coordResponse = await _supabase.rpc(
                'get_latitude_from_location',
                params: {'location_geom': donation['location']},
              );
              
              final lat = coordResponse as double?;
              if (lat != null) {
                final lngResponse = await _supabase.rpc(
                  'get_longitude_from_location',
                  params: {'location_geom': donation['location']},
                );
                
                final lng = lngResponse as double?;
                if (lng != null) {
                  final processedDonation = Map<String, dynamic>.from(donation);
                  processedDonation['latitude'] = lat;
                  processedDonation['longitude'] = lng;
                  processedDonations.add(processedDonation);
                }
              }
            } catch (coordError) {
              print('خطأ في استخراج الإحداثيات للتبرع ${donation['donation_id']}: $coordError');
            }
          }
        }
        
        return processedDonations;
      } catch (fallbackError) {
        print('خطأ في الطريقة البديلة: $fallbackError');
        return [];
      }
    }
  }
}