-- Fix for the ambiguous "code" column reference in generate_activation_code_enhanced function
-- This fixes the PostgrestException: column reference "code" is ambiguous

CREATE OR REPLACE FUNCTION generate_activation_code_enhanced(
  p_association_id uuid,
  p_count int DEFAULT 1
)
RETURNS TABLE(generated_code text, created_at timestamptz) AS $$
DECLARE
  i int;
  new_code text;
  created_time timestamptz;
BEGIN
  FOR i IN 1..p_count LOOP
    -- Generate a random 8-character code
    new_code := upper(substring(md5(random()::text || clock_timestamp()::text) from 1 for 8));
    
    -- Ensure uniqueness
    WHILE EXISTS (SELECT 1 FROM public.activation_codes WHERE activation_codes.code = new_code) LOOP
      new_code := upper(substring(md5(random()::text || clock_timestamp()::text) from 1 for 8));
    END LOOP;
    
    -- Insert the code
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
    
    generated_code := new_code;
    created_at := created_time;
    RETURN NEXT;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION generate_activation_code_enhanced(uuid, int) TO authenticated;