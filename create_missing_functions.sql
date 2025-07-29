-- Create missing functions for the Wisaal application
-- This script creates all the missing functions that are called from the Flutter app

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

-- Grant permissions on all functions
GRANT EXECUTE ON FUNCTION log_volunteer_hours(uuid, numeric, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_share_text(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_map_data_with_coordinates() TO authenticated;
GRANT EXECUTE ON FUNCTION get_latitude_from_location(geography) TO authenticated;
GRANT EXECUTE ON FUNCTION get_longitude_from_location(geography) TO authenticated;
GRANT EXECUTE ON FUNCTION check_duplicate_user_locations() TO authenticated;
GRANT EXECUTE ON FUNCTION check_duplicate_donation_locations() TO authenticated;
GRANT EXECUTE ON FUNCTION check_duplicate_personal_data() TO authenticated;
GRANT EXECUTE ON FUNCTION get_volunteer_qr_scan_history(uuid) TO authenticated;

-- Test message
DO $$
BEGIN
  RAISE NOTICE 'Missing functions have been created successfully!';
  RAISE NOTICE 'Created functions:';
  RAISE NOTICE '- log_volunteer_hours: Log volunteer working hours';
  RAISE NOTICE '- generate_share_text: Generate sharing text for donations';
  RAISE NOTICE '- get_map_data_with_coordinates: Get map data with coordinates';
  RAISE NOTICE '- get_latitude_from_location: Extract latitude from PostGIS point';
  RAISE NOTICE '- get_longitude_from_location: Extract longitude from PostGIS point';
  RAISE NOTICE '- check_duplicate_user_locations: Check for duplicate user locations';
  RAISE NOTICE '- check_duplicate_donation_locations: Check for duplicate donation locations';
  RAISE NOTICE '- check_duplicate_personal_data: Check for duplicate personal data';
  RAISE NOTICE '- get_volunteer_qr_scan_history: Get volunteer QR scan history';
END $$;