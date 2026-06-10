import { Response, NextFunction } from 'express';
import { supabase } from '../index';
import { AuthenticatedRequest } from '../types';

export async function requireAuth(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      // In development mode, allow bypassing strict auth to support local mobile demo testing
      if (process.env.NODE_ENV === 'development' || !process.env.SUPABASE_URL || process.env.SUPABASE_URL.includes('placeholder')) {
        req.user = {
          id: '00000000-0000-0000-0000-000000000000',
          email: 'mockuser@dojopro.com',
          user_metadata: { role: 'athlete', display_name: 'Mock Athlete' },
          aud: 'authenticated',
          created_at: new Date().toISOString(),
          app_metadata: {}
        } as any;
        return next();
      }

      return res.status(401).json({
        error: {
          code: 'UNAUTHORIZED',
          message: 'Authorization header is missing or malformed. Bearer token required.'
        }
      });
    }

    const token = authHeader.split(' ')[1];
    const { data: { user }, error } = await supabase.auth.getUser(token);

    if (error || !user) {
      return res.status(401).json({
        error: {
          code: 'UNAUTHORIZED',
          message: 'Invalid or expired authentication token.',
          details: error?.message
        }
      });
    }

    // Attach authenticated user to request
    req.user = user;
    next();
  } catch (err) {
    next(err);
  }
}
