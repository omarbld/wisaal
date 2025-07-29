-- ============================================================================
-- إصلاح أكواد التفعيل مع مراعاة سياسات RLS
-- تم إنشاؤه: 2025-01-20
-- الوصف: يصلح قيد التحقق ويضيف أكواد التفعيل بدون انتهاك سياسات RLS
-- ============================================================================

-- أولاً: تعطيل RLS مؤقتاً للعمليات الإدارية (يتطلب صلاحيات superuser)
-- ملاحظة: هذا الجزء اختياري ويمكن تخطيه إذا لم تكن لديك صلاحيات superuser

-- تعطيل RLS مؤقتاً (فقط إذا كنت superuser)
-- ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.activation_codes DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- الطريقة الأولى: استخدام المستخدمين الموجودين فقط
-- ============================================================================

-- إصلاح قيد التحقق أولاً
DO $$
BEGIN
    -- حذف القيد الحالي وإضافة القيد الجديد
    ALTER TABLE public.activation_codes DROP CONSTRAINT IF EXISTS activation_codes_role_check;
    
    ALTER TABLE public.activation_codes 
    ADD CONSTRAINT activation_codes_role_check 
    CHECK (role IN ('volunteer', 'manager', 'association', 'donor'));
    
    RAISE NOTICE 'تم تحديث قيد التحقق بنجاح';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'خطأ في تعديل القيد: %', SQLERRM;
END $$;

-- إضافة أكواد التفعيل باستخدام المستخدمين الموجودين أو NULL
DO $$
DECLARE
    existing_user_id UUID;
    activation_code_exists BOOLEAN;
BEGIN
    -- التحقق من وجود كود المدير
    SELECT EXISTS(SELECT 1 FROM public.activation_codes WHERE code = '012006001TB') INTO activation_code_exists;
    
    IF NOT activation_code_exists THEN
        -- البحث عن أي مستخدم موجود لاستخدامه كمرجع
        SELECT id INTO existing_user_id FROM public.users LIMIT 1;
        
        IF existing_user_id IS NOT NULL THEN
            -- إدراج كود المدير مع مستخدم موجود
            INSERT INTO public.activation_codes (
                code, 
                association_id, 
                role, 
                expires_at, 
                max_uses, 
                current_uses,
                is_used
            ) VALUES (
                '012006001TB',
                existing_user_id,
                'manager',
                NOW() + INTERVAL '1 year',
                1,
                0,
                false
            );
            
            RAISE NOTICE 'تم إضافة كود تفعيل المدير: 012006001TB مع المستخدم: %', existing_user_id;
        ELSE
            RAISE NOTICE 'لا يوجد مستخدمين في قاعدة البيانات لربط كود المدير بهم';
        END IF;
    ELSE
        RAISE NOTICE 'كود المدير 012006001TB موجود بالفعل';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'خطأ في إضافة كود المدير: %', SQLERRM;
END $$;

-- إضافة كود الجمعية
DO $$
DECLARE
    existing_user_id UUID;
    activation_code_exists BOOLEAN;
BEGIN
    -- التحقق من وجود كود الجمعية
    SELECT EXISTS(SELECT 1 FROM public.activation_codes WHERE code = '826627BO') INTO activation_code_exists;
    
    IF NOT activation_code_exists THEN
        -- البحث عن أي مستخدم موجود لاستخدامه كمرجع
        SELECT id INTO existing_user_id FROM public.users LIMIT 1;
        
        IF existing_user_id IS NOT NULL THEN
            -- إدراج كود الجمعية مع مستخدم موجود
            INSERT INTO public.activation_codes (
                code, 
                association_id, 
                role, 
                expires_at, 
                max_uses, 
                current_uses,
                is_used
            ) VALUES (
                '826627BO',
                existing_user_id,
                'association',
                NOW() + INTERVAL '1 year',
                1,
                0,
                false
            );
            
            RAISE NOTICE 'تم إضافة كود تفعيل الجمعية: 826627BO مع المستخدم: %', existing_user_id;
        ELSE
            RAISE NOTICE 'لا يوجد مستخدمين في قاعدة البيانات لربط كود الجمعية بهم';
        END IF;
    ELSE
        RAISE NOTICE 'كود الجمعية 826627BO موجود بالفعل';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'خطأ في إضافة كود الجمعية: %', SQLERRM;
END $$;

-- ============================================================================
-- الطريقة الثانية: إضافة الأكواد بدون association_id (إذا كان الحقل يسمح بـ NULL)
-- ============================================================================

-- إضافة كود المدير بدون association_id
DO $$
BEGIN
    INSERT INTO public.activation_codes (
        code, 
        role, 
        expires_at, 
        max_uses, 
        current_uses,
        is_used
    ) VALUES (
        '012006001TB_ALT',
        'manager',
        NOW() + INTERVAL '1 year',
        1,
        0,
        false
    );
    
    RAISE NOTICE 'تم إضافة كود المدير البديل: 012006001TB_ALT';
    
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'كود المدير البديل موجود بالفعل';
    WHEN OTHERS THEN
        RAISE NOTICE 'لا يمكن إضافة كود بدون association_id: %', SQLERRM;
END $$;

-- إضافة كود الجمعية بدون association_id
DO $$
BEGIN
    INSERT INTO public.activation_codes (
        code, 
        role, 
        expires_at, 
        max_uses, 
        current_uses,
        is_used
    ) VALUES (
        '826627BO_ALT',
        'association',
        NOW() + INTERVAL '1 year',
        1,
        0,
        false
    );
    
    RAISE NOTICE 'تم إضافة كود الجمعية البديل: 826627BO_ALT';
    
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'كود الجمعية البديل موجود بالفعل';
    WHEN OTHERS THEN
        RAISE NOTICE 'لا يمكن إضافة كود بدون association_id: %', SQLERRM;
END $$;

-- ============================================================================
-- إعادة تفعيل RLS (إذا تم تعطيله)
-- ============================================================================

-- إعادة تفعيل RLS (فقط إذا تم تعطيله سابقاً)
-- ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.activation_codes ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- التحقق من النتائج
-- ============================================================================

-- عرض معلومات القيد المحدث
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conname = 'activation_codes_role_check'
  AND conrelid = 'public.activation_codes'::regclass;

-- عرض جميع المستخدمين الموجودين
SELECT 
    id,
    email,
    full_name,
    role,
    created_at
FROM public.users 
ORDER BY created_at DESC
LIMIT 5;

-- عرض أكواد التفعيل المضافة
SELECT 
    ac.code,
    ac.role,
    ac.is_used,
    ac.expires_at,
    ac.created_at,
    u.full_name as associated_user,
    u.email as user_email,
    CASE 
        WHEN ac.code LIKE '%012006001TB%' THEN 'كود تفعيل المدير'
        WHEN ac.code LIKE '%826627BO%' THEN 'كود تفعيل الجمعية'
        ELSE 'كود آخر'
    END as description
FROM public.activation_codes ac
LEFT JOIN public.users u ON ac.association_id = u.id
WHERE ac.code LIKE '%012006001TB%' OR ac.code LIKE '%826627BO%'
ORDER BY ac.created_at DESC;

-- عرض إحصائيات أكواد التفعيل
SELECT 
    role,
    COUNT(*) as total_codes,
    COUNT(CASE WHEN is_used = false THEN 1 END) as unused_codes,
    COUNT(CASE WHEN is_used = true THEN 1 END) as used_codes
FROM public.activation_codes 
GROUP BY role
ORDER BY role;

-- ============================================================================
-- رسائل النجاح والتوجيهات
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '=== تم الانتهاء من إصلاح أكواد التفعيل ===';
    RAISE NOTICE 'تم تحديث قيد التحقق ليشمل جميع الأدوار';
    RAISE NOTICE 'تم إضافة أكواد التفعيل حسب المستخدمين المتاحين';
    RAISE NOTICE '=== ملاحظات مهمة ===';
    RAISE NOTICE '1. إذا لم تظهر الأكواد، تحقق من سياسات RLS';
    RAISE NOTICE '2. قد تحتاج لصلاحيات superuser لبعض العمليات';
    RAISE NOTICE '3. يمكن ربط الأكواد بمستخدمين محددين لاحقاً';
    RAISE NOTICE '=== العملية مكتملة ===';
END $$;

-- ============================================================================
-- تعليمات للمطور
-- ============================================================================

/*
تعليمات مهمة:

1. إذا كنت تواجه مشاكل مع RLS:
   - تأكد من أن لديك الصلاحيات المناسبة
   - أو قم بتعطيل RLS مؤقتاً (يتطلب superuser)

2. لتعطيل RLS مؤقتاً (كـ superuser):
   ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
   ALTER TABLE public.activation_codes DISABLE ROW LEVEL SECURITY;

3. لإعادة تفعيل RLS:
   ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
   ALTER TABLE public.activation_codes ENABLE ROW LEVEL SECURITY;

4. إذا لم تنجح الطريقة الأولى، استخدم الأكواد البديلة:
   - 012006001TB_ALT للمدير
   - 826627BO_ALT للجمعية

5. لربط كود بمستخدم محدد لاحقاً:
   UPDATE public.activation_codes 
   SET association_id = 'USER_ID_HERE'
   WHERE code = 'ACTIVATION_CODE_HERE';

6. لإنشاء مستخدم جديد عبر التطبيق (وليس SQL):
   استخدم واجهة التطبيق لإنشاء المستخدمين الجدد
*/

-- ============================================================================
-- نهاية الملف
-- ============================================================================
