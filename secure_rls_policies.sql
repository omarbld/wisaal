-- ====================================================================
-- إصلاح سياسات Row Level Security الآمنة لتطبيق وصال
-- تاريخ الإنشاء: $(date)
-- الهدف: إزالة السياسات المفتوحة وإنشاء سياسات آمنة ومحددة
-- ====================================================================

-- التحقق من السياسات الحالية
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ====================================================================
-- إزالة جميع السياسات المفتوحة والخطيرة
-- ====================================================================

DO $$
DECLARE
    r RECORD;
BEGIN
    -- البحث عن السياسات المفتوحة (USING true أو WITH CHECK true)
    FOR r IN 
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND (qual = 'true' OR with_check = 'true')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
                      r.policyname, r.schemaname, r.tablename);
        RAISE NOTICE 'تم حذف السياسة المفتوحة: % على جدول %', r.policyname, r.tablename;
    END LOOP;
    
    -- حذف السياسات العامة المسماة "allow_all" أو مشابهة
    FOR r IN 
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND (policyname ILIKE '%allow_all%' 
             OR policyname ILIKE '%public%'
             OR policyname ILIKE '%open%')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
                      r.policyname, r.schemaname, r.tablename);
        RAISE NOTICE 'تم حذف السياسة العامة: % على جدول %', r.policyname, r.tablename;
    END LOOP;
END $$;

-- ====================================================================
-- إنشاء دالة مساعدة للتحقق من دور المستخدم
-- ====================================================================

CREATE OR REPLACE FUNCTION public.get_user_role(user_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_role text;
BEGIN
    SELECT role INTO user_role 
    FROM public.users 
    WHERE id = user_id;
    
    RETURN COALESCE(user_role, 'anonymous');
END;
$$;

-- ====================================================================
-- سياسات آمنة لجدول المستخدمين (users)
-- ====================================================================

-- حذف السياسات القديمة
DROP POLICY IF EXISTS "Users can view their own data" ON public.users;
DROP POLICY IF EXISTS "Users can update their own data" ON public.users;
DROP POLICY IF EXISTS "Managers can view all users" ON public.users;
DROP POLICY IF EXISTS "Allow anon insert users" ON public.users;
DROP POLICY IF EXISTS "Allow authenticated read own" ON public.users;

-- سياسة القراءة: المستخدمون يرون بياناتهم + المدراء يرون الكل
CREATE POLICY "secure_users_select" ON public.users
FOR SELECT USING (
    auth.uid() = id OR 
    get_user_role(auth.uid()) = 'manager' OR
    (get_user_role(auth.uid()) = 'association' AND associated_with_association_id = auth.uid())
);

-- سياسة التحديث: المستخدمون يحدثون بياناتهم فقط
CREATE POLICY "secure_users_update" ON public.users
FOR UPDATE USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- سياسة الإدراج: للمستخدمين الجدد فقط
CREATE POLICY "secure_users_insert" ON public.users
FOR INSERT WITH CHECK (auth.uid() = id);

-- سياسة الحذف: المدراء فقط
CREATE POLICY "secure_users_delete" ON public.users
FOR DELETE USING (get_user_role(auth.uid()) = 'manager');

-- ====================================================================
-- سياسات آمنة لجدول التبرعات (donations)
-- ====================================================================

-- حذف السياسات القديمة
DROP POLICY IF EXISTS "Users can manage their own donations" ON public.donations;
DROP POLICY IF EXISTS "Associations can manage their donations" ON public.donations;
DROP POLICY IF EXISTS "Volunteers can manage their assigned donations" ON public.donations;
DROP POLICY IF EXISTS "Managers can view all donations" ON public.donations;

-- سياسة القراءة: المتبرع + الجمعية + المتطوع المكلف + المدراء
CREATE POLICY "secure_donations_select" ON public.donations
FOR SELECT USING (
    auth.uid() = donor_id OR
    auth.uid() = association_id OR
    auth.uid() = volunteer_id OR
    get_user_role(auth.uid()) = 'manager'
);

-- سياسة الإدراج: المتبرعون فقط
CREATE POLICY "secure_donations_insert" ON public.donations
FOR INSERT WITH CHECK (
    auth.uid() = donor_id AND
    get_user_role(auth.uid()) = 'donor'
);

-- سياسة التحديث: المت��رع + الجمعية + المتطوع المكلف
CREATE POLICY "secure_donations_update" ON public.donations
FOR UPDATE USING (
    (auth.uid() = donor_id AND get_user_role(auth.uid()) = 'donor') OR
    (auth.uid() = association_id AND get_user_role(auth.uid()) = 'association') OR
    (auth.uid() = volunteer_id AND get_user_role(auth.uid()) = 'volunteer') OR
    get_user_role(auth.uid()) = 'manager'
);

-- سياسة الحذف: المتبرع والمدراء فقط
CREATE POLICY "secure_donations_delete" ON public.donations
FOR DELETE USING (
    (auth.uid() = donor_id AND get_user_role(auth.uid()) = 'donor') OR
    get_user_role(auth.uid()) = 'manager'
);

-- ====================================================================
-- سياسات آمنة لجدول الإشعارات (notifications)
-- ====================================================================

-- حذف السياسات القديمة
DROP POLICY IF EXISTS "Users can manage their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Managers can do anything" ON public.notifications;

-- سياسة القراءة: المستخدم يرى إشعاراته + الإشعارات العامة
CREATE POLICY "secure_notifications_select" ON public.notifications
FOR SELECT USING (
    user_id = auth.uid() OR 
    user_id IS NULL OR
    get_user_role(auth.uid()) = 'manager'
);

-- سياسة الإدراج: النظام والمدراء فقط
CREATE POLICY "secure_notifications_insert" ON public.notifications
FOR INSERT WITH CHECK (
    get_user_role(auth.uid()) = 'manager' OR
    auth.role() = 'service_role'
);

-- سياسة التحديث: المستخدم يحدث إشعاراته (قراءة/عدم قراءة)
CREATE POLICY "secure_notifications_update" ON public.notifications
FOR UPDATE USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- سياسة الحذف: المدراء فقط
CREATE POLICY "secure_notifications_delete" ON public.notifications
FOR DELETE USING (get_user_role(auth.uid()) = 'manager');

-- ====================================================================
-- سياسات آمنة لجدول التقييمات (ratings)
-- ====================================================================

-- حذف السياسات القديمة
DROP POLICY IF EXISTS "Users can view related ratings" ON public.ratings;
DROP POLICY IF EXISTS "Users can create ratings" ON public.ratings;
DROP POLICY IF EXISTS "Managers can view all ratings" ON public.ratings;

-- سياسة القراءة: المقيِّم والمُقيَّم والمدراء
CREATE POLICY "secure_ratings_select" ON public.ratings
FOR SELECT USING (
    rater_id = auth.uid() OR
    volunteer_id = auth.uid() OR
    get_user_role(auth.uid()) = 'manager'
);

-- سياسة الإدراج: الجمعيات تقيم المتطوعين
CREATE POLICY "secure_ratings_insert" ON public.ratings
FOR INSERT WITH CHECK (
    rater_id = auth.uid() AND
    get_user_role(auth.uid()) = 'association'
);

-- لا تحديث أو حذف للتقييمات (للحفاظ على النزاهة)

-- ====================================================================
-- سياسات آمنة لجدول أكواد التفعيل (activation_codes)
-- ====================================================================

-- حذف السياسات القديمة
DROP POLICY IF EXISTS "Anonymous can read activation codes for verification" ON public.activation_codes;
DROP POLICY IF EXISTS "Managers can do anything" ON public.activation_codes;
DROP POLICY IF EXISTS "Allow anon read codes" ON public.activation_codes;

-- سياسة القراءة: للتحقق من الأكواد (محدودة)
CREATE POLICY "secure_activation_codes_select" ON public.activation_codes
FOR SELECT USING (
    NOT is_used OR
    get_user_role(auth.uid()) = 'manager' OR
    get_user_role(auth.uid()) = 'association'
);

-- سياسة الإدراج: المدراء والجمعيات فقط
CREATE POLICY "secure_activation_codes_insert" ON public.activation_codes
FOR INSERT WITH CHECK (
    get_user_role(auth.uid()) = 'manager' OR
    (get_user_role(auth.uid()) = 'association' AND created_by_association_id = auth.uid())
);

-- سياسة التحديث: لتحديد الكود كمستخدم
CREATE POLICY "secure_activation_codes_update" ON public.activation_codes
FOR UPDATE USING (
    NOT is_used AND (
        get_user_role(auth.uid()) = 'manager' OR
        auth.role() = 'service_role'
    )
);

-- سياسة الحذف: المدراء فقط
CREATE POLICY "secure_activation_codes_delete" ON public.activation_codes
FOR DELETE USING (get_user_role(auth.uid()) = 'manager');

-- ====================================================================
-- التحقق من السياسات الجديدة
-- ====================================================================

SELECT 
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN qual = 'true' THEN '⚠️ OPEN POLICY'
        WHEN qual LIKE '%auth.uid()%' THEN '✅ SECURE'
        ELSE '⚠️ CHECK NEEDED'
    END as security_status
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ====================================================================
-- تفعيل RLS على جميع الجداول المهمة
-- ====================================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.donations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activation_codes ENABLE ROW LEVEL SECURITY;

-- ====================================================================
-- رسالة النجاح
-- ====================================================================

DO $$
BEGIN
    RAISE NOTICE '====================================================================';
    RAISE NOTICE '✅ تم تطبيق السياسات الأمنية بنجاح!';
    RAISE NOTICE '🔒 جميع الجداول محمية بسياسات RLS آمنة';
    RAISE NOTICE '🚫 تم إزالة جميع السياسات المفتوحة';
    RAISE NOTICE '👥 السياسات تحترم أدوار المستخدمين';
    RAISE NOTICE '====================================================================';
END $$;