import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// خدمة تحديد الموقع الجغرافي وإدارة الإحداثيات
class LocationService {
  static final _supabase = Supabase.instance.client;

  /// طلب إذن الموقع والحصول على الإحداثيات
  static Future<Position?> getCurrentLocation(BuildContext context) async {
    try {
      // التحقق من تفعيل خدمات الموقع
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _showLocationServiceDialog(context);
        return null;
      }

      // التحقق من إذن الموقع
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          await _showPermissionDeniedDialog(context);
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await _showPermissionDeniedForeverDialog(context);
        return null;
      }

      // الحصول على الموقع الحالي
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      debugPrint('✅ تم الحصول على الموقع: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على الموقع: $e');
      await _showLocationErrorDialog(context, e.toString());
      return null;
    }
  }

  /// حفظ الموقع في قاعدة البيانات للمستخدم الحالي
  static Future<bool> saveUserLocation(
    double latitude,
    double longitude, {
    BuildContext? context,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ المستخدم غير مسجل الدخول');
        return false;
      }

      // تحديث موقع المستخدم في جدول users باستخدام PostGIS
      await _supabase.from('users').update({
        'location': 'POINT($longitude $latitude)', // PostGIS format: longitude first, then latitude
      }).eq('id', user.id);

      // تحديث م��قع المستخدم في جدول user_locations للتتبع المباشر
      await _supabase.rpc('update_user_location', params: {
        'lat': latitude,
        'lng': longitude,
      });

      debugPrint('✅ تم حفظ الموقع بنجاح: $latitude, $longitude');
      
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حفظ موقعك بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في حفظ الموقع: $e');
      
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في حفظ الموقع: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      return false;
    }
  }

  /// الحصول على الموقع وحفظه مباشرة
  static Future<bool> getCurrentLocationAndSave(BuildContext context) async {
    try {
      // عرض مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحديد موقعك...'),
                ],
              ),
            ),
          ),
        ),
      );

      // الحصول على الموقع
      Position? position = await getCurrentLocation(context);
      
      // إغلاق مؤشر التحميل
      Navigator.of(context).pop();

      if (position == null) {
        return false;
      }

      // حفظ الموقع
      return await saveUserLocation(
        position.latitude,
        position.longitude,
        context: context,
      );
    } catch (e) {
      // إغلاق مؤشر التحميل في حالة الخطأ
      Navigator.of(context).pop();
      debugPrint('❌ خطأ في العملية: $e');
      return false;
    }
  }

  /// التحقق من وجود تكرار في البيانات
  static Future<void> checkForDuplicateLocations() async {
    try {
      debugPrint('🔍 بدء فحص التكرار في البيانات...');

      // فحص المستخدمين المكررين بنفس الإحداثيات
      final duplicateUsers = await _supabase.rpc('check_duplicate_user_locations');
      
      if (duplicateUsers != null && duplicateUsers.isNotEmpty) {
        debugPrint('⚠️ تم العثور على مستخدمين مكررين بنفس الموقع:');
        for (var user in duplicateUsers) {
          debugPrint('   - المستخدم: ${user['full_name']} (${user['email']})');
          debugPrint('   - الموقع: ${user['latitude']}, ${user['longitude']}');
          debugPrint('   - عدد المكررات: ${user['duplicate_count']}');
        }
      }

      // فحص التبرعات المكررة بنفس الإحداثيات
      final duplicateDonations = await _supabase.rpc('check_duplicate_donation_locations');
      
      if (duplicateDonations != null && duplicateDonations.isNotEmpty) {
        debugPrint('⚠️ تم العثور على تبرعات مكررة بنفس الموقع:');
        for (var donation in duplicateDonations) {
          debugPrint('   - التبرع: ${donation['title']}');
          debugPrint('   - الموقع: ${donation['latitude']}, ${donation['longitude']}');
          debugPrint('   - عدد المكررات: ${donation['duplicate_count']}');
        }
      }

      // فحص المستخدمين بنفس البيانات الشخصية
      final duplicatePersonalData = await _supabase.rpc('check_duplicate_personal_data');
      
      if (duplicatePersonalData != null && duplicatePersonalData.isNotEmpty) {
        debugPrint('⚠️ تم العثور على مستخدمين مكررين بنفس البيانات الشخصية:');
        for (var user in duplicatePersonalData) {
          debugPrint('   - الاسم: ${user['full_name']}');
          debugPrint('   - الهاتف: ${user['phone']}');
          debugPrint('   - البريد: ${user['email']}');
          debugPrint('   - عدد المكررات: ${user['duplicate_count']}');
        }
      }

      debugPrint('✅ انتهى فحص التكرار في البيانات');
    } catch (e) {
      debugPrint('❌ خطأ في فحص التكرار: $e');
    }
  }

  /// الحصول على موقع المستخدم المحفوظ
  static Future<Map<String, double>?> getUserSavedLocation() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('users')
          .select('location')
          .eq('id', user.id)
          .single();

      if (response['location'] != null) {
        // استخراج الإحداثيات من PostGIS Point
        final locationData = await _supabase.rpc('extract_coordinates_from_location', params: {
          'location_point': response['location'],
        });

        if (locationData != null) {
          return {
            'latitude': locationData['latitude'].toDouble(),
            'longitude': locationData['longitude'].toDouble(),
          };
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على الموقع المحفوظ: $e');
      return null;
    }
  }

  /// حساب المسافة بين نقطتين
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// عرض dialog لتفعيل خدمات الموقع
  static Future<void> _showLocationServiceDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خدمات الموقع غير مفعلة'),
        content: const Text(
          'يرجى تفعيل خدمات الموقع في إعدادات الجهاز للمتابعة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await Geolocator.openLocationSettings();
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }

  /// عرض dialog لرفض إذن الموقع
  static Future<void> _showPermissionDeniedDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إذن الموقع مرفوض'),
        content: const Text(
          'نحتاج إلى إذن الوصول للموقع لتحديد موقعك وعرض التبرعات القريبة منك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await Geolocator.requestPermission();
            },
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  /// عرض dialog لرفض إذن الموقع نهائياً
  static Future<void> _showPermissionDeniedForeverDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إذن الموقع مرفوض نهائياً'),
        content: const Text(
          'تم رفض إذن الموقع نهائياً. يرجى الذهاب إلى إعدادات التطبيق وتفعيل إذن الموقع يدوياً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await Geolocator.openAppSettings();
            },
            child: const Text('فتح إعدادات التطبيق'),
          ),
        ],
      ),
    );
  }

  /// عرض dialog لخطأ في الموقع
  static Future<void> _showLocationErrorDialog(BuildContext context, String error) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خطأ في تحديد الموقع'),
        content: Text('حدث خطأ أثناء تحديد موقعك:\n$error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
}