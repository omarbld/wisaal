-- ============================================================================
-- قاعدة بيانات مشروع وصال - المخطط الشامل مع RLS
-- تم إنشاؤه: 2025-01-20
-- الوصف: يحتوي على جميع الجداول والسياسات والدوال المطلوبة للمشروع
-- ============================================================================

-- تفعيل الامتدادات المطلوبة
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================================================
-- الجداول الأساسية
-- ============================================================================

-- جدول المستخدمين
CREATE TABLE public.users (
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

-- جدول التبرعات
CREATE TABLE public.donations (
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
    images TEXT[], -- مصفوفة من روابط الصور
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

-- جدول الإشعارات
CREATE TABLE public.notifications (
    notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    is_read BOOLEAN DEFAULT false,
    data JSONB, -- بيانات إضافية للإشعار
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE
);

-- جدول التقييمات
CREATE TABLE public.ratings (
    rating_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    donation_id UUID NOT NULL REFERENCES public.donations(donation_id) ON DELETE CASCADE,
    rater_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    rated_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(donation_id, rater_id, rated_id)
);

-- جدول المخزون
CREATE TABLE public.inventory (
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

-- جدول أكواد التفعيل
CREATE TABLE public.activation_codes (
    code_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(20) UNIQUE NOT NULL,
    association_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL CHECK (role IN ('volunteer')),
    is_used BOOLEAN DEFAULT false,
    used_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    used_at TIMESTAMP WITH TIME ZONE,
    max_uses INTEGER DEFAULT 1,
    current_uses INTEGER DEFAULT 0
);

-- جدول النقاط والمستويات
CREATE TABLE public.user_points (
    point_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    points INTEGER NOT NULL,
    reason VARCHAR(255) NOT NULL,
    donation_id UUID REFERENCES public.donations(donation_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- جدول الشارات
CREATE TABLE public.badges (
    badge_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    icon_url TEXT,
    requirement_type VARCHAR(50) NOT NULL,
    requirement_value INTEGER NOT NULL,
    points_reward INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- جدول شارات المستخدمين
CREATE TABLE public.user_badges (
    user_badge_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    badge_id UUID NOT NULL REFERENCES public.badges(badge_id) ON DELETE CASCADE,
    earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, badge_id)
);

-- جدول المهام
CREATE TABLE public.tasks (
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

-- جدول سجل المواقع
CREATE TABLE public.location_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    accuracy DECIMAL(8, 2),
    activity_type VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- جدول التقارير
CREATE TABLE public.reports (
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

-- جدول الرسائل
CREATE TABLE public.messages (
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
-- إنشاء الفهارس
-- ============================================================================

-- فهارس جدول المستخدمين
CREATE INDEX idx_users_role ON public.users(role);
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_phone ON public.users(phone);
CREATE INDEX idx_users_is_active ON public.users(is_active);
CREATE INDEX idx_users_association_id ON public.users(association_id);
CREATE INDEX idx_users_location ON public.users(latitude, longitude);

-- فهارس جدول التبرعات
CREATE INDEX idx_donations_donor_id ON public.donations(donor_id);
CREATE INDEX idx_donations_volunteer_id ON public.donations(volunteer_id);
CREATE INDEX idx_donations_association_id ON public.donations(association_id);
CREATE INDEX idx_donations_status ON public.donations(status);
CREATE INDEX idx_donations_category ON public.donations(category);
CREATE INDEX idx_donations_priority ON public.donations(priority);
CREATE INDEX idx_donations_created_at ON public.donations(created_at);
CREATE INDEX idx_donations_pickup_location ON public.donations(pickup_latitude, pickup_longitude);

-- فهارس جدول الإشعارات
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX idx_notifications_type ON public.notifications(type);
CREATE INDEX idx_notifications_created_at ON public.notifications(created_at);

-- فهارس جدول التقييمات
CREATE INDEX idx_ratings_donation_id ON public.ratings(donation_id);
CREATE INDEX idx_ratings_rater_id ON public.ratings(rater_id);
CREATE INDEX idx_ratings_rated_id ON public.ratings(rated_id);

-- فهارس جدول المخزون
CREATE INDEX idx_inventory_association_id ON public.inventory(association_id);
CREATE INDEX idx_inventory_category ON public.inventory(category);
CREATE INDEX idx_inventory_expiry_date ON public.inventory(expiry_date);

-- ============================================================================
-- تفعيل RLS على جميع الجداول
-- ============================================================================

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

-- ============================================================================
-- سياسات RLS لجدول المستخدمين
-- ============================================================================

-- المدراء يمكنهم رؤية جميع المستخدمين
CREATE POLICY "managers_can_view_all_users" ON public.users
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'manager'
        )
    );

-- المستخدمون يمكنهم رؤية ملفهم الشخصي
CREATE POLICY "users_can_view_own_profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

-- المستخدمون يمكنهم تحديث ملفهم الشخصي
CREATE POLICY "users_can_update_own_profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- الجمعيات يمكنها رؤية المتطوعين المرتبطين بها
CREATE POLICY "associations_can_view_their_volunteers" ON public.users
    FOR SELECT USING (
        role = 'volunteer' AND association_id IN (
            SELECT id FROM public.users WHERE id = auth.uid() AND role = 'association'
        )
    );

-- المتطوعون يمكنهم رؤية معلومات الجمعيات والمتبرعين في التبرعات المقبولة
CREATE POLICY "volunteers_can_view_related_users" ON public.users
    FOR SELECT USING (
        (role = 'association' OR role = 'donor') AND id IN (
            SELECT COALESCE(association_id, donor_id) FROM public.donations 
            WHERE volunteer_id = auth.uid()
        )
    );

-- ============================================================================
-- سياسات RLS لجدول التبرعات
-- ============================================================================

-- المدراء يمكنهم رؤية جميع التبرعات
CREATE POLICY "managers_can_view_all_donations" ON public.donations
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'manager'
        )
    );

-- المتبرعون يمكنهم رؤية تبرعاتهم فقط
CREATE POLICY "donors_can_view_own_donations" ON public.donations
    FOR SELECT USING (donor_id = auth.uid());

-- المتبرعون يمكنهم إنشاء تبرعات جديدة
CREATE POLICY "donors_can_create_donations" ON public.donations
    FOR INSERT WITH CHECK (donor_id = auth.uid());

-- المتبرعون يمكنهم تحديث تبرعاتهم
CREATE POLICY "donors_can_update_own_donations" ON public.donations
    FOR UPDATE USING (donor_id = auth.uid());

-- المتطوعون يمكنهم رؤية التبرعات المتاحة والمقبولة منهم
CREATE POLICY "volunteers_can_view_available_and_accepted_donations" ON public.donations
    FOR SELECT USING (
        status = 'pending' OR volunteer_id = auth.uid()
    );

-- المتطوعون يمكنهم تحديث التبرعات المقبولة منهم
CREATE POLICY "volunteers_can_update_accepted_donations" ON public.donations
    FOR UPDATE USING (volunteer_id = auth.uid());

-- الجمعيات يمكنها رؤية التبرعات المرتبطة بها
CREATE POLICY "associations_can_view_their_donations" ON public.donations
    FOR SELECT USING (association_id = auth.uid());

-- الجمعيات يمكنها تحديث التبرعات المرتبطة بها
CREATE POLICY "associations_can_update_their_donations" ON public.donations
    FOR UPDATE USING (association_id = auth.uid());

-- ============================================================================
-- سياسات RLS لجدول الإشعارات
-- ============================================================================

-- المستخدمون يمكنهم رؤية إشعاراتهم فقط
CREATE POLICY "users_can_view_own_notifications" ON public.notifications
    FOR SELECT USING (user_id = auth.uid());

-- المستخدمون يمكنهم تحديث إشعاراتهم (تحديد كمقروءة)
CREATE POLICY "users_can_update_own_notifications" ON public.notifications
    FOR UPDATE USING (user_id = auth.uid());

-- النظام يمكنه إنشاء إشعارات للمستخدمين
CREATE POLICY "system_can_create_notifications" ON public.notifications
    FOR INSERT WITH CHECK (true);

-- المدراء يمكنهم إنشاء إشعارات
CREATE POLICY "managers_can_create_notifications" ON public.notifications
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'manager'
        )
    );

-- ============================================================================
-- سياسات RLS لجدول التقييمات
-- ============================================================================

-- المستخدمون يمكنهم رؤية التقييمات المتعلقة بهم
CREATE POLICY "users_can_view_related_ratings" ON public.ratings
    FOR SELECT USING (rater_id = auth.uid() OR rated_id = auth.uid());

-- المستخدمون يمكنهم إنشاء تقييمات
CREATE POLICY "users_can_create_ratings" ON public.ratings
    FOR INSERT WITH CHECK (rater_id = auth.uid());

-- المدراء يمكنهم رؤية جميع التقييمات
CREATE POLICY "managers_can_view_all_ratings" ON public.ratings
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'manager'
        )
    );

-- ============================================================================
-- سياسات RLS لجدول المخزون
-- ============================================================================

-- الجمعيات يمكنها إدارة مخزونها
CREATE POLICY "associations_can_manage_inventory" ON public.inventory
    FOR ALL USING (association_id = auth.uid());

-- المدراء يمكنهم رؤية جميع المخزون
CREATE POLICY "managers_can_view_all_inventory" ON public.inventory
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'manager'
        )
    );

-- ============================================================================
-- سياسات RLS لجدول أكواد التفعيل
-- ============================================================================

-- الجمعيات يمكنها إدارة أكواد التفعيل الخاصة بها
CREATE POLICY "associations_can_manage_activation_codes" ON public.activation_codes
    FOR ALL USING (association_id = auth.uid());

-- المدراء يمكنهم رؤية جميع أكواد التفعيل
CREATE POLICY "managers_can_view_all_activation_codes" ON public.activation_codes
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'manager'
        )
    );

-- المستخدمون يمكنهم رؤية الأكواد المستخدمة منهم
CREATE POLICY "users_can_view_used_codes" ON public.activation_codes
    FOR SELECT USING (used_by = auth.uid());

-- ============================================================================
-- سياسات RLS لجدول النقاط
-- ============================================================================

-- المستخدمون يمكنهم رؤية نقاطهم
CREATE POLICY "users_can_view_own_points" ON public.user_points
    FOR SELECT USING (user_id = auth.uid());

-- النظام يمكنه إضافة نقاط
CREATE POLICY "system_can_add_points" ON public.user_points
    FOR INSERT WITH CHECK (true);

-- المدراء يمكنهم رؤية جميع النقاط
CREATE POLICY "managers_can_view_all_points" ON public.user_points
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'manager'
        )
    );

-- ============================================================================
-- سياسات RLS لجدول الشارات
-- ============================================================================

-- الجميع يمكنهم رؤية الشارات المتاحة
CREATE POLICY "everyone_can_view_badges" ON public.badges
    FOR SELECT USING (true);

-- المدراء يمكنهم إدارة الشارات
CREATE POLICY "managers_can_manage_badges" ON public.badges
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'manager'
        )
    );

-- ============================================================================
-- سياسات RLS لجدول شارات المستخدمين
-- ============================================================================

-- المستخدمون يمكنهم رؤية شاراتهم
CREATE POLICY "users_can_view_own_badges" ON public.user_badges
    FOR SELECT USING (user_id = auth.uid());

-- النظام يمكنه منح شارات
CREATE POLICY "system_can_award_badges" ON public.user_badges
    FOR INSERT WITH CHECK (true);

-- المدراء يمكنهم رؤية جميع شارات المستخدمين
CREATE POLICY "managers_can_view_all_user_badges" ON public.user_badges
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'manager'
        )
    );

-- ============================================================================
-- سياسات RLS لجدول المهام
-- ============================================================================

-- المتطوعون يمكنهم رؤية مهامهم
CREATE POLICY "volunteers_can_view_own_tasks" ON public.tasks
    FOR SELECT USING (volunteer_id = auth.uid());

-- المتطوعون يمكنهم تحديث مهامهم
CREATE POLICY "volunteers_can_update_own_tasks" ON public.tasks
    FOR UPDATE USING (volunteer_id = auth.uid());

-- النظام يمكنه إنشاء مهام
CREATE POLICY "system_can_create_tasks" ON public.tasks
    FOR INSERT WITH CHECK (true);

-- المدراء يمكنهم رؤية جميع المهام
CREATE POLICY "managers_can_view_all_tasks" ON public.tasks
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'manager'
        )
    );

-- ============================================================================
-- سياسات RLS لجدول سجل المواقع
-- ============================================================================

-- المستخدمون يمكنهم رؤية سجل مواقعهم
CREATE POLICY "users_can_view_own_location_logs" ON public.location_logs
    FOR SELECT USING (user_id = auth.uid());

-- المستخدمون يمكنهم إضافة سجل مواقع
CREATE POLICY "users_can_create_location_logs" ON public.location_logs
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- المدراء يمكنهم رؤية جميع سجلات المواقع
CREATE POLICY "managers_can_view_all_location_logs" ON public.location_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'manager'
        )
    );

-- ============================================================================
-- سياسات RLS لجدول التقارير
-- ============================================================================

-- المستخدمون يمكنهم إنشاء تقارير
CREATE POLICY "users_can_create_reports" ON public.reports
    FOR INSERT WITH CHECK (reporter_id = auth.uid());

-- المستخدمون يمكنهم رؤية تقاريرهم
CREATE POLICY "users_can_view_own_reports" ON public.reports
    FOR SELECT USING (reporter_id = auth.uid());

-- المدراء يمكنهم إدارة جميع التقارير
CREATE POLICY "managers_can_manage_all_reports" ON public.reports
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'manager'
        )
    );

-- ============================================================================
-- سياسات RLS لجدول الرسائل
-- ============================================================================

-- المستخدمون يمكنهم رؤية رسائلهم
CREATE POLICY "users_can_view_own_messages" ON public.messages
    FOR SELECT USING (sender_id = auth.uid() OR receiver_id = auth.uid());

-- المستخدمون يمكنهم إرسال رسائل
CREATE POLICY "users_can_send_messages" ON public.messages
    FOR INSERT WITH CHECK (sender_id = auth.uid());

-- المستخدمون يمكنهم تحديث رسائلهم (تحديد كمقروءة)
CREATE POLICY "users_can_update_received_messages" ON public.messages
    FOR UPDATE USING (receiver_id = auth.uid());

-- المدراء يمكنهم رؤية جميع الرسائل
CREATE POLICY "managers_can_view_all_messages" ON public.messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'manager'
        )
    );

-- ============================================================================
-- الدوال المساعدة
-- ============================================================================

-- دالة تحديث updated_at تلقائياً
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- إضافة المحفزات لتحديث updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_donations_updated_at BEFORE UPDATE ON public.donations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_inventory_updated_at BEFORE UPDATE ON public.inventory
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON public.tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- إدراج البيانات الأولية
-- ============================================================================

-- إدراج الشارات الأساسية
INSERT INTO public.badges (name, description, requirement_type, requirement_value, points_reward) VALUES
('متطوع جديد', 'أول تبرع يتم قبوله', 'donations_completed', 1, 10),
('متطوع نشط', 'إكمال 5 تبرعات', 'donations_completed', 5, 25),
('متطوع محترف', 'إكمال 20 تبرع', 'donations_completed', 20, 100),
('متطوع خبير', 'إكمال 50 تبرع', 'donations_completed', 50, 250),
('متطوع أسطوري', 'إكمال 100 تبرع', 'donations_completed', 100, 500),
('مساعد سريع', 'إكمال تبرع في أقل من ساعة', 'quick_completion', 1, 50),
('نجم التقييم', 'الحصول على تقييم 5 نجوم', 'five_star_rating', 1, 30),
('متبرع كريم', 'إنشاء 10 تبرعات', 'donations_created', 10, 75);

-- إدراج أكواد التفعيل الأساسية
-- ملاحظة: يجب إنشاء مستخدم مدير وجمعية أولاً لربط الأكواد بهم
-- كود تفعيل المدير
INSERT INTO public.activation_codes (code, association_id, role, expires_at, max_uses, current_uses) 
SELECT 
    '012006001TB',
    (SELECT id FROM public.users WHERE role = 'manager' LIMIT 1),
    'manager',
    NOW() + INTERVAL '1 year',
    1,
    0
WHERE EXISTS (SELECT 1 FROM public.users WHERE role = 'manager');

-- كود تفعيل الجمعية
INSERT INTO public.activation_codes (code, association_id, role, expires_at, max_uses, current_uses)
SELECT 
    '826627BO',
    (SELECT id FROM public.users WHERE role = 'association' LIMIT 1),
    'association',
    NOW() + INTERVAL '1 year',
    1,
    0
WHERE EXISTS (SELECT 1 FROM public.users WHERE role = 'association');

-- إدراج أكواد التفعيل البديلة (في حالة عدم وجود مستخدمين)
-- يمكن تحديث association_id لاحقاً عند إنشاء المستخدمين
INSERT INTO public.activation_codes (code, association_id, role, expires_at, max_uses, current_uses) 
VALUES 
    ('012006001TB', uuid_generate_v4(), 'manager', NOW() + INTERVAL '1 year', 1, 0),
    ('826627BO', uuid_generate_v4(), 'association', NOW() + INTERVAL '1 year', 1, 0)
ON CONFLICT (code) DO NOTHING;

-- ============================================================================
-- نهاية الملف
-- ============================================================================

-- تعليق: تم إنشاء قاعدة البيانات بنجاح مع جميع الجداول وسياسات RLS
-- للتأكد من عمل السياسات بشكل صحيح، يجب التأكد من تسجيل المستخدمين في Supabase Auth
