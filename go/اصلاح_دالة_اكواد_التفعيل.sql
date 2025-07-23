-- إصلاح خطأ PostgrestException: مرجع العمود "code" غامض
-- هذا الملف يحل مشكلة تضارب أسماء الأعمدة في دالة generate_activation_code_enhanced

-- حذف الدالة المعطلة أولاً مع تحديد نوع المعاملات بدقة
DROP FUNCTION IF EXISTS generate_activation_code_enhanced(uuid, integer);

-- إنشاء الدالة المصححة
CREATE OR REPLACE FUNCTION generate_activation_code_enhanced(
  p_association_id uuid,
  p_count integer DEFAULT 1
)
RETURNS TABLE(generated_code text, created_at timestamptz) AS $
DECLARE
  i integer;
  new_code text;
  created_time timestamptz;
BEGIN
  FOR i IN 1..p_count LOOP
    -- إنشاء كود عشوائي من 8 أحرف
    new_code := upper(substring(md5(random()::text || clock_timestamp()::text) from 1 for 8));
    
    -- التأكد من عدم التكرار بتحديد اسم الجدول والعمود بوضوح
    WHILE EXISTS (SELECT 1 FROM public.activation_codes WHERE activation_codes.code = new_code) LOOP
      new_code := upper(substring(md5(random()::text || clock_timestamp()::text) from 1 for 8));
    END LOOP;
    
    -- إدراج الكود في قاعدة البيانات
    INSERT INTO public.activation_codes (
      code,
      role,
      created_by_association_id,
      created_at
    ) VALUES (
      new_code,
      'volunteer',
      p_association_id,
      now()
    ) RETURNING activation_codes.created_at INTO created_time;
    
    -- إرجاع القيم باستخدام أسماء أعمدة الإرجاع
    generated_code := new_code;
    created_at := created_time;
    RETURN NEXT;
  END LOOP;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- منح صلاحية التنفيذ
GRANT EXECUTE ON FUNCTION generate_activation_code_enhanced(uuid, integer) TO authenticated;

-- رسالة تأكيد
DO $
BEGIN
  RAISE NOTICE 'تم إصلاح دالة إنشاء أكواد التفعيل بنجاح!';
  RAISE NOTICE 'الآن يمكن استخدام الدالة بدون خطأ "code is ambiguous"';
END $;