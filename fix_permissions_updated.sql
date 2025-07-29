-- ====================================================================
-- حل محدث لمشكلة صلاحيات PostgreSQL
-- Updated Fix for PostgreSQL Permissions Issue
-- ====================================================================

-- هذا الملف يحل مشكلة: permission denied for schema: public
-- ويتجنب مشكلة information_schema.schema_privileges

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
    -- إنشاء دور anon
    BEGIN
        CREATE ROLE anon;
        RAISE NOTICE 'تم إنشاء دور anon';
    EXCEPTION
        WHEN duplicate_object THEN
            RAISE NOTICE 'دور anon موجود مسبقاً';
    END;
    
    -- إنشاء دور authenticated
    BEGIN
        CREATE ROLE authenticated;
        RAISE NOTICE 'تم إنشاء دور authenticated';
    EXCEPTION
        WHEN duplicate_object THEN
            RAISE NOTICE 'دور authenticated موجود مسبقاً';
    END;
    
    -- إنشاء دور service_role
    BEGIN
        CREATE ROLE service_role;
        RAISE NOTICE 'تم إنشاء دور service_role';
    EXCEPTION
        WHEN duplicate_object THEN
            RAISE NOTICE 'دور service_role موجود مسبقاً';
    END;
    
    -- إنشاء دور supabase_admin
    BEGIN
        CREATE ROLE supabase_admin;
        RAISE NOTICE 'تم إنشاء دور supabase_admin';
    EXCEPTION
        WHEN duplicate_object THEN
            RAISE NOTICE 'دور supabase_admin موجود مسبقاً';
    END;
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

-- التحقق من وجود الجداول قبل إعطاء الصلاحيات
DO $$
DECLARE
    table_exists boolean;
BEGIN
    -- جدول المستخدمين
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'users'
    ) INTO table_exists;
    
    IF table_exists THEN
        GRANT ALL ON users TO service_role, supabase_admin;
        GRANT SELECT, INSERT, UPDATE ON users TO authenticated;
        GRANT SELECT ON users TO anon;
        RAISE NOTICE 'تم إعطاء صلاحيات لجدول users';
    ELSE
        RAISE NOTICE 'جدول users غير موجود';
    END IF;
    
    -- جدول التبرعات
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'donations'
    ) INTO table_exists;
    
    IF table_exists THEN
        GRANT ALL ON donations TO service_role, supabase_admin;
        GRANT SELECT, INSERT, UPDATE ON donations TO authenticated;
        GRANT SELECT ON donations TO anon;
        RAISE NOTICE 'تم إعطاء صلاحيات لجدول donations';
    ELSE
        RAISE NOTICE 'جدول donations غير موجود';
    END IF;
    
    -- جدول أكواد التفعيل
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'activation_codes'
    ) INTO table_exists;
    
    IF table_exists THEN
        GRANT ALL ON activation_codes TO service_role, supabase_admin;
        GRANT SELECT, UPDATE ON activation_codes TO authenticated;
        GRANT SELECT ON activation_codes TO anon;
        RAISE NOTICE 'تم إعطاء صلاحيات لجدول activation_codes';
    ELSE
        RAISE NOTICE 'جدول activation_codes غير موجود';
    END IF;
END $$;

-- ====================================================================
-- الجزء الرابع: إعطاء صلاحيات للدوال المهمة
-- Part 4: Grant Permissions for Important Functions
-- ====================================================================

-- التحقق من وجود الدوال قبل إعطاء الصلاحيات
DO $$
DECLARE
    function_exists boolean;
BEGIN
    -- دالة التحقق من كود التفعيل
    SELECT EXISTS (
        SELECT FROM information_schema.routines 
        WHERE routine_schema = 'public' AND routine_name = 'check_activation_code'
    ) INTO function_exists;
    
    IF function_exists THEN
        GRANT EXECUTE ON FUNCTION check_activation_code(text) TO anon, authenticated;
        RAISE NOTICE 'تم إعطاء صلاحيات لدالة check_activation_code';
    END IF;
    
    -- دالة get_user_role
    SELECT EXISTS (
        SELECT FROM information_schema.routines 
        WHERE routine_schema = 'public' AND routine_name = 'get_user_role'
    ) INTO function_exists;
    
    IF function_exists THEN
        GRANT EXECUTE ON FUNCTION get_user_role(uuid) TO anon, authenticated;
        RAISE NOTICE 'تم إعطاء صلاحيات لدالة get_user_role';
    END IF;
END $$;

-- ====================================================================
-- الجزء الخامس: إصلاح مشاكل RLS المحتملة
-- Part 5: Fix Potential RLS Issues
-- ====================================================================

-- إضافة سياسات أكثر مرونة للجداول الموجودة
DO $$
DECLARE
    table_record RECORD;
BEGIN
    FOR table_record IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public'
    LOOP
        BEGIN
            -- حذف السياسة إذا كانت موجودة
            EXECUTE format('DROP POLICY IF EXISTS "allow_public_access" ON %I', table_record.tablename);
            
            -- إنشاء سياسة جديدة للوصول العام
            EXECUTE format('CREATE POLICY "allow_public_access" ON %I FOR ALL USING (true)', table_record.tablename);
            
            RAISE NOTICE 'تم إنشاء سياسة للجدول: %', table_record.tablename;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'خطأ في إنشاء سياسة للجدول %: %', table_record.tablename, SQLERRM;
        END;
    END LOOP;
END $$;

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
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'خطأ في إعطاء صلاحيات للمستخدم الحالي: %', SQLERRM;
END $$;

-- ====================================================================
-- الجزء السابع: التحقق من الصلاحيات باستخدام pg_class
-- Part 7: Verify Permissions using pg_class
-- ====================================================================

-- عرض الصلاحيات الحالية باستخدام pg_class بدلاً من information_schema
DO $$
DECLARE
    rec RECORD;
    table_count integer;
    function_count integer;
BEGIN
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'التحقق من الصلاحيات الحالية:';
    RAISE NOTICE '====================================================================';
    
    -- عدد الجداول
    SELECT COUNT(*) INTO table_count
    FROM pg_tables 
    WHERE schemaname = 'public';
    
    RAISE NOTICE 'عدد الجداول في schema public: %', table_count;
    
    -- عدد الدوال
    SELECT COUNT(*) INTO function_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public';
    
    RAISE NOTICE 'عدد الدوال في schema public: %', function_count;
    
    -- عرض أسماء الجداول
    RAISE NOTICE 'الجداول الموجودة:';
    FOR rec IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public'
        ORDER BY tablename
    LOOP
        RAISE NOTICE '  - %', rec.tablename;
    END LOOP;
    
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'تم الانتهاء من إصلاح الصلاحيات';
    RAISE NOTICE 'المستخدم الحالي: %', current_user;
    RAISE NOTICE 'قاعدة البيانات الحالية: %', current_database();
    RAISE NOTICE '====================================================================';
END $$;

-- ====================================================================
-- الجزء الثامن: اختبار الوصول للجداول
-- Part 8: Test Table Access
-- ====================================================================

-- اختبار الوصول للجداول الرئيسية
DO $$
DECLARE
    test_count integer;
    table_name text;
    tables_to_test text[] := ARRAY['users', 'donations', 'activation_codes', 'notifications'];
BEGIN
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'اختبار الوصول للجداول:';
    RAISE NOTICE '====================================================================';
    
    FOREACH table_name IN ARRAY tables_to_test
    LOOP
        BEGIN
            EXECUTE format('SELECT COUNT(*) FROM %I', table_name) INTO test_count;
            RAISE NOTICE 'جدول % - العدد: % ✓', table_name, test_count;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'جدول % - خطأ: % ✗', table_name, SQLERRM;
        END;
    END LOOP;
    
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'انتهى الاختبار';
    RAISE NOTICE '====================================================================';
END $$;

-- ====================================================================
-- نهاية ملف إصلاح الصلاحيات المحدث
-- End of Updated Permissions Fix File
-- ====================================================================