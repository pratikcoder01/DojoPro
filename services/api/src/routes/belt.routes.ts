import { Router, Response, NextFunction } from 'express';
import { z } from 'zod';
import { supabase } from '../index';
import { requireAuth } from '../middleware/auth.middleware';
import { AuthenticatedRequest } from '../types';

const router = Router();

// Zod validation for belt verification submission
const verifyBeltSchema = z.object({
  discipline: z.string().min(2),
  level: z.string().min(2),
  video_url: z.string().url().optional().or(z.literal('')),
  certificate_url: z.string().url().optional().or(z.literal('')),
  gym_id: z.string().optional()
});

interface BeltVerification {
  id: string;
  user_id: string;
  discipline: string;
  level: string;
  certificate_url: string;
  video_url: string;
  verifier_id: string;
  status: 'pending' | 'approved' | 'rejected';
  issued_at: string | null;
  created_at: string;
}

// In-Memory mock storage for local test stability
const mockVerifications: BeltVerification[] = [
  {
    id: 'bv_001',
    user_id: '00000000-0000-0000-0000-000000000000',
    discipline: 'Karate',
    level: 'brown',
    certificate_url: 'https://images.unsplash.com/photo-1555597673-b21d5c935865?w=500',
    video_url: 'https://assets.mixkit.co/videos/preview/mixkit-martial-arts-trainer-practicing-karate-kicks-40334-large.mp4',
    verifier_id: 'gym_001',
    status: 'approved',
    issued_at: new Date(Date.now() - 3600000 * 24 * 30).toISOString(), // 30 days ago
    created_at: new Date(Date.now() - 3600000 * 24 * 35).toISOString()
  }
];

// @route   POST /api/v1/belts/verify
// @desc    Submit a new belt verification request
// @access  Authenticated
router.post('/verify', requireAuth, async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const validation = verifyBeltSchema.safeParse(req.body);
    if (!validation.success) {
      return res.status(400).json({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid verification parameters.',
          details: validation.error.format()
        }
      });
    }

    const { discipline, level, video_url, certificate_url, gym_id } = validation.data;
    const userId = req.user?.id || '00000000-0000-0000-0000-000000000000';
    const verificationId = `bv_${Math.random().toString(36).substring(2, 11)}`;

    let isDbSuccess = false;
    let savedVerification: any = null;

    // 1. Try saving in Supabase database
    try {
      const { data, error } = await supabase
        .from('belt_verifications')
        .insert({
          user_id: userId,
          discipline,
          level,
          certificate_url: certificate_url || video_url || '',
          verifier_id: gym_id || null,
          status: 'pending'
        })
        .select('*')
        .single();

      if (error) {
        throw error;
      }

      if (data) {
        savedVerification = data;
        isDbSuccess = true;
      }
    } catch (err: any) {
      console.warn('Database: Belt verification insert failed, falling back to mock response. Reason:', err.message);
    }

    // 2. Fallback to mock memory storage
    if (!isDbSuccess) {
      const newMockVerification: BeltVerification = {
        id: verificationId,
        user_id: userId,
        discipline,
        level,
        certificate_url: certificate_url || '',
        video_url: video_url || '',
        verifier_id: gym_id || 'gym_001',
        status: 'pending',
        issued_at: null,
        created_at: new Date().toISOString()
      };

      mockVerifications.push(newMockVerification);
      savedVerification = newMockVerification;
    }

    // 3. Return response
    res.status(201).json({
      message: 'Verification request submitted successfully.',
      verification: savedVerification,
      dbSaved: isDbSuccess
    });

  } catch (err) {
    next(err);
  }
});

// @route   GET /api/v1/belts/verifications/:userId
// @desc    Retrieve all belt verification requests for a specific user
// @access  Public / Authenticated
router.get('/verifications/:userId', async (req: any, res: Response, next: NextFunction) => {
  try {
    const { userId } = req.params;

    let verifications: any[] = [];
    let isDbSuccess = false;

    // 1. Try query Supabase database
    try {
      const { data, error } = await supabase
        .from('belt_verifications')
        .select('*')
        .eq('user_id', userId);

      if (error) {
        throw error;
      }

      if (data) {
        verifications = data;
        isDbSuccess = true;
      }
    } catch (err: any) {
      console.warn('Database: Belt verifications query failed, using mock data. Reason:', err.message);
    }

    // 2. Fallback to memory
    if (!isDbSuccess) {
      verifications = mockVerifications.filter(v => v.user_id === userId);
    }

    res.status(200).json({
      verifications
    });

  } catch (err) {
    next(err);
  }
});

export default router;
