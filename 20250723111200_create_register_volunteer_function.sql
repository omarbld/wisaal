-- supabase/migrations/20250723111200_create_register_volunteer_function.sql

CREATE OR REPLACE FUNCTION public.register_volunteer(
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
AS $function$
DECLARE
    v_code_id int;
    v_association_id uuid;
BEGIN
    -- الخطوة 1: التحقق من وجود كود التفعيل وأنه صالح للاستخدام
    -- يتم قفل الصف لمنع الاستخدام المتزامن لنفس الكود
    SELECT id, created_by INTO v_code_id, v_association_id
    FROM public.activation_codes
    WHERE code = p_activation_code AND role = 'volunteer' AND is_used = FALSE
    FOR UPDATE;

    -- الخطوة 2: إذا لم يتم العثور على الكود، يتم إرجاع خطأ
    IF v_code_id IS NULL THEN
        RAISE EXCEPTION 'INVALID_ACTIVATION_CODE: The provided activation code is invalid, already used, or not for a volunteer.';
    END IF;

    -- الخطوة 3: تسجيل بيانات المستخدم الجديد في جدول users
    -- يتم ربط المتطوع بالجمعية التي أنشأت الكود
    INSERT INTO public.users (id, full_name, email, phone, city, role, associated_with_association_id)
    VALUES (p_user_id, p_full_name, p_email, p_phone, p_city, 'volunteer', v_association_id);

    -- الخطوة 4: تحديث كود التفعيل لتمييزه كمستخدم
    UPDATE public.activation_codes
    SET 
        is_used = TRUE,
        used_by_user_id = p_user_id,
        used_at = NOW()
    WHERE id = v_code_id;

END;
$function$;

-- Grant execute permission to the function for authenticated users
GRANT EXECUTE ON FUNCTION public.register_volunteer(uuid, text, text, text, text, text) TO authenticated;
