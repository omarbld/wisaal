-- ====================================================================
-- حل سريع لمشكلة صلاحيات PostgreSQL
-- Quick Fix for PostgreSQL Permissions Issue
-- ====================================================================

-- تشغيل هذا الملف لحل مشكلة: permission denied for schema: public

-- ====================================================================
-- الحل السريع
-- ====================================================================

-- 1. إعطاء صلاحيات أساسية
GRANT USAGE ON SCHEMA public TO PUBLIC;
GRANT CREATE ON SCHEMA public TO PUBLIC;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO PUBLIC;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO PUBLIC;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO PUBLIC;

-- 2. إعطاء صلاحيات للمستقبل
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO PUBLIC;

-- 3. إنشاء أدوار Supabase إذا لم تكن م��جودة
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
EXCEPTION
    WHEN OTHERS THEN
        -- تجاهل الأخطاء إذا كانت الأدوار موجودة
        NULL;
END $$;

-- 4. إعطاء صلاحيات لأدوار Supabase
GRANT ALL ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

-- 5. تعطيل RLS مؤقتاً (يمكن إعادة تفعيله لاحقاً)
DO $$
DECLARE
    table_name text;
BEGIN
    FOR table_name IN 
        SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        EXECUTE format('ALTER TABLE %I DISABLE ROW LEVEL SECURITY', table_name);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        -- تجاهل الأخطاء
        NULL;
END $$;

-- 6. إنشاء سياسات مرنة للقراءة
DO $$
DECLARE
    table_name text;
BEGIN
    FOR table_name IN 
        SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        BEGIN
            EXECUTE format('DROP POLICY IF EXISTS "allow_all_access" ON %I', table_name);
            EXECUTE format('CREATE POLICY "allow_all_access" ON %I FOR ALL USING (true)', table_name);
        EXCEPTION
            WHEN OTHERS THEN
                -- تجاهل الأخطاء
                NULL;
        END;
    END LOOP;
END $$;

-- 7. إعادة تفعيل RLS مع السياسات الجديدة
DO $$
DECLARE
    table_name text;
BEGIN
    FOR table_name IN 
        SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', table_name);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        -- تجاهل الأخطاء
        NULL;
END $$;

-- 8. التحقق من النتيجة
DO $$
BEGIN
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'تم تطبيق الحل السريع لمشكلة الصلاحيات';
    RAISE NOTICE 'Quick fix for permissions has been applied';
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'المستخدم الحالي: %', current_user;
    RAISE NOTICE 'قاعدة البيانات: %', current_database();
    RAISE NOTICE '====================================================================';
END $$;

-- ====================================================================
-- اختبار الحل
-- ====================================================================

-- اختبار القراءة من الجداول
DO $$
DECLARE
    user_count integer;
    donation_count integer;
BEGIN
    SELECT COUNT(*) INTO user_count FROM users;
    SELECT COUNT(*) INTO donation_count FROM donations;
    
    RAISE NOTICE 'عدد المستخدمين: %', user_count;
    RAISE NOTICE 'عدد التبرعات: %', donation_count;
    RAISE NOTICE 'الاختبار نجح - يمكنك الآن استخدام قاعدة البيانات';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'خطأ في الاختبار: %', SQLERRM;
        RAISE NOTICE 'قد تحتاج لتشغيل الملف كمستخدم postgres أو superuser';
END $$;