# توصيات تحسين الكود لاستخدام دوال SQL

## 1. تحسين association_activation_codes.dart

### الكود الحالي:
```dart
String _generateCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();
  return String.fromCharCodes(Iterable.generate(
    8,
    (_) => chars.codeUnitAt(random.nextInt(chars.length)),
  ));
}

Future<void> _createNewCode() async {
  final user = _supabase.auth.currentUser;
  if (user == null) return;

  final newCode = _generateCode();
  await _supabase.from('activation_codes').insert({
    'code': newCode,
    'role': 'volunteer',
    'created_by_association_id': user.id,
  });
}
```

### الكود المحسن:
```dart
Future<void> _createNewCode() async {
  final user = _supabase.auth.currentUser;
  if (user == null) return;

  try {
    final result = await _supabase.rpc('generate_activation_code_enhanced', 
      params: {'p_association_id': user.id, 'p_count': 1}
    ).select();
    
    if (result.isNotEmpty) {
      final newCode = result.first['code'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إنشاء الكود: $newCode')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('خطأ في إنشاء الكود: $e')),
    );
  }
  
  if (mounted) setState(() {});
}
```

## 2. إضافة QR Code Scanning

### إنشاء ملف جديد: `lib/core/services/qr_service.dart`
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class QRService {
  static final _supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>> scanQRCode({
    required String donationId,
    required String scanType, // 'pickup' or 'delivery'
    double? latitude,
    double? longitude,
  }) async {
    try {
      final result = await _supabase.rpc('scan_qr_code_enhanced', params: {
        'p_donation_id': donationId,
        'p_scan_type': scanType,
        'p_location_lat': latitude,
        'p_location_lng': longitude,
      }).select();

      return result.first as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getDonationTrackingHistory(String donationId) async {
    try {
      final result = await _supabase.rpc('get_donation_tracking_history', 
        params: {'p_donation_id': donationId}
      ).select();

      return result.first as Map<String, dynamic>;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
```

## 3. تحسين volunteer_home.dart

### استبدال الكود الحالي:
```dart
// بدلاً من:
final List data = await Supabase.instance.client
  .rpc('get_volunteer_dashboard_data', params: {'p_user_id': user.id})
  .single();

// استخدم:
final dashboardData = await Supabase.instance.client
  .rpc('get_volunteer_dashboard_data', params: {'p_user_id': user.id})
  .select();

final data = dashboardData.first;
```

## 4. تحسين association_volunteers.dart

### إضافة استخدام الدالة المحسنة:
```dart
Future<List<Map<String, dynamic>>> _fetchVolunteersDetailed() async {
  final user = _supabase.auth.currentUser;
  if (user == null) return [];

  try {
    final res = await _supabase.rpc(
      'get_volunteers_with_detailed_ratings',
      params: {'p_association_id': user.id},
    ).select();
    return List<Map<String, dynamic>>.from(res);
  } catch (e) {
    print('Error fetching volunteers: $e');
    return [];
  }
}
```

## 5. إضافة Manager Dashboard المحسن

### إنشاء ملف جديد: `lib/manager/enhanced_dashboard.dart`
```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EnhancedManagerDashboard extends StatefulWidget {
  @override
  _EnhancedManagerDashboardState createState() => _EnhancedManagerDashboardState();
}

class _EnhancedManagerDashboardState extends State<EnhancedManagerDashboard> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? dashboardData;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final result = await _supabase.rpc('get_manager_dashboard_comprehensive').select();
      setState(() {
        dashboardData = result.first;
      });
    } catch (e) {
      print('Error loading dashboard: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (dashboardData == null) {
      return Scaffold(
        appBar: AppBar(title: Text('لوحة التحكم المحسنة')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final overview = dashboardData!['overview'];
    final recentActivity = dashboardData!['recent_activity'];
    final trends = dashboardData!['trends'];

    return Scaffold(
      appBar: AppBar(title: Text('لوحة التحكم المحسنة')),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildOverviewCards(overview),
            SizedBox(height: 16),
            _buildRecentActivity(recentActivity),
            SizedBox(height: 16),
            _buildTrends(trends),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(Map<String, dynamic> overview) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('نظرة عامة', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              children: [
                _buildStatCard('إجمالي المستخدمين', overview['total_users'].toString()),
                _buildStatCard('إجمالي التبرعات', overview['total_donations'].toString()),
                _buildStatCard('التبرعات المكتملة', overview['completed_donations'].toString()),
                _buildStatCard('المتطوعين النشطين', overview['active_volunteers'].toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(Map<String, dynamic> activity) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('النشاط اليوم', style: Theme.of(context).textTheme.headlineSmall),
            ListTile(
              title: Text('مستخدمين جدد'),
              trailing: Text(activity['new_users_today'].toString()),
            ),
            ListTile(
              title: Text('تبرعات جديدة'),
              trailing: Text(activity['donations_today'].toString()),
            ),
            ListTile(
              title: Text('تبرعات مكتملة'),
              trailing: Text(activity['completed_today'].toString()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrends(Map<String, dynamic> trends) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الاتجاهات', style: Theme.of(context).textTheme.headlineSmall),
            ListTile(
              title: Text('التبرعات هذا الأسبوع'),
              trailing: Text(trends['donations_this_week'].toString()),
            ),
            ListTile(
              title: Text('التبرعات الأسبوع الماضي'),
              trailing: Text(trends['donations_last_week'].toString()),
            ),
            ListTile(
              title: Text('معدل الإكمال'),
              trailing: Text('${trends['completion_rate']}%'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 6. إضافة Map Data المحسن

### تحسين donations_map_page.dart للمدير:
```dart
Future<void> _loadMapData() async {
  try {
    final result = await _supabase.rpc('get_manager_map_data').select();
    
    setState(() {
      _mapData = List<Map<String, dynamic>>.from(result);
    });
    
    _updateMapMarkers();
  } catch (e) {
    print('Error loading map data: $e');
  }
}
```

## 7. إضافة Gamification المحسن

### إنشاء ملف جديد: `lib/core/services/gamification_service.dart`
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class GamificationService {
  static final _supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>?> getGamificationData(String userId) async {
    try {
      final result = await _supabase.rpc('get_gamification_data', 
        params: {'p_user_id': userId}
      ).select();

      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('Error fetching gamification data: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserBadges(String userId) async {
    try {
      final result = await _supabase.rpc('get_user_badges', 
        params: {'p_user_id': userId}
      ).select();

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('Error fetching user badges: $e');
      return [];
    }
  }
}
```

## ملخص التحسينات المطلوبة:

1. ✅ **استبدال إنشاء أكواد التفعيل اليدوي** بدالة SQL
2. ✅ **إضافة QR Code scanning** باستخدام دوال SQL المحسنة
3. ✅ **تحسين dashboard المدير** باستخدام البيانات الشاملة
4. ✅ **إضافة خدمة التحفيز** لاستخدام دوال الألعاب
5. ✅ **تحسين إدارة المتط��عين** بالتقييمات التفصيلية
6. ✅ **إضافة تتبع التبرعات** بالتاريخ الكامل

هذه التحسينات ستجعل التطبيق يستفيد بشكل كامل من دوال SQL الموجودة وتحسن الأداء والوظائف.