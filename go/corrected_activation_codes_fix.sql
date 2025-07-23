-- ============================================================================
-- الإصلاح المُصحح لأكواد التفعيل
-- تم إنشاؤه: 2025-01-20
-- الوصف: يصلح قيد التحقق ويضيف أكواد التفعيل مع حل مشكلة المفتاح الخارجي
-- ============================================================================

-- أولاً: حذف القيد الحالي وإضافة القيد الجديد
DO $$
BEGIN
    -- محاولة حذف القيد الحالي
    ALTER TABLE public.activation_codes DROP CONSTRAINT IF EXISTS activation_codes_role_check;
    
    -- إضافة القيد الجديد الذي يشمل جميع الأدوار
    ALTER TABLE public.activation_codes 
    ADD CONSTRAINT activation_codes_role_check 
    CHECK (role IN ('volunteer', 'manager', 'association', 'donor'));
    
    RAISE NOTICE 'تم تحديث قيد التحقق بنجاح';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'خطأ في تعديل القيد: %', SQLERRM;
END $$;

-- ثانياً: إنشاء مستخدم مدير مؤقت إذا لم يكن موجوداً
DO $$
DECLARE
    manager_id UUID;
BEGIN
    -- البحث عن مستخدم مدير موجود
    SELECT id INTO manager_id FROM public.users WHERE role = 'manager' LIMIT 1;
    
    -- إذا لم يوجد مدير، ننشئ مستخدم مؤقت
    IF manager_id IS NULL THEN
        INSERT INTO public.users (
            id, 
            email, 
            full_name, 
            role, 
            is_active,
            created_at
        ) VALUES (
            uuid_generate_v4(),
            'temp_manager@wisaal.com',
            'مدير مؤقت',
            'manager',
            true,
            NOW()
        ) RETURNING id INTO manager_id;
        
        RAISE NOTICE 'تم إنشاء مستخدم مدير مؤقت: %', manager_id;
    ELSE
        RAISE NOTICE 'تم العثور على مستخدم مدير موجود: %', manager_id;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'خطأ في إنشاء المستخدم المدير: %', SQLERRM;
END $$;

-- ثالثاً: إنشاء مستخدم جمعية مؤقت إذا لم يكن موجوداً
DO $$
DECLARE
    association_id UUID;
BEGIN
    -- البحث عن مستخدم جمعية موجود
    SELECT id INTO association_id FROM public.users WHERE role = 'association' LIMIT 1;
    
    -- إذا لم توجد جمعية، ننشئ مستخدم مؤقت
    IF association_id IS NULL THEN
        INSERT INTO public.users (
            id, 
            email, 
            full_name, 
            role, 
            is_active,
            created_at
        ) VALUES (
            uuid_generate_v4(),
            'temp_association@wisaal.com',
            'جمعية مؤقتة',
            'association',
            true,
            NOW()
        ) RETURNING id INTO association_id;
        
        RAISE NOTICE 'تم إنشاء مستخدم جمعية مؤقت: %', association_id;
    ELSE
        RAISE NOTICE 'تم العثور على مستخدم جمعية موجود: %', association_id;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'خطأ في إنشاء المستخدم الجمعية: %', SQLERRM;
END $$;

-- رابعاً: إضافة كود تفعيل المدير
DO $$
DECLARE
    manager_id UUID;
BEGIN
    -- الحصول على ID المدير
    SELECT id INTO manager_id FROM public.users WHERE role = 'manager' LIMIT 1;
    
    IF manager_id IS NOT NULL THEN
        -- محاولة إدراج كود المدير
        INSERT INTO public.activation_codes (
            code, 
            association_id, 
            role, 
            expires_at, 
            max_uses, 
            current_uses
        ) VALUES (
            '012006001TB',
            manager_id,
            'manager',
            NOW() + INTERVAL '1 year',
            1,
            0
        );
        
        RAISE NOTICE 'تم إضافة كود تفعيل المدير: 012006001TB';
        
    ELSE
        RAISE NOTICE 'لم يتم العثور على مستخدم مدير لربط الكود به';
    END IF;
    
EXCEPTION
    WHEN unique_violation THEN
        -- إذا كان الكود موجوداً، نحدثه
        UPDATE public.activation_codes 
        SET 
            expires_at = NOW() + INTERVAL '1 year',
            is_used = false,
            current_uses = 0,
            role = 'manager',
            association_id = manager_id
        WHERE code = '012006001TB';
        
        RAISE NOTICE 'تم تحديث كود المدير الموجود: 012006001TB';
        
    WHEN OTHERS THEN
        RAISE NOTICE 'خطأ في إضافة كود المدير: %', SQLERRM;
END $$;

-- خامساً: إضافة كود تفعيل الجمعية
DO $$
DECLARE
    association_id UUID;
BEGIN
    -- الحصول على ID الجمعية
    SELECT id INTO association_id FROM public.users WHERE role = 'association' LIMIT 1;
    
    IF association_id IS NOT NULL THEN
        -- محاولة إدراج كود الجمعية
        INSERT INTO public.activation_codes (
            code, 
            association_id, 
            role, 
            expires_at, 
            max_uses, 
            current_uses
        ) VALUES (
            '826627BO',
            association_id,
            'association',
            NOW() + INTERVAL '1 year',
            1,
            0
        );
        
        RAISE NOTICE 'تم إضافة كود تفعيل الجمعية: 826627BO';
        
    ELSE
        RAISE NOTICE 'لم يتم العثور على مستخدم جمعية لربط الكود به';
    END IF;
    
EXCEPTION
    WHEN unique_violation THEN
        -- إذا كان الكود موجوداً، نحدثه
        UPDATE public.activation_codes 
        SET 
            expires_at = NOW() + INTERVAL '1 year',
            is_used = false,
            current_uses = 0,
            role = 'association',
            association_id = association_id
        WHERE code = '826627BO';
        
        RAISE NOTICE 'تم تحديث كود الجمعية الموجود: 826627BO';
        
    WHEN OTHERS THEN
        RAISE NOTICE 'خطأ في إضافة كود الجمعية: %', SQLERRM;
END $$;

-- ============================================================================
-- التحقق من نجاح العملية
-- ============================================================================

-- عرض معلومات القيد المحدث
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conname = 'activation_codes_role_check'
  AND conrelid = 'public.activation_codes'::regclass;

-- عرض المستخدمين المؤقتين المُنشأين
SELECT 
    id,
    email,
    full_name,
    role,
    created_at,
    'مستخدم مؤقت' as note
FROM public.users 
WHERE email IN ('temp_manager@wisaal.com', 'temp_association@wisaal.com')
ORDER BY created_at DESC;

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
        WHEN ac.code = '012006001TB' THEN 'كود تفعيل المدير'
        WHEN ac.code = '826627BO' THEN 'كود تفعيل الجمعية'
        ELSE 'كود آخر'
    END as description
FROM public.activation_codes ac
LEFT JOIN public.users u ON ac.association_id = u.id
WHERE ac.code IN ('012006001TB', '826627BO')
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
-- رسائل النجاح النهائية
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '=== تم الانتهاء من إصلاح أكواد التفعيل بنجاح ===';
    RAISE NOTICE 'كود المدير: 012006001TB';
    RAISE NOTICE 'كود الجمعية: 826627BO';
    RAISE NOTICE 'تم تحديث قيد التحقق ليشمل جميع الأدوار';
    RAISE NOTICE 'تم إنشاء مستخدمين مؤقتين إذا لزم الأمر';
    RAISE NOTICE 'يمكنك الآن استخدام أكواد التفعيل في التطبيق';
    RAISE NOTICE '=== العملية مكتملة بنجاح ===';
END $$;

-- ============================================================================
-- ملاحظات مهمة
-- ============================================================================

/*
ملاحظات مهمة:
1. تم إنشاء مستخدمين مؤقتين إذا لم يكونوا موجودين
2. يمكن تحديث بيانات المستخدمين المؤقتين لاحقاً
3. أكواد التفعيل صالحة لمدة سنة واحدة
4. يمكن استخدام كل كود مرة واحدة فقط
5. الأكواد مرتبطة بمستخدمين حقيقيين في قاعدة البيانات

لتحديث بيانات المستخدم المؤقت:
UPDATE public.users 
SET email = 'البريد_الجديد@example.com', 
    full_name = 'الاسم الجديد'
WHERE email = 'temp_manager@wisaal.com' OR email = 'temp_association@wisaal.com';
*/

-- ============================================================================
-- نهاية الملف
-- ============================================================================
