-- ===========================================
-- إصلاح صلاحيات دالة تسجيل المتطوعين
-- ===========================================

-- 1. منح الصلاحيات الأساسية للجداول
GRANT SELECT, UPDATE ON public.activation_codes TO authenticated;
GRANT INSERT, SELECT, UPDATE ON public.users TO authenticated;

-- 2. تعديل الدالة مع إضافة search_path
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
SET search_path = public
AS $function$
DECLARE
    v_code_id int;
    v_association_id uuid;
BEGIN
    -- الخطوة 1: التحقق من وجود كود التفعيل وأنه صالح للاستخدام
    SELECT id, created_by INTO v_code_id, v_association_id
    FROM public.activation_codes
    WHERE code = p_activation_code AND role = 'volunteer' AND is_used = FALSE
    FOR UPDATE;

    -- الخطوة 2: إذا لم يتم العثور على الكود، يتم إرجاع خطأ
    IF v_code_id IS NULL THEN
        RAISE EXCEPTION 'INVALID_ACTIVATION_CODE: The provided activation code is invalid, already used, or not for a volunteer.';
    END IF;

    -- الخطوة 3: تسجيل بيانات المستخدم الجديد في جدول users
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

-- 3. منح صلاحيات التنفيذ للدالة
GRANT EXECUTE ON FUNCTION public.register_volunteer(uuid, text, text, text, text, text) TO authenticated;

-- 4. تأكيد الصلاحيات
COMMENT ON FUNCTION public.register_volunteer IS 'دالة مسجلة مع صلاحيات أمان محدثة';

-- ===========================================
-- نهاية ملف إصلاح الصلاحيات
-- ===========================================
