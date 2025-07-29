-- ====================================================================
-- حل بسيط وسريع لمشكلة صلاحيات PostgreSQL
-- Simple and Quick Fix for PostgreSQL Permissions
-- ====================================================================

-- تشغيل هذا الملف لحل مشكلة: permission denied for schema: public
-- بدون استخدام information_schema.schema_privileges

-- ====================================================================
-- الحل البسيط والمباشر
-- ====================================================================

-- 1. إعطاء صلاحيات شاملة لجميع المستخدمين
GRANT ALL PRIVILEGES ON SCHEMA public TO PUBLIC;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO PUBLIC;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO PUBLIC;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO PUBLIC;

-- 2. إعطاء صلاحيات للجداول والدوال المستقبلية
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO PUBLIC;

-- 3. إنشاء أدوار Supabase الأساسية
DO $$
BEGIN
    -- إنشاء الأدوار بأمان
    BEGIN
        CREATE ROLE anon;
    EXCEPTION WHEN duplicate_object THEN
        NULL; -- تجاهل إذا كان موجود
    END;
    
    BEGIN
        CREATE ROLE authenticated;
    EXCEPTION WHEN duplicate_object THEN
        NULL;
    END;
    
    BEGIN
        CREATE ROLE service_role;
    EXCEPTION WHEN duplicate_object THEN
        NULL;
    END;
    
    -- إعطاء صلاحيات للأدوار
    GRANT ALL ON SCHEMA public TO anon, authenticated, service_role;
    GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
    GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
    GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;
    
    RAISE NOTICE 'تم إنشاء وإعداد أدوار Supabase بنجاح';
END $$;

-- 4. تعطيل RLS على جميع الجداول (حل مؤقت)
DO $$
DECLARE
    table_name text;
BEGIN
    FOR table_name IN 
        SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        BEGIN
            EXECUTE format('ALTER TABLE %I DISABLE ROW LEVEL SECURITY', table_name);
            RAISE NOTICE 'تم تعطيل RLS على جدول: %', table_name;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'خطأ في تعطيل RLS على جدول %: %', table_name, SQLERRM;
        END;
    END LOOP;
END $$;

-- 5. إنشاء سياسات مفتوحة لجميع الجداول
DO $$
DECLARE
    table_name text;
BEGIN
    FOR table_name IN 
        SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        BEGIN
            -- حذف السياسات الموجودة
            EXECUTE format('DROP POLICY IF EXISTS "allow_all" ON %I', table_name);
            
            -- إنشاء سياسة مفتوحة
            EXECUTE format('CREATE POLICY "allow_all" ON %I FOR ALL USING (true) WITH CHECK (true)', table_name);
            
            RAISE NOTICE 'تم إنشاء سياسة مفتوحة لجدول: %', table_name;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'خطأ في إنشاء سياسة لجدول %: %', table_name, SQLERRM;
        END;
    END LOOP;
END $$;

-- 6. إعادة تفعيل RLS مع السياسات الجديدة
DO $$
DECLARE
    table_name text;
BEGIN
    FOR table_name IN 
        SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        BEGIN
            EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', table_name);
            RAISE NOTICE 'تم تفعيل RLS على جدول: %', table_name;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'خطأ في تفعيل RLS على جدول %: %', table_name, SQLERRM;
        END;
    END LOOP;
END $$;

-- 7. اختبار الحل
DO $$
DECLARE
    table_name text;
    row_count integer;
    success_count integer := 0;
    total_count integer := 0;
BEGIN
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'اختبار الوصول للجداول بعد إصلاح الصلاحيات:';
    RAISE NOTICE '====================================================================';
    
    FOR table_name IN 
        SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename
    LOOP
        total_count := total_count + 1;
        BEGIN
            EXECUTE format('SELECT COUNT(*) FROM %I', table_name) INTO row_count;
            RAISE NOTICE 'جدو�� % - عدد الصفوف: % ✓', table_name, row_count;
            success_count := success_count + 1;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'جدول % - خطأ: % ✗', table_name, SQLERRM;
        END;
    END LOOP;
    
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'نتائج الاختبار:';
    RAISE NOTICE 'الجداول التي تم الوصول إليها بنجاح: % من %', success_count, total_count;
    
    IF success_count = total_count THEN
        RAISE NOTICE '🎉 تم حل مشكلة الصلاحيات بنجاح!';
    ELSE
        RAISE NOTICE '⚠️  بعض الجداول لا تزال تواجه مشاكل';
    END IF;
    
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'معلومات الجلسة:';
    RAISE NOTICE 'المستخدم الحالي: %', current_user;
    RAISE NOTICE 'قاعدة البيانات: %', current_database();
    RAISE NOTICE '====================================================================';
END $$;

-- 8. رسالة نهائية
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔧 تم تطبيق الحل البسيط لمشكلة الصلاحيات';
    RAISE NOTICE '';
    RAISE NOTICE 'إذا استمرت ��لمشكلة:';
    RAISE NOTICE '1. تأكد من تشغيل هذا الملف كمستخدم postgres أو superuser';
    RAISE NOTICE '2. تحقق من إعدادات Supabase إذا كنت تستخدمه';
    RAISE NOTICE '3. استخدم service_role key بدلاً من anon key في Supabase';
    RAISE NOTICE '';
END $$;