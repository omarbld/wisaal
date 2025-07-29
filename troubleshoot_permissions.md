# حل مشكلة PostgreSQL Permission Denied

## المشكلة
```
PostgrestException(message: permission denied for schema: public, code: 42501, details: , hint: null)
```

## الأسباب المحتملة
1. المستخدم لا يملك صلاحيات على schema public
2. Row Level Security (RLS) يمنع الوصول
3. مشكلة في إعدادات Supabase
4. المستخدم غير مصرح له بالوصول للجداول

## الحلول

### الحل الأول: تشغيل ملف إصلاح الصلاحيات
```bash
# إذا كنت تستخدم PostgreSQL محلياً
psql -U postgres -d your_database -f fix_permissions.sql

# إذا كنت تستخدم Supabase
# استخدم SQL Editor في لوحة تحكم Supabase وانسخ محتوى fix_permissions.sql
```

### الحل الثاني: أوامر سريعة لإصلاح الصلاحيات
```sql
-- إعطاء صلاحيات أساسية
GRANT USAGE ON SCHEMA public TO PUBLIC;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO PUBLIC;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO PUBLIC;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO PUBLIC;

-- إعطاء صلاحيات لأدوار Supabase
GRANT ALL ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
```

### الحل الثالث: تعطيل RLS مؤقتاً
```sql
-- تعطيل RLS على الجداول الرئيسية
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE donations DISABLE ROW LEVEL SECURITY;
ALTER TABLE activation_codes DISABLE ROW LEVEL SECURITY;
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;
```

### الحل الرابع: إنشاء سياسات RLS أكثر مرونة
```sql
-- سياسة للقراءة العامة
CREATE POLICY "allow_public_read" ON users FOR SELECT USING (true);
CREATE POLICY "allow_public_read" ON donations FOR SELECT USING (true);
CREATE POLICY "allow_public_read" ON activation_codes FOR SELECT USING (true);
```

### الحل الخامس: للمطورين - إعدادات Supabase
1. اذهب إلى لوحة تحكم Supabase
2. انتقل إلى Settings > Database
3. تأكد من أن RLS مفعل بشكل صحيح
4. تحقق من أن المستخدم لديه الأدوار المناسبة

### الحل السادس: التحقق من الاتصال
```sql
-- التحقق من المستخدم الحالي
SELECT current_user, current_database();

-- التحقق من الصلاحيات
SELECT grantee, privilege_type 
FROM information_schema.schema_privileges 
WHERE schema_name = 'public';

-- التحقق من RLS
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';
```

## خطوات استكشاف الأخطاء

### الخطوة 1: تحديد نوع المشكلة
```sql
-- تشغيل هذا الاستعلام لمعرفة المشكلة
SELECT 
    current_user as current_user,
    current_database() as current_database,
    has_schema_privilege('public', 'USAGE') as can_use_schema,
    has_schema_privilege('public', 'CREATE') as can_create_in_schema;
```

### الخطوة 2: التحقق من الجداول
```sql
-- التحقق من وجود الجداول
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';
```

### الخطوة 3: التحقق من الصلاحيات على جدول معين
```sql
-- استبدل 'users' باسم الجدول المطلوب
SELECT grantee, privilege_type 
FROM information_schema.table_privileges 
WHERE table_schema = 'public' AND table_name = 'users';
```

## حلول خاصة بـ Supabase

### إعداد المصادقة
```javascript
// في كود JavaScript/TypeScript
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'YOUR_SUPABASE_URL'
const supabaseKey = 'YOUR_SUPABASE_ANON_KEY' // استخدم service_role key للعمليات الإدارية

const supabase = createClient(supabaseUrl, supabaseKey)
```

### استخدام Service Role Key
```javascript
// للعمليات التي تتطلب صلاحيات عالية
const supabaseAdmin = createClient(
  'YOUR_SUPABASE_URL',
  'YOUR_SERVICE_ROLE_KEY'
)
```

## اختبار الحل

### اختبار الاتصال
```sql
-- اختبار بسيط للقراءة
SELECT COUNT(*) FROM users;

-- اختبار الكتابة
INSERT INTO users (full_name, email, role) 
VALUES ('Test User', 'test@example.com', 'donor');
```

### اختبار الدوال
```sql
-- اختبار دالة
SELECT get_website_statistics();
```

## نصائح إضافية

1. **استخدم المستخدم الصحيح**: تأكد من أنك تستخدم مستخدم له صلاحيات كافية
2. **تحقق من RLS**: إذا كان RLS مفعل، تأكد من وجود سياسات مناسبة
3. **استخدم Service Role**: في Supabase، استخدم service_role key للعمليات الإدارية
4. **راجع الأخطاء**: اقرأ رسائل الخطأ بعناية لفهم المشكلة بدقة

## إذا استمرت المشكلة

1. تواصل مع فريق دعم Supabase إذا كنت تستخدمه
2. تحقق من إعدادات قاعدة البيانات
3. راجع سجلات الأخطاء للحصول على تفاصيل أكثر
4. جرب إنشاء مستخدم جديد بصلاحيات كاملة

## أوامر مفيدة للتشخيص

```sql
-- عرض جميع الأدوار
\du

-- عرض صلاحيات الجداول
\dp

-- عرض معلومات قاعدة البيانات
\l

-- عرض الجداول
\dt

-- عرض الدوال
\df
```