-- ====================================================================
-- PostgreSQL Permission Fix Script
-- ====================================================================
-- This script resolves "permission denied for schema: public" errors
-- ====================================================================

-- Solution 1: Grant schema permissions to the user
-- Replace 'your_username' with your actual database username
GRANT USAGE ON SCHEMA public TO your_username;
GRANT CREATE ON SCHEMA public TO your_username;
GRANT ALL PRIVILEGES ON SCHEMA public TO your_username;

-- Solution 2: Grant permissions on all existing tables
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO your_username;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO your_username;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO your_username;

-- Solution 3: Grant default permissions for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO your_username;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO your_username;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO your_username;

-- Solution 4: If using Supabase or similar service, grant to specific roles
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT CREATE ON SCHEMA public TO authenticated;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Solution 5: Grant to anon role for public access
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon;

-- Solution 6: For PostgreSQL superuser fix
-- Run this as a superuser (postgres user)
ALTER SCHEMA public OWNER TO your_username;

-- Solution 7: Reset public schema permissions (if needed)
-- REVOKE ALL ON SCHEMA public FROM PUBLIC;
-- GRANT USAGE ON SCHEMA public TO PUBLIC;
-- GRANT CREATE ON SCHEMA public TO your_username;

-- ====================================================================
-- Specific fixes for common scenarios
-- ====================================================================

-- If you're the database owner but still getting permission errors:
GRANT ALL PRIVILEGES ON DATABASE your_database_name TO your_username;

-- If using connection pooling or specific application user:
GRANT CONNECT ON DATABASE your_database_name TO your_username;
GRANT USAGE ON SCHEMA public TO your_username;
GRANT CREATE ON SCHEMA public TO your_username;

-- For RLS (Row Level Security) issues:
-- Make sure the user has proper role assignments
-- Check if auth.uid() is properly set in your application context

-- ====================================================================
-- Verification queries
-- ====================================================================

-- Check current user permissions
SELECT 
    schemaname,
    tablename,
    tableowner,
    hasinserts,
    hasselects,
    hasupdates,
    hasdeletes
FROM pg_tables 
WHERE schemaname = 'public';

-- Check schema permissions
SELECT 
    nspname as schema_name,
    nspowner::regrole as owner,
    nspacl as permissions
FROM pg_namespace 
WHERE nspname = 'public';

-- Check current user and roles
SELECT current_user, session_user;
SELECT rolname FROM pg_roles WHERE pg_has_role(current_user, oid, 'member');

-- ====================================================================
-- END OF PERMISSION FIX SCRIPT
-- ====================================================================