import { Router, Response, NextFunction } from 'express';
import { z } from 'zod';
import { supabase } from '../index';
import { requireAuth } from '../middleware/auth.middleware';
import { AuthenticatedRequest } from '../types';

const router = Router();

// Zod schema for profile updates
const updateProfileSchema = z.object({
  displayName: z.string().min(2).optional(),
  bio: z.string().max(1000).optional(),
  beltLevel: z.string().optional(),
  discipline: z.string().optional(),
  avatarUrl: z.string().url().optional(),
  location: z.object({
    lat: z.number().min(-90).max(90),
    lng: z.number().min(-180).max(180)
  }).optional()
});

// @route   GET /api/v1/users/:id
// @desc    Fetch user profile details
// @access  Authenticated
router.get('/:id', requireAuth, async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;

    // Fetch user details from public.users table
    const { data: user, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', id)
      .single();

    if (error || !user) {
      return res.status(404).json({
        error: {
          code: 'USER_NOT_FOUND',
          message: 'The requested user profile was not found.'
        }
      });
    }

    res.status(200).json({ user });
  } catch (err) {
    next(err);
  }
});

// @route   PUT /api/v1/users/:id
// @desc    Update user profile details
// @access  Owner
router.put('/:id', requireAuth, async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;

    // Authorization check: Make sure current user is updating their own profile
    if (req.user?.id !== id) {
      return res.status(403).json({
        error: {
          code: 'FORBIDDEN',
          message: 'You are not authorized to update this profile.'
        }
      });
    }

    // Input Validation
    const validation = updateProfileSchema.safeParse(req.body);
    if (!validation.success) {
      return res.status(400).json({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid profile details.',
          details: validation.error.format()
        }
      });
    }

    const { displayName, bio, beltLevel, discipline, avatarUrl, location } = validation.data;

    // Prepare database update payload
    const updatePayload: any = {};
    if (displayName !== undefined) updatePayload.display_name = displayName;
    if (bio !== undefined) updatePayload.bio = bio;
    if (beltLevel !== undefined) updatePayload.belt_level = beltLevel;
    if (discipline !== undefined) updatePayload.discipline = discipline;
    if (avatarUrl !== undefined) updatePayload.avatar_url = avatarUrl;
    
    // Convert lat/lng to PostGIS Point format if provided
    if (location !== undefined) {
      updatePayload.location = `POINT(${location.lng} ${location.lat})`;
    }

    const { data: updatedUser, error } = await supabase
      .from('users')
      .update(updatePayload)
      .eq('id', id)
      .select('*')
      .single();

    if (error) {
      return res.status(500).json({
        error: {
          code: 'UPDATE_FAILED',
          message: error.message
        }
      });
    }

    res.status(200).json({
      message: 'Profile updated successfully',
      user: updatedUser
    });
  } catch (err) {
    next(err);
  }
});

export default router;
