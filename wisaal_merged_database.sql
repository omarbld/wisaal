-- ====================================================================
-- Wisaal Project: Final Complete Database Script with RLS
-- ====================================================================
-- This script combines all SQL files with comprehensive Row Level Security
-- ====================================================================

-- ====================================================================
-- Part 1: Extensions and Basic Setup
-- ====================================================================

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ====================================================================
-- Part 2: ENUM Types
-- ====================================================================

DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS donation_status CASCADE;
CREATE TYPE user_role AS ENUM ('donor', 'association', 'volunteer', 'manager');
CREATE TYPE donation_status AS ENUM ('pending', 'accepted', 'assigned', 'in_progress', 'completed', 'cancelled');

-- ====================================================================
-- Part 3: Core Tables
-- ====================================================================

-- users table
DROP TABLE IF EXISTS users CASCADE;
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name text NOT NULL,
  email text UNIQUE NOT NULL,
  role user_role NOT NULL DEFAULT 'donor',
  phone text,
  city text,
  location geography(Point, 4326),
  avatar_url text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  associated_with_association_id uuid REFERENCES users(id),
  points INT DEFAULT 0
);

-- donations table
DROP TABLE IF EXISTS donations CASCADE;
CREATE TABLE IF NOT EXISTS donations (
  donation_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  donor_id uuid REFERENCES users(id),
  association_id uuid REFERENCES users(id),
  volunteer_id uuid REFERENCES users(id),
  status donation_status NOT NULL DEFAULT 'pending',
  method_of_pickup text CHECK (method_of_pickup IN ('by_association', 'by_volunteer') OR method_of_pickup IS NULL),
  donor_qr_code text,
  association_qr_code text,
  title text NOT NULL,
  description text,
  quantity int,
  food_type text,
  expiry_date date,
  pickup_address text,
  image_path text,
  is_urgent boolean DEFAULT false,
  location geography(Point, 4326),
  created_at timestamptz DEFAULT now(),
  picked_up_at timestamptz,
  delivered_at timestamptz,
  scheduled_pickup_time TIMESTAMPTZ
);

-- notifications table
DROP TABLE IF EXISTS notifications CASCADE;
CREATE TABLE IF NOT EXISTS notifications (
  id serial PRIMARY KEY,
  user_id uuid REFERENCES users(id),
  title text NOT NULL,
  body text NOT NULL,
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- ratings table
DROP TABLE IF EXISTS ratings CASCADE;
CREATE TABLE IF NOT EXISTS ratings (
  id serial PRIMARY KEY,
  rater_id uuid NOT NULL,
  volunteer_id uuid NOT NULL,
  task_id uuid,
  rating int CHECK (rating >= 1 AND rating <= 5),
  comment text,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT ratings_rater_id_fkey FOREIGN KEY (rater_id) REFERENCES users(id),
  CONSTRAINT ratings_volunteer_id_fkey FOREIGN KEY (volunteer_id) REFERENCES users(id),
  CONSTRAINT ratings_task_id_fkey FOREIGN KEY (task_id) REFERENCES donations(donation_id)
);

-- activation_codes table
DROP TABLE IF EXISTS activation_codes CASCADE;
CREATE TABLE IF NOT EXISTS activation_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text UNIQUE NOT NULL,
  role user_role NOT NULL,
  created_by_association_id uuid REFERENCES users(id),
  is_used boolean DEFAULT false,
  used_by_user_id uuid REFERENCES users(id),
  created_at timestamptz DEFAULT now(),
  used_at timestamptz,

  max_uses integer DEFAULT 1,
  current_uses integer DEFAULT 0,
  CONSTRAINT activation_codes_role_check CHECK (role IN ('volunteer', 'manager', 'association', 'donor'))
);

-- badges table
DROP TABLE IF EXISTS badges CASCADE;
CREATE TABLE IF NOT EXISTS badges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  icon_url TEXT,
  points_required INT DEFAULT 0
);

-- user_badges table
DROP TABLE IF EXISTS user_badges CASCADE;
CREATE TABLE IF NOT EXISTS user_badges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id),
  badge_id uuid REFERENCES badges(id),
  earned_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, badge_id)
);

-- user_locations table
DROP TABLE IF EXISTS user_locations CASCADE;
CREATE TABLE IF NOT EXISTS user_locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id),
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  created_at timestamptz DEFAULT now(),
  location GEOMETRY(Point, 4326)
);

-- stats table
DROP TABLE IF EXISTS stats CASCADE;
CREATE TABLE IF NOT EXISTS stats (
  id serial PRIMARY KEY,
  total_donations_completed int DEFAULT 0,
  active_volunteers_count int DEFAULT 0,
  active_associations_count int DEFAULT 0,
  last_updated timestamptz DEFAULT now()
);

-- volunteer_logs table
DROP TABLE IF EXISTS volunteer_logs CASCADE;
CREATE TABLE IF NOT EXISTS volunteer_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  volunteer_id uuid REFERENCES users(id),
  action text NOT NULL,
  details jsonb,
  created_at timestamptz DEFAULT now()
);

-- ====================================================================
-- Part 4: Helper Functions
-- ====================================================================

-- Function to get user role
CREATE OR REPLACE FUNCTION get_user_role(user_id uuid)
RETURNS user_role AS $$
BEGIN
  RETURN (SELECT role FROM users WHERE id = user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update user location
CREATE OR REPLACE FUNCTION update_user_location(lat double precision, lng double precision)
RETURNS void AS $$
BEGIN
  INSERT INTO user_locations (user_id, latitude, longitude, location)
  VALUES (auth.uid(), lat, lng, ST_SetSRID(ST_MakePoint(lng, lat), 4326))
  ON CONFLICT (user_id) DO UPDATE SET
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    location = EXCLUDED.location,
    created_at = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get top volunteers
CREATE OR REPLACE FUNCTION get_top_volunteers(limit_count integer DEFAULT 10)
RETURNS TABLE (
  id uuid,
  full_name text,
  points integer,
  total_donations integer,
  rating decimal,
  rank bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.full_name,
    u.points,
    COALESCE(COUNT(d.donation_id)::integer, 0) as total_donations,
    COALESCE(AVG(r.rating), 0.0)::decimal as rating,
    ROW_NUMBER() OVER (ORDER BY u.points DESC, u.full_name) as rank
  FROM users u
  LEFT JOIN donations d ON u.id = d.volunteer_id AND d.status = 'completed'
  LEFT JOIN ratings r ON u.id = r.volunteer_id
  WHERE u.role = 'volunteer' AND u.is_active = true
  GROUP BY u.id, u.full_name, u.points
  ORDER BY u.points DESC, u.full_name
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get leaderboard
CREATE OR REPLACE FUNCTION get_leaderboard()
RETURNS TABLE (rank BIGINT, full_name TEXT, points INT) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ROW_NUMBER() OVER (ORDER BY u.points DESC) as rank,
    u.full_name,
    u.points
  FROM users u
  WHERE u.role = 'volunteer' AND u.is_active = true
  ORDER BY u.points DESC
  LIMIT 10;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get full leaderboard
CREATE OR REPLACE FUNCTION get_full_leaderboard()
RETURNS TABLE (rank BIGINT, full_name TEXT, points INT) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ROW_NUMBER() OVER (ORDER BY u.points DESC) as rank,
    u.full_name,
    u.points
  FROM users u
  WHERE u.role = 'volunteer' AND u.is_active = true
  ORDER BY u.points DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create notification
CREATE OR REPLACE FUNCTION create_notification(
  p_user_id uuid,
  p_title text,
  p_body text
)
RETURNS void AS $$
BEGIN
  INSERT INTO notifications (user_id, title, body)
  VALUES (p_user_id, p_title, p_body);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to use volunteer activation code
CREATE OR REPLACE FUNCTION use_volunteer_activation_code(
  activation_code_param TEXT,
  volunteer_user_id UUID
)
RETURNS UUID AS $$
DECLARE
  code_id UUID;
  association_id UUID;
BEGIN
  -- Find the code, lock the row for update, and get the details
  SELECT id, created_by_association_id INTO code_id, association_id
  FROM public.activation_codes
  WHERE code = activation_code_param AND role = 'volunteer' AND is_used = false
  FOR UPDATE;

  IF code_id IS NULL THEN
    RAISE EXCEPTION 'Invalid or already used activation code';
  END IF;

  -- Mark the code as used
  UPDATE public.activation_codes
  SET is_used = true, used_by_user_id = volunteer_user_id, used_at = now()
  WHERE id = code_id;

  -- Update the volunteer's association
  UPDATE public.users
  SET associated_with_association_id = association_id
  WHERE id = volunteer_user_id;

  RETURN association_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to generate activation code
CREATE OR REPLACE FUNCTION generate_activation_code(
  p_association_id uuid
)
RETURNS text AS $$
DECLARE
  v_code text;
BEGIN
  -- Generate unique activation code
  v_code := substr(md5(random()::text), 0, 9);

  -- Insert the code into activation_codes table
  INSERT INTO activation_codes (
    code, 
    role, 
    created_by_association_id,
    max_uses,
    current_uses,
    is_used
  )
  VALUES (
    v_code, 
    'volunteer', 
    p_association_id,
    1,                          -- Can be used once
    0,                          -- Not used yet
    false                       -- Not used
  );

  RETURN v_code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to register a new volunteer
CREATE OR REPLACE FUNCTION public.register_volunteer(
    p_user_id uuid,
    p_full_name text,
    p_email text,
    p_phone text,
    p_city text,
    p_activation_code text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    v_code_id uuid;
    v_association_id uuid;
BEGIN
    -- Step 1: Find the activation code, ensure it's for a volunteer and not used.
    -- Lock the row to prevent concurrent use of the same code.
    SELECT id, created_by_association_id INTO v_code_id, v_association_id
    FROM public.activation_codes
    WHERE code = p_activation_code AND role = 'volunteer' AND is_used = FALSE
    FOR UPDATE;

    -- Step 2: If the code is not found, raise an exception.
    IF v_code_id IS NULL THEN
        RAISE EXCEPTION 'INVALID_ACTIVATION_CODE: The provided activation code is invalid, already used, or not for a volunteer.';
    END IF;

    -- Step 3: Insert the new user's data into the users table.
    -- The volunteer is associated with the association that created the code.
    INSERT INTO public.users (id, full_name, email, phone, city, role, associated_with_association_id)
    VALUES (p_user_id, p_full_name, p_email, p_phone, p_city, 'volunteer', v_association_id);

    -- Step 4: Update the activation code to mark it as used.
    UPDATE public.activation_codes
    SET 
        is_used = TRUE,
        used_by_user_id = p_user_id,
        used_at = NOW()
    WHERE id = v_code_id;

END;
$function$;

-- Function to send bulk notification
CREATE OR REPLACE FUNCTION send_bulk_notification(p_title TEXT, p_body TEXT, p_role user_role DEFAULT NULL)
RETURNS void AS $$
DECLARE
    target_user RECORD;
BEGIN
    FOR target_user IN SELECT id FROM public.users WHERE (p_role IS NULL OR role = p_role)
    LOOP
        INSERT INTO public.notifications (user_id, title, body)
        VALUES (target_user.id, p_title, p_body);
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check and award badges
CREATE OR REPLACE FUNCTION check_and_award_badges(p_user_id uuid)
RETURNS void AS $$
DECLARE
  user_points INT;
  badge_record RECORD;
BEGIN
  -- Get the user's current points
  SELECT points INTO user_points FROM users WHERE id = p_user_id;

  -- Loop through all badges that the user has enough points for
  FOR badge_record IN
    SELECT b.id, b.name, b.points_required
    FROM badges b
    WHERE b.points_required <= user_points
      AND NOT EXISTS (
        SELECT 1 FROM user_badges ub 
        WHERE ub.user_id = p_user_id AND ub.badge_id = b.id
      )
  LOOP
    -- Award the badge
    INSERT INTO user_badges (user_id, badge_id)
    VALUES (p_user_id, badge_record.id);
    
    -- Send notification about the new badge
    PERFORM create_notification(
      p_user_id,
      'شارة جديدة!',
      'تهانينا! لقد حصلت على شارة: ' || badge_record.name
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get volunteer dashboard data
CREATE OR REPLACE FUNCTION get_volunteer_dashboard_data(p_user_id uuid)
RETURNS json AS $$
BEGIN
  RETURN (SELECT json_build_object(
    'userName', (SELECT full_name FROM users WHERE id = p_user_id),
    'total_tasks', (SELECT COUNT(*) FROM donations WHERE volunteer_id = p_user_id),
    'completed_tasks', (SELECT COUNT(*) FROM donations WHERE volunteer_id = p_user_id AND status = 'completed'),
    'in_progress_tasks', (SELECT COUNT(*) FROM donations WHERE volunteer_id = p_user_id AND status = 'in_progress'),
    'pending_tasks', (SELECT COUNT(*) FROM donations WHERE volunteer_id = p_user_id AND status = 'assigned'),
    'avg_rating', (SELECT COALESCE(AVG(rating), 0.0)::float FROM ratings WHERE volunteer_id = p_user_id),
    'total_points', (SELECT points FROM users WHERE id = p_user_id),
    'next_task', (SELECT row_to_json(d) FROM (
      SELECT donation_id, title, description, pickup_address, created_at, expiry_date, is_urgent
      FROM donations 
      WHERE volunteer_id = p_user_id AND status = 'assigned' 
      ORDER BY created_at LIMIT 1
    ) d),
    'recent_completed', (SELECT json_agg(row_to_json(d)) FROM (
      SELECT donation_id, title, delivered_at
      FROM donations 
      WHERE volunteer_id = p_user_id AND status = 'completed' 
      ORDER BY delivered_at DESC LIMIT 3
    ) d)
  ));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to generate enhanced activation code
CREATE OR REPLACE FUNCTION generate_activation_code_enhanced(
  p_association_id uuid,
  p_count integer DEFAULT 1
)
RETURNS TABLE(generated_code text, created_at timestamptz) AS $$
DECLARE
  i integer;
  new_code text;
  created_time timestamptz;
BEGIN
  FOR i IN 1..p_count LOOP
    -- إنشاء كود عشوائي من 8 أحرف
    new_code := upper(substring(md5(random()::text || clock_timestamp()::text) from 1 for 8));
    
    -- التأكد من عدم التكرار بتحديد اسم الجدول والعمود بوضوح
    WHILE EXISTS (SELECT 1 FROM public.activation_codes WHERE activation_codes.code = new_code) LOOP
      new_code := upper(substring(md5(random()::text || clock_timestamp()::text) from 1 for 8));
    END LOOP;
    
    -- إدراج الكود في قاعدة البيانات
    INSERT INTO public.activation_codes (
      code,
      role,
      created_by_association_id,
      created_at
    ) VALUES (
      new_code,
      'volunteer',
      p_association_id,
      now()
    ) RETURNING activation_codes.created_at INTO created_time;
    
    -- إرجاع القيم باستخدام أسماء أعمدة الإرجاع الجديدة
    generated_code := new_code;
    created_at := created_time;
    RETURN NEXT;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get volunteers with detailed ratings
CREATE OR REPLACE FUNCTION get_volunteers_with_detailed_ratings(p_association_id uuid)
RETURNS TABLE(
  id uuid,
  full_name text,
  email text,
  phone text,
  city text,
  points int,
  is_active boolean,
  avg_rating numeric,
  total_ratings int,
  completed_tasks int,
  pending_tasks int,
  created_at timestamptz,
  last_activity timestamptz,
  rating_breakdown json
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.full_name,
    u.email,
    u.phone,
    u.city,
    u.points,
    u.is_active,
    COALESCE(AVG(r.rating), 0) as avg_rating,
    COUNT(r.id)::int as total_ratings,
    (SELECT COUNT(*)::int FROM public.donations WHERE volunteer_id = u.id AND status = 'completed') as completed_tasks,
    (SELECT COUNT(*)::int FROM public.donations WHERE volunteer_id = u.id AND status IN ('assigned', 'in_progress')) as pending_tasks,
    u.created_at,
    COALESCE(MAX(d.delivered_at), u.created_at) as last_activity,
    json_build_object(
      'rating_1', COUNT(CASE WHEN r.rating = 1 THEN 1 END),
      'rating_2', COUNT(CASE WHEN r.rating = 2 THEN 1 END),
      'rating_3', COUNT(CASE WHEN r.rating = 3 THEN 1 END),
      'rating_4', COUNT(CASE WHEN r.rating = 4 THEN 1 END),
      'rating_5', COUNT(CASE WHEN r.rating = 5 THEN 1 END)
    ) as rating_breakdown
  FROM public.users u
  LEFT JOIN public.ratings r ON u.id = r.volunteer_id
  LEFT JOIN public.donations d ON u.id = d.volunteer_id
  WHERE u.role = 'volunteer' 
    AND u.associated_with_association_id = p_association_id
  GROUP BY u.id, u.full_name, u.email, u.phone, u.city, u.points, u.is_active, u.created_at
  ORDER BY avg_rating DESC, completed_tasks DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get manager dashboard comprehensive data
CREATE OR REPLACE FUNCTION get_manager_dashboard_comprehensive()
RETURNS json AS $$
BEGIN
  RETURN (SELECT json_build_object(
    'overview', json_build_object(
      'total_users', (SELECT COUNT(*) FROM public.users),
      'total_donations', (SELECT COUNT(*) FROM public.donations),
      'active_volunteers', (SELECT COUNT(*) FROM public.users WHERE role = 'volunteer' AND is_active = true),
      'active_associations', (SELECT COUNT(*) FROM public.users WHERE role = 'association' AND is_active = true),
      'pending_donations', (SELECT COUNT(*) FROM public.donations WHERE status = 'pending'),
      'completed_donations', (SELECT COUNT(*) FROM public.donations WHERE status = 'completed'),
      'donations_today', (SELECT COUNT(*) FROM public.donations WHERE created_at >= CURRENT_DATE),
      'completed_today', (SELECT COUNT(*) FROM public.donations WHERE status = 'completed' AND delivered_at >= CURRENT_DATE)
    ),
    'trends', json_build_object(
      'donations_this_week', (SELECT COUNT(*) FROM public.donations WHERE created_at >= date_trunc('week', CURRENT_DATE)),
      'donations_last_week', (SELECT COUNT(*) FROM public.donations WHERE created_at >= date_trunc('week', CURRENT_DATE) - interval '1 week' AND created_at < date_trunc('week', CURRENT_DATE)),
      'new_users_this_month', (SELECT COUNT(*) FROM public.users WHERE created_at >= date_trunc('month', CURRENT_DATE)),
      'top_associations', (SELECT json_agg(row_to_json(t)) FROM (
        SELECT 
          u.id,
          u.full_name,
          COUNT(d.donation_id) as total_received
        FROM public.users u
        LEFT JOIN public.donations d ON u.id = d.association_id
        WHERE u.role = 'association'
        GROUP BY u.id, u.full_name
        ORDER BY total_received DESC
        LIMIT 5
      ) t)
    )
  ));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to scan QR code enhanced
CREATE OR REPLACE FUNCTION scan_qr_code_enhanced(
  p_donation_id uuid,
  p_scan_type text,
  p_location_lat double precision DEFAULT NULL,
  p_location_lng double precision DEFAULT NULL
)
RETURNS json AS $$
DECLARE
  current_user_id uuid := auth.uid();
  donation_record RECORD;
  result json;
BEGIN
  -- Get donation details
  SELECT * INTO donation_record FROM donations WHERE donation_id = p_donation_id;
  
  IF donation_record IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Donation not found');
  END IF;
  
  IF p_scan_type = 'pickup' THEN
    -- Update donation status to in_progress and set pickup time
    UPDATE donations 
    SET status = 'in_progress', picked_up_at = now()
    WHERE donation_id = p_donation_id;
    
    result := json_build_object('success', true, 'message', 'Pickup confirmed', 'new_status', 'in_progress');
    
  ELSIF p_scan_type = 'delivery' THEN
    -- Update donation status to completed and set delivery time
    UPDATE donations 
    SET status = 'completed', delivered_at = now()
    WHERE donation_id = p_donation_id;
    
    result := json_build_object('success', true, 'message', 'Delivery confirmed', 'new_status', 'completed');
    
  ELSE
    RETURN json_build_object('success', false, 'error', 'Invalid scan type');
  END IF;
  
  -- Log the scan event
  INSERT INTO volunteer_logs (volunteer_id, action, details, created_at)
  VALUES (
    current_user_id, 
    format('QR scan: %s', p_scan_type),
    json_build_object(
      'donation_id', p_donation_id,
      'scan_type', p_scan_type,
      'location_lat', p_location_lat,
      'location_lng', p_location_lng
    ),
    now()
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get donation tracking history
CREATE OR REPLACE FUNCTION get_donation_tracking_history(p_donation_id uuid)
RETURNS json AS $$
BEGIN
  RETURN (SELECT json_build_object(
    'donation_info', (SELECT row_to_json(d) FROM (
      SELECT donation_id, title, status, created_at, picked_up_at, delivered_at,
             donor_id, association_id, volunteer_id
      FROM donations WHERE donation_id = p_donation_id
    ) d),
    'timeline', (SELECT json_agg(
      json_build_object(
        'timestamp', timeline.timestamp,
        'status', timeline.status,
        'description', timeline.description
      ) ORDER BY timeline.timestamp
    ) FROM (
      SELECT created_at as timestamp, 'created' as status, 'تم إنشاء التبرع' as description
      FROM donations WHERE donation_id = p_donation_id
      UNION ALL
      SELECT picked_up_at as timestamp, 'picked_up' as status, 'تم استلام التبرع' as description
      FROM donations WHERE donation_id = p_donation_id AND picked_up_at IS NOT NULL
      UNION ALL
      SELECT delivered_at as timestamp, 'delivered' as status, 'تم توصيل التبرع' as description
      FROM donations WHERE donation_id = p_donation_id AND delivered_at IS NOT NULL
    ) timeline),
    'participants', (SELECT json_build_object(
      'donor', (SELECT json_build_object('id', id, 'name', full_name, 'phone', phone) 
                FROM users WHERE id = (SELECT donor_id FROM donations WHERE donation_id = p_donation_id)),
      'association', (SELECT json_build_object('id', id, 'name', full_name, 'phone', phone) 
                     FROM users WHERE id = (SELECT association_id FROM donations WHERE donation_id = p_donation_id)),
      'volunteer', (SELECT json_build_object('id', id, 'name', full_name, 'phone', phone) 
                   FROM users WHERE id = (SELECT volunteer_id FROM donations WHERE donation_id = p_donation_id))
    ))
  ));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Location management functions
CREATE OR REPLACE FUNCTION extract_coordinates_from_location(location_point geography)
RETURNS TABLE(latitude double precision, longitude double precision) AS $$
BEGIN
  IF location_point IS NULL THEN
    RETURN;
  END IF;
  
  RETURN QUERY
  SELECT 
    ST_Y(location_point::geometry) as latitude,
    ST_X(location_point::geometry) as longitude;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION update_user_location_safe(
  p_latitude double precision,
  p_longitude double precision
)
RETURNS json AS $$
DECLARE
  current_user_id uuid := auth.uid();
  result json;
BEGIN
  -- Validate coordinates
  IF p_latitude IS NULL OR p_longitude IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'الإحداثيات غير صالحة'
    );
  END IF;
  
  -- Update user location
  INSERT INTO user_locations (user_id, latitude, longitude, location)
  VALUES (current_user_id, p_latitude, p_longitude, ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326))
  ON CONFLICT (user_id) DO UPDATE SET
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    location = EXCLUDED.location,
    created_at = now();
  
  RETURN json_build_object(
    'success', true,
    'latitude', p_latitude,
    'longitude', p_longitude,
    'updated_at', NOW()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_nearby_users(
  p_latitude double precision,
  p_longitude double precision,
  p_radius_km double precision DEFAULT 10,
  p_user_role text DEFAULT NULL
)
RETURNS TABLE(
  user_id uuid,
  full_name text,
  role text,
  distance_km double precision,
  latitude double precision,
  longitude double precision
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id as user_id,
    u.full_name,
    u.role::text,
    ST_Distance(
      u.location,
      ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)
    ) / 1000 as distance_km,
    ST_Y(u.location::geometry) as latitude,
    ST_X(u.location::geometry) as longitude
  FROM public.users u
  WHERE u.location IS NOT NULL
    AND (p_user_role IS NULL OR u.role::text = p_user_role)
    AND ST_DWithin(
      u.location,
      ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326),
      p_radius_km * 1000
    )
  ORDER BY distance_km ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_nearby_donations(
  p_latitude double precision,
  p_longitude double precision,
  p_radius_km double precision DEFAULT 10,
  p_status text DEFAULT 'pending'
)
RETURNS TABLE(
  donation_id uuid,
  title text,
  status text,
  distance_km double precision,
  latitude double precision,
  longitude double precision,
  donor_name text,
  food_type text,
  is_urgent boolean
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    d.donation_id,
    d.title,
    d.status::text,
    ST_Distance(
      d.location,
      ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)
    ) / 1000 as distance_km,
    ST_Y(d.location::geometry) as latitude,
    ST_X(d.location::geometry) as longitude,
    u.full_name as donor_name,
    d.food_type,
    d.is_urgent
  FROM public.donations d
  JOIN public.users u ON d.donor_id = u.id
  WHERE d.location IS NOT NULL
    AND (p_status IS NULL OR d.status::text = p_status)
    AND ST_DWithin(
      d.location,
      ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326),
      p_radius_km * 1000
    )
  ORDER BY distance_km ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================================================
-- Part 5: Row Level Security (RLS) Setup
-- ====================================================================

-- Enable RLS on all tables
ALTER TABLE activation_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE donations ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE volunteer_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_locations ENABLE ROW LEVEL SECURITY;

-- ====================================================================
-- RLS Policies for users table
-- ====================================================================

DROP POLICY IF EXISTS "Users can view their own profile, and managers/associations can view related users" ON users;
CREATE POLICY "Users can view their own profile, and managers/associations can view related users"
  ON users FOR SELECT
  USING (
    -- Users can see their own profile
    id = auth.uid() OR
    -- Managers can see everyone
    get_user_role(auth.uid()) = 'manager' OR
    -- Associations can see their volunteers and donors
    (
      get_user_role(auth.uid()) = 'association' AND (
        (role = 'volunteer' AND associated_with_association_id = auth.uid()) OR
        (id IN (SELECT donor_id FROM donations WHERE association_id = auth.uid()))
      )
    ) OR
    -- Volunteers can see the donor and association of their assigned tasks
    (
      get_user_role(auth.uid()) = 'volunteer' AND (
        id IN (SELECT donor_id FROM donations WHERE volunteer_id = auth.uid()) OR
        id IN (SELECT association_id FROM donations WHERE volunteer_id = auth.uid())
      )
    )
  );

DROP POLICY IF EXISTS "User can update own profile" ON users;
CREATE POLICY "User can update own profile"
  ON users FOR UPDATE
  USING (id = auth.uid());

DROP POLICY IF EXISTS "Users can insert their own profile" ON users;
CREATE POLICY "Users can insert their own profile"
  ON users FOR INSERT
  WITH CHECK (
    -- Allow authenticated users to insert their own profile
    auth.uid() = id OR
    -- Allow system functions to create users (for registration via activation codes)
    auth.uid() IS NULL
  );

-- ====================================================================
-- RLS Policies for donations table
-- ====================================================================

DROP POLICY IF EXISTS "Donors can manage their donations" ON donations;
CREATE POLICY "Donors can manage their donations"
  ON donations FOR ALL
  USING (donor_id = auth.uid());

DROP POLICY IF EXISTS "Associations can view and accept donations" ON donations;
CREATE POLICY "Associations can view and accept donations"
  ON donations FOR SELECT
  USING (get_user_role(auth.uid()) = 'association' AND (status = 'pending' OR association_id = auth.uid()));

DROP POLICY IF EXISTS "Associations can accept and manage their donations" ON donations;
CREATE POLICY "Associations can accept and manage their donations"
  ON donations FOR UPDATE
  USING (get_user_role(auth.uid()) = 'association' AND (status = 'pending' OR association_id = auth.uid()))
  WITH CHECK (association_id = auth.uid());

DROP POLICY IF EXISTS "Volunteers can view their assigned donations" ON donations;
CREATE POLICY "Volunteers can view their assigned donations"
  ON donations FOR SELECT
  USING (get_user_role(auth.uid()) = 'volunteer' AND volunteer_id = auth.uid());

DROP POLICY IF EXISTS "Managers can do anything" ON donations;
CREATE POLICY "Managers can do anything"
  ON donations FOR ALL
  USING (get_user_role(auth.uid()) = 'manager');

-- ====================================================================
-- RLS Policies for notifications table
-- ====================================================================

DROP POLICY IF EXISTS "Users can manage their own notifications" ON notifications;
CREATE POLICY "Users can manage their own notifications"
  ON notifications FOR ALL
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Managers can do anything" ON notifications;
CREATE POLICY "Managers can do anything"
  ON notifications FOR ALL
  USING (get_user_role(auth.uid()) = 'manager');

-- ====================================================================
-- RLS Policies for ratings table
-- ====================================================================

DROP POLICY IF EXISTS "Associations and managers can insert ratings" ON ratings;
CREATE POLICY "Associations and managers can insert ratings"
  ON ratings FOR INSERT
  WITH CHECK (get_user_role(auth.uid()) IN ('association', 'manager'));

DROP POLICY IF EXISTS "Users can view ratings" ON ratings;
CREATE POLICY "Users can view ratings"
  ON ratings FOR SELECT
  USING (
    -- Managers can view all ratings
    get_user_role(auth.uid()) = 'manager' OR
    -- Associations can view ratings of their volunteers
    (
      get_user_role(auth.uid()) = 'association' AND
      volunteer_id IN (SELECT u.id FROM users u WHERE u.associated_with_association_id = auth.uid())
    )
  );

-- ====================================================================
-- RLS Policies for activation_codes table
-- ====================================================================

-- Allow anonymous users to read activation codes for verification
DROP POLICY IF EXISTS "Anonymous can read activation codes for verification" ON activation_codes;
CREATE POLICY "Anonymous can read activation codes for verification"
  ON activation_codes FOR SELECT
  USING (true); -- Allow all users (including anonymous) to read activation codes

DROP POLICY IF EXISTS "Managers can do anything" ON activation_codes;
CREATE POLICY "Managers can do anything"
  ON activation_codes FOR ALL
  USING (get_user_role(auth.uid()) = 'manager');

DROP POLICY IF EXISTS "Associations and managers can insert activation codes" ON activation_codes;
CREATE POLICY "Associations and managers can insert activation codes"
  ON activation_codes FOR INSERT
  WITH CHECK (get_user_role(auth.uid()) IN ('association', 'manager'));

DROP POLICY IF EXISTS "System can update activation codes" ON activation_codes;
CREATE POLICY "System can update activation codes"
  ON activation_codes FOR UPDATE
  USING (
    -- Managers can update anything
    get_user_role(auth.uid()) = 'manager' OR
    -- Associations can update their own codes
    (get_user_role(auth.uid()) = 'association' AND created_by_association_id = auth.uid()) OR
    -- Allow system functions to update codes (for marking as used)
    auth.uid() IS NULL OR
    -- Allow anonymous users to update codes during registration
    true
  );

-- ====================================================================
-- RLS Policies for user_locations table
-- ====================================================================

DROP POLICY IF EXISTS "Users can insert their own location" ON user_locations;
CREATE POLICY "Users can insert their own location" ON user_locations
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own location" ON user_locations;
CREATE POLICY "Users can update their own location" ON user_locations
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Authenticated users can view all locations" ON user_locations;
CREATE POLICY "Authenticated users can view all locations" ON user_locations
  FOR SELECT USING (auth.role() = 'authenticated');

-- ====================================================================
-- RLS Policies for stats table
-- ====================================================================

DROP POLICY IF EXISTS "Managers can do anything" ON stats;
CREATE POLICY "Managers can do anything"
  ON stats FOR ALL
  USING (get_user_role(auth.uid()) = 'manager');

-- ====================================================================
-- RLS Policies for badges table
-- ====================================================================

DROP POLICY IF EXISTS "Everyone can view badges" ON badges;
CREATE POLICY "Everyone can view badges"
  ON badges FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Managers can manage badges" ON badges;
CREATE POLICY "Managers can manage badges"
  ON badges FOR ALL
  USING (get_user_role(auth.uid()) = 'manager');

-- ====================================================================
-- RLS Policies for user_badges table
-- ====================================================================

DROP POLICY IF EXISTS "Users can view their own badges" ON user_badges;
CREATE POLICY "Users can view their own badges"
  ON user_badges FOR SELECT
  USING (user_id = auth.uid() OR get_user_role(auth.uid()) = 'manager');

DROP POLICY IF EXISTS "System can award badges" ON user_badges;
CREATE POLICY "System can award badges"
  ON user_badges FOR INSERT
  WITH CHECK (get_user_role(auth.uid()) = 'manager');

-- ====================================================================
-- RLS Policies for volunteer_logs table
-- ====================================================================

DROP POLICY IF EXISTS "Volunteers can view their own logs" ON volunteer_logs;
CREATE POLICY "Volunteers can view their own logs"
  ON volunteer_logs FOR SELECT
  USING (volunteer_id = auth.uid() OR get_user_role(auth.uid()) = 'manager');

DROP POLICY IF EXISTS "System can insert volunteer logs" ON volunteer_logs;
CREATE POLICY "System can insert volunteer logs"
  ON volunteer_logs FOR INSERT
  WITH CHECK (volunteer_id = auth.uid() OR get_user_role(auth.uid()) = 'manager');

-- ====================================================================
-- Part 6: Initial Data
-- ====================================================================

-- Insert default stats row
INSERT INTO stats (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

-- Insert activation codes
DO $$
BEGIN
    -- Manager Code
    INSERT INTO public.activation_codes (code, role, max_uses, current_uses, created_by_association_id, expires_at)
    VALUES ('012006001TB', 'manager', 999, 0, NULL, NOW() + INTERVAL '5 year')
    ON CONFLICT (code) DO UPDATE SET 
        role = 'manager', expires_at = NOW() + INTERVAL '5 year', is_used = false, current_uses = 0;
    -- Association Code
    INSERT INTO public.activation_codes (code, role, max_uses, current_uses, created_by_association_id, expires_at)
    VALUES ('826627BO', 'association', 1, 0, NULL, NOW() + INTERVAL '5 year')
    ON CONFLICT (code) DO UPDATE SET 
        role = 'association', expires_at = NOW() + INTERVAL '5 year', is_used = false, current_uses = 0;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inserting/updating special activation codes: %', SQLERRM;
END $$;

-- Sample volunteer activation codes (created by system for testing)
INSERT INTO activation_codes (code, role, max_uses, current_uses, created_by_association_id) VALUES
('VOL001', 'volunteer', 1, 0, NULL),
('VOL002', 'volunteer', 1, 0, NULL),
('VOL003', 'volunteer', 1, 0, NULL),
('VOLUNTEER2024', 'volunteer', 5, 0, NULL),
('HELP2024', 'volunteer', 10, 0, NULL)
ON CONFLICT (code) DO UPDATE SET
  is_used = false,
  current_uses = 0;

-- Insert sample badges
INSERT INTO badges (name, description, icon_url, points_required) VALUES
('أول تبرع', 'شارة للتبرع الأول', 'https://example.com/first-donation.png', 1),
('متبرع سخي', 'شارة للمتبرعين النشطين', 'https://example.com/generous-donor.png', 100),
('متبرع خارق', 'شارة للمتبرعين المتميزين', 'https://example.com/super-donor.png', 500),
('متطوع مساعد', 'شارة للمتطوعين الجدد', 'https://example.com/helpful-volunteer.png', 50),
('متطوع خارق', 'شارة للمتطوعين المتميزين', 'https://example.com/super-volunteer.png', 250),
('بطل المجتمع', 'شارة للأعضاء الاستثنائيين', 'https://example.com/community-hero.png', 1000)
ON CONFLICT (name) DO NOTHING;

-- ====================================================================
-- Part 7: Views
-- ====================================================================

-- Create donations_with_coordinates view
CREATE OR REPLACE VIEW public.donations_with_coordinates AS
SELECT 
  d.donation_id,
  d.donor_id,
  d.association_id,
  d.volunteer_id,
  d.title,
  d.description,
  d.quantity,
  d.food_type,
  d.status,
  d.method_of_pickup,
  d.donor_qr_code,
  d.association_qr_code,
  d.pickup_address,
  d.image_path,
  d.is_urgent,
  d.expiry_date,
  d.created_at,
  d.picked_up_at,
  d.delivered_at,
  d.scheduled_pickup_time,
  -- Extract coordinates from PostGIS geography
  CASE 
    WHEN d.location IS NOT NULL THEN ST_Y(d.location::geometry)
    ELSE NULL
  END as latitude,
  CASE 
    WHEN d.location IS NOT NULL THEN ST_X(d.location::geometry)
    ELSE NULL
  END as longitude,
  -- Include donor information
  u_donor.full_name as donor_name,
  u_donor.phone as donor_phone,
  u_donor.email as donor_email,
  -- Include association information
  u_assoc.full_name as association_name,
  u_assoc.phone as association_phone,
  u_assoc.email as association_email,
  -- Include volunteer information
  u_vol.full_name as volunteer_name,
  u_vol.phone as volunteer_phone,
  u_vol.email as volunteer_email
FROM donations d
LEFT JOIN users u_donor ON d.donor_id = u_donor.id
LEFT JOIN users u_assoc ON d.association_id = u_assoc.id
LEFT JOIN users u_vol ON d.volunteer_id = u_vol.id;

-- Create users_with_coordinates view
CREATE OR REPLACE VIEW public.users_with_coordinates AS
SELECT 
  u.id,
  u.full_name,
  u.email,
  u.role,
  u.phone,
  u.city,
  u.avatar_url,
  u.is_active,
  u.created_at,
  u.associated_with_association_id,
  u.points,
  -- Extract coordinates from PostGIS geography
  CASE 
    WHEN u.location IS NOT NULL THEN ST_Y(u.location::geometry)
    ELSE NULL
  END as latitude,
  CASE 
    WHEN u.location IS NOT NULL THEN ST_X(u.location::geometry)
    ELSE NULL
  END as longitude
FROM users u;

-- Create volunteer_stats view
CREATE OR REPLACE VIEW public.volunteer_stats AS
SELECT 
  u.id as volunteer_id,
  u.full_name,
  u.email,
  u.phone,
  u.points,
  u.is_active,
  u.created_at,
  u.associated_with_association_id,
  -- Statistics
  COALESCE(COUNT(d.donation_id), 0) as total_tasks,
  COALESCE(COUNT(CASE WHEN d.status = 'completed' THEN 1 END), 0) as completed_tasks,
  COALESCE(COUNT(CASE WHEN d.status = 'in_progress' THEN 1 END), 0) as in_progress_tasks,
  COALESCE(COUNT(CASE WHEN d.status = 'assigned' THEN 1 END), 0) as pending_tasks,
  COALESCE(AVG(r.rating), 0) as avg_rating,
  COALESCE(COUNT(r.id), 0) as total_ratings,
  -- Latest activity
  GREATEST(u.created_at, MAX(d.delivered_at)) as last_activity
FROM users u
LEFT JOIN donations d ON u.id = d.volunteer_id
LEFT JOIN ratings r ON u.id = r.volunteer_id
WHERE u.role = 'volunteer'
GROUP BY u.id, u.full_name, u.email, u.phone, u.points, u.is_active, u.created_at, u.associated_with_association_id;

-- Create association_stats view
CREATE OR REPLACE VIEW public.association_stats AS
SELECT 
  u.id as association_id,
  u.full_name,
  u.email,
  u.phone,
  u.is_active,
  u.created_at,
  -- Statistics
  COALESCE(COUNT(d.donation_id), 0) as total_donations_received,
  COALESCE(COUNT(CASE WHEN d.status = 'completed' THEN 1 END), 0) as completed_donations,
  COALESCE(COUNT(CASE WHEN d.status = 'pending' THEN 1 END), 0) as pending_donations,
  COALESCE(COUNT(v.id), 0) as total_volunteers,
  COALESCE(COUNT(CASE WHEN v.is_active = true THEN 1 END), 0) as active_volunteers
FROM users u
LEFT JOIN donations d ON u.id = d.association_id
LEFT JOIN users v ON u.id = v.associated_with_association_id AND v.role = 'volunteer'
WHERE u.role = 'association'
GROUP BY u.id, u.full_name, u.email, u.phone, u.is_active, u.created_at;

-- Grant permissions on views
GRANT SELECT ON public.donations_with_coordinates TO authenticated;
GRANT SELECT ON public.users_with_coordinates TO authenticated;
GRANT SELECT ON public.volunteer_stats TO authenticated;
GRANT SELECT ON public.association_stats TO authenticated;

-- Enable RLS on views (they inherit from base tables)
ALTER VIEW public.donations_with_coordinates SET (security_barrier = true);
ALTER VIEW public.users_with_coordinates SET (security_barrier = true);
ALTER VIEW public.volunteer_stats SET (security_barrier = true);
ALTER VIEW public.association_stats SET (security_barrier = true);

-- ====================================================================
-- Part 8: Indexes for Performance
-- ====================================================================

CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_donations_donor_id ON donations(donor_id);
CREATE INDEX IF NOT EXISTS idx_donations_association_id ON donations(association_id);
CREATE INDEX IF NOT EXISTS idx_donations_volunteer_id ON donations(volunteer_id);
CREATE INDEX IF NOT EXISTS idx_donations_status ON donations(status);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_ratings_volunteer_id ON ratings(volunteer_id);
CREATE INDEX IF NOT EXISTS idx_activation_codes_code ON activation_codes(code);
CREATE INDEX IF NOT EXISTS idx_user_locations_user_id ON user_locations(user_id);

-- ====================================================================
-- Part 8: Grants and Permissions
-- ====================================================================

GRANT ALL ON TABLE public.user_locations TO supabase_admin;
GRANT ALL ON TABLE public.user_locations TO postgres;
GRANT SELECT ON TABLE public.user_locations TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_user_location(double precision, double precision) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_role(uuid) TO authenticated;

-- Additional missing functions from comprehensive review

-- Function to verify activation code and create user
CREATE OR REPLACE FUNCTION public.verify_activation_code_and_create_user(
    p_activation_code TEXT,
    p_email TEXT,
    p_full_name TEXT,
    p_phone TEXT DEFAULT NULL,
    p_password TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_code_record RECORD;
    v_user_id UUID;
    v_result JSON;
BEGIN
    -- Check if activation code exists and is valid
    SELECT 
        code,
        role,
        created_by_association_id,
        is_used,
        expires_at,
        current_uses,
        max_uses
    INTO v_code_record
    FROM public.activation_codes
    WHERE code = p_activation_code
    AND is_used = false
    AND expires_at > NOW()
    AND current_uses < max_uses;
    
    -- If code not found or invalid
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'كود التفعيل غير صالح أو منتهي الصلاحية'
        );
    END IF;
    
    -- Generate new user ID
    v_user_id := gen_random_uuid();
    
    -- Create new user
    INSERT INTO public.users (
        id,
        email,
        full_name,
        phone,
        role,
        is_active,
        associated_with_association_id,
        created_at,
        updated_at
    ) VALUES (
        v_user_id,
        p_email,
        p_full_name,
        p_phone,
        v_code_record.role,
        true,
        -- Link volunteer to the association that created the activation code
        CASE 
            WHEN v_code_record.role = 'volunteer' THEN v_code_record.created_by_association_id
            ELSE NULL
        END,
        NOW(),
        NOW()
    );
    
    -- Update activation code as used
    UPDATE public.activation_codes
    SET 
        current_uses = current_uses + 1,
        is_used = CASE 
            WHEN current_uses + 1 >= max_uses THEN true
            ELSE false
        END,
        used_by_user_id = v_user_id,
        used_at = NOW()
    WHERE code = p_activation_code;
    
    -- Return success result
    RETURN json_build_object(
        'success', true,
        'user_id', v_user_id,
        'role', v_code_record.role,
        'message', 'تم إنشاء الحساب بنجاح'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        -- In case of error
        RETURN json_build_object(
            'success', false,
            'error', 'حدث خطأ أثناء إنشاء الحساب: ' || SQLERRM
        );
END;
$$;

-- Function to check activation code
CREATE OR REPLACE FUNCTION public.check_activation_code(p_activation_code TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_code_record RECORD;
BEGIN
    -- Check if activation code exists and is valid
    SELECT 
        code,
        role,
        expires_at,
        is_used,
        current_uses,
        max_uses
    INTO v_code_record
    FROM public.activation_codes
    WHERE code = p_activation_code;
    
    -- If code not found
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'كود التفعيل غير موجود'
        );
    END IF;
    
    -- Check if code is expired or used
    IF v_code_record.expires_at < NOW() OR 
       v_code_record.is_used = true OR 
       v_code_record.current_uses >= v_code_record.max_uses THEN
        RETURN json_build_object(
            'success', false,
            'error', 'كود التفعيل غير صالح أو منتهي الصلاحية',
            'details', json_build_object(
                'is_used', v_code_record.is_used,
                'expires_at', v_code_record.expires_at,
                'current_uses', v_code_record.current_uses,
                'max_uses', v_code_record.max_uses
            )
        );
    END IF;
    
    -- Return valid code information
    RETURN json_build_object(
        'success', true,
        'role', v_code_record.role,
        'expires_at', v_code_record.expires_at,
        'message', 'كود التفعيل صحيح'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'حدث خطأ أثناء التحقق من الكود: ' || SQLERRM
        );
END;
$$;

-- Function to update updated_at column automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Function to get user badges
CREATE OR REPLACE FUNCTION get_user_badges(p_user_id uuid)
RETURNS TABLE(
  badge_id uuid,
  badge_name text,
  badge_description text,
  badge_icon_url text,
  earned_at timestamptz
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    b.id as badge_id,
    b.name as badge_name,
    b.description as badge_description,
    b.icon_url as badge_icon_url,
    ub.earned_at
  FROM user_badges ub
  JOIN badges b ON ub.badge_id = b.id
  WHERE ub.user_id = p_user_id
  ORDER BY ub.earned_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get donations for map
CREATE OR REPLACE FUNCTION get_donations_for_map()
RETURNS TABLE(
  donation_id uuid,
  title text,
  status text,
  latitude double precision,
  longitude double precision,
  is_urgent boolean,
  created_at timestamptz
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    d.donation_id,
    d.title,
    d.status::text,
    ST_Y(d.location::geometry) as latitude,
    ST_X(d.location::geometry) as longitude,
    d.is_urgent,
    d.created_at
  FROM donations d
  WHERE d.location IS NOT NULL
    AND d.status IN ('pending', 'accepted', 'assigned')
  ORDER BY d.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get all donations for map (manager view)
CREATE OR REPLACE FUNCTION get_all_donations_for_map()
RETURNS TABLE(
  donation_id uuid,
  title text,
  status text,
  latitude double precision,
  longitude double precision,
  is_urgent boolean,
  donor_name text,
  association_name text,
  volunteer_name text,
  created_at timestamptz
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    d.donation_id,
    d.title,
    d.status::text,
    ST_Y(d.location::geometry) as latitude,
    ST_X(d.location::geometry) as longitude,
    d.is_urgent,
    u_donor.full_name as donor_name,
    u_assoc.full_name as association_name,
    u_vol.full_name as volunteer_name,
    d.created_at
  FROM donations d
  LEFT JOIN users u_donor ON d.donor_id = u_donor.id
  LEFT JOIN users u_assoc ON d.association_id = u_assoc.id
  LEFT JOIN users u_vol ON d.volunteer_id = u_vol.id
  WHERE d.location IS NOT NULL
  ORDER BY d.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get volunteers for association
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

-- Function to get volunteers with ratings
CREATE OR REPLACE FUNCTION get_volunteers_with_ratings(association_id_param uuid)
RETURNS TABLE(
  volunteer_id uuid,
  volunteer_name text,
  volunteer_email text,
  volunteer_phone text,
  avg_rating numeric,
  total_ratings int,
  completed_donations int,
  points int,
  is_active boolean
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id as volunteer_id,
    u.full_name as volunteer_name,
    u.email as volunteer_email,
    u.phone as volunteer_phone,
    COALESCE(AVG(r.rating), 0) as avg_rating,
    COUNT(r.id)::int as total_ratings,
    (SELECT COUNT(*)::int FROM donations WHERE volunteer_id = u.id AND status = 'completed') as completed_donations,
    u.points,
    u.is_active
  FROM users u
  LEFT JOIN ratings r ON u.id = r.volunteer_id
  WHERE u.role = 'volunteer' 
    AND u.associated_with_association_id = association_id_param
  GROUP BY u.id, u.full_name, u.email, u.phone, u.points, u.is_active
  ORDER BY avg_rating DESC, completed_donations DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get volunteer logs
CREATE OR REPLACE FUNCTION get_volunteer_logs(p_volunteer_id uuid)
RETURNS TABLE(
  log_id uuid,
  action text,
  details jsonb,
  created_at timestamptz
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    vl.id as log_id,
    vl.action,
    vl.details,
    vl.created_at
  FROM volunteer_logs vl
  WHERE vl.volunteer_id = p_volunteer_id
  ORDER BY vl.created_at DESC
  LIMIT 50;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions on functions
GRANT EXECUTE ON FUNCTION public.verify_activation_code_and_create_user TO authenticated;
GRANT EXECUTE ON FUNCTION public.verify_activation_code_and_create_user TO anon;

-- Simple function to check if activation code is valid
CREATE OR REPLACE FUNCTION public.is_activation_code_valid(p_activation_code TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.activation_codes
        WHERE code = p_activation_code
        AND is_used = false
        AND expires_at > NOW()
        AND current_uses < max_uses
    );
END;
$$;

-- Function to get activation code details
CREATE OR REPLACE FUNCTION public.get_activation_code_details(p_activation_code TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_code_record RECORD;
BEGIN
    SELECT 
        code,
        role,
        created_by_association_id,
        is_used,
        expires_at,
        current_uses,
        max_uses
    INTO v_code_record
    FROM public.activation_codes
    WHERE code = p_activation_code
    AND is_used = false
    AND expires_at > NOW()
    AND current_uses < max_uses;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'valid', false,
            'error', 'كود التفعيل غير صالح أو منتهي الصلاحية'
        );
    END IF;
    
    RETURN json_build_object(
        'valid', true,
        'role', v_code_record.role,
        'created_by_association_id', v_code_record.created_by_association_id
    );
END;
$$;

-- Grant permissions on new functions
GRANT EXECUTE ON FUNCTION public.is_activation_code_valid TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_activation_code_valid TO anon;
GRANT EXECUTE ON FUNCTION public.get_activation_code_details TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_activation_code_details TO anon;

-- Function to use activation code and link user to association
CREATE OR REPLACE FUNCTION public.use_activation_code_for_user(
    p_user_id UUID,
    p_activation_code TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_code_record RECORD;
BEGIN
    -- Check if activation code exists and is valid
    SELECT 
        code,
        role,
        created_by_association_id,
        is_used,
        expires_at,
        current_uses,
        max_uses
    INTO v_code_record
    FROM public.activation_codes
    WHERE code = p_activation_code
    AND is_used = false
    AND expires_at > NOW()
    AND current_uses < max_uses;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'كود التفعيل غير صالح أو منتهي الصلاحية'
        );
    END IF;
    
    -- Update user with association link if volunteer
    IF v_code_record.role = 'volunteer' AND v_code_record.created_by_association_id IS NOT NULL THEN
        UPDATE public.users
        SET 
            associated_with_association_id = v_code_record.created_by_association_id,
            role = v_code_record.role,
            updated_at = NOW()
        WHERE id = p_user_id;
    ELSE
        UPDATE public.users
        SET 
            role = v_code_record.role,
            updated_at = NOW()
        WHERE id = p_user_id;
    END IF;
    
    -- Mark activation code as used
    UPDATE public.activation_codes
    SET 
        is_used = true,
        current_uses = current_uses + 1,
        used_by_user_id = p_user_id,
        used_at = NOW()
    WHERE code = p_activation_code;
    
    RETURN json_build_object(
        'success', true,
        'role', v_code_record.role,
        'association_id', v_code_record.created_by_association_id,
        'message', 'تم ربط المستخدم بالجمعية بنجاح'
    );
END;
$$;

-- Grant permissions on the new function
GRANT EXECUTE ON FUNCTION public.use_activation_code_for_user TO authenticated;
GRANT EXECUTE ON FUNCTION public.use_activation_code_for_user TO anon;
GRANT EXECUTE ON FUNCTION public.check_activation_code TO anon;
GRANT EXECUTE ON FUNCTION public.check_activation_code TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_badges(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_donations_for_map() TO authenticated;
GRANT EXECUTE ON FUNCTION get_all_donations_for_map() TO authenticated;
GRANT EXECUTE ON FUNCTION get_volunteers_for_association(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_volunteers_with_ratings(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_volunteer_logs(uuid) TO authenticated;

-- ====================================================================
-- Final Verification
-- ====================================================================

DO $$
BEGIN
  RAISE NOTICE 'Wisaal Database with RLS Setup Completed Successfully!';
  RAISE NOTICE 'Tables created: %', (SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public');
  RAISE NOTICE 'Functions created: %', (SELECT count(*) FROM information_schema.routines WHERE routine_schema = 'public');
  RAISE NOTICE 'Policies created: %', (SELECT count(*) FROM pg_policies WHERE schemaname = 'public');
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'Database is ready for use with comprehensive RLS!';
  RAISE NOTICE '====================================================================';
END $$;

-- ====================================================================
-- END OF WISAAL COMPLETE DATABASE SCRIPT WITH RLS
-- ====================================================================

-- ====================================================================
-- Wisaal Website: Using Application Data
-- ====================================================================
-- This migration creates website views and functions that use the 
-- existing application data without creating separate tables
-- ====================================================================

-- ====================================================================
-- Part 1: Website-specific Tables (only what's not in the app)
-- ====================================================================

-- Partnership requests table (website only)
DROP TABLE IF EXISTS partnership_requests CASCADE;
CREATE TABLE IF NOT EXISTS partnership_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_name text NOT NULL,
  organization_type text NOT NULL,
  contact_person text NOT NULL,
  email text NOT NULL,
  phone text,
  description text,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Contact messages table (website only)
DROP TABLE IF EXISTS contact_messages CASCADE;
CREATE TABLE IF NOT EXISTS contact_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  email text NOT NULL,
  phone text,
  subject text,
  message text NOT NULL,
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Newsletter subscriptions table (website only)
DROP TABLE IF EXISTS newsletter_subscriptions CASCADE;
CREATE TABLE IF NOT EXISTS newsletter_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  name text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- ====================================================================
-- Part 2: Website Views (using application data)
-- ====================================================================

-- View for website statistics using real app data
CREATE OR REPLACE VIEW website_statistics AS
SELECT 
  (SELECT COUNT(*) FROM donations WHERE status = 'completed') as total_donations_completed,
  (SELECT COUNT(*) FROM users WHERE role = 'volunteer' AND is_active = true) as active_volunteers_count,
  (SELECT COUNT(*) FROM users WHERE role = 'association' AND is_active = true) as active_associations_count,
  (SELECT COUNT(*) FROM users WHERE is_active = true) as total_users_count,
  (SELECT COALESCE(SUM(quantity), 0) FROM donations WHERE status = 'completed') as total_meals_saved,
  (SELECT COUNT(*) FROM partnership_requests WHERE status = 'pending') as partnerships_pending,
  (SELECT COUNT(*) FROM partnership_requests WHERE status = 'approved') as partnerships_approved,
  NOW() as last_updated;

-- View for recent donations for website display
CREATE OR REPLACE VIEW website_recent_donations AS
SELECT 
  d.donation_id as id,
  d.title,
  d.description,
  d.quantity,
  d.food_type,
  u_donor.full_name as donor_name,
  u_assoc.full_name as association_name,
  d.created_at,
  d.status
FROM donations d
LEFT JOIN users u_donor ON d.donor_id = u_donor.id
LEFT JOIN users u_assoc ON d.association_id = u_assoc.id
WHERE d.status = 'completed'
ORDER BY d.created_at DESC;

-- View for website user counts by type
CREATE OR REPLACE VIEW website_user_stats AS
SELECT 
  role as user_type,
  COUNT(*) as count,
  COUNT(CASE WHEN is_active = true THEN 1 END) as active_count
FROM users 
GROUP BY role;

-- View for monthly donation trends
CREATE OR REPLACE VIEW website_monthly_trends AS
SELECT 
  DATE_TRUNC('month', created_at) as month,
  COUNT(*) as donations_count,
  SUM(quantity) as total_quantity,
  COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_count
FROM donations 
WHERE created_at >= NOW() - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month DESC;

-- ====================================================================
-- Part 3: Website Functions
-- ====================================================================

-- Function to get website statistics (using real app data)
CREATE OR REPLACE FUNCTION get_website_statistics()
RETURNS json AS $$
BEGIN
  RETURN (
    SELECT json_build_object(
      'total_donations', total_donations_completed,
      'total_users', total_users_count,
      'active_volunteers', active_volunteers_count,
      'active_associations', active_associations_count,
      'total_meals', total_meals_saved,
      'partnerships_pending', partnerships_pending,
      'partnerships_approved', partnerships_approved,
      'last_updated', last_updated
    )
    FROM website_statistics
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get recent donations for website
CREATE OR REPLACE FUNCTION get_recent_donations_for_website(limit_count int DEFAULT 10)
RETURNS TABLE(
  id uuid,
  title text,
  description text,
  quantity int,
  food_type text,
  donor_name text,
  association_name text,
  created_at timestamptz
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    wrd.id,
    wrd.title,
    wrd.description,
    wrd.quantity,
    wrd.food_type,
    wrd.donor_name,
    wrd.association_name,
    wrd.created_at
  FROM website_recent_donations wrd
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user statistics by type
CREATE OR REPLACE FUNCTION get_user_statistics_by_type()
RETURNS json AS $$
BEGIN
  RETURN (
    SELECT json_agg(
      json_build_object(
        'user_type', user_type,
        'total_count', count,
        'active_count', active_count
      )
    )
    FROM website_user_stats
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get monthly trends
CREATE OR REPLACE FUNCTION get_monthly_donation_trends()
RETURNS json AS $$
BEGIN
  RETURN (
    SELECT json_agg(
      json_build_object(
        'month', month,
        'donations_count', donations_count,
        'total_quantity', total_quantity,
        'completed_count', completed_count
      )
      ORDER BY month DESC
    )
    FROM website_monthly_trends
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to add partnership request
CREATE OR REPLACE FUNCTION add_partnership_request(
  p_organization_name text,
  p_organization_type text,
  p_contact_person text,
  p_email text,
  p_phone text DEFAULT NULL,
  p_description text DEFAULT NULL
)
RETURNS json AS $$
DECLARE
  new_request_id uuid;
BEGIN
  INSERT INTO partnership_requests (
    organization_name,
    organization_type,
    contact_person,
    email,
    phone,
    description
  ) VALUES (
    p_organization_name,
    p_organization_type,
    p_contact_person,
    p_email,
    p_phone,
    p_description
  ) RETURNING id INTO new_request_id;
  
  RETURN json_build_object(
    'success', true,
    'id', new_request_id,
    'message', 'تم إرسال طلب الشراكة بنجاح'
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', 'حدث خطأ أثناء إرسال الطلب: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to add contact message
CREATE OR REPLACE FUNCTION add_contact_message(
  p_name text,
  p_email text,
  p_message text,
  p_phone text DEFAULT NULL,
  p_subject text DEFAULT NULL
)
RETURNS json AS $$
DECLARE
  new_message_id uuid;
BEGIN
  INSERT INTO contact_messages (
    name,
    email,
    phone,
    subject,
    message
  ) VALUES (
    p_name,
    p_email,
    p_phone,
    p_subject,
    p_message
  ) RETURNING id INTO new_message_id;
  
  RETURN json_build_object(
    'success', true,
    'id', new_message_id,
    'message', 'تم إرسال رسالتك بنجاح'
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', 'حدث خطأ أثناء إرسال الرسالة: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to subscribe to newsletter
CREATE OR REPLACE FUNCTION subscribe_newsletter(
  p_email text,
  p_name text DEFAULT NULL
)
RETURNS json AS $$
DECLARE
  subscription_id uuid;
BEGIN
  INSERT INTO newsletter_subscriptions (email, name)
  VALUES (p_email, p_name)
  ON CONFLICT (email) DO UPDATE SET
    name = COALESCE(EXCLUDED.name, newsletter_subscriptions.name),
    is_active = true
  RETURNING id INTO subscription_id;
  
  RETURN json_build_object(
    'success', true,
    'id', subscription_id,
    'message', 'تم الاشتراك في النشرة البريدية بنجاح'
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', 'حدث خطأ أثناء الاشتراك: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get top performing associations
CREATE OR REPLACE FUNCTION get_top_associations(limit_count int DEFAULT 5)
RETURNS TABLE(
  association_id uuid,
  association_name text,
  total_donations_received int,
  total_meals_distributed int,
  active_volunteers int
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id as association_id,
    u.full_name as association_name,
    COUNT(d.donation_id)::int as total_donations_received,
    COALESCE(SUM(d.quantity), 0)::int as total_meals_distributed,
    (SELECT COUNT(*)::int FROM users v WHERE v.associated_with_association_id = u.id AND v.role = 'volunteer' AND v.is_active = true) as active_volunteers
  FROM users u
  LEFT JOIN donations d ON u.id = d.association_id AND d.status = 'completed'
  WHERE u.role = 'association' AND u.is_active = true
  GROUP BY u.id, u.full_name
  ORDER BY total_donations_received DESC, total_meals_distributed DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get top volunteers
CREATE OR REPLACE FUNCTION get_top_volunteers_for_website(limit_count int DEFAULT 5)
RETURNS TABLE(
  volunteer_id uuid,
  volunteer_name text,
  total_tasks int,
  completed_tasks int,
  points int,
  avg_rating numeric
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id as volunteer_id,
    u.full_name as volunteer_name,
    COUNT(d.donation_id)::int as total_tasks,
    COUNT(CASE WHEN d.status = 'completed' THEN 1 END)::int as completed_tasks,
    u.points,
    COALESCE(AVG(r.rating), 0) as avg_rating
  FROM users u
  LEFT JOIN donations d ON u.id = d.volunteer_id
  LEFT JOIN ratings r ON u.id = r.volunteer_id
  WHERE u.role = 'volunteer' AND u.is_active = true
  GROUP BY u.id, u.full_name, u.points
  ORDER BY u.points DESC, completed_tasks DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================================================
-- Part 4: Triggers for website tables
-- ====================================================================

-- Function to update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for partnership_requests
DROP TRIGGER IF EXISTS update_partnership_requests_updated_at ON partnership_requests;
CREATE TRIGGER update_partnership_requests_updated_at 
    BEFORE UPDATE ON partnership_requests 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ====================================================================
-- Part 5: Row Level Security for website tables
-- ====================================================================

-- Enable RLS on website-specific tables
ALTER TABLE partnership_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE newsletter_subscriptions ENABLE ROW LEVEL SECURITY;

-- Public policies for website functionality
DROP POLICY IF EXISTS "Public can read partnership requests" ON partnership_requests;
CREATE POLICY "Public can read partnership requests" ON partnership_requests
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Anyone can insert partnership requests" ON partnership_requests;
CREATE POLICY "Anyone can insert partnership requests" ON partnership_requests
  FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Anyone can insert contact messages" ON contact_messages;
CREATE POLICY "Anyone can insert contact messages" ON contact_messages
  FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Anyone can subscribe to newsletter" ON newsletter_subscriptions;
CREATE POLICY "Anyone can subscribe to newsletter" ON newsletter_subscriptions
  FOR INSERT WITH CHECK (true);

-- Update existing RLS policies to allow public reading for website
DROP POLICY IF EXISTS "Public can read basic user data for stats" ON users;
CREATE POLICY "Public can read basic user data for stats" ON users
  FOR SELECT USING (
    role IN ('association', 'volunteer', 'donor') AND is_active = true
  );

DROP POLICY IF EXISTS "Public can read basic donation data for stats" ON donations;
CREATE POLICY "Public can read basic donation data for stats" ON donations
  FOR SELECT USING (
    status IN ('completed', 'in_progress', 'assigned', 'accepted', 'pending')
  );

-- ====================================================================
-- Part 6: Sample data for website-specific tables
-- ====================================================================

-- Insert sample partnership requests
INSERT INTO partnership_requests (organization_name, organization_type, contact_person, email, phone, description, status) VALUES
('مطعم الأصالة', 'restaurant', 'أحمد محمد', 'ahmed@asala-restaurant.com', '+966511234567', 'مطعم يرغب في التبرع بالوجبات الفائضة يومياً', 'approved'),
('فندق الفخامة', 'hotel', 'سارة أحمد', 'sara@luxury-hotel.com', '+966512345678', 'فندق 5 نجوم يريد المساهمة في برنامج التبرع بالطعام', 'approved'),
('سوبر ماركت الوفرة', 'supermarket', 'فاطمة خالد', 'fatima@wafra-market.com', '+966514567890', 'سوبر ماركت يريد التبرع بالمنتجات قريبة الانتهاء', 'pending'),
('مخبز الحي', 'bakery', 'محمد علي', 'mohammed@neighborhood-bakery.com', '+966515678901', 'مخبز محلي يريد التبرع بالخبز الفائض', 'pending'),
('كافيه القهوة', 'cafe', 'نورا سالم', 'nora@coffee-cafe.com', '+966516789012', 'كافيه يريد التبرع بالمعجنات والساندويتشات', 'approved')
ON CONFLICT DO NOTHING;

-- ====================================================================
-- Part 7: Indexes for performance
-- ====================================================================

CREATE INDEX IF NOT EXISTS idx_partnership_requests_status ON partnership_requests(status);
CREATE INDEX IF NOT EXISTS idx_contact_messages_created_at ON contact_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_newsletter_subscriptions_active ON newsletter_subscriptions(is_active);

-- ====================================================================
-- Part 8: Grant permissions
-- ====================================================================

-- Grant permissions on views
GRANT SELECT ON website_statistics TO anon;
GRANT SELECT ON website_statistics TO authenticated;
GRANT SELECT ON website_recent_donations TO anon;
GRANT SELECT ON website_recent_donations TO authenticated;
GRANT SELECT ON website_user_stats TO anon;
GRANT SELECT ON website_user_stats TO authenticated;
GRANT SELECT ON website_monthly_trends TO anon;
GRANT SELECT ON website_monthly_trends TO authenticated;

-- Grant permissions on functions
GRANT EXECUTE ON FUNCTION get_website_statistics() TO anon;
GRANT EXECUTE ON FUNCTION get_website_statistics() TO authenticated;
GRANT EXECUTE ON FUNCTION get_recent_donations_for_website(int) TO anon;
GRANT EXECUTE ON FUNCTION get_recent_donations_for_website(int) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_statistics_by_type() TO anon;
GRANT EXECUTE ON FUNCTION get_user_statistics_by_type() TO authenticated;
GRANT EXECUTE ON FUNCTION get_monthly_donation_trends() TO anon;
GRANT EXECUTE ON FUNCTION get_monthly_donation_trends() TO authenticated;
GRANT EXECUTE ON FUNCTION add_partnership_request(text, text, text, text, text, text) TO anon;
GRANT EXECUTE ON FUNCTION add_partnership_request(text, text, text, text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION add_contact_message(text, text, text, text, text) TO anon;
GRANT EXECUTE ON FUNCTION add_contact_message(text, text, text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION subscribe_newsletter(text, text) TO anon;
GRANT EXECUTE ON FUNCTION subscribe_newsletter(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION get_top_associations(int) TO anon;
GRANT EXECUTE ON FUNCTION get_top_associations(int) TO authenticated;
GRANT EXECUTE ON FUNCTION get_top_volunteers_for_website(int) TO anon;
GRANT EXECUTE ON FUNCTION get_top_volunteers_for_website(int) TO authenticated;

-- ====================================================================
-- Final verification
-- ====================================================================

DO $$
BEGIN
  RAISE NOTICE 'Wisaal Website Integration with App Data Completed Successfully!';
  RAISE NOTICE 'Website Views: %', (SELECT count(*) FROM information_schema.views WHERE table_schema = 'public' AND table_name LIKE 'website_%');
  RAISE NOTICE 'Website Functions: %', (SELECT count(*) FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name LIKE '%website%');
  RAISE NOTICE 'Partnership Requests: %', (SELECT COUNT(*) FROM partnership_requests);
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'Website now uses real application data!';
  RAISE NOTICE 'Statistics are calculated from actual users and donations tables.';
  RAISE NOTICE '====================================================================';
END $$;

-- ====================================================================
-- END OF WISAAL WEBSITE INTEGRATION SCRIPT
-- ====================================================================
