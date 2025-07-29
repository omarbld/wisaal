-- ============================================================================
-- ملف تحديث قاعدة البيانات - إضافة أكواد التفعيل والجداول المفقودة
-- تم إنشاؤه: 2025-01-20
-- الوصف: يضيف الجداول المفقودة وأكواد التفعيل المطلوبة دون التأثير على الجداول الموجودة
-- ============================================================================

-- تفعيل الامتدادات المطلوبة (إذا لم تكن مفعلة)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================================================
-- إنشاء الجداول المفقودة فقط (IF NOT EXISTS)
-- ============================================================================

-- جدول المستخدمين (إذا لم يكن موجوداً)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('donor', 'volunteer', 'association', 'manager')),
    is_active BOOLEAN DEFAULT true,
    profile_image_url TEXT,
    address TEXT,
    city VARCHAR(100),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    date_of_birth DATE,
    gender VARCHAR(10) CHECK (gender IN ('male', 'female')),
    volunteer_hours INTEGER DEFAULT 0,
    total_donations INTEGER DEFAULT 0,
    rating DECIMAL(3, 2) DEFAULT 0.0,
    points INTEGER DEFAULT 0,
    level_id INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE,
    verification_status VARCHAR(20) DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected')),
    association_id UUID REFERENCES public.users(id),
    fcm_token TEXT,
    preferred_language VARCHAR(5) DEFAULT 'ar'
);

-- جدول التبرعات (إذا لم يكن موجوداً)
CREATE TABLE IF NOT EXISTS public.donations (
    donation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    donor_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    volunteer_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    association_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'in_progress', 'completed', 'cancelled')),
    priority VARCHAR(10) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    pickup_address TEXT NOT NULL,
    pickup_latitude DECIMAL(10, 8),
    pickup_longitude DECIMAL(11, 8),
    delivery_address TEXT,
    delivery_latitude DECIMAL(10, 8),
    delivery_longitude DECIMAL(11, 8),
    pickup_time TIMESTAMP WITH TIME ZONE,
    delivery_time TIMESTAMP WITH TIME ZONE,
    expiry_date TIMESTAMP WITH TIME ZONE,
    images TEXT[],
    special_instructions TEXT,
    estimated_weight DECIMAL(8, 2),
    estimated_value DECIMAL(10, 2),
    qr_code TEXT UNIQUE,
    tracking_number VARCHAR(50) UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    cancelled_reason TEXT,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    feedback TEXT
);

-- جدول الإشعارات (إذا لم يكن موجوداً)
CREATE TABLE IF NOT EXISTS public.notifications (
    notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    is_read BOOLEAN DEFAULT false,
    data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE
);

-- جدول التقييمات (إذا لم يكن موجوداً)
CREATE TABLE IF NOT EXISTS public.ratings (
    rating_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    donation_id UUID NOT NULL REFERENCES public.donations(donation_id) ON DELETE CASCADE,
    rater_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    rated_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(donation_id, rater_id, rated_id)
);

-- جدول المخزون (إذا لم يكن موجوداً)
CREATE TABLE IF NOT EXISTS public.inventory (
    inventory_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    association_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    item_name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 0,
    unit VARCHAR(50) NOT NULL,
    expiry_date DATE,
    location VARCHAR(255),
    minimum_threshold INTEGER DEFAULT 0,
    cost_per_unit DECIMAL(10, 2),
    supplier VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- جدول أكواد التفعيل (إذا لم يكن موجوداً)
CREATE TABLE IF NOT EXISTS public.activation_codes (
    code_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(20) UNIQUE NOT NULL,
    association_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL CHECK (role IN ('volunteer', 'manager', 'association')),
    is_used BOOLEAN DEFAULT false,
    used_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    used_at TIMESTAMP WITH TIME ZONE,
    max_uses INTEGER DEFAULT 1,
    current_uses INTEGER DEFAULT 0
);

-- جدول النقاط والمستويات (إذا لم يكن موجوداً)
CREATE TABLE IF NOT EXISTS public.user_points (
    point_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    points INTEGER NOT NULL,
    reason VARCHAR(255) NOT NULL,
    donation_id UUID REFERENCES public.donations(donation_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- جدول الشارات (إذا لم يكن موجوداً)
CREATE TABLE IF NOT EXISTS public.badges (
    badge_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    icon_url TEXT,
    requirement_type VARCHAR(50) NOT NULL,
    requirement_value INTEGER NOT NULL,
    points_reward INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- جدول شارات المستخدمين (إذا لم يكن موجوداً)
CREATE TABLE IF NOT EXISTS public.user_badges (
    user_badge_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    badge_id UUID NOT NULL REFERENCES public.badges(badge_id) ON DELETE CASCADE,
    earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, badge_id)
);

-- جدول المهام (إذا لم يكن موجوداً)
CREATE TABLE IF NOT EXISTS public.tasks (
    task_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    donation_id UUID NOT NULL REFERENCES public.donations(donation_id) ON DELETE CASCADE,
    volunteer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    priority VARCHAR(10) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    estimated_hours DECIMAL(4, 2),
    actual_hours DECIMAL(4, 2),
    due_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- جدول سجل المواقع (إذا لم يكن موجوداً)
CREATE TABLE IF NOT EXISTS public.location_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    accuracy DECIMAL(8, 2),
    activity_type VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- جدول التقارير (إذا لم يكن موجوداً)
CREATE TABLE IF NOT EXISTS public.reports (
    report_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    reported_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    donation_id UUID REFERENCES public.donations(donation_id) ON DELETE SET NULL,
    type VARCHAR(50) NOT NULL,
    reason TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'investigating', 'resolved', 'dismissed')),
    admin_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- جدول الرسائل (إذا لم يكن موجوداً)
CREATE TABLE IF NOT EXISTS public.messages (
    message_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    donation_id UUID REFERENCES public.donations(donation_id) ON DELETE SET NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE
);

-- ============================================================================
-- إنشاء الفهارس (إذا لم تكن موجودة)
-- ============================================================================

-- فهارس جدول المستخدمين
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON public.users(phone);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON public.users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_association_id ON public.users(association_id);
CREATE INDEX IF NOT EXISTS idx_users_location ON public.users(latitude, longitude);

-- فهارس جدول التبرعات
CREATE INDEX IF NOT EXISTS idx_donations_donor_id ON public.donations(donor_id);
CREATE INDEX IF NOT EXISTS idx_donations_volunteer_id ON public.donations(volunteer_id);
CREATE INDEX IF NOT EXISTS idx_donations_association_id ON public.donations(association_id);
CREATE INDEX IF NOT EXISTS idx_donations_status ON public.donations(status);
CREATE INDEX IF NOT EXISTS idx_donations_category ON public.donations(category);
CREATE INDEX IF NOT EXISTS idx_donations_priority ON public.donations(priority);
CREATE INDEX IF NOT EXISTS idx_donations_created_at ON public.donations(created_at);
CREATE INDEX IF NOT EXISTS idx_donations_pickup_location ON public.donations(pickup_latitude, pickup_longitude);

-- فهارس جدول الإشعارات
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at);

-- ============================================================================
-- إضافة أكواد التفعيل المطلوبة
-- ============================================================================

-- إضافة كود تفعيل المدير: 012006001TB
INSERT INTO public.activation_codes (code, association_id, role, expires_at, max_uses, current_uses)
VALUES (
    '012006001TB',
    (SELECT id FROM public.users WHERE role = 'manager' LIMIT 1),
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
    (SELECT id FROM public.users WHERE role = 'association' LIMIT 1),
    'association',
    NOW() + INTERVAL '1 year',
    1,
    0
)
ON CONFLICT (code) DO UPDATE SET
    expires_at = NOW() + INTERVAL '1 year',
    is_used = false,
    current_uses = 0;

-- إضافة أكواد التفعيل البديلة (في حالة عدم وجود مستخدمين)
-- سيتم تحديث association_id لاحقاً عند إنشاء المستخدمين
DO $$
BEGIN
    -- إضافة كود المدير إذا لم يكن موجوداً
    IF NOT EXISTS (SELECT 1 FROM public.activation_codes WHERE code = '012006001TB') THEN
        INSERT INTO public.activation_codes (code, association_id, role, expires_at, max_uses, current_uses)
        VALUES ('012006001TB', uuid_generate_v4(), 'manager', NOW() + INTERVAL '1 year', 1, 0);
    END IF;
    
    -- إضافة كود الجمعية إذا لم يكن موجوداً
    IF NOT EXISTS (SELECT 1 FROM public.activation_codes WHERE code = '826627BO') THEN
        INSERT INTO public.activation_codes (code, association_id, role, expires_at, max_uses, current_uses)
        VALUES ('826627BO', uuid_generate_v4(), 'association', NOW() + INTERVAL '1 year', 1, 0);
    END IF;
END $$;

-- ============================================================================
-- تفعيل RLS على الجداول (إذا لم يكن مفعلاً)
-- ============================================================================

DO $$
BEGIN
    -- تفعيل RLS على جميع الجداول
    ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.donations ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.activation_codes ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.user_points ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.location_logs ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
EXCEPTION
    WHEN OTHERS THEN
        -- تجاهل الأخطاء إذا كان RLS مفعلاً بالفعل
        NULL;
END $$;

-- ============================================================================
-- إضافة السياسات الأساسية (إذا لم تكن موجودة)
-- ============================================================================

-- سياسات جدول المستخدمين
DO $$
BEGIN
    -- المدراء يمكنهم رؤية جميع المستخدمين
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'users' AND policyname = 'managers_can_view_all_users') THEN
        CREATE POLICY "managers_can_view_all_users" ON public.users
            FOR SELECT USING (
                EXISTS (
                    SELECT 1 FROM public.users 
                    WHERE id = auth.uid() AND role = 'manager'
                )
            );
    END IF;

    -- المستخدمون يمكنهم رؤية ملفهم الشخصي
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'users' AND policyname = 'users_can_view_own_profile') THEN
        CREATE POLICY "users_can_view_own_profile" ON public.users
            FOR SELECT USING (auth.uid() = id);
    END IF;

    -- المستخدمون يمكنهم تحديث ملفهم الشخصي
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'users' AND policyname = 'users_can_update_own_profile') THEN
        CREATE POLICY "users_can_update_own_profile" ON public.users
            FOR UPDATE USING (auth.uid() = id);
    END IF;
END $$;

-- سياسات جدول أكواد التفعيل
DO $$
BEGIN
    -- الجمعيات يمكنها إدارة أكواد التفعيل الخاصة بها
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'activation_codes' AND policyname = 'associations_can_manage_activation_codes') THEN
        CREATE POLICY "associations_can_manage_activation_codes" ON public.activation_codes
            FOR ALL USING (association_id = auth.uid());
    END IF;

    -- المدراء يمكنهم رؤية جميع أكواد التفعيل
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'activation_codes' AND policyname = 'managers_can_view_all_activation_codes') THEN
        CREATE POLICY "managers_can_view_all_activation_codes" ON public.activation_codes
            FOR SELECT USING (
                EXISTS (
                    SELECT 1 FROM public.users 
                    WHERE id = auth.uid() AND role = 'manager'
                )
            );
    END IF;
END $$;

-- ============================================================================
-- إدراج البيانات الأولية (إذا لم تكن موجودة)
-- ============================================================================

-- إدراج الشارات الأساسية
INSERT INTO public.badges (name, description, requirement_type, requirement_value, points_reward) 
VALUES
    ('متطوع جديد', 'أول تبرع يتم قبوله', 'donations_completed', 1, 10),
    ('متطوع نشط', 'إكمال 5 تبرعات', 'donations_completed', 5, 25),
    ('متطوع محترف', 'إكمال 20 تبرع', 'donations_completed', 20, 100),
    ('متطوع خبير', 'إكمال 50 تبرع', 'donations_completed', 50, 250),
    ('متطوع أسطوري', 'إكمال 100 تبرع', 'donations_completed', 100, 500),
    ('مساعد سريع', 'إكمال تبرع في أقل من ساعة', 'quick_completion', 1, 50),
    ('نجم التقييم', 'الحصول على تقييم 5 نجوم', 'five_star_rating', 1, 30),
    ('متبرع كريم', 'إنشاء 10 تبرعات', 'donations_created', 10, 75)
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- التحقق من نجاح العملية
-- ============================================================================

-- عرض أكواد التفعيل المضافة
SELECT 
    code,
    role,
    is_used,
    expires_at,
    created_at
FROM public.activation_codes 
WHERE code IN ('012006001TB', '826627BO')
ORDER BY created_at DESC;

-- ============================================================================
-- نهاية الملف
-- ============================================================================

-- تعليق: تم تحديث قاعدة البيانات بنجاح مع إضافة أكواد التفعيل المطلوبة
-- الأكواد المضافة:
-- - 012006001TB (كود تفعيل المدير)
-- - 826627BO (كود تفعيل الجمعية)
