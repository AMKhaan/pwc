import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ThrottlerModule } from '@nestjs/throttler';
import configuration from './config/configuration';
import { User } from './database/entities/user.entity';
import { Vehicle } from './database/entities/vehicle.entity';
import { Ride } from './database/entities/ride.entity';
import { Booking } from './database/entities/booking.entity';
import { Payment } from './database/entities/payment.entity';
import { EmailVerification } from './database/entities/email-verification.entity';
import { UniversityDomain } from './database/entities/university-domain.entity';
import { Notification } from './database/entities/notification.entity';
import { AuthModule } from './modules/auth/auth.module';
import { RedisModule } from './modules/redis/redis.module';
import { UsersModule } from './modules/users/users.module';
import { RidesModule } from './modules/rides/rides.module';
import { BookingsModule } from './modules/bookings/bookings.module';
import { MatchingModule } from './modules/matching/matching.module';
import { PaymentsModule } from './modules/payments/payments.module';
import { RealtimeModule } from './modules/realtime/realtime.module';
import { AdminModule } from './modules/admin/admin.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { StorageModule } from './modules/storage/storage.module';

@Module({
  imports: [
    // Config — load .env globally
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
    }),

    // Database — PostgreSQL via TypeORM
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        host: config.get('database.host'),
        port: config.get('database.port'),
        username: config.get('database.username'),
        password: config.get('database.password'),
        database: config.get('database.name'),
        entities: [
          User,
          Vehicle,
          Ride,
          Booking,
          Payment,
          EmailVerification,
          UniversityDomain,
          Notification,
        ],
        synchronize: config.get('app.nodeEnv') === 'development' || process.env.DB_SYNC === 'true',
        logging: config.get('app.nodeEnv') === 'development',
      }),
      inject: [ConfigService],
    }),

    // Rate limiting — protect all endpoints
    ThrottlerModule.forRoot([
      {
        ttl: 60000, // 1 minute window
        limit: 60,  // max 60 requests per minute per IP
      },
    ]),

    // Feature modules
    RedisModule,
    MatchingModule,
    AuthModule,
    UsersModule,
    RidesModule,
    BookingsModule,
    PaymentsModule,
    RealtimeModule,
    AdminModule,
    NotificationsModule,
    StorageModule,
  ],
})
export class AppModule {}
