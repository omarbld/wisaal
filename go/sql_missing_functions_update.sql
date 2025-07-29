-- ====================================================================
-- SQL Missing Functions Update for Wisaal Project
-- ====================================================================
-- This script contains the missing functions that are used in the code
-- but not present in the main SQL file
-- ====================================================================

-- Function to get volunteer dashboard data (مستخدمة في volunteer_home.dart)
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

-- دالة محسنة لإنشاء أكواد التفعيل (لتحسين association_activation_codes.dart)
CREATE OR REPLACE FUNCTION generate_activation_code_enhanced(
  p_association_id uuid,
  p_count int DEFAULT 1
)
RETURNS TABLE(generated_code text, created_at timestamptz) AS $
DECLARE
  i int;
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
$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get enhanced volunteers with detailed ratings
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
    (SELECT MAX(COALESCE(delivered_at, picked_up_at, created_at)) FROM public.donations WHERE volunteer_id = u.id) as last_activity,
    (SELECT json_build_object(
      'rating_5', COUNT(CASE WHEN rating = 5 THEN 1 END),
      'rating_4', COUNT(CASE WHEN rating = 4 THEN 1 END),
      'rating_3', COUNT(CASE WHEN rating = 3 THEN 1 END),
      'rating_2', COUNT(CASE WHEN rating = 2 THEN 1 END),
      'rating_1', COUNT(CASE WHEN rating = 1 THEN 1 END)
    ) FROM public.ratings WHERE volunteer_id = u.id) as rating_breakdown
  FROM public.users u
  LEFT JOIN public.ratings r ON u.id = r.volunteer_id
  WHERE u.role = 'volunteer' 
    AND u.associated_with_association_id = p_association_id
  GROUP BY u.id, u.full_name, u.email, u.phone, u.city, u.points, u.is_active, u.created_at
  ORDER BY avg_rating DESC, completed_tasks DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get comprehensive manager dashboard data
CREATE OR REPLACE FUNCTION get_manager_dashboard_comprehensive()
RETURNS json AS $$
BEGIN
  RETURN (SELECT json_build_object(
    'overview', json_build_object(
      'total_users', (SELECT COUNT(*) FROM public.users),
      'total_donations', (SELECT COUNT(*) FROM public.donations),
      'completed_donations', (SELECT COUNT(*) FROM public.donations WHERE status = 'completed'),
      'active_volunteers', (SELECT COUNT(*) FROM public.users WHERE role = 'volunteer' AND is_active = true),
      'active_associations', (SELECT COUNT(*) FROM public.users WHERE role = 'association' AND is_active = true),
      'total_donors', (SELECT COUNT(*) FROM public.users WHERE role = 'donor'),
      'total_food_rescued', (SELECT COALESCE(SUM(quantity), 0) FROM public.donations WHERE status = 'completed')
    ),
    'recent_activity', json_build_object(
      'new_users_today', (SELECT COUNT(*) FROM public.users WHERE created_at >= CURRENT_DATE),
      'donations_today', (SELECT COUNT(*) FROM public.donations WHERE created_at >= CURRENT_DATE),
      'completed_today', (SELECT COUNT(*) FROM public.donations WHERE status = 'completed' AND delivered_at >= CURRENT_DATE)
    ),
    'trends', json_build_object(
      'donations_this_week', (SELECT COUNT(*) FROM public.donations WHERE created_at >= date_trunc('week', CURRENT_DATE)),
      'donations_last_week', (SELECT COUNT(*) FROM public.donations WHERE created_at >= date_trunc('week', CURRENT_DATE - interval '1 week') AND created_at < date_trunc('week', CURRENT_DATE)),
      'completion_rate', (SELECT CASE WHEN COUNT(*) > 0 THEN ROUND((COUNT(CASE WHEN status = 'completed' THEN 1 END) * 100.0 / COUNT(*)), 2) ELSE 0 END FROM public.donations)
    ),
    'top_performers', json_build_object(
      'top_volunteers', (SELECT json_agg(row_to_json(t)) FROM (
        SELECT u.full_name, u.points, COUNT(d.donation_id) as completed_tasks
        FROM public.users u
        LEFT JOIN public.donations d ON u.id = d.volunteer_id AND d.status = 'completed'
        WHERE u.role = 'volunteer'
        GROUP BY u.id, u.full_name, u.points
        ORDER BY u.points DESC, completed_tasks DESC
        LIMIT 5
      ) t),
      'top_associations', (SELECT json_agg(row_to_json(t)) FROM (
        SELECT u.full_name, COUNT(d.donation_id) as total_received
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

-- Enhanced QR Code scanning with validation and logging
CREATE OR REPLACE FUNCTION scan_qr_code_enhanced(
  p_donation_id uuid,
  p_scan_type text, -- 'pickup' or 'delivery'
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
  
  -- Validate user permissions
  IF donation_record.volunteer_id != current_user_id THEN
    RETURN json_build_object('success', false, 'error', 'Unauthorized access');
  END IF;
  
  IF p_scan_type = 'pickup' THEN
    -- Donor QR Code scan
    IF donation_record.status != 'assigned' THEN
      RETURN json_build_object('success', false, 'error', 'Invalid donation status for pickup');
    END IF;
    
    UPDATE donations
    SET
      status = 'in_progress',
      picked_up_at = now()
    WHERE donation_id = p_donation_id;
    
    result := json_build_object('success', true, 'message', 'Pickup confirmed', 'new_status', 'in_progress');
    
  ELSIF p_scan_type = 'delivery' THEN
    -- Association QR Code scan
    IF donation_record.status != 'in_progress' THEN
      RETURN json_build_object('success', false, 'error', 'Invalid donation status for delivery');
    END IF;
    
    UPDATE donations
    SET
      status = 'completed',
      delivered_at = now()
    WHERE donation_id = p_donation_id;
    
    result := json_build_object('success', true, 'message', 'Delivery confirmed', 'new_status', 'completed');
    
  ELSE
    RETURN json_build_object('success', false, 'error', 'Invalid scan type');
  END IF;
  
  -- Log the scan event (optional location tracking)
  INSERT INTO volunteer_logs (volunteer_id, donation_id, start_time, notes)
  VALUES (
    current_user_id, 
    p_donation_id, 
    now(), 
    format('QR scan: %s at %s', p_scan_type, now()::text)
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

-- ====================================================================
-- Grant necessary permissions
-- ====================================================================

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION get_scheduled_donations(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION schedule_donation_pickup(uuid, timestamptz) TO authenticated;
GRANT EXECUTE ON FUNCTION get_association_report_data(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_optimizable_donations_for_routing(double precision, double precision, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION get_volunteer_dashboard_data(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_activation_code_enhanced(uuid, int) TO authenticated;
GRANT EXECUTE ON FUNCTION get_volunteers_with_detailed_ratings(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_manager_dashboard_comprehensive() TO authenticated;
GRANT EXECUTE ON FUNCTION scan_qr_code_enhanced(uuid, text, double precision, double precision) TO authenticated;
GRANT EXECUTE ON FUNCTION get_donation_tracking_history(uuid) TO authenticated;

-- ====================================================================
-- Verification
-- ====================================================================

DO $$
BEGIN
  RAISE NOTICE 'Missing SQL Functions Update Completed Successfully!';
  RAISE NOTICE 'Added functions:';
  RAISE NOTICE '- get_volunteer_dashboard_data';
  RAISE NOTICE '- generate_activation_code_enhanced';
  RAISE NOTICE '- get_volunteers_with_detailed_ratings';
  RAISE NOTICE '- get_manager_dashboard_comprehensive';
  RAISE NOTICE '- scan_qr_code_enhanced';
  RAISE NOTICE '- get_donation_tracking_history';
  RAISE NOTICE '- get_scheduled_donations';
  RAISE NOTICE '- schedule_donation_pickup';
  RAISE NOTICE '- get_association_report_data';
  RAISE NOTICE '- get_optimizable_donations_for_routing';
END $$;