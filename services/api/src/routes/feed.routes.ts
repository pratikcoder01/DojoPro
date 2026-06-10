import { Router, Response, NextFunction } from 'express';
import { z } from 'zod';
import { supabase } from '../index';
import { requireAuth } from '../middleware/auth.middleware';
import { AuthenticatedRequest } from '../types';
import redis from '../redis';

const router = Router();

// Zod schema for feed request validation
const feedQuerySchema = z.object({
  limit: z.preprocess((val) => parseInt(val as string, 10), z.number().min(1).max(50).default(10)),
  cursor: z.string().optional()
});

// In-Memory fallback database for local execution & offline testing
interface MockPost {
  id: string;
  user_id: string;
  title: string;
  video_url: string;
  thumbnail_url: string;
  discipline: string;
  created_at: string;
  likes_count: number;
  comments_count: number;
  display_name: string;
  belt_level: string;
}

const mockPosts: MockPost[] = [
  {
    id: 'post_1001',
    user_id: '00000000-0000-0000-0000-000000000000',
    title: 'Shotokan Karate Mawashi Geri Form Check',
    video_url: 'https://assets.mixkit.co/videos/preview/mixkit-martial-arts-trainer-practicing-karate-kicks-40334-large.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1555597673-b21d5c935865?w=500',
    discipline: 'Karate',
    created_at: new Date(Date.now() - 3600000 * 2).toISOString(), // 2 hours ago
    likes_count: 142,
    comments_count: 24,
    display_name: 'Arjun Mehta',
    belt_level: 'brown'
  },
  {
    id: 'post_1002',
    user_id: '11111111-1111-1111-1111-111111111111',
    title: 'Closed Guard Sweeps & Armbar Transitions',
    video_url: 'https://assets.mixkit.co/videos/preview/mixkit-woman-training-martial-arts-at-home-42289-large.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=500',
    discipline: 'BJJ',
    created_at: new Date(Date.now() - 3600000 * 5).toISOString(), // 5 hours ago
    likes_count: 389,
    comments_count: 57,
    display_name: 'Sensei Priya Rao',
    belt_level: 'black'
  },
  {
    id: 'post_1003',
    user_id: '22222222-2222-2222-2222-222222222222',
    title: 'Explosive 540 Kick Tutorial',
    video_url: 'https://assets.mixkit.co/videos/preview/mixkit-martial-arts-trainer-practicing-karate-kicks-40334-large.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=500',
    discipline: 'Taekwondo',
    created_at: new Date(Date.now() - 3600000 * 12).toISOString(), // 12 hours ago
    likes_count: 89,
    comments_count: 12,
    display_name: 'Rohan Sharma',
    belt_level: 'blue'
  },
  {
    id: 'post_1004',
    user_id: '33333333-3333-3333-3333-333333333333',
    title: 'Heavy Bag Combos in Mumbai Gym',
    video_url: 'https://assets.mixkit.co/videos/preview/mixkit-woman-training-martial-arts-at-home-42289-large.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1555597673-b21d5c935865?w=500',
    discipline: 'Muay Thai',
    created_at: new Date(Date.now() - 3600000 * 24).toISOString(), // 1 day ago
    likes_count: 231,
    comments_count: 45,
    display_name: 'Vikram Singh',
    belt_level: 'black'
  },
  {
    id: 'post_1005',
    user_id: '44444444-4444-4444-4444-444444444444',
    title: 'Seoi Nage Throw Breakdown',
    video_url: 'https://assets.mixkit.co/videos/preview/mixkit-martial-arts-trainer-practicing-karate-kicks-40334-large.mp4',
    thumbnail_url: 'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=500',
    discipline: 'Judo',
    created_at: new Date(Date.now() - 3600000 * 48).toISOString(), // 2 days ago
    likes_count: 104,
    comments_count: 18,
    display_name: 'Anita Desai',
    belt_level: 'green'
  }
];

// Set tracking liked posts in-memory: 'userId:postId'
const mockLikes = new Set<string>();

// Pre-populate mockLikes so Sensei Priya Rao's post shows as liked by default for mock users
mockLikes.add('00000000-0000-0000-0000-000000000000:post_1002');

// Helper to invalidate feed cache keys in Redis
async function invalidateFeedCache(): Promise<void> {
  try {
    const keys = await redis.keys('feed:limit:*');
    if (keys.length > 0) {
      await redis.del(...keys);
      console.log(`Redis: Invalidated ${keys.length} feed cache keys.`);
    }
  } catch (err: any) {
    console.warn('Redis: Failed to invalidate cache:', err.message);
  }
}

// @route   GET /api/v1/feed
// @desc    Retrieve Home Video Feed with cursor-based pagination and Redis caching
// @access  Public / Optional Auth
router.get('/', async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    // 1. Validate Query Params
    const validation = feedQuerySchema.safeParse(req.query);
    if (!validation.success) {
      return res.status(400).json({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid query parameters.',
          details: validation.error.format()
        }
      });
    }

    const { limit, cursor } = validation.data;

    // 2. Resolve Authenticated User ID if Bearer Token is present
    let currentUserId: string | null = null;
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      try {
        const { data: { user } } = await supabase.auth.getUser(token);
        if (user) {
          currentUserId = user.id;
        }
      } catch (err) {
        // Continue as anonymous if token validation fails
        console.warn('Feed: Optional token validation failed, serving public feed.');
      }
    }

    // 3. Try Redis Cache (Shared feed list without user-specific `is_liked`)
    const cacheKey = `feed:limit:${limit}:cursor:${cursor || 'none'}`;
    let cachedFeedRaw: string | null = null;

    try {
      cachedFeedRaw = await redis.get(cacheKey);
    } catch (err: any) {
      console.warn('Redis: Read failed, bypassing cache:', err.message);
    }

    if (cachedFeedRaw) {
      console.log('Redis: Serving feed from cache.');
      const cachedData = JSON.parse(cachedFeedRaw);
      
      // Inject user-specific is_liked flag dynamically
      const postsWithLikeStatus = await injectLikesAndUserMeta(cachedData.posts, currentUserId);
      return res.status(200).json({
        posts: postsWithLikeStatus,
        nextCursor: cachedData.nextCursor
      });
    }

    // 4. Fetch Feed Data (Database with in-memory fallback)
    let posts: any[] = [];
    let nextCursor: string | null = null;
    let isDbSuccess = false;

    try {
      // Step A: Translate cursor to timestamp if pagination requested
      let cursorTimestamp: string | null = null;
      if (cursor) {
        const { data: cursorPost } = await supabase
          .from('posts')
          .select('created_at')
          .eq('id', cursor)
          .single();
        if (cursorPost) {
          cursorTimestamp = cursorPost.created_at;
        }
      }

      // Step B: Build Supabase Query (Fetch limit + 1 to check if there is a next page)
      let dbQuery = supabase
        .from('posts')
        .select(`
          id,
          title,
          video_url,
          thumbnail_url,
          discipline,
          created_at,
          user_id,
          users (
            display_name,
            belt_level
          )
        `)
        .order('created_at', { ascending: false })
        .order('id', { ascending: false })
        .limit(limit + 1);

      if (cursorTimestamp) {
        dbQuery = dbQuery.lt('created_at', cursorTimestamp);
      }

      const { data: dbPosts, error: dbError } = await dbQuery;

      if (dbError) {
        throw dbError;
      }

      if (dbPosts) {
        isDbSuccess = true;
        
        // Determine pagination next cursor
        const hasNextPage = dbPosts.length > limit;
        const pagePosts = hasNextPage ? dbPosts.slice(0, limit) : dbPosts;
        nextCursor = hasNextPage ? pagePosts[pagePosts.length - 1].id : null;

        // Fetch likes count via batch grouping
        const postIds = pagePosts.map(p => p.id);
        const { data: likesData } = await supabase
          .from('post_likes')
          .select('post_id')
          .in('post_id', postIds);

        const likesCountMap: { [id: string]: number } = {};
        postIds.forEach(id => { likesCountMap[id] = 0; });
        if (likesData) {
          likesData.forEach(like => {
            if (likesCountMap[like.post_id] !== undefined) {
              likesCountMap[like.post_id]++;
            }
          });
        }

        posts = pagePosts.map((p: any) => {
          const userProfile = Array.isArray(p.users) ? p.users[0] : p.users;
          return {
            id: p.id,
            display_name: userProfile?.display_name || 'Anonymous',
            belt_level: userProfile?.belt_level || 'White',
            discipline: p.discipline || 'Martial Arts',
            title: p.title,
            video_url: p.video_url,
            thumbnail_url: p.thumbnail_url,
            likes_count: likesCountMap[p.id] || 0,
            comments_count: 5 // Default simulated count for Phase 1
          };
        });
      }
    } catch (dbErr: any) {
      console.warn('Database: Feed query failed, falling back to mock database. Reason:', dbErr.message);
    }

    // fallback to Mock Database if DB is unconfigured or errors out
    if (!isDbSuccess) {
      let startIndex = 0;
      if (cursor) {
        const idx = mockPosts.findIndex(p => p.id === cursor);
        if (idx !== -1) {
          startIndex = idx + 1;
        }
      }

      const paginatedMock = mockPosts.slice(startIndex, startIndex + limit);
      const hasNextPage = startIndex + limit < mockPosts.length;
      nextCursor = hasNextPage ? paginatedMock[paginatedMock.length - 1].id : null;

      posts = paginatedMock.map(p => ({
        id: p.id,
        display_name: p.display_name,
        belt_level: p.belt_level,
        discipline: p.discipline,
        title: p.title,
        video_url: p.video_url,
        thumbnail_url: p.thumbnail_url,
        likes_count: p.likes_count,
        comments_count: p.comments_count
      }));
    }

    // 5. Save base result to Redis (TTL 5 minutes)
    try {
      const dataToCache = { posts, nextCursor };
      await redis.setex(cacheKey, 300, JSON.stringify(dataToCache));
    } catch (err: any) {
      console.warn('Redis: Write failed:', err.message);
    }

    // 6. Inject user-specific is_liked states and return response
    const finalPosts = await injectLikesAndUserMeta(posts, currentUserId);
    res.status(200).json({
      posts: finalPosts,
      nextCursor
    });

  } catch (err) {
    next(err);
  }
});

// @route   POST /api/v1/feed/:id/like
// @desc    Toggle like status on a post (Optimistic toggle)
// @access  Authenticated
router.post('/:id/like', requireAuth, async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const { id: postId } = req.params;
    const userId = req.user?.id || '00000000-0000-0000-0000-000000000000';

    let isLiked = false;
    let likesCount = 0;
    let isDbSuccess = false;

    // A. Attempt Database Like Toggle
    try {
      // Check if post exists
      const { data: post, error: postErr } = await supabase
        .from('posts')
        .select('id')
        .eq('id', postId)
        .single();

      if (postErr || !post) {
        throw new Error('Post not found in database');
      }

      // Check if like exists
      const { data: existingLike } = await supabase
        .from('post_likes')
        .select('*')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

      if (existingLike) {
        // Unlike: Delete row
        const { error: unlikeErr } = await supabase
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);

        if (unlikeErr) throw unlikeErr;
        isLiked = false;
      } else {
        // Like: Insert row
        const { error: likeErr } = await supabase
          .from('post_likes')
          .insert({ post_id: postId, user_id: userId });

        if (likeErr) throw likeErr;
        isLiked = true;
      }

      // Fetch updated likes count
      const { count, error: countErr } = await supabase
        .from('post_likes')
        .select('*', { count: 'exact', head: true })
        .eq('post_id', postId);

      if (countErr) throw countErr;
      likesCount = count || 0;
      isDbSuccess = true;
    } catch (dbErr: any) {
      console.warn('Database: Like transaction failed, falling back to mock state. Reason:', dbErr.message);
    }

    // B. Mock In-Memory Like Fallback
    if (!isDbSuccess) {
      const mockPost = mockPosts.find(p => p.id === postId);
      if (!mockPost) {
        return res.status(404).json({
          error: {
            code: 'POST_NOT_FOUND',
            message: 'The requested feed post was not found.'
          }
        });
      }

      const likeKey = `${userId}:${postId}`;
      if (mockLikes.has(likeKey)) {
        mockLikes.delete(likeKey);
        mockPost.likes_count = Math.max(0, mockPost.likes_count - 1);
        isLiked = false;
      } else {
        mockLikes.add(likeKey);
        mockPost.likes_count++;
        isLiked = true;
      }
      likesCount = mockPost.likes_count;
    }

    // C. Invalidate cached feed lists
    await invalidateFeedCache();

    // D. Return results
    res.status(200).json({
      message: isLiked ? 'Post liked successfully' : 'Post unliked successfully',
      isLiked,
      likesCount
    });

  } catch (err) {
    next(err);
  }
});

// Helper to inject is_liked flag based on user id and batch verify
async function injectLikesAndUserMeta(posts: any[], userId: string | null): Promise<any[]> {
  if (posts.length === 0) return [];

  const postIds = posts.map(p => p.id);

  // A. Database like mapping
  if (userId) {
    try {
      const { data: userLikesData } = await supabase
        .from('post_likes')
        .select('post_id')
        .eq('user_id', userId)
        .in('post_id', postIds);

      const userLikedPostIds = new Set<string>();
      if (userLikesData) {
        userLikesData.forEach(l => userLikedPostIds.add(l.post_id));
      }

      return posts.map(p => ({
        ...p,
        is_liked: userLikedPostIds.has(p.id)
      }));
    } catch (dbErr) {
      // Fallback to in-memory check if DB fails
      console.warn('Database: Like state validation failed, using memory state.');
    }
  }

  // B. Fallback/Mock like mapping
  return posts.map(p => {
    const likeKey = `${userId || 'anonymous'}:${p.id}`;
    return {
      ...p,
      is_liked: mockLikes.has(likeKey)
    };
  });
}

export default router;
