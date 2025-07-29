-- ====================================================================
-- PostgreSQL User Identification and Permission Fix
-- ====================================================================

-- Step 1: Identify current user and available roles
SELECT 'Current User: ' || current_user as info;
SELECT 'Session User: ' || session_user as info;

-- List all available roles/users
SELECT 'Available Roles:' as info;
SELECT rolname as role_name, rolsuper as is_superuser, rolcreatedb as can_create_db
FROM pg_roles 
ORDER BY rolname;

-- Step 2: Check current database and connection info
SELECT 'Current Database: ' || current_database() as info;
SELECT 'Current Schema: ' || current_schema() as info;

-- Step 3: Check what permissions current user has
SELECT 'Schema Permissions:' as info;
SELECT 
    schemaname,
    has_schema_privilege(current_user, schemaname, 'USAGE') as has_usage,
    has_schema_privilege(current_user, schemaname, 'CREATE') as has_create
FROM information_schema.schemata 
WHERE schemaname = 'public';

-- ====================================================================
-- COMMON FIXES - Choose the appropriate one based on your setup
-- ====================================================================

-- Fix 1: If you're using the default 'postgres' superuser
-- GRANT ALL PRIVILEGES ON SCHEMA public TO postgres;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO postgres;

-- Fix 2: Grant permissions to current user (whatever user you're connected as)
DO $$
BEGIN
    EXECUTE format('GRANT USAGE ON SCHEMA public TO %I', current_user);
    EXECUTE format('GRANT CREATE ON SCHEMA public TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO %I', current_user);
    EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO %I', current_user);
    
    RAISE NOTICE 'Granted permissions to current user: %', current_user;
END $$;

-- Fix 3: If using Supabase (common setup)
-- GRANT USAGE ON SCHEMA public TO authenticated;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO authenticated;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
-- GRANT USAGE ON SCHEMA public TO anon;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon;

-- Fix 4: Create a new user if needed (replace 'wisaal_user' with your preferred username)
-- CREATE USER wisaal_user WITH PASSWORD 'your_secure_password';
-- GRANT ALL PRIVILEGES ON SCHEMA public TO wisaal_user;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO wisaal_user;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wisaal_user;

-- Fix 5: Grant to PUBLIC (less secure, but works for development)
-- GRANT USAGE ON SCHEMA public TO PUBLIC;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO PUBLIC;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO PUBLIC;

-- ====================================================================
-- Verification queries (run after applying fixes)
-- ====================================================================

-- Check if permissions were granted successfully
SELECT 'Verification Results:' as info;
SELECT 
    'Can use public schema: ' || has_schema_privilege(current_user, 'public', 'USAGE') as result
UNION ALL
SELECT 
    'Can create in public schema: ' || has_schema_privilege(current_user, 'public', 'CREATE') as result;

-- Test table access
SELECT 'Testing table access...' as info;
-- SELECT COUNT(*) as user_count FROM users;

-- ====================================================================
-- END OF SCRIPT
-- ====================================================================