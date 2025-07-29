-- Comprehensive Button Test for Wisaal Application
-- This script tests all critical functions that are called by buttons in the app

-- ====================================================================
-- Test 1: Check if all required functions exist
-- ====================================================================

DO $$
DECLARE
    missing_functions text[] := ARRAY[]::text[];
    func_name text;
    required_functions text[] := ARRAY[
        'register_volunteer',
        'get_top_volunteers',
        'get_volunteer_dashboard_data',
        'get_leaderboard',
        'get_full_leaderboard',
        'get_association_report_data',
        'get_volunteers_for_association',
        'log_volunteer_hours',
        'generate_share_text',
        'get_map_data_with_coordinates',
        'get_user_badges',
        'send_bulk_notification',
        'generate_activation_code_enhanced'
    ];
BEGIN
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'Testing Function Availability...';
    RAISE NOTICE '====================================================================';
    
    FOREACH func_name IN ARRAY required_functions
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_schema = 'public' 
            AND routine_name = func_name
        ) THEN
            missing_functions := array_append(missing_functions, func_name);
        ELSE
            RAISE NOTICE '✅ Function % exists', func_name;
        END IF;
    END LOOP;
    
    IF array_length(missing_functions, 1) > 0 THEN
        RAISE NOTICE '❌ Missing functions: %', array_to_string(missing_functions, ', ');
    ELSE
        RAISE NOTICE '✅ All required functions are available!';
    END IF;
END $$;

-- ====================================================================
-- Test 2: Check if all required tables/views exist
-- ====================================================================

DO $$
DECLARE
    missing_tables text[] := ARRAY[]::text[];
    table_name text;
    required_tables text[] := ARRAY[
        'users',
        'donations',
        'notifications',
        'ratings',
        'activation_codes',
        'inventory',
        'donations_with_coordinates'
    ];
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'Testing Table/View Availability...';
    RAISE NOTICE '====================================================================';
    
    FOREACH table_name IN ARRAY required_tables
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = table_name
        ) AND NOT EXISTS (
            SELECT 1 FROM information_schema.views 
            WHERE table_schema = 'public' 
            AND table_name = table_name
        ) THEN
            missing_tables := array_append(missing_tables, table_name);
        ELSE
            RAISE NOTICE '✅ Table/View % exists', table_name;
        END IF;
    END LOOP;
    
    IF array_length(missing_tables, 1) > 0 THEN
        RAISE NOTICE '❌ Missing tables/views: %', array_to_string(missing_tables, ', ');
    ELSE
        RAISE NOTICE '✅ All required tables/views are available!';
    END IF;
END $$;

-- ====================================================================
-- Test 3: Test Function Execution (with sample data)
-- ====================================================================

DO $$
DECLARE
    test_user_id uuid := gen_random_uuid();
    test_association_id uuid := gen_random_uuid();
    test_result json;
    test_count integer;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'Testing Function Execution...';
    RAISE NOTICE '====================================================================';
    
    -- Test get_leaderboard
    BEGIN
        SELECT get_leaderboard() INTO test_result;
        RAISE NOTICE '✅ get_leaderboard() executed successfully';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ get_leaderboard() failed: %', SQLERRM;
    END;
    
    -- Test get_top_volunteers
    BEGIN
        SELECT COUNT(*) INTO test_count FROM get_top_volunteers(5);
        RAISE NOTICE '✅ get_top_volunteers() executed successfully, returned % rows', test_count;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ get_top_volunteers() failed: %', SQLERRM;
    END;
    
    -- Test get_association_report_data (with dummy ID)
    BEGIN
        SELECT get_association_report_data(test_association_id, 'all') INTO test_result;
        RAISE NOTICE '✅ get_association_report_data() executed successfully';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ get_association_report_data() failed: %', SQLERRM;
    END;
    
    -- Test get_volunteers_for_association (with dummy ID)
    BEGIN
        SELECT COUNT(*) INTO test_count FROM get_volunteers_for_association(test_association_id);
        RAISE NOTICE '✅ get_volunteers_for_association() executed successfully, returned % rows', test_count;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ get_volunteers_for_association() failed: %', SQLERRM;
    END;
    
    -- Test get_volunteer_dashboard_data (with dummy ID)
    BEGIN
        SELECT get_volunteer_dashboard_data(test_user_id) INTO test_result;
        RAISE NOTICE '✅ get_volunteer_dashboard_data() executed successfully';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ get_volunteer_dashboard_data() failed: %', SQLERRM;
    END;
    
    -- Test get_user_badges (with dummy ID)
    BEGIN
        SELECT COUNT(*) INTO test_count FROM get_user_badges(test_user_id);
        RAISE NOTICE '✅ get_user_badges() executed successfully, returned % rows', test_count;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ get_user_badges() failed: %', SQLERRM;
    END;
    
    -- Test generate_share_text (with dummy ID)
    BEGIN
        SELECT generate_share_text(test_user_id) INTO test_result;
        RAISE NOTICE '✅ generate_share_text() executed successfully';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ generate_share_text() failed: %', SQLERRM;
    END;
    
    -- Test get_map_data_with_coordinates
    BEGIN
        SELECT get_map_data_with_coordinates() INTO test_result;
        RAISE NOTICE '✅ get_map_data_with_coordinates() executed successfully';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ get_map_data_with_coordinates() failed: %', SQLERRM;
    END;
    
END $$;

-- ====================================================================
-- Test 4: Check RLS Policies
-- ====================================================================

DO $$
DECLARE
    policy_count integer;
    table_name text;
    tables_with_rls text[] := ARRAY['users', 'donations', 'notifications', 'ratings', 'activation_codes', 'inventory'];
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'Testing RLS Policies...';
    RAISE NOTICE '====================================================================';
    
    FOREACH table_name IN ARRAY tables_with_rls
    LOOP
        SELECT COUNT(*) INTO policy_count 
        FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = table_name;
        
        IF policy_count > 0 THEN
            RAISE NOTICE '✅ Table % has % RLS policies', table_name, policy_count;
        ELSE
            RAISE NOTICE '❌ Table % has no RLS policies', table_name;
        END IF;
    END LOOP;
END $$;

-- ====================================================================
-- Test 5: Check Sample Data
-- ====================================================================

DO $$
DECLARE
    user_count integer;
    donation_count integer;
    activation_code_count integer;
    inventory_count integer;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'Checking Sample Data...';
    RAISE NOTICE '====================================================================';
    
    SELECT COUNT(*) INTO user_count FROM users;
    RAISE NOTICE 'Users in database: %', user_count;
    
    SELECT COUNT(*) INTO donation_count FROM donations;
    RAISE NOTICE 'Donations in database: %', donation_count;
    
    SELECT COUNT(*) INTO activation_code_count FROM activation_codes;
    RAISE NOTICE 'Activation codes in database: %', activation_code_count;
    
    SELECT COUNT(*) INTO inventory_count FROM inventory;
    RAISE NOTICE 'Inventory items in database: %', inventory_count;
    
    -- Check if we have users of each role
    FOR user_count IN 
        SELECT COUNT(*) FROM users WHERE role = 'donor'
    LOOP
        RAISE NOTICE 'Donors: %', user_count;
    END LOOP;
    
    FOR user_count IN 
        SELECT COUNT(*) FROM users WHERE role = 'association'
    LOOP
        RAISE NOTICE 'Associations: %', user_count;
    END LOOP;
    
    FOR user_count IN 
        SELECT COUNT(*) FROM users WHERE role = 'volunteer'
    LOOP
        RAISE NOTICE 'Volunteers: %', user_count;
    END LOOP;
    
    FOR user_count IN 
        SELECT COUNT(*) FROM users WHERE role = 'manager'
    LOOP
        RAISE NOTICE 'Managers: %', user_count;
    END LOOP;
END $$;

-- ====================================================================
-- Test 6: Test Critical Button Workflows
-- ====================================================================

DO $$
DECLARE
    test_result json;
    test_code text;
    test_association_id uuid;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'Testing Critical Button Workflows...';
    RAISE NOTICE '====================================================================';
    
    -- Get a real association ID if available
    SELECT id INTO test_association_id FROM users WHERE role = 'association' LIMIT 1;
    
    IF test_association_id IS NOT NULL THEN
        -- Test activation code generation (Association button)
        BEGIN
            SELECT generated_code INTO test_code 
            FROM generate_activation_code_enhanced(test_association_id, 1) 
            LIMIT 1;
            RAISE NOTICE '✅ Activation code generation works: %', test_code;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Activation code generation failed: %', SQLERRM;
        END;
        
        -- Test association report data (Reports button)
        BEGIN
            SELECT get_association_report_data(test_association_id, 'month') INTO test_result;
            RAISE NOTICE '✅ Association reports work';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Association reports failed: %', SQLERRM;
        END;
        
    ELSE
        RAISE NOTICE '⚠️  No association found for testing association-specific functions';
    END IF;
    
    -- Test leaderboard (Leaderboard button)
    BEGIN
        SELECT COUNT(*) FROM get_leaderboard();
        RAISE NOTICE '✅ Leaderboard functionality works';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Leaderboard functionality failed: %', SQLERRM;
    END;
    
END $$;

-- ====================================================================
-- Final Summary
-- ====================================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'COMPREHENSIVE BUTTON TEST COMPLETED';
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'Review the results above to identify any issues.';
    RAISE NOTICE 'If all tests show ✅, then all buttons should work properly.';
    RAISE NOTICE 'If any tests show ❌, those functions need to be fixed.';
    RAISE NOTICE '====================================================================';
END $$;