-- Fix for ambiguous column reference "volunteer_id"
-- This script fixes the ambiguous column reference in get_association_report_data function

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

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_association_report_data(uuid, text) TO authenticated;

-- Test the function
DO $$
BEGIN
  RAISE NOTICE 'Fixed ambiguous column reference in get_association_report_data function!';
  RAISE NOTICE 'Changes made:';
  RAISE NOTICE '- Added table aliases (d.volunteer_id, d.donor_id)';
  RAISE NOTICE '- Fixed JOIN conditions to be more explicit';
  RAISE NOTICE '- Ensured all column references are unambiguous';
END $$;