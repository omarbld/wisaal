-- ====================================================================
-- حل مشكلة صلاحيات PostgreSQL
-- Fix PostgreSQL Permissions Issue
-- ====================================================================

-- هذا الملف يحل مشكلة: permission denied for schema: public

-- ====================================================================
-- الجزء الأول: إعطاء صلاحيات أساسية للمستخدمين
-- Part 1: Grant Basic Permissions to Users
-- ====================================================================

-- إعطاء صلاحيات للمستخدم الحالي على schema public
GRANT USAGE ON SCHEMA public TO PUBLIC;
GRANT CREATE ON SCHEMA public TO PUBLIC;

-- إعطاء صلاحيات على جميع الجداول الموجودة
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO PUBLIC;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO PUBLIC;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO PUBLIC;

-- إعطاء صلاحيات على الجداول المستقبلية
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO PUBLIC;

-- ====================================================================
-- الجزء الثاني: إعطاء صلاحيات خاصة لـ Supabase
-- Part 2: Grant Special Permissions for Supabase
-- ====================================================================

-- إنشاء أدوار Supabase إذا لم تكن موجودة
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        CREATE ROLE anon;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        CREATE ROLE authenticated;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        CREATE ROLE service_role;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_admin') THEN
        CREATE ROLE supabase_admin;
    END IF;
END $$;

-- إعطاء صلاحيات لأدوار Supabase
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role, supabase_admin;
GRANT ALL ON SCHEMA public TO service_role, supabase_admin;

-- صلاحيات الجداول
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO service_role, supabase_admin;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;

-- صلاحيات التسلسلات
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO service_role, supabase_admin;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- صلاحيات الدوال
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO service_role, supabase_admin;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- ====================================================================
-- الجزء الثالث: إعطاء صلاحيات خاصة للجداول المهمة
-- Part 3: Grant Special Permissions for Important Tables
-- ====================================================================

-- صلاحيات خاصة لجدول المستخدمين
GRANT ALL ON users TO service_role, supabase_admin;
GRANT SELECT, INSERT, UPDATE ON users TO authenticated;
GRANT SELECT ON users TO anon;

-- صلاحيات خاصة لجدول التبرعات
GRANT ALL ON donations TO service_role, supabase_admin;
GRANT SELECT, INSERT, UPDATE ON donations TO authenticated;
GRANT SELECT ON donations TO anon;

-- صلاحيات خاصة لجدول أكواد التفعيل
GRANT ALL ON activation_codes TO service_role, supabase_admin;
GRANT SELECT, UPDATE ON activation_codes TO authenticated;
GRANT SELECT ON activation_codes TO anon;

-- صلاحيات خاصة لجدول الإشعارات
GRANT ALL ON notifications TO service_role, supabase_admin;
GRANT SELECT, INSERT, UPDATE ON notifications TO authenticated;

-- صلاحيات خاصة لجدول التقييمات
GRANT ALL ON ratings TO service_role, supabase_admin;
GRANT SELECT, INSERT ON ratings TO authenticated;

-- ====================================================================
-- الجزء الرابع: إعطاء صلاحيات للدوال المهمة
-- Part 4: Grant Permissions for Important Functions
-- ====================================================================

-- دوال التحقق من أكواد التفعيل
GRANT EXECUTE ON FUNCTION check_activation_code(text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION is_activation_code_valid(text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_activation_code_details(text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION use_activation_code_for_user(uuid, text) TO anon, authenticated;

-- دوال إدارة المستخدمين
GRANT EXECUTE ON FUNCTION get_user_role(uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION register_volunteer(uuid, text, text, text, text, text) TO anon, authenticated;

-- دوال الموقع الجغرافي
GRANT EXECUTE ON FUNCTION update_user_location(double precision, double precision) TO authenticated;
GRANT EXECUTE ON FUNCTION update_user_location_safe(double precision, double precision) TO authenticated;

-- دوال الإحصائيات
GRANT EXECUTE ON FUNCTION get_website_statistics() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_leaderboard() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_full_leaderboard() TO anon, authenticated;

-- ====================================================================
-- الجزء الخامس: إصلاح مشاكل RLS المحتملة
-- Part 5: Fix Potential RLS Issues
-- ====================================================================

-- تعطيل RLS مؤقتاً للاختبار (يمكن إعادة تفعيله لاحقاً)
-- ALTER TABLE users DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE donations DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE activation_codes DISABLE ROW LEVEL SECURITY;

-- أو إضافة سياسات أكثر مرونة
DROP POLICY IF EXISTS "Allow public read for testing" ON users;
CREATE POLICY "Allow public read for testing" ON users
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow public read for testing" ON donations;
CREATE POLICY "Allow public read for testing" ON donations
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow public read for testing" ON activation_codes;
CREATE POLICY "Allow public read for testing" ON activation_codes
  FOR SELECT USING (true);

-- ====================================================================
-- الجزء السادس: إعطاء صلاحيات للمستخدم الحالي
-- Part 6: Grant Permissions to Current User
-- ====================================================================

-- إعطاء صلاحيات للمستخدم الحالي
DO $$
DECLARE
    current_user_name text;
BEGIN
    SELECT current_user INTO current_user_name;
    
    -- إعطاء صلاحيات المالك للمستخدم الحالي
    EXECUTE format('GRANT ALL PRIVILEGES ON SCHEMA public TO %I', current_user_name);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO %I', current_user_name);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO %I', current_user_name);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO %I', current_user_name);
    
    RAISE NOTICE 'تم إعطاء صلاحيات للمستخدم: %', current_user_name;
END $$;

-- ====================================================================
-- الجزء السابع: إعطاء صلاحيات postgres
-- Part 7: Grant postgres Permissions
-- ====================================================================

-- إعطاء صلاحيات لمستخدم postgres
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'postgres') THEN
        GRANT ALL PRIVILEGES ON SCHEMA public TO postgres;
        GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
        GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
        GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO postgres;
        
        RAISE NOTICE 'تم إعطاء صلاحيات لمستخدم postgres';
    END IF;
END $$;

-- ====================================================================
-- الجزء الثامن: التحقق من الصلاحيات
-- Part 8: Verify Permissions
-- ====================================================================

-- عرض الصلاحيات الحالية
DO $$
DECLARE
    rec RECORD;
BEGIN
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'التحقق من الصلاحيات الحالية:';
    RAISE NOTICE '====================================================================';
    
    -- عرض صلاحيات schema
    FOR rec IN 
        SELECT grantee, privilege_type 
        FROM information_schema.schema_privileges 
        WHERE schema_name = 'public'
    LOOP
        RAISE NOTICE 'Schema public - المستخدم: %, الصلاحية: %', rec.grantee, rec.privilege_type;
    END LOOP;
    
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'تم الانتهاء من إصلاح الصلاحيات';
    RAISE NOTICE '====================================================================';
END $$;

-- ====================================================================
-- الجزء التاسع: إعادة تحميل الصلاحيات
-- Part 9: Reload Privileges
-- ====================================================================

-- إعادة تحميل الصلاحيات
SELECT pg_reload_conf();

-- ====================================================================
-- تعليمات الاستخدام
-- Usage Instructions
-- ====================================================================

/*
لحل مشكلة الصلاحيات، قم بتنفيذ الخطوات التالية:

1. تشغيل هذا الملف كمستخدم postgres أو superuser:
   psql -U postgres -d your_database -f fix_permissions.sql

2. إذا كنت تستخدم Supabase، تأكد من أن المستخدم لديه صلاحيات كافية

3. إذا استمرت المشكلة، جرب تشغيل الأوامر التالية:
   GRANT ALL PRIVILEGES ON DATABASE your_database TO your_user;
   GRANT ALL PRIVILEGES ON SCHEMA public TO your_user;

4. للتحقق من الصلاحيات:
   \dp في psql لعرض صلاحيات الجداول
   \dn+ لعرض صلاحيات schemas

5. إذا كنت تستخدم RLS وتواجه مشاكل، يمكنك تعطيله مؤقتاً:
   ALTER TABLE table_name DISABLE ROW LEVEL SECURITY;
*/

-- ====================================================================
-- نهاية ملف إصلاح الصلاحيات
-- End of Permissions Fix File
-- ====================================================================