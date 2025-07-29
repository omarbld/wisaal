-- Create Missing Critical Functions for Wisaal Application
-- This script creates essential functions that are called from the Flutter app but missing from database

-- ====================================================================
-- Part 1: Register Volunteer Function (Critical for Registration)
-- ====================================================================

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
$$;

-- ====================================================================
-- Part 2: Get Top Volunteers Function
-- ====================================================================

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

-- ====================================================================
-- Part 3: Get Volunteer Dashboard Data Function
-- ====================================================================

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

-- ====================================================================
-- Part 4: Get Leaderboard Function
-- ====================================================================

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

-- ====================================================================
-- Part 5: Get Full Leaderboard Function
-- ====================================================================

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
-- Part 6: Create Inventory Table (if missing)
-- ====================================================================

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

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_inventory_association_id ON inventory(association_id);
CREATE INDEX IF NOT EXISTS idx_inventory_item_name ON inventory(item_name);

-- ====================================================================
-- Part 7: Create/Fix donations_with_coordinates View
-- ====================================================================

-- Drop existing view if it exists
DROP VIEW IF EXISTS donations_with_coordinates;

-- Create the view with proper coordinate extraction
CREATE VIEW donations_with_coordinates AS
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

-- ====================================================================
-- Part 8: Additional Helper Functions
-- ====================================================================

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

-- Function to send bulk notifications
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

-- Function to generate activation code enhanced
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
    
    -- التأكد من عدم التكرار
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
    
    -- إرجاع القيم
    generated_code := new_code;
    created_at := created_time;
    RETURN NEXT;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================================================
-- Part 9: Enable RLS on new tables
-- ====================================================================

-- Enable RLS on inventory table
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for inventory
CREATE POLICY "Associations can manage their own inventory" ON inventory
  FOR ALL USING (association_id = auth.uid());

CREATE POLICY "Managers can view all inventory" ON inventory
  FOR SELECT USING (get_user_role(auth.uid()) = 'manager');

-- Grant permissions on view
GRANT SELECT ON donations_with_coordinates TO authenticated;

-- ====================================================================
-- Part 10: Grant Permissions
-- ====================================================================

-- Grant permissions on all functions
GRANT EXECUTE ON FUNCTION register_volunteer(uuid, text, text, text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION register_volunteer(uuid, text, text, text, text, text) TO anon;
GRANT EXECUTE ON FUNCTION get_top_volunteers(integer) TO authenticated;
GRANT EXECUTE ON FUNCTION get_volunteer_dashboard_data(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_leaderboard() TO authenticated;
GRANT EXECUTE ON FUNCTION get_full_leaderboard() TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_badges(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION send_bulk_notification(text, text, user_role) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_activation_code_enhanced(uuid, integer) TO authenticated;

-- Grant permissions on inventory table
GRANT ALL ON inventory TO authenticated;

-- ====================================================================
-- Part 11: Insert Sample Data
-- ====================================================================

-- Insert sample inventory data for testing
INSERT INTO inventory (association_id, item_name, quantity, unit, notes) 
SELECT 
  u.id,
  'وجبة',
  FLOOR(RANDOM() * 100 + 10)::integer,
  'وجبة',
  'وجبات جاهزة للتوزيع'
FROM users u 
WHERE u.role = 'association' 
ON CONFLICT DO NOTHING;

-- ====================================================================
-- Part 12: Final Verification
-- ====================================================================

DO $$
BEGIN
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'Missing Critical Functions Created Successfully!';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'Created Functions:';
  RAISE NOTICE '1. ✅ register_volunteer - For volunteer registration';
  RAISE NOTICE '2. ✅ get_top_volunteers - For leaderboard display';
  RAISE NOTICE '3. ✅ get_volunteer_dashboard_data - For volunteer dashboard';
  RAISE NOTICE '4. ✅ get_leaderboard - For main leaderboard';
  RAISE NOTICE '5. ✅ get_full_leaderboard - For full leaderboard';
  RAISE NOTICE '6. ✅ get_user_badges - For user badges';
  RAISE NOTICE '7. ✅ send_bulk_notification - For bulk notifications';
  RAISE NOTICE '8. ✅ generate_activation_code_enhanced - For activation codes';
  RAISE NOTICE '';
  RAISE NOTICE 'Created Tables/Views:';
  RAISE NOTICE '1. ✅ inventory table - For association inventory management';
  RAISE NOTICE '2. ✅ donations_with_coordinates view - For map display';
  RAISE NOTICE '';
  RAISE NOTICE 'All critical functions are now available!';
  RAISE NOTICE 'The application buttons should work properly now.';
  RAISE NOTICE '====================================================================';
END $$;