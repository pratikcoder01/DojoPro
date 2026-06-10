import { Router, Response, NextFunction } from 'express';
import { z } from 'zod';
import { supabase } from '../index';

const router = Router();

// Zod validation for gym discovery search query
const gymQuerySchema = z.object({
  lat: z.preprocess((val) => parseFloat(val as string), z.number().min(-90).max(90)),
  lng: z.preprocess((val) => parseFloat(val as string), z.number().min(-180).max(180)),
  radius: z.preprocess((val) => parseFloat(val as string), z.number().positive().default(10)),
  style: z.string().optional(),
  maxDistance: z.preprocess((val) => parseFloat(val as string), z.number().positive().optional()),
  openNow: z.preprocess((val) => val === 'true', z.boolean().optional()),
  minRating: z.preprocess((val) => parseFloat(val as string), z.number().min(1).max(5).optional())
});

interface Gym {
  id: string;
  name: string;
  styles: string[];
  lat: number;
  lng: number;
  rating: number;
  isOpen: boolean;
  photos: string[];
  coaches: string[];
  schedule: string[];
}

// Mock database of premium martial arts gyms in Mumbai
const mockGyms: Gym[] = [
  {
    id: 'gym_001',
    name: 'Dharavi MMA & BJJ Academy',
    styles: ['BJJ', 'MMA'],
    lat: 19.0380,
    lng: 72.8538,
    rating: 4.8,
    isOpen: true,
    photos: [
      'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=800',
      'https://images.unsplash.com/photo-1555597673-b21d5c935865?w=800',
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=800'
    ],
    coaches: ['Sensei Priya Rao', 'Coach Vikram Singh'],
    schedule: [
      'Mon - Fri: 7:00 AM - 9:00 PM',
      'Sat: 8:00 AM - 12:00 PM',
      'Sun: Closed'
    ]
  },
  {
    id: 'gym_002',
    name: 'Bandra Striking & Karate Dojo',
    styles: ['Karate', 'Self-Defense'],
    lat: 19.0596,
    lng: 72.8295,
    rating: 4.6,
    isOpen: true,
    photos: [
      'https://images.unsplash.com/photo-1555597673-b21d5c935865?w=800',
      'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=800'
    ],
    coaches: ['Sensei Priya Rao'],
    schedule: [
      'Mon - Wed - Fri: 6:00 AM - 8:00 PM',
      'Tue - Thu: 4:00 PM - 9:00 PM',
      'Sat: 9:00 AM - 1:00 PM'
    ]
  },
  {
    id: 'gym_003',
    name: 'Colaba Judo & Wrestling Center',
    styles: ['Judo', 'Wrestling'],
    lat: 18.9067,
    lng: 72.8147,
    rating: 4.9,
    isOpen: false,
    photos: [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800',
      'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=800'
    ],
    coaches: ['Anita Desai'],
    schedule: [
      'Tue - Thu - Sat: 8:00 AM - 10:00 PM',
      'Mon - Wed: Closed'
    ]
  },
  {
    id: 'gym_004',
    name: 'Andheri Fight Club (MMA)',
    styles: ['MMA', 'Muay Thai'],
    lat: 19.1136,
    lng: 72.8697,
    rating: 4.7,
    isOpen: true,
    photos: [
      'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=800',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800'
    ],
    coaches: ['Coach Vikram Singh'],
    schedule: [
      'Mon - Sat: 6:00 AM - 11:00 PM',
      'Sun: 9:00 AM - 5:00 PM'
    ]
  },
  {
    id: 'gym_005',
    name: 'Juhu Beach Karate Academy',
    styles: ['Karate'],
    lat: 19.0988,
    lng: 72.8264,
    rating: 4.2,
    isOpen: true,
    photos: [
      'https://images.unsplash.com/photo-1555597673-b21d5c935865?w=800'
    ],
    coaches: ['Arjun Mehta'],
    schedule: [
      'Mon - Sun: 5:00 AM - 9:00 AM'
    ]
  }
];

// Haversine formula to compute distance in km
function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371; // Earth radius in km
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return parseFloat((R * c).toFixed(1));
}

// @route   GET /api/v1/gyms/nearby
// @desc    Retrieve nearby gyms based on location and optional style filters
// @access  Public
router.get('/nearby', async (req: any, res: Response, next: NextFunction) => {
  try {
    const validation = gymQuerySchema.safeParse(req.query);
    if (!validation.success) {
      return res.status(400).json({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid coordinates or search parameters.',
          details: validation.error.format()
        }
      });
    }

    const { lat, lng, radius, style, maxDistance, openNow, minRating } = validation.data;

    let gymsWithDistance = mockGyms.map(gym => {
      const distance = calculateDistance(lat, lng, gym.lat, gym.lng);
      return {
        ...gym,
        distance_km: distance
      };
    });

    // 1. Filter by radius limit
    gymsWithDistance = gymsWithDistance.filter(gym => gym.distance_km <= radius);

    // 2. Filter by style (if provided)
    if (style && style !== 'All Styles') {
      gymsWithDistance = gymsWithDistance.filter(gym => 
        gym.styles.some(s => s.toLowerCase() === style.toLowerCase())
      );
    }

    // 3. Filter by maxDistance helper (< 5km chip)
    if (maxDistance) {
      gymsWithDistance = gymsWithDistance.filter(gym => gym.distance_km < maxDistance);
    }

    // 4. Filter by open status (Open Now)
    if (openNow) {
      gymsWithDistance = gymsWithDistance.filter(gym => gym.isOpen);
    }

    // 5. Filter by rating threshold (4★+)
    if (minRating) {
      gymsWithDistance = gymsWithDistance.filter(gym => gym.rating >= minRating);
    }

    // Sort by distance (closest first)
    gymsWithDistance.sort((a, b) => a.distance_km - b.distance_km);

    res.status(200).json({
      gyms: gymsWithDistance
    });

  } catch (err) {
    next(err);
  }
});

export default router;
