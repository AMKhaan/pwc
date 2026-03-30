import { Injectable, OnModuleDestroy, OnModuleInit, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private client: Redis;
  private readonly logger = new Logger(RedisService.name);

  constructor(private config: ConfigService) {}

  onModuleInit() {
    this.client = new Redis({
      host: this.config.get<string>('redis.host'),
      port: this.config.get<number>('redis.port'),
      password: this.config.get<string>('redis.password') || undefined,
      retryStrategy: (times) => Math.min(times * 500, 3000),
    });

    this.client.on('connect', () => this.logger.log('Redis connected'));
    this.client.on('error', (err) => this.logger.error('Redis error', err));
  }

  onModuleDestroy() {
    this.client.disconnect();
  }

  // ─── Core operations ───────────────────────────────────────────────────────

  async set(key: string, value: string, ttlSeconds?: number): Promise<void> {
    if (ttlSeconds) {
      await this.client.set(key, value, 'EX', ttlSeconds);
    } else {
      await this.client.set(key, value);
    }
  }

  async get(key: string): Promise<string | null> {
    return this.client.get(key);
  }

  async del(key: string): Promise<void> {
    await this.client.del(key);
  }

  async exists(key: string): Promise<boolean> {
    const result = await this.client.exists(key);
    return result === 1;
  }

  async ttl(key: string): Promise<number> {
    return this.client.ttl(key);
  }

  // ─── OTP rate limiting ─────────────────────────────────────────────────────
  // Max 3 OTP requests per email per 10 minutes

  private otpRateLimitKey(email: string): string {
    return `otp_rate:${email}`;
  }

  async checkOtpRateLimit(email: string): Promise<void> {
    const key = this.otpRateLimitKey(email);
    const count = await this.client.get(key);

    if (count && parseInt(count) >= 3) {
      const remaining = await this.client.ttl(key);
      throw new Error(
        `Too many OTP requests. Please wait ${Math.ceil(remaining / 60)} minutes.`,
      );
    }
  }

  async incrementOtpCount(email: string): Promise<void> {
    const key = this.otpRateLimitKey(email);
    const exists = await this.exists(key);

    if (!exists) {
      await this.client.set(key, '1', 'EX', 600); // 10 min window
    } else {
      await this.client.incr(key);
    }
  }

  // ─── Blacklist JWT on logout ───────────────────────────────────────────────

  async blacklistToken(token: string, ttlSeconds: number): Promise<void> {
    await this.set(`blacklist:${token}`, '1', ttlSeconds);
  }

  async isTokenBlacklisted(token: string): Promise<boolean> {
    return this.exists(`blacklist:${token}`);
  }
}
