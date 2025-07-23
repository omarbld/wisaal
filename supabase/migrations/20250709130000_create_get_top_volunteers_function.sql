
CREATE OR REPLACE FUNCTION get_top_volunteers(limit_count INT)
RETURNS TABLE(volunteer_id UUID, full_name TEXT, completed_donations_count BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.id AS volunteer_id,
        u.full_name,
        COUNT(d.donation_id) AS completed_donations_count
    FROM
        public.users u
    JOIN
        public.donations d ON u.id = d.volunteer_id
    WHERE
        u.role = 'volunteer' AND d.status = 'completed'
    GROUP BY
        u.id, u.full_name
    ORDER BY
        completed_donations_count DESC
    LIMIT
        limit_count;
END;
$$ LANGUAGE plpgsql;
