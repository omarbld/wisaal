# تقرير إصلاح مشكلة أعمدة الموقع (Location Columns Fix Report)

## المشكلة الأصلية
```
PostgrestException(message: column donations.latitude does not exist, code: 42703)
```

## سبب المشكلة
- جدول `donations` في قاعدة البيانات يستخدم عمود `location` من نوع `geography(Point, 4326)` لتخزين الإحداثيات
- الكود في التطبيق كان يحاول الوصول إلى أعمدة `latitude` و `longitude` منفصلة غير موجودة
- هذا تسبب في خطأ PostgreSQL عند محاولة تنفيذ الاستعلامات

## الحل المطبق

### 1. إنشاء دوال SQL لاستخراج الإحداثيات
تم إنشاء ملف `fix_location_columns.sql` يحتوي على:

#### دوال استخراج الإحداثيات:
```sql
-- دالة لاستخراج latitude من عمود location
CREATE OR REPLACE FUNCTION get_latitude_from_location(location_geom geography)
RETURNS double precision AS $$
BEGIN
  IF location_geom IS NULL THEN
    RETURN NULL;
  END IF;
  RETURN ST_Y(location_geom::geometry);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- دالة لاستخراج longitude من عمود location
CREATE OR REPLACE FUNCTION get_longitude_from_location(location_geom geography)
RETURNS double precision AS $$
BEGIN
  IF location_geom IS NULL THEN
    RETURN NULL;
  END IF;
  RETURN ST_X(location_geom::geometry);
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

#### Views مع الإحداثيات:
```sql
-- إنشاء view لجدول donations مع أعمدة latitude و longitude
CREATE OR REPLACE VIEW donations_with_coordinates AS
SELECT 
  *,
  get_latitude_from_location(location) as latitude,
  get_longitude_from_location(location) as longitude
FROM donations;

-- إنشاء view لجدول users مع أعمدة latitude و longitude
CREATE OR REPLACE VIEW users_with_coordinates AS
SELECT 
  *,
  get_latitude_from_location(location) as latitude,
  get_longitude_from_location(location) as longitude
FROM users;
```

#### دوال محدثة للخرائط:
```sql
-- دالة محدثة للحصول على بيانات الخريطة مع الإحداثيات
CREATE OR REPLACE FUNCTION get_map_data_with_coordinates(p_user_role text, p_user_id uuid DEFAULT NULL)
RETURNS TABLE(
  id uuid,
  title text,
  latitude double precision,
  longitude double precision,
  status text,
  food_type text,
  quantity int,
  is_urgent boolean,
  created_at timestamptz,
  marker_type text
) AS $$
-- ... implementation
```

### 2. تحديث الكود في التطبيق

#### تحديث `lib/association/association_home.dart`:

**قبل الإصلاح:**
```dart
final donationsWithLocationFuture = supabase.from('donations').select('latitude, longitude, title').not('latitude', 'is', null).not('longitude', 'is', null);
```

**بعد الإصلاح:**
```dart
final donationsWithLocationFuture = supabase
    .from('donations_with_coordinates')
    .select('title, latitude, longitude')
    .not('latitude', 'is', null)
    .not('longitude', 'is', null);
```

#### تحديث دالة `_buildMap`:

**قبل الإصلاح:**
```dart
Widget _buildMap(BuildContext context, List<Map<String, dynamic>> donations) {
  final markers = donations.where((donation) => donation['location'] != null).map((donation) {
    // Parse PostGIS location format: "POINT(longitude latitude)"
    final locationStr = donation['location'] as String;
    final coords = locationStr.replaceAll('POINT(', '').replaceAll(')', '').split(' ');
    if (coords.length >= 2) {
      final longitude = double.tryParse(coords[0]) ?? 0.0;
      final latitude = double.tryParse(coords[1]) ?? 0.0;
      
      return Marker(
        markerId: MarkerId(donation['title']),
        position: LatLng(latitude, longitude),
        infoWindow: InfoWindow(title: donation['title']),
      );
    }
    return null;
  }).where((marker) => marker != null).cast<Marker>().toSet();
  // ...
}
```

**بعد الإصلاح:**
```dart
Widget _buildMap(BuildContext context, List<Map<String, dynamic>> donations) {
  final markers = donations
      .where((donation) =>
          donation['latitude'] != null && donation['longitude'] != null)
      .map((donation) {
    final latitude = donation['latitude'] as double;
    final longitude = donation['longitude'] as double;

    return Marker(
      markerId: MarkerId(donation['title']),
      position: LatLng(latitude, longitude),
      infoWindow: InfoWindow(title: donation['title']),
    );
  }).toSet();
  // ...
}
```

## الملفات المتأثرة

### ملفات تم إنشاؤها:
- `fix_location_columns.sql` - يحتوي على الدوال والـ Views الجديدة

### ملفات تم تحديثها:
- `lib/association/association_home.dart` - تحديث الاستعلامات ودالة الخريطة

### ملفات تم فحصها (لا تحتاج تحديث):
- `lib/volunteer/donations_map_page.dart` - يستخدم بيانات وهمية
- `lib/manager/donations_map_page.dart` - يتعامل مع البيانات بشكل صحيح
- `lib/donor/donations_map_page.dart` - يتعامل مع البيانات بشكل صحيح باستخدام `location['coordinates']`

## الخطوات المطلوبة للتطبيق

### 1. تنفيذ ملف SQL في قاعدة البيانات
```bash
# قم بتنفيذ الملف في Supabase SQL Editor أو PostgreSQL
psql -d your_database -f fix_location_columns.sql
```

أو انسخ محتوى ملف `fix_location_columns.sql` وقم بتنفيذه في Supabase SQL Editor.

### 2. التحقق من إنشاء الدوال والـ Views
```sql
-- التحقق من وجود الدوال
SELECT proname FROM pg_proc WHERE proname LIKE '%location%';

-- التحقق من وجود الـ Views
SELECT viewname FROM pg_views WHERE viewname LIKE '%coordinates%';

-- اختبار الـ View الجديد
SELECT title, latitude, longitude FROM donations_with_coordinates LIMIT 5;
```

### 3. إعادة تشغيل التطبيق
بعد تطبيق التحديثات، قم بإعادة تشغيل التطبيق للتأكد من عمل الخرائط بشكل صحيح.

## الفوائد من هذا الحل

### 1. التوافق مع PostGIS
- يحافظ على استخدام PostGIS للبيانات الجغرافية
- يستفيد من ميزات PostGIS المتقدمة للاستعلامات المكانية

### 2. سهولة الاستخدام
- يوفر أعمدة `latitude` و `longitude` منفصلة للتطبيق
- لا يتطلب تغييرات كبيرة في الكود الموجود

### 3. الأداء
- الدوال محددة كـ `IMMUTABLE` لتحسين الأداء
- الـ Views تسمح بإعادة الاستخدام السهل

### 4. المرونة
- يمكن استخدام الـ Views في أي مكان في التطبيق
- يمكن إضافة المزيد من الدوال الجغرافية حسب الحاجة

## ملاحظات مهمة

### 1. صلاحيات قاعدة البيانات
تأكد من أن المستخدم `authenticated` لديه صلاحيات للوصول إلى:
- الدوال الجديدة
- الـ Views الجديدة
- جداول `donations` و `users`

### 2. Row Level Security (RLS)
الـ Views ترث سياسات RLS من الجداول الأصلية، لذا لا حاجة لإعداد سياسات إضافية.

### 3. النسخ الاحتياطية
تأكد من أخذ نسخة احتياطية من قاعدة البيانات قبل تطبيق التغييرات.

## الاختبار

### 1. اختبار الدوال
```sql
-- اختبار دالة latitude
SELECT get_latitude_from_location(ST_GeogFromText('POINT(-7.603869 33.589886)'));

-- اختبار دالة longitude  
SELECT get_longitude_from_location(ST_GeogFromText('POINT(-7.603869 33.589886)'));
```

### 2. اختبار الـ Views
```sql
-- اختبار view التبرعات
SELECT donation_id, title, latitude, longitude 
FROM donations_with_coordinates 
WHERE latitude IS NOT NULL 
LIMIT 10;

-- اختبار view المستخدمين
SELECT id, full_name, role, latitude, longitude 
FROM users_with_coordinates 
WHERE latitude IS NOT NULL 
LIMIT 10;
```

### 3. اختبار التطبيق
- افتح صفحة الجمعية الرئيسية
- تحقق من ظهور الخريطة بدون أخطاء
- تأكد من ظهور العلامات على الخريطة

## الخلاصة
تم حل مشكلة `donations.latitude does not exist` بنجاح من خلال:
1. إنشاء دوال SQL لاستخراج الإحداثيات من عمود PostGIS
2. إنشاء Views تحتوي على أعمدة latitude و longitude
3. تحديث الكود في التطبيق لاستخدام الـ Views الجديدة
4. الحفاظ على التوافق مع PostGIS وميزاته المتقدمة

هذا الحل يوفر طريقة نظيفة ومرنة للتعامل مع البيانات الجغرافية في التطبيق.
