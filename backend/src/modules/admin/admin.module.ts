import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { User } from '../../database/entities/user.entity';
import { Ride } from '../../database/entities/ride.entity';
import { Payment } from '../../database/entities/payment.entity';
import { Booking } from '../../database/entities/booking.entity';

@Module({
  imports: [TypeOrmModule.forFeature([User, Ride, Payment, Booking])],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}
