-- ============================================================================
-- إصلاح قيد التحقق لجدول أكواد التفعيل
-- تم إنشاؤه: 2025-01-20
-- الوصف: يصلح قيد التحقق ليسمح بجميع الأدوار المطلوبة
-- ============================================================================

-- أولاً: حذف القيد الحالي
ALTER TABLE public.activation_codes 
DROP CONSTRAINT IF EXISTS activation_codes_role_check;

-- ثانياً: إضافة القيد الجديد الذي يشمل جميع الأدوار
ALTER TABLE public.activation_codes 
ADD CONSTRAINT activation_codes_role_check 
CHECK (role IN ('volunteer', 'manager', 'association', 'donor'));

-- ثالثاً: إضافة أكواد التفعيل المطلوبة
-- إضافة كود تفعيل المدير: 012006001TB
INSERT INTO public.activation_codes (code, association_id, role, expires_at, max_uses, current_uses)
VALUES (
    '012006001TB',
    COALESCE(
        (SELECT id FROM public.users WHERE role = 'manager' LIMIT 1),
        uuid_generate_v4()
    ),
    'manager',
    NOW() + INTERVAL '1 year',
    1,
    0
)
ON CONFLICT (code) DO UPDATE SET
    expires_at = NOW() + INTERVAL '1 year',
    is_used = false,
    current_uses = 0;

-- إضافة كود تفعيل الجمعية: 826627BO
INSERT INTO public.activation_codes (code, association_id, role, expires_at, max_uses, current_uses)
VALUES (
    '826627BO',
    COALESCE(
        (SELECT id FROM public.users WHERE role = 'association' LIMIT 1),
        uuid_generate_v4()
    ),
    'association',
    NOW() + INTERVAL '1 year',
    1,
    0
)
ON CONFLICT (code) DO UPDATE SET
    expires_at = NOW() + INTERVAL '1 year',
    is_used = false,
    current_uses = 0;

-- ============================================================================
-- التحقق من نجاح العملية
-- ============================================================================

-- عرض أكواد التفعيل المضافة
SELECT 
    code,
    role,
    is_used,
    expires_at,
    created_at,
    'تم إضافة الكود بنجاح' as status
FROM public.activation_codes 
WHERE code IN ('012006001TB', '826627BO')
ORDER BY created_at DESC;

-- عرض القيد الجديد للتأكد
SELECT 
    conname as constraint_name,
    consrc as constraint_definition
FROM pg_constraint 
WHERE conname = 'activation_codes_role_check';

-- ============================================================================
-- نهاية الملف
-- ============================================================================

-- تعليق: تم إصلاح قيد التحقق وإضافة أكواد التفعيل بنجاح
-- الأكواد المضافة:
-- - 012006001TB (كود تفعيل المدير)
-- - 826627BO (كود تفعيل الجمعية)
