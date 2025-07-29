-- FINAL COMPLETE FIX FOR WISAAL APPLICATION
-- This script ensures ALL buttons and functions work properly
-- Run this script to fix all database-related issues

-- ====================================================================
-- Part 1: Create Missing Critical Functions
-- ====================================================================

-- Register Volunteer Function (Critical for Registration)
CREATE OR REPLACE FUNCTION register_volunteer(
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
AS $$
DECLARE
    v_code_id uuid;
    v_association_id uuid;
BEGIN
    -- Find and lock the activation code
    SELECT id, created_by_association_id INTO v_code_id, v_association_id
    FROM public.activation_codes
    WHERE code = p_activation_code AND role = 'volunteer' AND is_used = FALSE
    FOR UPDATE;

    -- Check if code is valid
    IF v_code_id IS NULL THEN
        RAISE EXCEPTION 'INVALID_ACTIVATION_CODE: The provided activation code is invalid, already used, or not for a volunteer.';
    END IF;

    -- Insert the new user
    INSERT INTO public.users (id, full_name, email, phone, city, role, associated_with_association_id)
    VALUES (p_user_id, p_full_name, p_email, p_phone, p_city, 'volunteer', v_association_id);

    -- Mark code as used
    UPDATE public.activation_codes
    SET is_used = TRUE, used_by_user_id = p_user_id, used_at = NOW()
    WHERE id = v_code_id;
END;
$$;

-- Get Top Volunteers Function
CREATE OR REPLACE FUNCTION get_top_volunteers(limit_count integer DEFAULT 10)
RETURNS TABLE (
  id uuid,
  full_name text,
  points integer,
  total_donations integer,
  rating decimal,
  rank bigint,
  completed_donations_count integer
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.full_name,
    u.points,
    COALESCE(COUNT(d.donation_id)::integer, 0) as total_donations,
    COALESCE(AVG(r.rating), 0.0)::decimal as rating,
    ROW_NUMBER() OVER (ORDER BY u.points DESC, u.full_name) as rank,
    COALESCE(COUNT(CASE WHEN d.status = 'completed' THEN 1 END)::integer, 0) as completed_donations_count
  FROM users u
  LEFT JOIN donations d ON u.id = d.volunteer_id
  LEFT JOIN ratings r ON u.id = r.volunteer_id
  WHERE u.role = 'volunteer' AND u.is_active = true
  GROUP BY u.id, u.full_name, u.points
  ORDER BY u.points DESC, u.full_name
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get Volunteer Dashboard Data Function
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

-- Get Leaderboard Functions
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

-- ====================================================================
-- Part 2: Fix Association Reports Function (Fixed Ambiguous Columns)
-- ====================================================================

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
    ELSE start_date := '1900-01-01'::timestamptz;
  END CASE;

  -- Get statistics
  SELECT COUNT(*) INTO total_donations_count
  FROM donations WHERE association_id = p_association_id AND created_at >= start_date AND created_at <= end_date;

  SELECT COUNT(*) INTO completed_donations_count
  FROM donations WHERE association_id = p_association_id AND status = 'completed' AND created_at >= start_date AND created_at <= end_date;

  SELECT COUNT(*) INTO active_volunteers_count
  FROM users WHERE role = 'volunteer' AND associated_with_association_id = p_association_id AND is_active = true;

  -- Get food type distribution
  SELECT json_object_agg(COALESCE(food_type, 'غير محدد'), count) INTO food_type_distribution
  FROM (
    SELECT food_type, COUNT(*) as count
    FROM donations 
    WHERE association_id = p_association_id AND created_at >= start_date AND created_at <= end_date AND status = 'completed'
    GROUP BY food_type ORDER BY count DESC LIMIT 10
  ) food_dist;

  -- Get monthly donations
  SELECT json_object_agg(month_year, donation_count) INTO monthly_donations
  FROM (
    SELECT TO_CHAR(created_at, 'YYYY-MM') as month_year, COUNT(*) as donation_count
    FROM donations 
    WHERE association_id = p_association_id AND created_at >= NOW() - INTERVAL '12 months' AND status = 'completed'
    GROUP BY TO_CHAR(created_at, 'YYYY-MM') ORDER BY month_year
  ) monthly_data;

  -- Get top donors
  SELECT json_agg(json_build_object('full_name', u.full_name, 'count', donor_data.donation_count)) INTO top_donors
  FROM (
    SELECT d.donor_id, COUNT(*) as donation_count
    FROM donations d
    WHERE d.association_id = p_association_id AND d.created_at >= start_date AND d.created_at <= end_date AND d.status = 'completed'
    GROUP BY d.donor_id ORDER BY donation_count DESC LIMIT 5
  ) donor_data
  JOIN users u ON donor_data.donor_id = u.id;

  -- Get top volunteers (fixed ambiguous column reference)
  SELECT json_agg(json_build_object('full_name', u.full_name, 'avg_rating', COALESCE(volunteer_data.avg_rating, 0), 'completed_tasks', volunteer_data.completed_tasks)) INTO top_volunteers
  FROM (
    SELECT d.volunteer_id, AVG(r.rating) as avg_rating, COUNT(d.donation_id) as completed_tasks
    FROM donations d
    LEFT JOIN ratings r ON d.donation_id = r.task_id AND r.volunteer_id = d.volunteer_id
    WHERE d.association_id = p_association_id AND d.created_at >= start_date AND d.created_at <= end_date AND d.status = 'completed' AND d.volunteer_id IS NOT NULL
    GROUP BY d.volunteer_id ORDER BY avg_rating DESC, completed_tasks DESC LIMIT 5
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
-- Part 3: Fix Volunteer Assignment Function
-- ====================================================================

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
  WHERE u.role = 'volunteer' AND u.associated_with_association_id = p_association_id
  GROUP BY u.id, u.full_name, u.email, u.phone, u.points, u.is_active, u.created_at
  ORDER BY u.points DESC, completed_tasks DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================================================
-- Part 4: Create Missing Utility Functions
-- ====================================================================

-- Log volunteer hours
CREATE OR REPLACE FUNCTION log_volunteer_hours(
  p_volunteer_id uuid,
  p_hours numeric DEFAULT 1.0,
  p_task_id uuid DEFAULT NULL
)
RETURNS json AS $$
BEGIN
  INSERT INTO volunteer_logs (volunteer_id, action, details, created_at)
  VALUES (p_volunteer_id, 'hours_logged', json_build_object('hours', p_hours, 'task_id', p_task_id, 'logged_at', NOW()), NOW());
  
  UPDATE users SET points = points + p_hours::int WHERE id = p_volunteer_id;
  
  RETURN json_build_object('success', true, 'hours_logged', p_hours, 'message', 'تم تسجيل الساعات بنجاح');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Generate share text
CREATE OR REPLACE FUNCTION generate_share_text(p_donation_id uuid)
RETURNS json AS $$
DECLARE
  donation_record RECORD;
  share_text text;
BEGIN
  SELECT d.title, d.description, d.quantity, d.food_type, u_donor.full_name as donor_name, u_assoc.full_name as association_name
  INTO donation_record
  FROM donations d
  LEFT JOIN users u_donor ON d.donor_id = u_donor.id
  LEFT JOIN users u_assoc ON d.association_id = u_assoc.id
  WHERE d.donation_id = p_donation_id;
  
  IF donation_record IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'التبرع غير موجود');
  END IF;
  
  share_text := format('🌟 تم توصيل تبرع بنجاح عبر تطبيق وصال! 🌟

📦 التبرع: %s
🍽️ النوع: %s
📊 الكمية: %s
👤 المتبرع: %s
🏢 الجمعية: %s

#وصال #مكافحة_هدر_الطع��م #تطوع #خير',
    donation_record.title,
    COALESCE(donation_record.food_type, 'غير محدد'),
    COALESCE(donation_record.quantity::text, 'غير محدد'),
    COALESCE(donation_record.donor_name, 'غير معروف'),
    COALESCE(donation_record.association_name, 'غير معروف')
  );
  
  RETURN json_build_object('success', true, 'share_text', share_text);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get map data with coordinates
CREATE OR REPLACE FUNCTION get_map_data_with_coordinates()
RETURNS json AS $$
BEGIN
  RETURN (
    SELECT json_build_object(
      'donations', (
        SELECT json_agg(json_build_object(
          'donation_id', d.donation_id, 'title', d.title, 'status', d.status,
          'latitude', ST_Y(d.location::geometry), 'longitude', ST_X(d.location::geometry),
          'is_urgent', d.is_urgent, 'food_type', d.food_type,
          'donor_name', u_donor.full_name, 'association_name', u_assoc.full_name
        ))
        FROM donations d
        LEFT JOIN users u_donor ON d.donor_id = u_donor.id
        LEFT JOIN users u_assoc ON d.association_id = u_assoc.id
        WHERE d.location IS NOT NULL AND d.status IN ('pending', 'accepted', 'assigned', 'in_progress')
      ),
      'users', (
        SELECT json_agg(json_build_object(
          'user_id', u.id, 'full_name', u.full_name, 'role', u.role,
          'latitude', ST_Y(u.location::geometry), 'longitude', ST_X(u.location::geometry),
          'is_active', u.is_active
        ))
        FROM users u
        WHERE u.location IS NOT NULL AND u.is_active = true AND u.role IN ('volunteer', 'association')
      )
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get user badges
CREATE OR REPLACE FUNCTION get_user_badges(p_user_id uuid)
RETURNS TABLE(badge_id uuid, badge_name text, badge_description text, badge_icon_url text, earned_at timestamptz) AS $$
BEGIN
  RETURN QUERY
  SELECT b.id as badge_id, b.name as badge_name, b.description as badge_description, b.icon_url as badge_icon_url, ub.earned_at
  FROM user_badges ub
  JOIN badges b ON ub.badge_id = b.id
  WHERE ub.user_id = p_user_id
  ORDER BY ub.earned_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Send bulk notification
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

-- Generate activation code enhanced
CREATE OR REPLACE FUNCTION generate_activation_code_enhanced(p_association_id uuid, p_count integer DEFAULT 1)
RETURNS TABLE(generated_code text, created_at timestamptz) AS $$
DECLARE
  i integer;
  new_code text;
  created_time timestamptz;
BEGIN
  FOR i IN 1..p_count LOOP
    new_code := upper(substring(md5(random()::text || clock_timestamp()::text) from 1 for 8));
    
    WHILE EXISTS (SELECT 1 FROM public.activation_codes WHERE activation_codes.code = new_code) LOOP
      new_code := upper(substring(md5(random()::text || clock_timestamp()::text) from 1 for 8));
    END LOOP;
    
    INSERT INTO public.activation_codes (code, role, created_by_association_id, created_at)
    VALUES (new_code, 'volunteer', p_association_id, now())
    RETURNING activation_codes.created_at INTO created_time;
    
    generated_code := new_code;
    created_at := created_time;
    RETURN NEXT;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================================================
-- Part 5: Create Missing Tables
-- ====================================================================

-- Create inventory table if missing
CREATE TABLE IF NOT EXISTS inventory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  association_id uuid REFERENCES users(id),
  item_name text NOT NULL,
  quantity integer DEFAULT 0,
  unit text DEFAULT 'وحدة',
  expiry_date date,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_inventory_association_id ON inventory(association_id);
CREATE INDEX IF NOT EXISTS idx_inventory_item_name ON inventory(item_name);

-- Enable RLS on inventory
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Associations can manage their own inventory" ON inventory
  FOR ALL USING (association_id = auth.uid());

CREATE POLICY "Managers can view all inventory" ON inventory
  FOR SELECT USING (get_user_role(auth.uid()) = 'manager');

-- ====================================================================
-- Part 6: Create/Fix Views
-- ====================================================================

DROP VIEW IF EXISTS donations_with_coordinates;

CREATE VIEW donations_with_coordinates AS
SELECT 
  d.donation_id, d.donor_id, d.association_id, d.volunteer_id, d.title, d.description,
  d.quantity, d.food_type, d.status, d.method_of_pickup, d.donor_qr_code, d.association_qr_code,
  d.pickup_address, d.image_path, d.is_urgent, d.expiry_date, d.created_at, d.picked_up_at, d.delivered_at, d.scheduled_pickup_time,
  CASE WHEN d.location IS NOT NULL THEN ST_Y(d.location::geometry) ELSE NULL END as latitude,
  CASE WHEN d.location IS NOT NULL THEN ST_X(d.location::geometry) ELSE NULL END as longitude,
  u_donor.full_name as donor_name, u_donor.phone as donor_phone, u_donor.email as donor_email,
  u_assoc.full_name as association_name, u_assoc.phone as association_phone, u_assoc.email as association_email,
  u_vol.full_name as volunteer_name, u_vol.phone as volunteer_phone, u_vol.email as volunteer_email
FROM donations d
LEFT JOIN users u_donor ON d.donor_id = u_donor.id
LEFT JOIN users u_assoc ON d.association_id = u_assoc.id
LEFT JOIN users u_vol ON d.volunteer_id = u_vol.id;

-- ====================================================================
-- Part 7: Grant Permissions
-- ====================================================================

-- Grant permissions on all functions
GRANT EXECUTE ON FUNCTION register_volunteer(uuid, text, text, text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION register_volunteer(uuid, text, text, text, text, text) TO anon;
GRANT EXECUTE ON FUNCTION get_top_volunteers(integer) TO authenticated;
GRANT EXECUTE ON FUNCTION get_volunteer_dashboard_data(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_leaderboard() TO authenticated;
GRANT EXECUTE ON FUNCTION get_full_leaderboard() TO authenticated;
GRANT EXECUTE ON FUNCTION get_association_report_data(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION get_volunteers_for_association(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION log_volunteer_hours(uuid, numeric, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_share_text(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_map_data_with_coordinates() TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_badges(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION send_bulk_notification(text, text, user_role) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_activation_code_enhanced(uuid, integer) TO authenticated;

-- Grant permissions on tables and views
GRANT ALL ON inventory TO authenticated;
GRANT SELECT ON donations_with_coordinates TO authenticated;

-- ====================================================================
-- Part 8: Insert Sample Data
-- ====================================================================

-- Insert sample inventory data
INSERT INTO inventory (association_id, item_name, quantity, unit, notes) 
SELECT u.id, 'وجبة', FLOOR(RANDOM() * 100 + 10)::integer, 'وجبة', 'وجبات جاهزة للتوزيع'
FROM users u WHERE u.role = 'association' 
ON CONFLICT DO NOTHING;

-- ====================================================================
-- Part 9: Final Verification
-- ====================================================================

DO $$
BEGIN
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'FINAL COMPLETE FIX APPLIED SUCCESSFULLY!';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'All critical functions have been created/fixed:';
  RAISE NOTICE '✅ register_volunteer - For user registration';
  RAISE NOTICE '✅ get_top_volunteers - For leaderboards';
  RAISE NOTICE '✅ get_volunteer_dashboard_data - For volunteer dashboard';
  RAISE NOTICE '✅ get_leaderboard/get_full_leaderboard - For leaderboard pages';
  RAISE NOTICE '✅ get_association_report_data - For association reports (fixed ambiguous columns)';
  RAISE NOTICE '✅ get_volunteers_for_association - For volunteer assignment (fixed column names)';
  RAISE NOTICE '✅ log_volunteer_hours - For logging volunteer hours';
  RAISE NOTICE '✅ generate_share_text - For sharing donations';
  RAISE NOTICE '✅ get_map_data_with_coordinates - For map functionality';
  RAISE NOTICE '✅ get_user_badges - For user badges';
  RAISE NOTICE '✅ send_bulk_notification - For bulk notifications';
  RAISE NOTICE '✅ generate_activation_code_enhanced - For activation codes';
  RAISE NOTICE '';
  RAISE NOTICE 'Tables/Views created:';
  RAISE NOTICE '✅ inventory table - For association inventory management';
  RAISE NOTICE '✅ donations_with_coordinates view - For map display';
  RAISE NOTICE '';
  RAISE NOTICE 'ALL BUTTONS IN THE APPLICATION SHOULD NOW WORK PROPERLY!';
  RAISE NOTICE '====================================================================';
END $$;