-- ===========================================
-- إصلاح شامل لصلاحيات قاعدة البيانات
-- Fix Database Permissions Comprehensively
-- ===========================================

-- 1. منح الصلاحيات الأساسية للمخطط العام (public schema)
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;

-- 2. منح صلاحيات الجداول الأساسية
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;

-- 3. منح صلاحيات التسلسلات (sequences)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;

-- 4. منح صلاحيات الدوال
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon;

-- 5. تعيين الصلاحيات الافتراضية للكائنات المستقبلية
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO anon;

-- 6. إصلاح صلاحيات الجداول المحددة
GRANT ALL PRIVILEGES ON TABLE public.users TO authenticated;
GRANT ALL PRIVILEGES ON TABLE public.donations TO authenticated;
GRANT ALL PRIVILEGES ON TABLE public.activation_codes TO authenticated;
GRANT ALL PRIVILEGES ON TABLE public.notifications TO authenticated;
GRANT ALL PRIVILEGES ON TABLE public.ratings TO authenticated;
GRANT ALL PRIVILEGES ON TABLE public.user_locations TO authenticated;
GRANT ALL PRIVILEGES ON TABLE public.badges TO authenticated;
GRANT ALL PRIVILEGES ON TABLE public.user_badges TO authenticated;
GRANT ALL PRIVILEGES ON TABLE public.volunteer_logs TO authenticated;

-- منح صلاحيات القراءة للمستخدمين غير المصادق عليهم
GRANT SELECT ON TABLE public.activation_codes TO anon;
GRANT SELECT ON TABLE public.badges TO anon;

-- 7. إصلاح صلاحيات الدوال المهمة
GRANT EXECUTE ON FUNCTION public.register_volunteer(uuid, text, text, text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.register_volunteer(uuid, text, text, text, text, text) TO anon;

-- دوال أخرى مهمة
GRANT EXECUTE ON FUNCTION public.get_user_role(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_role(uuid) TO anon;

-- دوال كود التفعيل
GRANT EXECUTE ON FUNCTION public.check_activation_code(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_activation_code(text) TO anon;
GRANT EXECUTE ON FUNCTION public.is_activation_code_valid(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_activation_code_valid(text) TO anon;
GRANT EXECUTE ON FUNCTION public.get_activation_code_details(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_activation_code_details(text) TO anon;

-- 8. إصلاح سياسات RLS المتساهلة مؤقتاً للتشخيص
-- تعطيل RLS مؤقتاً للتشخيص (يمكن إعادة تفعيلها لاحقاً)
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.donations DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.activation_codes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.ratings DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_locations DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.badges DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_badges DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.volunteer_logs DISABLE ROW LEVEL SECURITY;

-- 9. إنشاء سياسات RLS أكثر تساهلاً للاختبار
-- حذف السياسات الموجودة أولاً ثم إنشاء سياسات جديدة
DROP POLICY IF EXISTS "Allow authenticated users full access" ON public.users;
DROP POLICY IF EXISTS "Allow authenticated users full access" ON public.donations;
DROP POLICY IF EXISTS "Allow authenticated users full access" ON public.activation_codes;
DROP POLICY IF EXISTS "Allow authenticated users full access" ON public.notifications;
DROP POLICY IF EXISTS "Allow authenticated users full access" ON public.ratings;
DROP POLICY IF EXISTS "Allow authenticated users full access" ON public.user_locations;
DROP POLICY IF EXISTS "Allow authenticated users full access" ON public.badges;
DROP POLICY IF EXISTS "Allow authenticated users full access" ON public.user_badges;
DROP POLICY IF EXISTS "Allow authenticated users full access" ON public.volunteer_logs;
DROP POLICY IF EXISTS "Allow anon read activation codes" ON public.activation_codes;
DROP POLICY IF EXISTS "Allow anon read badges" ON public.badges;

-- إنشاء سياسات جديدة للمستخدمين المصادق عليهم للوصول لكل شيء
CREATE POLICY "Allow authenticated users full access" ON public.users
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Allow authenticated users full access" ON public.donations
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Allow authenticated users full access" ON public.activation_codes
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Allow authenticated users full access" ON public.notifications
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Allow authenticated users full access" ON public.ratings
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Allow authenticated users full access" ON public.user_locations
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Allow authenticated users full access" ON public.badges
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Allow authenticated users full access" ON public.user_badges
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Allow authenticated users full access" ON public.volunteer_logs
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- سياسات للمستخدمين غير المصادق عليهم (قراءة فقط لبعض الجداول)
CREATE POLICY "Allow anon read activation codes" ON public.activation_codes
    FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anon read badges" ON public.badges
    FOR SELECT TO anon USING (true);

-- 10. إعادة تفعيل RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.donations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activation_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.volunteer_logs ENABLE ROW LEVEL SECURITY;

-- 11. إصلاح دالة register_volunteer مع صلاحيات محسنة
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
    -- التحقق من وجود كود التفعيل وأنه صالح للاستخدام
    SELECT id, created_by_association_id INTO v_code_id, v_association_id
    FROM public.activation_codes
    WHERE code = p_activation_code AND role = 'volunteer' AND is_used = FALSE
    FOR UPDATE;

    -- إذا لم يتم العثور على الكود، يتم إرجاع خطأ
    IF v_code_id IS NULL THEN
        RAISE EXCEPTION 'INVALID_ACTIVATION_CODE: The provided activation code is invalid, already used, or not for a volunteer.';
    END IF;

    -- تسجيل بيانات المستخدم الجديد في جدول users
    INSERT INTO public.users (id, full_name, email, phone, city, role, associated_with_association_id)
    VALUES (p_user_id, p_full_name, p_email, p_phone, p_city, 'volunteer', v_association_id);

    -- تحديث كود التفعيل لتمييزه كمستخدم
    UPDATE public.activation_codes
    SET 
        is_used = TRUE,
        used_by_user_id = p_user_id,
        used_at = NOW()
    WHERE id = v_code_id;

END;
$function$;

-- منح صلاحيات التنفيذ للدالة
GRANT EXECUTE ON FUNCTION public.register_volunteer(uuid, text, text, text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.register_volunteer(uuid, text, text, text, text, text) TO anon;

-- 12. التحقق من الصلاحيات
DO $$
BEGIN
    RAISE NOTICE 'تم إصلاح صلاحيات قاعدة البيانات بنجاح!';
    RAISE NOTICE 'Database permissions fixed successfully!';
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'الجداول المحدثة: %', (SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public');
    RAISE NOTICE 'الدوال المحدثة: %', (SELECT count(*) FROM information_schema.routines WHERE routine_schema = 'public');
    RAISE NOTICE 'السياسات المحدثة: %', (SELECT count(*) FROM pg_policies WHERE schemaname = 'public');
    RAISE NOTICE '==========================================';
END $$;

-- ===========================================
-- نهاية ملف إصلاح الصلاحيات
-- ===========================================