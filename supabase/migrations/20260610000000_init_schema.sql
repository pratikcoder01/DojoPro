-- Enable Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "vector";

-- Drop Custom Types if they exist
DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS booking_type CASCADE;
DROP TYPE IF EXISTS booking_status CASCADE;
DROP TYPE IF EXISTS verification_status CASCADE;
DROP TYPE IF EXISTS tournament_status CASCADE;

-- Create Custom Types
CREATE TYPE user_role AS ENUM ('athlete', 'coach', 'gym', 'admin');
CREATE TYPE booking_type AS ENUM ('in-person', 'online');
CREATE TYPE booking_status AS ENUM ('pending', 'confirmed', 'cancelled', 'completed');
CREATE TYPE verification_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE tournament_status AS ENUM ('open', 'closed', 'completed');

-- Create public.users Table (extends auth.users)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) UNIQUE NOT NULL,
    role user_role NOT NULL DEFAULT 'athlete',
    belt_level VARCHAR(50) NOT NULL DEFAULT 'White',
    discipline VARCHAR(100),
    location GEOMETRY(Point, 4326),
    verified BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    avatar_url VARCHAR(500),
    display_name VARCHAR(150),
    bio TEXT
);

-- Index for spatial queries
CREATE INDEX IF NOT EXISTS users_location_idx ON public.users USING GIST (location);

-- Create public.coach_profiles Table
CREATE TABLE IF NOT EXISTS public.coach_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE UNIQUE,
    hourly_rate NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    bio TEXT,
    certifications JSONB NOT NULL DEFAULT '[]'::jsonb,
    availability JSONB NOT NULL DEFAULT '[]'::jsonb,
    rating NUMERIC(3, 2) NOT NULL DEFAULT 5.00 CHECK (rating >= 1.00 AND rating <= 5.00),
    total_sessions INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create public.bookings Table
CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    coach_id UUID NOT NULL REFERENCES public.coach_profiles(id) ON DELETE CASCADE,
    athlete_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_mins INT NOT NULL DEFAULT 60 CHECK (duration_mins > 0),
    type booking_type NOT NULL DEFAULT 'in-person',
    status booking_status NOT NULL DEFAULT 'pending',
    stripe_payment_intent VARCHAR(255),
    amount_paise INT NOT NULL CHECK (amount_paise >= 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create public.belt_verifications Table
CREATE TABLE IF NOT EXISTS public.belt_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    discipline VARCHAR(100) NOT NULL,
    level VARCHAR(50) NOT NULL,
    certificate_url VARCHAR(500),
    verifier_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    status verification_status NOT NULL DEFAULT 'pending',
    blockchain_hash VARCHAR(255),
    issued_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create public.tournaments Table
CREATE TABLE IF NOT EXISTS public.tournaments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organizer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    discipline VARCHAR(100) NOT NULL,
    location GEOMETRY(Point, 4326),
    venue VARCHAR(255) NOT NULL,
    start_date DATE NOT NULL,
    registration_deadline DATE NOT NULL,
    fee_paise INT NOT NULL CHECK (fee_paise >= 0),
    max_participants INT NOT NULL CHECK (max_participants > 0),
    bracket JSONB NOT NULL DEFAULT '{}'::jsonb,
    status tournament_status NOT NULL DEFAULT 'open',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_deadline CHECK (registration_deadline <= start_date)
);

-- Index for tournament locations
CREATE INDEX IF NOT EXISTS tournaments_location_idx ON public.tournaments USING GIST (location);

-- Function to handle user sign up via Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, role, display_name, avatar_url)
    VALUES (
        new.id,
        new.email,
        COALESCE((new.raw_user_meta_data->>'role')::user_role, 'athlete'::user_role),
        COALESCE(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)),
        new.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call handler on insert to auth.users
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coach_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.belt_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tournaments ENABLE ROW LEVEL SECURITY;

-- RLS Policies: users
CREATE POLICY "Allow public read access to profiles" ON public.users
    FOR SELECT USING (true);

CREATE POLICY "Allow users to update their own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- RLS Policies: coach_profiles
CREATE POLICY "Allow public read access to coach profiles" ON public.coach_profiles
    FOR SELECT USING (true);

CREATE POLICY "Allow coaches to update their own profiles" ON public.coach_profiles
    FOR UPDATE USING (
        auth.uid() = user_id
    );

CREATE POLICY "Allow coaches to insert their own profile" ON public.coach_profiles
    FOR INSERT WITH CHECK (
        auth.uid() = user_id
    );

-- RLS Policies: bookings
CREATE POLICY "Allow users to read bookings they are involved in" ON public.bookings
    FOR SELECT USING (
        auth.uid() = athlete_id OR 
        auth.uid() = (SELECT user_id FROM public.coach_profiles WHERE id = coach_id)
    );

CREATE POLICY "Allow athletes to insert bookings" ON public.bookings
    FOR INSERT WITH CHECK (
        auth.uid() = athlete_id
    );

CREATE POLICY "Allow involved users to update booking status" ON public.bookings
    FOR UPDATE USING (
        auth.uid() = athlete_id OR 
        auth.uid() = (SELECT user_id FROM public.coach_profiles WHERE id = coach_id)
    );

-- RLS Policies: belt_verifications
CREATE POLICY "Allow users to read their own verifications" ON public.belt_verifications
    FOR SELECT USING (
        auth.uid() = user_id OR 
        auth.uid() = verifier_id
    );

CREATE POLICY "Allow athletes to submit verification requests" ON public.belt_verifications
    FOR INSERT WITH CHECK (
        auth.uid() = user_id
    );

-- RLS Policies: tournaments
CREATE POLICY "Allow public read access to tournaments" ON public.tournaments
    FOR SELECT USING (true);

CREATE POLICY "Allow organizers to manage their own tournaments" ON public.tournaments
    FOR ALL USING (
        auth.uid() = organizer_id
    );
