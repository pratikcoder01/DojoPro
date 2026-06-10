import Redis from 'ioredis';

const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';

const redis = new Redis(redisUrl, {
  maxRetriesPerRequest: 1,
  showFriendlyErrorStack: true,
  retryStrategy(times) {
    // Attempt connection a maximum of 3 times before entering offline mode
    if (times > 3) {
      console.warn('Redis client: Max reconnection attempts reached. Entering offline mode (bypassing cache).');
      return null;
    }
    return Math.min(times * 100, 2000);
  }
});

redis.on('connect', () => {
  console.log('Redis client: Successfully connected to Redis.');
});

redis.on('error', (err: any) => {
  console.warn('Redis client connection warning/error:', err.message);
});

export default redis;
