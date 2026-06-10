import { Router, Response, NextFunction } from 'express';
import { z } from 'zod';
import { requireAuth } from '../middleware/auth.middleware';
import { AuthenticatedRequest } from '../types';

const router = Router();

const challengeSchema = z.object({
  challenger_id: z.string(),
  target_id: z.string(),
});

// @route   POST /api/v1/sparring/challenge
// @desc    Issue a sparring challenge to another athlete
// @access  Authenticated
router.post('/challenge', requireAuth, async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const validation = challengeSchema.safeParse(req.body);
    if (!validation.success) {
      return res.status(400).json({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid sparring challenge parameters.',
          details: validation.error.format(),
        },
      });
    }

    const { challenger_id, target_id } = validation.data;

    // Simulate database insertion and returns success response
    const challenge = {
      id: `chal_${Math.random().toString(36).substring(2, 11)}`,
      challenger_id,
      target_id,
      status: 'pending',
      created_at: new Date().toISOString(),
    };

    res.status(201).json({
      message: 'Sparring challenge issued successfully.',
      challenge,
    });
  } catch (err) {
    next(err);
  }
});

export default router;
