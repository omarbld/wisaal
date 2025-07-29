-- ============================================================================
-- إصلاح سياسة RLS لحل مشكلة إدخال رمز OTP - نسخة مبسطة
-- تم إنشاؤه: 2025-01-20
-- الوصف: يصلح سياسات Row Level Security للسماح بإنشاء المستخدمين عند إدخال OTP
-- ============================================================================

-- عرض السياسات الحالية أولاً
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

-- ============================================================================
-- إصلاح سياسات RLS لجدول users
-- ============================================================================

-- حذف السياسات المقيدة الحالية
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.users;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.users;
DROP POLICY IF EXISTS "Allow anonymous users to create accounts" ON public.users;

-- سياسة للسماح للمستخدمين المجهولين بإنشاء حسابات جديدة
CREATE POLICY "Allow anon insert users"
ON public.users
FOR INSERT
TO anon
WITH CHECK (true);

-- سياسة للسماح للمستخدمين المصادق عليهم بقراءة ملفاتهم
CREATE POLICY "Allow authenticated read own"
ON public.users
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- سياسة للسماح للمستخدمين المصادق عليهم بتحديث ملفاتهم
CREATE POLICY "Allow authenticated update own"
ON public.users
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- ============================================================================
-- إصلاح سياسات RLS لجدول activation_codes
-- ============================================================================

-- حذف السياسات المقيدة الحالية
DROP POLICY IF EXISTS "Enable read access for all users" ON public.activation_codes;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.activation_codes;
DROP POLICY IF EXISTS "Allow anonymous users to read activation codes" ON public.activation_codes;
DROP POLICY IF EXISTS "Allow anonymous users to update activation codes" ON public.activation_codes;
DROP POLICY IF EXISTS "Managers can manage activation codes" ON public.activation_codes;

-- سياسة للسماح للمستخدمين المجهولين بقراءة أكواد التفعيل
CREATE POLICY "Allow anon read codes"
ON public.activation_codes
FOR SELECT
TO anon
USING (true);

-- سياسة للسماح للمستخدمين المجهولين بتحديث أكواد التفعيل
CREATE POLICY "Allow anon update codes"
ON public.activation_codes
FOR UPDATE
TO anon
USING (true)
WITH CHECK (true);

-- سياسة للسماح للمستخدمين المصادق عليهم بإدارة أكواد التفعيل
CREATE POLICY "Allow authenticated manage codes"
ON public.activation_codes
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

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

-- ============================================================================
-- رسائل النجاح
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '=== تم إصلاح سياسات RLS بنجاح ===';
    RAISE NOTICE '1. تم السماح للمستخدمين المجهولين بإنشاء حسابات في جدول users';
    RAISE NOTICE '2. تم السماح للمستخدمين المجهولين بقراءة وتحديث أكواد التفعيل';
    RAISE NOTICE '3. يمكن الآن إدخال رمز OTP بدون مشاكل RLS';
    RAISE NOTICE '=== العملية مكتملة ===';
END $$;

-- ============================================================================
-- تعليمات للمطور
-- ============================================================================

/*
ملاحظات مهمة:

1. هذا الحل يسمح للمستخدمين المجهولين (anon) بإنشاء حسابات جديدة
2. يسمح أيضاً بقراءة وتحديث أكواد التفعيل
3. المستخدمون المصادق عليهم يمكنهم قراءة وتحديث ملفاتهم الشخصية فقط
4. هذا يحل مشكلة PostgrestException عند إدخال OTP

لاختبار الحل:
- جرب إدخال رمز OTP في التطبيق
- يجب أن يعمل بدون أخطاء RLS الآن
*/
