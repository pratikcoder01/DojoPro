import { Router, Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { supabase } from '../index';

const router = Router();

// Zod schemas for input validation
const signupSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters long'),
  role: z.enum(['athlete', 'coach', 'gym', 'admin']).optional().default('athlete'),
  displayName: z.string().min(2, 'Display name must be at least 2 characters').optional()
});

const loginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string()
});

// @route   POST /api/v1/auth/signup
// @desc    Register a new user (extends auth.users)
// @access  Public
router.post('/signup', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const validation = signupSchema.safeParse(req.body);
    if (!validation.success) {
      return res.status(400).json({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid registration input.',
          details: validation.error.format()
        }
      });
    }

    const { email, password, role, displayName } = validation.data;

    // Call Supabase Auth sign up
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          role,
          display_name: displayName || email.split('@')[0]
        }
      }
    });

    if (error) {
      return res.status(400).json({
        error: {
          code: 'REGISTRATION_FAILED',
          message: error.message
        }
      });
    }

    res.status(201).json({
      message: 'User registered successfully. Please verify your email.',
      user: {
        id: data.user?.id,
        email: data.user?.email,
        role: data.user?.user_metadata?.role,
        displayName: data.user?.user_metadata?.display_name
      }
    });
  } catch (err) {
    next(err);
  }
});

// @route   POST /api/v1/auth/login
// @desc    Authenticate user and get JWT
// @access  Public
router.post('/login', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const validation = loginSchema.safeParse(req.body);
    if (!validation.success) {
      return res.status(400).json({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid login credentials structure.',
          details: validation.error.format()
        }
      });
    }

    const { email, password } = validation.data;

    // Call Supabase Auth login
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });

    if (error) {
      return res.status(401).json({
        error: {
          code: 'AUTHENTICATION_FAILED',
          message: error.message
        }
      });
    }

    res.status(200).json({
      message: 'Login successful',
      session: {
        access_token: data.session?.access_token,
        refresh_token: data.session?.refresh_token,
        expires_in: data.session?.expires_in,
        token_type: data.session?.token_type
      },
      user: {
        id: data.user?.id,
        email: data.user?.email,
        role: data.user?.user_metadata?.role,
        displayName: data.user?.user_metadata?.display_name
      }
    });
  } catch (err) {
    next(err);
  }
});

export default router;
