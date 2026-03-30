import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ScheduleModule } from '@nestjs/schedule';
import { PaymentsService } from './payments.service';
import { PaymentsController } from './payments.controller';
import { JazzCashService } from './gateways/jazzcash.service';
import { EasypaisaService } from './gateways/easypaisa.service';
import { Payment } from '../../database/entities/payment.entity';
import { Booking } from '../../database/entities/booking.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Payment, Booking]),
    ScheduleModule.forRoot(),
  ],
  controllers: [PaymentsController],
  providers: [PaymentsService, JazzCashService, EasypaisaService],
  exports: [PaymentsService],
})
export class PaymentsModule {}
