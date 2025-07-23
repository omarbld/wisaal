-- ====================================================================
-- دوال إدارة الموقع والتحقق من التكرار
-- ====================================================================

-- دالة لاستخراج الإحداثيات من PostGIS Point
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

-- دالة للتحقق من المستخدمين المكررين بنفس الموقع
CREATE OR REPLACE FUNCTION check_duplicate_user_locations()
RETURNS TABLE(
  full_name text,
  email text,
  latitude double precision,
  longitude double precision,
  duplicate_count bigint
) AS $$
BEGIN
  RETURN QUERY
  WITH location_groups AS (
    SELECT 
      ST_Y(location::geometry) as lat,
      ST_X(location::geometry) as lng,
      COUNT(*) as count_users,
      array_agg(u.full_name) as names,
      array_agg(u.email) as emails
    FROM public.users u
    WHERE u.location IS NOT NULL
    GROUP BY ST_Y(location::geometry), ST_X(location::geometry)
    HAVING COUNT(*) > 1
  )
  SELECT 
    unnest(lg.names) as full_name,
    unnest(lg.emails) as email,
    lg.lat as latitude,
    lg.lng as longitude,
    lg.count_users as duplicate_count
  FROM location_groups lg;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- دالة للتحقق من التبرعات المكررة بنفس الموقع
CREATE OR REPLACE FUNCTION check_duplicate_donation_locations()
RETURNS TABLE(
  title text,
  donor_name text,
  latitude double precision,
  longitude double precision,
  duplicate_count bigint
) AS $$
BEGIN
  RETURN QUERY
  WITH location_groups AS (
    SELECT 
      ST_Y(d.location::geometry) as lat,
      ST_X(d.location::geometry) as lng,
      COUNT(*) as count_donations,
      array_agg(d.title) as titles,
      array_agg(u.full_name) as donor_names
    FROM public.donations d
    JOIN public.users u ON d.donor_id = u.id
    WHERE d.location IS NOT NULL
    GROUP BY ST_Y(d.location::geometry), ST_X(d.location::geometry)
    HAVING COUNT(*) > 1
  )
  SELECT 
    unnest(lg.titles) as title,
    unnest(lg.donor_names) as donor_name,
    lg.lat as latitude,
    lg.lng as longitude,
    lg.count_donations as duplicate_count
  FROM location_groups lg;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- دالة للتحقق من المستخدمين المكررين بنفس البيانات الشخصية
CREATE OR REPLACE FUNCTION check_duplicate_personal_data()
RETURNS TABLE(
  full_name text,
  phone text,
  email text,
  duplicate_count bigint
) AS $$
BEGIN
  RETURN QUERY
  -- التحقق من تكرار الأسماء والهواتف
  SELECT 
    u.full_name,
    u.phone,
    u.email,
    COUNT(*) as duplicate_count
  FROM public.users u
  WHERE u.phone IS NOT NULL AND u.phone != ''
  GROUP BY u.full_name, u.phone, u.email
  HAVING COUNT(*) > 1
  
  UNION ALL
  
  -- التحقق من تكرار البريد الإلكتروني
  SELECT 
    u.full_name,
    u.phone,
    u.email,
    COUNT(*) as duplicate_count
  FROM public.users u
  GROUP BY u.email
  HAVING COUNT(*) > 1 AND u.email IS NOT NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- دالة لتنظيف البيانات المكررة (للاستخدام الحذر)
CREATE OR REPLACE FUNCTION cleanup_duplicate_users()
RETURNS TABLE(
  action text,
  user_id uuid,
  full_name text,
  email text
) AS $$
DECLARE
  duplicate_record RECORD;
  keep_user_id uuid;
BEGIN
  -- البحث عن المستخدمين المكررين بنفس البريد الإلكتروني
  FOR duplicate_record IN 
    SELECT email, array_agg(id ORDER BY created_at ASC) as user_ids
    FROM public.users
    GROUP BY email
    HAVING COUNT(*) > 1
  LOOP
    -- الاحتفاظ بأول مستخدم (الأقدم)
    keep_user_id := duplicate_record.user_ids[1];
    
    -- حذف المستخدمين المكررين الآخرين
    FOR i IN 2..array_length(duplicate_record.user_ids, 1) LOOP
      -- تحديث المراجع في الجداول الأخرى قبل الحذف
      UPDATE public.donations SET donor_id = keep_user_id 
      WHERE donor_id = duplicate_record.user_ids[i];
      
      UPDATE public.donations SET association_id = keep_user_id 
      WHERE association_id = duplicate_record.user_ids[i];
      
      UPDATE public.donations SET volunteer_id = keep_user_id 
      WHERE volunteer_id = duplicate_record.user_ids[i];
      
      -- إرجاع معلومات المستخدم المحذوف
      RETURN QUERY
      SELECT 
        'DELETED'::text as action,
        duplicate_record.user_ids[i] as user_id,
        u.full_name,
        u.email
      FROM public.users u
      WHERE u.id = duplicate_record.user_ids[i];
      
      -- حذف المستخدم المكرر
      DELETE FROM public.users WHERE id = duplicate_record.user_ids[i];
    END LOOP;
    
    -- إرجاع معلومات المستخدم المحتفظ به
    RETURN QUERY
    SELECT 
      'KEPT'::text as action,
      keep_user_id as user_id,
      u.full_name,
      u.email
    FROM public.users u
    WHERE u.id = keep_user_id;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- دالة لتحديث موقع المستخدم مع التحقق من الصحة
CREATE OR REPLACE FUNCTION update_user_location_safe(
  p_latitude double precision,
  p_longitude double precision
)
RETURNS json AS $$
DECLARE
  current_user_id uuid := auth.uid();
  result json;
BEGIN
  -- التحقق من صحة الإحداثيات
  IF p_latitude IS NULL OR p_longitude IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'الإحداثيات غير صالحة'
    );
  END IF;
  
  -- التحقق من نطاق الإحداثيات (المغرب تقريباً)
  IF p_latitude < 20 OR p_latitude > 40 OR p_longitude < -20 OR p_longitude > 0 THEN
    RETURN json_build_object(
      'success', false,
      'error', 'الإحداثيات خارج النطاق المسموح'
    );
  END IF;
  
  -- تحديث موقع المستخدم
  UPDATE public.users 
  SET location = ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)
  WHERE id = current_user_id;
  
  -- تحديث جدول المواقع المباشرة
  INSERT INTO public.user_locations (user_id, location, last_seen)
  VALUES (current_user_id, ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326), NOW())
  ON CONFLICT (user_id)
  DO UPDATE SET
    location = ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326),
    last_seen = NOW();
  
  RETURN json_build_object(
    'success', true,
    'latitude', p_latitude,
    'longitude', p_longitude,
    'updated_at', NOW()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- دالة للحصول على المستخدمين القريبين
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

-- دالة للحصول على التبرعات القريبة
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

-- منح الصلاحيات للدوال الجديدة
GRANT EXECUTE ON FUNCTION extract_coordinates_from_location(geography) TO authenticated;
GRANT EXECUTE ON FUNCTION check_duplicate_user_locations() TO authenticated;
GRANT EXECUTE ON FUNCTION check_duplicate_donation_locations() TO authenticated;
GRANT EXECUTE ON FUNCTION check_duplicate_personal_data() TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_duplicate_users() TO postgres; -- للمدير فقط
GRANT EXECUTE ON FUNCTION update_user_location_safe(double precision, double precision) TO authenticated;
GRANT EXECUTE ON FUNCTION get_nearby_users(double precision, double precision, double precision, text) TO authenticated;
GRANT EXECUTE ON FUNCTION get_nearby_donations(double precision, double precision, double precision, text) TO authenticated;

-- إشعار بالانتهاء
DO $$
BEGIN
  RAISE NOTICE 'تم إنشاء دوال إدارة الموقع بنجاح!';
  RAISE NOTICE 'الدوال المتاحة:';
  RAISE NOTICE '- extract_coordinates_from_location() - استخراج الإحداثيات';
  RAISE NOTICE '- check_duplicate_user_locations() - فحص المستخدمين المكررين';
  RAISE NOTICE '- check_duplicate_donation_locations() - فحص التبرعات المكررة';
  RAISE NOTICE '- check_duplicate_personal_data() - فحص البيانات الشخصية المكررة';
  RAISE NOTICE '- update_user_location_safe() - تحديث الموقع بأمان';
  RAISE NOTICE '- get_nearby_users() - البحث عن المستخدمين القريبين';
  RAISE NOTICE '- get_nearby_donations() - البحث عن التبرعات القريبة';
END $$;