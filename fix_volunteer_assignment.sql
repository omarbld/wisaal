-- Fix for volunteer assignment issue
-- This script ensures the get_volunteers_for_association function returns the correct column names

-- Drop and recreate the function with correct column names
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

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_volunteers_for_association(uuid) TO authenticated;

-- Test the function to ensure it works
DO $$
BEGIN
  RAISE NOTICE 'Function get_volunteers_for_association has been fixed!';
  RAISE NOTICE 'The function now returns:';
  RAISE NOTICE '- volunteer_id (instead of id)';
  RAISE NOTICE '- avg_rating (instead of average_rating)';
  RAISE NOTICE '- completed_tasks (instead of completed_tasks_count)';
END $$;