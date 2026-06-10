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

// In-memory follow tracker for local demo / tests
const mockFollows = new Set<string>();

// Mock data structures
const mockVideos = [
  {
    id: 'vid_1',
    title: 'Shotokan Karate Kata Heian Shodan Demonstration',
    video_url: 'https://assets.mixkit.co/videos/preview/mixkit-martial-arts-trainer-practicing-karate-kicks-40334-large.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1555597673-b21d5c935865?w=500',
    discipline: 'Karate',
    created_at: new Date(Date.now() - 3600000 * 24 * 5).toISOString(),
    likesCount: 142,
    commentsCount: 24,
    isLiked: false
  },
  {
    id: 'vid_2',
    title: 'Kumite Sparring Session - Speed & Distance Drills',
    video_url: 'https://assets.mixkit.co/videos/preview/mixkit-woman-training-martial-arts-at-home-42289-large.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=500',
    discipline: 'Karate',
    created_at: new Date(Date.now() - 3600000 * 24 * 12).toISOString(),
    likesCount: 95,
    commentsCount: 12,
    isLiked: true
  },
  {
    id: 'vid_3',
    title: 'Mawashi Geri Form Check & Bag Work',
    video_url: 'https://assets.mixkit.co/videos/preview/mixkit-martial-arts-trainer-practicing-karate-kicks-40334-large.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1555597673-b21d5c935865?w=500',
    discipline: 'Karate',
    created_at: new Date(Date.now() - 3600000 * 24 * 20).toISOString(),
    likesCount: 64,
    commentsCount: 8,
    isLiked: false
  }
];

const mockBadges = [
  { id: 'badge_founding', title: 'Founding Member', icon: 'star', earnedDate: '2026-01-10', description: 'Founding Member of DojoPro community' },
  { id: 'badge_verified', title: 'Verified Athlete', icon: 'shield_check', earnedDate: '2026-02-15', description: 'Verified belt credentials' },
  { id: 'badge_champion', title: 'Tournament Champion', icon: 'trophy', earnedDate: '2026-03-20', description: 'Won a division in Mumbai Open' },
  { id: 'badge_sessions_100', title: '100 Sessions', icon: 'flame', earnedDate: '2026-04-05', description: 'Completed 100 training sessions' },
  { id: 'badge_creator', title: 'Kata Creator', icon: 'video', earnedDate: '2026-05-12', description: 'Uploaded first technique video' }
];

const mockTimeline = [
  { id: 't1', level: 'white', title: 'White Belt', earnedDate: '2024-01-15', verified: true },
  { id: 't2', level: 'yellow', title: 'Yellow Belt', earnedDate: '2024-06-10', verified: true },
  { id: 't3', level: 'green', title: 'Green Belt', earnedDate: '2024-12-05', verified: true },
  { id: 't4', level: 'blue', title: 'Blue Belt', earnedDate: '2025-05-20', verified: true },
  { id: 't5', level: 'brown', title: 'Brown Belt', earnedDate: '2025-11-10', verified: true, isCurrent: true }
];

// @route   GET /api/v1/users/:id
// @desc    Fetch user profile details + stats
// @access  Authenticated
router.get('/:id', requireAuth, async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;

    // Fetch user details from public.users table
    let user: any = null;
    try {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('id', id)
        .single();
      if (!error && data) {
        user = data;
      }
    } catch (_) {
      // Fallback below if db is not connected
    }

    if (!user) {
      // Return a robust mock user for Arjun Mehta if user ID is Arjun's mock or fallback
      user = {
        id: id,
        email: 'arjun@dojopro.com',
        role: 'athlete',
        belt_level: 'brown',
        discipline: 'Karate',
        verified: true,
        display_name: 'ARJUN MEHTA',
        avatar_url: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        bio: 'Recreational karate athlete training 4x/week at Bandra Dojo. Specializing in kumite sparring, active competition formats, and kata forms.'
      };
    }

    const currentUserId = req.user?.id || '00000000-0000-0000-0000-000000000000';
    const isFollowing = mockFollows.has(`${currentUserId}:${id}`);
    const followersCount = 120 + (isFollowing ? 1 : 0);

    const stats = {
      sessions: 142,
      wins: 3,
      certs: 2,
      followersCount,
      followingCount: 84,
      isFollowing
    };

    res.status(200).json({ user, stats });
  } catch (err) {
    next(err);
  }
});

// @route   GET /api/v1/users/:id/videos
// @desc    Fetch user's uploaded videos (posts)
// @access  Authenticated
router.get('/:id/videos', requireAuth, async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    let videos: any[] = [];
    
    try {
      const { data, error } = await supabase
        .from('posts')
        .select('*')
        .eq('user_id', id)
        .order('created_at', { ascending: false });
      if (!error && data && data.length > 0) {
        videos = data.map(p => ({
          id: p.id,
          user_id: p.user_id,
          title: p.title,
          video_url: p.video_url,
          thumbnail_url: p.thumbnail_url,
          discipline: p.discipline,
          created_at: p.created_at,
          likesCount: 12,
          commentsCount: 2,
          isLiked: false
        }));
      }
    } catch (_) {
      // Fail silently to local mock fallback
    }

    if (videos.length === 0) {
      videos = mockVideos.map(v => ({ ...v, user_id: id }));
    }

    res.status(200).json({ videos });
  } catch (err) {
    next(err);
  }
});

// @route   GET /api/v1/users/:id/badges
// @desc    Fetch user's trophies/badges
// @access  Authenticated
router.get('/:id/badges', requireAuth, async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    res.status(200).json({ badges: mockBadges });
  } catch (err) {
    next(err);
  }
});

// @route   GET /api/v1/users/:id/belt-timeline
// @desc    Fetch user's rank belt timeline
// @access  Authenticated
router.get('/:id/belt-timeline', requireAuth, async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    res.status(200).json({ timeline: mockTimeline });
  } catch (err) {
    next(err);
  }
});

// @route   POST /api/v1/users/:id/follow
// @desc    Toggle follow status for a user
// @access  Authenticated
router.post('/:id/follow', requireAuth, async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const currentUserId = req.user?.id || '00000000-0000-0000-0000-000000000000';
    const key = `${currentUserId}:${id}`;
    let isFollowing = false;

    if (mockFollows.has(key)) {
      mockFollows.delete(key);
    } else {
      mockFollows.add(key);
      isFollowing = true;
    }

    const followersCount = 120 + (isFollowing ? 1 : 0);
    res.status(200).json({
      message: isFollowing ? 'Followed successfully' : 'Unfollowed successfully',
      isFollowing,
      followersCount
    });
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
