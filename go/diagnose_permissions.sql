-- ===========================================
-- تشخيص مشاكل الصلاحيات في قاعدة البيانات
-- Database Permissions Diagnostic Script
-- ===========================================

-- 1. فحص صلاحيات المخطط العام (public schema)
SELECT 
    'Schema Permissions' as check_type,
    nspname as schema_name,
    has_schema_privilege('authenticated', nspname, 'USAGE') as authenticated_usage,
    has_schema_privilege('anon', nspname, 'USAGE') as anon_usage
FROM pg_namespace 
WHERE nspname = 'public';

-- 2. فحص صلاحيات الجداول
SELECT 
    'Table Permissions' as check_type,
    schemaname,
    tablename,
    has_table_privilege('authenticated', schemaname||'.'||tablename, 'SELECT') as auth_select,
    has_table_privilege('authenticated', schemaname||'.'||tablename, 'INSERT') as auth_insert,
    has_table_privilege('authenticated', schemaname||'.'||tablename, 'UPDATE') as auth_update,
    has_table_privilege('authenticated', schemaname||'.'||tablename, 'DELETE') as auth_delete,
    has_table_privilege('anon', schemaname||'.'||tablename, 'SELECT') as anon_select
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- 3. فحص صلاحيات الدوال
SELECT 
    'Function Permissions' as check_type,
    routine_schema,
    routine_name,
    has_function_privilege('authenticated', routine_schema||'.'||routine_name||'('||COALESCE(data_type, 'void')||')', 'EXECUTE') as auth_execute,
    has_function_privilege('anon', routine_schema||'.'||routine_name||'('||COALESCE(data_type, 'void')||')', 'EXECUTE') as anon_execute
FROM information_schema.routines 
WHERE routine_schema = 'public'
ORDER BY routine_name;

-- 4. فحص حالة RLS
SELECT 
    'RLS Status' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- 5. فحص السياسات الموجودة
SELECT 
    'RLS Policies' as check_type,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- 6. فحص الأدوار والصلاحيات
SELECT 
    'Role Information' as check_type,
    rolname,
    rolsuper,
    rolinherit,
    rolcreaterole,
    rolcreatedb,
    rolcanlogin,
    rolreplication,
    rolbypassrls
FROM pg_roles 
WHERE rolname IN ('authenticated', 'anon', 'postgres', 'supabase_admin')
ORDER BY rolname;

-- 7. فحص الجداول المفقودة أو المشاكل الهيكلية
SELECT 
    'Table Structure' as check_type,
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name IN ('users', 'donations', 'activation_codes', 'notifications', 'ratings')
ORDER BY table_name, ordinal_position;

-- 8. فحص الفهارس
SELECT 
    'Index Information' as check_type,
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- 9. فحص القيود (Constraints)
SELECT 
    'Constraints' as check_type,
    table_schema,
    table_name,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_schema = 'public'
ORDER BY table_name, constraint_name;

-- 10. فحص المراجع الخارجية (Foreign Keys)
SELECT 
    'Foreign Keys' as check_type,
    tc.table_schema,
    tc.table_name,
    kcu.column_name,
    ccu.table_schema AS foreign_table_schema,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

-- 11. فحص الأخطاء الشائعة
SELECT 
    'Common Issues Check' as check_type,
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'users') 
        THEN 'ERROR: users table missing'
        WHEN NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'activation_codes') 
        THEN 'ERROR: activation_codes table missing'
        WHEN NOT has_schema_privilege('authenticated', 'public', 'USAGE') 
        THEN 'ERROR: authenticated role lacks USAGE on public schema'
        WHEN NOT has_table_privilege('authenticated', 'public.users', 'SELECT') 
        THEN 'ERROR: authenticated role lacks SELECT on users table'
        ELSE 'OK: Basic structure appears correct'
    END as issue_description;

-- 12. معلومات الاتصال الحالي
SELECT 
    'Connection Info' as check_type,
    current_user as current_user,
    session_user as session_user,
    current_database() as current_database,
    current_schema() as current_schema,
    version() as postgres_version;

-- ===========================================
-- نهاية ملف التشخيص
-- ===========================================