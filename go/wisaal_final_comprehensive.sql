-- ====================================================================
-- Wisaal Project: Final Comprehensive Database Script
-- Version: 1.0
-- Date: 2025-07-20
-- Description: This script contains the complete database schema,
--              functions, indexes, triggers, and the final consolidated
--              Row-Level Security (RLS) policies.
-- ====================================================================

-- ====================================================================
-- Part 1: Extensions and Basic Setup
-- ====================================================================
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ====================================================================
-- Part 2: ENUM Types
-- ====================================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE user_role AS ENUM ('donor', 'association', 'volunteer', 'manager');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'donation_status') THEN
        CREATE TYPE donation_status AS ENUM ('pending', 'accepted', 'assigned', 'in_progress', 'completed', 'cancelled');
    END IF;
END$$;

-- ====================================================================
-- Part 3: Core Tables
-- ====================================================================

-- Users Table
CREATE TABLE IF NOT EXISTS public.users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name text NOT NULL,
    email text UNIQUE NOT NULL,
    role user_role NOT NULL DEFAULT 'donor',
    phone text,
    city text,
    location geography(Point, 4326),
    avatar_url text,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    associated_with_association_id uuid REFERENCES public.users(id),
    points INT DEFAULT 0
);

-- Donations Table
CREATE TABLE IF NOT EXISTS public.donations (
    donation_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    donor_id uuid REFERENCES public.users(id),
    association_id uuid REFERENCES public.users(id),
    volunteer_id uuid REFERENCES public.users(id),
    status donation_status NOT NULL DEFAULT 'pending',
    method_of_pickup text CHECK (method_of_pickup IN ('by_association', 'by_volunteer') OR method_of_pickup IS NULL),
    donor_qr_code text,
    association_qr_code text,
    title text NOT NULL,
    description text,
    quantity int,
    food_type text,
    expiry_date date,
    pickup_address text,
    image_path text,
    is_urgent boolean DEFAULT false,
    location geography(Point, 4326),
    created_at timestamptz DEFAULT now(),
    picked_up_at timestamptz,
    delivered_at timestamptz,
    scheduled_pickup_time TIMESTAMPTZ
);

-- Activation Codes Table
CREATE TABLE IF NOT EXISTS public.activation_codes (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT NOT NULL UNIQUE,
    role user_role NOT NULL,
    is_used BOOLEAN DEFAULT false,
    created_by_association_id UUID REFERENCES users(id),
    used_by_user_id UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ,
    max_uses INT DEFAULT 1,
    current_uses INT DEFAULT 0
);

-- Notifications Table
CREATE TABLE IF NOT EXISTS public.notifications (
    id serial PRIMARY KEY,
    user_id uuid REFERENCES public.users(id),
    title text NOT NULL,
    body text NOT NULL,
    is_read boolean DEFAULT false,
    created_at timestamptz DEFAULT now()
);

-- Ratings Table
CREATE TABLE IF NOT EXISTS public.ratings (
    id serial PRIMARY KEY,
    rater_id uuid NOT NULL REFERENCES public.users(id),
    volunteer_id uuid NOT NULL REFERENCES public.users(id),
    task_id uuid REFERENCES public.donations(donation_id),
    rating int CHECK (rating >= 1 AND rating <= 5),
    comment text,
    created_at timestamptz DEFAULT now()
);

-- Badges Table
CREATE TABLE IF NOT EXISTS public.badges (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    icon_url TEXT,
    points_required INT DEFAULT 0
);

-- User Badges Table
CREATE TABLE IF NOT EXISTS public.user_badges (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES public.users(id),
    badge_id uuid REFERENCES public.badges(id),
    earned_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, badge_id)
);

-- User Locations Table
CREATE TABLE IF NOT EXISTS public.user_locations (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    location GEOMETRY(Point, 4326) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ====================================================================
-- Part 4: Indexes for Performance
-- ====================================================================
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_location ON public.users USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_donations_status ON public.donations(status);
CREATE INDEX IF NOT EXISTS idx_donations_location ON public.donations USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_activation_codes_role ON public.activation_codes(role);

-- ====================================================================
-- Part 5: Database Functions
-- ====================================================================

-- Get User Role (Helper for RLS)
CREATE OR REPLACE FUNCTION public.get_user_role(p_user_id uuid)
RETURNS text AS $$
BEGIN
  RETURN (SELECT role::text FROM public.users WHERE id = p_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Handle New User (Trigger Function)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, full_name, email, role, avatar_url)
  VALUES (new.id, new.raw_user_meta_data->>'full_name', new.email, 'donor', new.raw_user_meta_data->>'avatar_url');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Generate Activation Code
CREATE OR REPLACE FUNCTION public.generate_activation_code(p_association_id uuid, p_role user_role)
RETURNS text AS $$
DECLARE
    v_code text;
BEGIN
    v_code := substr(md5(random()::text), 0, 9);
    INSERT INTO public.activation_codes (code, role, created_by_association_id)
    VALUES (v_code, p_role, p_association_id);
    RETURN v_code;
END;
$$ LANGUAGE plpgsql;

-- Update User Location
CREATE OR REPLACE FUNCTION public.update_user_location(lat double precision, long double precision)
RETURNS void AS $$
BEGIN
  INSERT INTO public.user_locations(user_id, location)
  VALUES (auth.uid(), ST_SetSRID(ST_MakePoint(long, lat), 4326));
END;
$$ LANGUAGE plpgsql;

-- ====================================================================
-- Part 6: Triggers
-- ====================================================================

-- Trigger for new user creation
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ====================================================================
-- Part 7: Row-Level Security (RLS) Setup
-- ====================================================================

-- Enable RLS on all relevant tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.donations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activation_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;

-- RLS Policies for 'users'
DROP POLICY IF EXISTS "Users can view their own data" ON public.users;
CREATE POLICY "Users can view their own data" ON public.users FOR SELECT USING (auth.uid() = id);
DROP POLICY IF EXISTS "Users can update their own data" ON public.users;
CREATE POLICY "Users can update their own data" ON public.users FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
DROP POLICY IF EXISTS "Managers can view all users" ON public.users;
CREATE POLICY "Managers can view all users" ON public.users FOR SELECT USING (get_user_role(auth.uid()) = 'manager');
DROP POLICY IF EXISTS "Associations can view their volunteers" ON public.users;
CREATE POLICY "Associations can view their volunteers" ON public.users FOR SELECT USING (get_user_role(auth.uid()) = 'association' AND associated_with_association_id = auth.uid());

-- RLS Policies for 'donations'
DROP POLICY IF EXISTS "Users can manage their own donations" ON public.donations;
CREATE POLICY "Users can manage their own donations" ON public.donations FOR ALL USING (auth.uid() = donor_id);
DROP POLICY IF EXISTS "Associations can manage their donations" ON public.donations;
CREATE POLICY "Associations can manage their donations" ON public.donations FOR ALL USING (auth.uid() = association_id);
DROP POLICY IF EXISTS "Volunteers can manage their assigned donations" ON public.donations;
CREATE POLICY "Volunteers can manage their assigned donations" ON public.donations FOR ALL USING (auth.uid() = volunteer_id);
DROP POLICY IF EXISTS "Managers can view all donations" ON public.donations;
CREATE POLICY "Managers can view all donations" ON public.donations FOR SELECT USING (get_user_role(auth.uid()) = 'manager');

-- RLS Policies for 'notifications'
DROP POLICY IF EXISTS "Users can manage their own notifications" ON public.notifications;
CREATE POLICY "Users can manage their own notifications" ON public.notifications FOR ALL USING (auth.uid() = user_id);

-- RLS Policies for 'ratings'
DROP POLICY IF EXISTS "Users can insert ratings" ON public.ratings;
CREATE POLICY "Users can insert ratings" ON public.ratings FOR INSERT WITH CHECK (get_user_role(auth.uid()) IN ('association', 'manager', 'donor'));
DROP POLICY IF EXISTS "Users can view ratings" ON public.ratings;
CREATE POLICY "Users can view ratings" ON public.ratings FOR SELECT USING (
    get_user_role(auth.uid()) = 'manager' OR
    (get_user_role(auth.uid()) = 'association' AND volunteer_id IN (SELECT u.id FROM users u WHERE u.associated_with_association_id = auth.uid()))
);

-- RLS Policies for 'activation_codes'
DROP POLICY IF EXISTS "Public can read activation codes" ON public.activation_codes;
CREATE POLICY "Public can read activation codes" ON public.activation_codes FOR SELECT USING (true);
DROP POLICY IF EXISTS "Managers can do anything on activation_codes" ON public.activation_codes;
CREATE POLICY "Managers can do anything on activation_codes" ON public.activation_codes FOR ALL USING (get_user_role(auth.uid()) = 'manager');
DROP POLICY IF EXISTS "Associations can manage their activation codes" ON public.activation_codes;
CREATE POLICY "Associations can manage their activation codes" ON public.activation_codes FOR ALL USING (get_user_role(auth.uid()) = 'association' AND created_by_association_id = auth.uid());

-- RLS Policies for 'user_locations'
DROP POLICY IF EXISTS "Users can manage their own location" ON public.user_locations;
CREATE POLICY "Users can manage their own location" ON public.user_locations FOR ALL USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Authenticated users can view all locations" ON public.user_locations;
CREATE POLICY "Authenticated users can view all locations" ON public.user_locations FOR SELECT USING (auth.role() = 'authenticated');

-- ====================================================================
-- Part 8: Initial Data and Setup
-- ====================================================================

-- Fix activation_codes CHECK constraint
DO $$
BEGIN
    ALTER TABLE public.activation_codes DROP CONSTRAINT IF EXISTS activation_codes_role_check;
    ALTER TABLE public.activation_codes ADD CONSTRAINT activation_codes_role_check CHECK (role IN ('volunteer', 'manager', 'association', 'donor'));
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Could not modify activation_codes_role_check constraint: %', SQLERRM;
END $$;

-- Insert/Update special activation codes
DO $$
BEGIN
    -- Manager Code
    INSERT INTO public.activation_codes (code, role, expires_at, max_uses)
    VALUES ('012006001TB', 'manager', NOW() + INTERVAL '5 year', 1)
    ON CONFLICT (code) DO UPDATE SET 
        role = 'manager', expires_at = NOW() + INTERVAL '5 year', is_used = false, current_uses = 0;
    -- Association Code
    INSERT INTO public.activation_codes (code, role, expires_at, max_uses)
    VALUES ('826627BO', 'association', NOW() + INTERVAL '5 year', 1)
    ON CONFLICT (code) DO UPDATE SET 
        role = 'association', expires_at = NOW() + INTERVAL '5 year', is_used = false, current_uses = 0;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inserting/updating special activation codes: %', SQLERRM;
END $$;

-- Insert sample badges
INSERT INTO public.badges (name, description, icon_url, points_required) VALUES
('أول تبرع', 'شارة للتبرع الأول', 'url_icon_1', 1),
('متبرع سخي', 'شارة للمتبرعين النشطين', 'url_icon_2', 100),
('متطوع مساعد', 'شارة للمتطوعين الجدد', 'url_icon_3', 50),
('بطل المجتمع', 'شارة للأعضاء الاستثنائيين', 'url_icon_4', 1000)
ON CONFLICT (name) DO NOTHING;

-- ====================================================================
-- Part 9: Final Verification
-- ====================================================================
DO $$
BEGIN
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'Wisaal Final Comprehensive Database Script Completed Successfully!';
  RAISE NOTICE 'Database is ready for use.';
  RAISE NOTICE '====================================================================';
END $$;

-- ====================================================================
-- END OF SCRIPT
-- ====================================================================
