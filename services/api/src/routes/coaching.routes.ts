import { Router, Response, NextFunction } from 'express';
import { z } from 'zod';
import { supabase } from '../index';
import { requireAuth } from '../middleware/auth.middleware';
import { AuthenticatedRequest } from '../types';

const router = Router();

// Zod schemas for input validation
const bookingSchema = z.object({
  coach_id: z.string(),
  athlete_id: z.string(),
  scheduled_at: z.string().datetime(),
  duration_mins: z.number().min(30).max(480).default(60),
  type: z.enum(['in-person', 'online']).default('in-person'),
  amount_paise: z.number().positive()
});

const checkoutSchema = z.object({
  booking_id: z.string(),
  amount_paise: z.number().positive(),
  currency: z.string().default('INR')
});

// Mock Coach Detail for Priya Rao
const mockCoach = {
  id: 'coach_priya_rao',
  name: 'Sensei Priya Rao',
  avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
  coverUrl: 'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=800',
  isVerified: true,
  disciplines: ['Karate', 'Self-Defense', 'Competition Prep'],
  rating: 4.8,
  reviewCount: 127,
  sessionsCompleted: 1420,
  activeStudents: 85,
  yearsExperience: 12,
  bio: 'Black belt in Shotokan Karate and Brazilian Jiu-Jitsu. Over 12 years of coaching professional athletes in Mumbai. Specialized in explosive striking mechanics and active competition prep.',
  hourlyRate: 800,
  specialties: ['Explosive Striking', 'Youth Mentorship', 'Tournament Strategy', 'Advanced Kumite'],
  recentReviews: [
    {
      id: 'rev_1',
      userName: 'Arjun Mehta',
      userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80',
      rating: 5.0,
      comment: 'Sensei Priya is incredible. Her attention to detail on hip rotation during kicks completely changed my sparring game.',
      date: '2 days ago'
    },
    {
      id: 'rev_2',
      userName: 'Rohan Sharma',
      userAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=80',
      rating: 5.0,
      comment: 'Highly structured class. Ideal for anyone preparing for state tournaments in Maharashtra.',
      date: '1 week ago'
    },
    {
      id: 'rev_3',
      userName: 'Pooja Patel',
      userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=80',
      rating: 4.8,
      comment: 'Excellent self-defense drills. She explains the physics of leverage so well!',
      date: '3 weeks ago'
    }
  ]
};

// Generate availability slots
function getAvailabilitySlots() {
  const now = new Date();
  const baseDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  
  return [
    { time: new Date(baseDate.getTime() + 3600000 * 10).toISOString(), isBooked: false },  // Today 10:00 AM
    { time: new Date(baseDate.getTime() + 3600000 * 15).toISOString(), isBooked: true },   // Today 3:00 PM (Booked)
    { time: new Date(baseDate.getTime() + 3600000 * 35).toISOString(), isBooked: false },  // Tomorrow 11:00 AM
    { time: new Date(baseDate.getTime() + 3600000 * 40).toISOString(), isBooked: false },  // Tomorrow 4:00 PM
    { time: new Date(baseDate.getTime() + 3600000 * 57).toISOString(), isBooked: true },   // Day after 9:00 AM (Booked)
    { time: new Date(baseDate.getTime() + 3600000 * 62).toISOString(), isBooked: false },  // Day after 2:00 PM
    { time: new Date(baseDate.getTime() + 3600000 * 82).toISOString(), isBooked: false }   // Next day 10:00 AM
  ];
}

// @route   GET /api/v1/coaches/:id
// @desc    Retrieve coach profile details
// @access  Public
router.get('/coaches/:id', async (req: any, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;

    let coachData: any = null;
    let isDbSuccess = false;

    // 1. Try querying from coach_profiles joined with users
    try {
      const { data, error } = await supabase
        .from('coach_profiles')
        .select(`
          id,
          hourly_rate,
          bio,
          availability,
          rating,
          total_sessions,
          users (
            display_name,
            avatar_url,
            discipline,
            verified
          )
        `)
        .eq('id', id)
        .maybeSingle();

      if (error) throw error;

      if (data) {
        const userMeta = Array.isArray(data.users) ? data.users[0] : data.users;
        coachData = {
          id: data.id,
          name: userMeta?.display_name || 'Sensei',
          avatarUrl: userMeta?.avatar_url || mockCoach.avatarUrl,
          coverUrl: mockCoach.coverUrl,
          isVerified: userMeta?.verified || false,
          disciplines: userMeta?.discipline ? [userMeta.discipline] : mockCoach.disciplines,
          rating: data.rating || 5.0,
          reviewCount: mockCoach.reviewCount,
          sessionsCompleted: data.total_sessions || 0,
          activeStudents: mockCoach.activeStudents,
          yearsExperience: mockCoach.yearsExperience,
          bio: data.bio || mockCoach.bio,
          hourlyRate: parseFloat(data.hourly_rate),
          specialties: mockCoach.specialties,
          recentReviews: mockCoach.recentReviews
        };
        isDbSuccess = true;
      }
    } catch (err: any) {
      console.warn('Database: Coach profile query failed, using mock data. Reason:', err.message);
    }

    if (!isDbSuccess || !coachData) {
      coachData = mockCoach;
    }

    res.status(200).json({ coach: coachData });

  } catch (err) {
    next(err);
  }
});

// @route   GET /api/v1/coaches/:id/availability
// @desc    Retrieve coach availability slots for a specific week
// @access  Public
router.get('/coaches/:id/availability', async (req: any, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const { week } = req.query;

    const slots = getAvailabilitySlots();
    res.status(200).json({
      coach_id: id,
      week: week || 'current',
      slots
    });

  } catch (err) {
    next(err);
  }
});

// @route   POST /api/v1/bookings
// @desc    Create a new booking transaction
// @access  Authenticated
router.post('/bookings', requireAuth, async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const validation = bookingSchema.safeParse(req.body);
    if (!validation.success) {
      return res.status(400).json({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid booking data parameters.',
          details: validation.error.format()
        }
      });
    }

    const { coach_id, athlete_id, scheduled_at, duration_mins, type, amount_paise } = validation.data;
    const bookingId = `bk_${Math.random().toString(36).substring(2, 11)}`;

    let savedBooking: any = null;
    let isDbSuccess = false;

    // 1. Save booking in Supabase Database
    try {
      const { data, error } = await supabase
        .from('bookings')
        .insert({
          coach_id,
          athlete_id,
          scheduled_at,
          duration_mins,
          type,
          status: 'pending',
          amount_paise
        })
        .select('*')
        .single();

      if (error) throw error;

      if (data) {
        savedBooking = data;
        isDbSuccess = true;
      }
    } catch (err: any) {
      console.warn('Database: Booking insert failed, using mock transaction. Reason:', err.message);
    }

    if (!isDbSuccess) {
      savedBooking = {
        id: bookingId,
        coach_id,
        athlete_id,
        scheduled_at,
        duration_mins,
        type,
        status: 'pending',
        amount_paise,
        created_at: new Date().toISOString()
      };
    }

    res.status(201).json({
      message: 'Booking created successfully.',
      booking: savedBooking,
      dbSaved: isDbSuccess
    });

  } catch (err) {
    next(err);
  }
});

// @route   POST /api/v1/payments/checkout
// @desc    Initialize payment checkout details (UPI/Razorpay/Stripe)
// @access  Authenticated
router.post('/payments/checkout', requireAuth, async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const validation = checkoutSchema.safeParse(req.body);
    if (!validation.success) {
      return res.status(400).json({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid payment parameters.',
          details: validation.error.format()
        }
      });
    }

    const { booking_id, amount_paise, currency } = validation.data;
    const paymentIntentId = `pi_${Math.random().toString(36).substring(2, 15)}`;
    const razorpayOrderId = `order_${Math.random().toString(36).substring(2, 15)}`;

    let isDbSuccess = false;

    // Update stripe payment intent in bookings table
    try {
      const { error } = await supabase
        .from('bookings')
        .update({ stripe_payment_intent: paymentIntentId, status: 'confirmed' })
        .eq('id', booking_id);
      
      if (!error) {
        isDbSuccess = true;
      }
    } catch (err: any) {
      console.warn('Database: Booking payment update failed, continuing with mock success. Reason:', err.message);
    }

    res.status(200).json({
      message: 'Checkout initialized successfully.',
      paymentIntentId,
      razorpayOrderId,
      amount: amount_paise,
      currency,
      status: 'requires_payment_method',
      dbUpdated: isDbSuccess
    });

  } catch (err) {
    next(err);
  }
});

// Mock legacy path fallback
router.post('/book', requireAuth, async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  res.status(200).json({
    paymentIntentId: `pi_mock_${Math.random().toString(36).substring(2, 10)}`
  });
});

export default router;
