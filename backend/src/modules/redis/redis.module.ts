import { Global, Module } from '@nestjs/common';
import { RedisService } from './redis.service';

@Global() // Available everywhere without re-importing
@Module({
  providers: [RedisService],
  exports: [RedisService],
})
export class RedisModule {}
