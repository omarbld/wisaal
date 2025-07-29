-- ====================================================================
-- Simple PostgreSQL Permission Fix
-- ====================================================================
-- Run these commands one by one to fix the permission error
-- ====================================================================

-- STEP 1: Find out who you are
SELECT current_user as "Your Username";

-- STEP 2: Grant permissions to yourself (current user)
-- This will work regardless of what your username is
GRANT USAGE ON SCHEMA public TO CURRENT_USER;
GRANT CREATE ON SCHEMA public TO CURRENT_USER;

-- STEP 3: Grant table permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO CURRENT_USER;

-- STEP 4: Grant sequence permissions
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO CURRENT_USER;

-- STEP 5: Grant function permissions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO CURRENT_USER;

-- STEP 6: Set default permissions for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO CURRENT_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO CURRENT_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO CURRENT_USER;

-- STEP 7: If you're using a web application, also grant to common roles
-- Uncomment these if you're using Supabase or similar:

-- GRANT USAGE ON SCHEMA public TO authenticated;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO authenticated;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- GRANT USAGE ON SCHEMA public TO anon;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon;

-- STEP 8: Test the fix
SELECT 'Permission fix completed for user: ' || current_user as result;

-- Try to access a table to verify
-- SELECT COUNT(*) FROM users;

-- ====================================================================
-- Alternative: If you need to create a specific user
-- ====================================================================

-- If you want to create a dedicated user for your application:
-- CREATE USER wisaal_app WITH PASSWORD 'secure_password_here';
-- GRANT ALL PRIVILEGES ON SCHEMA public TO wisaal_app;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO wisaal_app;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wisaal_app;

-- ====================================================================
-- Emergency Fix: Grant to everyone (ONLY for development/testing)
-- ====================================================================

-- If nothing else works, uncomment these (NOT recommended for production):
-- GRANT USAGE ON SCHEMA public TO PUBLIC;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO PUBLIC;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO PUBLIC;