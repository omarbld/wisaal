-- ====================================================================
-- تشخيص حالة قاعدة البيانات والصلاحيات
-- Database and Permissions Diagnosis
-- ====================================================================

-- هذا الملف يساعد في تشخيص مشاكل الصلاحيات في PostgreSQL

-- ====================================================================
-- معلومات أساسية عن الجلسة
-- ====================================================================

DO $$
BEGIN
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'معلومات الجلسة الحالية:';
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'المستخدم الحالي: %', current_user;
    RAISE NOTICE 'قاعدة البيانات: %', current_database();
    RAISE NOTICE 'إصدار PostgreSQL: %', version();
    RAISE NOTICE 'الوقت الحالي: %', now();
    RAISE NOTICE '====================================================================';
END $$;

-- ====================================================================
-- فحص الأدوار الموجودة
-- ====================================================================

DO $$
DECLARE
    role_record RECORD;
    role_count integer := 0;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE 'الأدوار الموجودة في قاعدة البيانات:';
    RAISE NOTICE '====================================================================';
    
    FOR role_record IN 
        SELECT rolname, rolsuper, rolcreaterole, rolcreatedb, rolcanlogin
        FROM pg_roles 
        ORDER BY rolname
    LOOP
        role_count := role_count + 1;
        RAISE NOTICE 'دور: % | مدير: % | إنشاء أدوار: % | إنشاء قواعد: % | تسجيل دخول: %', 
            role_record.rolname, 
            role_record.rolsuper, 
            role_record.rolcreaterole, 
            role_record.rolcreatedb, 
            role_record.rolcanlogin;
    END LOOP;
    
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'إجمالي عدد الأدوار: %', role_count;
    RAISE NOTICE '';
END $$;

-- ====================================================================
-- فحص الجداول الموجودة
-- ====================================================================

DO $$
DECLARE
    table_record RECORD;
    table_count integer := 0;
BEGIN
    RAISE NOTICE 'الجداول الموجودة في schema public:';
    RAISE NOTICE '====================================================================';
    
    FOR table_record IN 
        SELECT tablename, tableowner
        FROM pg_tables 
        WHERE schemaname = 'public'
        ORDER BY tablename
    LOOP
        table_count := table_count + 1;
        RAISE NOTICE 'جدول: % | المالك: %', table_record.tablename, table_record.tableowner;
    END LOOP;
    
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'إجمالي عدد الجداول: %', table_count;
    RAISE NOTICE '';
END $$;

-- ====================================================================
-- فحص الدوال الموجودة
-- ====================================================================

DO $$
DECLARE
    function_record RECORD;
    function_count integer := 0;
BEGIN
    RAISE NOTICE 'الدوال الموجودة في schema public:';
    RAISE NOTICE '====================================================================';
    
    FOR function_record IN 
        SELECT p.proname as function_name, 
               pg_get_function_identity_arguments(p.oid) as arguments,
               u.usename as owner
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        LEFT JOIN pg_user u ON p.proowner = u.usesysid
        WHERE n.nspname = 'public'
        ORDER BY p.proname
    LOOP
        function_count := function_count + 1;
        RAISE NOTICE 'دالة: %(%)', function_record.function_name, function_record.arguments;
    END LOOP;
    
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'إجمالي عدد الدوال: %', function_count;
    RAISE NOTICE '';
END $$;

-- ====================================================================
-- فحص حالة RLS على الجداول
-- ====================================================================

DO $$
DECLARE
    table_record RECORD;
    rls_enabled_count integer := 0;
    total_tables integer := 0;
BEGIN
    RAISE NOTICE 'حالة Row Level Security (RLS) على الجداول:';
    RAISE NOTICE '====================================================================';
    
    FOR table_record IN 
        SELECT schemaname, tablename, rowsecurity
        FROM pg_tables 
        WHERE schemaname = 'public'
        ORDER BY tablename
    LOOP
        total_tables := total_tables + 1;
        IF table_record.rowsecurity THEN
            rls_enabled_count := rls_enabled_count + 1;
            RAISE NOTICE 'جدول: % | RLS: مفعل ✓', table_record.tablename;
        ELSE
            RAISE NOTICE 'جدول: % | RLS: معطل ✗', table_record.tablename;
        END IF;
    END LOOP;
    
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'الجداول التي لديها RLS مفعل: % من %', rls_enabled_count, total_tables;
    RAISE NOTICE '';
END $$;

-- ====================================================================
-- فحص السياسات الموجودة
-- ====================================================================

DO $$
DECLARE
    policy_record RECORD;
    policy_count integer := 0;
BEGIN
    RAISE NOTICE 'السياسات الموجودة:';
    RAISE NOTICE '====================================================================';
    
    FOR policy_record IN 
        SELECT schemaname, tablename, policyname, cmd, qual
        FROM pg_policies 
        WHERE schemaname = 'public'
        ORDER BY tablename, policyname
    LOOP
        policy_count := policy_count + 1;
        RAISE NOTICE 'جدول: % | سياسة: % | نوع: %', 
            policy_record.tablename, 
            policy_record.policyname, 
            policy_record.cmd;
    END LOOP;
    
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'إجمالي عدد السياسات: %', policy_count;
    RAISE NOTICE '';
END $$;

-- ====================================================================
-- اختبار الوصول للجداول الرئيسية
-- ====================================================================

DO $$
DECLARE
    table_name text;
    row_count integer;
    accessible_tables integer := 0;
    total_tested integer := 0;
    important_tables text[] := ARRAY['users', 'donations', 'activation_codes', 'notifications', 'ratings'];
BEGIN
    RAISE NOTICE 'اختبار الوصول للجداول المهمة:';
    RAISE NOTICE '====================================================================';
    
    FOREACH table_name IN ARRAY important_tables
    LOOP
        total_tested := total_tested + 1;
        BEGIN
            EXECUTE format('SELECT COUNT(*) FROM %I', table_name) INTO row_count;
            accessible_tables := accessible_tables + 1;
            RAISE NOTICE 'جدول: % | عدد الصفوف: % | الحالة: يمكن الوصول ✓', table_name, row_count;
        EXCEPTION
            WHEN undefined_table THEN
                RAISE NOTICE 'جدول: % | الحالة: غير موجود ⚠️', table_name;
            WHEN insufficient_privilege THEN
                RAISE NOTICE 'جدول: % | الحالة: لا توجد صلاحيات ✗', table_name;
            WHEN OTHERS THEN
                RAISE NOTICE 'جدول: % | خطأ: % ✗', table_name, SQLERRM;
        END;
    END LOOP;
    
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'الجداول التي يمكن الوصول إليها: % من %', accessible_tables, total_tested;
    RAISE NOTICE '';
END $$;

-- ====================================================================
-- اختبار الدوال المهمة
-- ====================================================================

DO $$
DECLARE
    function_name text;
    accessible_functions integer := 0;
    total_tested integer := 0;
    important_functions text[] := ARRAY['get_user_role', 'check_activation_code', 'get_website_statistics'];
BEGIN
    RAISE NOTICE 'اختبار الوصول للدوال المهمة:';
    RAISE NOTICE '====================================================================';
    
    FOREACH function_name IN ARRAY important_functions
    LOOP
        total_tested := total_tested + 1;
        BEGIN
            -- اختبار وجود الدالة
            IF EXISTS (
                SELECT 1 FROM pg_proc p
                JOIN pg_namespace n ON p.pronamespace = n.oid
                WHERE n.nspname = 'public' AND p.proname = function_name
            ) THEN
                accessible_functions := accessible_functions + 1;
                RAISE NOTICE 'دالة: % | الحالة: موجودة ✓', function_name;
            ELSE
                RAISE NOTICE 'دالة: % | الحالة: غير موجودة ⚠️', function_name;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'دالة: % | خطأ: % ✗', function_name, SQLERRM;
        END;
    END LOOP;
    
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'الدوال الموجودة: % من %', accessible_functions, total_tested;
    RAISE NOTICE '';
END $$;

-- ====================================================================
-- فحص صلاحيات المستخدم الحالي
-- ====================================================================

DO $$
DECLARE
    can_create_table boolean;
    can_create_function boolean;
    is_superuser boolean;
BEGIN
    RAISE NOTICE 'صلاحيات المستخدم الحالي:';
    RAISE NOTICE '====================================================================';
    
    -- فحص إذا كان المستخدم superuser
    SELECT rolsuper INTO is_superuser
    FROM pg_roles 
    WHERE rolname = current_user;
    
    RAISE NOTICE 'هل المستخدم superuser: %', COALESCE(is_superuser, false);
    
    -- فحص صلاحية إنشاء جداول
    SELECT has_schema_privilege('public', 'CREATE') INTO can_create_table;
    RAISE NOTICE 'يمكن إنشاء جداول في public: %', can_create_table;
    
    -- فحص صلاحية استخدام schema
    RAISE NOTICE 'يمكن استخدام schema public: %', has_schema_privilege('public', 'USAGE');
    
    RAISE NOTICE '====================================================================';
    RAISE NOTICE '';
END $$;

-- ====================================================================
-- التوصيات النهائية
-- ====================================================================

DO $$
DECLARE
    table_count integer;
    accessible_count integer := 0;
    table_name text;
BEGIN
    -- حساب عدد الجداول التي يمكن الوصول إليها
    SELECT COUNT(*) INTO table_count FROM pg_tables WHERE schemaname = 'public';
    
    FOR table_name IN 
        SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        BEGIN
            EXECUTE format('SELECT 1 FROM %I LIMIT 1', table_name);
            accessible_count := accessible_count + 1;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    END LOOP;
    
    RAISE NOTICE 'التوصيات النهائية:';
    RAISE NOTICE '====================================================================';
    
    IF accessible_count = table_count AND table_count > 0 THEN
        RAISE NOTICE '🎉 ممتاز! يمكن الوصول لجميع الجداول';
        RAISE NOTICE '✅ لا توجد مشاكل في الصلاحيات';
    ELSIF accessible_count = 0 AND table_count > 0 THEN
        RAISE NOTICE '🚨 مشكلة خطيرة: لا يمكن الوصول لأي جدول';
        RAISE NOTICE '🔧 يجب تشغيل ملف simple_fix.sql أو fix_permissions_updated.sql';
        RAISE NOTICE '⚠️  تأكد من تشغيل الملف كمستخدم postgres أو superuser';
    ELSIF accessible_count < table_count THEN
        RAISE NOTICE '⚠️  مشكلة جزئية: يمكن الوصول لـ % من % جدول', accessible_count, table_count;
        RAISE NOTICE '🔧 يُنصح بتشغيل ملف simple_fix.sql';
    ELSE
        RAISE NOTICE '❓ لا توجد جداول في قاعدة البيانات';
        RAISE NOTICE '🔧 يجب تشغيل ملف wisaal_merged_database.sql أولاً';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE 'ملفات الحل المتاحة:';
    RAISE NOTICE '1. simple_fix.sql - للحل السريع';
    RAISE NOTICE '2. fix_permissions_updated.sql - للحل الشامل';
    RAISE NOTICE '3. wisaal_merged_database.sql - لإنشاء قاعدة البيانات';
    RAISE NOTICE '====================================================================';
END $$;