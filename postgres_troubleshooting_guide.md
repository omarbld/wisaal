# PostgreSQL Permission Error Troubleshooting Guide

## Error: `permission denied for schema: public`

This error occurs when the database user doesn't have sufficient privileges to access or modify the public schema.

## Quick Solutions

### 1. **Immediate Fix (Run as Database Administrator)**

```sql
-- Connect as postgres superuser and run:
GRANT ALL PRIVILEGES ON SCHEMA public TO your_username;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO your_username;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO your_username;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO your_username;
```

### 2. **For Supabase Users**

```sql
-- Grant permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- For anonymous access (if needed)
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
```

### 3. **Check Your Connection String**

Make sure you're connecting with the correct user:
```
postgresql://username:password@host:port/database
```

### 4. **Verify User Permissions**

```sql
-- Check current user
SELECT current_user;

-- Check user roles
SELECT rolname FROM pg_roles WHERE pg_has_role(current_user, oid, 'member');

-- Check schema permissions
SELECT has_schema_privilege('public', 'USAGE');
SELECT has_schema_privilege('public', 'CREATE');
```

## Common Causes and Solutions

### **Cause 1: User lacks schema permissions**
**Solution:** Grant schema access
```sql
GRANT USAGE ON SCHEMA public TO your_username;
GRANT CREATE ON SCHEMA public TO your_username;
```

### **Cause 2: RLS (Row Level Security) blocking access**
**Solution:** Check RLS policies or temporarily disable
```sql
-- Check RLS status
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';

-- Temporarily disable RLS (for testing only)
ALTER TABLE table_name DISABLE ROW LEVEL SECURITY;
```

### **Cause 3: Connection using wrong user**
**Solution:** Verify connection credentials and use correct database user

### **Cause 4: Database ownership issues**
**Solution:** Change ownership
```sql
ALTER SCHEMA public OWNER TO your_username;
ALTER DATABASE your_database OWNER TO your_username;
```

## Step-by-Step Troubleshooting

### Step 1: Identify the Problem
```sql
-- Run this to see current permissions
\dp
\l
\du
```

### Step 2: Check Schema Access
```sql
SELECT 
    nspname as schema_name,
    nspowner::regrole as owner,
    nspacl as permissions
FROM pg_namespace 
WHERE nspname = 'public';
```

### Step 3: Grant Necessary Permissions
```sql
-- Basic permissions
GRANT USAGE ON SCHEMA public TO your_username;
GRANT CREATE ON SCHEMA public TO your_username;

-- Table permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO your_username;

-- Function permissions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO your_username;

-- Sequence permissions
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO your_username;
```

### Step 4: Set Default Permissions
```sql
-- For future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
GRANT ALL ON TABLES TO your_username;

ALTER DEFAULT PRIVILEGES IN SCHEMA public 
GRANT ALL ON SEQUENCES TO your_username;

ALTER DEFAULT PRIVILEGES IN SCHEMA public 
GRANT EXECUTE ON FUNCTIONS TO your_username;
```

## For Your Wisaal Project Specifically

Based on your database schema, run these commands as a superuser:

```sql
-- Grant permissions to your application user
GRANT ALL PRIVILEGES ON SCHEMA public TO your_app_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO your_app_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO your_app_user;

-- If using Supabase
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- For anonymous access to website functions
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon;
```

## Prevention

1. **Always create users with proper permissions**
2. **Use connection pooling with appropriate user roles**
3. **Regularly audit permissions**
4. **Document your permission structure**

## Testing the Fix

After applying the permissions, test with:

```sql
-- Test basic access
SELECT * FROM users LIMIT 1;

-- Test function execution
SELECT get_website_statistics();

-- Test insert permissions
INSERT INTO contact_messages (name, email, message) 
VALUES ('Test', 'test@example.com', 'Test message');
```

## Emergency Reset (Use with Caution)

If all else fails, reset public schema permissions:

```sql
-- As superuser
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO PUBLIC;
GRANT CREATE ON SCHEMA public TO your_username;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO your_username;
```

Remember to replace `your_username`, `your_app_user`, and `your_database` with your actual values.