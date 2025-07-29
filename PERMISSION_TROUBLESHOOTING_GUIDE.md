# دليل إصلاح مشكلة صلاحيات قاعدة البيانات
# Database Permission Troubleshooting Guide

## المشكلة / Problem
```
PostgrestException(message: permission denied for schema public, code: 42501)
```

## الحل السريع / Quick Solution

### الخطوة 1: تشغيل الإصلاح البسيط
في Supabase SQL Editor، قم بتشغيل:
```sql
-- انسخ والصق محتوى ملف simple_permission_fix.sql
```

### الخطوة 2: اختبار الاتصال
```sql
-- اختبار بسيط
SELECT current_user, current_database();
SELECT * FROM public.users LIMIT 1;
```

## الأسباب المحتملة / Possible Causes

1. **نقص صلاحيات المخطط العام** - Missing public schema permissions
2. **سياسات RLS صارمة جداً** - Overly restrictive RLS policies  
3. **نقص صلاحيات الجداول** - Missing table permissions
4. **نقص صلاحيات الدوال** - Missing function permissions
5. **مشاكل في إعدادات Supabase** - Supabase configuration issues

## خطوات الإصلاح التفصيلية / Detailed Fix Steps

### الخطوة 1: فحص إعدادات Supabase

1. **افتح Supabase Dashboard**
2. **اذهب إلى Settings > API**
3. **تأكد من صحة:**
   - Project URL
   - anon/public key
   - service_role key (إذا كنت تستخدمه)

### الخطوة 2: فحص متغيرات البيئة

تأكد من أن ملف `.env` يحتوي على:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### الخطوة 3: تطبيق إصلاحات الصلاحيات

#### الإصلاح البسيط (مُوصى به):
```sql
-- في Supabase SQL Editor
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon;

-- تعطيل RLS مؤقتاً للاختبار
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.donations DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.activation_codes DISABLE ROW LEVEL SECURITY;
```

#### الإصلاح الشامل:
```sql
-- استخدم ملف fix_database_permissions.sql
-- (بعد إصلاح مشكلة IF NOT EXISTS)
```

### الخطوة 4: إعادة تشغيل التطبيق

```bash
flutter clean
flutter pub get
flutter run
```

## اختبار الحلول / Testing Solutions

### اختبار 1: فحص الصلاحيات الأساسية
```sql
SELECT 
    has_schema_privilege('authenticated', 'public', 'USAGE') as auth_schema,
    has_table_privilege('authenticated', 'public.users', 'SELECT') as auth_users,
    has_function_privilege('authenticated', 'public.register_volunteer(uuid,text,text,text,text,text)', 'EXECUTE') as auth_function;
```

### اختبار 2: فحص RLS
```sql
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';
```

### اختبار 3: فحص الجداول
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';
```

## معالجة الأخطاء في الكود / Error Handling in Code

### تحسين معالجة الأخطاء:
```dart
try {
  final response = await Supabase.instance.client
      .from('users')
      .select();
} on PostgrestException catch (e) {
  print('Database error: ${e.message}');
  print('Error code: ${e.code}');
  
  // معالجة خاصة لخطأ الصلاحيات
  if (e.code == '42501') {
    print('Permission denied - check database permissions');
    // يمكن إظهار رسالة للمستخدم أو إعادة المحاولة
  }
} catch (e) {
  print('General error: $e');
}
```

### تحسين إعداد Supabase:
```dart
// في main.dart
try {
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    debug: true, // لإظهار تفاصيل أكثر في التطوير
  );
} catch (e) {
  print('Supabase initialization failed: $e');
}
```

## إعادة تفعيل RLS بأمان / Safely Re-enabling RLS

بعد حل المشكلة، يمكن إعادة تفعيل RLS مع سياسات مناسبة:

```sql
-- إعادة تفعيل RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- إنشاء سياسة أساسية
DROP POLICY IF EXISTS "Users can view own data" ON public.users;
CREATE POLICY "Users can view own data" ON public.users
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own data" ON public.users;
CREATE POLICY "Users can update own data" ON public.users
    FOR UPDATE USING (auth.uid() = id);
```

## ��صائح الأمان / Security Tips

1. **لا تعطل RLS في الإنتاج** - Don't disable RLS in production
2. **استخدم أقل الصلاحيات المطلوبة** - Use least required permissions
3. **اختبر الإصلاحات في بيئة التطوير أولاً** - Test fixes in development first
4. **راجع السياسات بانتظام** - Review policies regularly

## إذا استمرت المشكلة / If Problem Persists

1. **تحقق من سجلات Supabase** في Dashboard > Logs
2. **جرب إنشاء مشروع جديد** للاختبار
3. **تواصل مع دعم Supabase** مع تفاصيل الخطأ
4. **تحقق من حدود الاستخدام** في Dashboard

## ملفات مفيدة في المشروع / Useful Project Files

- `simple_permission_fix.sql` - إصلاح سريع وبسيط
- `fix_database_permissions.sql` - إصلاح شامل
- `diagnose_permissions.sql` - تشخيص المشاكل
- `.env` - متغيرات البيئة
- `supabase_config.dart` - إعدادات Supabase

---

**تاريخ التحديث:** 2025-01-23
**الإصدار:** 1.1
**المؤلف:** qodo AI Assistant