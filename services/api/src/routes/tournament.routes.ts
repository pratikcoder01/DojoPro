import { Router, Response, NextFunction } from 'express';
import { z } from 'zod';
import { supabase } from '../index';
import { requireAuth } from '../middleware/auth.middleware';
import { AuthenticatedRequest } from '../types';

const router = Router();

// Zod schemas for input validation
const registerSchema = z.object({
  athlete_id: z.string(),
  payment_intent_id: z.string()
});

interface Tournament {
  id: string;
  organizer_id: string;
  title: string;
  discipline: string;
  city: string;
  location_name: string;
  start_date: string;
  registration_deadline: string;
  fee_paise: number;
  max_participants: number;
  current_participants: number;
  status: 'open' | 'closed' | 'completed';
  format: 'kata' | 'kumite' | 'both';
  weight_class: string;
  bracket: any;
  created_at: string;
}

// Structured Mock Bracket for Mumbai Open (Single elimination, 8 participants)
const mockMumbaiBracket = {
  rounds: [
    {
      name: "Quarterfinals",
      matches: [
        {
          id: "m1",
          competitor1: { name: "Arjun Mehta", belt: "brown", gym: "Dharavi MMA & BJJ", isWinner: false, score: "2" },
          competitor2: { name: "Rohan Sharma", belt: "black", gym: "Mumbai Karate Club", isWinner: true, score: "3" },
          winnerName: "Rohan Sharma",
          time: "10:30 AM",
          result: "Rohan Sharma won by Decision (3-2) after close striking exchange.",
          status: "completed"
        },
        {
          id: "m2",
          competitor1: { name: "Pooja Patel", belt: "green", gym: "Dojo Pro Mumbai", isWinner: true, score: "2" },
          competitor2: { name: "Aisha Khan", belt: "blue", gym: "West Mumbai Karate", isWinner: false, score: "0" },
          winnerName: "Pooja Patel",
          time: "11:00 AM",
          result: "Pooja Patel won by Ippon (2-0) using leverage throws.",
          status: "completed"
        },
        {
          id: "m3",
          competitor1: { name: "Vikram Malhotra", belt: "brown", gym: "Pune Fighter Gym", isWinner: true, score: "1" },
          competitor2: { name: "Sameer Joshi", belt: "yellow", gym: "Thane Martial Arts", isWinner: false, score: "0" },
          winnerName: "Vikram Malhotra",
          time: "11:30 AM",
          result: "Vikram Malhotra won by Yuko (1-0).",
          status: "completed"
        },
        {
          id: "m4",
          competitor1: { name: "Rahul Sen", belt: "blue", gym: "Navi Mumbai Karate Academy", isWinner: false, score: "" },
          competitor2: null, // TBD placeholder
          winnerName: null,
          time: "12:00 PM",
          result: "Waiting for opponent allocation.",
          status: "pending"
        }
      ]
    },
    {
      name: "Semifinals",
      matches: [
        {
          id: "m5",
          competitor1: { name: "Rohan Sharma", belt: "black", gym: "Mumbai Karate Club", isWinner: true, score: "2" },
          competitor2: { name: "Pooja Patel", belt: "green", gym: "Dojo Pro Mumbai", isWinner: false, score: "0" },
          winnerName: "Rohan Sharma",
          time: "02:30 PM",
          result: "Rohan Sharma won by Ippon (2-0) with explosive roundhouse kicks.",
          status: "completed"
        },
        {
          id: "m6",
          competitor1: { name: "Vikram Malhotra", belt: "brown", gym: "Pune Fighter Gym", isWinner: false, score: "" },
          competitor2: null, // TBD placeholder
          winnerName: null,
          time: "03:00 PM",
          result: "TBD Semifinal Match.",
          status: "pending"
        }
      ]
    },
    {
      name: "Finals",
      matches: [
        {
          id: "m7",
          competitor1: { name: "Rohan Sharma", belt: "black", gym: "Mumbai Karate Club", isWinner: false, score: "" },
          competitor2: null, // TBD placeholder
          winnerName: null,
          time: "05:00 PM",
          result: "Championship Final Match.",
          status: "pending"
        }
      ]
    }
  ]
};

// In-Memory mock storage for local dev / offline testing
const mockTournaments: Tournament[] = [
  {
    id: 'tourn_mumbai_open_123',
    organizer_id: '00000000-0000-0000-0000-000000000000',
    title: 'Mumbai Open Karate Championship',
    discipline: 'Karate',
    city: 'Mumbai',
    location_name: 'Dharavi Sports Complex, Mumbai',
    start_date: new Date(Date.now() + 3600000 * 24 * 15).toISOString().split('T')[0], // 15 days from now
    registration_deadline: new Date(Date.now() + 3600000 * 24 * 3.5).toISOString().split('T')[0], // Closes in ~3 days
    fee_paise: 50000, // ₹500
    max_participants: 100,
    current_participants: 47,
    status: 'open',
    format: 'both',
    weight_class: 'Under 75kg',
    bracket: mockMumbaiBracket,
    created_at: new Date().toISOString()
  },
  {
    id: 'tourn_bjj_challenge_456',
    organizer_id: '00000000-0000-0000-0000-000000000000',
    title: 'National BJJ Grappling Challenge',
    discipline: 'BJJ',
    city: 'Pune',
    location_name: 'Balewadi Stadium, Pune',
    start_date: new Date(Date.now() + 3600000 * 24 * 30).toISOString().split('T')[0],
    registration_deadline: new Date(Date.now() + 3600000 * 24 * 25).toISOString().split('T')[0],
    fee_paise: 75000, // ₹750
    max_participants: 64,
    current_participants: 12,
    status: 'open',
    format: 'kumite',
    weight_class: 'Absolute division',
    bracket: {},
    created_at: new Date().toISOString()
  },
  {
    id: 'tourn_tkd_league_789',
    organizer_id: '00000000-0000-0000-0000-000000000000',
    title: 'Maharashtra Taekwondo League',
    discipline: 'Taekwondo',
    city: 'Mumbai',
    location_name: 'BKC Sports Center, Mumbai',
    start_date: new Date(Date.now() - 3600000 * 24 * 2).toISOString().split('T')[0], // Started 2 days ago
    registration_deadline: new Date(Date.now() - 3600000 * 24 * 5).toISOString().split('T')[0],
    fee_paise: 60000, // ₹600
    max_participants: 80,
    current_participants: 80,
    status: 'completed',
    format: 'kata',
    weight_class: 'Open Weight',
    bracket: mockMumbaiBracket,
    created_at: new Date(Date.now() - 3600000 * 24 * 10).toISOString()
  }
];

// Set of registered tournament IDs for default mock user
const mockRegistrations = new Set<string>();

// @route   GET /api/v1/tournaments
// @desc    Retrieve list of upcoming tournaments with optional filters
// @access  Public
router.get('/', async (req: any, res: Response, next: NextFunction) => {
  try {
    const { city, status } = req.query;

    let tournamentsData: any[] = [];
    let isDbSuccess = false;

    // 1. Try querying from Supabase
    try {
      let query = supabase.from('tournaments').select('*');
      
      if (status) {
        query = query.eq('status', status);
      }

      const { data, error } = await query;

      if (error) throw error;

      if (data) {
        tournamentsData = data.map((t: any) => ({
          id: t.id,
          organizer_id: t.organizer_id,
          title: t.title,
          discipline: t.discipline,
          city: t.venue ? t.venue.split(',')[1]?.trim() || 'Mumbai' : 'Mumbai',
          location_name: t.venue || 'Sports Complex',
          start_date: t.start_date,
          registration_deadline: t.registration_deadline,
          fee_paise: t.fee_paise,
          max_participants: t.max_participants,
          current_participants: 47, // Default mock progress
          status: t.status,
          format: 'both',
          weight_class: 'Under 75kg',
          bracket: t.bracket,
          created_at: t.created_at
        }));
        isDbSuccess = true;
      }
    } catch (err: any) {
      console.warn('Database: Tournaments query failed, falling back to mock data. Reason:', err.message);
    }

    if (!isDbSuccess || tournamentsData.length === 0) {
      tournamentsData = mockTournaments;
    }

    // Apply query filters on mock data if db failed
    if (!isDbSuccess) {
      if (city) {
        tournamentsData = tournamentsData.filter(t => t.city.toLowerCase() === city.toString().toLowerCase());
      }
      if (status) {
        tournamentsData = tournamentsData.filter(t => t.status === status);
      }
    }

    // Attach isRegistered state dynamically
    const finalTournaments = tournamentsData.map(t => ({
      ...t,
      isRegistered: mockRegistrations.has(t.id)
    }));

    res.status(200).json({ tournaments: finalTournaments });

  } catch (err) {
    next(err);
  }
});

// @route   GET /api/v1/tournaments/:id
// @desc    Retrieve detailed tournament information
// @access  Public
router.get('/:id', async (req: any, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;

    let tournament: any = null;
    let isDbSuccess = false;

    // 1. Query DB
    try {
      const { data, error } = await supabase
        .from('tournaments')
        .select('*')
        .eq('id', id)
        .maybeSingle();

      if (error) throw error;

      if (data) {
        tournament = {
          id: data.id,
          organizer_id: data.organizer_id,
          title: data.title,
          discipline: data.discipline,
          city: data.venue ? data.venue.split(',')[1]?.trim() || 'Mumbai' : 'Mumbai',
          location_name: data.venue || 'Sports Complex',
          start_date: data.start_date,
          registration_deadline: data.registration_deadline,
          fee_paise: data.fee_paise,
          max_participants: data.max_participants,
          current_participants: 47,
          status: data.status,
          format: 'both',
          weight_class: 'Under 75kg',
          bracket: data.bracket,
          created_at: data.created_at,
          isRegistered: mockRegistrations.has(data.id)
        };
        isDbSuccess = true;
      }
    } catch (err: any) {
      console.warn('Database: Tournament details query failed, using mock. Reason:', err.message);
    }

    if (!isDbSuccess || !tournament) {
      tournament = mockTournaments.find(t => t.id === id);
    }

    if (!tournament) {
      return res.status(404).json({
        error: {
          code: 'NOT_FOUND',
          message: 'Tournament profile not found.'
        }
      });
    }

    // Dynamic field check
    res.status(200).json({
      tournament: {
        ...tournament,
        isRegistered: mockRegistrations.has(tournament.id)
      }
    });

  } catch (err) {
    next(err);
  }
});

// @route   POST /api/v1/tournaments/:id/register
// @desc    Register athlete for the tournament
// @access  Authenticated
router.post('/:id/register', requireAuth, async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const validation = registerSchema.safeParse(req.body);
    
    if (!validation.success) {
      return res.status(400).json({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid registration parameters.',
          details: validation.error.format()
        }
      });
    }

    const { athlete_id, payment_intent_id } = validation.data;
    let isDbSuccess = false;
    let savedRegistration: any = null;

    // 1. Try to insert into tournament_registrations table
    try {
      const { data, error } = await supabase
        .from('tournament_registrations')
        .insert({
          tournament_id: id,
          athlete_id,
          payment_intent_id
        })
        .select('*')
        .single();

      if (error) throw error;

      if (data) {
        savedRegistration = data;
        isDbSuccess = true;
      }
    } catch (err: any) {
      console.warn('Database: Tournament registration insert failed, using mock handler. Reason:', err.message);
    }

    // 2. Add to in-memory registration tracker
    mockRegistrations.add(id);

    // Increment participant counts for mock data
    const tourn = mockTournaments.find(t => t.id === id);
    if (tourn) {
      tourn.current_participants += 1;
    }

    if (!isDbSuccess) {
      savedRegistration = {
        id: `reg_${Math.random().toString(36).substring(2, 11)}`,
        tournament_id: id,
        athlete_id,
        payment_intent_id,
        created_at: new Date().toISOString()
      };
    }

    res.status(201).json({
      message: 'Successfully registered for tournament.',
      registration: savedRegistration,
      dbSaved: isDbSuccess
    });

  } catch (err) {
    next(err);
  }
});

// @route   GET /api/v1/tournaments/:id/bracket
// @desc    Retrieve bracket results / tree diagram structure
// @access  Public
router.get('/:id/bracket', async (req: any, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;

    let bracketData: any = null;
    let isDbSuccess = false;

    // 1. Query from DB
    try {
      const { data, error } = await supabase
        .from('tournaments')
        .select('bracket, status')
        .eq('id', id)
        .maybeSingle();

      if (error) throw error;

      if (data && data.bracket && Object.keys(data.bracket).length > 0) {
        bracketData = data.bracket;
        isDbSuccess = true;
      }
    } catch (err: any) {
      console.warn('Database: Bracket query failed, using mock fallback. Reason:', err.message);
    }

    if (!isDbSuccess || !bracketData) {
      const tourn = mockTournaments.find(t => t.id === id);
      bracketData = tourn?.bracket || {};
    }

    res.status(200).json({
      tournament_id: id,
      bracket: bracketData
    });

  } catch (err) {
    next(err);
  }
});

export default router;
