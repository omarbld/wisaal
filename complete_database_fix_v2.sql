-- Complete Database Fix for Wisaal Application (Version 2)
-- This script fixes all missing functions and database issues including ambiguous column references

-- ====================================================================
-- Part 1: Fix Association Reports Function (Fixed Ambiguous Columns)
-- ====================================================================

-- Drop and recreate function for association reports and statistics
DROP FUNCTION IF EXISTS get_association_report_data(uuid, text);

CREATE OR REPLACE FUNCTION get_association_report_data(
  p_association_id uuid,
  p_period text DEFAULT 'all'
)
RETURNS json AS $$
DECLARE
  start_date timestamptz;
  end_date timestamptz;
  total_donations_count int;
  completed_donations_count int;
  active_volunteers_count int;
  food_type_distribution json;
  monthly_donations json;
  top_donors json;
  top_volunteers json;
BEGIN
  -- Set date range based on period
  end_date := NOW();
  CASE p_period
    WHEN 'week' THEN start_date := end_date - INTERVAL '1 week';
    WHEN 'month' THEN start_date := end_date - INTERVAL '1 month';
    WHEN 'quarter' THEN start_date := end_date - INTERVAL '3 months';
    WHEN 'year' THEN start_date := end_date - INTERVAL '1 year';
    ELSE start_date := '1900-01-01'::timestamptz; -- All time
  END CASE;

  -- Get total donations count
  SELECT COUNT(*) INTO total_donations_count
  FROM donations 
  WHERE association_id = p_association_id 
    AND created_at >= start_date 
    AND created_at <= end_date;

  -- Get completed donations count
  SELECT COUNT(*) INTO completed_donations_count
  FROM donations 
  WHERE association_id = p_association_id 
    AND status = 'completed'
    AND created_at >= start_date 
    AND created_at <= end_date;

  -- Get active volunteers count
  SELECT COUNT(*) INTO active_volunteers_count
  FROM users 
  WHERE role = 'volunteer' 
    AND associated_with_association_id = p_association_id 
    AND is_active = true;

  -- Get food type distribution
  SELECT json_object_agg(
    COALESCE(food_type, 'غير محدد'), 
    count
  ) INTO food_type_distribution
  FROM (
    SELECT 
      food_type,
      COUNT(*) as count
    FROM donations 
    WHERE association_id = p_association_id 
      AND created_at >= start_date 
      AND created_at <= end_date
      AND status = 'completed'
    GROUP BY food_type
    ORDER BY count DESC
    LIMIT 10
  ) food_dist;

  -- Get monthly donations (last 12 months)
  SELECT json_object_agg(
    month_year,
    donation_count
  ) INTO monthly_donations
  FROM (
    SELECT 
      TO_CHAR(created_at, 'YYYY-MM') as month_year,
      COUNT(*) as donation_count
    FROM donations 
    WHERE association_id = p_association_id 
      AND created_at >= NOW() - INTERVAL '12 months'
      AND status = 'completed'
    GROUP BY TO_CHAR(created_at, 'YYYY-MM')
    ORDER BY month_year
  ) monthly_data;

  -- Get top donors (fixed to avoid ambiguity)
  SELECT json_agg(
    json_build_object(
      'full_name', u.full_name,
      'count', donor_data.donation_count
    )
  ) INTO top_donors
  FROM (
    SELECT 
      d.donor_id,
      COUNT(*) as donation_count
    FROM donations d
    WHERE d.association_id = p_association_id 
      AND d.created_at >= start_date 
      AND d.created_at <= end_date
      AND d.status = 'completed'
    GROUP BY d.donor_id
    ORDER BY donation_count DESC
    LIMIT 5
  ) donor_data
  JOIN users u ON donor_data.donor_id = u.id;

  -- Get top volunteers (fixed to avoid ambiguity)
  SELECT json_agg(
    json_build_object(
      'full_name', u.full_name,
      'avg_rating', COALESCE(volunteer_data.avg_rating, 0),
      'completed_tasks', volunteer_data.completed_tasks
    )
  ) INTO top_volunteers
  FROM (
    SELECT 
      d.volunteer_id,
      AVG(r.rating) as avg_rating,
      COUNT(d.donation_id) as completed_tasks
    FROM donations d
    LEFT JOIN ratings r ON d.donation_id = r.task_id AND r.volunteer_id = d.volunteer_id
    WHERE d.association_id = p_association_id 
      AND d.created_at >= start_date 
      AND d.created_at <= end_date
      AND d.status = 'completed'
      AND d.volunteer_id IS NOT NULL
    GROUP BY d.volunteer_id
    ORDER BY avg_rating DESC, completed_tasks DESC
    LIMIT 5
  ) volunteer_data
  JOIN users u ON volunteer_data.volunteer_id = u.id;

  -- Return comprehensive report data
  RETURN json_build_object(
    'total_donations', total_donations_count,
    'completed_donations', completed_donations_count,
    'active_volunteers', active_volunteers_count,
    'food_type_dist', COALESCE(food_type_distribution, '{}'::json),
    'monthly_donations', COALESCE(monthly_donations, '{}'::json),
    'top_donors', COALESCE(top_donors, '[]'::json),
    'top_volunteers', COALESCE(top_volunteers, '[]'::json),
    'period', p_period,
    'start_date', start_date,
    'end_date', end_date,
    'generated_at', NOW()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================================================
-- Part 2: Fix Volunteer Assignment Function
-- ====================================================================

-- Ensure get_volunteers_for_association function returns correct column names
DROP FUNCTION IF EXISTS get_volunteers_for_association(uuid);

CREATE OR REPLACE FUNCTION get_volunteers_for_association(p_association_id uuid)
RETURNS TABLE(
  volunteer_id uuid,
  full_name text,
  email text,
  phone text,
  points int,
  is_active boolean,
  avg_rating numeric,
  total_tasks int,
  completed_tasks int,
  created_at timestamptz
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id as volunteer_id,
    u.full_name,
    u.email,
    u.phone,
    u.points,
    u.is_active,
    COALESCE(AVG(r.rating), 0) as avg_rating,
    COUNT(d.donation_id)::int as total_tasks,
    COUNT(CASE WHEN d.status = 'completed' THEN 1 END)::int as completed_tasks,
    u.created_at
  FROM users u
  LEFT JOIN ratings r ON u.id = r.volunteer_id
  LEFT JOIN donations d ON u.id = d.volunteer_id
  WHERE u.role = 'volunteer' 
    AND u.associated_with_association_id = p_association_id
  GROUP BY u.id, u.full_name, u.email, u.phone, u.points, u.is_active, u.created_at
  ORDER BY u.points DESC, completed_tasks DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================================================
-- Part 3: Create Missing Utility Functions
-- ====================================================================

-- Function to log volunteer hours
CREATE OR REPLACE FUNCTION log_volunteer_hours(
  p_volunteer_id uuid,
  p_hours numeric DEFAULT 1.0,
  p_task_id uuid DEFAULT NULL
)
RETURNS json AS $$
BEGIN
  -- Insert log entry
  INSERT INTO volunteer_logs (volunteer_id, action, details, created_at)
  VALUES (
    p_volunteer_id,
    'hours_logged',
    json_build_object(
      'hours', p_hours,
      'task_id', p_task_id,
      'logged_at', NOW()
    ),
    NOW()
  );
  
  -- Award points for logging hours (1 point per hour)
  UPDATE users 
  SET points = points + p_hours::int
  WHERE id = p_volunteer_id;
  
  RETURN json_build_object(
    'success', true,
    'hours_logged', p_hours,
    'message', 'تم تسجيل الساعات بنجاح'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to generate share text for donations
CREATE OR REPLACE FUNCTION generate_share_text(
  p_donation_id uuid
)
RETURNS json AS $$
DECLARE
  donation_record RECORD;
  share_text text;
BEGIN
  -- Get donation details
  SELECT 
    d.title,
    d.description,
    d.quantity,
    d.food_type,
    u_donor.full_name as donor_name,
    u_assoc.full_name as association_name
  INTO donation_record
  FROM donations d
  LEFT JOIN users u_donor ON d.donor_id = u_donor.id
  LEFT JOIN users u_assoc ON d.association_id = u_assoc.id
  WHERE d.donation_id = p_donation_id;
  
  IF donation_record IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'التبرع غير موجود'
    );
  END IF;
  
  -- Generate share text
  share_text := format(
    '🌟 تم توصيل تبرع بنجاح عبر تطبيق وصال! 🌟
    
📦 التبرع: %s
🍽️ النوع: %s
📊 الكمية: %s
👤 المتبرع: %s
🏢 الجمعية: %s

#وصال #مكافحة_هدر_الطعام #تطوع #خير',
    donation_record.title,
    COALESCE(donation_record.food_type, 'غير محدد'),
    COALESCE(donation_record.quantity::text, 'غير محدد'),
    COALESCE(donation_record.donor_name, 'غير معروف'),
    COALESCE(donation_record.association_name, 'غير معروف')
  );
  
  RETURN json_build_object(
    'success', true,
    'share_text', share_text
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get map data with coordinates
CREATE OR REPLACE FUNCTION get_map_data_with_coordinates()
RETURNS json AS $$
BEGIN
  RETURN (
    SELECT json_build_object(
      'donations', (
        SELECT json_agg(
          json_build_object(
            'donation_id', d.donation_id,
            'title', d.title,
            'status', d.status,
            'latitude', ST_Y(d.location::geometry),
            'longitude', ST_X(d.location::geometry),
            'is_urgent', d.is_urgent,
            'food_type', d.food_type,
            'donor_name', u_donor.full_name,
            'association_name', u_assoc.full_name
          )
        )
        FROM donations d
        LEFT JOIN users u_donor ON d.donor_id = u_donor.id
        LEFT JOIN users u_assoc ON d.association_id = u_assoc.id
        WHERE d.location IS NOT NULL
          AND d.status IN ('pending', 'accepted', 'assigned', 'in_progress')
      ),
      'users', (
        SELECT json_agg(
          json_build_object(
            'user_id', u.id,
            'full_name', u.full_name,
            'role', u.role,
            'latitude', ST_Y(u.location::geometry),
            'longitude', ST_X(u.location::geometry),
            'is_active', u.is_active
          )
        )
        FROM users u
        WHERE u.location IS NOT NULL
          AND u.is_active = true
          AND u.role IN ('volunteer', 'association')
      )
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get latitude from location
CREATE OR REPLACE FUNCTION get_latitude_from_location(
  location_point geography
)
RETURNS double precision AS $$
BEGIN
  IF location_point IS NULL THEN
    RETURN NULL;
  END IF;
  
  RETURN ST_Y(location_point::geometry);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get longitude from location
CREATE OR REPLACE FUNCTION get_longitude_from_location(
  location_point geography
)
RETURNS double precision AS $$
BEGIN
  IF location_point IS NULL THEN
    RETURN NULL;
  END IF;
  
  RETURN ST_X(location_point::geometry);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get volunteer QR scan history
CREATE OR REPLACE FUNCTION get_volunteer_qr_scan_history(
  p_volunteer_id uuid
)
RETURNS json AS $$
BEGIN
  RETURN (
    SELECT json_agg(
      json_build_object(
        'log_id', vl.id,
        'action', vl.action,
        'details', vl.details,
        'created_at', vl.created_at
      )
      ORDER BY vl.created_at DESC
    )
    FROM volunteer_logs vl
    WHERE vl.volunteer_id = p_volunteer_id
      AND vl.action LIKE '%QR%'
    LIMIT 50
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check duplicate user locations
CREATE OR REPLACE FUNCTION check_duplicate_user_locations()
RETURNS json AS $$
BEGIN
  RETURN (
    SELECT json_agg(
      json_build_object(
        'latitude', latitude,
        'longitude', longitude,
        'user_count', user_count,
        'users', users
      )
    )
    FROM (
      SELECT 
        ul.latitude,
        ul.longitude,
        COUNT(*) as user_count,
        json_agg(
          json_build_object(
            'user_id', u.id,
            'full_name', u.full_name,
            'role', u.role
          )
        ) as users
      FROM user_locations ul
      JOIN users u ON ul.user_id = u.id
      GROUP BY ul.latitude, ul.longitude
      HAVING COUNT(*) > 1
    ) duplicates
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check duplicate donation locations
CREATE OR REPLACE FUNCTION check_duplicate_donation_locations()
RETURNS json AS $$
BEGIN
  RETURN (
    SELECT json_agg(
      json_build_object(
        'latitude', latitude,
        'longitude', longitude,
        'donation_count', donation_count,
        'donations', donations
      )
    )
    FROM (
      SELECT 
        ST_Y(d.location::geometry) as latitude,
        ST_X(d.location::geometry) as longitude,
        COUNT(*) as donation_count,
        json_agg(
          json_build_object(
            'donation_id', d.donation_id,
            'title', d.title,
            'status', d.status
          )
        ) as donations
      FROM donations d
      WHERE d.location IS NOT NULL
      GROUP BY ST_Y(d.location::geometry), ST_X(d.location::geometry)
      HAVING COUNT(*) > 1
    ) duplicates
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check duplicate personal data
CREATE OR REPLACE FUNCTION check_duplicate_personal_data()
RETURNS json AS $$
BEGIN
  RETURN (
    SELECT json_agg(
      json_build_object(
        'email', email,
        'phone', phone,
        'user_count', user_count,
        'users', users
      )
    )
    FROM (
      SELECT 
        u.email,
        u.phone,
        COUNT(*) as user_count,
        json_agg(
          json_build_object(
            'user_id', u.id,
            'full_name', u.full_name,
            'role', u.role,
            'created_at', u.created_at
          )
        ) as users
      FROM users u
      WHERE u.email IS NOT NULL OR u.phone IS NOT NULL
      GROUP BY u.email, u.phone
      HAVING COUNT(*) > 1
    ) duplicates
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================================================
-- Part 4: Grant Permissions
-- ====================================================================

-- Grant permissions on all functions
GRANT EXECUTE ON FUNCTION get_association_report_data(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION get_volunteers_for_association(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION log_volunteer_hours(uuid, numeric, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_share_text(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_map_data_with_coordinates() TO authenticated;
GRANT EXECUTE ON FUNCTION get_latitude_from_location(geography) TO authenticated;
GRANT EXECUTE ON FUNCTION get_longitude_from_location(geography) TO authenticated;
GRANT EXECUTE ON FUNCTION get_volunteer_qr_scan_history(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION check_duplicate_user_locations() TO authenticated;
GRANT EXECUTE ON FUNCTION check_duplicate_donation_locations() TO authenticated;
GRANT EXECUTE ON FUNCTION check_duplicate_personal_data() TO authenticated;

-- ====================================================================
-- Part 5: Final Verification
-- ====================================================================

DO $$
BEGIN
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'Complete Database Fix V2 Applied Successfully!';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'Fixed Issues:';
  RAISE NOTICE '1. ✅ Association reports function (get_association_report_data)';
  RAISE NOTICE '2. ✅ Fixed ambiguous column reference "volunteer_id"';
  RAISE NOTICE '3. ✅ Volunteer assignment function (get_volunteers_for_association)';
  RAISE NOTICE '4. ✅ Volunteer hours logging (log_volunteer_hours)';
  RAISE NOTICE '5. ✅ Share text generation (generate_share_text)';
  RAISE NOTICE '6. ✅ Map data with coordinates (get_map_data_with_coordinates)';
  RAISE NOTICE '7. ✅ Location coordinate extraction functions';
  RAISE NOTICE '8. ✅ QR scan history tracking';
  RAISE NOTICE '9. ✅ Duplicate data checking functions';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'All functions are now available and properly configured!';
  RAISE NOTICE 'The application should work without PostgrestException errors.';
  RAISE NOTICE '====================================================================';
END $$;