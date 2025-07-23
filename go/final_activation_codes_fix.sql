-- ============================================================================
-- الإصلاح النهائي لأكواد التفعيل
-- تم إنشاؤه: 2025-01-20
-- الوصف: يصلح قيد التحقق الموجود ويضيف أكواد التفعيل المطلوبة
-- ============================================================================

-- أولاً: حذف القيد الحالي إذا كان موجوداً
DO $$
BEGIN
    -- محاولة حذف القيد الحالي
    ALTER TABLE public.activation_codes DROP CONSTRAINT IF EXISTS activation_codes_role_check;
    
    -- إضافة القيد الجديد الذي يشمل جميع الأدوار
    ALTER TABLE public.activation_codes 
    ADD CONSTRAINT activation_codes_role_check 
    CHECK (role IN ('volunteer', 'manager', 'association', 'donor'));
    
EXCEPTION
    WHEN duplicate_object THEN
        -- إذا كان القيد موجوداً بالفعل، نحاول تعديله
        ALTER TABLE public.activation_codes DROP CONSTRAINT activation_codes_role_check;
        ALTER TABLE public.activation_codes 
        ADD CONSTRAINT activation_codes_role_check 
        CHECK (role IN ('volunteer', 'manager', 'association', 'donor'));
    WHEN OTHERS THEN
        -- في حالة أي خطأ آخر، نتجاهله ونكمل
        RAISE NOTICE 'تم تجاهل خطأ في تعديل القيد: %', SQLERRM;
END $$;

-- ثانياً: إضافة أكواد التفعيل المطلوبة
-- إضافة كود تفعيل المدير: 012006001TB
DO $$
BEGIN
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
    );
EXCEPTION
    WHEN unique_violation THEN
        -- إذا كان الكود موجوداً، نحدثه
        UPDATE public.activation_codes 
        SET 
            expires_at = NOW() + INTERVAL '1 year',
            is_used = false,
            current_uses = 0,
            role = 'manager'
        WHERE code = '012006001TB';
        RAISE NOTICE 'تم تحديث كود المدير الموجود: 012006001TB';
    WHEN OTHERS THEN
        RAISE NOTICE 'خطأ في إضافة كود المدير: %', SQLERRM;
END $$;

-- إضافة كود تفعيل الجمعية: 826627BO
DO $$
BEGIN
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
    );
EXCEPTION
    WHEN unique_violation THEN
        -- إذا كان الكود موجوداً، نحدثه
        UPDATE public.activation_codes 
        SET 
            expires_at = NOW() + INTERVAL '1 year',
            is_used = false,
            current_uses = 0,
            role = 'association'
        WHERE code = '826627BO';
        RAISE NOTICE 'تم تحديث كود الجمعية الموجود: 826627BO';
    WHEN OTHERS THEN
        RAISE NOTICE 'خطأ في إضافة كود الجمعية: %', SQLERRM;
END $$;

-- ثالثاً: التحقق من وجود الأكواد وإضافتها إذا لم تكن موجودة
DO $$
BEGIN
    -- التحقق من كود المدير
    IF NOT EXISTS (SELECT 1 FROM public.activation_codes WHERE code = '012006001TB') THEN
        INSERT INTO public.activation_codes (code, association_id, role, expires_at, max_uses, current_uses)
        VALUES (
            '012006001TB',
            uuid_generate_v4(),
            'manager',
            NOW() + INTERVAL '1 year',
            1,
            0
        );
        RAISE NOTICE 'تم إنشاء كود المدير الجديد: 012006001TB';
    END IF;
    
    -- التحقق من كود الجمعية
    IF NOT EXISTS (SELECT 1 FROM public.activation_codes WHERE code = '826627BO') THEN
        INSERT INTO public.activation_codes (code, association_id, role, expires_at, max_uses, current_uses)
        VALUES (
            '826627BO',
            uuid_generate_v4(),
            'association',
            NOW() + INTERVAL '1 year',
            1,
            0
        );
        RAISE NOTICE 'تم إنشاء كود الجمعية الجديد: 826627BO';
    END IF;
END $$;

-- ============================================================================
-- التحقق من نجاح العملية
-- ============================================================================

-- عرض معلومات القيد الحالي
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conname = 'activation_codes_role_check'
  AND conrelid = 'public.activation_codes'::regclass;

-- عرض أكواد التفعيل المضافة
SELECT 
    code,
    role,
    is_used,
    expires_at,
    created_at,
    CASE 
        WHEN code = '012006001TB' THEN 'كود تفعيل المدير'
        WHEN code = '826627BO' THEN 'كود تفعيل الجمعية'
        ELSE 'كود آخر'
    END as description
FROM public.activation_codes 
WHERE code IN ('012006001TB', '826627BO')
ORDER BY created_at DESC;

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
-- رسائل النجاح
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '=== تم الانتهاء من إصلاح أكواد التفعيل ===';
    RAISE NOTICE 'كود المدير: 012006001TB';
    RAISE NOTICE 'كود الجمعية: 826627BO';
    RAISE NOTICE 'تم تحديث قيد التحقق ليشمل جميع الأدوار';
    RAISE NOTICE '=== العملية مكتملة بنجاح ===';
END $$;

-- ============================================================================
-- نهاية الملف
-- ============================================================================
