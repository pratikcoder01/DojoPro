-- Create public.tournament_registrations Table
CREATE TABLE IF NOT EXISTS public.tournament_registrations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
    athlete_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    payment_intent_id VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_tournament_athlete UNIQUE (tournament_id, athlete_id)
);

-- Enable RLS
ALTER TABLE public.tournament_registrations ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Allow public read access to registrations" ON public.tournament_registrations
    FOR SELECT USING (true);

CREATE POLICY "Allow authenticated athletes to register themselves" ON public.tournament_registrations
    FOR INSERT WITH CHECK (
        auth.uid() = athlete_id
    );
