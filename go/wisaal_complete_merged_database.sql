-- ====================================================================
-- Wisaal Project: Complete Merged Database Script
-- ====================================================================
-- This script combines all SQL files into a single, comprehensive database setup
-- Execute this entire script in your Supabase SQL editor to set up the complete database
-- ====================================================================

-- ====================================================================
-- Part 1: Extensions and Basic Setup
-- ====================================================================

-- تفعيل PostGIS إذا لم تكن مفعلة
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ====================================================================
-- Part 2: ENUM Types
-- ====================================================================

-- تعريف ENUM للأدوار
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

-- stats table
DROP TABLE IF EXISTS stats CASCADE;
CREATE TABLE IF NOT EXISTS stats (
  id serial PRIMARY KEY,
  total_donations_completed int DEFAULT 0,
  active_volunteers_count int DEFAULT 0,
  active_associations_count int DEFAULT 0,
  last_updated timestamptz DEFAULT now()
);

-- Insert a default row for stats
INSERT INTO stats (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

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

-- volunteer_logs table
DROP TABLE IF EXISTS volunteer_logs CASCADE;
CREATE TABLE IF NOT EXISTS volunteer_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  volunteer_id uuid REFERENCES users(id),
  donation_id uuid REFERENCES donations(donation_id),
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ,
  notes TEXT
);

-- activation_codes table
DROP TABLE IF EXISTS activation_codes CASCADE;
CREATE TABLE IF NOT EXISTS activation_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text UNIQUE NOT NULL,
  role user_role NOT NULL DEFAULT 'donor',
  is_used boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  created_by_association_id uuid REFERENCES users(id),
  used_by_user_id uuid REFERENCES users(id)
);

-- user_locations table for real-time tracking
DROP TABLE IF EXISTS user_locations CASCADE;
CREATE TABLE IF NOT EXISTS public.user_locations (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  last_seen TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  location GEOMETRY(Point, 4326)
);

-- Sample data for activation codes
INSERT INTO activation_codes (code, role) VALUES
('826627BO', 'association'),
('01200602TB', 'manager')
ON CONFLICT (code) DO NOTHING;

-- ====================================================================
-- Part 4: Indexes for Performance
-- ====================================================================

-- إنشاء فهارس لتحسين الأداء
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_city ON users(city);
CREATE INDEX IF NOT EXISTS idx_donations_donor_id ON donations(donor_id);
CREATE INDEX IF NOT EXISTS idx_donations_association_id ON donations(association_id);
CREATE INDEX IF NOT EXISTS idx_donations_volunteer_id ON donations(volunteer_id);
CREATE INDEX IF NOT EXISTS idx_donations_status ON donations(status);
CREATE INDEX IF NOT EXISTS idx_donations_food_type ON donations(food_type);
CREATE INDEX IF NOT EXISTS idx_donations_location ON donations USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_users_location ON users USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_donations_created_at ON donations(created_at);
CREATE INDEX IF NOT EXISTS idx_donations_expiry_date ON donations(expiry_date);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);
CREATE INDEX IF NOT EXISTS idx_ratings_rater_id ON ratings(rater_id);
CREATE INDEX IF NOT EXISTS idx_ratings_volunteer_id ON ratings(volunteer_id);
CREATE INDEX IF NOT EXISTS idx_ratings_created_at ON ratings(created_at);
CREATE INDEX IF NOT EXISTS idx_user_badges_user_id ON user_badges(user_id);
CREATE INDEX IF NOT EXISTS idx_user_badges_badge_id ON user_badges(badge_id);
CREATE INDEX IF NOT EXISTS idx_volunteer_logs_volunteer_id ON volunteer_logs(volunteer_id);
CREATE INDEX IF NOT EXISTS idx_volunteer_logs_donation_id ON volunteer_logs(donation_id);

-- ====================================================================
-- Part 5: Helper Functions
-- ====================================================================

-- Helper function to get user role
CREATE OR REPLACE FUNCTION get_user_role(user_id uuid)
RETURNS text AS $$
  SELECT u.role::text FROM public.users u WHERE u.id = user_id;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- دالة لإنشاء إشعار جديد
CREATE OR REPLACE FUNCTION create_notification(
  p_user_id uuid,
  p_title text,
  p_body text
)
RETURNS void AS $$
BEGIN
  INSERT INTO notifications(user_id, title, body)
  VALUES (p_user_id, p_title, p_body);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================================================
-- Part 6: Core Business Logic Functions
-- ====================================================================

-- Function to use an activation code and get the association ID
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

  -- If no code is found, raise an exception
  IF code_id IS NULL THEN
    RAISE EXCEPTION 'Activation code is invalid or has already been used.';
  END IF;

  -- Mark the code as used
  UPDATE public.activation_codes
  SET
    is_used = true,
    used_by_user_id = volunteer_user_id
  WHERE id = code_id;

  -- Return the association ID
  RETURN association_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to register a volunteer with activation code
CREATE OR REPLACE FUNCTION register_volunteer(
  p_user_id uuid,
  p_full_name text,
  p_email text,
  p_phone text,
  p_city text,
  p_activation_code text
)
RETURNS void AS $$
DECLARE
  v_association_id uuid;
BEGIN
  -- 1. التحقق من كود التفعيل والحصول على معرف الجمعية
  SELECT created_by_association_id INTO v_association_id
  FROM public.activation_codes
  WHERE code = p_activation_code AND role = 'volunteer' AND is_used = false;

  -- إذا لم يتم العثور على الكود، أرجع خطأ
  IF v_association_id IS NULL THEN
    RAISE EXCEPTION 'كود التفعيل غير صالح أو تم استخدامه بالفعل.';
  END IF;

  -- 2. إدخال بيانات المتطوع الجديد باستخدام معرف المستخدم من نظام المصادقة
  INSERT INTO public.users (id, full_name, email, phone, city, role, is_active, associated_with_association_id)
  VALUES (p_user_id, p_full_name, p_email, p_phone, p_city, 'volunteer', true, v_association_id);

  -- 3. تحديث حالة كود التفعيل لـ "مستخدم"
  UPDATE public.activation_codes
  SET is_used = true, used_by_user_id = p_user_id
  WHERE code = p_activation_code;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to generate activation codes for volunteers
CREATE OR REPLACE FUNCTION generate_activation_code(
  p_association_id uuid
)
RETURNS text AS $$
DECLARE
  v_code text;
BEGIN
  -- إنشاء كود تفعيل فريد
  v_code := substr(md5(random()::text), 0, 9);

  -- إدراج الكود في جدول أكواد التفعيل
  INSERT INTO activation_codes (code, role, created_by_association_id)
  VALUES (v_code, 'volunteer', p_association_id);

  RETURN v_code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to handle scanning the donor's QR code
CREATE OR REPLACE FUNCTION scan_donor_qr_code(
  p_donation_id uuid
)
RETURNS void AS $$
DECLARE
    current_user_id uuid := auth.uid();
BEGIN
  UPDATE donations
  SET
    status = 'in_progress',
    picked_up_at = now()
  WHERE
    donation_id = p_donation_id AND
    volunteer_id = current_user_id AND
    status = 'assigned';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to handle scanning the association's QR code
CREATE OR REPLACE FUNCTION scan_association_qr_code(
  p_donation_id uuid
)
RETURNS void AS $$
DECLARE
    current_user_id uuid := auth.uid();
BEGIN
  UPDATE donations
  SET
    status = 'completed',
    delivered_at = now()
  WHERE
    donation_id = p_donation_id AND
    volunteer_id = current_user_id AND
    status = 'in_progress';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to send bulk notifications to users based on their role
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

-- ====================================================================
-- Part 7: Gamification Functions
-- ====================================================================

-- Function to award points to a volunteer for a completed donation
CREATE OR REPLACE FUNCTION award_points_for_donation(
  p_volunteer_id uuid,
  p_points INT
)
RETURNS void AS $$
BEGIN
  UPDATE users
  SET points = points + p_points
  WHERE id = p_volunteer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check for and award new badges
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
    SELECT id FROM badges WHERE points_required <= user_points
  LOOP
    -- Check if the user already has the badge
    IF NOT EXISTS (SELECT 1 FROM user_badges WHERE user_id = p_user_id AND badge_id = badge_record.id) THEN
      -- Award the new badge
      INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, badge_record.id);
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get a user's earned badges
CREATE OR REPLACE FUNCTION get_user_badges(p_user_id uuid)
RETURNS TABLE (name TEXT, description TEXT, icon_url TEXT, earned_at TIMESTAMPTZ) AS $$
BEGIN
  RETURN QUERY
  SELECT b.name, b.description, b.icon_url, ub.earned_at
  FROM user_badges ub
  JOIN badges b ON ub.badge_id = b.id
  WHERE ub.user_id = p_user_id
  ORDER BY ub.earned_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get the leaderboard
CREATE OR REPLACE FUNCTION get_leaderboard()
RETURNS TABLE (rank BIGINT, full_name TEXT, points INT) AS $$
BEGIN
  RETURN QUERY
  SELECT
    rank() OVER (ORDER BY u.points DESC) as rank,
    u.full_name,
    u.points
  FROM users u
  WHERE u.role = 'volunteer'
  ORDER BY u.points DESC
  LIMIT 10;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get the full leaderboard for manager view
CREATE OR REPLACE FUNCTION get_full_leaderboard()
RETURNS TABLE (rank BIGINT, full_name TEXT, points INT) AS $$
BEGIN
  RETURN QUERY
  SELECT
    rank() OVER (ORDER BY u.points DESC) as rank,
    u.full_name,
    u.points
  FROM users u
  WHERE u.role = 'volunteer'
  ORDER BY u.points DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get gamification data
CREATE OR REPLACE FUNCTION get_gamification_data(p_user_id uuid)
RETURNS TABLE(
  user_points int,
  user_rank int,
  total_users int,
  badges_earned json,
  next_badge json,
  leaderboard json
) AS $
BEGIN
  RETURN QUERY
  SELECT 
    u.points as user_points,
    (SELECT COUNT(*)::int + 1 FROM public.users WHERE points > u.points AND role = u.role) as user_rank,
    (SELECT COUNT(*)::int FROM public.users WHERE role = u.role) as total_users,
    (SELECT COALESCE(json_agg(
       json_build_object(
         'id', b.id,
         'name', b.name,
         'description', b.description,
         'icon_url', b.icon_url,
         'earned_at', ub.earned_at
       )
     ), '[]'::json)
     FROM public.user_badges ub
     JOIN public.badges b ON ub.badge_id = b.id
     WHERE ub.user_id = p_user_id
    ) as badges_earned,
    (SELECT json_build_object(
       'id', b.id,
       'name', b.name,
       'description', b.description,
       'icon_url', b.icon_url,
       'points_required', b.points_required,
       'points_needed', b.points_required - u.points
     )
     FROM public.badges b
     WHERE b.points_required > u.points
       AND b.id NOT IN (SELECT badge_id FROM public.user_badges WHERE user_id = p_user_id)
     ORDER BY b.points_required ASC
     LIMIT 1
    ) as next_badge,
    (SELECT json_agg(
       json_build_object(
         'id', users.id,
         'name', users.full_name,
         'points', users.points,
         'rank', rank
       )
       ORDER BY rank
     )
     FROM (
       SELECT 
         id,
         full_name,
         points,
         ROW_NUMBER() OVER (ORDER BY points DESC) as rank
       FROM public.users
       WHERE role = u.role
       ORDER BY points DESC
       LIMIT 10
     ) users
    ) as leaderboard
  FROM public.users u
  WHERE u.id = p_user_id;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get volunteer dashboard data (المفقودة من الكود)
CREATE OR REPLACE FUNCTION get_volunteer_dashboard_data(p_user_id uuid)
RETURNS json AS $
BEGIN
  RETURN (SELECT json_build_object(
    'userName', (SELECT full_name FROM users WHERE id = p_user_id),
    'total_tasks', (SELECT COUNT(*) FROM donations WHERE volunteer_id = p_user_id),
    'completed_tasks', (SELECT COUNT(*) FROM donations WHERE volunteer_id = p_user_id AND status = 'completed'),
    'in_progress_tasks', (SELECT COUNT(*) FROM donations WHERE volunteer_id = p_user_id AND status = 'in_progress'),
    'avg_rating', (SELECT COALESCE(AVG(rating), 0.0)::float FROM ratings WHERE volunteer_id = p_user_id),
    'next_task', (SELECT row_to_json(d) FROM (SELECT * FROM donations WHERE volunteer_id = p_user_id AND status = 'assigned' ORDER BY created_at LIMIT 1) d)
  ));
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================================================
-- Part 8: Map and Location Functions
-- ====================================================================

-- Function to get all pending donations for map view
CREATE OR REPLACE FUNCTION get_donations_for_map()
RETURNS TABLE (
  donation_id uuid,
  title text,
  status donation_status,
  location json
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.donation_id,
    d.title,
    d.status,
    ST_AsGeoJSON(d.location)::json
  FROM
    donations d
  WHERE
    d.status = 'pending';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get all donations for manager map view
CREATE OR REPLACE FUNCTION get_all_donations_for_map()
RETURNS TABLE (
  donation_id uuid,
  title text,
  status donation_status,
  location json
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.donation_id,
    d.title,
    d.status,
    ST_AsGeoJSON(d.location)::json
  FROM
    donations d;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get map data for different user roles
CREATE OR REPLACE FUNCTION get_map_data(p_user_role text, p_user_id uuid DEFAULT NULL)
RETURNS TABLE(
  id uuid,
  title text,
  latitude double precision,
  longitude double precision,
  status text,
  food_type text,
  quantity int,
  is_urgent boolean,
  created_at timestamptz,
  marker_type text
) AS $$
BEGIN
  IF p_user_role = 'donor' THEN
    -- Donors see their own donations
    RETURN QUERY
    SELECT 
      d.donation_id as id,
      d.title,
      ST_Y(d.location::geometry) as latitude,
      ST_X(d.location::geometry) as longitude,
      d.status::text,
      d.food_type,
      d.quantity,
      d.is_urgent,
      d.created_at,
      'donation'::text as marker_type
    FROM public.donations d
    WHERE d.donor_id = p_user_id
      AND d.location IS NOT NULL;
      
  ELSIF p_user_role = 'association' THEN
    -- Associations see pending donations and their accepted ones
    RETURN QUERY
    SELECT 
      d.donation_id as id,
      d.title,
      ST_Y(d.location::geometry) as latitude,
      ST_X(d.location::geometry) as longitude,
      d.status::text,
      d.food_type,
      d.quantity,
      d.is_urgent,
      d.created_at,
      'donation'::text as marker_type
    FROM public.donations d
    WHERE (d.status = 'pending' OR d.association_id = p_user_id)
      AND d.location IS NOT NULL;
      
  ELSIF p_user_role = 'volunteer' THEN
    -- Volunteers see their assigned tasks
    RETURN QUERY
    SELECT 
      d.donation_id as id,
      d.title,
      ST_Y(d.location::geometry) as latitude,
      ST_X(d.location::geometry) as longitude,
      d.status::text,
      d.food_type,
      d.quantity,
      d.is_urgent,
      d.created_at,
      'donation'::text as marker_type
    FROM public.donations d
    WHERE d.volunteer_id = p_user_id
      AND d.location IS NOT NULL;
      
  ELSIF p_user_role = 'manager' THEN
    -- Managers see everything
    RETURN QUERY
    SELECT 
      d.donation_id as id,
      d.title,
      ST_Y(d.location::geometry) as latitude,
      ST_X(d.location::geometry) as longitude,
      d.status::text,
      d.food_type,
      d.quantity,
      d.is_urgent,
      d.created_at,
      'donation'::text as marker_type
    FROM public.donations d
    WHERE d.location IS NOT NULL
    
    UNION ALL
    
    SELECT 
      u.id,
      u.full_name as title,
      ST_Y(u.location::geometry) as latitude,
      ST_X(u.location::geometry) as longitude,
      u.role::text as status,
      NULL as food_type,
      NULL as quantity,
      false as is_urgent,
      u.created_at,
      u.role::text as marker_type
    FROM public.users u
    WHERE u.location IS NOT NULL
      AND u.role IN ('association', 'volunteer');
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get manager map data
CREATE OR REPLACE FUNCTION get_manager_map_data()
RETURNS TABLE(
  id uuid,
  name text,
  type text,
  latitude double precision,
  longitude double precision,
  city text,
  status text,
  additional_info json
) AS $$
BEGIN
  RETURN QUERY
  -- Users (associations and volunteers)
  SELECT 
    u.id,
    u.full_name as name,
    u.role::text as type,
    ST_Y(u.location::geometry) as latitude,
    ST_X(u.location::geometry) as longitude,
    u.city,
    CASE WHEN u.is_active THEN 'active' ELSE 'inactive' END as status,
    json_build_object(
      'email', u.email,
      'phone', u.phone,
      'points', u.points,
      'created_at', u.created_at
    ) as additional_info
  FROM public.users u
  WHERE u.location IS NOT NULL
    AND u.role IN ('association', 'volunteer')
  
  UNION ALL
  
  -- Donations
  SELECT 
    d.donation_id as id,
    d.title as name,
    'donation'::text as type,
    ST_Y(d.location::geometry) as latitude,
    ST_X(d.location::geometry) as longitude,
    (SELECT city FROM public.users WHERE id = d.donor_id) as city,
    d.status::text as status,
    json_build_object(
      'food_type', d.food_type,
      'quantity', d.quantity,
      'is_urgent', d.is_urgent,
      'donor_id', d.donor_id,
      'association_id', d.association_id,
      'volunteer_id', d.volunteer_id,
      'created_at', d.created_at
    ) as additional_info
  FROM public.donations d
  WHERE d.location IS NOT NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update user location
CREATE OR REPLACE FUNCTION public.update_user_location(
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.user_locations (user_id, location, last_seen)
  VALUES (auth.uid(), ST_SetSRID(ST_MakePoint(lng, lat), 4326), NOW())
  ON CONFLICT (user_id)
  DO UPDATE SET
    location = ST_SetSRID(ST_MakePoint(lng, lat), 4326),
    last_seen = NOW();
END;
$$;

-- ====================================================================
-- Part 9: Volunteer and Association Management Functions
-- ====================================================================

-- Function to get volunteers for an association
CREATE OR REPLACE FUNCTION get_volunteers_for_association(
  p_association_id uuid
)
RETURNS TABLE (
  id uuid,
  full_name text,
  phone text,
  city text,
  is_active boolean,
  average_rating float,
  completed_tasks_count int
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id,
    u.full_name,
    u.phone,
    u.city,
    u.is_active,
    (SELECT AVG(r.rating)::float8 FROM ratings r WHERE r.volunteer_id = u.id) AS average_rating,
    (SELECT COUNT(*)::int FROM donations d WHERE d.volunteer_id = u.id AND d.status = 'completed') AS completed_tasks_count
  FROM
    users u
  WHERE
    u.role = 'volunteer' AND
    u.associated_with_association_id = p_association_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get volunteers with ratings
CREATE OR REPLACE FUNCTION get_volunteers_with_ratings(association_id_param uuid)
RETURNS TABLE (id uuid, full_name text, email text, phone text, is_active boolean, avg_rating float)
AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id,
    u.full_name,
    u.email,
    u.phone,
    u.is_active,
    COALESCE(avg(r.rating), 0.0)::float as avg_rating
  FROM
    users u
  LEFT JOIN
    ratings r ON u.id = r.volunteer_id
  WHERE
    u.role = 'volunteer' AND u.associated_with_association_id = association_id_param
  GROUP BY
    u.id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get a volunteer's logs
CREATE OR REPLACE FUNCTION get_volunteer_logs(p_volunteer_id uuid)
RETURNS TABLE (donation_title TEXT, start_time TIMESTAMPTZ, end_time TIMESTAMPTZ, notes TEXT) AS $$
BEGIN
  RETURN QUERY
  SELECT d.title, vl.start_time, vl.end_time, vl.notes
  FROM volunteer_logs vl
  JOIN donations d ON vl.donation_id = d.donation_id
  WHERE vl.volunteer_id = p_volunteer_id
  ORDER BY vl.start_time DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get scheduled donations for an association
CREATE OR REPLACE FUNCTION get_scheduled_donations(p_association_id uuid)
RETURNS TABLE (donation_title TEXT, scheduled_time TIMESTAMPTZ, volunteer_name TEXT) AS $$
BEGIN
  RETURN QUERY
  SELECT d.title, d.scheduled_pickup_time, u.full_name
  FROM donations d
  LEFT JOIN users u ON d.volunteer_id = u.id
  WHERE d.association_id = p_association_id
    AND d.scheduled_pickup_time IS NOT NULL
  ORDER BY d.scheduled_pickup_time ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to schedule a donation pickup time
CREATE OR REPLACE FUNCTION schedule_donation_pickup(
  p_donation_id uuid,
  p_scheduled_time TIMESTAMPTZ
)
RETURNS void AS $$
DECLARE
  current_user_id uuid := auth.uid();
  association_id_for_donation uuid;
BEGIN
  -- Get the association_id for the donation
  SELECT association_id INTO association_id_for_donation
  FROM donations
  WHERE donation_id = p_donation_id;

  -- Check if the current user is the association for this donation
  IF association_id_for_donation = current_user_id THEN
    UPDATE donations
    SET scheduled_pickup_time = p_scheduled_time
    WHERE donation_id = p_donation_id;
  ELSE
    RAISE EXCEPTION 'You are not authorized to schedule a pickup for this donation.';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function for a volunteer to log their hours
CREATE OR REPLACE FUNCTION log_volunteer_hours(
  p_donation_id uuid,
  p_start_time TIMESTAMPTZ,
  p_end_time TIMESTAMPTZ,
  p_notes TEXT
)
RETURNS void AS $$
DECLARE
  current_user_id uuid := auth.uid();
  volunteer_id_for_donation uuid;
BEGIN
  -- Get the volunteer_id for the donation
  SELECT volunteer_id INTO volunteer_id_for_donation
  FROM donations
  WHERE donation_id = p_donation_id;

  -- Check if the current user is the volunteer for this donation
  IF volunteer_id_for_donation = current_user_id THEN
    INSERT INTO volunteer_logs (volunteer_id, donation_id, start_time, end_time, notes)
    VALUES (current_user_id, p_donation_id, p_start_time, p_end_time, p_notes);
  ELSE
    RAISE EXCEPTION 'You are not authorized to log hours for this donation.';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get volunteer management data
CREATE OR REPLACE FUNCTION get_volunteer_management_data(p_association_id uuid)
RETURNS TABLE(
  volunteer_id uuid,
  volunteer_name text,
  volunteer_phone text,
  volunteer_city text,
  is_active boolean,
  points int,
  avg_rating numeric,
  total_tasks int,
  completed_tasks int,
  pending_tasks int,
  last_activity timestamptz
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id as volunteer_id,
    u.full_name as volunteer_name,
    u.phone as volunteer_phone,
    u.city as volunteer_city,
    u.is_active,
    u.points,
    COALESCE(AVG(r.rating), 0) as avg_rating,
    COUNT(d.donation_id)::int as total_tasks,
    COUNT(CASE WHEN d.status = 'completed' THEN 1 END)::int as completed_tasks,
    COUNT(CASE WHEN d.status IN ('assigned', 'in_progress') THEN 1 END)::int as pending_tasks,
    MAX(COALESCE(d.picked_up_at, d.created_at)) as last_activity
  FROM public.users u
  LEFT JOIN public.donations d ON u.id = d.volunteer_id
  LEFT JOIN public.ratings r ON u.id = r.volunteer_id
  WHERE u.role = 'volunteer' 
    AND u.associated_with_association_id = p_association_id
  GROUP BY u.id, u.full_name, u.phone, u.city, u.is_active, u.points
  ORDER BY u.is_active DESC, avg_rating DESC, completed_tasks DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================================================
-- Part 10: Reporting Functions
-- ====================================================================

-- Function to get association report data
CREATE OR REPLACE FUNCTION get_association_report_data(p_association_id uuid, p_period TEXT)
RETURNS json AS $$
DECLARE
  report_data json;
  start_date TIMESTAMPTZ;
BEGIN

  start_date := 
    CASE
      WHEN p_period = 'year' THEN date_trunc('year', now())
      WHEN p_period = 'month' THEN date_trunc('month', now())
      ELSE '1970-01-01'::TIMESTAMPTZ
    END;


  WITH association_donations AS (
    SELECT * FROM donations 
    WHERE association_id = p_association_id AND created_at >= start_date
  ),
  association_volunteers AS (
    SELECT DISTINCT volunteer_id FROM association_donations WHERE volunteer_id IS NOT NULL
  ),
  volunteer_ratings AS (
    SELECT r.volunteer_id, r.rating, u.full_name
    FROM ratings r
    JOIN users u ON r.volunteer_id = u.id
    WHERE r.volunteer_id IN (SELECT volunteer_id FROM association_volunteers)
  )
  SELECT json_build_object(
    'total_donations', (SELECT COUNT(*) FROM association_donations),
    'completed_donations', (SELECT COUNT(*) FROM association_donations WHERE status = 'completed'),
    'active_volunteers', (SELECT COUNT(*) FROM association_volunteers),
    'food_type_dist', (
      SELECT json_object_agg(COALESCE(food_type, 'غير محدد'), count)
      FROM (SELECT food_type, COUNT(*) as count FROM association_donations GROUP BY food_type) AS food_counts
    ),
    'monthly_donations', (
      SELECT json_object_agg(month, count)
      FROM (
        SELECT to_char(created_at, 'YYYY-MM') as month, COUNT(*) as count
        FROM association_donations
        GROUP BY month
      ) AS monthly_counts
    ),
    'top_donors', (
      SELECT json_agg(donors)
      FROM (
        SELECT u.full_name, COUNT(d.donation_id) as count
        FROM association_donations d
        JOIN users u ON d.donor_id = u.id
        GROUP BY u.full_name
        ORDER BY count DESC
        LIMIT 5
      ) as donors
    ),
    'top_volunteers', (
      SELECT json_agg(volunteers)
      FROM (
        SELECT full_name, AVG(rating) as avg_rating
        FROM volunteer_ratings
        GROUP BY full_name
        ORDER BY avg_rating DESC
        LIMIT 5
      ) as volunteers
    )
  ) INTO report_data;

  RETURN report_data;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get manager leaderboard data
CREATE OR REPLACE FUNCTION get_manager_leaderboard_data()
RETURNS TABLE(
  donors json,
  associations json,
  volunteers json,
  overall_stats json
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    (SELECT json_agg(
       json_build_object(
         'id', u.id,
         'name', u.full_name,
         'city', u.city,
         'points', u.points,
         'total_donations', donation_count,
         'completed_donations', completed_count
       )
       ORDER BY u.points DESC
     )
     FROM (
       SELECT 
         u.*,
         COUNT(d.donation_id) as donation_count,
         COUNT(CASE WHEN d.status = 'completed' THEN 1 END) as completed_count
       FROM public.users u
       LEFT JOIN public.donations d ON u.id = d.donor_id
       WHERE u.role = 'donor'
       GROUP BY u.id
       ORDER BY u.points DESC
       LIMIT 20
     ) u
    ) as donors,
    
    (SELECT json_agg(
       json_build_object(
         'id', u.id,
         'name', u.full_name,
         'city', u.city,
         'points', u.points,
         'total_received', received_count,
         'total_volunteers', volunteer_count
       )
       ORDER BY u.points DESC
     )
     FROM (
       SELECT 
         u.*,
         COUNT(d.donation_id) as received_count,
         COUNT(v.id) as volunteer_count
       FROM public.users u
       LEFT JOIN public.donations d ON u.id = d.association_id
       LEFT JOIN public.users v ON u.id = v.associated_with_association_id
       WHERE u.role = 'association'
       GROUP BY u.id
       ORDER BY u.points DESC
       LIMIT 20
     ) u
    ) as associations,
    
    (SELECT json_agg(
       json_build_object(
         'id', u.id,
         'name', u.full_name,
         'city', u.city,
         'points', u.points,
         'completed_tasks', task_count,
         'avg_rating', avg_rating
       )
       ORDER BY u.points DESC
     )
     FROM (
       SELECT 
         u.*,
         COUNT(d.donation_id) as task_count,
         COALESCE(AVG(r.rating), 0) as avg_rating
       FROM public.users u
       LEFT JOIN public.donations d ON u.id = d.volunteer_id AND d.status = 'completed'
       LEFT JOIN public.ratings r ON u.id = r.volunteer_id
       WHERE u.role = 'volunteer'
       GROUP BY u.id
       ORDER BY u.points DESC
       LIMIT 20
     ) u
    ) as volunteers,
    
    (SELECT json_build_object(
       'total_users', (SELECT COUNT(*) FROM public.users),
       'total_donations', (SELECT COUNT(*) FROM public.donations),
       'completed_donations', (SELECT COUNT(*) FROM public.donations WHERE status = 'completed'),
       'active_volunteers', (SELECT COUNT(*) FROM public.users WHERE role = 'volunteer' AND is_active = true),
       'active_associations', (SELECT COUNT(*) FROM public.users WHERE role = 'association' AND is_active = true),
       'total_food_rescued', (SELECT COALESCE(SUM(quantity), 0) FROM public.donations WHERE status = 'completed')
     )
    ) as overall_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================================================
-- Part 11: Social Media Integration
-- ====================================================================

-- Function to generate a shareable text for a completed donation
CREATE OR REPLACE FUNCTION generate_share_text(p_donation_id uuid)
RETURNS TEXT AS $$
DECLARE
  donation_title TEXT;
  association_name TEXT;
BEGIN
  SELECT d.title, u.full_name
  INTO donation_title, association_name
  FROM donations d
  JOIN users u ON d.association_id = u.id
  WHERE d.donation_id = p_donation_id;

  RETURN 'لقد أكملت للتو تبرع "' || donation_title || '" مع جمعية ' || association_name || '. #wisaal #donation #volunteer';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================================================
-- Part 12: Triggers and Automated Functions
-- ====================================================================

-- دالة مشغل لإرسال الإشعارات عند تغيير حالة التبرع
CREATE OR REPLACE FUNCTION notify_on_donation_status_change()
RETURNS TRIGGER AS $$
DECLARE
  donor_id uuid;
  association_id uuid;
  volunteer_id uuid;
  title text;
  body text;
BEGIN
  -- الحصول على معرفات المستخدمين المعنيين
  donor_id := NEW.donor_id;
  association_id := NEW.association_id;
  volunteer_id := NEW.volunteer_id;
  title := 'تحديث حالة التبرع';

  -- إرسال إشعار للمتبرع
  IF NEW.status = 'accepted' THEN
    body := 'تم قبول تبرعك "' || NEW.title || '"';
    PERFORM create_notification(donor_id, title, body);
  ELSIF NEW.status = 'cancelled' THEN
    body := 'تم إلغاء تبرعك "' || NEW.title || '"';
    PERFORM create_notification(donor_id, title, body);
  END IF;

  -- إرسال إشعار للجمعية
  IF NEW.status = 'completed' THEN
    body := 'اكتمل توصيل التبرع "' || NEW.title || '"';
    PERFORM create_notification(association_id, title, body);
  END IF;

  -- إرسال إشعار للمتطوع
  IF NEW.volunteer_id IS NOT NULL AND (NEW.status = 'assigned' OR NEW.status = 'in_progress') THEN
    body := 'تم تعيينك لمهمة توصيل التبرع "' || NEW.title || '"';
    PERFORM create_notification(volunteer_id, title, body);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- دالة لتحديث جدول الإحصائيات
CREATE OR REPLACE FUNCTION update_stats()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE stats
  SET
    total_donations_completed = (SELECT COUNT(*) FROM donations WHERE status = 'completed'),
    active_volunteers_count = (SELECT COUNT(*) FROM users WHERE role = 'volunteer' AND is_active = true),
    active_associations_count = (SELECT COUNT(*) FROM users WHERE role = 'association' AND is_active = true),
    last_updated = now()
  WHERE id = 1;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to award points when a donation is completed
CREATE OR REPLACE FUNCTION on_donation_completed_award_points()
RETURNS TRIGGER AS $$
BEGIN
  -- Award 10 points for each completed donation
  PERFORM award_points_for_donation(NEW.volunteer_id, 10);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to check for new badges after points are updated
CREATE OR REPLACE FUNCTION on_points_updated_check_badges()
RETURNS TRIGGER AS $$
BEGIN
  -- Check for new badges for the user whose points were updated
  PERFORM check_and_award_badges(NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to make the manager activation code reusable
CREATE OR REPLACE FUNCTION prevent_manager_code_deactivation()
RETURNS TRIGGER AS $$
BEGIN
  -- If the code being updated is the specific manager code '01200602TB',
  -- we prevent the is_used flag from being set to true.
  -- This ensures the manager activation code is always reusable.
  IF OLD.code = '01200602TB' THEN
    NEW.is_used = false;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- دالة مشغل لإنشاء رموز QR تلقا��يًا عند إنشاء تبرع جديد
CREATE OR REPLACE FUNCTION generate_donation_qr_codes()
RETURNS TRIGGER AS $$
BEGIN
  -- استخدام معرف التبرع كمحتوى لرمز الاستجابة السريعة
  NEW.donor_qr_code := NEW.donation_id::text;
  NEW.association_qr_code := NEW.donation_id::text;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ====================================================================
-- Part 13: Create All Triggers
-- ====================================================================

-- إنشاء المشغل على جدول التبرعات
DROP TRIGGER IF EXISTS on_donation_status_change ON donations;
CREATE TRIGGER on_donation_status_change
  AFTER UPDATE OF status ON donations
  FOR EACH ROW
  EXECUTE FUNCTION notify_on_donation_status_change();

-- مشغل لتحديث الإحصائيات عند اكتمال التبرع أو تغيير حالة المستخدم
DROP TRIGGER IF EXISTS on_donation_completed ON donations;
CREATE TRIGGER on_donation_completed
  AFTER UPDATE OF status ON donations
  FOR EACH ROW
  WHEN (NEW.status = 'completed')
  EXECUTE FUNCTION update_stats();

DROP TRIGGER IF EXISTS on_user_status_change ON users;
CREATE TRIGGER on_user_status_change
  AFTER INSERT OR UPDATE OF is_active, role ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_stats();

DROP TRIGGER IF EXISTS on_donation_completed_award_points_trigger ON donations;
CREATE TRIGGER on_donation_completed_award_points_trigger
  AFTER UPDATE OF status ON donations
  FOR EACH ROW
  WHEN (NEW.status = 'completed' AND OLD.status <> 'completed' AND NEW.volunteer_id IS NOT NULL)
  EXECUTE FUNCTION on_donation_completed_award_points();

DROP TRIGGER IF EXISTS on_points_updated_check_badges_trigger ON users;
CREATE TRIGGER on_points_updated_check_badges_trigger
  AFTER UPDATE OF points ON users
  FOR EACH ROW
  WHEN (NEW.points > OLD.points)
  EXECUTE FUNCTION on_points_updated_check_badges();

DROP TRIGGER IF EXISTS on_activation_code_update ON activation_codes;
CREATE TRIGGER on_activation_code_update
  BEFORE UPDATE ON activation_codes
  FOR EACH ROW
  EXECUTE FUNCTION prevent_manager_code_deactivation();

-- إنشاء المشغل على جدول التبرعات
DROP TRIGGER IF EXISTS on_donation_creation_generate_qr ON donations;
CREATE TRIGGER on_donation_creation_generate_qr
  BEFORE INSERT ON donations
  FOR EACH ROW
  EXECUTE FUNCTION generate_donation_qr_codes();

-- ====================================================================
-- Part 14: Row Level Security (RLS) Setup
-- ====================================================================

-- تفعيل RLS لكل جدول
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

-- سياسات users
DROP POLICY IF EXISTS "Users can view their own profile, and managers can view all" ON users;
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
  WITH CHECK (auth.uid() = id);

-- سياسات donations
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

-- سياسات notifications
DROP POLICY IF EXISTS "Users can manage their own notifications" ON notifications;
CREATE POLICY "Users can manage their own notifications"
  ON notifications FOR ALL
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Managers can do anything" ON notifications;
CREATE POLICY "Managers can do anything"
  ON notifications FOR ALL
  USING (get_user_role(auth.uid()) = 'manager');

-- سياسات ratings
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

-- سياسات stats
DROP POLICY IF EXISTS "Managers can do anything" ON stats;
CREATE POLICY "Managers can do anything"
  ON stats FOR ALL
  USING (get_user_role(auth.uid()) = 'manager');

-- سياسات activation_codes
DROP POLICY IF EXISTS "Public can read activation codes" ON activation_codes;
CREATE POLICY "Public can read activation codes" ON activation_codes
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Managers can do anything" ON activation_codes;
CREATE POLICY "Managers can do anything"
  ON activation_codes FOR ALL
  USING (get_user_role(auth.uid()) = 'manager');

DROP POLICY IF EXISTS "Associations and managers can select activation codes" ON activation_codes;
CREATE POLICY "Associations and managers can select activation codes"
  ON activation_codes FOR SELECT
  USING (get_user_role(auth.uid()) IN ('association', 'manager'));

DROP POLICY IF EXISTS "Associations and managers can insert activation codes" ON activation_codes;
CREATE POLICY "Associations and managers can insert activation codes"
  ON activation_codes FOR INSERT
  WITH CHECK (get_user_role(auth.uid()) IN ('association', 'manager'));

DROP POLICY IF EXISTS "Associations and managers can update activation codes" ON activation_codes;
CREATE POLICY "Associations and managers can update activation codes"
  ON activation_codes FOR UPDATE
  USING (get_user_role(auth.uid()) IN ('association', 'manager'));

-- سيا��ات user_locations
DROP POLICY IF EXISTS "Users can insert their own location" ON public.user_locations;
CREATE POLICY "Users can insert their own location" ON public.user_locations
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own location" ON public.user_locations;
CREATE POLICY "Users can update their own location" ON public.user_locations
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Authenticated users can view all locations" ON public.user_locations;
CREATE POLICY "Authenticated users can view all locations" ON public.user_locations
  FOR SELECT USING (auth.role() = 'authenticated');

-- ====================================================================
-- Part 15: Permissions and Grants
-- ====================================================================

-- Grant permissions for location tracking
GRANT ALL ON TABLE public.user_locations TO supabase_admin;
GRANT ALL ON TABLE public.user_locations TO postgres;
GRANT SELECT ON TABLE public.user_locations TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_user_location(double precision, double precision) TO authenticated;

-- ====================================================================
-- Part 16: Sample Data and Initial Setup
-- ====================================================================

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
-- Part 17: Final Verification and Completion
-- ====================================================================

-- Final verification
DO $$
BEGIN
  RAISE NOTICE 'Wisaal Database Setup Completed Successfully!';
  RAISE NOTICE 'Tables created: %', (SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public');
  RAISE NOTICE 'Functions created: %', (SELECT count(*) FROM information_schema.routines WHERE routine_schema = 'public');
  RAISE NOTICE 'Policies created: %', (SELECT count(*) FROM pg_policies WHERE schemaname = 'public');
  RAISE NOTICE 'Triggers created: %', (SELECT count(*) FROM information_schema.triggers WHERE trigger_schema = 'public');
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'Database is ready for use!';
  RAISE NOTICE '====================================================================';
END $$;

-- ====================================================================
-- END OF WISAAL COMPLETE MERGED DATABASE SCRIPT
-- ====================================================================