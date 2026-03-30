import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BookingsService } from './bookings.service';
import { BookingsController } from './bookings.controller';
import { Booking } from '../../database/entities/booking.entity';
import { Ride } from '../../database/entities/ride.entity';
import { RidesModule } from '../rides/rides.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Booking, Ride]),
    RidesModule,
  ],
  controllers: [BookingsController],
  providers: [BookingsService],
  exports: [BookingsService],
})
export class BookingsModule {}
