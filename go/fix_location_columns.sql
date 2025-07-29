-- إصلاح مشكلة أعمدة latitude و longitude المفقودة
-- هذا الملف يحتوي على الدوال والتحديثات اللازمة لحل مشكلة PostGIS

-- دالة لاستخراج latitude من عمود location
CREATE OR REPLACE FUNCTION get_latitude_from_location(location_geom geography)
RETURNS double precision AS $$
BEGIN
  IF location_geom IS NULL THEN
    RETURN NULL;
  END IF;
  RETURN ST_Y(location_geom::geometry);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- دالة لاستخراج longitude من عمود location
CREATE OR REPLACE FUNCTION get_longitude_from_location(location_geom geography)
RETURNS double precision AS $$
BEGIN
  IF location_geom IS NULL THEN
    RETURN NULL;
  END IF;
  RETURN ST_X(location_geom::geometry);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- إنشاء view لجدول donations مع أعمدة latitude و longitude
CREATE OR REPLACE VIEW donations_with_coordinates AS
SELECT 
  *,
  get_latitude_from_location(location) as latitude,
  get_longitude_from_location(location) as longitude
FROM donations;

-- إنشاء view لجدول users مع أعمدة latitude و longitude
CREATE OR REPLACE VIEW users_with_coordinates AS
SELECT 
  *,
  get_latitude_from_location(location) as latitude,
  get_longitude_from_location(location) as longitude
FROM users;

-- دالة محدثة للحصول على بيانات الخريطة مع الإحداثيات
CREATE OR REPLACE FUNCTION get_map_data_with_coordinates(p_user_role text, p_user_id uuid DEFAULT NULL)
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
      get_latitude_from_location(d.location) as latitude,
      get_longitude_from_location(d.location) as longitude,
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
      get_latitude_from_location(d.location) as latitude,
      get_longitude_from_location(d.location) as longitude,
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
      get_latitude_from_location(d.location) as latitude,
      get_longitude_from_location(d.location) as longitude,
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
      get_latitude_from_location(d.location) as latitude,
      get_longitude_from_location(d.location) as longitude,
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
      get_latitude_from_location(u.location) as latitude,
      get_longitude_from_location(u.location) as longitude,
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

-- دالة للحصول على التبرعات مع الإحداثيات للخريطة
CREATE OR REPLACE FUNCTION get_donations_with_coordinates_for_map()
RETURNS TABLE (
  donation_id uuid,
  title text,
  status donation_status,
  latitude double precision,
  longitude double precision,
  location_json json
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.donation_id,
    d.title,
    d.status,
    get_latitude_from_location(d.location) as latitude,
    get_longitude_from_location(d.location) as longitude,
    ST_AsGeoJSON(d.location)::json as location_json
  FROM
    donations d
  WHERE
    d.location IS NOT NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- منح الصلاحيات للدوال الجديدة
GRANT EXECUTE ON FUNCTION get_latitude_from_location(geography) TO authenticated;
GRANT EXECUTE ON FUNCTION get_longitude_from_location(geography) TO authenticated;
GRANT EXECUTE ON FUNCTION get_map_data_with_coordinates(text, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_donations_with_coordinates_for_map() TO authenticated;

-- منح الصلاحيات للـ views
GRANT SELECT ON donations_with_coordinates TO authenticated;
GRANT SELECT ON users_with_coordinates TO authenticated;

-- إشعار بالانتهاء
DO $$
BEGIN
  RAISE NOTICE 'تم إنشاء الدوال والـ Views بنجاح!';
  RAISE NOTICE 'يمكنك الآن استخدام:';
  RAISE NOTICE '- donations_with_coordinates view للحصول على التبرعات مع الإحداثيات';
  RAISE NOTICE '- users_with_coordinates view للحصول على المستخدمين مع الإحداثيات';
  RAISE NOTICE '- get_map_data_with_coordinates() function للحصول على بيانات الخريطة';
  RAISE NOTICE '- get_donations_with_coordinates_for_map() function للحصول على التبرعات للخريطة';
END $$;
