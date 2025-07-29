-- ====================================================================
-- إضافة الجداول المفقودة لمشروع وصال
-- Add Missing Tables for Wisaal Project
-- ====================================================================

-- هذا الملف يضيف الجداول التي قد يحتاجها التطبيق ولكنها غير موجودة في قاعدة البيانات

-- ====================================================================
-- جدول المخزون (Inventory)
-- ====================================================================

-- إنشاء جدول المخزون للجمعيات
DROP TABLE IF EXISTS inventory CASCADE;
CREATE TABLE IF NOT EXISTS inventory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  association_id uuid REFERENCES users(id) NOT NULL,
  item_name text NOT NULL,
  item_type text NOT NULL, -- 'food', 'clothing', 'medicine', 'other'
  quantity integer NOT NULL DEFAULT 0,
  unit text DEFAULT 'piece', -- 'kg', 'liter', 'piece', 'box', etc.
  expiry_date date,
  location_in_warehouse text,
  notes text,
  status text DEFAULT 'available' CHECK (status IN ('available', 'reserved', 'distributed', 'expired')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  -- معلومات إضافية
  source_donation_id uuid REFERENCES donations(donation_id),
  minimum_stock_level integer DEFAULT 0,
  current_stock_level integer DEFAULT 0,
  
  -- معلومات التوزيع
  distributed_quantity integer DEFAULT 0,
  last_distributed_at timestamptz,
  
  CONSTRAINT inventory_quantity_check CHECK (quantity >= 0),
  CONSTRAINT inventory_distributed_check CHECK (distributed_quantity >= 0),
  CONSTRAINT inventory_stock_check CHECK (current_stock_level >= 0)
);

-- ====================================================================
-- جدول طلبات المساعدة (Help Requests)
-- ====================================================================

-- إنشاء جدول طلبات المساعدة من المحتاجين
DROP TABLE IF EXISTS help_requests CASCADE;
CREATE TABLE IF NOT EXISTS help_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_name text NOT NULL,
  requester_phone text NOT NULL,
  requester_email text,
  family_size integer DEFAULT 1,
  request_type text NOT NULL, -- 'food', 'clothing', 'medicine', 'financial', 'other'
  description text NOT NULL,
  urgency_level text DEFAULT 'normal' CHECK (urgency_level IN ('low', 'normal', 'high', 'urgent')),
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'in_progress', 'completed', 'rejected')),
  
  -- معلومات الموقع
  address text,
  city text,
  location geography(Point, 4326),
  
  -- معلومات الاستجابة
  assigned_association_id uuid REFERENCES users(id),
  assigned_volunteer_id uuid REFERENCES users(id),
  response_notes text,
  
  -- التواريخ
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  approved_at timestamptz,
  completed_at timestamptz,
  
  -- معلومات إضافية
  verification_status text DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected')),
  verification_notes text,
  priority_score integer DEFAULT 0
);

-- ====================================================================
-- جدول توزيع المساعدات (Distribution Records)
-- ====================================================================

-- إنشاء جدول سجلات توزيع المساعدات
DROP TABLE IF EXISTS distribution_records CASCADE;
CREATE TABLE IF NOT EXISTS distribution_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  association_id uuid REFERENCES users(id) NOT NULL,
  volunteer_id uuid REFERENCES users(id),
  help_request_id uuid REFERENCES help_requests(id),
  
  -- تفاصيل التوزيع
  items_distributed jsonb NOT NULL, -- قائمة بالعناصر الموزعة
  total_value decimal(10,2) DEFAULT 0,
  beneficiary_name text NOT NULL,
  beneficiary_phone text,
  beneficiary_signature text, -- base64 encoded signature
  
  -- معلومات الموقع والوقت
  distribution_date timestamptz DEFAULT now(),
  distribution_location text,
  location geography(Point, 4326),
  
  -- معلومات إضافية
  notes text,
  photos jsonb, -- قائمة بروابط الصور
  verification_code text,
  
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ====================================================================
-- جدول الأحداث والفعاليات (Events)
-- ====================================================================

-- إنشاء جدول الأحداث والفعاليات الخيرية
DROP TABLE IF EXISTS events CASCADE;
CREATE TABLE IF NOT EXISTS events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organizer_id uuid REFERENCES users(id) NOT NULL,
  title text NOT NULL,
  description text,
  event_type text NOT NULL, -- 'donation_drive', 'volunteer_training', 'awareness', 'distribution', 'other'
  
  -- معلومات الوقت والمكان
  start_date timestamptz NOT NULL,
  end_date timestamptz NOT NULL,
  location_name text,
  address text,
  city text,
  location geography(Point, 4326),
  
  -- معلومات التسجيل
  max_participants integer,
  current_participants integer DEFAULT 0,
  registration_required boolean DEFAULT true,
  registration_deadline timestamptz,
  
  -- الحالة
  status text DEFAULT 'planned' CHECK (status IN ('planned', 'active', 'completed', 'cancelled')),
  
  -- معلومات إضافية
  requirements text, -- متطلبات المشاركة
  contact_info text,
  image_url text,
  
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  CONSTRAINT events_date_check CHECK (end_date >= start_date),
  CONSTRAINT events_participants_check CHECK (current_participants <= max_participants)
);

-- ====================================================================
-- جدول تسجيل المشاركين في الأحداث (Event Registrations)
-- ====================================================================

-- إنشاء جدول تسجيل المشاركين في الأحداث
DROP TABLE IF EXISTS event_registrations CASCADE;
CREATE TABLE IF NOT EXISTS event_registrations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid REFERENCES events(id) NOT NULL,
  participant_id uuid REFERENCES users(id) NOT NULL,
  
  -- معلومات التسجيل
  registration_date timestamptz DEFAULT now(),
  status text DEFAULT 'registered' CHECK (status IN ('registered', 'confirmed', 'attended', 'cancelled', 'no_show')),
  
  -- معلومات إضافية
  notes text,
  special_requirements text,
  
  -- معلومات الحضور
  check_in_time timestamptz,
  check_out_time timestamptz,
  attendance_verified boolean DEFAULT false,
  
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  UNIQUE(event_id, participant_id)
);

-- ====================================================================
-- جدول التقارير (Reports)
-- ====================================================================

-- إنشاء جدول التقارير للإحصائيات والتحليلات
DROP TABLE IF EXISTS reports CASCADE;
CREATE TABLE IF NOT EXISTS reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  generated_by uuid REFERENCES users(id) NOT NULL,
  report_type text NOT NULL, -- 'monthly', 'quarterly', 'annual', 'custom', 'donation_summary', 'volunteer_performance'
  title text NOT NULL,
  
  -- فترة التقرير
  start_date date NOT NULL,
  end_date date NOT NULL,
  
  -- محتوى التقرير
  data jsonb NOT NULL, -- بيانات التقرير في صيغة JSON
  summary text,
  
  -- معلومات التوليد
  generated_at timestamptz DEFAULT now(),
  status text DEFAULT 'generated' CHECK (status IN ('generating', 'generated', 'error')),
  
  -- معلومات إضافية
  filters_applied jsonb, -- الفلاتر المطبقة
  file_url text, -- رابط ملف PDF إذا تم إنشاؤه
  
  created_at timestamptz DEFAULT now(),
  
  CONSTRAINT reports_date_check CHECK (end_date >= start_date)
);

-- ====================================================================
-- جدول الرسائل (Messages)
-- ====================================================================

-- إنشاء جدول الرسائل بين المستخدمين
DROP TABLE IF EXISTS messages CASCADE;
CREATE TABLE IF NOT EXISTS messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id uuid REFERENCES users(id) NOT NULL,
  recipient_id uuid REFERENCES users(id) NOT NULL,
  
  -- محتوى الرسالة
  subject text,
  content text NOT NULL,
  message_type text DEFAULT 'direct' CHECK (message_type IN ('direct', 'notification', 'system', 'broadcast')),
  
  -- الحالة
  is_read boolean DEFAULT false,
  is_archived boolean DEFAULT false,
  priority text DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  
  -- معلومات إضافية
  attachments jsonb, -- قائمة بالمرفقات
  related_donation_id uuid REFERENCES donations(donation_id),
  related_event_id uuid REFERENCES events(id),
  
  -- التواريخ
  sent_at timestamptz DEFAULT now(),
  read_at timestamptz,
  
  created_at timestamptz DEFAULT now()
);

-- ====================================================================
-- إضافة الفهارس للأداء
-- ====================================================================

-- فهارس جدول المخزون
CREATE INDEX IF NOT EXISTS idx_inventory_association_id ON inventory(association_id);
CREATE INDEX IF NOT EXISTS idx_inventory_item_type ON inventory(item_type);
CREATE INDEX IF NOT EXISTS idx_inventory_status ON inventory(status);
CREATE INDEX IF NOT EXISTS idx_inventory_expiry_date ON inventory(expiry_date);

-- فهارس جدول طلبات المساعدة
CREATE INDEX IF NOT EXISTS idx_help_requests_status ON help_requests(status);
CREATE INDEX IF NOT EXISTS idx_help_requests_urgency ON help_requests(urgency_level);
CREATE INDEX IF NOT EXISTS idx_help_requests_type ON help_requests(request_type);
CREATE INDEX IF NOT EXISTS idx_help_requests_assigned_association ON help_requests(assigned_association_id);

-- فهارس جدول سجلات التوزيع
CREATE INDEX IF NOT EXISTS idx_distribution_association_id ON distribution_records(association_id);
CREATE INDEX IF NOT EXISTS idx_distribution_volunteer_id ON distribution_records(volunteer_id);
CREATE INDEX IF NOT EXISTS idx_distribution_date ON distribution_records(distribution_date);

-- فهارس جدول الأحداث
CREATE INDEX IF NOT EXISTS idx_events_organizer_id ON events(organizer_id);
CREATE INDEX IF NOT EXISTS idx_events_start_date ON events(start_date);
CREATE INDEX IF NOT EXISTS idx_events_status ON events(status);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type);

-- فهارس جدول تسجيل الأحداث
CREATE INDEX IF NOT EXISTS idx_event_registrations_event_id ON event_registrations(event_id);
CREATE INDEX IF NOT EXISTS idx_event_registrations_participant_id ON event_registrations(participant_id);
CREATE INDEX IF NOT EXISTS idx_event_registrations_status ON event_registrations(status);

-- فهارس جدول التقارير
CREATE INDEX IF NOT EXISTS idx_reports_generated_by ON reports(generated_by);
CREATE INDEX IF NOT EXISTS idx_reports_type ON reports(report_type);
CREATE INDEX IF NOT EXISTS idx_reports_generated_at ON reports(generated_at);

-- فهارس جدول الرسائل
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_recipient_id ON messages(recipient_id);
CREATE INDEX IF NOT EXISTS idx_messages_sent_at ON messages(sent_at);
CREATE INDEX IF NOT EXISTS idx_messages_is_read ON messages(is_read);

-- ====================================================================
-- إضافة Triggers لتحديث updated_at
-- ====================================================================

-- Trigger لجدول المخزون
DROP TRIGGER IF EXISTS update_inventory_updated_at ON inventory;
CREATE TRIGGER update_inventory_updated_at 
    BEFORE UPDATE ON inventory 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger لجدول طلبات المساعدة
DROP TRIGGER IF EXISTS update_help_requests_updated_at ON help_requests;
CREATE TRIGGER update_help_requests_updated_at 
    BEFORE UPDATE ON help_requests 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger لجدول سجلات التوزيع
DROP TRIGGER IF EXISTS update_distribution_records_updated_at ON distribution_records;
CREATE TRIGGER update_distribution_records_updated_at 
    BEFORE UPDATE ON distribution_records 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger لجدول الأحداث
DROP TRIGGER IF EXISTS update_events_updated_at ON events;
CREATE TRIGGER update_events_updated_at 
    BEFORE UPDATE ON events 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger لجدول تسجيل الأحداث
DROP TRIGGER IF EXISTS update_event_registrations_updated_at ON event_registrations;
CREATE TRIGGER update_event_registrations_updated_at 
    BEFORE UPDATE ON event_registrations 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ====================================================================
-- إعداد Row Level Security للجداول الجديدة
-- ====================================================================

-- تفعيل RLS على الجداول الجديدة
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE help_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE distribution_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- سياسات RLS لجدول المخزون
DROP POLICY IF EXISTS "Associations can manage their inventory" ON inventory;
CREATE POLICY "Associations can manage their inventory" ON inventory
  FOR ALL USING (association_id = auth.uid());

DROP POLICY IF EXISTS "Managers can view all inventory" ON inventory;
CREATE POLICY "Managers can view all inventory" ON inventory
  FOR SELECT USING (get_user_role(auth.uid()) = 'manager');

-- سياسات RLS لجدول طلبات المساعدة
DROP POLICY IF EXISTS "Anyone can create help requests" ON help_requests;
CREATE POLICY "Anyone can create help requests" ON help_requests
  FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Associations and managers can view help requests" ON help_requests;
CREATE POLICY "Associations and managers can view help requests" ON help_requests
  FOR SELECT USING (
    get_user_role(auth.uid()) IN ('association', 'manager') OR
    assigned_association_id = auth.uid() OR
    assigned_volunteer_id = auth.uid()
  );

-- سياسات RLS لجدول سجلات التوزيع
DROP POLICY IF EXISTS "Associations can manage their distributions" ON distribution_records;
CREATE POLICY "Associations can manage their distributions" ON distribution_records
  FOR ALL USING (association_id = auth.uid() OR get_user_role(auth.uid()) = 'manager');

-- سياسات RLS لجدول الأحداث
DROP POLICY IF EXISTS "Anyone can view events" ON events;
CREATE POLICY "Anyone can view events" ON events
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Associations and managers can create events" ON events;
CREATE POLICY "Associations and managers can create events" ON events
  FOR INSERT WITH CHECK (get_user_role(auth.uid()) IN ('association', 'manager'));

-- سياسات RLS لجدول تسجيل الأحداث
DROP POLICY IF EXISTS "Users can manage their event registrations" ON event_registrations;
CREATE POLICY "Users can manage their event registrations" ON event_registrations
  FOR ALL USING (participant_id = auth.uid() OR get_user_role(auth.uid()) = 'manager');

-- سياسات RLS لجدول التقارير
DROP POLICY IF EXISTS "Managers can manage all reports" ON reports;
CREATE POLICY "Managers can manage all reports" ON reports
  FOR ALL USING (get_user_role(auth.uid()) = 'manager');

-- سياسات RLS لجدول الرسائل
DROP POLICY IF EXISTS "Users can manage their messages" ON messages;
CREATE POLICY "Users can manage their messages" ON messages
  FOR ALL USING (sender_id = auth.uid() OR recipient_id = auth.uid() OR get_user_role(auth.uid()) = 'manager');

-- ====================================================================
-- إضافة دوال مساعدة للجداول الجديدة
-- ====================================================================

-- دالة لإضافة عنصر للمخزون
CREATE OR REPLACE FUNCTION add_inventory_item(
  p_association_id uuid,
  p_item_name text,
  p_item_type text,
  p_quantity integer,
  p_unit text DEFAULT 'piece',
  p_expiry_date date DEFAULT NULL,
  p_source_donation_id uuid DEFAULT NULL
)
RETURNS uuid AS $$
DECLARE
  new_item_id uuid;
BEGIN
  INSERT INTO inventory (
    association_id,
    item_name,
    item_type,
    quantity,
    unit,
    expiry_date,
    source_donation_id,
    current_stock_level
  ) VALUES (
    p_association_id,
    p_item_name,
    p_item_type,
    p_quantity,
    p_unit,
    p_expiry_date,
    p_source_donation_id,
    p_quantity
  ) RETURNING id INTO new_item_id;
  
  RETURN new_item_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- دالة لإنشاء طلب مساعدة
CREATE OR REPLACE FUNCTION create_help_request(
  p_requester_name text,
  p_requester_phone text,
  p_request_type text,
  p_description text,
  p_family_size integer DEFAULT 1,
  p_urgency_level text DEFAULT 'normal',
  p_address text DEFAULT NULL,
  p_city text DEFAULT NULL
)
RETURNS uuid AS $$
DECLARE
  new_request_id uuid;
BEGIN
  INSERT INTO help_requests (
    requester_name,
    requester_phone,
    request_type,
    description,
    family_size,
    urgency_level,
    address,
    city
  ) VALUES (
    p_requester_name,
    p_requester_phone,
    p_request_type,
    p_description,
    p_family_size,
    p_urgency_level,
    p_address,
    p_city
  ) RETURNING id INTO new_request_id;
  
  RETURN new_request_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- دالة للحصول على إحصائيات المخزون
CREATE OR REPLACE FUNCTION get_inventory_stats(p_association_id uuid)
RETURNS json AS $$
BEGIN
  RETURN (
    SELECT json_build_object(
      'total_items', COUNT(*),
      'available_items', COUNT(CASE WHEN status = 'available' THEN 1 END),
      'expired_items', COUNT(CASE WHEN status = 'expired' OR expiry_date < CURRENT_DATE THEN 1 END),
      'low_stock_items', COUNT(CASE WHEN current_stock_level <= minimum_stock_level THEN 1 END),
      'item_types', json_agg(DISTINCT item_type)
    )
    FROM inventory
    WHERE association_id = p_association_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================================================
-- إعطاء الصلاحيات
-- ====================================================================

-- صلاحيات الجداول
GRANT ALL ON inventory TO service_role, supabase_admin;
GRANT ALL ON help_requests TO service_role, supabase_admin;
GRANT ALL ON distribution_records TO service_role, supabase_admin;
GRANT ALL ON events TO service_role, supabase_admin;
GRANT ALL ON event_registrations TO service_role, supabase_admin;
GRANT ALL ON reports TO service_role, supabase_admin;
GRANT ALL ON messages TO service_role, supabase_admin;

GRANT SELECT, INSERT, UPDATE ON inventory TO authenticated;
GRANT SELECT, INSERT, UPDATE ON help_requests TO authenticated;
GRANT SELECT, INSERT, UPDATE ON distribution_records TO authenticated;
GRANT SELECT, INSERT, UPDATE ON events TO authenticated;
GRANT SELECT, INSERT, UPDATE ON event_registrations TO authenticated;
GRANT SELECT ON reports TO authenticated;
GRANT SELECT, INSERT, UPDATE ON messages TO authenticated;

-- صلاحيات الدوال
GRANT EXECUTE ON FUNCTION add_inventory_item TO authenticated;
GRANT EXECUTE ON FUNCTION create_help_request TO authenticated;
GRANT EXECUTE ON FUNCTION get_inventory_stats TO authenticated;

-- ====================================================================
-- إدراج بيانات تجريبية
-- ====================================================================

-- إدراج بعض العناصر التجريبية في المخزون (إذا كانت هناك جمعيات)
DO $$
DECLARE
  association_id uuid;
BEGIN
  -- البحث عن أول جمعية في النظام
  SELECT id INTO association_id 
  FROM users 
  WHERE role = 'association' 
  LIMIT 1;
  
  -- إذا وُجدت جمعية، أضف بعض العناصر التجريبية
  IF association_id IS NOT NULL THEN
    INSERT INTO inventory (association_id, item_name, item_type, quantity, unit, current_stock_level, minimum_stock_level) VALUES
    (association_id, 'أرز أبيض', 'food', 50, 'kg', 50, 10),
    (association_id, 'زيت طبخ', 'food', 20, 'liter', 20, 5),
    (association_id, 'معلبات تونة', 'food', 100, 'can', 100, 20),
    (association_id, 'ملابس شتوية', 'clothing', 30, 'piece', 30, 5),
    (association_id, 'أدوية أساسية', 'medicine', 15, 'box', 15, 3)
    ON CONFLICT DO NOTHING;
    
    RAISE NOTICE 'تم إدراج عناصر تجريبية في المخزون للجمعية: %', association_id;
  END IF;
END $$;

-- ====================================================================
-- رسالة نهائية
-- ====================================================================

DO $$
BEGIN
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'تم إضافة الجداول المفقودة بنجاح!';
  RAISE NOTICE 'Added Missing Tables Successfully!';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'الجداول المضافة:';
  RAISE NOTICE '- inventory (المخزون)';
  RAISE NOTICE '- help_requests (طلبات المساعدة)';
  RAISE NOTICE '- distribution_records (سجلات التوزيع)';
  RAISE NOTICE '- events (الأحداث)';
  RAISE NOTICE '- event_registrations (تسجيل الأحداث)';
  RAISE NOTICE '- reports (التقارير)';
  RAISE NOTICE '- messages (الرسائل)';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'يمكن الآن استخدام جميع ميزات التطبيق!';
  RAISE NOTICE '====================================================================';
END $$;