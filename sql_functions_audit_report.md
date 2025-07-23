# تقرير مراجعة دوال SQL في مشروع وصال

## الدوال المستخدمة في الكود ✅

### 1. دوال المتطوعين
- `get_volunteer_dashboard_data` - مستخدمة في `volunteer_home.dart`
- `get_user_badges` - مستخدمة في `volunteer_profile_screen.dart`
- `get_volunteer_logs` - مستخدمة في `volunteer_profile_screen.dart`
- `log_volunteer_hours` - مستخدمة في `volunteer_task_details.dart`
- `get_leaderboard` - مستخدمة في `volunteer/leaderboard_page.dart`, `donor/leaderboard_page.dart`, `association/leaderboard_page.dart`
- `update_user_location` - مستخدمة في `volunteer/donations_map_page.dart`

### 2. دوال الجمعيات
- `get_volunteers_for_association` - مستخدمة في `association_volunteers.dart`, `association_select_volunteer.dart`
- `get_association_report_data` - مستخدمة في `association_reports.dart`
- `get_scheduled_donations` - مستخدمة في `association_home.dart`
- `schedule_donation_pickup` - مستخدمة في `association_home.dart`

### 3. دوال المدير
- `get_full_leaderboard` - مستخدمة في `manager/leaderboard_page.dart`
- `send_bulk_notification` - مستخدمة في `manager_notifications.dart`, `notification_service.dart`

### 4. دوال عامة
- `register_volunteer` - مستخدمة في `otp_screen.dart`
- `generate_share_text` - مستخدمة في `volunteer_task_details.dart`

## الدوال الموجودة في SQL لكن غير مستخدمة في الكود ⚠️

### 1. دوال الخريطة والمواقع
- `get_map_data` - دالة شاملة لجلب بيانات الخريطة حسب نوع المستخدم
- `get_donations_for_map` - جلب التبرعات المعلقة للخريطة
- `get_all_donations_for_map` - جلب جميع التبرعات للمدير
- `get_manager_map_data` - بيانات خريطة المدير الشاملة

### 2. دوال التحفيز والألعاب
- `get_gamification_data` - بيانات التحفيز الشاملة للمستخدم
- `award_points_for_donation` - منح نقاط للمتطوع (تعمل تلقائياً عبر المشغلات)
- `check_and_award_badges` - فحص ومنح الشارات (تعمل تلقائياً عبر المشغلات)

### 3. دوال إدارة المتطوعين
- `get_volunteers_with_ratings` - جلب المتطوعين مع التقييمات
- `get_volunteer_management_data` - بيانات إدارة المتطوعين الشاملة

### 4. دوال المدير المتقدمة
- `get_manager_leaderboard_data` - بيانات لوحة القيادة الشاملة للمدير

### 5. دوال QR Code
- `scan_donor_qr_code` - مسح كود QR الخاص بالمتبرع
- `scan_association_qr_code` - مسح كود QR الخاص بالجمعية

### 6. دوال إنشاء أكواد التفعيل
- `generate_activation_code` - إنشاء كود تفعيل (يتم إنشاء الأكواد يدوياً في الكود حالياً)

## الدوال المفقودة من SQL ❌

### 1. دوال مطلوبة في الكود لكن غير موجودة في SQL
- `get_volunteer_dashboard_data` - مستخدمة في `volunteer_home.dart` لكن غير موجودة في ملف SQL

## التوصيات 📋

### 1. دوال يجب إضافتها للكود
```dart
// في volunteer_home.dart - استبدال get_volunteer_dashboard_data
// يمكن استخدام get_gamification_data بدلاً منها

// في association_volunteers.dart - إضافة استخدام
// get_volunteers_with_ratings للحصول على تقييمات أكثر تفصيلاً

// في manager screens - إضافة استخدام
// get_manager_leaderboard_data للحصول على إحصائيات شا��لة
// get_manager_map_data للخريطة المتقدمة

// إضافة QR Code scanning functionality
// scan_donor_qr_code و scan_association_qr_code
```

### 2. دوال يجب إضافتها لـ SQL
```sql
-- إضافة دالة get_volunteer_dashboard_data المفقودة
CREATE OR REPLACE FUNCTION get_volunteer_dashboard_data(p_user_id uuid)
RETURNS json AS $$
BEGIN
  RETURN (SELECT json_build_object(
    'userName', (SELECT full_name FROM users WHERE id = p_user_id),
    'total_tasks', (SELECT COUNT(*) FROM donations WHERE volunteer_id = p_user_id),
    'completed_tasks', (SELECT COUNT(*) FROM donations WHERE volunteer_id = p_user_id AND status = 'completed'),
    'in_progress_tasks', (SELECT COUNT(*) FROM donations WHERE volunteer_id = p_user_id AND status = 'in_progress'),
    'avg_rating', (SELECT COALESCE(AVG(rating), 0.0)::float FROM ratings WHERE volunteer_id = p_user_id),
    'next_task', (SELECT row_to_json(d) FROM (SELECT * FROM donations WHERE volunteer_id = p_user_id AND status = 'assigned' ORDER BY created_at LIMIT 1) d)
  ));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 3. تحسينات مقترحة
1. **استخدام generate_activation_code**: استبدال الكود اليدوي في `association_activation_codes.dart`
2. **إضافة QR Code scanning**: تطبيق دوال مسح QR في تفاصيل المهام
3. **تحسين الخرائط**: استخدام دوال الخريطة المتقدمة
4. **إضافة التحفيز**: استخدام `get_gamification_data` لعرض بيانات أكثر تفصيلاً

## ملخص الحالة
- **دوال مستخدمة**: 14 دالة
- **دوال غير مستخدمة**: 11 دالة  
- **دوال مفقودة**: 1 دالة
- **نسبة الاستخدام**: 56% من دوال SQL مستخدمة في الكود