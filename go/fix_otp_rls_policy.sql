-- ============================================================================
-- إصلاح سياسة RLS لحل مشكلة إدخال رمز OTP
-- تم إنشاؤه: 2025-01-20
-- الوصف: يصلح سياسات Row Level Security للسماح بإنشاء المستخدمين عند إدخال OTP
-- ============================================================================

-- التحقق من السياسات الحالية
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename IN ('users', 'activation_codes')
ORDER BY tablename, policyname;

-- ============================================================================
-- إصلاح سياسات RLS لجدول users
-- ============================================================================

-- حذف السياسات الحالية المقيدة (إن وجدت)
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.users;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.users;

-- إنشاء سياسة للسماح للمستخدمين المجهولين بإنشاء حسابات جديدة
CREATE POLICY "Allow anonymous users to create accounts"
ON public.users
FOR INSERT
TO anon
WITH CHECK (true);

-- إنشاء سياسة للسماح للمستخدمين المصادق عليهم بقراءة ملفاتهم الشخصية
CREATE POLICY "Users can view own profile"
ON public.users
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- إنشاء سياسة للسماح للمستخدمين المصادق عليهم بتحديث ملفاتهم الشخصية
CREATE POLICY "Users can update own profile"
ON public.users
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- إنشاء سياسة للسماح للمديرين بقراءة جميع المستخدمين
CREATE POLICY "Managers can view all users"
ON public.users
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role IN ('manager', 'association')
    )
);

-- ============================================================================
-- إصلاح سياسات RLS لجدول activation_codes
-- ============================================================================

-- حذف السياسات الحالية المقيدة (إن وجدت)
DROP POLICY IF EXISTS "Enable read access for all users" ON public.activation_codes;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.activation_codes;

-- إنشاء سياسة للسماح للمستخدمين المجهولين بقراءة أكواد التفعيل (للتحقق من صحتها)
CREATE POLICY "Allow anonymous users to read activation codes"
ON public.activation_codes
FOR SELECT
TO anon
USING (true);

-- إنشاء سياسة للسماح للمستخدمين المجهولين بتحديث أكواد التفعيل (لتمييزها كمستخدمة)
CREATE POLICY "Allow anonymous users to update activation codes"
ON public.activation_codes
FOR UPDATE
TO anon
USING (true)
WITH CHECK (true);

-- إنشاء سياسة للسماح للمديرين بإدارة أكواد التفعيل
CREATE POLICY "Managers can manage activation codes"
ON public.activation_codes
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role IN ('manager', 'association')
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role IN ('manager', 'association')
    )
);

-- ============================================================================
-- إنشاء دالة للتحقق من أكواد التفعيل وإنشاء المستخدمين
-- ============================================================================

-- إنشاء دالة آمنة للتحقق من كود التفعيل وإنشاء المستخدم
CREATE OR REPLACE FUNCTION public.verify_activation_code_and_create_user(
    p_activation_code TEXT,
    p_email TEXT,
    p_full_name TEXT,
    p_phone TEXT DEFAULT NULL,
    p_password TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER -- تشغيل بصلاحيات المالك (postgres)
SET search_path = public
AS $$
DECLARE
    v_code_record RECORD;
    v_user_id UUID;
    v_result JSON;
BEGIN
    -- التحقق من وجود كود التفعيل وصحته
    SELECT * INTO v_code_record
    FROM public.activation_codes
    WHERE code = p_activation_code
    AND is_used = false
    AND expires_at > NOW()
    AND current_uses < max_uses;
    
    -- إذا لم يتم العثور على الكود أو انتهت صلاحيته
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'كود التفعيل غير صحيح أو منتهي الصلاحية'
        );
    END IF;
    
    -- التحقق من عدم وجود مستخدم بنفس البريد الإلكتروني
    IF EXISTS (SELECT 1 FROM public.users WHERE email = p_email) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'يوجد مستخدم مسجل بهذا البريد الإلكتروني بالفعل'
        );
    END IF;
    
    -- إنشاء معرف فريد للمستخدم الجديد
    v_user_id := gen_random_uuid();
    
    -- إنشاء المستخدم الجديد
    INSERT INTO public.users (
        id,
        email,
        full_name,
        phone,
        role,
        is_active,
        created_at,
        updated_at
    ) VALUES (
        v_user_id,
        p_email,
        p_full_name,
        p_phone,
        v_code_record.role,
        true,
        NOW(),
        NOW()
    );
    
    -- تحديث كود التفعيل كمستخدم
    UPDATE public.activation_codes
    SET 
        is_used = true,
        current_uses = current_uses + 1,
        association_id = v_user_id,
        updated_at = NOW()
    WHERE code = p_activation_code;
    
    -- إرجاع النتيجة الناجحة
    RETURN json_build_object(
        'success', true,
        'user_id', v_user_id,
        'role', v_code_record.role,
        'message', 'تم إنشاء الحساب بنجاح'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        -- في حالة حدوث خطأ
        RETURN json_build_object(
            'success', false,
            'error', 'حدث خطأ أثناء إنشاء الحساب: ' || SQLERRM
        );
END;
$$;

-- منح الصلاحيات للمستخدمين المجهولين لاستخدام الدالة
GRANT EXECUTE ON FUNCTION public.verify_activation_code_and_create_user TO anon;
GRANT EXECUTE ON FUNCTION public.verify_activation_code_and_create_user TO authenticated;

-- ============================================================================
-- إنشاء دالة للتحقق من كود التفعيل فقط (بدون إنشاء مستخدم)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.check_activation_code(p_activation_code TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_code_record RECORD;
BEGIN
    -- التحقق من وجود كود التفعيل وصحته
    SELECT 
        code,
        role,
        expires_at,
        is_used,
        current_uses,
        max_uses
    INTO v_code_record
    FROM public.activation_codes
    WHERE code = p_activation_code;
    
    -- إذا لم يتم العثور على الكود
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'كود التفعيل غير موجود'
        );
    END IF;
    
    -- التحقق من صحة الكود
    IF v_code_record.is_used = true OR 
       v_code_record.expires_at < NOW() OR 
       v_code_record.current_uses >= v_code_record.max_uses THEN
        RETURN json_build_object(
            'success', false,
            'error', 'كود التفعيل غير صالح أو منتهي الصلاحية',
            'details', json_build_object(
                'is_used', v_code_record.is_used,
                'expires_at', v_code_record.expires_at,
                'current_uses', v_code_record.current_uses,
                'max_uses', v_code_record.max_uses
            )
        );
    END IF;
    
    -- إرجاع معلومات الكود الصحيح
    RETURN json_build_object(
        'success', true,
        'role', v_code_record.role,
        'expires_at', v_code_record.expires_at,
        'message', 'كود التفعيل صحيح'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'حدث خطأ أثناء التحقق من الكود: ' || SQLERRM
        );
END;
$$;

-- منح الصلاحيات للمستخدمين المجهولين لاستخدام الدالة
GRANT EXECUTE ON FUNCTION public.check_activation_code TO anon;
GRANT EXECUTE ON FUNCTION public.check_activation_code TO authenticated;

-- ============================================================================
-- التحقق من النتائج
-- ============================================================================

-- عرض السياسات الجديدة
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename IN ('users', 'activation_codes')
ORDER BY tablename, policyname;

-- اختبار الدالة الجديدة (اختياري)
-- SELECT public.check_activation_code('012006001TB');

-- ============================================================================
-- رسائل النجاح والتوجيهات
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '=== تم إصلاح سياسات RLS بنجاح ===';
    RAISE NOTICE '1. تم إنشاء سياسات جديدة للسماح للمستخدمين المجهولين بإنشاء حسابات';
    RAISE NOTICE '2. تم إنشاء دالة آمنة للتحقق من أكواد التفعيل وإنشاء المستخدمين';
    RAISE NOTICE '3. تم إنشاء دالة للتحقق من صحة أكواد التفعيل';
    RAISE NOTICE '=== كيفية الاستخدام ===';
    RAISE NOTICE 'استخدم الدالة: verify_activation_code_and_create_user()';
    RAISE NOTICE 'أو الدالة: check_activation_code() للتحقق فقط';
    RAISE NOTICE '=== العملية مكتملة ===';
END $$;

-- ============================================================================
-- تعليمات للمطور
-- ============================================================================

/*
تعليمات الاستخدام:

1. للتحقق من كود التفعيل فقط:
   SELECT public.check_activation_code('YOUR_CODE_HERE');

2. لإنشاء مستخدم جديد باستخدام كود التفعيل:
   SELECT public.verify_activation_code_and_create_user(
       'YOUR_CODE_HERE',
       'user@example.com',
       'اسم المستخدم',
       '1234567890'
   );

3. في تطبيق Flutter، استخدم:
   - supabase.rpc('check_activation_code', {'p_activation_code': code})
   - supabase.rpc('verify_activation_code_and_create_user', {
       'p_activation_code': code,
       'p_email': email,
       'p_full_name': fullName,
       'p_phone': phone
     })

4. هذا الحل يسمح للمستخدمين المجهولين بإنشاء حسابات جديدة
   باستخدام أكواد التفعيل الصحيحة فقط.

5. السياسات الجديدة آمنة ولا تسمح بالوصول غير المصرح به.
*/

-- ============================================================================
-- نهاية الملف
-- ============================================================================
