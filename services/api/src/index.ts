import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import { createClient } from '@supabase/supabase-js';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// Initialize Supabase Client
const supabaseUrl = process.env.SUPABASE_URL || 'https://placeholder.supabase.co';
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'placeholder-anon-key';

export const supabase = createClient(supabaseUrl, supabaseKey);

// Middleware
app.use(helmet());
app.use(cors({
  origin: '*', // Adjust this for production to only allow the mobile & web clients
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(morgan('dev'));
app.use(express.json());

// Health check endpoint
app.get('/health', (req: Request, res: Response) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    env: process.env.NODE_ENV || 'development'
  });
});

// Import and mount routes
import authRoutes from './routes/auth.routes';
import userRoutes from './routes/user.routes';
import feedRoutes from './routes/feed.routes';
import coachingRoutes from './routes/coaching.routes';
import gymRoutes from './routes/gym.routes';
import beltRoutes from './routes/belt.routes';
import tournamentRoutes from './routes/tournament.routes';
import sparringRoutes from './routes/sparring.routes';

app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/feed', feedRoutes);
app.use('/api/v1/coaching', coachingRoutes);
app.use('/api/v1/gyms', gymRoutes);
app.use('/api/v1/belts', beltRoutes);
app.use('/api/v1/tournaments', tournamentRoutes);
app.use('/api/v1/sparring', sparringRoutes);

// Global Error Handler
app.use((err: any, req: Request, res: Response, next: NextFunction) => {
  console.error('Unhandled Error:', err);
  res.status(err.status || 500).json({
    error: {
      code: err.code || 'INTERNAL_SERVER_ERROR',
      message: err.message || 'An unexpected error occurred.',
      details: process.env.NODE_ENV === 'development' ? err.stack : undefined
    }
  });
});

// Start the server
if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => {
    console.log(`DojoPro Primary API running on port ${PORT}`);
  });
}

export default app;
